// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {StkTruToken} from "../StkTruToken.sol";
import {ITrueDistributor} from "../interfaces/ITrueDistributor.sol";
import {VoteToken} from "../VoteToken.sol";

contract MockStkTruToken is StkTruToken {
    constructor() StkTruToken() {}

    function mint(address account, uint256 amount) public {
        super._mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        super._burn(account, amount);
    }

    function doubleMint(address account, uint256 amount) public {
        mint(account, amount);
        mint(account, amount);
    }

    function setDistributor(ITrueDistributor _distributor) public {
        distributor = _distributor;
    }

    function mintWithoutCheckpoint(address account, uint256 amount) public {
        VoteToken._mint(account, amount);
    }

    function totalSupplyCheckpoints(uint256 index) public view returns (Checkpoint memory) {
        return _totalSupplyCheckpoints[index];
    }

    function setVotes(address account, uint96 newVotes) external {
        _writeCheckpoint(account, numCheckpoints[account], getCurrentVotes(account), newVotes);
    }
}
