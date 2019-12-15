pragma solidity ^0.5.8;
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

/** 
 * Code based in Openzeppelin implementation of ERC20.
 */

/** 
 * It's not needed these imports as HoldableERC20 extends ERC20 that already
 * includes those imports.
 */
/* import "../../GSN/Context.sol"; */
/* import "./IERC20.sol"; */
/* import "../../math/SafeMath.sol"; */

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract HoldableERC20 is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _holdBalances;

    mapping (address => mapping (address => uint256)) private _allowances;

    struct holdStruct {
      address from;
      address to;
      uint256 amount;
    }
    mapping(uint256 => holdStruct) private _holdData;

    uint256 private _totalSupply;
    string public name = "Adhara Token";
    string public symbol = "ADH";
    uint8 public decimals = 2;
    uint public INITIAL_SUPPLY = 12000;


    constructor() public {
      _mint(msg.sender, INITIAL_SUPPLY);
    }

    function balanceOf(address account) public view returns (uint256) {
      return _balances[account] + _holdBalances[account];
    }

    function holdFrom(address sender, address recipient, uint256 amount, uint256 holdId) public returns (bool) {
        _hold(sender, recipient, amount, holdId);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function hold(address recipient, uint256 amount, uint256 holdId) public returns (bool) {
        _hold(_msgSender(), recipient, amount, holdId);
        return true;
    }
    function _hold(address sender, address recipient, uint256 amount, uint256 holdId) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_holdData[holdId].from == address(0), "HoldableERC20: holdId not accepted");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
	    /* Hold balances are updated */
	    _holdBalances[sender] = _holdBalances[sender].add(amount);
        /* Hold data structure is created */
        _holdData[holdId] = holdStruct({from:sender,to:recipient,amount:amount});
        /* No event is emitted as no transfer between users has been performed */
    }
    function executeHold(uint256 holdId) public returns (bool){
      /* It is required that holdId points to a valid hold */
        require(_holdData[holdId].from != address(0), "HoldableERC20: invalid holdId");
      /* It is required that holdId has not been executed before */
        require(_holdData[holdId].to != address(0), "HoldableERC20: holdId already executed");

        _holdBalances[_holdData[holdId].from] = _holdBalances[_holdData[holdId].from].sub(
            _holdBalances[_holdData[holdId].from],
            "HoldableERC20: fatal error in hold balances algorithm");
        _balances[_holdData[holdId].to] = _balances[_holdData[holdId].to].add(
            _holdData[holdId].amount);
        emit Transfer(_holdData[holdId].from, _holdData[holdId].to, _holdData[holdId].amount);
        /* "Clean" hold Id data, to avoid repeated calls */
        _holdData[holdId].to = address(0);
    }
    function removeHold(uint256 holdId) public returns (bool){
        require(_holdData[holdId].from != address(0), "HoldableERC20: invalid holdId");

        _holdBalances[_holdData[holdId].from] = _holdBalances[_holdData[holdId].from].sub(
            _holdBalances[_holdData[holdId].from],
            "HoldableERC20: fatal error in hold balances algorithm");
        _balances[_holdData[holdId].from] = _balances[_holdData[holdId].from].add(
            _holdData[holdId].amount);
        /* "Clean" hold Id data, to avoid repeated calls */
        _holdData[holdId].to = address(0);
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /* balanceOf has been changed to include balances on hold. */
    /**
     * @dev See {IERC20-balanceOf}.
     */
    /* function balanceOf(address account) public view returns (uint256) { */
    /*     return _balances[account]; */
    /* } */

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
