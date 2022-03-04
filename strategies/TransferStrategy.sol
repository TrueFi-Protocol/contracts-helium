// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ITransferStrategy} from "../interfaces/ITransferStrategy.sol";

contract TransferStrategy is ITransferStrategy {
    function canTransfer(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        revert("TS_NOT_SUPPORTED_YET");
    }
}
