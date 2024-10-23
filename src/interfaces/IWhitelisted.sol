// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IWhitelisted {
    event AddedToWhitelist(address _addr);
    event RemovedFromWhitelist(address _addr);
}
