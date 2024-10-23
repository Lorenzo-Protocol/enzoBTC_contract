// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/EnzoBTC.sol";
import "src/tokens/EnzoBTCB2.sol";
import "src/tokens/EnzoBTCBBN.sol";
import {TestToken, TestToken2, TestStrategy} from "test/TestContract.sol";
import "src/core/EnzoNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import "src/interfaces/IBaseStrategy.sol";
import "src/interfaces/IMintStrategy.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EnzoNetworkTest is Test {
    address _dao = address(1000);
    address _ownerAddr = address(1001);
    address _blackListAdmin = address(1003);
    address _fundManager = address(1004);

    EnzoBTC public _enzoBTC;
    EnzoNetwork public _EnzoNetwork;
    StrategyManager public _strategyManager;
    MintSecurity public _mintSecurity;
    DefiStrategy public _defiStrategyB2;
    DefiStrategy public _defiStrategyBBL;
    MintStrategy public _mintStrategy;
    TestToken public _testBTC;
    MintStrategy public _mintStrategy2;
    TestToken2 public _testBTC2;

    function setUp() public {
        address _EnzoNetworkImple = address(new EnzoNetwork());
        _EnzoNetwork = EnzoNetwork(payable(new ERC1967Proxy(_EnzoNetworkImple, "")));

        console.log("=====enzoBTC=====", address(_EnzoNetwork));

        _enzoBTC = new EnzoBTC(address(_EnzoNetwork), _dao);

        console.log("=====enzoBTC=====", address(_enzoBTC));

        address _mintSecurityImple = address(new MintSecurity());
        _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address _strategyManagerImple = address(new StrategyManager());
        _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        console.log("=====strategyManager=====", address(_strategyManager));

        address _mintStrategyImple = address(new MintStrategy());
        _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        _testBTC = new TestToken("test BTC", "tBTC", _dao, _dao);
        _mintStrategy.initialize(_ownerAddr, _dao, address(_EnzoNetwork), address(_testBTC), address(_enzoBTC), 50400);

        _mintStrategy2 = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        _testBTC2 = new TestToken2("test BTC 2", "tBTC2", _dao, _dao);
        _mintStrategy2.initialize(_ownerAddr, _dao, address(_EnzoNetwork), address(_testBTC2), address(_enzoBTC), 50400);

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_enzoBTC);
        address[] memory _mintStrategies = new address[](2);
        _mintStrategies[0] = address(_mintStrategy);
        _mintStrategies[1] = address(_mintStrategy2);
        _EnzoNetwork.initialize(_ownerAddr, _dao, _blackListAdmin, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_ownerAddr, _dao, address(_EnzoNetwork));
        // MINT_MESSAGE_PREFIX 0x5706b75259dd61ada5d917cc9b0e797d76b00ca645bc55beb09d4c8ff153ec16
        console.logBytes32(_mintSecurity.MINT_MESSAGE_PREFIX());

        address[] memory _guardians = new address[](3);
        _guardians[0] = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;
        _guardians[1] = 0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5;
        _guardians[2] = 0xd7189759502ec8bb475e707aCB1C6A4D210e0214;
        vm.prank(address(_dao));
        _mintSecurity.addGuardians(_guardians, 3);

        address[] memory _strategies = deployStrategys();
        _strategyManager.initialize(_ownerAddr, _dao, _strategies);
    }

    function deployStrategys() internal returns (address[] memory) {
        address _defiStrategyImple = address(new DefiStrategy());
        _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        EnzoBTCB2 nBTCb2 = new EnzoBTCB2(address(_defiStrategyB2), _dao);
        EnzoBTCBBN nBTCbbl = new EnzoBTCBBN(address(_defiStrategyBBL), _dao);
        console.log("=====nBTCb2=====", address(nBTCb2));
        console.log("=====nBTCbbl=====", address(nBTCbbl));

        address[] memory _whitelistedStrategies = new address[](0);
        _defiStrategyB2.initialize(
            _ownerAddr,
            _dao,
            address(_strategyManager),
            _fundManager,
            10000,
            10000000000000,
            address(_enzoBTC),
            address(nBTCb2),
            _whitelistedStrategies
        );
        _defiStrategyBBL.initialize(
            _ownerAddr,
            _dao,
            address(_strategyManager),
            _fundManager,
            10000,
            10000000000000,
            address(_enzoBTC),
            address(nBTCbbl),
            _whitelistedStrategies
        );

        vm.prank(_fundManager);
        _defiStrategyBBL.setStrategyStatus(IBaseStrategy.StrategyStatus.Open, IBaseStrategy.StrategyStatus.Close);
        vm.prank(_fundManager);
        _defiStrategyB2.setStrategyStatus(IBaseStrategy.StrategyStatus.Open, IBaseStrategy.StrategyStatus.Close);

        address[] memory _strategies = new address[](2);
        _strategies[0] = address(_defiStrategyB2);
        _strategies[1] = address(_defiStrategyBBL);
        return _strategies;
    }

    function testMint() public {
        address token = address(_enzoBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](3);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        sortedGuardianSignatures[2] = MintSecurity.Signature({
            r: 0x0a323c499c5f3ba1508119b3d29ee063c26a3312dad38dda7912f4a34a10aab7,
            vs: 0x7620506989779ce6e5ea47624de9d3dfd9d83411174178e8d7aab83793fe75f8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );

        assertEq(_enzoBTC.balanceOf(destAddr), stakingAmount);
    }

    function testBulkMint() public {
        address[] memory tokens = new address[](1);
        bytes32[] memory txHashs = new bytes32[](1);
        address[] memory destAddrs = new address[](1);
        uint256[] memory stakingOutputIdxs = new uint256[](1);
        uint256[] memory inclusionHeights = new uint256[](1);
        uint256[] memory stakingAmounts = new uint256[](1);
        MintSecurity.Signature[][] memory bulkSortedGuardianSignatures = new MintSecurity.Signature[][](1);

        address token = address(_enzoBTC);
        tokens[0] = token;
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        txHashs[0] = txHash;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        destAddrs[0] = destAddr;
        uint256 stakingOutputIdx = 0;
        stakingOutputIdxs[0] = stakingOutputIdx;
        uint256 inclusionHeight = 2865235;
        inclusionHeights[0] = inclusionHeight;
        uint256 stakingAmount = 120000000;
        stakingAmounts[0] = stakingAmount;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](3);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        sortedGuardianSignatures[2] = MintSecurity.Signature({
            r: 0x0a323c499c5f3ba1508119b3d29ee063c26a3312dad38dda7912f4a34a10aab7,
            vs: 0x7620506989779ce6e5ea47624de9d3dfd9d83411174178e8d7aab83793fe75f8
        });
        bulkSortedGuardianSignatures[0] = sortedGuardianSignatures;

        _mintSecurity.bulkMint(
            tokens,
            txHashs,
            destAddrs,
            stakingOutputIdxs,
            inclusionHeights,
            stakingAmounts,
            bulkSortedGuardianSignatures
        );

        assertEq(_enzoBTC.balanceOf(destAddr), stakingAmount);
    }

    function testFailMint() public {
        vm.prank(address(_dao));
        _mintSecurity.pause();
        testMint();
    }

    function testFailMint2() public {
        address token = address(_enzoBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](3);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[2] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x0a323c499c5f3ba1508119b3d29ee063c26a3312dad38dda7912f4a34a10aab7,
            vs: 0x7620506989779ce6e5ea47624de9d3dfd9d83411174178e8d7aab83793fe75f8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testFailMint3() public {
        address token = address(_enzoBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](2);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testMint4() public {
        vm.prank(address(_dao));
        _mintSecurity.setGuardianQuorum(2);
        address token = address(_enzoBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](2);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testFailRequestWithdraws() public {
        testMint();
        bytes memory _to = bytes("0xd6027dfc74fa9b2cffb447ee1b372ed6ba45ae615992b54a6fb3b11cb6e3a491");
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _EnzoNetwork.requestWithdrawals(0x000000000000000000000000000000000000000b, address(_enzoBTC), 10000, _to);
    }

    function testRequestWithdraws() public {
        testMint();
        bytes memory _to = bytes("0xd6027dfc74fa9b2cffb447ee1b372ed6ba45ae615992b54a6fb3b11cb6e3a491");
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _enzoBTC.approve(address(_EnzoNetwork), 10000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _EnzoNetwork.requestWithdrawals(0x000000000000000000000000000000000000000b, address(_enzoBTC), 10000, _to);
    }

    function testFailPauseRequestWithdraws() public {
        vm.prank(address(_dao));
        _EnzoNetwork.pause();

        testRequestWithdraws();
    }

    function testClaimWithdrawals() public {
        testRequestWithdraws();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailPauseClaimWithdrawals() public {
        testRequestWithdraws();

        vm.prank(address(_dao));
        _EnzoNetwork.pause();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailClaimWithdrawals() public {
        testRequestWithdraws();

        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailClaimWithdrawals2() public {
        testRequestWithdraws();
        testAddBlackList();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testClaimWithdrawals2() public {
        testRequestWithdraws();
        testAddBlackList();
        testRemoveBlackList();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testAddBlackList() public {
        vm.prank(_blackListAdmin);
        _EnzoNetwork.addBlackList(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        assertTrue(_EnzoNetwork.isBlackListed(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8));
    }

    function testRemoveBlackList() public {
        vm.prank(_blackListAdmin);
        _EnzoNetwork.removeBlackList(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        assertTrue(!_EnzoNetwork.isBlackListed(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8));
    }

    function testFailSetBlackListAdmin() public {
        _EnzoNetwork.setBlackListAdmin(address(1));
    }

    function testSetBlackListAdmin() public {
        vm.prank(_dao);
        _EnzoNetwork.setBlackListAdmin(address(1));
        assertEq(_EnzoNetwork.blackListAdmin(), address(1));
    }

    function testFailAddAsset() public {
        vm.prank(_dao);
        _EnzoNetwork.addAsset(address(1));
    }

    function testSetWithdrawalDelayBlocks() public {
        assertEq(_EnzoNetwork.withdrawalDelayBlocks(), 50400);
        vm.prank(_dao);
        _EnzoNetwork.setWithdrawalDelayBlocks(20);
        assertEq(_EnzoNetwork.withdrawalDelayBlocks(), 20);
    }

    function testFailSetWithdrawalDelayBlocks() public {
        vm.prank(_dao);
        _EnzoNetwork.setWithdrawalDelayBlocks(72001);
    }

    function testGetGuardianQuorum() public {
        assertEq(_mintSecurity.getGuardianQuorum(), 3);
        vm.prank(_dao);
        _mintSecurity.setGuardianQuorum(2);
        assertEq(_mintSecurity.getGuardianQuorum(), 2);
    }

    function testGetGuardians() public view {
        address[] memory _guardians = _mintSecurity.getGuardians();
        assertEq(_guardians[0], 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc);
        assertEq(_guardians[1], 0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5);
        assertEq(_guardians[2], 0xd7189759502ec8bb475e707aCB1C6A4D210e0214);
        assertTrue(_mintSecurity.isGuardian(0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc));
        assertTrue(_mintSecurity.isGuardian(0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5));
        assertTrue(_mintSecurity.isGuardian(0xd7189759502ec8bb475e707aCB1C6A4D210e0214));
        assertEq(_mintSecurity.getGuardianIndex(0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc), 0);
        assertEq(_mintSecurity.getGuardianIndex(0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5), 1);
        assertEq(_mintSecurity.getGuardianIndex(0xd7189759502ec8bb475e707aCB1C6A4D210e0214), 2);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), -1);
    }

    function testFailAddGuardian() public {
        _mintSecurity.addGuardian(address(1), 4);
    }

    function testAddGuardian() public {
        vm.prank(_dao);
        _mintSecurity.addGuardian(address(1), 4);
        assertEq(_mintSecurity.getGuardianQuorum(), 4);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), 3);
    }

    function testFailremoveGuardian() public {
        testAddGuardian();
        _mintSecurity.removeGuardian(address(1), 3);
    }

    function testFailremoveGuardian2() public {
        testAddGuardian();
        vm.prank(_dao);
        _mintSecurity.removeGuardian(address(2), 3);
    }

    function testremoveGuardian() public {
        testAddGuardian();
        vm.prank(_dao);
        _mintSecurity.removeGuardian(address(1), 3);
        assertEq(_mintSecurity.getGuardianQuorum(), 3);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), -1);
    }

    function testGetStrategyList() public view {
        address[] memory strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 2);
        assertEq(address(_defiStrategyB2), strategyList[0]);
        assertEq(address(_defiStrategyBBL), strategyList[1]);
    }

    function testAddStrategies() public {
        address[] memory _strategies = deployStrategys();
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), false);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), false);

        vm.prank(_dao);
        _strategyManager.addStrategyWhitelisted(_strategies);
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), true);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), true);
        address[] memory strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 4);

        vm.prank(_dao);
        _strategyManager.removeStrategyWhitelisted(_strategies);
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), false);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), false);
        strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 2);
    }

    function testDeposit() public {
        testMint();
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _enzoBTC.approve(address(_strategyManager), 100000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyB2), 100000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _enzoBTC.approve(address(_strategyManager), 100000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyBBL), 100000);
        assertEq(_enzoBTC.balanceOf(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8), 120000000 - 100000 * 2);
    }

    function testFailDeposit() public {
        testMint();
        vm.prank(_fundManager);
        _defiStrategyBBL.setStrategyStatus(IBaseStrategy.StrategyStatus.Close, IBaseStrategy.StrategyStatus.Close);
        vm.prank(_fundManager);
        _defiStrategyB2.setStrategyStatus(IBaseStrategy.StrategyStatus.Close, IBaseStrategy.StrategyStatus.Close);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _enzoBTC.approve(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _enzoBTC.approve(address(_defiStrategyBBL), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyBBL), 100000);
        assertEq(_enzoBTC.balanceOf(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8), 120000000 - 100000 * 2);
    }

    function testFailWithdrawal() public {
        testDeposit();
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.withdraw(address(_defiStrategyBBL), 100000);
    }

    function testWithdrawal() public {
        testDeposit();
        vm.prank(_fundManager);
        _defiStrategyBBL.setStrategyStatus(IBaseStrategy.StrategyStatus.Open, IBaseStrategy.StrategyStatus.Open);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.withdraw(address(_defiStrategyBBL), 100000);
    }

    function testTBTCDeposit() public {
        vm.prank(_dao);
        _testBTC.whiteListMint(10000000000, address(1));
        vm.prank(address(1));
        _testBTC.approve(address(_mintStrategy), 100000000);

        vm.prank(address(1));
        _EnzoNetwork.deposit(address(_mintStrategy), address(_enzoBTC), 100000000);

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 100000000);
    }

    function testTBTCDeposit2() public {
        vm.prank(_dao);
        _testBTC2.whiteListMint(100000000000000000000, address(1));
        vm.prank(address(1));
        _testBTC2.approve(address(_mintStrategy2), 1000000000000000000);

        vm.prank(address(1));
        _EnzoNetwork.deposit(address(_mintStrategy2), address(_enzoBTC), 1000000000000000000);

        assertEq(_testBTC2.balanceOf(address(_mintStrategy2)), 1000000000000000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 100000000);
    }

    function testTBTCWithdrawal() public {
        testTBTCDeposit();
        vm.prank(address(1));
        _enzoBTC.approve(address(_EnzoNetwork), 100000000);
        vm.prank(address(1));
        _EnzoNetwork.requestWithdrawals(address(_mintStrategy), address(_enzoBTC), 100000000, "0x");

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testFailTBTCWithdrawal() public {
        testTBTCDeposit();
        vm.prank(address(1));
        _enzoBTC.approve(address(_EnzoNetwork), 100000000);

        vm.prank(_dao);
        _mintStrategy.setStrategyStatus(IMintStrategy.StrategyStatus.Open, IMintStrategy.StrategyStatus.Close);
        vm.prank(address(1));
        _EnzoNetwork.requestWithdrawals(address(_mintStrategy), address(_enzoBTC), 100000000, "0x");

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testTBTCWithdrawal2() public {
        testTBTCDeposit2();
        vm.prank(address(1));
        _enzoBTC.approve(address(_EnzoNetwork), 100000000);
        vm.prank(address(1));
        _EnzoNetwork.requestWithdrawals(address(_mintStrategy2), address(_enzoBTC), 100000000, "0x");
        assertEq(_testBTC2.balanceOf(address(_mintStrategy2)), 1000000000000000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testTBTCClaim() public {
        vm.prank(_dao);
        _mintStrategy.setStrategyStatus(IMintStrategy.StrategyStatus.Open, IMintStrategy.StrategyStatus.Open);
        testTBTCWithdrawal();
        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(address(1), _requestIds);
        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 0);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testTBTCClaim2() public {
        vm.prank(_dao);
        _mintStrategy2.setStrategyStatus(IMintStrategy.StrategyStatus.Open, IMintStrategy.StrategyStatus.Open);
        testTBTCWithdrawal2();
        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _EnzoNetwork.claimWithdrawals(address(1), _requestIds);
        assertEq(_testBTC2.balanceOf(address(_mintStrategy2)), 0);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testTBTCClaim3() public {
        vm.prank(_dao);
        _mintStrategy.setStrategyStatus(IMintStrategy.StrategyStatus.Open, IMintStrategy.StrategyStatus.Open);
        vm.prank(_dao);
        _mintStrategy2.setStrategyStatus(IMintStrategy.StrategyStatus.Open, IMintStrategy.StrategyStatus.Open);

        testTBTCWithdrawal();
        testTBTCWithdrawal2();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](2);
        _requestIds[0] = 0;
        _requestIds[1] = 1;
        _EnzoNetwork.claimWithdrawals(address(1), _requestIds);

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 0);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
        assertEq(_testBTC2.balanceOf(address(_mintStrategy2)), 0);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
    }

    function testExecute() public {
        TestStrategy _strategy = new TestStrategy(address(_testBTC));
        address[] memory _strategies = new address[](2);
        _strategies[0] = address(_strategy);
        _strategies[1] = address(_testBTC);
        vm.prank(_dao);
        _mintStrategy.addStrategyWhitelisted(_strategies);

        testTBTCDeposit();

        vm.prank(_dao);
        _mintStrategy.execute(
            0, address(_testBTC), abi.encodeWithSelector(ERC20.approve.selector, address(_strategy), 100000000), 200000
        );

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);

        vm.prank(_dao);
        _mintStrategy.execute(
            0, address(_strategy), abi.encodeWithSelector(TestStrategy.deposit.selector, 100000000), 200000
        );

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 0);
        assertEq(_testBTC.balanceOf(address(_strategy)), 100000000);
    }

    function testSetStrategyWhitelisted() public {
        address[] memory _strategies = new address[](2);
        _strategies[0] = address(1);
        _strategies[1] = address(2);
        vm.prank(_dao);
        _mintStrategy.addStrategyWhitelisted(_strategies);
        assertEq(_mintStrategy.isWhitelisted(address(1)), true);
        assertEq(_mintStrategy.isWhitelisted(address(2)), true);
        assertEq(_mintStrategy.isWhitelisted(address(3)), false);
        assertEq(_mintStrategy.getWhitelistedList().length, 2);
        assertEq(_mintStrategy.getWhitelistedList()[0], address(1));
        assertEq(_mintStrategy.getWhitelistedList()[1], address(2));

        _strategies[0] = address(1);
        _strategies[1] = address(3);
        vm.prank(_dao);
        _mintStrategy.addStrategyWhitelisted(_strategies);
        assertEq(_mintStrategy.isWhitelisted(address(1)), true);
        assertEq(_mintStrategy.isWhitelisted(address(2)), true);
        assertEq(_mintStrategy.isWhitelisted(address(3)), true);
        assertEq(_mintStrategy.getWhitelistedList().length, 3);
        assertEq(_mintStrategy.getWhitelistedList()[0], address(1));
        assertEq(_mintStrategy.getWhitelistedList()[1], address(2));
        assertEq(_mintStrategy.getWhitelistedList()[2], address(3));

        _strategies[0] = address(0);
        _strategies[1] = address(4);
        vm.prank(_dao);
        _mintStrategy.addStrategyWhitelisted(_strategies);
        assertEq(_mintStrategy.isWhitelisted(address(0)), true);
        assertEq(_mintStrategy.isWhitelisted(address(1)), true);
        assertEq(_mintStrategy.isWhitelisted(address(2)), true);
        assertEq(_mintStrategy.isWhitelisted(address(3)), true);
        assertEq(_mintStrategy.isWhitelisted(address(4)), true);
        assertEq(_mintStrategy.getWhitelistedList().length, 5);
        assertEq(_mintStrategy.getWhitelistedList()[0], address(1));
        assertEq(_mintStrategy.getWhitelistedList()[1], address(2));
        assertEq(_mintStrategy.getWhitelistedList()[2], address(3));
        assertEq(_mintStrategy.getWhitelistedList()[3], address(0));
        assertEq(_mintStrategy.getWhitelistedList()[4], address(4));

        _strategies[0] = address(0);
        _strategies[1] = address(4);
        vm.prank(_dao);
        _mintStrategy.removeStrategyWhitelisted(_strategies);
        assertEq(_mintStrategy.isWhitelisted(address(0)), false);
        assertEq(_mintStrategy.isWhitelisted(address(1)), true);
        assertEq(_mintStrategy.isWhitelisted(address(2)), true);
        assertEq(_mintStrategy.isWhitelisted(address(3)), true);
        assertEq(_mintStrategy.isWhitelisted(address(4)), false);
        assertEq(_mintStrategy.getWhitelistedList().length, 3);
        assertEq(_mintStrategy.getWhitelistedList()[0], address(1));
        assertEq(_mintStrategy.getWhitelistedList()[1], address(2));
        assertEq(_mintStrategy.getWhitelistedList()[2], address(3));
    }

    function testGetStakerStrategyList() public {
        testDeposit();
        (address[] memory addrs, uint256[] memory amounts) =
            _strategyManager.getStakerStrategyList(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        assertEq(addrs.length, 2);
        assertEq(amounts.length, 2);
        assertEq(addrs[0], address(_defiStrategyB2));
        assertEq(amounts[0], 100000);
        assertEq(addrs[1], address(_defiStrategyBBL));
        assertEq(amounts[1], 100000);
    }

    function testTokenBlackList() public {
        vm.prank(address(_EnzoNetwork));
        _enzoBTC.whiteListMint(100000000000, address(1));
        vm.prank(address(_EnzoNetwork));
        _enzoBTC.whiteListMint(100000000000, address(2));

        assertEq(_enzoBTC.balanceOf(address(1)), 100000000000);
        vm.prank(_dao);
        _enzoBTC.addBlackList(address(1));
        assertEq(true, _enzoBTC.isBlackListed(address(1)));
        assertEq(false, _enzoBTC.isBlackListed(address(2)));
    }

    function testFailTokenBlackList2() public {
        testTokenBlackList();
        vm.prank(address(1));
        _enzoBTC.transfer(address(2), 10000);
    }

    function testFailTokenBlackList3() public {
        testTokenBlackList();
        vm.prank(address(2));
        _enzoBTC.transfer(address(1), 10000);
    }

    function testChangeTokenAdmin() public {
        assertEq(_enzoBTC.blackListAdmin(), _dao);
        _enzoBTC.setBlackListAdmin(address(1));
        assertEq(_enzoBTC.blackListAdmin(), address(1));
    }

    function testTotalWithdrawalAmount() public {
        testTBTCDeposit();

        vm.prank(address(1));
        _enzoBTC.approve(address(_EnzoNetwork), 100000000);
        address _nativeBTC = _EnzoNetwork.nativeWithdrawStrategy();
        vm.prank(address(1));
        _EnzoNetwork.requestWithdrawals(_nativeBTC, address(_enzoBTC), 100000000, "0x");

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);
        assertEq(_enzoBTC.balanceOf(address(1)), 0);
        assertEq(_EnzoNetwork.totalWithdrawalAmount(address(_nativeBTC)), 100000000);
        assertEq(_EnzoNetwork.totalWithdrawalAmount(address(_mintStrategy)), 0);
    }
}
