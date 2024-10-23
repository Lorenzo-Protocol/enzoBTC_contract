// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IStrategyManager {
    event UserWithdrawal(address _strategy, address _user, uint256 _amount, uint256 _blockNumber);
    event UserRequestWithdrawal(address _strategy, address _user, uint256 _amount, uint256 _blockNumber);
    event UserDeposit(address _strategy, address _user, uint256 _amount, uint256 _blockNumber);
}
