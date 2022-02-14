// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {InitializableManageable} from "./access/InitializableManageable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IBasePortfolio} from "./interfaces/IBasePortfolio.sol";
import {IERC20WithDecimals} from "./interfaces/IERC20WithDecimals.sol";
import {ITransferStrategy} from "./interfaces/ITransferStrategy.sol";

abstract contract BasePortfolio is IBasePortfolio, ERC20Upgradeable, InitializableManageable, AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public endDate;
    IERC20 public underlyingToken;
    uint256 public underlyingTokenDecimals;

    address[] public depositStrategies;
    address[] public withdrawStrategies;
    address public transferStrategy;

    bytes32 public DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 public WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    bytes32 public TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor() InitializableManageable(msg.sender) {}

    function __BasePortfolio_init(
        uint256 _duration,
        IERC20 _underlyingToken,
        address _manager
    ) internal initializer {
        InitializableManageable.initialize(_manager);
        AccessControlUpgradeable.__AccessControl_init();

        endDate = block.timestamp + _duration;
        underlyingToken = _underlyingToken;
        underlyingTokenDecimals = IERC20WithDecimals(address(_underlyingToken)).decimals();
    }

    function getDepositStrategies() public view returns (address[] memory) {
        return depositStrategies;
    }

    function getWithdrawStrategies() public view returns (address[] memory) {
        return withdrawStrategies;
    }

    function addStrategy(
        bytes32 role,
        address[] storage strategies,
        address strategy
    ) internal {
        _grantRole(role, strategy);
        strategies.push(strategy);
    }

    function removeStrategy(
        bytes32 role,
        address[] storage strategies,
        address strategy
    ) internal {
        _revokeRole(role, strategy);
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i] == strategy) {
                delete strategies[i];
                if (i <= strategies.length - 1) {
                    strategies[i] = strategies[strategies.length - 1];
                }
                strategies.pop();
            }
        }
    }

    function addDepositStrategy(address _depositStrategy) external {
        addStrategy(DEPOSIT_ROLE, depositStrategies, _depositStrategy);
    }

    function removeDepositStrategy(address _depositStrategy) external {
        removeStrategy(DEPOSIT_ROLE, depositStrategies, _depositStrategy);
    }

    function addWithdrawStrategy(address _withdrawStrategy) external {
        addStrategy(WITHDRAW_ROLE, withdrawStrategies, _withdrawStrategy);
    }

    function removeWithdrawStrategy(address _withdrawStrategy) external {
        removeStrategy(WITHDRAW_ROLE, withdrawStrategies, _withdrawStrategy);
    }

    function setTransferStrategy(address _transferStrategy) external {
        if (transferStrategy != address(0)) {
            _revokeRole(TRANSFER_ROLE, transferStrategy);
        }
        if (_transferStrategy != address(0)) {
            _grantRole(TRANSFER_ROLE, _transferStrategy);
        }
        transferStrategy = _transferStrategy;
    }

    function deposit(uint256 amount, address sender) public virtual onlyRole(DEPOSIT_ROLE) {
        _mint(sender, calculateAmountToMint(amount));
        underlyingToken.safeTransferFrom(sender, address(this), amount);
    }

    function withdraw(uint256 shares, address sender) public virtual onlyRole(WITHDRAW_ROLE) {
        uint256 amountToWithdraw = calculateAmountToWithdraw(shares);
        _burn(sender, shares);
        underlyingToken.safeTransfer(sender, amountToWithdraw);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (transferStrategy == address(0) || ITransferStrategy(transferStrategy).canTransfer(msg.sender, recipient, amount)) {
            _transfer(msg.sender, recipient, amount);
            return true;
        }
        return false;
    }

    function calculateAmountToMint(uint256 depositedAmount) public view virtual returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return (depositedAmount * 10**decimals()) / (10**underlyingTokenDecimals);
        } else {
            return (depositedAmount * _totalSupply) / value();
        }
    }

    function calculateAmountToWithdraw(uint256 sharesAmount) public view virtual returns (uint256) {
        return (sharesAmount * value()) / totalSupply();
    }

    function value() public view virtual returns (uint256) {
        return underlyingToken.balanceOf(address(this));
    }
}
