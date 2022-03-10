// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IManageable} from "../access/interfaces/IManageable.sol";

interface IProtocolConfig is IManageable {
    function protocolFee() external view returns (uint256);

    function automatedLineOfCreditPremiumFee() external view returns (uint256);

    function protocolAddress() external view returns (address);
}
