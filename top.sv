`include "uvm_pkg.sv"
import uvm_pkg::*;  //everything of uvm_pkg becomes part of my TB now
`include "ahb_common.sv"
`include "ahb_intf.sv"
`include "arb_intf.sv"
`include "ahb_tx.sv"
`include "ahb_seq_lib.sv"
`include "ahb_sbd.sv"
`include "ahb_sqr.sv"
`include "ahb_drv.sv"
`include "ahb_responder.sv"
`include "ahb_mon.sv"
`include "ahb_cov.sv"
`include "ahb_magent.sv"
`include "ahb_sagent.sv"
`include "ahb_env.sv"
`include "ahb_assertion.sv"
module top;
reg clk, rst;
integer count;
ahb_intf pif(clk, rst);
arb_intf arb_pif(clk, rst);
ahb_assertion ahb_assertion_i(pif.hclk, pif.hrst, pif.haddr, pif.hburst, pif.hprot, pif.hsize, pif.hnonsec, pif.hexcl, pif.htrans, pif.hwdata, pif.hrdata, pif.hwrite, pif.hreadyout, pif.hresp, pif.hexokay); 

initial begin
	clk = 0;
	forever #5 clk = ~clk;
end
initial begin
	rst = 1;
	drive_reset_values();
	#20;
	rst = 0;
end

task drive_reset_values();
	pif.haddr = 0;
	pif.hburst = 0;
	pif.hprot = 0;
	pif.hsize = 0;
	pif.hnonsec = 0;
	pif.hexcl = 0;
	pif.htrans = 0;
	pif.hwdata = 0;
	pif.hrdata = 0;
	pif.hwrite = 0;
	pif.hreadyout = 0;
	pif.hresp = 0;
	pif.hexokay = 0;
	//
	arb_pif.hbusreq = 0;
	arb_pif.hlock = 0;
	arb_pif.hgrant = 0;
	arb_pif.hmaster = 0;
	arb_pif.hmastlock = 0;
	arb_pif.hsplit = 0;
endtask

`include "test_lib.sv"
initial begin
	run_test("ahb_base_test");
end
initial begin
	$value$plusargs("count=%d",count);
	uvm_resource_db#(virtual ahb_intf)::set("AHB", "VIF", pif, null); //now pif will accessible everywhere in TB
	uvm_resource_db#(virtual arb_intf)::set("AHB", "ARB_VIF", arb_pif, null); //now pif will accessible everywhere in TB
end
endmodule
