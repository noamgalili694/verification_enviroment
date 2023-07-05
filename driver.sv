`timescale 1ns / 1ps

`include "class_vector.sv"
`include "DISPLAY.SV"
`include "FILE_API.SV"

module Driver (
        data                 , // input  samples 
        enable               ,
        reset                ,
		data_valid			 ,
        clk_event 	         ,
		vector_length	     ,
		frame_counter        ,
		start_frame_event
);

parameter FRAME_SIZE            = 2048,
		  DESIRED_FRAME_SIZE    = 2000,
		  SKIP_FRAME_SAMPLES    = 48  ,
		  CLK_PERIOD            = 50  ,
          INPUT_DATA_WIDTH      = 16  ,
          INPUT_ELEMENTS        = 4   ,		  // number of antennas
          DATA_INPUT_FILE_NAMES = ""  ,
          ENABLE_FILE_NAMES     = ""  ,
          RESET_FILE_NAMES      = ""  ;   
          
localparam DATA_ELEMENTS     	= 2   ,           // number of element to read 
           RESET_ELEMENTS    	= 2   ,
           ENABLE_ELEMENTS   	= 2   ,
           ENABLE_DATA_WIDTH 	= 16  ,
		   RESET_DATA_WIDTH  	= 16  ;
		   
           
string module_name = "Driver";

typedef logic     [INPUT_DATA_WIDTH - 1 : 0 ] logic_Input_DA_t     [DATA_ELEMENTS  ]; // define new Dynamic Array driver
typedef logic     [RESET_DATA_WIDTH  - 1 : 0] logic_Input_RESET_t  [RESET_ELEMENTS ]; 
typedef logic     [ENABLE_DATA_WIDTH - 1 : 0] logic_Input_ENABLE_t [ENABLE_ELEMENTS];
                       
typedef string 										  string_DA_t  []                     ;  // define new Dynamic Array structure
output  event 										  start_frame_event  				  ;
output  int                                           vector_length    [INPUT_ELEMENTS]   ;  
output  int                                           frame_counter			   			  ;    
output  logic_Input_DA_t                              data [INPUT_ELEMENTS] 		      ;
output  logic 										  data_valid	        		      ;
output  logic                                         enable                              ;
output  logic                                         reset                               ;
input   event                                         clk_event                           ;     

string_DA_t                                           list_of_input_files                 ;
string_DA_t                                           list_of_enable_files                ;
string_DA_t                                           list_of_reset_files                 ;
Vector  #(INPUT_DATA_WIDTH,DATA_ELEMENTS)    		  vector_data      [INPUT_ELEMENTS]   ;
integer                                               vector_data_size [INPUT_ELEMENTS]   ; 
Vector  #(ENABLE_DATA_WIDTH, ENABLE_ELEMENTS)         vector_enable                       ; 
integer                                               vector_enable_size                  ; 
logic_Input_ENABLE_t                                  vector_enable_data                  ;
int                                                   enable_cycles                       ;
logic 												  start_frame_flag					  ;
Vector  #(RESET_DATA_WIDTH, RESET_ELEMENTS)           vector_reset                        ;
integer                                               vector_reset_size                   ; 
logic_Input_RESET_t                                   vector_reset_data                   ; 
int                                                   reset_cycles                        ;


function string_DA_t get_file (input string file_name);
    FILE_API file_api ;
    
    file_api = new (file_name);
    get_file = file_api.Read(); 
endfunction

initial begin
	start_frame_flag = 0;
	data_valid = 0;
	reset  = 0;
	enable = 0;
	list_of_input_files  = get_file (DATA_INPUT_FILE_NAMES);  //read the txt input data path file // == 8; 
	for (int i = 0 ; i < INPUT_ELEMENTS ; i++) // 0->3
		vector_length[i]=0;
   
    list_of_enable_files = get_file (ENABLE_FILE_NAMES); // read the txt enable path file
    list_of_reset_files  = get_file (RESET_FILE_NAMES);   //read the txt reset path file
	
    
	if ((list_of_input_files.size % INPUT_ELEMENTS) != 0) // input_elements = 4 in this case
	begin
        Display (ERROR, module_name, $sformatf("NUMBER OF FILES (%0d) in %s DOES NOT FIT EXPECTED ELEMENTS (%0d)", 
												list_of_input_files.size, DATA_INPUT_FILE_NAMES, INPUT_ELEMENTS));
        $stop;
    end
	
	Display (INFO, module_name, $sformatf("There are %0d data files - %0d tests", list_of_input_files.size, list_of_input_files.size / INPUT_ELEMENTS));
	Display (INFO, module_name, $sformatf("There are %0d enable files", list_of_enable_files.size));
	Display (INFO, module_name, $sformatf("There are %0d reset files" , list_of_enable_files.size));

	fork
		//enable_task();
		reset_task();
        // Each statement in a fork is a concurrent thread. 
        // A for loop is a single statement and each iteration gets executed serially.
        // join_none prevents from the thread to wait to the end of task execution.
        for (int i = 0 ; i < INPUT_ELEMENTS ; i++) begin
            fork 
                // if j is not used, then it results in calling the task many times in parallel.
                // automatic means that the value of j is "re-entrant" and in any look it will get the value of i
                automatic int j = i;
                data_task(j);
            join_none
        end
    join
	Display (INFO, module_name, $sformatf("DRIVER COMPLETED FILE INJECTION"));
