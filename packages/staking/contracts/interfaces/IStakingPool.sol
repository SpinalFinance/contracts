// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Staking Pool interface
interface IStakingPool {

    function slash(uint256 amount) external;

    function numOfValidatorAllowed(address usr) external returns (uint256);

    function claimAndUpdateRewardDebt(address usr) external;

    function stakePriorityFee() external returns (bool);

    function updateRewardPerValidator(uint256 newReward) external;

}