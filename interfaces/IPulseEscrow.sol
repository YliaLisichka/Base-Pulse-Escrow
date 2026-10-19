// SPDX-License-Identifier: MIT
pragma solidity 0.8.37;
interface IPulseEscrow {
    function lockFunds(bytes32 agreementHash) external payable;
    function releaseFunds(uint256 escrowId) external;
}
