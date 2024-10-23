// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title EnzoNetwork Yield
 * @author EnzoNetwork
 * @notice FBTC Yield
 */
contract EnzoBTCFBTC is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("EnzoBTC Yield BTC-FBTC", "enzoBTC-fbtc", _tokenAdmin, _blackListAdmin)
    {}
}
