// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IBlackList.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Blacklist management
 * @author EnzoNetwork
 * @notice Provides a freezing function when unexpected withdrawals occur, such as withdrawals by attackers
 */
abstract contract BlackList is Initializable, IBlackList {
    mapping(address => bool) public isBlackListed;
    address public blackListAdmin;

    modifier onlyBlackListAdmin() {
        if (msg.sender != blackListAdmin) revert Errors.PermissionDenied();
        _;
    }

    function __BlackList_init(address _blackListAdmin) internal onlyInitializing {
        blackListAdmin = _blackListAdmin;
    }

    function __BlackList_init_OnlyNotSet(address _blackListAdmin) internal {
        if (blackListAdmin == address(0)) {
            blackListAdmin = _blackListAdmin;
        }
    }

    function addBlackList(address _user) external onlyBlackListAdmin {
        isBlackListed[_user] = true;
        emit AddedBlackList(_user);
    }

    function removeBlackList(address _user) external onlyBlackListAdmin {
        isBlackListed[_user] = false;
        emit RemovedBlackList(_user);
    }

    function _setBlackListAdmin(address _blackListAdmin) internal {
        emit BlackListAdminChanged(blackListAdmin, _blackListAdmin);
        blackListAdmin = _blackListAdmin;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
