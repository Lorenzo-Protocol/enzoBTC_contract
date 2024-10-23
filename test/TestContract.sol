// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract TestToken is BaseToken {
    constructor(string memory _name, string memory _symbol, address _tokenAdmin, address _blackListAdmi)
        BaseToken(_name, _symbol, _tokenAdmin, _blackListAdmi)
    {}
}

contract TestToken2 is BaseToken {
    constructor(string memory _name, string memory _symbol, address _tokenAdmin, address _blackListAdmi)
        BaseToken(_name, _symbol, _tokenAdmin, _blackListAdmi)
    {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}

contract TestStrategy {
    using SafeERC20 for IERC20;

    IERC20 public token;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function deposit(uint256 _amount) public {
        _deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) internal {
        token.safeTransferFrom(_user, address(this), _amount);
    }
}
