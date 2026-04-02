class ahb_base_seq extends uvm_sequence#(ahb_tx);
	`uvm_object_utils(ahb_base_seq)
	`NEW_OBJ
	task pre_body();
		uvm_phase phase = get_starting_phase();
		if (phase != null) begin
			$display("Raising objection");
			phase.phase_done.set_drain_time(this, 100);
			phase.raise_objection(this);
		end
	endtask
	task post_body();
		uvm_phase phase = get_starting_phase();
		if (phase != null) begin
			$display("Drop objection");
			phase.drop_objection(this);
		end
	endtask
endclass


class ahb_wr_rd_seq extends ahb_base_seq; //ahb_wr_rd_seq will be based on ahb_tx
bit [31:0] wr_addr;
	`uvm_object_utils(ahb_wr_rd_seq)
	`NEW_OBJ
	task body();
		repeat(1) begin
			`uvm_do_with(req, {req.wr_rd == 1;})  //write tx
			wr_addr = req.addr;
		end
		repeat(1) `uvm_do_with(req, {req.wr_rd == 0; req.addr == wr_addr;})  //read tx
	endtask
endclass

class ahb_mult_wr_rd_seq extends ahb_base_seq; //ahb_wr_rd_seq will be based on ahb_tx
bit [31:0] wr_addrQ[$];
bit [31:0] addr_x;
int num_tx;
	`uvm_object_utils(ahb_mult_wr_rd_seq)
	`NEW_OBJ
	task body();
		uvm_resource_db#(int)::read_by_name("GLOBAL", "NUM_TX", num_tx);
		repeat(num_tx) begin
			`uvm_do_with(req, {req.wr_rd == 1;})  //write tx
			wr_addrQ.push_back(req.addr);
		end
		foreach (wr_addrQ[i]) begin
			$display("addr = %h", wr_addrQ[i]);
		end
		repeat(num_tx) begin
			addr_x = wr_addrQ.pop_front();
			`uvm_do_with(req, {req.wr_rd == 0; req.addr == addr_x;})  //read tx
		end
	endtask
endclass
