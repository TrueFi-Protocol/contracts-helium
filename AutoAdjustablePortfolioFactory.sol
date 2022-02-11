// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IAutoAdjustablePortfolio} from "./interfaces/IAutoAdjustablePortfolio.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";
import {ProxyWrapper} from "./proxy/ProxyWrapper.sol";

contract AutoAdjustablePortfolioFactory is InitializableManageable {
    IAutoAdjustablePortfolio[] private portfolios;
    IAutoAdjustablePortfolio public portfolioImplementation;

    mapping(address => bool) public isWhitelisted;

    event PortfolioCreated(IAutoAdjustablePortfolio newPortfolio);
    event WhitelistChanged(address account, bool whitelisted);

    constructor() InitializableManageable(msg.sender) {}

    function initialize(IAutoAdjustablePortfolio _portfolioImplementation) external {
        InitializableManageable.initialize(msg.sender);
        portfolioImplementation = _portfolioImplementation;
    }

    function setIsWhitelisted(address account, bool _isWhitelisted) external onlyManager {
        isWhitelisted[account] = _isWhitelisted;
        emit WhitelistChanged(account, _isWhitelisted);
    }

    function createPortfolio(uint256 _duration, IERC20WithDecimals _underlyingToken) external {
        require(isWhitelisted[msg.sender], "AutoAdjustablePortfolioFactory: Caller is not whitelisted");
        bytes memory initCalldata = abi.encodeWithSelector(IAutoAdjustablePortfolio.initialize.selector, _duration, _underlyingToken);
        IAutoAdjustablePortfolio newPortfolio = IAutoAdjustablePortfolio(
            address(new ProxyWrapper(address(portfolioImplementation), initCalldata))
        );
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio);
    }

    function getPortfolios() external view returns (IAutoAdjustablePortfolio[] memory) {
        return portfolios;
    }
}
