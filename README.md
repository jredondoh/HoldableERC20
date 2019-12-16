# Holdable ERC-20

**System Requirements**

- NodeJS v8.9+
- Git
- Python 3.6
- Ganache
- yarn
- truffle
- Django
- web3.py python library
- HTTPie

## Improved ERC-20 Contract ##
For this task, as you suggested, I have used OpenZeppelin interface as starting point and I have expanded its implementation. 

The reasoning behind the reuse of their code is the need to have access to their private variables in order to perform correctly the transfers. 

The only function modified is balanceOf that needed to take into account the funds on hold. 

I have added the following functions:                                                           
- hold                                                                                          
- holdFrom                                                                                      
- _hold                                                                                         
- executeHold                                                                                   
- removeHold 
                                                                                                                                                          
I have implemented the signature details as in the assessment, only a Hold id has been added to hold and holdFrom from transfer and transferFrom. 

I have added the following private variables:
- a mapping from the user addresses to the quantities on hold
- a mapping from hold id to all needed hold information

The algorithm behind the uniqueness of hold id is not in the smart contract and must be implemented in the backend.

To test it, from the root folder: 

`yarn install` 

`ganache-cli -p 7545` 

`truffle compile` 

`truffle test`

I have gone through nominal and error cases in my testing.


## Backend Holdable ERC-20 ##
For the backend, I have chosen Python as programming language and Django as framework.

3 services have been provided:

- register
- status
- bet

The input body is a JSON structure with only an “addr” field with the address in hex.

No database or encryption have been implemented for this task, just a plain text file, and no shared resource control. 

For bets, only 4 simultaneous instances have been made available but it is not acceptable for scalability issues. A possible solution is to have several instances of bets running in parallel and assign an oncoming bet to a random instance instead of only one as it is in this proof-of-concept.

To start the server, from the ./backend folder: 

`yarn install` 

`ganache-cli -p 7545` 

`python3.6 manage.py runserver` 

For testing, HTTPie and sh scripting has been used to generate input to provided endpoints. 

In folder ./backend/tests/ 

`sh HoldableERC20.sh > output.txt` 

`sh InvalidCasesHoldableERC20.sh > invalidCasesOutput.txt` 

Test correctness must be ensured via output tests inspection for timing constraints. It would be easy to use a testing tool to generate input and check the backend output.

## Overall thoughts ##
I have tried to follow style guidelines for both Solidity, JavaScript and Python code (PEP8 in this case) but it has not been enforced for timing constraints.
Doxygen style comments have been provided in order to make the documentation generation as automatic as possible.

## Improvements ##
Implement database service for storing users and bets information
Shared resource control
Service for simultaneous instance bet service.
Automatic testing for backend.
Enforcement of coding style guidelines and automatic formatting.