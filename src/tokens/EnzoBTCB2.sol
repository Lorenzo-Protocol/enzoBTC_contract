// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title EnzoNetwork Yield
 * @author EnzoNetwork
 * @notice B2 Yield
 */
contract EnzoBTCB2 is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("EnzoBTC Yield BTC-B2", "enzoBTC-B2", _tokenAdmin, _blackListAdmin)
    {}
}
