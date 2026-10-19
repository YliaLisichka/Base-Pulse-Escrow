const hre = require("hardhat");
async function main() {
  const Escrow = await hre.ethers.getContractFactory("PulseEscrow");
  const escrow = await Escrow.deploy();
  await escrow.deployed();
  console.log("PulseEscrow deployed to:", escrow.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
