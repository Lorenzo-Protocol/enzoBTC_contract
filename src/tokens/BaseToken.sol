// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "src/interfaces/IBaseToken.sol";
import {Errors} from "src/libraries/Errors.sol";
import "src/modules/BlackList.sol";

/**
 * @title Provide basic token functions
 * @author EnzoNetwork
 * @notice tokenAdmin has the right to mint and burn tokens.
 * blackListAdmin has the right to set blacklists.
 */
abstract contract BaseToken is ERC20, Ownable, BlackList, IBaseToken {
    address public tokenAdmin;

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin) revert Errors.PermissionDenied();
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenAdmin, address _blackListAdmin)
        ERC20(_tokenName, _tokenSymbol)
    {
        tokenAdmin = _tokenAdmin;
        __BlackList_init_OnlyNotSet(_blackListAdmin);
    }

    /**
     * decimals 8, The native precision of BTC is 8
     */
    function decimals() public pure virtual override returns (uint8) {
        return 8;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if (msg.sender == tokenAdmin) {
            return;
        }

        if (isBlackListed[from] || isBlackListed[to]) {
            revert Errors.BlackListed();
        }
    }

    /**
     * @notice mint
     * @param _amount mint amount
     * @param _account mint account
     */
    function whiteListMint(uint256 _amount, address _account) external onlyTokenAdmin {
        if (_account == address(0)) revert Errors.InvalidAddr();
        _mint(_account, _amount);
    }

    /**
     * @notice burn
     * @param _amount burn amount
     * @param _account burn account
     */
    function whiteListBurn(uint256 _amount, address _account) external onlyTokenAdmin {
        if (_account == address(0)) revert Errors.InvalidAddr();
        _burn(_account, _amount);
    }

    function changeTokenAdmin(address _tokenAdmin) public onlyOwner {
        emit TokenAdminChanged(tokenAdmin, _tokenAdmin);
        tokenAdmin = payable(_tokenAdmin);
    }

    function setBlackListAdmin(address _blackListAdmin) public onlyOwner {
        _setBlackListAdmin(_blackListAdmin);
    }
}
