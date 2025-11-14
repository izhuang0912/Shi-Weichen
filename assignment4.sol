// 统一编译器版本：适配所有合约，避免版本冲突
pragma solidity ^0.5.1;

/**
 * 问题4：ERC20 标准接口
 * 定义 ERC20 代币必须实现的函数和事件
 */
interface ERC20 {
    // 核心查询函数
    function totalSupply() external view returns (uint256); // 总供应量
    function balanceOf(address who) external view returns (uint256); // 地址余额
    function allowance(address owner, address spender) external view returns (uint256); // 授权额度

    // 核心操作函数
    function transfer(address to, uint256 value) external returns (bool); // 直接转账
    function approve(address spender, uint256 value) external returns (bool); // 授权
    function transferFrom(address from, address to, uint256 value) external returns (bool); // 授权转账

    // 强制触发事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * 问题4：XYZCoin 代币合约（实现 ERC20 接口）
 * 代币信息：名称 XYZCoin，符号 XYZ，0 小数位，总供应量 1000 枚
 */
contract XYZCoin is ERC20 {
    // 代币元数据
    string public name = "XYZCoin";
    string public symbol = "XYZ";
    uint8 public decimals = 0; // 无小数，1 枚 = 1 单位
    uint256 public totalSupply = 1000; // 固定总供应量

    // 状态变量：余额映射 + 授权映射
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    // 构造函数：部署者获得全部代币
    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    // -------------------------- 实现 ERC20 接口 --------------------------
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "余额不足");

        // 检查-效果-交互模式：先更新状态，再触发事件
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value, "余额不足");
        require(allowed[from][msg.sender] >= value, "授权额度不足");

        // 检查-效果-交互模式：先更新状态，再触发事件
        balances[from] -= value;
        allowed[from][msg.sender] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);

        return true;
    }
}

/**
 * 问题2：修复重入漏洞的投票合约
 * 核心功能：购买选票、投票、赎回选票、结束投票
 * 修复点：遵循「检查-效果-交互」模式，防止重入攻击
 */
contract VotingContract {
    // 状态变量
    address public owner; // 合约所有者
    bool public votingEnded; // 投票是否结束
    mapping(address => uint256) public remainingVotes; // 用户剩余选票（1 ETH = 1e18 选票）
    mapping(uint256 => uint256) public candidates; // 候选人 ID → 得票数
    uint256 public candidateCount; // 候选人总数

    // 访问控制 modifier
    modifier notEnded() {
        require(!votingEnded, "投票已结束");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "非合约所有者");
        _;
    }

    // 构造函数：初始化所有者和候选人数量
    constructor(uint256 _candidateCount) public {
        require(_candidateCount > 0, "候选人数量必须大于0");
        owner = msg.sender;
        candidateCount = _candidateCount;
        votingEnded = false;
    }

    /**
     * 1. 购买选票
     * 逻辑：用户发送 ETH，按 1 ETH = 1e18 选票发放，多余 ETH 退还
     */
    function buyVotes() public payable notEnded {
        require(msg.value > 0, "必须发送 ETH 购买选票");
        uint256 votes = msg.value; // 1 ETH = 1e18 wei = 1e18 选票
        remainingVotes[msg.sender] += votes;

        // 退还多余 ETH（若用户发送的 ETH 超出预期，可选逻辑）
        uint256 excess = msg.value - votes;
        if (excess > 0) {
            msg.sender.transfer(excess);
        }
    }

    /**
     * 2. 投票
     * 修复：先更新选票余额和候选人得票，再执行后续逻辑（无外部转账，防重入）
     */
    function vote(uint256 _candidateId) public notEnded {
        // 检查：候选人 ID 有效 + 选票充足（1 票 = 1e18 单位）
        require(_candidateId > 0 && _candidateId <= candidateCount, "无效的候选人 ID");
        require(remainingVotes[msg.sender] >= 1e18, "选票不足");

        // 效果：更新状态（核心修复：移到外部交互前）
        remainingVotes[msg.sender] -= 1e18;
        candidates[_candidateId] += 1e18;
    }

    /**
     * 3. 赎回未使用选票
     * 修复：先扣除用户选票，再转账（遵循检查-效果-交互）
     */
    function payoutVotes(uint256 _amount) public notEnded {
        // 检查：赎回数量有效 + 选票充足
        require(_amount > 0, "赎回数量必须大于0");
        require(remainingVotes[msg.sender] >= _amount, "选票不足");

        // 效果：更新状态（核心修复：移到 transfer 前）
        remainingVotes[msg.sender] -= _amount;

        // 交互：转账（1 选票 = 1 wei，对应 1 ETH = 1e18 选票）
        msg.sender.transfer(_amount);
    }

    /**
     * 4. 结束投票（仅所有者）
     * 逻辑：标记投票结束，将合约余额转给所有者
     */
    function endVoting() public onlyOwner {
        votingEnded = true;
        owner.transfer(address(this).balance);
    }

    /**
     * 辅助函数：查询候选人得票
     */
    function getCandidateVotes(uint256 _candidateId) public view returns (uint256) {
        require(_candidateId > 0 && _candidateId <= candidateCount, "无效的候选人 ID");
        return candidates[_candidateId];
    }

    // 接收 ETH 回调（可选：允许合约直接接收 ETH，默认转为选票）
    receive() external payable notEnded {
        buyVotes();
    }
}
