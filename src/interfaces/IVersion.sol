// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IVersion {
    function typeId() external pure returns (bytes32);

    function version() external pure returns (uint8);

    function implementation() external view returns (address);
}
