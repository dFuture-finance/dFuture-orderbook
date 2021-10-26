// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Orders} from "./libraries/Orders.sol";
import {CouponOrders} from "./libraries/CouponOrders.sol";
import {EIP712} from "./libraries/EIP712.sol";
import {SettlementStorage} from "./SettlementStorage.sol";
import {IFuturePerpetual} from "./intf/IFuturePerpetual.sol";
import {IOracleAggregator} from "./intf/IOracleAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract Settlement is SettlementStorage {
    using SafeMath  for uint256;

    function initialize() public  onlyOnce {
        AddressMap[OwnerAddressIndex] = msg.sender;
        _initialized = 1;
    }

    function verify(address trader, bytes32 orderHash, uint8 v, bytes32 r, bytes32 s) private view returns(bool) {
        address signer = EIP712.recover(DOMAIN_SEPARATOR, orderHash, v, r, s);
        return signer != address(0) && signer == trader;
    }

    function onPositionOut(address trader, bytes32 symbol, uint256 blockNumber, uint8 reason)  public onlyMaster {
        CancelledByTimestamp[trader][symbol] = block.timestamp;
        emit OrderCanceled(trader, symbol, blockNumber, reason);
    }

    function setAddress(uint256 index, address newAddress)  public onlyOwner {
        require(newAddress != address(0), "newAddress is 0");
        address previousAddress = AddressMap[index];
        AddressMap[index] = newAddress;
        emit AddressSet(index, previousAddress, newAddress);
    }

    function setDomainSeparator(uint256 chainId, address settlementAddr)  public onlyOwner {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("OrderBook"),
                keccak256("1"),
                chainId,
                settlementAddr
            )
        );
    }

