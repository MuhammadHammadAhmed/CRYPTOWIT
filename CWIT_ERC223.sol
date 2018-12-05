pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// CWIT COIN  token contract, Options contract
//
// Deployed to : 
// Symbol      : WIT
// Name        : CryptoWIT
// Total supply: Gazillion
// Decimals    : 18
//Deployed & tested
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

/*
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}*/
//-------ERC721 Interface-----------------------------------------------------------------------------------------------------------------------
contract ERC721Interface {
   // ERC20 compatible functions
  function name() constant returns (string name);
   function symbol() constant returns (string symbol);
   function totalSupply() constant returns (uint256 totalSupply);
   function balanceOf(address _owner) public constant returns (uint balance);
   // Functions that define ownership
   function ownerOf(uint256 _tokenId) constant returns (address owner);
   function approve(address _to, uint256 _tokenId)returns(bool);
  // function takeOwnership(uint256 _tokenId);
   function transfer(address _to, uint256 _tokenId)public returns (bool success);
  //function tokenOfOwnerByIndex(address _owner, uint256 _index) constant returns (uint tokenId);
   // Token metadata
  // function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl);
   // Events
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    address public admin;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Constructor() public {
        owner = msg.sender;
        admin=msg.sender;
    }
    function changeAdmin(address newadmin) onlyOwner{
        admin=newadmin;
    }

    modifier onlyAdmin {
    require(msg.sender==admin);
    _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
         _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//Contract to enable receipt of Token by the Contract, this will help in receiving WITtokens in our Options Contract
 contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data)returns(bool);
}

// ----------------------------------------------------------------------------
// Option Token, which include features from ERC20 & ERC721
// ----------------------------------------------------------------------------
contract CryptoWitOptionToken is  ERC721Interface, Owned, SafeMath,ContractReceiver {
   
     /*......................State Variables..............................*/
    string public _symbol;
    string public  _name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnds;
    uint public endDate;
    address optionWriter;
    address contractAddress;
    uint optionsId=1;
  string[] optiontypes = ["Mobile","Web","IOT","Blockchain","AI"];// initial list of focussed technologies group
 

 /*** ----------------------------------STORAGE & Records ***/

  
mapping(uint=>cwt)optionsbyId;
  mapping (uint256 => address) public optionsIndexToOwner;
  mapping (uint256 => address) public optionsIndexToApproved;
 mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;//remove
mapping (string =>mapping (string =>uint[]))records;

  
 /**Data types */ 
    struct cwt{
        uint optionId;
        string name;
        string optionType;
        address writer;
        address buyer;
    uint underlying;
    uint Premium;
    uint strikePrice;
    uint contractDate;
    uint effectiveDate;
    uint expiryDate;
    bool IsInitiated;
}
/*--------------------Events---*/
event logString(string);
event loguint(uint);
 event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
event OptionCreated(uint optionId, string indexed _name,string indexed _optionType, uint _strikePrice,uint underlying_hours, uint _premium,uint _contractDate,uint _effectiveDate,uint _expiryDate);
//name,Strike price,underlying,premium,contract date,effective date,expiry date)
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        _symbol = "WITCO";
        _name = "WIT Call";
        decimals = 0;
       // bonusEnds = now + 1 weeks;
       // endDate = now + 7 weeks;
        optionWriter=msg.sender;
    emit logString("Constructor is executed");
    contractAddress = address(this);
    /*
    creating a default options, onee of each type with contract date, now, effective in 20 weeeks and expired in 150 weeks.
    admin can create further options laterusing create option function
    */
    for(uint i=0;i<optiontypes.length;i++){
    createOption("Default options", optiontypes[i],1, 1, 5, now, now +20 weeks,now + 150 weeks);
    }
    }
    /* Tokenfallback function.   
    This function will be executed, when, it receives WIT*/
    function tokenFallback(address _from, uint _value, bytes _data)returns(bool){
        //function logic to buy CWITO against WITs
        logString("Contract has received WITs");
    }
    
    /*----------------------------Internal functions---------------*/
    
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {// confirms ownership
    return optionsIndexToOwner[_tokenId] == _claimant;
    emit logString("confirmed that token is owned by Claimant");
  }

  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {//confirmsfirms if authorized approved
    return optionsIndexToApproved[_tokenId] == _claimant;//confirm if authorized
    emit logString("confirmed that Claimant is authorized");
  }

  function _approve(address _to, uint256 _tokenId) internal {//authorize for transfer
    optionsIndexToApproved[_tokenId] = _to;
    
    emit logString("Approved for transfer of Option");

   // Approval(tokenIndexToOwner[_tokenId], tokenIndexToApproved[_tokenId], _tokenId);//event
  }
 // function takeOwnership(uint256 _tokenId);
