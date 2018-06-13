set proj_name "dma_example_adm7v3"
set root_dir [pwd]
set proj_dir $root_dir/$proj_name
set src_dir $root_dir/../hdl
set ip_dir $root_dir/../ip/
set ip_repo $root_dir/../iprepo
set constraints_dir $root_dir/../constraints

if { [file isdirectory $ip_repo] } {
	set lib_dir "$ip_repo"
} else {
	puts "ipRepository directory could not be found."
	exit 1
}
# Create project
create_project $proj_name $proj_dir

# Set project properties
set obj [get_projects $proj_name]
set_property part xc7vx690tffg1157-2 $obj
set_property "target_language" "Verilog" $obj

set_property IP_REPO_PATHS $lib_dir [current_fileset]
update_ip_catalog

# Add sources
add_files $src_dir/common
add_files -norecurse $src_dir/7series
add_files $src_dir/7series/adm7v3

#foreach subdir [glob -type d $ip_dir/fg1157/*] {
#	add_files [glob $subdir/*.xci]
#}
#add_files [glob ./ip/*.xcix]
add_files $ip_dir/mig_7series_0.dcp
add_files -fileset constrs_1 $constraints_dir/adm7v3.xdc

#create IPs

#Clock Converters

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_clock_converter_32 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {4} CONFIG.Component_Name {axis_clock_converter_32}] [get_ips axis_clock_converter_32]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_clock_converter_32/axis_clock_converter_32.xci]
update_compile_order -fileset sources_1

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_clock_converter_64 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {8} CONFIG.Component_Name {axis_clock_converter_64}] [get_ips axis_clock_converter_64]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_clock_converter_64/axis_clock_converter_64.xci]
update_compile_order -fileset sources_1

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_clock_converter_96 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {12} CONFIG.Component_Name {axis_clock_converter_96}] [get_ips axis_clock_converter_96]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_clock_converter_96/axis_clock_converter_96.xci]
update_compile_order -fileset sources_1

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_clock_converter_144 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {18} CONFIG.Component_Name {axis_clock_converter_144}] [get_ips axis_clock_converter_144]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_clock_converter_144/axis_clock_converter_144.xci]
update_compile_order -fileset sources_1

create_ip -name axis_clock_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_clock_converter_200 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {25} CONFIG.Component_Name {axis_clock_converter_200}] [get_ips axis_clock_converter_200]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_clock_converter_200/axis_clock_converter_200.xci]
update_compile_order -fileset sources_1


#Data Width Converters

create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_256_to_512_converter -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {32} CONFIG.M_TDATA_NUM_BYTES {64} CONFIG.HAS_TLAST {1} CONFIG.HAS_TKEEP {1} CONFIG.HAS_MI_TKEEP {1} CONFIG.Component_Name {axis_256_to_512_converter}] [get_ips axis_256_to_512_converter]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_256_to_512_converter/axis_256_to_512_converter.xci]
update_compile_order -fileset sources_1


create_ip -name axis_dwidth_converter -vendor xilinx.com -library ip -version 1.1 -module_name axis_512_to_256_converter -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.S_TDATA_NUM_BYTES {64} CONFIG.M_TDATA_NUM_BYTES {32} CONFIG.HAS_TLAST {1} CONFIG.HAS_TKEEP {1} CONFIG.HAS_MI_TKEEP {1} CONFIG.Component_Name {axis_512_to_256_converter}] [get_ips axis_512_to_256_converter]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_512_to_256_converter/axis_512_to_256_converter.xci]
update_compile_order -fileset sources_1


#Register slices
create_ip -name axis_register_slice -vendor xilinx.com -library ip -version 1.1 -module_name axis_register_slice_64 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {8} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axis_register_slice_64}] [get_ips axis_register_slice_64]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_register_slice_64/axis_register_slice_64.xci]
update_compile_order -fileset sources_1


#FIFOs

create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 1.1 -module_name axis_data_fifo_96 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {12} CONFIG.Component_Name {axis_data_fifo_96}] [get_ips axis_data_fifo_96]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_data_fifo_96/axis_data_fifo_96.xci]
update_compile_order -fileset sources_1

create_ip -name axis_data_fifo -vendor xilinx.com -library ip -version 1.1 -module_name axis_data_fifo_512_cc -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.TDATA_NUM_BYTES {64} CONFIG.IS_ACLK_ASYNC {1} CONFIG.HAS_TKEEP {1} CONFIG.HAS_TLAST {1} CONFIG.Component_Name {axis_data_fifo_512_cc}] [get_ips axis_data_fifo_512_cc]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axis_data_fifo_512_cc/axis_data_fifo_512_cc.xci]
update_compile_order -fileset sources_1


#Network
create_ip -name ten_gig_eth_pcs_pma -vendor xilinx.com -library ip -version 6.0 -module_name ten_gig_eth_pcs_pma_ip -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.MDIO_Management {false} CONFIG.base_kr {BASE-R} CONFIG.baser32 {64bit}] [get_ips ten_gig_eth_pcs_pma_ip]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/ten_gig_eth_pcs_pma_ip/ten_gig_eth_pcs_pma_ip.xci]
update_compile_order -fileset sources_1

