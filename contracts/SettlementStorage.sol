// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Orders} from "./libraries/Orders.sol";

contract SettlementStorage {
    enum Direction {
        Low,
        Up
    }
    struct BiDirection {
        bool low;
        bool up;
    }
    struct ValidateRes {
        bool res;
        uint8 reason;
    }

    event CouponOrderExecuted(address indexed owner, bytes32 indexed orderHash, Orders.CouponOrder order, Direction direction);

    event LimitOrderExecuted(address indexed owner, bytes32 indexed orderHash, Orders.LimitOrder order);

    event CouponOrderCanceled(address indexed owner, Orders.CouponOrder[] orders, BiDirection[] lowUp);

    event LimitOrderCanceled(address indexed owner, Orders.LimitOrder[] orders);

    event OrderCanceled(address indexed owner, bytes32 symbols, uint256 blockNumber, uint8 reason);

    event AddressSet(uint256 indexed index, address previousAddress, address newAddress);

    uint256 constant OwnerAddressIndex = 0;
    uint256 constant MasterAddressIndex = 1;
    uint256 constant OracleAddressIndex = 2;
    uint256 constant UsdtAddressIndex = 3;

    uint8 constant InvalidReasonSuccess = 0;
    uint8 constant InvalidReasonCancelled = 1;
    uint8 constant InvalidReasonExecuted = 2;
    uint8 constant InvalidReasonNotMeetPrice = 3;
    uint8 constant InvalidReasonNotEnoughPosition = 4;
    uint8 constant InvalidReasonNotEnoughUsdt = 5;
    uint8 constant InvalidReasonWrongDirection = 6;
    uint8 constant InvalidReasonExceedDeadline = 7;

    // hash of an order => if canceled
    mapping(bytes32 => mapping(Direction => bool)) internal CancelledHash;

    // address => (symbol => blockNumber)
    mapping(address => mapping(bytes32 => uint256)) internal CancelledByBlockNumber; // deprecated, but can not be deleted for updatable

    mapping(bytes32 => mapping(Direction => bool)) internal ExecutedHash;

    mapping(uint256 => address) internal AddressMap;

    bytes32 internal DOMAIN_SEPARATOR;

    address internal _owner;

    uint256 internal _initialized;

    // address => (symbol => timestamp)
    mapping(address => mapping(bytes32 => uint256)) internal CancelledByTimestamp;

    mapping(bytes32 => bool) internal LimitOrderExecutedHash;

    mapping(bytes32 => bool) internal LimitOrderCancelledHash;

    modifier onlyOwner() {
        require(AddressMap[OwnerAddressIndex] == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyMaster() {
        require(AddressMap[MasterAddressIndex] == msg.sender, "caller is not the master");
        _;
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "allowed for EOA");
        _;
    }

    modifier onlyOnce() {
        require(_initialized == 0, "OnlyOnce: function recalled");
        _;
    }
}
