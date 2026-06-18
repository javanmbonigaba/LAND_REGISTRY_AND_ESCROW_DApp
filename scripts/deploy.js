// Sample deployment script for LandSaleEscrow
// This script shows how to deploy the contract using Hardhat runtime environment (hre)
// It is commented line-by-line so you can follow each step when running or adapting it.

const hre = require("hardhat"); // import Hardhat runtime environment

async function main() { // main deployment function
  // Get the contract factory for LandSaleEscrow // comment: factory
  const LandSaleEscrow = await hre.ethers.getContractFactory("LandSaleEscrow"); // create factory

  // Deploy the contract // comment: deploy
  const escrow = await LandSaleEscrow.deploy(); // deploy instance

  // Wait for deployment to be mined // comment: wait
  await escrow.deployed(); // ensure deployed

  // Log the deployed address // comment: log
  console.log("LandSaleEscrow deployed to:", escrow.address); // output address
}

// Execute main and handle errors // comment: run
main()
  .then(() => process.exit(0)) // on success exit 0
  .catch((error) => { // on error log and exit 1
    console.error(error); // print error
    process.exit(1); // exit
  });
