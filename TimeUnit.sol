// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract TimeUnit {
    uint public startTime;
    uint public commitDeadline = 5 minutes;
    uint public revealDeadline = 5 minutes;

    function setStartTime() public {
        startTime = block.timestamp;
    }

    function isCommitPhaseOver() public view returns (bool) {
        return block.timestamp > startTime + commitDeadline;
    }

    function isRevealPhaseOver() public view returns (bool) {
        return block.timestamp > startTime + commitDeadline + revealDeadline;
    }
}
