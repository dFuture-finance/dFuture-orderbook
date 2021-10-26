// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUsdt is ERC20("usdt", "USDT") {
    constructor() public {
        _setupDecimals(6);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}
