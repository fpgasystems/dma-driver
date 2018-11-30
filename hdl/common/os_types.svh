`ifndef TYPES_SVH_
`define TYPES_SVH_
`default_nettype none
//package OStypes;


//typedef int NUM_DDR_CHANNELS = 2;//TODO change
//const int NUM_DDR_CHANNELS = 2;
parameter NUM_DDR_CHANNELS = 2;

/*typedef struct packed {
    logic[511:0]    data;
    logic[63:0]     keep;
    logic           last;
} axi_word_512_t;

typedef struct packed {
    logic[63:0]     address;
    logic[31:0]     length;
} mem_cmd_t;*/


interface axis_mem_cmd;
    logic valid;
    logic ready;
    logic[63:0]     address;
    logic[31:0]     length;

    modport master (output valid,
                    input ready,
                    output address,
                    output length);

    modport slave ( input valid,
                    output ready,
                    input address,
                    input length);

endinterface

interface axi_stream;
    logic valid;
    logic ready;
    logic[511:0]    data;
    logic[63:0]     keep;
    logic           last;

    modport master (output valid,
                    input ready,
                    output data,
                    output keep,
                    output last);

    modport slave ( input valid,
                    output ready,
                    input data,
                    input keep,
                    input last);

endinterface

interface axis_mem_status;
    logic valid;
    logic ready;
    logic[7:0]     data;

    modport master (output valid,
                    input  ready,
                    output data);

    modport slave ( input  valid,
                    output ready,
                    input  data);
endinterface


interface axi_lite;
    //write address
    logic [31: 0]   awaddr;
    logic           awvalid;
    logic           awready;
 
    //write data
    logic [31: 0]   wdata;
    logic [3: 0]    wstrb;
    logic           wvalid;
    logic           wready;
 
    //write response (handhake)
    logic [1:0]     bresp;
    logic           bvalid;
    logic           bready;
 
    //read address
    logic [31: 0]   araddr;
    logic           arvalid;
    logic           arready;
 
    //read data
    logic [31: 0]   rdata;
    logic [1:0]     rresp;
    logic           rvalid;
    logic           rready;

    modport master (output  awvalid,
                    input   awready,
                    output  awaddr,
                    output  wdata,
                    output  wstrb,
                    output  wvalid,
                    input   wready,
                    output  arvalid,
                    input   arready,
                    output  araddr,
                    input   rvalid,
                    output  rready,
                    input   rdata,
                    input   rresp);

    modport slave ( input   awvalid,
                    output  awready,
                    input   awaddr,
                    input   wdata,
                    input   wstrb,
                    input   wvalid,
                    output  wready,
                    input   arvalid,
                    output  arready,
                    input   araddr,
                    output  rvalid,
                    input   rready,
                    output  rdata,
                    output  rresp);

endinterface


//endpackage

`endif