// SPDX-License-Identifier: MIT
// License declaration
pragma solidity ^0.8.28;

// Main contract for managing land sales using an escrow mechanism
contract LandSaleEscrow {

    // Address of the registrar (administrator)
    // Only this account can approve land sales
    address public registrar;

    // Counter used to generate unique land IDs
    uint256 public landCounter;

    // Counter used to generate unique transaction IDs
    uint256 public transactionCounter;

    // Constructor runs once when the contract is deployed
    // The deployer becomes the registrar/admin
    constructor() {
        registrar = msg.sender;
    }

    // Structure to store land information
    struct Land {

        // Unique identifier of the land
        uint256 landId;

        // Physical location of the land
        string location;

        // Size of the land (e.g., square meters)
        uint256 area;

        // Current owner of the land
        address owner;

        // Selling price of the land in Wei
        uint256 price;

        // Indicates whether the land is available for sale
        bool forSale;
    }

    // Structure to store information about a sale
    struct Sale {

        // ID of the land being sold
        uint256 landId;

        // Seller's wallet address
        address seller;

        // Buyer's wallet address
        address buyer;

        // Amount paid by the buyer
        uint256 amountPaid;

        // Indicates whether the registrar approved the sale
        bool approved;

        // Indicates whether the sale has been completed
        bool completed;
    }

    // Structure used to maintain transaction history
    struct TransactionHistory {

        // Unique transaction identifier
        uint256 transactionId;

        // Land involved in the transaction
        uint256 landId;

        // Previous owner of the land
        address previousOwner;

        // New owner after transfer
        address newOwner;

        // Price paid for the land
        uint256 salePrice;

        // Timestamp when transaction occurred
        uint256 timestamp;
    }

    // Mapping Land ID => Land Details
    mapping(uint256 => Land) public lands;

    // Mapping Land ID => Sale Details
    mapping(uint256 => Sale) public sales;

    // Array storing all completed transactions
    TransactionHistory[] public transactionHistory;

    // Event emitted when a new land is registered
    event LandRegistered(
        uint256 landId,
        address owner,
        string location
    );

    // Event emitted when land is listed for sale
    event LandListed(
        uint256 landId,
        uint256 price
    );

    // Event emitted when buyer deposits payment
    event PaymentDeposited(
        uint256 landId,
        address buyer,
        uint256 amount
    );

    // Event emitted when registrar approves a sale
    event SaleApproved(
        uint256 landId
    );

    // Event emitted when ownership changes
    event OwnershipTransferred(
        uint256 landId,
        address oldOwner,
        address newOwner
    );

    // Modifier restricting access to registrar only
    modifier onlyRegistrar() {

        require(
            msg.sender == registrar,
            "Only registrar allowed"
        );

        _;
    }

    // Modifier ensuring caller owns the specified land
    modifier onlyLandOwner(uint256 _landId) {

        require(
            lands[_landId].owner == msg.sender,
            "Not land owner"
        );

        _;
    }

    // Function used to register a new land
    function registerLand(
        string memory _location,
        uint256 _area,
        uint256 _price
    ) public {

        // Generate new land ID
        landCounter++;

        // Store land information
        lands[landCounter] = Land({
            landId: landCounter,
            location: _location,
            area: _area,
            owner: msg.sender,
            price: _price,
            forSale: false
        });

        // Notify blockchain listeners
        emit LandRegistered(
            landCounter,
            msg.sender,
            _location
        );
    }

    // Function for owner to list land for sale
    function listLandForSale(
        uint256 _landId,
        uint256 _price
    )
        public
        onlyLandOwner(_landId)
    {
        // Reference to land record
        Land storage land = lands[_landId];

        // Mark land as available
        land.forSale = true;

        // Update sale price
        land.price = _price;

        // Emit event
        emit LandListed(
            _landId,
            _price
        );
    }

    // Function allowing buyer to purchase land
    // payable allows ETH to be sent with transaction
    function buyLand(
        uint256 _landId
    )
        public
        payable
    {
        // Get land record
        Land storage land = lands[_landId];

        // Ensure land is listed for sale
        require(
            land.forSale,
            "Land not for sale"
        );

        // Ensure exact payment is made
        require(
            msg.value == land.price,
            "Incorrect payment"
        );

        // Create sale record
        sales[_landId] = Sale({
            landId: _landId,
            seller: land.owner,
            buyer: msg.sender,
            amountPaid: msg.value,
            approved: false,
            completed: false
        });

        // Payment remains inside contract (escrow)
        emit PaymentDeposited(
            _landId,
            msg.sender,
            msg.value
        );
    }

    // Registrar approves the sale
    function approveSale(
        uint256 _landId
    )
        public
        onlyRegistrar
    {
        // Retrieve sale record
        Sale storage sale = sales[_landId];

        // Retrieve land record
        Land storage land = lands[_landId];

        // Ensure buyer exists
        require(
            sale.buyer != address(0),
            "No buyer found"
        );

        // Ensure sale was not already completed
        require(
            !sale.completed,
            "Sale already completed"
        );

        // Mark sale approved and completed
        sale.approved = true;
        sale.completed = true;

        // Save previous owner
        address oldOwner = land.owner;

        // Transfer ownership
        land.owner = sale.buyer;

        // Remove land from marketplace
        land.forSale = false;

        // Release escrow payment to seller
        payable(sale.seller).transfer(
            sale.amountPaid
        );

        // Generate transaction ID
        transactionCounter++;

        // Store transaction history
        transactionHistory.push(
            TransactionHistory({
                transactionId: transactionCounter,
                landId: _landId,
                previousOwner: oldOwner,
                newOwner: sale.buyer,
                salePrice: sale.amountPaid,
                timestamp: block.timestamp
            })
        );

        // Emit approval event
        emit SaleApproved(_landId);

        // Emit ownership transfer event
        emit OwnershipTransferred(
            _landId,
            oldOwner,
            sale.buyer
        );
    }

    // Retrieve land details by ID
    function getLand(
        uint256 _landId
    )
        public
        view
        returns (Land memory)
    {
        return lands[_landId];
    }

    // Retrieve sale details by land ID
    function getSale(
        uint256 _landId
    )
        public
        view
        returns (Sale memory)
    {
        return sales[_landId];
    }

    // Return total number of completed transactions
    function getTransactionCount()
        public
        view
        returns (uint256)
    {
        return transactionHistory.length;
    }
}