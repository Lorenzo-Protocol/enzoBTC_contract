// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";

/**
 * @title Contract call
 * @author EnzoNetwork
 * @notice Provides contract calling function.
 * Used for fund transfer between DeFi protocols without the need for intermediate account.
 */
abstract contract Call {
    function _execute(uint256 value, address to, bytes memory data, uint256 txGas) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
        if (!success) revert Errors.ExecuteFailed();
    }
}
