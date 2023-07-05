`timescale 1ns / 1ps

`include "class_vector.sv"
`include "DISPLAY.SV"
`include "FILE_API.SV"

module Scoreboard (
       event_compare_file , 
	   status			   
	
);

parameter OUTPUT_DATA_WIDTH    =  33,
		  OUTPUT_DATA_ELEMENTS =  2 ,
		  OUTPUT_ELEMENTS      =  1 ,
		  UUT_OUTPUT_FILES     =  "",
          GOLDEN_OUTOUT_FILES  =  "";
                    
string    module_name = "Scoreboard";


typedef logic      [OUTPUT_DATA_WIDTH-1:0] logic_Output_DA_t  [OUTPUT_DATA_ELEMENTS]  ;     // define new Dynamic Array driver
typedef string     string_DA_t  [] 						   							  ; 
string_DA_t        list_of_output_uut_files                                           ;
string_DA_t        list_of_output_golden_files             							  ;

input event        event_compare_file												  ;
output logic       status            			    	    					 	  ;

int 			   data_UUT															  ;
int                data_GOLDEN                                                        ;
int 			   number_of_files									                  ;
int 			   flag_compare									                      ;
int                number_of_tests 												      ; 
int                pass_test_cnt = 0												  ;
int 			   vector_UUT_data_size 											  ;
int 			   vector_GOLDEN_data_size 											  ; 
Vector #(OUTPUT_DATA_WIDTH, OUTPUT_DATA_ELEMENTS) vector_UUT_data                     ;
Vector #(OUTPUT_DATA_WIDTH, OUTPUT_DATA_ELEMENTS) vector_GOLDEN_data                  ;	


function string_DA_t get_file (input string file_name);
    FILE_API file_api;
    
    file_api = new (file_name);
    get_file = file_api.Read(); 
endfunction

                         
initial begin
	#2
	pass_test_cnt = 0;
	list_of_output_uut_files  = get_file (UUT_OUTPUT_FILES);  //read the txt output UUT data path file.
	list_of_output_golden_files  = get_file (GOLDEN_OUTOUT_FILES);  //read the txt output GOLDEN data path file
	if (list_of_output_uut_files.size != list_of_output_golden_files.size) 
	begin
        Display (ERROR, module_name, $sformatf("NUMBER OF FILES DOES NOT MATCH %s (%0d) - %s (%0d)",
														UUT_OUTPUT_FILES , list_of_output_uut_files.size, 
														GOLDEN_OUTOUT_FILES , list_of_output_golden_files.size));
		$stop;
	end
	
	number_of_files = list_of_output_uut_files.size;
	number_of_tests = number_of_files/OUTPUT_ELEMENTS;
	flag_compare = 0 ; 

	for (int i = 0 ; i < number_of_tests ; i++) begin
		Display (INFO, module_name, $sformatf("Waiting for EVENT #%0d", i+1));
		@(event_compare_file);
		Display (INFO, module_name, $sformatf("event occure #%0d", i+1));
		for (int j = 0 ; j < OUTPUT_ELEMENTS ; j++) begin			
			flag_compare = compare(j+OUTPUT_ELEMENTS*i);
		end
			if (flag_compare == 0) begin 
				Display (ERROR, module_name, $sformatf("FAILED ON TEST #%0d", i+1 ));
			end
			else begin
				pass_test_cnt++;
				Display (INFO, module_name, $sformatf("Comparison on TEST #%0d was successfully",i+1));
			end
	end
		status = (pass_test_cnt == number_of_tests);
		if (status)
			Display (INFO, module_name, $sformatf("TESTS SUMMARY : PASS : %0d \t FAIL : %0d - TEST COMPLETED SUCCESSFULLY", 
												pass_test_cnt, number_of_tests-pass_test_cnt));
		else
			Display (INFO, module_name, $sformatf("TESTS SUMMARY : PASS : %0d \t FAIL : %0d - TEST COMPLETED WITH ERRORS", 
												pass_test_cnt, number_of_tests-pass_test_cnt));
end


function int compare (input int idx) ;
	int pass_cnt;
	int fail_cnt;
	
	// value must be initialized in the code otherwise they are accumulated.
	pass_cnt=0;
	fail_cnt=0;
	
	vector_UUT_data  = new (list_of_output_uut_files[idx]);
	vector_GOLDEN_data  = new (list_of_output_golden_files[idx]);
	vector_UUT_data_size = vector_UUT_data.get_size();
	vector_GOLDEN_data_size = vector_GOLDEN_data.get_size();
	
	if (vector_UUT_data_size != vector_GOLDEN_data_size ) begin
		Display (ERROR, module_name, $sformatf("VECTOR #%0d:  SIZE OF UUT - (%0d) , GOLDEN - (%0d) DOES NOT MATCH", 
									idx+1, vector_UUT_data_size,vector_GOLDEN_data_size));
		return 0;
	end
	
	for (int i = 0; i < vector_UUT_data_size; i = i + 1) begin 
		for (int j = 0; j < OUTPUT_DATA_ELEMENTS; j = j + 1) begin
			data_UUT = vector_UUT_data.get_element_by_index(i, j);
			//$display("%d",data_UUT);
			data_GOLDEN = vector_GOLDEN_data.get_element_by_index(i, j);
			if (data_UUT != data_GOLDEN) begin
				Display (ERROR, module_name, $sformatf("NO MATCH %0d %d, UUT ELEMENT= %0d : GOLDEN ELEMENT= %0d",i+1, j+1,
												data_UUT, data_GOLDEN));
				fail_cnt++;
			end
			else 
				pass_cnt++;
		end
	end
		
	return (pass_cnt == (vector_UUT_data_size * OUTPUT_DATA_ELEMENTS));

endfunction

endmodule
