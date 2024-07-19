// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IObeliskNetwork.sol";
import "src/interfaces/IMintStrategy.sol";
import "src/modules/Dao.sol";
import "src/modules/Assets.sol";
import "src/modules/Version.sol";
import "src/modules/Strategy.sol";
import "src/modules/WithdrawalRequest.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract ObeliskNetwork is Initializable, Version, Dao, Assets, WithdrawalRequest, Strategy, IObeliskNetwork {
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
        address[] memory _tokenAddrs,
        address[] calldata _mintStrategies
    ) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);
        __Assets_init(_tokenAddrs);
        __WithdrawalRequest_init(50400, _blackListAdmin);
        __Strategy_init(_mintStrategies);
        mintSecurityAddr = _mintSecurityAddr;
    }

    function mint(address _token, address _to, uint256 _mintAmount) external onlyMintSecurity {
        if (!_isSupportedAsset(_token)) {
            revert Errors.AssetNotSupported();
        }
        if (_isPausedAsset(_token)) {
            revert Errors.AssetPaused();
        }

        IBaseToken(_token).whiteListMint(_mintAmount, _to);
    }

    function deposit(address _strategy, address _token, uint256 _amount) external whenNotPaused {
        _checkStrategiesWhitelisted(_strategy);
        address _user = msg.sender;
        uint256 _mintAmount = IMintStrategy(_strategy).deposit(_token, _user, _amount);
        IBaseToken(_token).whiteListMint(_mintAmount, _user);
        emit Deposit(_strategy, _token, _mintAmount);
    }

    function requestWithdrawals(
        address _strategy,
        address _token,
        uint256 _withdrawalAmount,
        bytes memory _withdrawalAddr // If the _strategy is not nativeBTCStrategy, it can be empty
    ) external whenNotPaused {
        if (_strategy != nativeBTCStrategy) {
            _checkStrategiesWhitelisted(_strategy);
        } else {
            if (nativeBTCPaused) {
                revert Errors.NativeBTCPaused();
            }
        }

        if (!_isSupportedAsset(_token)) {
            revert Errors.AssetNotSupported();
        }

        address _sender = msg.sender;
        bool ok = IBaseToken(_token).transferFrom(_sender, address(this), _withdrawalAmount);
        if (!ok) {
            revert Errors.TransferFailed();
        }
        _requestWithdrawals(_strategy, _token, _sender, _withdrawalAmount, _withdrawalAddr);
    }

    function bulkClaimWithdrawals(address[] memory _receivers, uint256[][] memory _requestIds) external {
        uint256 bulkLen = _receivers.length;
        if (bulkLen != _requestIds.length) {
            revert Errors.InvalidLength();
        }

        for (uint256 i = 0; i < bulkLen; ++i) {
            claimWithdrawals(_receivers[i], _requestIds[i]);
        }
    }

    function claimWithdrawals(address _receiver, uint256[] memory _requestIds) public whenNotPaused {
        for (uint256 i = 0; i < _requestIds.length; ++i) {
            uint256 _requestId = _requestIds[i];

            (uint256 _withdrawalAmount, address _token) = _claimWithdrawals(_receiver, _requestId);
            IBaseToken(_token).whiteListBurn(_withdrawalAmount, address(this));
        }
    }

    function addAsset(address _token) external onlyDao {
        _addAsset(_token);
    }

    function removeAsset(address _token) external onlyDao {
        _removeAsset(_token);
    }

    function setAssetStatus(address _token, bool _status) external onlyDao {
        _setAssetStatus(_token, _status);
    }

    function setBlackListAdmin(address _blackListAdmin) external onlyDao {
        _setBlackListAdmin(_blackListAdmin);
    }

    function setWithdrawalDelayBlocks(uint256 _withdrawalDelayBlocks) public onlyDao {
        _setWithdrawalDelayBlocks(_withdrawalDelayBlocks);
    }

    function setNativeBTCPausedStatus(bool _status) public onlyDao {
        _setNativeBTCPaused(_status);
    }

    function addStrategies(address[] calldata _strategies) external onlyDao {
        _addStrategies(_strategies);
    }

    function removeStrategies(address[] calldata _strategies) external onlyDao {
        _removeStrategies(_strategies);
    }

    function setDao(address _dao) public onlyOwner {
        _setDao(_dao);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("ObeliskNetwork");
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
