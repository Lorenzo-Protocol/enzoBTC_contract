// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/core/MintSecurity.sol";

// forge script script/Call-testnet.s.sol:HoleskyCallEnzoNetwork  --rpc-url $HOLESKY_RPC_URL --broadcast
contract HoleskyCallEnzoNetwork is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        MintSecurity mintSecurity = MintSecurity(0x3312C264CE156301D00Ede741c3F07E642c84e32);
        address token = 0x85827757c02c850595d96Df22cd6Ad794d57854C;
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 1000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](2);
        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0xe2135567c8f450e2d2dafe80f193dcfd6060969276a317f28d491271a0788314,
            vs: 0xa7761cdc7eb42bc24d989b90bd682b91d3dcc6e3fe7ad0c79fb15410de0dfc6a
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x40206b106a5a91938b01e645413dae48e5fb3c7b99d605f4e8d66a0fb11784fe,
            vs: 0x76921c93ad395e0bbb972500d730a76e49a5d238b4fbad674501fb0df5d62f7c
        });

        bytes32 msgHash =
            mintSecurity.calcMsgHash(token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount);
        console.logBytes32(msgHash);

        mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );

        vm.stopBroadcast();
    }
}
