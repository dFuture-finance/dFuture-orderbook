// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {Orders} from "./libraries/Orders.sol";
import {EIP712} from "./libraries/EIP712.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract OrderBook is Ownable {
    event CouponOrderCreated(bytes32 indexed hash, address indexed owner, Orders.CouponOrder order);

    event LimitOrderCreated(bytes32 indexed hash, address indexed owner, Orders.LimitOrder order);
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;

    constructor() public {
    }

    function setDomainSeparator(uint256 chainId, address masterAddr) public onlyOwner {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("OrderBook"),
                keccak256("1"),
                chainId,
                masterAddr
            )
        );
    }

    function createCouponOrder(Orders.CouponOrder memory order) public onlyOwner {
        require(order.trader != address(0), "invalid-trader-address");
        bytes32 orderHash = Orders.hash(order);
        require(EIP712.recover(DOMAIN_SEPARATOR, orderHash, order.v, order.r, order.s) == order.trader && order.trader != address(0), "not-signed-by-trader");
        emit CouponOrderCreated(orderHash, order.trader, order);
    }

    function createLimitOrder(Orders.LimitOrder memory order) public onlyOwner {
        require(order.trader != address(0), "invalid-trader-address");
        bytes32 orderHash = Orders.hash(order);
        require(EIP712.recover(DOMAIN_SEPARATOR, orderHash, order.v, order.r, order.s) == order.trader && order.trader != address(0), "not-signed-by-trader");
        emit LimitOrderCreated(orderHash, order.trader, order);
    }
}
