// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../libraries/CouponOrders.sol";
import "../libraries/Orders.sol";

interface IFuturePerpetual {
    struct Position {
        uint104   amount;
        uint104   price;
        uint40    modifyBlock;
        int8      direction; // 1 long,  -1 short
    }

    function closePositionFromOrderBook(
        address maker,
        bytes32 symbol,
        uint256 amount,
        address relayer,
        uint256 reward
    )
    external;

    function closePositionFromOrderBookWithPrice(
        address maker,
        bytes32 symbol,
        uint256 amount,
        address relayer,
        uint256 reward,
        uint256 price,
        uint    timestamp,
        uint256[] calldata coupons
    )
    external;

    function openPositionFromOrderBookWithPrice(
        CouponOrders.OpenOrder calldata order,
        Orders.OfflinePrice calldata prices,
        address relayer,
        uint256 reward
    )
    external;

    function queryPosition(address holder, bytes32 symbol)
    external
    view
    returns (Position memory);

    function querySymbolDecimal(bytes32 symbol) external view returns (uint8);

    function setOrderBookContract(address orderBook) external;

    function setPosition(address maker, bytes32 symbol, uint256 amount) external;
}
