interface arb_intf(input logic hclk, hrst);
logic [15:0] hbusreq;
logic [15:0] hlock;
logic [15:0] hgrant;
logic [3:0] hmaster;
logic hmastlock;
logic [15:0] hsplit;

clocking master_cb@(posedge hclk);
default input #0 output #1;
output hbusreq;
output hlock;
input hgrant;
output hmaster;
output hmastlock;
input hsplit;
endclocking

clocking slave_cb@(posedge hclk);
default input #0 output #1;
input hbusreq;
input hlock;
output hgrant;
input hmaster;
input hmastlock;
output hsplit;
endclocking

clocking mon_cb@(posedge hclk);
default input #0;
input hbusreq;
input hlock;
input hgrant;
input hmaster;
input hmastlock;
input hsplit;
endclocking

modport master_mp(clocking master_cb);
modport slave_mp(clocking slave_cb);
modport mon_mp(clocking mon_cb);
endinterface
