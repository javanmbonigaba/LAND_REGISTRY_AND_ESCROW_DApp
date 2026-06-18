// ==========================================================
// IMPORT LIBRARIES
// ==========================================================

// Chai assertion library
// Used for comparing expected and actual values
const { expect } = require("chai");

// Hardhat Ethers library
// Used for deploying and interacting with contracts
const { ethers } = require("hardhat");

// ==========================================================
// TEST SUITE
// ==========================================================

describe("LandSaleEscrow + LandHistory", function () {


// Contract instances
let escrow;
let history;

// Test accounts
let registrar;
let seller;
let buyer;


// ======================================================
// BEFORE EACH TEST
// ======================================================
// Runs before every test case

beforeEach(async function () {

    // Get test blockchain accounts
    [registrar, seller, buyer] =
        await ethers.getSigners();

    // Deploy Escrow Contract

    const LandSaleEscrow =
        await ethers.getContractFactory(
            "LandSaleEscrow"
        );

    escrow =
        await LandSaleEscrow.deploy();

    // Get address of automatically deployed
    // LandHistory contract

    const historyAddress =
        await escrow.historyContract();

    // Connect to LandHistory

    history =
        await ethers.getContractAt(
            "LandHistory",
            historyAddress
        );

    console.log("\n================================");
    console.log("Contracts Deployed");
    console.log("Escrow:", await escrow.getAddress());
    console.log("History:", historyAddress);
    console.log("Registrar:", registrar.address);
    console.log("Seller:", seller.address);
    console.log("Buyer:", buyer.address);
    console.log("================================\n");
});


// ======================================================
// TEST 1
// Register Land
// ======================================================

it("Seller registers land", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    const land =
        await escrow.getLand(1);

    console.log("Land Registered");
    console.log("Location:", land.location);
    console.log("Owner:", land.owner);

    expect(
        land.owner
    ).to.equal(
        seller.address
    );
});


// ======================================================
// TEST 2
// Registrar Approves Registration
// ======================================================

it("Registrar approves registration", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    const land =
        await escrow.getLand(1);

    console.log(
        "Approved:",
        land.approved
    );

    expect(
        land.approved
    ).to.equal(true);
});


// ======================================================
// TEST 3
// Prevent Duplicate Registration
// ======================================================

it("Cannot register same land twice", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await expect(

        escrow.connect(seller)
            .registerLand(
                "Musanze",
                500,
                ethers.parseEther("1")
            )

    ).to.be.revertedWith(
        "Land already registered"
    );
});


// ======================================================
// TEST 4
// Register Multiple Lands
// ======================================================

it("Seller registers second land", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow.connect(seller)
        .registerLand(
            "Kigali",
            1000,
            ethers.parseEther("2")
        );

    const land2 =
        await escrow.getLand(2);

    expect(
        land2.location
    ).to.equal(
        "Kigali"
    );
});


// ======================================================
// TEST 5
// List Land For Sale
// ======================================================

it("Seller lists approved land", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("2")
        );

    const land =
        await escrow.getLand(1);

    expect(
        land.forSale
    ).to.equal(true);
});


// ======================================================
// TEST 6
// Buyer Pays For Land
// ======================================================

it("Buyer deposits payment", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("1")
        );

    await escrow.connect(buyer)
        .buyLand(
            1,
            {
                value:
                ethers.parseEther("1")
            }
        );

    const sale =
        await escrow.getSale(1);

    expect(
        sale.buyer
    ).to.equal(
        buyer.address
    );
});


// ======================================================
// TEST 7
// Registrar Approves Payment
// ======================================================

it("Registrar approves payment", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("1")
        );

    await escrow.connect(buyer)
        .buyLand(
            1,
            {
                value:
                ethers.parseEther("1")
            }
        );

    await escrow
        .approvePayment(1);

    const sale =
        await escrow.getSale(1);

    expect(
        sale.paymentApproved
    ).to.equal(true);
});


// ======================================================
// TEST 8
// Seller Withdraws Payment
// ======================================================

it("Seller withdraws payment", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("1")
        );

    await escrow.connect(buyer)
        .buyLand(
            1,
            {
                value:
                ethers.parseEther("1")
            }
        );

    await escrow
        .approvePayment(1);

    await escrow.connect(seller)
        .withdrawPayment(1);

    const sale =
        await escrow.getSale(1);

    expect(
        sale.sellerPaid
    ).to.equal(true);
});


// ======================================================
// TEST 9
// Transfer Ownership
// ======================================================

it("Registrar transfers ownership", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("1")
        );

    await escrow.connect(buyer)
        .buyLand(
            1,
            {
                value:
                ethers.parseEther("1")
            }
        );

    await escrow
        .approvePayment(1);

    await escrow.connect(seller)
        .withdrawPayment(1);

    await escrow
        .transferOwnership(1);

    const land =
        await escrow.getLand(1);

    expect(
        land.owner
    ).to.equal(
        buyer.address
    );
});


// ======================================================
// TEST 10
// Verify History Contract Records
// ======================================================

it("Stores completed transaction in LandHistory", async function () {

    await escrow.connect(seller)
        .registerLand(
            "Musanze",
            500,
            ethers.parseEther("1")
        );

    await escrow
        .approveLandRegistration(1);

    await escrow.connect(seller)
        .listLandForSale(
            1,
            ethers.parseEther("1")
        );

    await escrow.connect(buyer)
        .buyLand(
            1,
            {
                value:
                ethers.parseEther("1")
            }
        );

    await escrow
        .approvePayment(1);

    await escrow.connect(seller)
        .withdrawPayment(1);

    await escrow
        .transferOwnership(1);

    const count =
        await history.getRecordCount();

    console.log(
        "History Records:",
        count.toString()
    );

    expect(
        count
    ).to.equal(1);
});


});