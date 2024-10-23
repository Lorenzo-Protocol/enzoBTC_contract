// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IBaseToken is IERC20 {
    function whiteListMint(uint256 _amount, address _account) external;

    function whiteListBurn(uint256 _amount, address _account) external;

    function tokenAdmin() external view returns (address);

    event TokenAdminChanged(address _oldTokenAdmin, address _tokenAdmin);
}
