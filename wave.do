onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group AHB_PIF /top/pif/hclk
add wave -noupdate -expand -group AHB_PIF /top/pif/hrst
add wave -noupdate -expand -group AHB_PIF /top/pif/haddr
add wave -noupdate -expand -group AHB_PIF /top/pif/hburst
add wave -noupdate -expand -group AHB_PIF /top/pif/hprot
add wave -noupdate -expand -group AHB_PIF /top/pif/hsize
add wave -noupdate -expand -group AHB_PIF /top/pif/hnonsec
add wave -noupdate -expand -group AHB_PIF /top/pif/hexcl
add wave -noupdate -expand -group AHB_PIF /top/pif/htrans
add wave -noupdate -expand -group AHB_PIF /top/pif/hwdata
add wave -noupdate -expand -group AHB_PIF /top/pif/hrdata
add wave -noupdate -expand -group AHB_PIF /top/pif/hwrite
add wave -noupdate -expand -group AHB_PIF /top/pif/hreadyout
add wave -noupdate -expand -group AHB_PIF /top/pif/hresp
add wave -noupdate -expand -group AHB_PIF /top/pif/hexokay
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hclk
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hrst
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hbusreq
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hlock
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hgrant
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hmaster
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hmastlock
add wave -noupdate -expand -group ARB_PIF /top/arb_pif/hsplit
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 1
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {299 ns}
