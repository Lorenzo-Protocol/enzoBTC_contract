// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title EnzoNetwork Yield
 * @author EnzoNetwork
 * @notice Babylon Yield
 */
contract EnzoBTCBBN is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("EnzoBTC Yield BTC-BBN", "enzoBTC-BBN", _tokenAdmin, _blackListAdmin)
    {}
}
