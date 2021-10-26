// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IOracleAggregator} from "../intf/IOracleAggregator.sol";
import "../intf/IOracleAggregator.sol";

contract MockOracle is IOracleAggregator {
    mapping(bytes32 => uint256) priceMap;

    function readLatestPrice(bytes32) external override returns(uint256) {
        return 0;
    }
    function readCachedPrice(bytes32) external override returns(uint256) {
        return 0;
    }
    // view方法, 读最新的数据
    function getPriceOf(bytes32 symbol) external view override returns(uint256) {
        return priceMap[symbol] / 1000; // only support btc
    }

    function setPriceOf(bytes32 symbol, uint256 price) external override returns(uint256) {
        priceMap[symbol] = price;
    }

    function setOfflinePrice(bytes32 symbol, uint256 price, uint256) external override {
        priceMap[symbol] = price;
    }

}

