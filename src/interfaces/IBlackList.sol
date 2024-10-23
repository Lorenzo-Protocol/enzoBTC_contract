// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IBlackList {
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    event BlackListAdminChanged(address _oldAdmin, address _admin);
}
