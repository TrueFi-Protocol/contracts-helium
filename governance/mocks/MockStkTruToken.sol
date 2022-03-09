// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {StkTruToken} from "../StkTruToken.sol";

contract MockStkTruToken is StkTruToken {
    constructor() StkTruToken() {}

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        super._burn(account, amount);
    }
}
