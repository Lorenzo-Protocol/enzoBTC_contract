// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title enzoBTC
 * @author EnzoNetwork
 * @notice enzoBTC: Lorenzo Wrapped Bitcoin
 */
contract EnzoBTC is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("Lorenzo Wrapped Bitcoin", "enzoBTC", _tokenAdmin, _blackListAdmin)
    {}
}
