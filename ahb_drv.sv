class ahb_drv extends uvm_driver#(ahb_tx);
virtual ahb_intf.master_mp vif;
virtual arb_intf.master_mp arb_vif;
`uvm_component_utils_begin(ahb_drv)
`uvm_component_utils_end
`NEW_COMP

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if (!uvm_resource_db#(virtual ahb_intf)::read_by_type("AHB", vif, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive ahb_vif handle from resource_db")
end
if (!uvm_resource_db#(virtual arb_intf)::read_by_type("AHB", arb_vif, this)) begin
	`uvm_error("RESOURCE_DB_ERROR", "Not able to retrive arb_vif handle from resource_db")
end
endfunction

task run_phase(uvm_phase phase);
	wait (vif.master_cb.hrst == 0);
	forever begin
		seq_item_port.get_next_item(req);
		//req.print();
		drive_tx(req); //drive the AHB interface with this request
		seq_item_port.item_done();  //I am done with this item
	end
endtask

task drive_tx(ahb_tx req);
	arb_phase(req);
	//implement burst_len number of phases
	//also implement pipelining
	addr_phase(req, 1);
	for (int i = 0; i < req.len-1; i=i+1) begin
	fork
		data_phase(req);
		addr_phase(req);
	join
	end
	data_phase(req);
	set_default_values();
endtask

task set_default_values();
	arb_vif.master_cb.hbusreq <= 0; //req.master indicate which master is making request, correspnding hbusreq is driven to '1'
	arb_vif.master_cb.hlock <= 0;
	vif.master_cb.haddr <= 0;
	vif.master_cb.hburst <= 0;
	vif.master_cb.hprot <= 0;
	vif.master_cb.hsize <= 0;
	vif.master_cb.hnonsec <= 0;
	vif.master_cb.hexcl <= 0;
	vif.master_cb.htrans <= IDLE;
	vif.master_cb.hwrite <= 0;
	@(vif.master_cb); 
	vif.master_cb.hwdata <= 0;
endtask

task arb_phase(ahb_tx req);
	`uvm_info("AHB_TX", "arb_phase", UVM_FULL)
	//signals required for arb phase
	@(arb_vif.master_cb);
	arb_vif.master_cb.hbusreq[req.master] <= 1; //req.master indicate which master is making request, correspnding hbusreq is driven to '1'
	arb_vif.master_cb.hlock[req.master] <= req.mastlock;
	wait (arb_vif.master_cb.hgrant[req.master] == 1); //Master is not getting the grant
	arb_vif.master_cb.hmaster <= req.master;
	arb_vif.master_cb.hmastlock <= req.mastlock;
endtask

task addr_phase(ahb_tx req=null, bit first_beat_f = 0);
	`uvm_info("AHB_TX", "addr_phase", UVM_FULL)
	@(vif.master_cb);
	vif.master_cb.haddr <= req.addr_t;
	vif.master_cb.hburst <= req.burst;
	vif.master_cb.hprot <= req.prot;
	vif.master_cb.hsize <= req.size;
	vif.master_cb.hnonsec <= req.nonsec;
	vif.master_cb.hexcl <= req.excl;
	if (first_beat_f == 1) vif.master_cb.htrans <= NONSEQ;
	if (first_beat_f == 0) vif.master_cb.htrans <= SEQ; 
	vif.master_cb.hwrite <= req.wr_rd;
	//do not wait for hready in 1st beat
	req.addr_t = req.addr_t + 2**req.size;
	if (first_beat_f == 0) wait (vif.master_cb.hreadyout == 1);
endtask

task data_phase(ahb_tx req);
	`uvm_info("AHB_TX", "data_phase", UVM_FULL)
	@(vif.master_cb);
	if (req.wr_rd == 1) vif.master_cb.hwdata <= req.dataQ.pop_front();
	if (req.wr_rd == 0) req.dataQ.push_back(vif.master_cb.hrdata);
	req.resp = vif.master_cb.hresp;
	if (vif.master_cb.hresp == ERROR) begin
		`uvm_error("AHB_TX", "Slave issued Error response")
	end
	`uvm_info("AHB_TX", $psprintf("Driving data=%h at addr=%d", vif.master_cb.hwdata, req.addr_t), UVM_FULL)
	wait (vif.master_cb.hreadyout == 1);
endtask

endclass
