// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

interface IEnzoCustody {
    event EnzoCustodyAddrAdded(string mark, string btcAddr);
    event EnzoCustodyAddrRemoved(string mark, string btcAddr);
}
