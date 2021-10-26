// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// sync with future-perpetual/contracts/lib/CouponOrders.sol
library CouponOrders {
    struct OpenOrder {
        bytes32 symbol;
        uint256 amount;
        int8    direction;
        uint256 acceptablePrice;
        uint256 approvedUsdt;
        address parent;
        bool    withDiscount;
        uint256 deadline;
        address maker;
        uint8   gasLevel;
        uint256 couponId;
        uint256 couponAmount;

        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}
