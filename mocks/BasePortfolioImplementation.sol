// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasePortfolio} from "../BasePortfolio.sol";
import {IProtocolConfig} from "../interfaces/IProtocolConfig.sol";

contract BasePortfolioImplementation is BasePortfolio {
    function initialize(
        IProtocolConfig _protocolConfig,
        uint256 _duration,
        IERC20 _underlyingToken,
        uint256 _managerFee
    ) external initializer {
        __BasePortfolio_init(_protocolConfig, _duration, _underlyingToken, msg.sender, _managerFee);
        __ERC20_init("BasePortfolio", "BP");
    }
}
