pragma solidity ^0.5.0;

contract auditing{
    
    // Models a participant who wants to genrate a random bit for a specific request
    struct Participant{
        bool bp; // The random bit
        uint ID; // The user ID of participant which is between 1 to n
        uint hp; // Hash that was announced by the participant
        bool checked; // whether the hash value is consistent with the data provided by the participant
    }
    
    // Data of a request for a random bit, with the summary of responders
    struct Request{
        uint phi; // The fee paid by the client to generate a random bit
        uint t; // Deadline for random bit generation proccess
        uint v; // Estimated value to cover potentail manipulation
        uint opened; // The time the request has been opened in the system
        uint n; // Number of registered participants in the system
        mapping(address => Participant) participants; // List of partcipants 
        uint nPrime; // Number of participants in the system who correctly revealed their random bit
        uint n0; 
        uint n1; 
        uint n2; 
        uint n3; 
        bool result; // Save the result of this request at the end of each step
    }
    
    uint numberOfRequests; // Keep number of requests that has been sumbitted in the system up until now.
    uint tMin; // Minimum of time for generation of random bit
    uint tReg; // The amount of time that requests will be open for registeration

    mapping(uint => Request) public requests; //Keeps a set of all requests

    constructor() public {
        numberOfRequests = 0;
        tReg = 60;
        tMin = 2 * tReg;
    }

    event Ret(uint test);
    
    // This function is called by a client whenever he wants to generate a random bit
    function requstRandomBit(uint _phi, uint _t, uint _v) public payable returns(uint){
        uint new_t = _t / 1000;
        require(!tooClose(_t)); // Check if there is enough time until _t to genrate a random bit
        deposit(msg.value,_phi); //Accepts the money from client  if matches the _phi 
        numberOfRequests++;
        uint id = numberOfRequests;
        requests[id] = Request({phi: _phi,t: new_t,v: _v, opened: block.timestamp, n: 0, nPrime: 0, n0:0, n1:0, n2:0,n3:0, result: false}); //Create a request with the info provided by client
        return id; //Return id to caller of the client for further actions
    }
    //Register a participant in the desired request
    function register(uint id, uint _hp) public payable{
        require(block.timestamp < requests[id].opened + tReg); // Check if the request is still open for registration
        deposit(msg.value,requests[id].v); // Allow the implict transaction if and only if its value matches value of request
        requests[id].participants[msg.sender] = Participant({ID: requests[id].n, hp: _hp, bp: false,  checked:false}); //Add this participant to the list of registered participants
        requests[id].n++;
    }
    // Participants can reveal their random bit using the following function which checks iff this value is consistent with previously announced hash value
    function reveal(bool bp, uint np, uint id) public{
        require(block.timestamp > requests[id].opened + tReg); // Check if the registeration time has ended
        require(block.timestamp < requests[id].t ); // Check if there is still time until the deadline of this request
        require(hash(bp,np,msg.sender,id) == requests[id].participants[msg.sender].hp); // Check if the hash of revealed value matches the one announced previously
        requests[id].participants[msg.sender].bp = bp; //Save the random bit of this participant
        requests[id].nPrime++; //Increase the number of participants who revealed their value truthfully
        // Keeping track of RBGC values
        if(bp == false){
            if(requests[id].participants[msg.sender].ID % 2 == 0){
                requests[id].n0++; // When the proposed random bit is zero and participant ID is even 
            }
            else{
                requests[id].n1++; // When the proposed random bit is zero and participant ID is odd
            }
        }
        else{
            if(requests[id].participants[msg.sender].ID % 2 == 0){
                requests[id].n2++; // When the proposed random bit is one and participant ID is even
            }
            else{
                requests[id].n3++; // When the proposed random bit is one and participant ID is odd
            }
        }
        requests[id].result = !(requests[id].result == bp); // Update the result of the request -- this operation is equivalent to xor
        requests[id].participants[msg.sender].checked = true; // Save that this participant has revealed her value truthfully
    }
    //Return deposit of truthful participant after deadline
    function returnDeposit(uint id) public payable{
        require(block.timestamp > requests[id].t); // Check if deadline has been passed already
        require(requests[id].participants[msg.sender].checked == true); // Check if the participant is truthful
        withdraw(msg.sender,requests[id].v); // Give back money to participant
    }
    // Distribute the fee among the truthful participant after deadline among his demand
    function requstReward(uint id) public payable{
        require(block.timestamp > requests[id].t ); // Check if the deadline has been passed 
        //Destribute money based on the RBG rules
        bool bp = requests[id].participants[msg.sender].bp; 
        uint up;
        if(bp == false){
            if(requests[id].participants[msg.sender].ID % 2 == 0){
                up = requests[id].n3-requests[id].n1;
            }
            else{
                up = requests[id].n0-requests[id].n2;
            }
        }   
        else{
            if(requests[id].participants[msg.sender].ID % 2 == 0){
                up = requests[id].n1-requests[id].n3;
            }
            else{
                up = requests[id].n2-requests[id].n0;
            }
        }
        uint _nPrime = requests[id].nPrime;
        uint rp = ((requests[id].phi)*(up+_nPrime-1))/((_nPrime-1)*2*_nPrime);
        withdraw(msg.sender,rp); // Give the truthful participant his share of the reward 
    }
    // Give the client the random bit which has been genrated by contract
    function getOutput(uint id) public payable returns (bytes32){
        require(block.timestamp > requests[id].t ); // Check if the deadline has been passed 
        if(requests[id].nPrime == 0){ // If no one had truthfully participated in contract
            withdraw(msg.sender,requests[id].phi); //Give back deposited fee to client
            return "failure";
        }
        else if(requests[id].nPrime == requests[id].n){ //If all the registered participant revealed their value truthfully
           if(requests[id].result){
                emit Ret(1);
                return "success: 1";
           }
           else{
               emit Ret(0);
               return "success: 0";
           }
        }
        else{ //Give deposit of registered participant who do not contribute to the end result to the client
            withdraw(msg.sender,((requests[id].n-requests[id].nPrime)*requests[id].v));
            return "penalty";
        }
    }
    // Check if the proposed deadline of client for a request is too close or not    
    function tooClose(uint t) private view returns (bool){
        uint x = t / 1000;
        if(x < tMin + block.timestamp){
            return true;
        }
        return false;
    }
    //Calculate the hash of the participant to check for consistency
    function hash(bool bp,uint np,address p, uint id) private pure returns (uint){
        return uint(keccak256(abi.encodePacked(bp,np,p,id)));
    }
    // Allow the implict transaction if and only if its value matches amount of request
    function deposit(uint value, uint amount) private pure{
        require(value == amount); 
    }
    // Transfer money to the client/participant based on their address
    function withdraw(address payable sender, uint amount) private{
        sender.transfer(amount);
    }
}