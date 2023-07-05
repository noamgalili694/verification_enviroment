`timescale 1ns / 1ps

`include "class_vector.sv"
`include "DISPLAY.SV"
`include "FILE_API.SV"

module monitor (
	UUT_data_out      ,
	valid_event 	  ,
	start_frame_event ,
	vector_length	  ,
	event_compare_file	
);

parameter OUTPUT_DATA_WIDTH    = 33 ,
		  OUTPUT_ELEMENTS      = 1  ,
		  OUTPUT_DATA_ELEMENTS = 2  ,			// number of element to read 
		  UUT_OUTPUT_FILES     = "" ;
		  
typedef logic           [OUTPUT_DATA_WIDTH  - 1 : 0] logic_output_DA_t [OUTPUT_DATA_ELEMENTS ]  ; // define new Dynamic Array driver
typedef string          string_DA_t  []                                                         ;  // define new Dynamic Array structure

input logic_output_DA_t UUT_data_out       [OUTPUT_ELEMENTS];
input event             valid_event        [OUTPUT_ELEMENTS];
input event             start_frame_event                   ; 
input int               vector_length      [OUTPUT_ELEMENTS];
                                                           
output event            event_compare_file;

string                  module_name = "Monitor"             ;
string_DA_t             list_of_output_files                ;
event                   event_output_file  [OUTPUT_ELEMENTS];


initial begin 
	#1 
	list_of_output_files  = get_file (UUT_OUTPUT_FILES); //->2 
	if ((list_of_output_files.size % OUTPUT_ELEMENTS) != 0) begin
		Display (ERROR, module_name, $sformatf("NUMBER OF FILES (%0d) in %s DOES NOT FIT EXPECTED ELEMENTS (%0d)", 
											list_of_output_files.size, UUT_OUTPUT_FILES, OUTPUT_ELEMENTS));
		$stop;
	end
	
	// Each statement in a fork is a concurrent thread. 
	// A for loop is a single statement and each iteration gets executed serially.
	// join_none prevents from the thread to wait to the end of task execution.
	for (int i = 0 ; i < OUTPUT_ELEMENTS ; i++) begin
		fork 
			// if j is not used, then it results in calling the task many times in parallel.
			// automatic means that the value of j is "re-entrant" and in any look it will get the value of i
			automatic int j = i;
			data_task(j);
		join_none
	end
end


initial begin 
	int max_file_number;

	// max_file_number must be calculated after list_of_output_files has a value
	#2 max_file_number = list_of_output_files.size/OUTPUT_ELEMENTS;
	
	for(int n = 0; n < max_file_number; n++) begin 
		fork
			for (int i = 0 ; i < OUTPUT_ELEMENTS ; i++) begin
				automatic int j = i;
				@(event_output_file[0]);			// need to understand why index j prevents simulation runing
			end
		join
		
		Display (INFO, module_name, $sformatf("TEST #%0d Completed - Generating event)", n+1 ));
		->event_compare_file;
	end
end


function string_DA_t get_file (input string file_name);
    FILE_API file_api;
    file_api = new (file_name);
    get_file = file_api.Read(); 
endfunction


function void write_file (input string file_name, input string file_data);
	
	FILE_API file_api;
	
    file_api = new (file_name);
	file_api.Write(file_data);
	
endfunction

// in order to enter the task many time with diffferent variables - the task must be automatic
// that means that the task is re-entrant - items declared within the task are dynamically 
// allocated rather than shared between different invocations of the task.
task automatic data_task; 
    input int task_idx;
	string new_str;
	event  ev   = valid_event   [task_idx];
    int    len;
	string str  = "";
	//int lastNewlineIndex = str.last_index("\n") ; 
	int max_file_number = list_of_output_files.size/OUTPUT_ELEMENTS;
	int i;
	string task_name = {module_name, ":data_task ", $sformatf("%0d", task_idx+1)};
	Display (INFO, task_name, $sformatf("DATA TASK %0d STARTED", task_idx+1));
	
	for(int n = 0; n < max_file_number; n++) begin 
		@(start_frame_event);
		
		len  = vector_length [task_idx];
		

		str  = "";		
		for (i = 0; i < len; i++) begin
			@(ev) ;
			
			
			for(int j = 0; j < OUTPUT_DATA_ELEMENTS; j++)
				str = {str,$sformatf("%0d",UUT_data_out[task_idx][j])};
			str = {str,"\n"};
			//$display("%s",str);
		end
		new_str = str.substr(0, str.len() - 2);

		write_file(list_of_output_files[task_idx + n * OUTPUT_ELEMENTS], new_str);
		Display (INFO, module_name, $sformatf("Output file event #%0d", n+1 ));
		->event_output_file[task_idx];
	end
	Display (INFO, task_name, $sformatf("END OF TASK %0d", task_idx+1));
endtask

endmodule

  
