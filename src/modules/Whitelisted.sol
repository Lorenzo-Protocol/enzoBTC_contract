// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IWhitelisted.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Whitelisted Management
 * @author EnzoNetwork
 * @notice Provides management strategy functions
 */
abstract contract Whitelisted is Initializable, IWhitelisted {
    mapping(address => bool) public isWhitelisted;
    address[] internal whitelistedList;

    function _checkWhitelisted(address _strategy) internal view {
        if (!isWhitelisted[_strategy]) revert Errors.StrategyNotWhitelisted();
    }

    function __Whitelisted_init(address[] calldata _strategies) internal onlyInitializing {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            address _strategy = _strategies[i];
            if (_strategy == address(0)) {
                revert Errors.InvalidAddr();
            }
            if (isWhitelisted[_strategy]) {
                revert Errors.DuplicateStrategy();
            }
            isWhitelisted[_strategy] = true;
            whitelistedList.push(_strategy);
            emit AddedToWhitelist(_strategy);
            unchecked {
                ++i;
            }
        }
    }

    function getWhitelistedList() public view returns (address[] memory) {
        return whitelistedList;
    }

    function _addWhitelisted(address[] calldata _strategies) internal {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            if (!isWhitelisted[_strategies[i]]) {
                isWhitelisted[_strategies[i]] = true;
                whitelistedList.push(_strategies[i]);
                emit AddedToWhitelist(_strategies[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _removeWhitelisted(address[] calldata _strategies) internal {
        uint256 strategiesLength = _strategies.length;
        for (uint256 i = 0; i < strategiesLength;) {
            if (isWhitelisted[_strategies[i]]) {
                isWhitelisted[_strategies[i]] = false;
                _removeSlice(_strategies[i]);
                emit RemovedFromWhitelist(_strategies[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _removeSlice(address _strategy) internal {
        uint256 _whitelistedListLength = whitelistedList.length;
        for (uint256 i = 0; i < _whitelistedListLength;) {
            if (whitelistedList[i] == _strategy) {
                whitelistedList[i] = whitelistedList[_whitelistedListLength - 1];
                whitelistedList.pop();
                return;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
