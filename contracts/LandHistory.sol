// SPDX-License-Identifier: MIT
// Specifies the software license for this smart contract
pragma solidity ^0.8.28;

// ======================================================
// LAND HISTORY CONTRACT
// Purpose:
// Store permanent records of completed land transactions
// ======================================================

contract LandHistory {

    // ==================================================
    // STRUCT
    // ==================================================
    // A struct is a custom data type that groups
    // related information together.

    struct Record {

        // Unique transaction number
        uint256 transactionId;

        // ID of the land involved
        uint256 landId;

        // Previous owner of the land
        address previousOwner;

        // New owner of the land
        address newOwner;

        // Sale price paid for the land
        uint256 salePrice;

        // Date and time when transaction was recorded
        uint256 timestamp;
    }

    // ==================================================
    // STORAGE
    // ==================================================

    // Dynamic array that stores all transaction records
    Record[] public records;

    // ==================================================
    // EVENTS
    // ==================================================
    // Events create logs on the blockchain.
    // They are useful for:
    // - Frontend notifications
    // - Debugging
    // - Transaction tracking

    event TransactionRecorded(

        uint256 transactionId,

        uint256 landId,

        address previousOwner,

        address newOwner
    );

    // ==================================================
    // FUNCTION:
    // ADD A NEW TRANSACTION RECORD
    // ==================================================

    function addRecord(

        uint256 _transactionId,

        uint256 _landId,

        address _previousOwner,

        address _newOwner,

        uint256 _salePrice

    )
        public
    {
        // Create a new record and store it
        // inside the records array

        records.push(

            Record({

                transactionId: _transactionId,

                landId: _landId,

                previousOwner: _previousOwner,

                newOwner: _newOwner,

                salePrice: _salePrice,

                timestamp: block.timestamp

            })

        );

        // Emit blockchain log

        emit TransactionRecorded(

            _transactionId,

            _landId,

            _previousOwner,

            _newOwner

        );
    }

    // ==================================================
    // FUNCTION:
    // GET TOTAL NUMBER OF RECORDS
    // ==================================================

    function getRecordCount()
        public
        view
        returns (uint256)
    {
        return records.length;
    }

    // ==================================================
    // FUNCTION:
    // GET A SPECIFIC RECORD
    // ==================================================

    function getRecord(
        uint256 _index
    )
        public
        view
        returns (
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint256
        )
    {
        // Load record into memory

        Record memory record =
            records[_index];

        // Return all fields

        return (

            record.transactionId,

            record.landId,

            record.previousOwner,

            record.newOwner,

            record.salePrice,

            record.timestamp

        );
    }
}