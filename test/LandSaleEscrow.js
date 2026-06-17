// Import Chai assertion library
// Used to verify expected results in tests
const { expect } = require("chai");

// Import Hardhat's ethers library
// Used to deploy contracts and interact with them
const { ethers } = require("hardhat");

// Test suite for the LandSaleEscrow contract
describe("LandSaleEscrow", function () {

  // Variables that will be used across all tests
  let contract;
  let registrar;
  let seller;
  let buyer;

  // Runs before each test case
  // Creates a fresh contract deployment every time
  beforeEach(async function () {

    // Get test accounts provided by Hardhat
    // Account[0] = registrar (contract deployer)
    // Account[1] = seller
    // Account[2] = buyer
    [registrar, seller, buyer] =
      await ethers.getSigners();

    // Get the contract factory
    // Factory is used to deploy new contract instances
    const LandSaleEscrow =
      await ethers.getContractFactory(
        "LandSaleEscrow"
      );

    // Deploy the smart contract
    // The deployer becomes the registrar because
    // constructor sets registrar = msg.sender
    contract =
      await LandSaleEscrow.deploy();
  });

  // Test Case 1:
  // Verify that land registration works correctly
  it("Should register land", async function () {

    // Seller registers a land
    await contract.connect(seller)
      .registerLand(
        "Musanze",                 // location
        500,                       // area
        ethers.parseEther("1")     // price = 1 ETH
      );

    // Retrieve land information using land ID = 1
    const land =
      await contract.getLand(1);

    // Verify that the land owner is the seller
    expect(
      land.owner
    ).to.equal(seller.address);
  });

  // Test Case 2:
  // Verify the complete land sale process
  it("Should complete land sale", async function () {

    // Step 1:
    // Seller registers a land
    await contract.connect(seller)
      .registerLand(
        "Musanze",
        500,
        ethers.parseEther("1")
      );

    // Step 2:
    // Seller lists the land for sale
    await contract.connect(seller)
      .listLandForSale(
        1,                         // Land ID
        ethers.parseEther("1")     // Selling price
      );

    // Step 3:
    // Buyer purchases the land
    // Sends exactly 1 ETH to the contract
    await contract.connect(buyer)
      .buyLand(
        1,
        {
          value:
          ethers.parseEther("1")
        }
      );

    // Step 4:
    // Registrar approves the sale
    // This transfers ownership and releases payment
    await contract
      .approveSale(1);

    // Step 5:
    // Retrieve updated land information
    const land =
      await contract.getLand(1);

    // Verify ownership changed from seller to buyer
    expect(
      land.owner
    ).to.equal(buyer.address);
  });

});