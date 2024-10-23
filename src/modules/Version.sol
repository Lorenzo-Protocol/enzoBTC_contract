// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Errors} from "src/libraries/Errors.sol";
import "src/interfaces/IVersion.sol";

/**
 * @title Version management contract
 * @author EnzoNetwork
 * @notice Encapsulates the basic functions of
 * UUPSUpgradeable contract,
 * OwnableUpgradeable contract,
 * PausableUpgradeable contract,
 * and ReentrancyGuardUpgradeable contract.
 */
abstract contract Version is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    function __Version_init(address _ownerAddr) internal onlyInitializing {
        _transferOwnership(_ownerAddr);
        __UUPSUpgradeable_init();
        __Pausable_init();
    }

    /**
     * @notice When upgrading the contract,
     * it is required that the typeid of the contract must be constant and version +1.
     */
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {
        if (IVersion(newImplementation).typeId() != typeId()) {
            revert Errors.InvalidtypeId();
        }
        if (IVersion(newImplementation).version() != version() + 1) {
            revert Errors.InvalidVersion();
        }
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure virtual returns (bytes32);

    /**
     * @notice Contract version
     */
    function version() public pure virtual returns (uint8);

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
