vlog -sv +incdir+/home/projects/src\
+incdir+../MASTER\
+incdir+../SLAVE\
+incdir+../COMMON\
+incdir+../TOP\
+define+UVM_NO_DPI\
  ../TOP/top.sv
vsim top +UVM_TESTNAME=ahb_mult_wr_rd_test -l run.log +UVM_TIMEOUT=5000 +UVM_VERBOSITY=UVM_MEDIUM
do wave.do
run -all
