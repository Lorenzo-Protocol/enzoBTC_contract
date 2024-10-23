// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/core/EnzoCustody.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EnzoCustodyTest is Test {
    address _dao = address(1000);
    address _ownerAddr = address(1001);

    EnzoCustody public custody;

    function setUp() public {
        address _custodyImple = address(new EnzoCustody());

        custody = EnzoCustody(payable(new ERC1967Proxy(_custodyImple, "")));

        console.log("=====custody=====", address(custody));

        string[] memory marks = new string[](1);
        string[] memory btcAddrs = new string[](1);
        marks[0] = "mpc";
        btcAddrs[0] = "bc1qpde26qq28svk87knnnxa2vuucnsql40ec4522s";
        custody.initialize(_ownerAddr, _dao, marks, btcAddrs);
    }

    function testGetEnzoCustodyAddrInfo() public view {
        EnzoCustody.AddrInfo[] memory _addrInfos = custody.getEnzoCustodyAddrInfo();
        for (uint256 i = 0; i < _addrInfos.length; ++i) {
            console.log(i, "====mark====", _addrInfos[i].mark);
            console.log(i, "====btcAddr====", _addrInfos[i].btcAddr);
        }
    }

    function testFailAddEnzoCustodyAddr() public {
        custody.addEnzoCustodyAddr("mpc2", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
    }

    function testFailAddEnzoCustodyAddr2() public {
        vm.prank(_dao);
        custody.addEnzoCustodyAddr("", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
    }

    function testFailAddEnzoCustodyAddr3() public {
        vm.prank(_dao);
        custody.addEnzoCustodyAddr("mpc2", "");
    }

    function testAddEnzoCustodyAddr() public {
        vm.prank(_dao);
        custody.addEnzoCustodyAddr("mpc2", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
        testGetEnzoCustodyAddrInfo();
    }

    function testFailRemoveEnzoCustodyAddr() public {
        custody.removeEnzoCustodyAddr(1);
    }

    function testFailRemoveEnzoCustodyAddr2() public {
        vm.prank(_dao);
        custody.removeEnzoCustodyAddr(1);
    }

    function testRemoveEnzoCustodyAddr() public {
        vm.prank(_dao);
        custody.removeEnzoCustodyAddr(0);
        console.log("========testRemoveEnzoCustodyAddr==========");
        testGetEnzoCustodyAddrInfo();
    }

    function testRemoveEnzoCustodyAddr2() public {
        testAddEnzoCustodyAddr();
        vm.prank(_dao);
        custody.removeEnzoCustodyAddr(0);
        console.log("========testRemoveEnzoCustodyAddr2==========");
        testGetEnzoCustodyAddrInfo();
    }
}
