// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IOracleAggregator {
    // 实时读最新的数据
    function readLatestPrice(bytes32 symbol) external returns(uint256);
    // 读报价数据, 有Cache使用Cache, 没有Cache就读最新的数据
    function readCachedPrice(bytes32 symbol) external returns(uint256);
    // view方法, 读最新的数据
    function getPriceOf(bytes32 symbol) external view returns(uint256);
    // set price
    function setPriceOf(bytes32 symbol, uint256 price) external returns(uint256);
    // set offline price to oracle aggregator.
    function setOfflinePrice(bytes32 symbol, uint256 price, uint256 timestamp) external;
}
