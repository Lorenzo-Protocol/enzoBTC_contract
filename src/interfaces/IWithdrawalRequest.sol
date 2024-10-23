// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IWithdrawalRequest {
    event WithdrawalDelayChanged(uint256 _oldWithdrawalDelayBlocks, uint256 _withdrawalDelayBlocks);
    event NativeBTCPausedChanged(bool _oldStatus, bool _status);
    event NonNativeWithdrawalFeeChanged(uint256 _oldNonNativeWithdrawalFee, uint256 _nonNativeWithdrawalFee);
    event WithdrawalsRequest(
        address _token,
        address _receiver,
        uint256 _requestId,
        uint256 _withdrawalAmount,
        bytes _withdrawalAddr,
        uint256 _blockNumber
    );
    event WithdrawalsClaimed(
        address _token,
        address _receiver,
        uint256 _requestId,
        uint256 _claimAmount,
        bytes _withdrawalAddr,
        uint256 _blockNumber
    );
}
