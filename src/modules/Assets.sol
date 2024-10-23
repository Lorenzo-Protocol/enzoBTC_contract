// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IBaseToken.sol";
import "src/interfaces/IAssets.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Asset Management
 * @author EnzoNetwork
 * @notice Provide asset management function module
 */
abstract contract Assets is Initializable, IAssets {
    address[] internal assetList;
    mapping(address => bool) public assetPaused;

    function __Assets_init(address[] calldata _tokenAddrs) internal onlyInitializing {
        for (uint256 i = 0; i < _tokenAddrs.length; ++i) {
            address _token = _tokenAddrs[i];
            _checkAssets(_token);
            assetList.push(_token);
        }
    }

    function getAssetList() public view returns (address[] memory) {
        return assetList;
    }

    function _checkAssets(address _token) internal view {
        if (IBaseToken(_token).tokenAdmin() != address(this)) {
            revert Errors.InvalidAsset();
        }
        if (_isSupportedAsset(_token)) {
            revert Errors.AssetAlreadyExist();
        }
    }

    function _isSupportedAsset(address _token) internal view returns (bool) {
        bool found = false;
        uint256 _length = assetList.length;
        for (uint256 i = 0; i < _length;) {
            if (address(assetList[i]) == _token) {
                found = true;
                break;
            }

            unchecked {
                ++i;
            }
        }

        return found;
    }

    function _isPausedAsset(address _token) internal view returns (bool) {
        return assetPaused[_token];
    }

    function _addAsset(address _token) internal {
        _checkAssets(_token);
        assetList.push(_token);
        emit AssetAdded(_token);
    }

    function _removeAsset(address _token) internal {
        uint256 _length = assetList.length;
        for (uint256 i = 0; i < _length;) {
            if (assetList[i] == _token) {
                assetList[i] = assetList[_length - 1];
                assetList.pop();
                if (assetPaused[_token]) {
                    assetPaused[_token] = false;
                }
                emit AssetRemoved(_token);
                return;
            }
            unchecked {
                ++i;
            }
        }
    }

    function _setAssetStatus(address _token, bool _AssetStatus) internal {
        emit AssetStatusChanged(_AssetStatus);
        assetPaused[_token] = _AssetStatus;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
