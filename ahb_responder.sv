class ahb_responder extends uvm_driver#(ahb_tx);
virtual ahb_intf.slave_mp vif;
virtual ahb_intf vif_nocb;
virtual arb_intf.slave_mp arb_vif;
//Slave is essentially a memory with AHB interface
byte mem[*]; //assosicative array, why not dynamic array or fixed size array?
	//dynamic array: memory of 2**32 locations, address width is 32 bits
	//fixed size array : byte mem[1073741823:0];  //laptop will hang

bit [31:0] addr_t;
bit [2:0] burst_t;
bit [6:0] prot_t;
bit [2:0] size_t;
bit nonsec_t;
bit excl_t;
bit [1:0] prev_htrans;
bit write_t;
`uvm_component_utils_begin(ahb_responder)
`uvm_component_utils_end
`NEW_COMP

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_resource_db#(virtual ahb_intf)::read_by_type("AHB", vif, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive ahb_vif handle from resource_db")
end
if (!uvm_resource_db#(virtual ahb_intf)::read_by_type("AHB", vif_nocb, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive ahb_vif handle from resource_db")
end
if (!uvm_resource_db#(virtual arb_intf)::read_by_type("AHB", arb_vif, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive arb_vif handle from resource_db")
end
endfunction

task run_phase(uvm_phase phase);
//respond to the requests coming from master driver
fork
//Arbitration grant 
forever begin
	@(arb_vif.slave_cb);	
	arb_vif.slave_cb.hgrant <= 0;
	if (arb_vif.slave_cb.hbusreq[0] == 1) begin
		arb_vif.slave_cb.hgrant[0] <= 1;
	end
	else if (arb_vif.slave_cb.hbusreq[1] == 1) begin
		arb_vif.slave_cb.hgrant[1] <= 1;
	end
	//so on till 15
end
//Handling AHB write/read requests
forever begin
	//@(vif_nocb);
	@(posedge vif_nocb.hclk);
	vif_nocb.hreadyout = 0;
	//case (vif_nocb.htrans) //current_htrans
	//$display("%t : prev_htrans = %b, current_htrans = %b", $time, prev_htrans, vif_nocb.htrans);
	case (vif_nocb.htrans) //current_htrans
		IDLE : begin
			case (prev_htrans)
				IDLE : begin
					//DO nothing
					idle_phase();
				end
				BUSY : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_BUSY_IDLE")
				end
				NONSEQ : begin
					data_phase();  //If write is happening, store the data in to memory, if read is happening, provide the data.
					vif_nocb.hreadyout = 1;
				end
				SEQ : begin
					data_phase();
					vif_nocb.hreadyout = 1;
				end
			endcase
		end
		BUSY : begin
			case (prev_htrans)
				IDLE : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_IDLE_BUSY")
				end
				BUSY : begin
					//nothing
				end
				NONSEQ : begin
					data_phase();
					vif_nocb.hreadyout = 1;
				end
				SEQ : begin
					data_phase();
					vif_nocb.hreadyout = 1;
				end
			endcase
		end
		NONSEQ : begin
			case (prev_htrans)
				IDLE : begin
					$display("%t : CALLING collect_addr_phase", $time);
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
				BUSY : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_BUSY_NONSEQ")
				end
				NONSEQ : begin
					data_phase();
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
				SEQ : begin
					data_phase();
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
			endcase
		end
		SEQ : begin
			case (prev_htrans)
				IDLE : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_IDLE_SEQ")
				end
				BUSY : begin
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
				NONSEQ : begin
					data_phase();
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
				SEQ : begin
					data_phase();
					collect_addr_phase();
					vif_nocb.hreadyout = 1;
				end
			endcase
		end
	endcase
	prev_htrans = vif_nocb.htrans;
	//if (vif_nocb.htrans inside {NONSEQ, SEQ}) begin
	//	vif_nocb.hreadyout <= 1;
	//end
	//else begin
	//	vif_nocb.hreadyout <= 0;
	//end
end
join
endtask

//AHB works on pipelining nature, current cycle addr, burst, prot, size etc will be used in the next clock cycle data transfer
task collect_addr_phase();
	addr_t = vif_nocb.haddr;
	burst_t = vif_nocb.hburst;
	prot_t = vif_nocb.hprot;
	size_t = vif_nocb.hsize;
	nonsec_t = vif_nocb.hnonsec;
	excl_t = vif_nocb.hexcl;
	prev_htrans = vif_nocb.htrans;
	write_t = vif_nocb.hwrite;
	data_phase();
endtask

task data_phase();
bit [63:0] wdata_t, rdata_t;
	wdata_t = vif_nocb.hwdata;
for (int i = 0; i < 2**size_t; i=i+1) begin
	if (write_t == 1) begin
		mem[addr_t+i] = wdata_t[7:0];
		wdata_t >>= 8;
	end
	if (write_t == 0) begin
		rdata_t <<= 8;
		rdata_t[7:0] = mem[addr_t+2**size_t-1-i];
	end
end
	//vif_nocb.hrdata = rdata_t;
	vif.slave_cb.hrdata <= rdata_t;
endtask

task idle_phase();
	vif_nocb.hrdata[7:0] = 0;
	vif_nocb.hrdata[15:8] = 0;
	vif_nocb.hrdata[23:16] = 0;
	vif_nocb.hrdata[31:24] = 0;
endtask
endclass