/*--------------------------End of Internal functions--*/
    
    function _transfer(address _from, address _to, uint256 _optionId) internal {//transfer tokens
    balances[_to]++;//increasing ownership count
    optionsIndexToOwner[_optionId] = _to; // changing ownership

    if (_from != address(0)) {
      balances[_from]--;// decreasing ownership count
      delete optionsIndexToApproved[_optionId];// deleting the authorized by previous owner
    }

    Transfer(_from, _to, _optionId);//event 
  }
//------------------------------------------------------------------------
function createOption(string _name,string optionType,uint _underlying, uint _premium, uint _strikePrice,uint _contractDate,uint _effectiveDate,uint _expiryDate){
      // address optionBuyer= msg.sender; 
       
        cwt memory cwit= cwt(optionsId, _name,optionType, optionWriter, address(0), _underlying, _premium, _strikePrice, _contractDate, _effectiveDate, _expiryDate,false);
    
   // options.push(cwit);
   optionsIndexToOwner[optionsId]=contractAddress;
 balances[contractAddress]++;
  // balances[contractAddress]++;
    
    records["Uninitialized"][optionType].push(optionsId);
   
    
    emit logString("Option is Created");
   emit OptionCreated(optionsId, _name,  optionType,  _strikePrice,_underlying,_premium,_contractDate, _effectiveDate, _expiryDate); 
    optionsId++;
  
    } 
     /*--Call Option specific functions--*/
     function excercise(uint optionId, uint excercisePrice) returns(bool)  {
        cwt memory opt = optionsbyId[optionId];
        require(tx.origin == opt.buyer);
        require(!isExpired(optionId));
        
        /*code to call escrow excercise Price till such time developer complete task*/
      emit logString("optionis excercised");
      return true;
                
    }
     function isExpired(uint opId) view public returns(bool){
 return (optionsbyId[opId].expiryDate< now);
}  

//---------------------------------------------------------
    function buyOption(uint _type, uint wit){
        string memory optype = optiontypes[_type];
            
      if(records["Uninitialized"][optype].length>0){
          _transfer(contractAddress, msg.sender,records["Uninitialized"][optype][0]);
          records["initiated"][optype].push(records["Uninitialized"][optype][0]);
          delete records["Uninitialized"][optype][0];//deletethe record
          emit logString("Option is bought");
      }else{
       emit logString("coulnt execute bought function"); 
    }
      }
        
        
   // }
    function name() constant returns (string _name){
    return _name;
  }
    function symbol() constant returns (string symbol){
    return _symbol;
    }
//---------------------------------------------------------

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
//retn the owner address
 function ownerOf(uint256 _optionId) public view returns (address owner) {//returns the owner of a particular option
    owner = optionsIndexToOwner[_optionId];
}
    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
        
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
   function transfer(address _to, uint256 _optionId) public returns (bool success){// owner can transfer the tokens.removed external
    require(_to != address(0));
    require(_to != address(this));// to avoid sendingitself
    require(_owns(msg.sender, _optionId));//confirms ownership

    _transfer(msg.sender, _to, _optionId);// transferred by calling the internal function
    return true;
  }
   //delete below function
/*    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }*/


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;//authorizer, authorized
        Approval(msg.sender, spender, tokens);//event
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);//from is authorizer,msg.sender is authorized
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
       emit Approval(msg.sender, spender, tokens);//event
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // //ETH=type - 1
    //
    
    // ------------------------------------------------------------------------
    function () public payable {
      /*  require(now >= startDate && now <= endDate);
        uint Eth = msg.value;
        if (now <= bonusEnds) {
            tokens = msg.value * 600;
        } else {
            tokens = msg.value * 500;
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);*/
        
        uint eth = uint(msg.value);
        
        if(eth ==1){
            buyOption(0,1);
            
           }else if (eth == 2){
               
            buyOption(1,eth);
             emit logString("1st option bought");
        }else if (eth==3){
               
            buyOption(2,eth);
             emit logString("2nd option bought");
     /*   }else if (eth==3){
               
            buyOption(2,3);*/
             emit logString("3rd option bought");
               emit loguint(eth);
        }else if (eth==4){
               
            buyOption(3,eth);
            emit logString("4thoption bought");
              emit loguint(eth);
    }else{
       buyOption(4,eth);
        emit logString("default option bought");
        emit loguint(eth);
        
    }
    }



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
  /*  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }*/
}

