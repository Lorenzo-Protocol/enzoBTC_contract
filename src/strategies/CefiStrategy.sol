// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/strategies/BaseStrategy.sol";

/**
 * @title cefi strategy
 * @author EnzoNetwork
 * @notice Collect assets and help users complete cefi arbitrage
 */
contract CefiStrategy is BaseStrategy {
    mapping(address => uint256) public pendingWithdrawal;
    uint256 public totalPendingWithdrawal;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ownerAddr,
        address _dao,
        address _strategyManager,
        address _fundManager,
        uint256 _floorAmount,
        uint256 _sharesLimit,
        address _underlyingToken,
        address _strategyToken,
        address[] calldata _whitelistedStrategies
    ) public initializer {
        __BaseStrategy_init(
            _ownerAddr,
            _dao,
            _strategyManager,
            _fundManager,
            _floorAmount,
            _underlyingToken,
            _strategyToken,
            _sharesLimit,
            StrategyStatus.Open,
            StrategyStatus.Close,
            _whitelistedStrategies
        );
    }

    /**
     * Withdrawal request, can only be applied when the withdrawal status is Close
     * @param _user user addr
     * @param _amount withdrawal amount
     */
    function requestWithdrawal(address _user, uint256 _amount) external override onlyStrategyManager nonReentrant {
        if (withdrawStatus != StrategyStatus.Close) {
            revert Errors.CantRequestWithdrawal();
        }

        pendingWithdrawal[_user] += _amount;
        totalPendingWithdrawal += _amount;
        emit RequestWithdrawal(address(this), _user, _amount);
    }

    /**
     * Users must apply in advance and initiate a withdrawal when the withdrawal status is open
     * @param _user user addr
     * @param _amount withdrawa amount
     */
    function withdraw(address _user, uint256 _amount) external override onlyStrategyManager nonReentrant {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }

        if (pendingWithdrawal[_user] != _amount) {
            revert Errors.NoWithdrawalRequested();
        }

        pendingWithdrawal[_user] = 0;
        totalPendingWithdrawal -= _amount;

        _withdraw(_user, _amount);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("CefiStrategy");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }
}
