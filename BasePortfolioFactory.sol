// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBasePortfolio} from "./interfaces/IBasePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";

import {InitializableManageable} from "./access/InitializableManageable.sol";
import {ProxyWrapper} from "./proxy/ProxyWrapper.sol";

abstract contract BasePortfolioFactory is InitializableManageable {
    IBasePortfolio public portfolioImplementation;
    IBasePortfolio[] public portfolios;
    IProtocolConfig public protocolConfig;

    mapping(address => bool) public isWhitelisted;

    event PortfolioCreated(IBasePortfolio newPortfolio, address manager);
    event WhitelistChanged(address account, bool whitelisted);
    event PortfolioImplementationChanged(IBasePortfolio newImplementation);

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "BasePortfolioFactory: Caller is not whitelisted");
        _;
    }

    constructor() InitializableManageable(msg.sender) {}

    function initialize(IBasePortfolio _portfolioImplementation, IProtocolConfig _protocolConfig) external initializer {
        InitializableManageable.initialize(msg.sender);
        portfolioImplementation = _portfolioImplementation;
        protocolConfig = _protocolConfig;
    }

    function setIsWhitelisted(address account, bool _isWhitelisted) external onlyManager {
        isWhitelisted[account] = _isWhitelisted;
        emit WhitelistChanged(account, _isWhitelisted);
    }

    function setPortfolioImplementation(IBasePortfolio newImplementation) external onlyManager {
        portfolioImplementation = newImplementation;
        emit PortfolioImplementationChanged(newImplementation);
    }

    function getPortfolios() external view returns (IBasePortfolio[] memory) {
        return portfolios;
    }

    function _deployPortfolio(bytes memory initData) internal {
        IBasePortfolio newPortfolio = IBasePortfolio(address(new ProxyWrapper(address(portfolioImplementation), initData)));
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio, msg.sender);
    }
}
