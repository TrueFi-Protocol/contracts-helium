// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FailingERC20 is ERC20 {
    bool public isFailing;

    constructor() ERC20("Failing", "FAILING") {
        isFailing = true;
    }

    function initialize() external {}

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function setFailing(bool _isFailing) external {
        isFailing = _isFailing;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (isFailing) {
            return false;
        } else {
            return super.transfer(to, amount);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (isFailing) {
            return false;
        } else {
            return super.transferFrom(from, to, amount);
        }
    }

    function mint(address account, uint256 amount) external {
        super._mint(account, amount);
    }
}
