// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
// pragma experimental ABIEncoderV2;

library Orders {

    struct OfflinePrice {
        uint256 price;
        uint    timestamp;
    }

    bytes32 public constant COUPON_ORDER_TYPEHASH = 0x37121680a6625a8f51de4886244a9f478567c8aba3b73e1fefa9b400653b6946;

    struct CouponOrder {
        address trader;
        uint256 timestamp; // the timestamp when the order created
        uint256 deadline; // the life period of the order, reserved now
        uint256 amount0; // the amount to be settled when price lower than targetPrice0
        uint256 targetPrice0; // settled when price lower than targetPrice0
        uint256 fee0; // the fee to the relayer
        uint256 coupons0;
        uint256 amount1; // the amount to be settled when price higher than targetPrice1
        uint256 targetPrice1; // settled when price higher than targetPrice1
        uint256 fee1; // the foo to the relayer
        uint256 coupons1;
        bytes32 symbol; // 0 : no supported; 1 : BTC; 2 : ETH; 3 : LINK; 4 : YFI
        bytes32 r;
        bytes32 s;
        uint8   v;
    }

    function hash(CouponOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                COUPON_ORDER_TYPEHASH,
                order.trader,
                order.timestamp,
                order.deadline,
                order.amount0,
                order.targetPrice0,
                order.fee0,
                order.coupons0,
                order.amount1,
                order.targetPrice1,
                order.fee1,
                order.coupons1,
                order.symbol
            )
        );
    }

    bytes32 public constant OPEN_ORDER_SUBSET_TYPEHASH = 0x656c5b476af55ca28384e6a269d245c95419b05ade819517bff17f3552b6b78a;
    bytes32 public constant LIMIT_ORDER_TYPEHASH = 0x058312a32946d0911be9c3813cadb605e2446e0e11f07fbe084903d6f85f795c;

    struct OpenOrderSubset {
        bytes32 symbol;
        uint256 amount;
        int8    direction;
        uint256 acceptablePrice;
        uint256 approvedUsdt;
        address parent;
        bool    withDiscount;
        uint256 openOrderDeadline;
        uint8   gasLevel;
        uint256 couponId;
    }

    struct LimitOrder {
        address trader;
        uint256 timestamp;
        uint256 deadline;
        uint256 lowOrUp; // Direction
        uint256 targetPrice;
        uint256 fee;
        OpenOrderSubset openOrderSubset;
        bytes32 r;
        bytes32 s;
        uint8   v;
    }

    function hash(LimitOrder memory order) internal pure returns (bytes32) {
        bytes32 internalOrderHash = keccak256(
            abi.encode(
                OPEN_ORDER_SUBSET_TYPEHASH,
                order.openOrderSubset.symbol,
                order.openOrderSubset.amount,
                order.openOrderSubset.direction,
                order.openOrderSubset.acceptablePrice,
                order.openOrderSubset.approvedUsdt,
                order.openOrderSubset.parent,
                order.openOrderSubset.withDiscount,
                order.openOrderSubset.openOrderDeadline,
                order.openOrderSubset.gasLevel,
                order.openOrderSubset.couponId
            )
        );
        return keccak256(
            abi.encode(
                LIMIT_ORDER_TYPEHASH,
                order.trader,
                order.timestamp,
                order.deadline,
                order.lowOrUp,
                order.targetPrice,
                order.fee,
                internalOrderHash
            )
        );
    }
}
