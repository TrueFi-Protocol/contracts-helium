// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {VoteToken} from "../VoteToken.sol";

contract MockVoteToken is VoteToken {
    constructor(uint256 _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }

    function name() public pure virtual override returns (string memory) {
        return "MockVoteToken";
    }

    function symbol() public pure virtual override returns (string memory) {
        return "MVT";
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) public {
        _writeCheckpoint(delegatee, nCheckpoints, oldVotes, newVotes);
    }

    function writeTwoCheckpoints(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newerVotes,
        uint96 newestVotes
    ) public {
        _writeCheckpoint(delegatee, nCheckpoints, oldVotes, newerVotes);
        _writeCheckpoint(delegatee, nCheckpoints + 1, newerVotes, newestVotes);
    }

    function moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) public {
        _moveDelegates(srcRep, dstRep, amount);
    }
}
