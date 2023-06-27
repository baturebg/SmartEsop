// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract EmployeeStockOptionPlan {

    // address defined as public
    address public manager;

    //StockOptionsGranted Events declaration 
    event StockOptionsGranted(address indexed employee, uint256 options);
     
    //an event to set vesting shedule of an employee
    event VestingScheduleSet(
        address indexed employee,
        uint256 secondsBeforeStart,
        uint256 vestingDurationInSeconds
    );
    
    //OptionsExercised event declaration
    event OptionsExercised(address indexed employee, uint256 options);
    
   //OptionsTransferred event declaration
    event OptionsTransferred(
        address indexed from,
        address indexed to,
        uint256 options
    );

    //vesting shedule struct
    struct VestingSchedule {
        uint256 secondsBeforeStart;
        uint256 vestingDurationInSeconds;
        uint256 optionsGranted;
        uint256 optionsVested;
    }
     
    ///Mapping for storing vesting shedule per address,
    mapping(address => VestingSchedule) public vestingSchedules;


    //Stockoptions constructor
    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "Only the contract manager can perform this action"
        );
        _;
    }

   
      //A function that allows the company (contract owner) to grant stock options to an employee by specifying their 
      //address and the number of options.

    function grantStockOptions(address employee, uint256 options)
        public
        onlyManager
    {
        vestingSchedules[employee].optionsGranted += options;

        //an event to log the grant of stock options.
        emit StockOptionsGranted(employee, options);
    }


    //a function that allows the company to set the vesting schedule for an employee's options.
    function setVestingSchedule(
        address employee,
        uint256 secondsBeforeStart,
        uint256 vestingDurationInSeconds
    ) public onlyManager {
        require(
            vestingDurationInSeconds >= secondsBeforeStart,
            "Vesting duration must be greater than or equal to cliff duration"
        );

        vestingSchedules[employee].secondsBeforeStart = secondsBeforeStart;
        vestingSchedules[employee]
            .vestingDurationInSeconds = vestingDurationInSeconds;
        emit VestingScheduleSet(
            employee,
            secondsBeforeStart,
            vestingDurationInSeconds
        );
    }

    //a fucntion that allows employee to excercse their option
    function exerciseOptions() public {
        VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender];
        require(
            vestingSchedule.optionsGranted > 0,
            "No options granted to the caller"
        );

        uint256 vestedOptions = calculateVestedOptions(vestingSchedule);
        require(
            vestedOptions > 0,
            "No vested options available for the caller"
        );

        vestingSchedule.optionsVested += vestedOptions;
        vestingSchedule.optionsGranted -= vestedOptions;

        emit OptionsExercised(msg.sender, vestedOptions);
    }

    //a function to get vested options
    function getVestedOptions(address employee) public view returns (uint256) {
        VestingSchedule storage vestingSchedule = vestingSchedules[employee];
        return calculateVestedOptions(vestingSchedule);
    }
 
    //a fuction to get excercised options by employees      
    function getExercisedOptions(address employee)
        public
        view
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule = vestingSchedules[employee];
        return vestingSchedule.optionsVested;
    }

    // a function to transferoptions from employee to employee which the transferer
   // needs to have granted options in their address
    function transferOptions(address to, uint256 options) public {
        VestingSchedule storage senderSchedule = vestingSchedules[msg.sender];
        VestingSchedule storage receiverSchedule = vestingSchedules[to];

        require(
            senderSchedule.optionsGranted > 0,
            "No options granted to the sender"
        );
        require(
            receiverSchedule.optionsGranted == 0,
            "Options already granted to the receiver"
        );

        uint256 vestedOptions = calculateVestedOptions(senderSchedule);
        require(
            vestedOptions >= options,
            "Not enough vested options to transfer"
        );

        senderSchedule.optionsVested -= options;
        receiverSchedule.optionsGranted += options;

        emit OptionsTransferred(msg.sender, to, options);
    }

	
	// a functions to calculate vested options
    function calculateVestedOptions(VestingSchedule storage vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = block.timestamp;
        if (currentTime < vestingSchedule.secondsBeforeStart) {
            return 0;
        }

        uint256 elapsedTime = currentTime - vestingSchedule.secondsBeforeStart;
        if (elapsedTime >= vestingSchedule.vestingDurationInSeconds) {
            return vestingSchedule.optionsGranted;
        }

        uint256 vestedOptions = (vestingSchedule.optionsGranted * elapsedTime) /
            vestingSchedule.vestingDurationInSeconds;
        return vestedOptions;
    }
}