end

// in order to enter the task many time with different variables - the task must be automatic
// that means that the task is re-entrant - items declared within the task are dynamically 
// allocated rather than shared between different invocations of the task.
task automatic data_task; 
	input int task_idx;
	int number_of_tests = list_of_input_files.size / INPUT_ELEMENTS;
	string task_name = {module_name, ":data_task ", $sformatf("%0d", task_idx+1)};
    int k;
    Display (INFO, task_name, $sformatf("DATA TASK %0d STARTED", task_idx+1));
	
	for (int i = 0 ; i <  number_of_tests; i++) begin
		k=0;
		vector_data [task_idx] = new (list_of_input_files[task_idx + i*INPUT_ELEMENTS]);
		vector_data_size[task_idx] = vector_data[task_idx].get_size();
		vector_length[task_idx] = vector_data_size[task_idx];
		frame_counter = (vector_length[task_idx]/FRAME_SIZE);
		start_frame_flag=1;
		Display (INFO, task_name, $sformatf("reading data of test # %0d/%0d input vector #%0d [len = %0d] - %s",
										i+1, number_of_tests, task_idx+1,vector_data_size[task_idx],
										list_of_input_files[task_idx + i*INPUT_ELEMENTS]));
										
		//Display (INFO, task_name, $sformatf("Vector Size in file %0d is %0d", i+1, vector_data_size[task_idx]));
		//for (int k = 0; k < vector_data_size[task_idx]; k = k + 1) begin 
		while ( k < vector_data_size[task_idx]) begin 
			@(clk_event);
			
			if ((start_frame_flag==1) && (task_idx==0)) begin
				start_frame_flag=0;
				->start_frame_event;
			end
			//if k % (DESIRED_FRAME_SIZE + SKIP_FRAME_SAMPLES) < DESIRED_FRAME_SIZE begin 
				if (reset) begin
					data[task_idx] = vector_data[task_idx].get_value(k++);
					data_valid=1'b1;
				end
				else begin
					for (int i=0; i<INPUT_ELEMENTS; i=i+1)
						data[task_idx][i] = {INPUT_DATA_WIDTH{1'bx}};
					data_valid=1'b0;
				end
			//end	
		end 	
	end
	Display (INFO, task_name, $sformatf("END OF DATA TASK"));
endtask


// ENABLE injection
task enable_task; 
	string task_name;
	
	task_name = {module_name, ":", "enable_task"};
	
    foreach (list_of_enable_files [i]) begin
        Display (INFO, task_name, $sformatf("reading enable file #%0d of %0d files" , i+1, list_of_enable_files.size));
        vector_enable = new (list_of_enable_files[i]);
        vector_enable_size = vector_enable.get_size();

		for (int j = 0; j < vector_enable_size; j = j + 1) begin 
            vector_enable_data = vector_enable.get_value(j);
            enable_cycles = vector_enable_data[0];
            Display (INFO, task_name, $sformatf("ENABLE is %s for %0d cycles", vector_enable_data[1]==1 ? "HIGH" : "LOW", enable_cycles));
			repeat (enable_cycles * CLK_PERIOD)
            #1 enable = vector_enable_data[1];
        end
    end
	Display (INFO, task_name, $sformatf("END OF ENABLE TASK"));
endtask


// RESET injection
task reset_task; 
	string task_name;
	
	task_name = {module_name, ":", "reset_task"};
    
	foreach (list_of_reset_files [i]) begin
        Display (INFO, module_name, $sformatf("reading reset file #%0d of %0d files" , i+1, list_of_reset_files.size));
        vector_reset = new (list_of_reset_files[i]);
        vector_reset_size = vector_reset.get_size();

		for (int j = 0; j < vector_reset_size; j = j + 1) begin 
            vector_reset_data = vector_reset.get_value(j);
            reset_cycles = vector_reset_data[0];
			Display (INFO, task_name, $sformatf("RESET is %s for %0d cycles", vector_reset_data[1]==1 ? "HIGH" : "LOW", reset_cycles));			
			repeat (reset_cycles * CLK_PERIOD)
            #1 reset = vector_reset_data[1];
        end
    end
	Display (INFO, task_name, $sformatf("END OF RESET TASK"));
endtask

endmodule
