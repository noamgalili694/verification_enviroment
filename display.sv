`ifndef DISPLAY_SV
`define DISPLAY_SV

string COMPANY_NAME = "SAVERONE";

typedef enum {ERROR, WARNING, INFO} MSG_TYPE_NUM;

string MSG_TYPE [3/*MSG_TYPE_NUM.num()*/] = {
                            ERROR   : "ERROR  ",
                            WARNING : "WARNING",
                            INFO    : "INFO   "   
                           };


function void Display (MSG_TYPE_NUM level, string module_name, string str);
    time   cur_time;
    real   time_msg;
    string time_unit;
    
    cur_time = $realtime;
	
	if      (cur_time < 1e3 )    begin    time_msg = cur_time;           time_unit = "ns";   end
    else if (cur_time < 1e6 )    begin    time_msg = cur_time / 1e3 ;    time_unit = "us";   end
    else if (cur_time < 1e9 )    begin    time_msg = cur_time / 1e6 ;    time_unit = "ms";   end
    else                         begin    time_msg = cur_time / 1e12;    time_unit = "Sec";  end
    
    $display ("%s %s\t[%6.2f %s] :\t%s\t[%s]", COMPANY_NAME, MSG_TYPE[level], $realtime, time_unit, str, module_name);
endfunction

`endif
