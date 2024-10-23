// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/EnzoBTC.sol";
import {TestToken, TestToken2} from "test/TestContract.sol";
import "src/tokens/EnzoBTCB2.sol";
import "src/tokens/EnzoBTCBBN.sol";
import "src/tokens/EnzoBTCFBTC.sol";
import "src/core/EnzoNetwork.sol";
import "src/core/EnzoCustody.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deploy-testnet.s.sol:HoleskyDeployEnzoNetwork  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract HoleskyDeployEnzoNetwork is Script {
    address _dao = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _EnzoNetworkImple = address(new EnzoNetwork());
        EnzoNetwork _EnzoNetwork = EnzoNetwork(payable(new ERC1967Proxy(_EnzoNetworkImple, "")));

        console.log("=====EnzoNetwork=====", address(_EnzoNetwork));

        EnzoBTC _enzoBTC = new EnzoBTC(address(_EnzoNetwork), _dao);
        console.log("=====oBTC=====", address(_enzoBTC));

        address _mintSecurityImple = address(new MintSecurity());
        MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        // address _strategyManagerImple = address(new StrategyManager());
        // StrategyManager _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        // console.log("=====strategyManager=====", address(_strategyManager));

        address[] memory _mintStrategies = deployMintStrategys(address(_EnzoNetwork), address(_enzoBTC));
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_enzoBTC);
        _EnzoNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_dao, _dao, address(_EnzoNetwork));

        // address fbtc = deployStrategysFBTC(address(_enzoBTC), address(_strategyManager));
        // address b2 = deployStrategysB2(address(_enzoBTC), address(_strategyManager));
        // address bbl = deployStrategysBBL(address(_enzoBTC), address(_strategyManager));
        // address[] memory _strategies = new address[](3);
        // _strategies[0] = address(b2);
        // _strategies[1] = address(bbl);
        // _strategies[2] = address(fbtc);

        // _strategyManager.initialize(_dao, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _EnzoNetwork, address _enzoBTC) internal returns (address[] memory) {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        MintStrategy _mintStrategy2 = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        console.log("=====mintStrategy=====", address(_mintStrategy));
        console.log("=====mintStrategy2=====", address(_mintStrategy2));

        address _testBTC = address(new TestToken("test BTC", "tBTC", _dao, _dao));
        _mintStrategy.initialize(_dao, _dao, address(_EnzoNetwork), address(_testBTC), address(_enzoBTC), 10);
        address _testBTC2 = address(new TestToken2("test BTC18", "tBTC18", _dao, _dao));
        _mintStrategy2.initialize(_dao, _dao, address(_EnzoNetwork), address(_testBTC2), address(_enzoBTC), 10);

        console.log("=====testBTC=====", address(_testBTC));
        console.log("=====testBTC2=====", address(_testBTC2));

        address[] memory _mintStrategies = new address[](2);
        _mintStrategies[0] = address(_mintStrategy);
        _mintStrategies[1] = address(_mintStrategy2);
        return _mintStrategies;
    }

    // function deployStrategysB2(address _enzoBTC, address _strategyManager) internal returns (address) {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
    //     EnzoBTCB2 nBTCb2 = new EnzoBTCB2(address(_defiStrategyB2), _dao);
    //     console.log("=====nBTCb2=====", address(nBTCb2));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyB2.initialize(
    //         _dao,
    //         _dao,
    //         _strategyManager,
    //         _dao,
    //         10000,
    //         10000000000000,
    //         address(_enzoBTC),
    //         address(nBTCb2),
    //         _whitelistedStrategies
    //     );

    //     return address(_defiStrategyB2);
    // }

    // function deployStrategysBBL(address _enzoBTC, address _strategyManager) internal returns (address) {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
    //     EnzoBTCBBN nBTCbbl = new EnzoBTCBBN(address(_defiStrategyBBL), _dao);
    //     console.log("=====nBTCbbl=====", address(nBTCbbl));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyBBL.initialize(
    //         _dao,
    //         _dao,
    //         _strategyManager,
    //         _dao,
    //         10000,
    //         10000000000000,
    //         address(_enzoBTC),
    //         address(nBTCbbl),
    //         _whitelistedStrategies
    //     );

    //     return address(_defiStrategyBBL);
    // }

    // function deployStrategysFBTC(address _enzoBTC, address _strategyManager) internal returns (address) {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyFBTC = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyFBTC=====", address(_defiStrategyFBTC));
    //     EnzoBTCFBTC oyBTCfbtc = new EnzoBTCFBTC(address(_defiStrategyFBTC), _dao);
    //     console.log("=====oyBTCfbtc=====", address(oyBTCfbtc));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyFBTC.initialize(
    //         _dao,
    //         _dao,
    //         _strategyManager,
    //         _dao,
    //         10000,
    //         10000000000000,
    //         address(_enzoBTC),
    //         address(oyBTCfbtc),
    //         _whitelistedStrategies
    //     );

    //     return address(_defiStrategyFBTC);
    // }
}

// forge script script/Deploy-testnet.s.sol:HoleskyDeployEnzoCustody  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract HoleskyDeployEnzoCustody is Script {
    address _dao = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _EnzoCustodyImple = address(new EnzoCustody());
        EnzoCustody _EnzoCustody = EnzoCustody(payable(new ERC1967Proxy(_EnzoCustodyImple, "")));

        console.log("=====EnzoCustodyImple=====", address(_EnzoCustody));

        string[] memory marks = new string[](1);
        marks[0] = "custody";
        string[] memory btcAddrs = new string[](1);
        btcAddrs[0] = "tb1qdlexklc4kq8nzntqkkay06zyjfu790jsuj3wxr";
        _EnzoCustody.initialize(_dao, _dao, marks, btcAddrs);

        vm.stopBroadcast();
    }
}
