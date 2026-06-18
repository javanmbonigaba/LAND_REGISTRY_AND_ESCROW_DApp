// SPDX-License-Identifier: MIT

// Solidity compiler version
pragma solidity ^0.8.28;

// Import LandHistory contract
// Used to record completed transactions
import "./LandHistory.sol";

// =====================================================
// LAND SALE ESCROW CONTRACT
// =====================================================
// This contract simulates a land sale process.
//
// Actors:
// 1. Registrar (Admin)
// 2. Seller (Land Owner)
// 3. Buyer
//
// Workflow:
// Seller registers land
// Registrar approves registration
// Seller lists land for sale
// Buyer pays for land
// Registrar approves payment
// Seller withdraws payment
// Registrar transfers ownership
// Transaction recorded in LandHistory
// =====================================================

contract LandSaleEscrow {


// =================================================
// STATE VARIABLES
// =================================================

// Registrar address
address public registrar;

// Counter for land IDs
uint256 public landCounter;

// Counter for transaction IDs
uint256 public transactionCounter;

// Reference to LandHistory contract
LandHistory public historyContract;

// Used to prevent duplicate land registration
mapping(bytes32 => bool) public registeredLands;


// =================================================
// CONSTRUCTOR
// =================================================
// Runs only once during deployment

constructor() {

    // Contract deployer becomes registrar
    registrar = msg.sender;

    // Deploy LandHistory contract
    historyContract = new LandHistory();
}


// =================================================
// LAND STRUCT
// =================================================
// Stores land information

struct Land {

    uint256 landId;

    string location;

    uint256 area;

    address owner;

    uint256 price;

    bool registered;

    bool approved;

    bool forSale;
}


// =================================================
// SALE STRUCT
// =================================================
// Stores sale information

struct Sale {

    uint256 landId;

    address seller;

    address buyer;

    uint256 amountPaid;

    bool paymentApproved;

    bool sellerPaid;

    bool ownershipTransferred;
}


// =================================================
// MAPPINGS
// =================================================

// landId => Land
mapping(uint256 => Land) public lands;

// landId => Sale
mapping(uint256 => Sale) public sales;


// =================================================
// EVENTS
// =================================================

event LandRegistered(
    uint256 landId,
    address owner,
    string location
);

event LandApproved(
    uint256 landId
);

event LandListed(
    uint256 landId,
    uint256 price
);

event PaymentDeposited(
    uint256 landId,
    address buyer,
    uint256 amount
);

event PaymentApproved(
    uint256 landId
);

event SellerPaid(
    uint256 landId,
    uint256 amount
);

event OwnershipTransferred(
    uint256 landId,
    address oldOwner,
    address newOwner
);


// =================================================
// MODIFIERS
// =================================================

// Registrar only
modifier onlyRegistrar() {

    require(
        msg.sender == registrar,
        "Only registrar allowed"
    );

    _;
}

// Land owner only
modifier onlyLandOwner(
    uint256 _landId
) {

    require(
        lands[_landId].owner ==
        msg.sender,
        "Not land owner"
    );

    _;
}


// =================================================
// REGISTER LAND
// =================================================

function registerLand(
    string memory _location,
    uint256 _area,
    uint256 _price
)
    public
{
    // Generate unique fingerprint

    bytes32 landKey =
        keccak256(
            abi.encodePacked(
                _location,
                _area,
                msg.sender
            )
        );

    // Prevent duplicate registration

    require(
        !registeredLands[landKey],
        "Land already registered"
    );

    // Create new land ID

    landCounter++;

    // Store land

    lands[landCounter] = Land({

        landId: landCounter,

        location: _location,

        area: _area,

        owner: msg.sender,

        price: _price,

        registered: true,

        approved: false,

        forSale: false
    });

    // Mark as registered

    registeredLands[landKey] = true;

    emit LandRegistered(
        landCounter,
        msg.sender,
        _location
    );
}


// =================================================
// APPROVE LAND REGISTRATION
// =================================================

function approveLandRegistration(
    uint256 _landId
)
    public
    onlyRegistrar
{
    require(
        lands[_landId].registered,
        "Land not found"
    );

    lands[_landId].approved = true;

    emit LandApproved(
        _landId
    );
}


// =================================================
// LIST LAND FOR SALE
// =================================================

function listLandForSale(
    uint256 _landId,
    uint256 _price
)
    public
    onlyLandOwner(_landId)
{
    require(
        lands[_landId].approved,
        "Land not approved"
    );

    lands[_landId].forSale = true;

    lands[_landId].price = _price;

    emit LandListed(
        _landId,
        _price
    );
}


// =================================================
// BUY LAND
// =================================================
// Buyer sends ETH to escrow

function buyLand(
    uint256 _landId
)
    public
    payable
{
    Land storage land =
        lands[_landId];

    require(
        land.forSale,
        "Land not for sale"
    );

    require(
        msg.value ==
        land.price,
        "Incorrect payment"
    );

    sales[_landId] = Sale({

        landId: _landId,

        seller: land.owner,

        buyer: msg.sender,

        amountPaid: msg.value,

        paymentApproved: false,

        sellerPaid: false,

        ownershipTransferred: false
    });

    emit PaymentDeposited(
        _landId,
        msg.sender,
        msg.value
    );
}


// =================================================
// APPROVE PAYMENT
// =================================================

function approvePayment(
    uint256 _landId
)
    public
    onlyRegistrar
{
    sales[_landId]
        .paymentApproved = true;

    emit PaymentApproved(
        _landId
    );
}


// =================================================
// SELLER WITHDRAWS PAYMENT
// =================================================

function withdrawPayment(
    uint256 _landId
)
    public
{
    Sale storage sale =
        sales[_landId];

    require(
        msg.sender ==
        sale.seller,
        "Not seller"
    );

    require(
        sale.paymentApproved,
        "Payment not approved"
    );

    require(
        !sale.sellerPaid,
        "Already paid"
    );

    sale.sellerPaid = true;

    payable(
        sale.seller
    ).transfer(
        sale.amountPaid
    );

    emit SellerPaid(
        _landId,
        sale.amountPaid
    );
}


// =================================================
// TRANSFER OWNERSHIP
// =================================================

function transferOwnership(
    uint256 _landId
)
    public
    onlyRegistrar
{
    Sale storage sale =
        sales[_landId];

    Land storage land =
        lands[_landId];

    require(
        sale.paymentApproved,
        "Payment not approved"
    );

    require(
        sale.sellerPaid,
        "Seller not paid"
    );

    require(
        !sale.ownershipTransferred,
        "Already transferred"
    );

    address oldOwner =
        land.owner;

    // Transfer ownership

    land.owner =
        sale.buyer;

    land.forSale = false;

    sale.ownershipTransferred = true;

    // Create transaction ID

    transactionCounter++;

    // Save transaction in LandHistory

    historyContract.addRecord(
        transactionCounter,
        _landId,
        oldOwner,
        sale.buyer,
        sale.amountPaid
    );

    emit OwnershipTransferred(
        _landId,
        oldOwner,
        sale.buyer
    );
}


// =================================================
// GET LAND DETAILS
// =================================================

function getLand(
    uint256 _landId
)
    public
    view
    returns (Land memory)
{
    return lands[_landId];
}


// =================================================
// GET SALE DETAILS
// =================================================

function getSale(
    uint256 _landId
)
    public
    view
    returns (Sale memory)
{
    return sales[_landId];
}


// =================================================
// GET TRANSACTION COUNT
// =================================================

function getTransactionCount()
    public
    view
    returns (uint256)
{
    return transactionCounter;
}


}