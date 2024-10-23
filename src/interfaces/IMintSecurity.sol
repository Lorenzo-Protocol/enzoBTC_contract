// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IMintSecurity {
    event GuardianQuorumChanged(uint256 newValue);
    event GuardianAdded(address guardian);
    event GuardianRemoved(address guardian);
    event EnzoNetworkChanged(address _oldEnzoNetwork, address _EnzoNetwork);
    event TokenMinted(
        bytes32 indexed msgHash,
        bytes32 txHash,
        address token,
        address destAddr,
        uint256 stakingOutputIdx,
        uint256 inclusionHeight,
        uint256 stakingAmount
    );
}
