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
import "src/TimelockController.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deploy-mainnet.s.sol:MainnetDeployEnzoNetwork  --rpc-url $MAINNET_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract MainnetDeployEnzoNetwork is Script {
    address _dao = 0x125baD0a49D6c2055D6C67707eFB38F88316dFf3;
    address _owner = 0x125baD0a49D6c2055D6C67707eFB38F88316dFf3;
    address fbtc = 0xC96dE26018A54D51c097160568752c4E3BD6C364;
    address btcb = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // address[] memory proposers = new address[](2);
        // address[] memory executors = new address[](1);
        // proposers[0] = 0x3E29BF7B650b8910F3B4DDda5b146e8716c683a6; // nodedao.eth
        // proposers[1] = _dao;
        // executors[0] = _dao;

        // address _owner = address(new TimelockController(3600, proposers, executors, address(0)));
        // console.log("=====timelock=====", address(_owner));

        address _EnzoNetworkImple = address(new EnzoNetwork());
        EnzoNetwork _EnzoNetwork = EnzoNetwork(payable(new ERC1967Proxy(_EnzoNetworkImple, "")));

        console.log("=====EnzoNetwork=====", address(_EnzoNetwork));

        EnzoBTC _enzoBTC = new EnzoBTC(address(_EnzoNetwork), _dao);
        // transfer owner
        _enzoBTC.transferOwnership(_owner);
        console.log("=====enzoBTC=====", address(_enzoBTC));

        address _mintSecurityImple = address(new MintSecurity());
        MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        // address _strategyManagerImple = address(new StrategyManager());
        // StrategyManager _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        // console.log("=====strategyManager=====", address(_strategyManager));

        address btcToken = fbtc;
        if (block.chainid != 1) {
            btcToken = btcb;
        }
        
        address[] memory _mintStrategies = deployMintStrategys(_owner, address(_EnzoNetwork), address(_enzoBTC), btcToken);
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_enzoBTC);
        _EnzoNetwork.initialize(_owner, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_owner, _dao, address(_EnzoNetwork));

        // address fbtc = deployStrategysFBTC(_owner, address(_enzoBTC), address(_strategyManager));
        // address b2 = deployStrategysB2(_owner, address(_enzoBTC), address(_strategyManager));
        // address bbl = deployStrategysBBL(_owner, address(_enzoBTC), address(_strategyManager));
        // address[] memory _strategies = new address[](3);
        // _strategies[0] = address(b2);
        // _strategies[1] = address(bbl);
        // _strategies[2] = address(fbtc);

        // _strategyManager.initialize(_owner, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _ownerAddr, address _EnzoNetwork, address _enzoBTC, address _btcToken)
        internal
        returns (address[] memory)
    {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        
        console.log("=====mintStrategy=====", address(_mintStrategy));
        console.log("=====btc erctoken=====", address(_btcToken));

        _mintStrategy.initialize(_ownerAddr, _dao, address(_EnzoNetwork), address(_btcToken), address(_enzoBTC), 21600); // delay 3 day

        address[] memory _mintStrategies = new address[](1);
        _mintStrategies[0] = address(_mintStrategy);
        return _mintStrategies;
    }

    // function deployStrategysB2(address _ownerAddr, address _enzoBTC, address _strategyManager)
    //     internal
    //     returns (address)
    // {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
    //     EnzoBTCB2 oyBTCb2 = new EnzoBTCB2(address(_defiStrategyB2), _dao);
    //     // transfer owner
    //     oyBTCb2.transferOwnership(_ownerAddr);
    //     console.log("=====nBTCb2=====", address(oyBTCb2));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyB2.initialize(
    //         _ownerAddr,
    //         _dao,
    //         _strategyManager,
    //         _dao,
    //         10000,
    //         10000000000000,
    //         address(_enzoBTC),
    //         address(oyBTCb2),
    //         _whitelistedStrategies
    //     );

    //     return address(_defiStrategyB2);
    // }

    // function deployStrategysBBL(address _ownerAddr, address _enzoBTC, address _strategyManager)
    //     internal
    //     returns (address)
    // {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
    //     EnzoBTCBBN oyBTCbbl = new EnzoBTCBBN(address(_defiStrategyBBL), _dao);
    //     // transfer owner
    //     oyBTCbbl.transferOwnership(_ownerAddr);
    //     console.log("=====nBTCbbl=====", address(oyBTCbbl));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyBBL.initialize(
    //         _ownerAddr,
    //         _dao,
    //         _strategyManager,
    //         _dao,
    //         10000,
    //         10000000000000,
    //         address(_enzoBTC),
    //         address(oyBTCbbl),
    //         _whitelistedStrategies
    //     );

    //     return address(_defiStrategyBBL);
    // }

    // function deployStrategysFBTC(address _ownerAddr, address _enzoBTC, address _strategyManager)
    //     internal
    //     returns (address)
    // {
    //     address _defiStrategyImple = address(new DefiStrategy());
    //     DefiStrategy _defiStrategyFBTC = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
    //     console.log("=====defiStrategyFBTC=====", address(_defiStrategyFBTC));
    //     EnzoBTCFBTC oyBTCfbtc = new EnzoBTCFBTC(address(_defiStrategyFBTC), _dao);
    //     // transfer owner
    //     oyBTCfbtc.transferOwnership(_ownerAddr);
    //     console.log("=====oyBTCfbtc=====", address(oyBTCfbtc));
    //     address[] memory _whitelistedStrategies = new address[](0);
    //     _defiStrategyFBTC.initialize(
    //         _ownerAddr,
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

// forge script script/Deploy-mainnet.s.sol:MainnetDeployEnzoCustody  --rpc-url $MAINNET_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract MainnetDeployEnzoCustody is Script {
    address _dao = 0x8cC49b20c1d8B7129D76ca3E9EFacD968728ca95;
    address _owner = 0xe4c555c2aa8F7FDB7Baf90039b3A583c8E312f20;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _EnzoCustodyImple = address(new EnzoCustody());
        EnzoCustody _EnzoCustody = EnzoCustody(payable(new ERC1967Proxy(_EnzoCustodyImple, "")));

        console.log("=====EnzoCustodyImple=====", address(_EnzoCustody));

        string[] memory marks = new string[](0);
        string[] memory btcAddrs = new string[](0);
        _EnzoCustody.initialize(_owner, _dao, marks, btcAddrs);

        vm.stopBroadcast();
    }
}
