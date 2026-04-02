class ahb_mon extends uvm_monitor;
uvm_analysis_port#(ahb_tx) ap_port;
ahb_tx tx;
virtual ahb_intf.mon_mp vif;
trans_t prev_htrans = IDLE;
`uvm_component_utils(ahb_mon)
`NEW_COMP

function void build_phase(uvm_phase phase);
super.build_phase(phase);
ap_port = new("ap_port", this);
if (!uvm_resource_db#(virtual ahb_intf)::read_by_type("AHB", vif, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive ahb_vif handle from resource_db")
end
endfunction

task run_phase(uvm_phase phase);
forever begin
@(vif.mon_cb);
//if (vif.mon_cb.hreadyout == 1) begin
	case (vif.mon_cb.htrans) //current_htrans
		IDLE : begin
			case (prev_htrans)
				IDLE : begin
					//DO nothing
				end
				BUSY : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_BUSY_IDLE")
				end
				NONSEQ : begin
					data_phase();
					ap_port.write(tx);
					$display("WRITIGN TX TO AP_PORT");
					tx.print();
				end
				SEQ : begin
					data_phase();
					ap_port.write(tx);
					$display("WRITIGN TX TO AP_PORT");
					tx.print();
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
				end
				SEQ : begin
					data_phase();
				end
			endcase
		end
		NONSEQ : begin
			case (prev_htrans)
				IDLE : begin
					collect_addr_phase();
				end
				BUSY : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_BUSY_NONSEQ")
				end
				NONSEQ : begin
					data_phase();
					ap_port.write(tx);
					$display("WRITIGN TX TO AP_PORT");
					tx.print();
					collect_addr_phase(); //a new tx is starting, earlier tx should be written to ap_port
				end
				SEQ : begin
					data_phase();
					ap_port.write(tx);
					$display("WRITIGN TX TO AP_PORT");
					tx.print();
					collect_addr_phase();
				end
			endcase
		end
		SEQ : begin
			case (prev_htrans)
				IDLE : begin
					`uvm_error("AHB TX", "Illegal Htrans scenario : H_TRANS_IDLE_SEQ")
				end
				BUSY : begin
					//collect_addr_phase(); // we should not collect, since it will override the exisitng addr information
				end
				NONSEQ : begin
					data_phase();
					//collect_addr_phase();
				end
				SEQ : begin
					data_phase();
					//collect_addr_phase();
				end
			endcase
		end
	endcase
	prev_htrans = trans_t'(vif.mon_cb.htrans);
//end
end
endtask

task collect_addr_phase();
	tx = ahb_tx::type_id::create("tx");
	tx.addr = vif.mon_cb.haddr;
	tx.burst = burst_t'(vif.mon_cb.hburst);
	tx.prot = vif.mon_cb.hprot;
	tx.size = vif.mon_cb.hsize;
	tx.nonsec = vif.mon_cb.hnonsec;
	tx.excl = vif.mon_cb.hexcl;
	tx.wr_rd = vif.mon_cb.hwrite;
endtask

task data_phase();
	if (tx.wr_rd == 1) begin
		`uvm_info("MON", $psprintf("data_phase collected, addr = %h, data = %h, wr_rd = %h", tx.addr, vif.mon_cb.hwdata, tx.wr_rd), UVM_FULL);
		tx.dataQ.push_back(vif.mon_cb.hwdata);
	end
	if (tx.wr_rd == 0) begin
		`uvm_info("MON", $psprintf("data_phase collected, addr = %h, data = %h, wr_rd = %h", tx.addr, vif.mon_cb.hrdata, tx.wr_rd), UVM_FULL);
		tx.dataQ.push_back(vif.mon_cb.hrdata);
	end
endtask
endclass
