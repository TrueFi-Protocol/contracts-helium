// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IBasePortfolio} from "./interfaces/IBasePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {IProtocolConfig} from "./interfaces/IProtocolConfig.sol";
import {ProxyWrapper} from "./proxy/ProxyWrapper.sol";
import {Upgradeable} from "./access/Upgradeable.sol";

abstract contract BasePortfolioFactory is Upgradeable {
    IBasePortfolio public portfolioImplementation;
    IBasePortfolio[] public portfolios;
    IProtocolConfig public protocolConfig;

    mapping(address => bool) public isWhitelisted;

    event PortfolioCreated(IBasePortfolio indexed newPortfolio, address indexed manager);
    event WhitelistChanged(address indexed account, bool whitelisted);
    event PortfolioImplementationChanged(IBasePortfolio indexed newImplementation);

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "BasePortfolioFactory: Caller is not whitelisted");
        _;
    }

    function initialize(IBasePortfolio _portfolioImplementation, IProtocolConfig _protocolConfig) external initializer {
        __Upgradeable_init(msg.sender);
        portfolioImplementation = _portfolioImplementation;
        protocolConfig = _protocolConfig;
    }

    function setIsWhitelisted(address account, bool _isWhitelisted) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isWhitelisted[account] != _isWhitelisted, "BasePortfolioFactory: New whitelist status needs to be different");
        isWhitelisted[account] = _isWhitelisted;
        emit WhitelistChanged(account, _isWhitelisted);
    }

    function setPortfolioImplementation(IBasePortfolio newImplementation) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            portfolioImplementation != newImplementation,
            "BasePortfolioFactory: New portfolio implementation needs to be different"
        );
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
