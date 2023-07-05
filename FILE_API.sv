`ifndef FILE_API_SV
`define FILE_API_SV

`include "DISPLAY.SV"

class FILE_API ;
	local string class_name = "FILE_API";
	local string lines [];
	local string line;
	local string file_name;
	
	typedef string string_DA_t  [];     // define new Dynamic Array structure
	
    function new (string name);
        string function_name = {class_name, "::new"};
		file_name = name;
        lines = new[0]; //It is an operator to size/resize a dynamic array.
    endfunction

    function string_DA_t Read ();
        string  function_name = {class_name, "::Read"};
        integer file = $fopen(file_name, "r"); 
        integer line_len = 0;
       	
		if (lines == null)
        begin
            Display (ERROR, function_name, $sformatf("lines not Initialized"));
            lines.delete ();
            lines = new[0];
            return lines;
        end
         
        if (file == 0) //Could not open file
        begin
            Display (ERROR, function_name, $sformatf("Could not open file %s", file_name));
            lines.delete ();
            lines = new[0];
            return lines;
        end

        while ($fgets(line, file) != 0) // read entire line include 'new line'
		begin
			lines = new[lines.size() + 1] (lines);
			line_len = line.len();
						
			// remove "new line"
			if (line[line_len - 1] == 10)
				line = line.substr(0, line_len - 2);

			lines[lines.size() - 1] = line;
         end
         
         $fclose(file);
		 return lines;		 
    endfunction
	
	function void Write (string data);
		string  function_name = {class_name, "::Write"};
		integer file = $fopen(file_name, "w");
		if (file == 0) //Could not open file
        begin
            Display (ERROR, function_name, $sformatf("Could not open file %s", file_name));
			return;
        end
		$fwrite(file,"%0s",data);
		$fclose(file);
		Display (INFO, function_name, $sformatf("File %s created", file_name));
    endfunction
	
	function void Append (string dir_path, string file_name, string data_list);
		string  function_name = {class_name, "::Append"};
		Display (ERROR, function_name, $sformatf("FUNCTION NOT SUPPORTED YET"));
    endfunction
	
endclass

`endif
