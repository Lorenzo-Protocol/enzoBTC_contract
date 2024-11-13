// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IMintableBurnable {
    function whiteListMint(uint256 _amount, address _account) external;
    function whiteListBurn(uint256 _amount, address _account) external;
}
