// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IMintStrategy {
    enum StrategyStatus {
        Close, // 0
        Open // 1

    }

    function getStrategyStatus()
        external
        view
        returns (StrategyStatus _depositStatus, StrategyStatus _withdrawStatus);
    function getWithdrawalDelayBlocks() external view returns (uint256);
    function deposit(address _token, address _user, uint256 _amount) external returns (uint256);
    function withdraw(address _token, address _user, uint256 _amount) external;

    event DepositStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event WithdrawalStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event EnzoNetworkChanged(address EnzoNetwork, address _EnzoNetwork);
    event Withdrawal(address _strategy, address _underlyingToken, address _user, uint256 _amount);
    event WithdrawalDelayChanged(uint256 _oldWithdrawalDelayBlocks, uint256 _withdrawalDelayBlocks);
    event Deposit(address _strategy, address _underlyingToken, address _user, uint256 _amount);
    event TxExecuted(uint256 _value, address _to, bytes _data);
}
