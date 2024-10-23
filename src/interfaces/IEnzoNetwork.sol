// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IEnzoNetwork {
    function mint(address token, address to, uint256 mintAmount) external;

    event Deposit(address _strategy, address _token, uint256 _mintAmount);
    event MintSecurityAddrChanged(address _oldMintSecurityAddr, address _mintSecurityAddr);
}
