module ahb_assertion(hclk, hrst, haddr, hburst, hprot, hsize, hnonsec, hexcl, htrans, hwdata, hrdata, hwrite, hreadyout, hresp, hexokay); 
input hclk, hrst;
input [31:0] haddr;
input [2:0] hburst;
input [6:0] hprot;
input [2:0] hsize;
input hnonsec;
input hexcl;
input [1:0] htrans;
input [31:0] hwdata;
input [31:0] hrdata;
input hwrite;
input hreadyout;
input [1:0] hresp;
input hexokay;

property ahb_handshake_prop;
	@(posedge hclk) (htrans == 2'b10 || htrans == 2'b11) |-> ##[1:5] (hreadyout == 1);
endproperty
AHB_HANDSHAKE_PROP : assert property (ahb_handshake_prop);

//hwrite=1, next clock cycle hwdata=valid
property ahb_hwdata_valid_prop;
	@(posedge hclk) ((htrans == 2'b10 || htrans == 2'b11) && hwrite == 1) |-> ##1 ~($isunknown(hwdata))
endproperty
AHB_HWDATA_VALID_PROP : assert property (ahb_hwdata_valid_prop);

endmodule
