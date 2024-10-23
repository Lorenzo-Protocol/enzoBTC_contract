// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/strategies/BaseStrategy.sol";

/**
 * @title Defi Strategy
 * @author EnzoNetwork
 * @notice Obtain income through DeFi
 */
contract DefiStrategy is BaseStrategy {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _ownerAddr,
        address _dao,
        address _strategyManager,
        address _fundManager,
        uint256 _floorAmount,
        uint256 _sharesLimit,
        address _underlyingToken,
        address _strategyToken,
        address[] calldata _whitelistedStrategies
    ) public initializer {
        __BaseStrategy_init(
            _ownerAddr,
            _dao,
            _strategyManager,
            _fundManager,
            _floorAmount,
            _underlyingToken,
            _strategyToken,
            _sharesLimit,
            StrategyStatus.Close,
            StrategyStatus.Close,
            _whitelistedStrategies
        );
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("DefiStrategy");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }
}
