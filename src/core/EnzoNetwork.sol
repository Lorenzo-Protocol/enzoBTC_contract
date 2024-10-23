// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IEnzoNetwork.sol";
import "src/interfaces/IMintStrategy.sol";
import "src/modules/Dao.sol";
import "src/modules/Assets.sol";
import "src/modules/Version.sol";
import "src/modules/Whitelisted.sol";
import "src/modules/WithdrawalRequest.sol";
import "src/interfaces/IMintStrategy.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title EnzoNetwork
 * @author EnzoNetwork
 * @notice Manage asset minting and withdrawals
 */
contract EnzoNetwork is Initializable, Version, Dao, Assets, WithdrawalRequest, Whitelisted, IEnzoNetwork {
    // mintSecurity is responsible for checking the guardian's minting signature
    address public mintSecurityAddr;

    modifier onlyMintSecurity() {
        if (msg.sender != mintSecurityAddr) revert Errors.PermissionDenied();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ownerAddr,
        address _dao,
        address _blackListAdmin,
        address _mintSecurityAddr,
        address[] calldata _tokenAddrs,
        address[] calldata _mintStrategies
    ) public initializer {
        if (
            _ownerAddr == address(0) || _dao == address(0) || _mintSecurityAddr == address(0)
                || _blackListAdmin == address(0)
        ) {
            revert Errors.InvalidAddr();
        }

        __Version_init(_ownerAddr);
        __Dao_init(_dao);
        __Assets_init(_tokenAddrs);
        __WithdrawalRequest_init(50400, _blackListAdmin);
        __Whitelisted_init(_mintStrategies);
        mintSecurityAddr = _mintSecurityAddr;
    }

    /**
     * The user has completed the deposit and the guardians has signed the minting tx
     * @param _token The address of the asset to be minted
     * @param _to The address where the token is received
     * @param _mintAmount mint amount
     */
    function mint(address _token, address _to, uint256 _mintAmount) external onlyMintSecurity {
        // Check if assets are supported
        if (!_isSupportedAsset(_token)) {
            revert Errors.AssetNotSupported();
        }
        // Check if the asset is suspended
        if (_isPausedAsset(_token)) {
            revert Errors.AssetPaused();
        }

        if (_to == address(0)) {
            revert Errors.InvalidAddr();
        }

        IBaseToken(_token).whiteListMint(_mintAmount, _to);
    }

    /**
     * Allow users to deposit assets for minting
     * @param _strategy deposit strategy
     * @param _token The address of the asset to be minted
     * @param _amount deposit amount, when the asset precision is different, _amount may not be the final deposit amount
     */
    function deposit(address _strategy, address _token, uint256 _amount) external whenNotPaused {
        _checkWhitelisted(_strategy);
        address _user = msg.sender;
        uint256 _mintAmount = IMintStrategy(_strategy).deposit(_token, _user, _amount);
        IBaseToken(_token).whiteListMint(_mintAmount, _user);
        emit Deposit(_strategy, _token, _mintAmount);
    }

    /**
     * User application for withdrawing underlying assets
     * @param _strategy deposit strategy
     * @param _token he address of the asset to be minted
     * @param _withdrawalAmount withdrawal amount, enzoBTC amount
     * @param _withdrawalAddr withdrawal addr, if the _strategy is not nativeBTCStrategy, it can be empty
     */
    function requestWithdrawals(
        address _strategy,
        address _token,
        uint256 _withdrawalAmount,
        bytes memory _withdrawalAddr
    ) external payable whenNotPaused {
        if (_strategy != nativeWithdrawStrategy) {
            // If it is a deposit strategy, check whether the strategy address is recognized
            _checkWhitelisted(_strategy);
            if (nonNativeWithdrawalFee != msg.value) {
                // Check whether the handling fee is prepaid
                revert Errors.InvalidAmount();
            }

            (, IMintStrategy.StrategyStatus _withdrawStatus) = IMintStrategy(_strategy).getStrategyStatus();
            if (_withdrawStatus != IMintStrategy.StrategyStatus.Open) {
                revert Errors.StrategyBTCWithdrawPaused();
            }
        } else {
            // If it is a native withdrawal, check whether it is suspended
            if (nativeWithdrawPaused) {
                revert Errors.NativeBTCWithdrawPaused();
            }
            // There is no pre-collection fee for native withdrawals, and the fee will be charged on the BTC chain
            if (msg.value != 0) {
                revert Errors.InvalidAmount();
            }
        }

        // Check if the token is supported
        if (!_isSupportedAsset(_token)) {
            revert Errors.AssetNotSupported();
        }

        address _sender = msg.sender;
        bool ok = IBaseToken(_token).transferFrom(_sender, address(this), _withdrawalAmount);
        if (!ok) {
            revert Errors.TransferFailed();
        }
        // _withdrawalAmount is enzoBTC amount, decimals is 8
        _requestWithdrawals(_strategy, _token, _sender, _withdrawalAmount, _withdrawalAddr);
    }

    /**
     * Batch claim to satisfy delayed withdrawal requests
     * @param _receivers receiver addr
     * @param _requestIds withdrawal request id
     */
    function bulkClaimWithdrawals(address[] memory _receivers, uint256[][] memory _requestIds) external {
        uint256 bulkLen = _receivers.length;
        if (bulkLen != _requestIds.length) {
            revert Errors.InvalidLength();
        }

        for (uint256 i = 0; i < bulkLen; ++i) {
            claimWithdrawals(_receivers[i], _requestIds[i]);
        }
    }

    /**
     * claim to satisfy delayed withdrawal requests
     * @param _receiver receiver addr
     * @param _requestIds withdrawal request id
     */
    function claimWithdrawals(address _receiver, uint256[] memory _requestIds) public whenNotPaused nonReentrant {
        for (uint256 i = 0; i < _requestIds.length; ++i) {
            uint256 _requestId = _requestIds[i];

            (uint256 _withdrawalAmount, address _token) = _claimWithdrawals(_receiver, _requestId);
            IBaseToken(_token).whiteListBurn(_withdrawalAmount, address(this));
        }
    }

    /**
     * Adding supported assets
     * @param _token asset addr
     */
    function addAsset(address _token) external onlyDao {
        _addAsset(_token);
    }

    /**
     * Remove supported assets
     *  @param _token asset addr
     */
    function removeAsset(address _token) external onlyDao {
        _removeAsset(_token);
    }

    /**
     * Whether to suspend or re-support assets
     * @param _token asset addr
     * @param _AssetStatus asset status
     */
    function setAssetStatus(address _token, bool _AssetStatus) external onlyDao {
        _setAssetStatus(_token, _AssetStatus);
    }

    /**
     * Set up blacklist administrators to handle abnormal withdrawals
     * Such as withdrawals initiated by attackers
     * @param _blackListAdmin blackList admin
     */
    function setBlackListAdmin(address _blackListAdmin) external onlyDao {
        _setBlackListAdmin(_blackListAdmin);
    }

    /**
     * Set delay block for native withdrawals
     * @param _withdrawalDelayBlocks withdrawal delay block
     */
    function setWithdrawalDelayBlocks(uint256 _withdrawalDelayBlocks) public onlyDao {
        _setWithdrawalDelayBlocks(_withdrawalDelayBlocks);
    }

    /**
     * Set nonNativeWithdrawalFee
     * @param _nonNativeWithdrawalFee nonNativeWithdrawal fee
     * @notice Non-native withdrawal pre-collection fee, used to help users automatically claim
     * There is no pre-collection fee for native withdrawals, and the fee will be charged on the BTC chain
     */
    function setNonNativeWithdrawalFee(uint256 _nonNativeWithdrawalFee) public onlyDao {
        _setNonNativeWithdrawalFee(_nonNativeWithdrawalFee);
    }

    /**
     * Set the state of native withdrawal
     * @param _status withdrawal status
     */
    function setNativeBTCPausedStatus(bool _status) public onlyDao {
        _setNativeBTCPaused(_status);
    }

    /**
     * Add deposit strategy
     * @param _strategies deposit strategies
     */
    function addStrategyWhitelisted(address[] calldata _strategies) external onlyDao {
        _addWhitelisted(_strategies);
    }

    /**
     * Remove strategy
     * @param _strategies deposit strategies
     */
    function removeStrategyWhitelisted(address[] calldata _strategies) external onlyDao {
        _removeWhitelisted(_strategies);
    }

    /**
     * change mintSecurityAddr
     * @param _mintSecurityAddr mintSecurity contract address
     */
    function setMintSecurityAddr(address _mintSecurityAddr) external onlyDao {
        emit MintSecurityAddrChanged(mintSecurityAddr, _mintSecurityAddr);
        mintSecurityAddr = _mintSecurityAddr;
    }

    /**
     * Owner set dao addr
     * @param _dao dao addr
     */
    function setDao(address _dao) public onlyOwner {
        _setDao(_dao);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("EnzoNetwork");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }

    /**
     * @notice stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice start protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }
}