create_ip -name ten_gig_eth_mac -vendor xilinx.com -library ip -version 15.1 -module_name ten_gig_eth_mac_ip -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.Management_Interface {false} CONFIG.Statistics_Gathering {false}] [get_ips ten_gig_eth_mac_ip]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/ten_gig_eth_mac_ip/ten_gig_eth_mac_ip.xci]
update_compile_order -fileset sources_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name axis_sync_fifo -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.INTERFACE_TYPE {AXI_STREAM} CONFIG.TDATA_NUM_BYTES {8} CONFIG.TUSER_WIDTH {0} CONFIG.Enable_TLAST {true} CONFIG.HAS_TKEEP {true} CONFIG.Enable_Data_Counts_axis {true} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.TSTRB_WIDTH {8} CONFIG.TKEEP_WIDTH {8} CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wach {15} CONFIG.Empty_Threshold_Assert_Value_wach {14} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_wrch {15} CONFIG.Empty_Threshold_Assert_Value_wrch {14} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.Full_Threshold_Assert_Value_rach {15} CONFIG.Empty_Threshold_Assert_Value_rach {14}] [get_ips axis_sync_fifo]
generate_target {instantiation_template} [get_files $ip_dir/ff1157/axis_sync_fifo/axis_sync_fifo.xci]
update_compile_order -fileset sources_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name cmd_fifo_xgemac_rxif -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.Component_Name {cmd_fifo_xgemac_rxif} CONFIG.Input_Data_Width {16} CONFIG.Output_Data_Width {16} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1} CONFIG.Enable_Safety_Circuit {true}] [get_ips cmd_fifo_xgemac_rxif]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/cmd_fifo_xgemac_rxif/cmd_fifo_xgemac_rxif.xci]
update_compile_order -fileset sources_1


create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name cmd_fifo_xgemac_txif -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.Input_Data_Width {1} CONFIG.Output_Data_Width {1} CONFIG.Reset_Type {Asynchronous_Reset} CONFIG.Full_Flags_Reset_Value {1}] [get_ips cmd_fifo_xgemac_txif]
generate_target {instantiation_template} [get_files $ip_dir/ff1157/cmd_fifo_xgemac_txif/cmd_fifo_xgemac_txif.xci]
update_compile_order -fileset sources_1

#Other IPs
create_ip -name xdma -vendor xilinx.com -library ip -version 4.1 -module_name xdma_ip -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.Component_Name {xdma_ip} CONFIG.pcie_blk_locn {X0Y2} CONFIG.pl_link_cap_max_link_width {X8} CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} CONFIG.axi_data_width {256_bit} CONFIG.axisten_freq {250} CONFIG.pf0_device_id {7038} CONFIG.pf0_base_class_menu {Memory_controller} CONFIG.pf0_class_code_base {05} CONFIG.pf0_sub_class_interface_menu {Other_memory_controller} CONFIG.pf0_class_code_sub {80} CONFIG.pf0_class_code_interface {00} CONFIG.pf0_class_code {058000} CONFIG.axilite_master_en {true} CONFIG.xdma_rnum_rids {64} CONFIG.xdma_wnum_rids {32} CONFIG.plltype {QPLL1} CONFIG.xdma_axi_intf_mm {AXI_Stream} CONFIG.xdma_pcie_64bit_en {true} CONFIG.dsc_bypass_rd {0001} CONFIG.dsc_bypass_wr {0001} CONFIG.xdma_sts_ports {true} CONFIG.pf0_msix_cap_table_bir {BAR_3:2} CONFIG.pf0_msix_cap_pba_bir {BAR_3:2} CONFIG.cfg_mgmt_if {false} CONFIG.PF0_DEVICE_ID_mqdma {9038} CONFIG.PF2_DEVICE_ID_mqdma {9038} CONFIG.PF3_DEVICE_ID_mqdma {9038}] [get_ips xdma_ip]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/xdma_ip/xdma_ip.xci]
update_compile_order -fileset sources_1


create_ip -name axi_register_slice -vendor xilinx.com -library ip -version 2.1 -module_name axi_register_slice -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.PROTOCOL {AXI4LITE} CONFIG.REG_W {7} CONFIG.REG_R {7} CONFIG.Component_Name {axi_register_slice}] [get_ips axi_register_slice]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/axi_register_slice/axi_register_slice.xci]
update_compile_order -fileset sources_1

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name register_bram_32 -dir $ip_dir/ffg1157
set_property -dict [list CONFIG.Component_Name {register_bram_32} CONFIG.Interface_Type {Native} CONFIG.Use_AXI_ID {false} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {9} CONFIG.Assume_Synchronous_Clk {false} CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {512} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {WRITE_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTB_Pin {false} CONFIG.Reset_Type {SYNC} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100} CONFIG.EN_SAFETY_CKT {false}] [get_ips register_bram_32]
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/register_bram_32/register_bram_32.xci]
update_compile_order -fileset sources_1


#HLS IPs
create_ip -name tlb -vendor ethz.systems.fpga -library hls -version 0.09 -module_name tlb_ip -dir $ip_dir/ffg1157
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/tlb_ip/tlb_ip.xci]
update_compile_order -fileset sources_1

create_ip -name mem_write_cmd_page_boundary_check_512 -vendor ethz.systems.fpga -library hls -version 0.3 -module_name mem_write_cmd_page_boundary_check_512_ip -dir $ip_dir/ffg1157
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/mem_write_cmd_page_boundary_check_512_ip/mem_write_cmd_page_boundary_check_512_ip.xci]
update_compile_order -fileset sources_1

create_ip -name dma_bench -vendor ethz.systems.fpga -library hls -version 0.1 -module_name dma_bench_ip -dir $ip_dir/ffg1157
generate_target {instantiation_template} [get_files $ip_dir/ffg1157/dma_bench_ip/dma_bench_ip.xci]
update_compile_order -fileset sources_1



start_gui
