// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract CommitReveal {
    mapping(address => bytes32) public player_commit;
    mapping(address => uint) public player_choice;
    mapping(address => bool) public player_not_played;
    uint public numReveal = 0;

    function commitChoice(bytes32 commitHash) public {
        require(player_not_played[msg.sender], "Already committed");
        player_commit[msg.sender] = commitHash;
        player_not_played[msg.sender] = false;
    }

    function revealChoice(uint choice, string memory salt) public {
        require(!player_not_played[msg.sender], "Must commit first");
        require(keccak256(abi.encodePacked(choice, salt)) == player_commit[msg.sender], "Commit does not match reveal");
        player_choice[msg.sender] = choice;
        numReveal++;
    }

    function resetCommitReveal() public {
        delete player_commit[msg.sender];
        delete player_choice[msg.sender];
        player_not_played[msg.sender] = true;
        numReveal = 0;
    }
}
