class ahb_tx extends uvm_sequence_item;
rand bit [31:0] addr;
     bit [31:0] addr_t;
rand bit [31:0] dataQ[$];
rand bit wr_rd;
//rand bit [2:0] burst;
rand burst_t burst;
rand bit [2:0] size;
rand bit [4:0] len;
rand bit [6:0] prot;
rand bit excl;
rand bit [3:0] master;
rand bit nonsec;
rand bit mastlock;
     bit [1:0] resp;
     bit exokay;
integer txsize;
bit [31:0] lower_wrap_addr;
bit [31:0] upper_wrap_addr;

//prot? excl? size? err?
`uvm_object_utils_begin(ahb_tx)
	`uvm_field_int(addr, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_queue_int(dataQ, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(wr_rd, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_enum(burst_t, burst, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(size, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(len, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(prot, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(excl, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(master, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(nonsec, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(mastlock, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(resp, UVM_ALL_ON|UVM_NOPACK)
	`uvm_field_int(exokay, UVM_ALL_ON|UVM_NOPACK)
`uvm_object_utils_end
`NEW_OBJ
function void post_randomize();
	addr_t = addr;
	calc_wrap_boundaries();
endfunction
//Constraints
constraint burst_len_c {
	(burst == SINGLE) -> (len == 1);
	(burst inside {INCR4, WRAP4}) -> (len == 4);
	(burst inside {INCR8, WRAP8}) -> (len == 8);
	(burst inside {INCR16, WRAP16}) -> (len == 16);
	len inside {[1:16]}; //taking care of INCR burst
}

constraint dataQ_c {
	dataQ.size() == len;
}

//AHB only supports aligend transfers
constraint aligned_c {
	addr % (2**size) == 0;
}

//default transfers keep as INCR
constraint burst_c {
	soft burst == INCR4;
}
constraint size_c {
	soft size == 2;  //4 bytes per beat => fit in to 32 bit data bus
}
constraint master_c {
	soft master == 0;
}

//methods
//wrap boundaries
function void calc_wrap_boundaries();
	//txsize = num_transfers * bytes_per_beat;
	txsize = len * (2**size); //wrap boundaries will be 0, 1*txsize, 2*txsize..
		//0, 64, 128
	lower_wrap_addr = addr - (addr%txsize);
				//78 - 78%64 = 78-14 = 64
	upper_wrap_addr = lower_wrap_addr + txsize - 1;
				//64 + 64 - 1 = 127
endfunction


endclass
