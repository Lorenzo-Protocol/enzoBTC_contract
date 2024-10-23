// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/interfaces/IEnzoCustody.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title EnzoNetwork custodial BTC address disclosure
 * @author EnzoNetwork
 */
contract EnzoCustody is Initializable, Version, Dao, IEnzoCustody {
    struct AddrInfo {
        string mark;
        string btcAddr;
    }

    AddrInfo[] internal addrInfos;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerAddr, address _dao, string[] calldata marks, string[] calldata btcAddrs)
        public
        initializer
    {
        if (_ownerAddr == address(0) || _dao == address(0)) {
            revert Errors.InvalidAddr();
        }
        if (marks.length != btcAddrs.length) {
            revert Errors.InvalidAddr();
        }

        __Version_init(_ownerAddr);
        __Dao_init(_dao);

        for (uint256 i = 0; i < marks.length; ++i) {
            addrInfos.push(AddrInfo({mark: marks[i], btcAddr: btcAddrs[i]}));
            emit EnzoCustodyAddrAdded(marks[i], btcAddrs[i]);
        }
    }

    function getEnzoCustodyAddrInfo() external view returns (AddrInfo[] memory) {
        return addrInfos;
    }

    function addEnzoCustodyAddr(string calldata mark, string calldata btcAddr) external onlyDao {
        if (
            keccak256(abi.encodePacked(mark)) == keccak256(abi.encodePacked(""))
                || keccak256(abi.encodePacked(btcAddr)) == keccak256(abi.encodePacked(""))
        ) {
            revert Errors.InvalidParameter();
        }

        addrInfos.push(AddrInfo({mark: mark, btcAddr: btcAddr}));

        emit EnzoCustodyAddrAdded(mark, btcAddr);
    }

    function removeEnzoCustodyAddr(uint256 index) external onlyDao {
        if (index > addrInfos.length) {
            revert Errors.InvalidParameter();
        }

        AddrInfo memory addrInfo = addrInfos[index];
        addrInfos[index] = addrInfos[addrInfos.length - 1];
        addrInfos.pop();

        emit EnzoCustodyAddrRemoved(addrInfo.mark, addrInfo.btcAddr);
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("EnzoCustody");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }

    /**
     * @notice stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice start protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }

    /**
     * Owner set dao addr
     * @param _dao dao addr
     */
    function setDao(address _dao) public onlyOwner {
        _setDao(_dao);
    }
}
