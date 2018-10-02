pragma solidity ^0.4.24;

contract MintableERC20Token {

  /***************************************************************************
  * Public Variables
  ***************************************************************************/
  // Ether と トークンの交換レート
  uint8 public constant rate = 100; // 1 Ether = 100 トークン

  // このコントラクトから Ether を引き出すことのできるアドレス
  uint8 public constant contractOwner = 0xee8779531B0693d518D707dfB41675c056fE8c70;

  /***************************************************************************
  * Private Variables
  ***************************************************************************/
  // トークン名を保持
  string private _name;
  
  // トークンシンボルを保持
  string private _symbol;

  // トークンの小数点以下桁数を保持
  uint8 private _decimals;

  // トークンの供給量を保持
  uint256 private _totalSupply;

  // アドレス毎のトークン残高を保持
  mapping (address => uint256) private _balances;
  
  // トークン所有者 owner が別アドレス spender に移動を許可したトークン残高を保持
  mapping (address => mapping (address => uint256)) private _allowed;  

  /***************************************************************************
  * Event
  ***************************************************************************/
  // トークン転送時に実行されるイベント
  event Transfer(
      address indexed from,
      address indexed to,
      uint256 value
  );
  
  // トークンの移動許可承認時に実行されるイベント
  event Approval(
      address indexed owner,
      address indexed spender,
      uint256 value
  );

  /***************************************************************************
  * Constructor
  ***************************************************************************/
  // コントラクトのデプロイ時に1度のみ実行されるメソッドです。
  constructor ()
    public
  {
    _name = "MyToken";
    _symbol = "MTK";
    _decimals = 18;
    _totalSupply = 1000000000000000000000;  // 1000 MTK
    _balances[msg.sender] = _totalSupply;
    emit Transfer(0x0, msg.sender, _totalSupply);
  }

  /***************************************************************************
  * Internal Methods
  ***************************************************************************/
  // トークンを追加発行します。
  function _mint(address account, uint256 amount)
    internal
  {
    // 追加発行したトークンを転送するアカウントが 0x0 でないことをチェック
    require(account != 0);

    // トークン供給量と追加発行トークン数の合計値が、現在のトークン供給量以上であることをチェック
    // オーバーフロー対策
    require(_totalSupply + amount >= _totalSupply);

    // トークン供給量に追加発行トークン数を加える
    _totalSupply = _totalSupply + amount;

    // 転送先の残高と転送トークン数の合計値が、現在の残高以上であることをチェック
    // オーバーフロー対策
    require(_balances[account] + amount >= _balances[account]);

    // 転送先の残高に追加発行トークン数を加える
    _balances[account] = _balances[account] + amount;

    // イベントを発火
    emit Transfer(address(0), account, amount);
  }

  /***************************************************************************
  * Public Methods
  ***************************************************************************/
  // トークン名を返します。
  function name()
    public
    view
    returns(string) 
  {
    return _name;
  }

  // トークンシンボルを返します。
  function symbol()
    public
    view
    returns(string) 
  {
    return _symbol;
  }

  // トークンの小数点以下桁数を返します。
  function decimals()
    public
    view
    returns(uint8)
  {
    return _decimals;
  }

  // 現在のトークン供給量を返します。
  function totalSupply()
    public
    view
    returns (uint256) 
  {
    return _totalSupply;
  }

  // アドレスのトークン残高を返します。
  function balanceOf(address owner)
    public
    view
    returns (uint256) 
  {
    return _balances[owner];
  }

  // トークン所有者 owner が別アドレス spender に移動を許可したトークン残高を返します。
  function allowance(address owner, address spender)
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  // トークンを別のアドレスに転送します。
  function transfer(address to, uint256 value)
    public
    returns (bool) 
  {
    // 転送トークン数が残高以下であることをチェック
    require(value <= _balances[msg.sender]);

    // 転送先が 0x0 でないことチェック
    require(to != address(0));

    // メソッド実行者（転送元）の残高から転送トークン数を差し引く
    // require(value <= _balances[msg.sender]); により、
    // value が _balances[msg.sender] 以下であることが保証済
    _balances[msg.sender] = _balances[msg.sender] - value;

    // 転送先の残高と転送トークン数の合計値が、現在の残高以上であることをチェック
    // オーバーフロー対策
    require(_balances[to] + value >= _balances[to]);

    // 転送先の残高に転送トークン数を加える
    _balances[to] = _balances[to] + value;

    // イベントを発火
    emit Transfer(msg.sender, to, value);

    return true;
  }

  // トークン所有者 owner が別アドレス spender に、指定した数のトークン移動を許可します。
  function approve(address spender, uint256 value)
    public
    returns (bool) 
  {
    // spender のアドレスが 0x0 でないことをチェック
    require(spender != address(0));
    
    // spender に移動を許可するトークン数をセット
    _allowed[msg.sender][spender] = value;

    // イベントを発火
    emit Approval(msg.sender, spender, value);

    return true;
  }

  // 任意のアドレスから任意のアドレスにトークンを転送します。
  // 転送できるトークン数は、メソッドの実行者がトークンの所有者に転送を許可されている
  // トークン数の範囲内です。
  function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
  {
    // 転送トークン数が残高以下であることをチェック
    require(value <= _balances[from]);
    
    // 転送トークン数が、トークン所有者がこのメソッドの実行者に許可した転送トークン数以下であることをチェック
    require(value <= _allowed[from][msg.sender]);
    
    // 転送先が 0x0 でないことチェック
    require(to != address(0));

    // 転送元の残高から転送トークン数を差し引く
    // require(value <= _balances[from]); により、
    // value が _balances[from] 以下であることが保証済
    _balances[from] = _balances[from] - value;

    // 転送先の残高と転送トークン数の合計値が、現在の残高以上であることをチェック
    // オーバーフロー対策
    require(_balances[to] + value >= _balances[to]);

    // 転送先の残高に転送トークン数を加える
    _balances[to] = _balances[to] + value;

    // トークン所有者がこのメソッドの実行者に許可した転送トークン数から転送トークン数を差し引く
    // require(value <= _allowed[from][msg.sender]) により、
    // value が _allowed[from][msg.sender] 以下であることが保証済
    _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;

    // イベントを発火
    emit Transfer(from, to, value);

    return true;
  }

  function mint()
    public
    payable
    returns (bool)
  {
    require(msg.value > 0);
    uint256 amount = msg.value * rate;
    // オーバーフロー対策    
    require(amount / msg.value == rate);
    _mint(msg.sender, amount);
  }

  function withdraw(uint256 amount)
    public
  {
    require (msg.sender == contractOwner);
    msg.sender.transfer(amount);
  }

}