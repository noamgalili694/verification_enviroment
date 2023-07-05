`timescale 1ns / 1ps
`include "class_vector.sv"
`include "DISPLAY.SV"


module TB();

localparam  INPUT_ELEMENTS        = 4,
			INPUT_DATA_ELEMENTS   = 2,
            INPUT_DATA_WIDTH      = 16,
			FRAME_SIZE            = 2048,
		    DESIRED_FRAME_SIZE    = 2000,
		    SKIP_FRAME_SAMPLES    = 48,
            OUTPUT_ELEMENTS       = 1,
			OUTPUT_DATA_ELEMENTS  = 1,
            OUTPUT_DATA_WIDTH     = 64,
			MAIN_CLK_PERIOD       = 400,
            CLK_PERIOD        = MAIN_CLK_PERIOD/2,
			CLK_PERIOD_X8 	  = MAIN_CLK_PERIOD/8, 
			
            DATA_INPUT_FILE_NAMES  = "C:\\Users\\NoamGalili\\OneDrive - SaverOne\\Desktop\\TEST_FILES\\TEST_COV_FILES\\TEST_002\\INPUT_FILES_FIXED.txt" ,
            ENABLE_FILE_NAMES      = "C:\\Users\\NoamGalili\\OneDrive - SaverOne\\Desktop\\TEST_FILES\\TEST_002\\ENABLE_FILES.txt",

            RESET_FILE_NAMES       = "C:\\Users\\NoamGalili\\OneDrive - SaverOne\\Desktop\\TEST_FILES\\TEST_COV_FILES\\TEST_002\\RESET_FILES.txt",
			UUT_OUTPUT_FILES       = "C:\\Users\\NoamGalili\\OneDrive - SaverOne\\Desktop\\TEST_FILES\\TEST_COV_FILES\\TEST_002\\OUTPUT_UUT_FILES.txt",
            GOLDEN_OUTOUT_FILES    = "C:\\Users\\NoamGalili\\OneDrive - SaverOne\\Desktop\\TEST_FILES\\TEST_COV_FILES\\TEST_002\\OUTPUT_GOLDEN_FILES.txt";

								
typedef logic       [OUTPUT_DATA_WIDTH  - 1 : 0] logic_output_DA_t [OUTPUT_DATA_ELEMENTS]  ; // define new Dynamic Array driver

logic  rst;
logic  clk ;
logic  clk_X4 ;
logic   [INPUT_DATA_WIDTH -1:0]  vector_data_in [INPUT_ELEMENTS]   [INPUT_DATA_ELEMENTS] ;
logic  valid_in                                                         ;
logic [OUTPUT_DATA_WIDTH-1:0] uut_data_out 								;
logic_output_DA_t vector_data_out   			[OUTPUT_ELEMENTS]		;
int frame_counter														;
logic  valid_out 						        [OUTPUT_ELEMENTS]		;	
logic  result                                                           ;
int    input_vector_length                      [INPUT_ELEMENTS]		; 
int    output_vector_length                     [OUTPUT_ELEMENTS]		; 
ref event  event_compare_file                                   		; 
ref event  valid_event                          [OUTPUT_ELEMENTS]       ; 
event  clk_event                                                        ;
event  size_array_event												    ; 
logic  status                                                           ;
ref event  start_frame_event											;

assign output_vector_length[0] = frame_counter*21; //10 complex values- real , img + time step
assign vector_data_out[0] = {uut_data_out};			// convert unpacked array tro packed array

logic  [2:0] clk_counter=0;

always #(CLK_PERIOD_X8/2)  clk_counter<=clk_counter-1;
assign	clk_X4 = clk_counter[0];
assign	clk = clk_counter[2];

always @(posedge clk) 
     ->clk_event ;

initial
begin
	for (int i = 0 ; i < OUTPUT_ELEMENTS ; i = i + 1) begin
		fork 
            // if j is not used, then it results in calling the task many times in parallel.
            // automatic means that the value of j is "re-entrant" and in any look it will get the value of i
            automatic int j = i;

			generate_valid_event (j);

		join_none
	end	
end


task automatic generate_valid_event;
	input int task_idx;
	while (1) begin
		@(posedge clk_X4) ;
		
		if (valid_out[task_idx])
			->valid_event[task_idx];
	end
endtask


Driver #(
	.FRAME_SIZE            (FRAME_SIZE           ),
	.DESIRED_FRAME_SIZE    (DESIRED_FRAME_SIZE   ),
	.SKIP_FRAME_SAMPLES    (SKIP_FRAME_SAMPLES   ),
    .CLK_PERIOD            (CLK_PERIOD           ),
    .INPUT_DATA_WIDTH      (INPUT_DATA_WIDTH     ),
    .INPUT_ELEMENTS        (INPUT_ELEMENTS       ),
    .DATA_INPUT_FILE_NAMES (DATA_INPUT_FILE_NAMES),
    .ENABLE_FILE_NAMES     (ENABLE_FILE_NAMES    ),
    .RESET_FILE_NAMES      (RESET_FILE_NAMES     )    
) driver (
    .data                  (vector_data_in		 ),
    .reset                 (rst					 ),
	.enable				   (					 ),
    .data_valid            (valid_in			 ),
    .clk_event             (clk_event			 ),
	.vector_length		   (input_vector_length	 ),
	.frame_counter		   (frame_counter		 ),
	.start_frame_event     (start_frame_event	 )
);


cov_matrix  cov_matrix  		(
	.clk_x4     	    		(clk_X4											 ),
    .sync_reset  	    		(rst											 ),
    .data_in_valid     			(valid_in									     ),
    .channel_1_i       			(vector_data_in  [0][0][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_1_q       			(vector_data_in  [0][1][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_2_i       			(vector_data_in  [1][0][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_2_q       			(vector_data_in  [1][1][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_3_i       			(vector_data_in  [2][0][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_3_q       			(vector_data_in  [2][1][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_4_i       			(vector_data_in  [3][0][INPUT_DATA_WIDTH - 1 : 0]),
    .channel_4_q       			(vector_data_in  [3][1][INPUT_DATA_WIDTH - 1 : 0]),
    .vd_out     				(valid_out[0]									 ),
    .matrix_data_out_expanded 	(uut_data_out)
);

monitor #(	.OUTPUT_DATA_WIDTH    (OUTPUT_DATA_WIDTH   ),
			.OUTPUT_ELEMENTS      (OUTPUT_ELEMENTS     ),
			.OUTPUT_DATA_ELEMENTS (OUTPUT_DATA_ELEMENTS),
			.UUT_OUTPUT_FILES     (UUT_OUTPUT_FILES    )
)monitor (
			.UUT_data_out		  (vector_data_out     ),
			.valid_event    	  (valid_event         ),
			.start_frame_event    (start_frame_event   ),
			.vector_length		  (output_vector_length),
			.event_compare_file   (event_compare_file  )


);


Scoreboard #(
			.OUTPUT_DATA_WIDTH    (OUTPUT_DATA_WIDTH   ), 
			.OUTPUT_DATA_ELEMENTS (OUTPUT_DATA_ELEMENTS), 
			.OUTPUT_ELEMENTS      (OUTPUT_ELEMENTS     ), 
			.UUT_OUTPUT_FILES     (UUT_OUTPUT_FILES    ), 
			.GOLDEN_OUTOUT_FILES  (GOLDEN_OUTOUT_FILES )
) scoreboard (
			.event_compare_file  (event_compare_file   ),
			.status              (status               )				   
);



endmodule