// --------------------------------------------------
    function doCallFuturePerpetual(Orders.CouponOrder memory order, Direction direction, Orders.OfflinePrice memory price) internal {
        IFuturePerpetual fp = IFuturePerpetual(AddressMap[MasterAddressIndex]);
        uint8 decimal = fp.querySymbolDecimal(order.symbol);
        uint256 priceOfShare = price.price.div(10**uint256(decimal));
        uint256[] memory coupons = new uint256[](2);
        coupons[1] = 1;
        if (direction == Direction.Low) {
            require(priceOfShare <= order.targetPrice0, "not-meet-price");
            coupons[0] = order.coupons0;
            fp.closePositionFromOrderBookWithPrice(order.trader, order.symbol, order.amount0, msg.sender, order.fee0, price.price, price.timestamp, coupons);
        } else if (direction == Direction.Up) {
            require(priceOfShare >= order.targetPrice1, "not-meet-price");
            coupons[0] = order.coupons1;
            fp.closePositionFromOrderBookWithPrice(order.trader, order.symbol, order.amount1, msg.sender, order.fee1, price.price, price.timestamp, coupons);
        } else {
            revert("invalid direction");
        }
    }

    function executeOrderWithCoupon(Orders.CouponOrder memory order, Direction direction, Orders.OfflinePrice memory price) public onlyEOA {
        bytes32 orderHash = Orders.hash(order);
        require(verify(order.trader, orderHash, order.v, order.r, order.s), "not-signed-by-trader");
        (bool success, ) = validateWithCoupon(order, direction);
        require(success == true, "not-valid-order");
        require(price.price > 0 && price.timestamp > 0, "wrong-price");

        ExecutedHash[orderHash][direction] = true;
        doCallFuturePerpetual(order, direction, price);

        emit CouponOrderExecuted(order.trader, orderHash, order, direction);
    }

    function cancelOrderWithCoupon(Orders.CouponOrder[] memory orders, BiDirection[] memory lowUp) public onlyEOA {
        require(orders.length > 0, "none-orders");
        for (uint256 i = 0; i < orders.length; i++) {
            require(msg.sender == orders[i].trader, "cancel-other's-order");
            bytes32 orderHash = Orders.hash(orders[i]);
            require(verify(orders[i].trader, orderHash, orders[i].v, orders[i].r, orders[i].s), "not-signed-by-trader");
            require(orders[i].timestamp > CancelledByTimestamp[orders[i].trader][orders[i].symbol], "timestamp-too-late");
            if (lowUp[i].low == true) {
                require(ExecutedHash[orderHash][Direction.Low] == false, "order-already-executed");
                require(CancelledHash[orderHash][Direction.Low] == false, "order-already-cancelled");
                CancelledHash[orderHash][Direction.Low] = true;
            }
            if (lowUp[i].up == true) {
                require(ExecutedHash[orderHash][Direction.Up] == false, "order-already-executed");
                require(CancelledHash[orderHash][Direction.Up] == false, "order-already-cancelled");
                CancelledHash[orderHash][Direction.Up] = true;
            }
        }
        emit CouponOrderCanceled(orders[0].trader, orders, lowUp);
    }

    function validateWithCoupon(Orders.CouponOrder memory order, Direction direction) view public returns(bool, uint8) {
        bytes32 orderHash = Orders.hash(order);
        if (ExecutedHash[orderHash][direction] == true) {
            return (false, InvalidReasonExecuted);
        }
        if (CancelledHash[orderHash][direction] == true || order.timestamp <= CancelledByTimestamp[order.trader][order.symbol]) {
            return (false, InvalidReasonCancelled);
        }

        IFuturePerpetual fp = IFuturePerpetual(AddressMap[MasterAddressIndex]);
        IFuturePerpetual.Position memory position = fp.queryPosition(order.trader, order.symbol);
        if (direction == Direction.Low) {
            if (position.amount < order.amount0) {
                return (false, InvalidReasonNotEnoughPosition);
            }
        } else if (direction == Direction.Up) {
            if (position.amount < order.amount1) {
                return (false, InvalidReasonNotEnoughPosition);
            }
        } else {
            return (false, InvalidReasonWrongDirection);
        }
        return (true, InvalidReasonSuccess);
    }

    function validateBatchWithCoupon(Orders.CouponOrder[] memory orders, Direction[] memory directions) view public returns(ValidateRes[] memory) {
        require(orders.length == directions.length, "length-not-equal");
        ValidateRes[] memory resList = new ValidateRes[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            (resList[i].res, resList[i].reason) = validateWithCoupon(orders[i], directions[i]);
        }
        return resList;
    }

    // Limit Order
    function toOpenOrder(Orders.LimitOrder memory order) pure internal returns(CouponOrders.OpenOrder memory){
        CouponOrders.OpenOrder memory openOrder;
        openOrder.maker = order.trader;
        openOrder.symbol = order.openOrderSubset.symbol;
        openOrder.amount = order.openOrderSubset.amount;
        openOrder.direction = order.openOrderSubset.direction;
        openOrder.acceptablePrice = order.openOrderSubset.acceptablePrice;
        openOrder.approvedUsdt = order.openOrderSubset.approvedUsdt.sub(order.fee);
        openOrder.parent = order.openOrderSubset.parent;
        openOrder.withDiscount = order.openOrderSubset.withDiscount;
        openOrder.deadline = order.openOrderSubset.openOrderDeadline;
        openOrder.gasLevel = order.openOrderSubset.gasLevel;
        openOrder.couponId = order.openOrderSubset.couponId;
        openOrder.couponAmount = 1;
        return openOrder;
    }

    function doCallFuturePerpetualOpen(Orders.LimitOrder memory order, Orders.OfflinePrice memory price) internal {
        IFuturePerpetual fp = IFuturePerpetual(AddressMap[MasterAddressIndex]);
        CouponOrders.OpenOrder memory openOrder = toOpenOrder(order);
        openOrder.deadline = openOrder.deadline.add(block.timestamp + 60);
        if (Direction(order.lowOrUp) == Direction.Low) {
            require(price.price <= order.targetPrice, "not-meet-price");
            fp.openPositionFromOrderBookWithPrice(openOrder, price, msg.sender, order.fee);
        } else if (Direction(order.lowOrUp) == Direction.Up) {
            require(price.price >= order.targetPrice, "not-meet-price");
            fp.openPositionFromOrderBookWithPrice(openOrder, price, msg.sender, order.fee);
        } else {
            revert("invalid direction");
        }
    }

    function executeLimitOrder(Orders.LimitOrder memory order, Orders.OfflinePrice memory price) public onlyEOA {
        bytes32 orderHash = Orders.hash(order);
        require(verify(order.trader, orderHash, order.v, order.r, order.s), "not-signed-by-trader");
        (bool success, ) = validateLimitOrder(order);
        require(success == true, "not-valid-order");
        require(price.price > 0 && price.timestamp > 0, "wrong-price");

        LimitOrderExecutedHash[orderHash] = true;
        doCallFuturePerpetualOpen(order, price);

        emit LimitOrderExecuted(order.trader, orderHash, order);
    }

    function cancelLimitOrder(Orders.LimitOrder[] memory orders) public onlyEOA {
        require(orders.length > 0, "none-orders");
        for (uint256 i = 0; i < orders.length; i++) {
            require(msg.sender == orders[i].trader, "cancel-other's-order");
            bytes32 orderHash = Orders.hash(orders[i]);
            require(verify(orders[i].trader, orderHash, orders[i].v, orders[i].r, orders[i].s), "not-signed-by-trader");
            require(LimitOrderExecutedHash[orderHash] == false, "order-already-executed");
            require(LimitOrderCancelledHash[orderHash] == false, "order-already-cancelled");
            LimitOrderCancelledHash[orderHash] = true;
        }
        emit LimitOrderCanceled(orders[0].trader, orders);
    }

    function validateLimitOrder(Orders.LimitOrder memory order) view public returns(bool, uint8) {
        bytes32 orderHash = Orders.hash(order);
        if (LimitOrderExecutedHash[orderHash] == true) {
            return (false, InvalidReasonExecuted);
        }
        if (LimitOrderCancelledHash[orderHash] == true) {
            return (false, InvalidReasonCancelled);
        }
        if (order.deadline > 0 && order.deadline < block.timestamp) {
            return (false, InvalidReasonExceedDeadline);
        }
        return (true, InvalidReasonSuccess);
    }

    function validateLimitOrderBatch(Orders.LimitOrder[] memory orders) view public returns(ValidateRes[] memory) {
        require(orders.length > 0, "length-zero");
        ValidateRes[] memory resList = new ValidateRes[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            (resList[i].res, resList[i].reason) = validateLimitOrder(orders[i]);
        }
        return resList;
    }
}
