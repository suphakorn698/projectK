1. ป้องกันการล็อคเงินในสัญญา
โค้ดนี้จะป้องกันการล็อคเงินในสัญญาด้วยกลไกดังนี้:

Refund Mechanism (Claim Refund): หากเกมไม่สามารถดำเนินการได้ (เช่น ผู้เล่นไม่สามารถ commit หรือ reveal ในเวลาที่กำหนด) ฟังก์ชัน claimRefund จะช่วยให้ผู้เล่นทั้งสองสามารถขอคืนเงินที่ฝากไว้ได้

solidity
Copy
Edit
function claimRefund() public onlyAllowedPlayers {
    require(isRevealPhaseOver(), "Refund not available yet");
    require(numReveal < 2, "Game already resolved");

    for (uint i = 0; i < players.length; i++) {
        payable(players[i]).transfer(1 ether);
    }

    resetGame();
}
Reset เกม: เมื่อเกมสิ้นสุดหรือการขอคืนเงินเสร็จสิ้น ฟังก์ชัน resetGame จะถูกเรียกเพื่อเคลียร์ข้อมูลของผู้เล่นและรีเซ็ตสถานะของเกม เพื่อให้แน่ใจว่าไม่มีเงินคงค้างในสัญญาหลังจากที่เกมสิ้นสุด

solidity
Copy
Edit
function resetGame() private {
    delete players;
    numPlayer = 0;
    numReveal = 0;
    reward = 0;


2. การซ่อนตัวเลือกและการ commit (Commit-Then-Reveal)
เพื่อป้องกันไม่ให้ผู้เล่นสามารถเปลี่ยนแปลงตัวเลือกหลังจากเห็นตัวเลือกของฝ่ายตรงข้าม ระบบนี้ใช้ commit-reveal scheme ซึ่งเป็นวิธีที่ช่วยให้การเล่นยุติธรรม:

Commitment Phase: ผู้เล่นจะ commit ตัวเลือกของตนโดยการส่ง hash ซึ่งสร้างขึ้นจากการผสมระหว่างตัวเลือกและ "salt" การ commit นี้จะถูกเก็บไว้เป็นความลับจนกว่าจะถึงช่วงเวลาการเปิดเผย

solidity
Copy
Edit
function commitChoice(bytes32 commitHash) public onlyAllowedPlayers {
    require(player_not_played[msg.sender], "Already committed");
    player_commit[msg.sender] = commitHash;
    player_not_played[msg.sender] = false;
}
การใช้ hash ในการ commit จะช่วยซ่อนตัวเลือกของผู้เล่น และการใช้ salt จะช่วยให้แต่ละ commit มีความแตกต่างและไม่สามารถคำนวณล่วงหน้าได้
Reveal Phase: ในช่วงการเปิดเผย ผู้เล่นจะต้องเปิดเผยตัวเลือกจริงของตนและ salt ที่ใช้ในการ commit โค้ดจะตรวจสอบว่า hash ที่ผู้เล่นเปิดเผยตรงกับ commit ที่เก็บไว้หรือไม่ หากตรงกัน ตัวเลือกของผู้เล่นจะได้รับการยอมรับ

solidity
Copy
Edit
function revealChoice(uint choice, string memory salt) public onlyAllowedPlayers {
    require(!player_not_played[msg.sender], "Must commit first");
    require(keccak256(abi.encodePacked(choice, salt)) == player_commit[msg.sender], "Commit does not match reveal");
    player_choice[msg.sender] = choice;
    numReveal++;
}
ระบบนี้ช่วยป้องกันไม่ให้ผู้เล่นเปลี่ยนแปลงตัวเลือกหลังจากเห็นตัวเลือกของฝ่ายตรงข้าม ซึ่งทำให้เกมมีความยุติธรรม

3. การจัดการกับการล่าช้าและเกมที่ไม่สมบูรณ์
เพื่อจัดการกับกรณีที่ผู้เล่นไม่เข้าร่วมในเวลา ผู้เล่นที่ล่าช้าจะไม่สามารถเข้าร่วมเกมได้:

Commitment Deadline: ผู้เล่นจะมีเวลา 5 นาทีในการ commit ตัวเลือก หากผู้เล่นคนใดไม่สามารถ commit ได้ภายในเวลานี้ เกมจะไม่สามารถดำเนินการต่อได้ และผู้เล่นสามารถขอคืนเงินได้

solidity
Copy
Edit
function isCommitPhaseOver() public view returns (bool) {
    return block.timestamp > startTime + commitDeadline;
}
Reveal Deadline: หลังจากที่ทั้งสองผู้เล่นได้ commit แล้ว พวกเขาจะมีเวลาอีก 5 นาทีในการเปิดเผยตัวเลือก หากผู้เล่นไม่เปิดเผยภายในเวลานี้ เกมจะไม่สามารถแก้ไขได้และสามารถขอคืนเงินได้

solidity
Copy
Edit
function isRevealPhaseOver() public view returns (bool) {
    return block.timestamp > startTime + commitDeadline + revealDeadline;
}

4. การเปิดเผยตัวเลือกและการตัดสินผู้ชนะ
เมื่อทั้งสองผู้เล่น commit และเปิดเผยตัวเลือกแล้ว สัญญาจะเปรียบเทียบตัวเลือกและตัดสินผู้ชนะ:

กติกาของเกม Rock, Paper, Scissors คือ:

Rock ชนะ Scissors
Scissors ชนะ Paper
Paper ชนะ Rock
หากผู้เล่นทั้งสองเลือกเหมือนกัน จะเป็นการเสมอและรางวัลจะถูกแบ่งเท่าๆ กันระหว่างทั้งสอง

solidity
Copy
Edit
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
หาก Player 0 เลือก Rock และ Player 1 เลือก Scissors, Player 0 ชนะ
หาก Player 1 เลือก Rock และ Player 0 เลือก Scissors, Player 1 ชนะ
หากทั้งสองเลือกเหมือนกัน เกมจะเสมอและรางวัลจะถูกแบ่งเท่าๆ กัน
