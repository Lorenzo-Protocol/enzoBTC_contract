// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/modules/Whitelisted.sol";
import "src/modules/Call.sol";
import "src/interfaces/IBaseToken.sol";
import "src/interfaces/IBaseStrategy.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Provide basic staking strategy
 * @author EnzoNetwork
 * @notice When the strategy does not set strategyToken, the user deposit is recorded through the state
 */
abstract contract BaseStrategy is Initializable, Version, Dao, Whitelisted, Call, IBaseStrategy {
    using SafeERC20 for IERC20;

    address public strategyManager;

    address public fundManager;
    uint256 public floorAmount;
    uint256 public sharesLimit;

    StrategyStatus internal depositStatus;
    StrategyStatus internal withdrawStatus;

    address internal underlyingToken;

    address public strategyToken;
    mapping(address => uint256) internal userShares;
    uint256 public totalShares;

    modifier onlyStrategyManager() {
        if (msg.sender != strategyManager) revert Errors.PermissionDenied();
        _;
    }

    modifier onlyFundManager() {
        if (msg.sender != fundManager) revert Errors.PermissionDenied();
        _;
    }

    function __BaseStrategy_init(
        address _ownerAddr,
        address _dao,
        address _strategyManager,
        address _fundManager,
        uint256 _floorAmount,
        address _underlyingToken,
        address _strategyToken,
        uint256 _sharesLimit,
        StrategyStatus _depositStatus,
        StrategyStatus _withdrawStatus,
        address[] calldata _whitelistedStrategies
    ) internal onlyInitializing {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);

        __Whitelisted_init(_whitelistedStrategies);
        strategyManager = _strategyManager;
        fundManager = _fundManager;
        floorAmount = _floorAmount;
        underlyingToken = _underlyingToken;
        if (_strategyToken != address(0)) {
            strategyToken = _strategyToken;
        }
        depositStatus = _depositStatus;
        withdrawStatus = _withdrawStatus;
        sharesLimit = _sharesLimit;
    }

    function getUnderlyingToken() external view returns (address) {
        return underlyingToken;
    }

    /**
     * Get the deposit and withdrawal status of the strategy
     * @return _depositStatus
     * @return _withdrawStatus
     */
    function getStrategyStatus() public view returns (StrategyStatus _depositStatus, StrategyStatus _withdrawStatus) {
        return (depositStatus, withdrawStatus);
    }

    /**
     * setStrategyStatus
     * @param _depositStatus deposit status
     * @param _withdrawStatus  withdrawal status
     */
    function setStrategyStatus(StrategyStatus _depositStatus, StrategyStatus _withdrawStatus)
        external
        onlyFundManager
    {
        if (_depositStatus != depositStatus) {
            emit DepositStatusChanged(depositStatus, _depositStatus);
            depositStatus = _depositStatus;
        }
        if (_withdrawStatus != withdrawStatus) {
            emit WithdrawalStatusChanged(withdrawStatus, _withdrawStatus);
            withdrawStatus = _withdrawStatus;
        }
    }

    /**
     * Set strategy parameters
     * @param _strategyManager strategy manager
     * @param _fundManager  strategy fund manager
     * @param _floorAmount Minimum stake amount
     * @param _sharesLimit The maximum amount that the strategy allows to receive
     */
    function setStrategySetting(
        address _strategyManager,
        address _fundManager,
        uint256 _floorAmount,
        uint256 _sharesLimit
    ) external onlyDao {
        if (_strategyManager != address(0)) {
            emit StrategyManagerChanged(strategyManager, _strategyManager);
            strategyManager = _strategyManager;
        }
        if (_fundManager != address(0)) {
            emit FundManagerChanged(fundManager, _fundManager);
            fundManager = _fundManager;
        }
        if (_floorAmount != 0) {
            emit FloorAmountChanged(floorAmount, _floorAmount);
            floorAmount = _floorAmount;
        }
        if (_sharesLimit != 0) {
            emit SharesLimitChanged(sharesLimit, _sharesLimit);
            sharesLimit = _sharesLimit;
        }
    }

    function deposit(address _user, uint256 _amount) external onlyStrategyManager nonReentrant {
        if (_amount < floorAmount) {
            revert Errors.InvalidAmount();
        }

        if (totalShares + _amount > sharesLimit) {
            revert Errors.ExceedDepositLimit();
        }

        if (depositStatus != StrategyStatus.Open) {
            revert Errors.DepositNotOpen();
        }

        _addShares(_user, _amount);

        emit Deposit(address(this), _user, _amount);
    }

    /**
     * User Withdrawal
     * @param _user user addr
     * @param _amount withdrawal amount
     */
    function requestWithdrawal(address _user, uint256 _amount) external virtual onlyStrategyManager {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }

        _withdraw(_user, _amount);
    }

    /**
     * User Withdrawal
     * @param _user user addr
     * @param _amount withdrawa amount
     */
    function withdraw(address _user, uint256 _amount) external virtual onlyStrategyManager {
        if (withdrawStatus != StrategyStatus.Open) {
            revert Errors.WithdrawalNotOpen();
        }

        _withdraw(_user, _amount);
    }

    function _withdraw(address _user, uint256 _amount) internal {
        _removeShares(_user, _amount);
        _transfer(_user, _amount);
        emit Withdrawal(address(this), _user, _amount);
    }

    function _transfer(address _user, uint256 _amountToSend) internal {
        IERC20(underlyingToken).safeTransfer(_user, _amountToSend);
    }

    function _addShares(address _user, uint256 _amount) internal {
        totalShares += _amount;

        if (strategyToken == address(0)) {
            userShares[_user] += _amount;
            return;
        }

        IBaseToken(strategyToken).whiteListMint(_amount, _user);
    }

    function _removeShares(address _user, uint256 _amount) internal {
        totalShares -= _amount;

        if (strategyToken == address(0)) {
            userShares[_user] -= _amount;
            return;
        }

        IBaseToken(strategyToken).whiteListBurn(_amount, _user);
    }

    /**
     * Query user stake amount
     * @param _user user addr
     */
    function getUserShares(address _user) external view returns (uint256) {
        if (strategyToken == address(0)) {
            return userShares[_user];
        }

        return IERC20(strategyToken).balanceOf(_user);
    }

    /**
     * The _to parameter must be pre-set to a whitelist.
     * Used for fund transfer between DeFi protocols without the need for intermediate account.
     */
    function execute(uint256 _value, address _to, bytes memory _data, uint256 _txGas) external onlyDao {
        _checkWhitelisted(_to);
        _execute(_value, _to, _data, _txGas);
        emit TxExecuted(_value, _to, _data);
    }

    /**
     * Add deposit strategy
     * @param _strategies deposit strategies
     */
    function addStrategyWhitelisted(address[] calldata _strategies) external onlyDao {
        _addWhitelisted(_strategies);
    }

    /**
     * Remove strategy
     * @param _strategies deposit strategies
     */
    function removeStrategyWhitelisted(address[] calldata _strategies) external onlyDao {
        _removeWhitelisted(_strategies);
    }

    /**
     * Owner set dao addr
     * @param _dao dao addr
     */
    function setDao(address _dao) public onlyOwner {
        _setDao(_dao);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
