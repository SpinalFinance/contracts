//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20} from "./IERC20.sol";

/// @title Oracle interface
interface IStkFIL is IERC20{

    function pricePerShare() external view returns (uint256 amount);

    function mint(address user, uint256 amount) external;

    function burn(address user, uint256 amount) external;
}