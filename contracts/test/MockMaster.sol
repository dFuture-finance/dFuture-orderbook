// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IFuturePerpetual} from "./../intf/IFuturePerpetual.sol";
import {Settlement} from "./../Settlement.sol";
import "../libraries/CouponOrders.sol";
import "../libraries/Orders.sol";

contract MockMaster is IFuturePerpetual {
    address orderBook;
    mapping(address => mapping(bytes32 => uint256)) positions;
    function closePositionFromOrderBook(
        address maker,
        bytes32 symbol,
        uint256 amount,
        address,
        uint256
    )
    external
    override {
        if (positions[maker][symbol] < amount) {
            revert("position not enough");
        } else if (positions[maker][symbol] == amount) {
            positions[maker][symbol] = 0;
            Settlement settlement = Settlement(orderBook);
            settlement.onPositionOut(maker, symbol, block.number, 0);
        } else {
            positions[maker][symbol] -= amount;
        }
    }

    function closePositionFromOrderBookWithPrice(
        address maker,
        bytes32 symbol,
        uint256 amount,
        address relayer,
        uint256 reward,
        uint256 ,
        uint ,
        uint256[] calldata
    )
    external
    override {
        this.closePositionFromOrderBook(maker, symbol, amount, relayer, reward);
    }

    function openPositionFromOrderBookWithPrice(
        CouponOrders.OpenOrder calldata order,
        Orders.OfflinePrice calldata prices,
        address relayer,
        uint256 reward
    )
    external
    override {
        // todo
    }

    function queryPosition(address holder, bytes32 symbol)
    external
    view
    override
    returns (IFuturePerpetual.Position memory) {
        IFuturePerpetual.Position memory position;
        position.amount = uint104(positions[holder][symbol]);
        return position;
    }

    function setOrderBookContract(address orderBookAddress) external override {
        orderBook = orderBookAddress;
    }

    function setPosition(address maker, bytes32 symbol, uint256 amount) external override {
        positions[maker][symbol] = amount;
    }

    function querySymbolDecimal(bytes32) external view override returns (uint8) {
        return 3; // btc only
    }
}
