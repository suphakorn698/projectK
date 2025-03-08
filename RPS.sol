// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./CommitReveal.sol";
import "./TimeUnit.sol";

contract RPS is CommitReveal, TimeUnit {
    address[4] private allowedPlayers = [
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
        0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,
        0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
    ];

    uint public numPlayer = 0;
    uint public reward = 0;
    address[] public players;

    modifier onlyAllowedPlayers() {
        require(isAllowed(msg.sender), "Not allowed to play");
        _;
    }

    function isAllowed(address player) private view returns (bool) {
        for (uint i = 0; i < allowedPlayers.length; i++) {
            if (allowedPlayers[i] == player) {
                return true;
            }
        }
        return false;
    }

    function addPlayer() public payable onlyAllowedPlayers {
        require(numPlayer < 2, "Game is full");
        require(msg.value == 1 ether, "Must send 1 ETH to play");
        if (numPlayer > 0) {
            require(msg.sender != players[0], "Same player cannot join twice");
        }

        reward += msg.value;
        player_not_played[msg.sender] = true;
        players.push(msg.sender);
        numPlayer++;

        if (numPlayer == 2) {
            setStartTime();  // เริ่มเวลา
        }
    }

    function claimRefund() public onlyAllowedPlayers {
        require(isRevealPhaseOver(), "Refund not available yet");
        require(numReveal < 2, "Game already resolved");

        for (uint i = 0; i < players.length; i++) {
            payable(players[i]).transfer(1 ether);
        }

        resetGame();
    }

    function _checkWinnerAndPay() private {
        uint p0Choice = player_choice[players[0]];
        uint p1Choice = player_choice[players[1]];
        address payable account0 = payable(players[0]);
        address payable account1 = payable(players[1]);

        if ((p0Choice + 1) % 3 == p1Choice) {
            account1.transfer(reward);
        } else if ((p1Choice + 1) % 3 == p0Choice) {
            account0.transfer(reward);
        } else {
            account0.transfer(reward / 2);
            account1.transfer(reward / 2);
        }

        resetGame();
    }

    function resetGame() private {
        delete players;
        numPlayer = 0;
        numReveal = 0;
        reward = 0;
    }
}
