// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "../interfaces/IBasePortfolio.sol";
import {ILenderVerifier} from "../interfaces/ILenderVerifier.sol";

contract AlternativeTradingSystemDepositStrategy {
    mapping(IBasePortfolio => mapping(address => bool)) public isWhitelisted;
    ILenderVerifier globalWhitelist;

    event WhitelistStatusChanged(IBasePortfolio indexed portfolio, address indexed user, bool status);

    modifier onlyManager(IBasePortfolio portfolio) {
        require(
            portfolio.hasRole(portfolio.MANAGER_ROLE(), msg.sender),
            "AlternativeTradingSystemDepositStrategy: Caller in not portfolio manager"
        );

        _;
    }

    constructor(ILenderVerifier _globalWhitelist) {
        globalWhitelist = _globalWhitelist;
    }

    function isAllowed(IBasePortfolio portfolio, address investor) public view returns (bool) {
        return isWhitelisted[portfolio][investor] || globalWhitelist.isAllowed(investor, 0, "0x0");
    }

    function deposit(IBasePortfolio portfolio, uint256 amount) external {
        require(isAllowed(portfolio, msg.sender), "AlternativeTradingSystemDepositStrategy: User is not whitelisted for deposit");
        portfolio.deposit(amount, msg.sender);
    }

    function _setWhitelistStatus(
        IBasePortfolio portfolio,
        address user,
        bool status
    ) internal {
        require(isWhitelisted[portfolio][user] != status, "AlternativeTradingSystemDepositStrategy: Cannot set the same status twice");
        isWhitelisted[portfolio][user] = status;
        emit WhitelistStatusChanged(portfolio, user, status);
    }

    function setWhitelistStatus(
        IBasePortfolio portfolio,
        address user,
        bool status
    ) external onlyManager(portfolio) {
        _setWhitelistStatus(portfolio, user, status);
    }

    function setWhitelistStatusForMany(
        IBasePortfolio portfolio,
        address[] calldata addressesToWhitelist,
        bool status
    ) external onlyManager(portfolio) {
        for (uint256 i = 0; i < addressesToWhitelist.length; i++) {
            _setWhitelistStatus(portfolio, addressesToWhitelist[i], status);
        }
    }
}
