// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import {Errors} from "src/libraries/Errors.sol";
import "src/interfaces/IDao.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title dao permission contract
 * @author EnzoNetwork
 * @notice This is an abstract contract, although there are no unimplemented functions.
 * This contract is used in other contracts as a basic contract for dao's authority management.
 */
abstract contract Dao is Initializable, IDao {
    address public dao;

    modifier onlyDao() {
        if (msg.sender != dao) revert Errors.PermissionDenied();
        _;
    }

    function __Dao_init(address _dao) internal onlyInitializing {
        dao = _dao;
    }

    function _setDao(address _dao) internal {
        emit DaoChanged(dao, _dao);
        dao = _dao;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
