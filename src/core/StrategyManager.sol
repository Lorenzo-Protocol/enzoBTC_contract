// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "src/modules/Whitelisted.sol";
import "src/interfaces/IStrategyManager.sol";
import "src/interfaces/IBaseStrategy.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Yield Strategy Manager
 * @author EnzoNetwork
 * @notice Entry to income strategy
 */
contract StrategyManager is Initializable, Version, Dao, Whitelisted, IStrategyManager {
    using SafeERC20 for IERC20;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerAddr, address _dao, address[] calldata _strategies) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);
        __Whitelisted_init(_strategies);
    }

    /**
     * Query which strategies the user has staked
     * @param _user user addr
     * @return strategies
     * @return _shares
     */
    function getStakerStrategyList(address _user) public view returns (address[] memory, uint256[] memory) {
        uint256 _strategyListLength = whitelistedList.length;
        uint256[] memory _sharesList = new uint256[](_strategyListLength);
        uint256 _number = 0;
        for (uint256 i = 0; i < _strategyListLength;) {
            uint256 _share = IBaseStrategy(whitelistedList[i]).getUserShares(_user);
            if (_share != 0) {
                _number++;
            }

            _sharesList[i] = _share;
            unchecked {
                ++i;
            }
        }
        address[] memory _strategies = new address[](_number);
        uint256[] memory _shares = new uint256[](_number);
        uint256 j = 0;
        for (uint256 i = 0; i < _strategyListLength;) {
            if (_sharesList[i] != 0) {
                _strategies[j] = whitelistedList[i];
                _shares[j] = _sharesList[i];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        return (_strategies, _shares);
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
     * Stake assets into strategies to earn
     * @param _strategy stake strategy addr
     * @param _amount stake amount
     */
    function deposit(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkWhitelisted(_strategy);
        address underlyingToken = IBaseStrategy(_strategy).getUnderlyingToken();
        _beforeDeposit(underlyingToken, msg.sender, _strategy, _amount);
        IBaseStrategy(_strategy).deposit(msg.sender, _amount);
        emit UserDeposit(_strategy, msg.sender, _amount, block.number);
    }

    /**
     * Withdrawal Request
     * @param _strategy strategy addr
     * @param _amount withdraw amount
     */
    function requestWithdrawal(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkWhitelisted(_strategy);
        IBaseStrategy(_strategy).requestWithdrawal(msg.sender, _amount);
        emit UserRequestWithdrawal(_strategy, msg.sender, _amount, block.number);
    }

    /**
     * Withdrawal, When the strategy does not require immediate withdrawal,
     * A withdrawal request must be initiated first, such as: CefiStrategy
     * @param _strategy strategy addr
     * @param _amount withdraw amount
     */
    function withdraw(address _strategy, uint256 _amount) external whenNotPaused nonReentrant {
        _checkWhitelisted(_strategy);
        IBaseStrategy(_strategy).withdraw(msg.sender, _amount);
        emit UserWithdrawal(_strategy, msg.sender, _amount, block.number);
    }

    function _beforeDeposit(address underlyingToken, address _user, address _strategy, uint256 _amount) internal {
        IERC20(underlyingToken).safeTransferFrom(_user, _strategy, _amount);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("StrategyManager");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }

    /**
     * @notice stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice start protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }
}
