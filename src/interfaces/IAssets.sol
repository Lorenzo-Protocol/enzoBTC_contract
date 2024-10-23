// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IAssets {
    event AssetAdded(address _token);
    event AssetRemoved(address _token);
    event AssetStatusChanged(bool _status);
}
