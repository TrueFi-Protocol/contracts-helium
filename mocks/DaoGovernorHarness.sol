// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {DaoGovernor} from "../governance/DaoGovernor.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract DaoGovernorHarness is DaoGovernor {
    constructor(
        uint256 __votingDelay,
        uint256 __votingPeriod,
        uint256 __proposalThreshold,
        IVotes _token,
        uint256 _quorumFraction,
        TimelockController _timelock
    ) DaoGovernor(__votingDelay, __votingPeriod, __proposalThreshold, _token, _quorumFraction, _timelock) {}

    function _quorumReachedHarness(uint256 timestamp) public view returns (bool) {
        return super._quorumReached(timestamp);
    }

    function _voteSucceededHarness(uint256 timestamp) public view returns (bool) {
        return super._voteSucceeded(timestamp);
    }

    uint256 _votingDelay;

    uint256 _votingPeriod;

    uint256 _proposalThreshold;

    mapping(uint256 => uint256) public ghost_sum_vote_power_by_id;

    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual override returns (uint256) {
        uint256 deltaWeight = super._castVote(proposalId, account, support, reason); //HARNESS
        ghost_sum_vote_power_by_id[proposalId] += deltaWeight;

        return deltaWeight;
    }

    function getExecutor() public view returns (address) {
        return _executor();
    }
}
