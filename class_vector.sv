
`ifndef CLASS_VECTOR_SV
`define CLASS_VECTOR_SV

`include "DISPLAY.SV"

class Vector #(
      DATA_WIDTH = 16,
      ELEMENTS   =  2
);

	localparam     ERROR_CODE = {DATA_WIDTH{1'bx}};
    typedef logic  [DATA_WIDTH - 1 : 0]   logic_DA_t  [ELEMENTS];     // define new Dynamic Array structure
    
    local logic    [DATA_WIDTH - 1 : 0] vector [];
    local string   class_name = "Vector";
    
    function new (string file_name);
        string function_name = {class_name, "::new"};
        vector = new[0]; //It is an operator to size/resize a dynamic array.
        read_from_file (file_name);
        // print();
    endfunction
    
    local function void read_from_file (string file_name);
        string function_name = {class_name, "::read_from_file"};
        integer file = $fopen(file_name, "r"); 
        integer idx = 0;
        integer line_cnt = 0;
        integer status;
        integer value [0 : ELEMENTS - 1];

        if (vector == null)
        begin
            Display (ERROR, function_name, $sformatf("Vector not Initialized"));
            vector.delete ();
            return;
        end
         
        if (file == 0) //Could not open file
        begin
            Display (ERROR, function_name, $sformatf("Could not open file ", file_name));
            vector.delete ();
            return;
        end

        while(! $feof(file)) begin
            line_cnt += 1;
            
            foreach (value[i]) begin
                status = $fscanf(file, "%d", value[i]);

                if (status == -1) begin   // empty line
                    Display (WARNING, function_name, $sformatf("empty line %0d in %s", line_cnt, file_name));
                    continue;
                end
            
                if (status != 1) begin
                    Display (ERROR, function_name, $sformatf("Unexpected line %0d in %s", line_cnt, file_name));
                    vector.delete ();
                    return;
                end
            
                vector = new[vector.size() + 1] (vector);
                vector[vector.size() - 1] = value[i];
            end
         end
         
         // sanity check - verify that there are no missing elemnts
         if ((get_size() * ELEMENTS) != $size(vector))
            Display (WARNING, function_name, 
                     $sformatf("Number of elemnts (%0d) does not fit full simulation - only first %0d will be simulated !",
                     $size(vector), get_size() * ELEMENTS));
            
            
         // Display (INFO, $sformatf("end of file"));
         $fclose(file);
    endfunction

    local function void print();
        string function_name = {class_name, "::print"};
        foreach (vector [i])
            Display (INFO, function_name, $sformatf("vector[%0d] = %b", i, vector[i]));
    endfunction 
            
    function int get_size ();
        string function_name = {class_name, "::get_size"};
        return $size(vector) / ELEMENTS;
    endfunction

    function logic_DA_t get_value(int index);
        string function_name = {class_name, "::get_value"};
        logic_DA_t arr;
    
        // sanity check index is in range of vector size
        if ((index >= 0) && (index < get_size()))
            foreach (arr[i])
                arr[i] = vector[(ELEMENTS * index) + i];
        else begin
            Display (ERROR, function_name, $sformatf("Index [%0d] is out of range (0 : %0d)", index, get_size()-1));
            foreach (arr[i])
                arr[i] = ERROR_CODE;
        end
            
        // Display (INFO, function_name, $sformatf("value[%0d] = %s", index, $sformatf("%p", arr)));
        return arr;
    endfunction
    
	function int get_element_by_value (logic_DA_t value, int element_index);
		string function_name = {class_name, "::get_element_by_value"};
		
        // sanity check index is in range of ELEMENTS
        if ((element_index < 0) || (element_index >= ELEMENTS)) begin
            Display (ERROR, function_name, $sformatf("Element [%0d] is out of range (0 : %0d)", element_index, ELEMENTS-1));
            return ERROR_CODE;
        end
				
		return value[element_index];
	endfunction	
	
	function int get_element_by_index (int index, int element_index);		
		return get_element_by_value (get_value(index), element_index);
	endfunction
	
endclass

`endif
