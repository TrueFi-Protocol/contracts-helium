// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IBulletLoans} from "./interfaces/IBulletLoans.sol";
import {IFlexiblePortfolio} from "./interfaces/IFlexiblePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";
import {ProxyWrapper} from "./proxy/ProxyWrapper.sol";

contract FlexiblePortfolioFactory is InitializableManageable {
    IFlexiblePortfolio public portfolioImplementation;
    IFlexiblePortfolio[] public portfolios;

    mapping(address => bool) public isWhitelisted;

    event PortfolioCreated(IFlexiblePortfolio newPortfolio, address manager);
    event WhitelistChanged(address account, bool whitelisted);
    event PortfolioImplementationChanged(IFlexiblePortfolio newImplementation);

    constructor() InitializableManageable(msg.sender) {}

    function initialize(IFlexiblePortfolio _portfolioImplementation) external {
        InitializableManageable.initialize(msg.sender);
        portfolioImplementation = _portfolioImplementation;
    }

    function setIsWhitelisted(address account, bool _isWhitelisted) external onlyManager {
        isWhitelisted[account] = _isWhitelisted;
        emit WhitelistChanged(account, _isWhitelisted);
    }

    function setPortfolioImplementation(IFlexiblePortfolio newImplementation) external onlyManager {
        portfolioImplementation = newImplementation;
        emit PortfolioImplementationChanged(newImplementation);
    }

    function createPortfolio(IERC20WithDecimals _underlyingToken, uint256 _duration) external {
        require(isWhitelisted[msg.sender], "FlexiblePortfolioFactory: Caller is not whitelisted");
        bytes memory initCalldata = abi.encodeWithSelector(
            IFlexiblePortfolio.initialize.selector,
            _duration,
            _underlyingToken,
            msg.sender
        );
        IFlexiblePortfolio newPortfolio = IFlexiblePortfolio(
            address(new ProxyWrapper(address(portfolioImplementation), initCalldata))
        );
        portfolios.push(newPortfolio);
        emit PortfolioCreated(newPortfolio, msg.sender);
    }

    function getPortfolios() external view returns (IFlexiblePortfolio[] memory) {
        return portfolios;
    }
}
