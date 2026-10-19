// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract PulseEscrow {
    enum DealState { Created, Fulfilled, Completed, Refunded }

    struct Deal {
        address buyer;
        address seller;
        uint256 amount;
        string itemDescription;
        DealState state;
        uint256 createdAt;
    }

    uint256 public dealCount;
    mapping(uint256 => Deal) public deals;

    event DealCreated(uint256 indexed dealId, address indexed buyer, address indexed seller, uint256 amount);
    event DealFulfilled(uint256 indexed dealId);
    event DealCompleted(uint256 indexed dealId, uint256 amount);
    event DealRefunded(uint256 indexed dealId, uint256 amount);

    // 1. Покупатель создает сделку и отправляет ETH в эскроу
    function createDeal(address seller, string calldata itemDescription) external payable returns (uint256) {
        require(msg.value > 0, "PulseEscrow: Amount must be greater than zero");
        require(seller != address(0), "PulseEscrow: Invalid seller address");
        require(seller != msg.sender, "PulseEscrow: Cannot buy from yourself");

        dealCount++;
        deals[dealCount] = Deal({
            buyer: msg.sender,
            seller: seller,
            amount: msg.value,
            itemDescription: itemDescription,
            state: DealState.Created,
            createdAt: block.timestamp
        });

        emit DealCreated(dealCount, msg.sender, seller, msg.value);
        return dealCount;
    }

    // 2. Продавец отмечает, что товар/услуга предоставлена
    function confirmFulfillment(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(d.seller == msg.sender, "PulseEscrow: Only seller can confirm");
        require(d.state == DealState.Created, "PulseEscrow: Invalid deal state");

        d.state = DealState.Fulfilled;
        emit DealFulfilled(dealId);
    }

    // 3. Покупатель принимает работу и выпускает ETH продавцу
    function releasePayment(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(d.buyer == msg.sender, "PulseEscrow: Only buyer can release payment");
        require(d.state == DealState.Fulfilled, "PulseEscrow: Deal not fulfilled yet");

        d.state = DealState.Completed;
        uint256 payout = d.amount;
        d.amount = 0;

        (bool sent, ) = payable(d.seller).call{value: payout}("");
        require(sent, "PulseEscrow: Transfer failed");

        emit DealCompleted(dealId, payout);
    }

    // 4. Покупатель может отменить сделку и вернуть ETH, пока продавец не подтвердил выполнение
    function cancelDeal(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(d.buyer == msg.sender, "PulseEscrow: Only buyer can cancel");
        require(d.state == DealState.Created, "PulseEscrow: Cannot cancel active deal");

        d.state = DealState.Refunded;
        uint256 refund = d.amount;
        d.amount = 0;

        (bool sent, ) = payable(d.buyer).call{value: refund}("");
        require(sent, "PulseEscrow: Refund transfer failed");

        emit DealRefunded(dealId, refund);
    }

    // Просмотр сделки
    function getDeal(uint256 dealId) external view returns (
        address buyer,
        address seller,
        uint256 amount,
        string memory itemDescription,
        DealState state,
        uint256 createdAt
    ) {
        Deal memory d = deals[dealId];
        return (d.buyer, d.seller, d.amount, d.itemDescription, d.state, d.createdAt);
    }
}