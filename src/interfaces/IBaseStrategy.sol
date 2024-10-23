// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IBaseStrategy {
    enum StrategyStatus {
        Close, // 0
        Open // 1

    }

    function deposit(address _user, uint256 _amount) external;
    function requestWithdrawal(address _user, uint256 _amount) external;
    function withdraw(address _user, uint256 _amount) external;
    function getUserShares(address _user) external view returns (uint256);
    function getUnderlyingToken() external view returns (address);

    event DepositStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event WithdrawalStatusChanged(StrategyStatus _oldStatus, StrategyStatus _status);
    event StrategyManagerChanged(address strategyManager, address _strategyManager);
    event FundManagerChanged(address fundManager, address _fundManager);
    event FloorAmountChanged(uint256 floorAmount, uint256 _floorAmount);
    event SharesLimitChanged(uint256 sharesLimit, uint256 _sharesLimit);
    event Withdrawal(address _strategy, address _user, uint256 _amount);
    event RequestWithdrawal(address _strategy, address _user, uint256 _amount);
    event Deposit(address _strategy, address _user, uint256 _amount);
    event TxExecuted(uint256 _value, address _to, bytes _data);
}
