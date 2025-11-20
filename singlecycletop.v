`include "pc.v"
`include "instructionmem.v"
`include "registerfile.v"
`include "immediate_extender.v"
`include "alu.v"
`include "controlunittop.v"
`include "datamemo.v"
`include "pcadder.v"
`include "mux.v"

module singletop (clk,rst_n);

input clk,rst_n;

wire [31:0] pctoaddr; // connects op of PC to ip of instruction memory
wire [31:0] imtoreg; // connects op of instructionmem to ip of registers 
wire [31:0] regtoalu1,regtoalu2; // connects op of reg to ip of alu
wire [31:0] imexttoalu; // connects op of extender to ip of alu
wire [3:0] cutoalu; // connects op of cu to ip of alu
wire [31:0] aluresult; // connects op of alu to ip of datamemo
wire regw; // connect op regwrite of CU to write_e of registers
wire [31:0] dmtoreg; // connects op of dm to write port of reg
wire [31:0] pc4; // pc + 4
wire [1:0] immsrcwire; 
wire memwr;
wire alusrcwire;
wire [31:0] muxop;
wire resultsrc;
wire [31:0] dmmuxop;
wire zero_wire;


programcounter pc (
    .pc(pctoaddr), // output to instruction memory
    .pcnext(pc4), // next address from PC adder
    .rst_n(rst_n),
    .clk(clk)
);

instruction_memory im(
    .address(pctoaddr), // gets PC output
    .readdata(imtoreg), // sends instruction to register file + CU + extender
    .rst_n(rst_n) 
);

multiplexer mxregtoalu (
    .i1(regtoalu2), // from register file read2
    .i2(imexttoalu), // immediate extended
    .sel(alusrcwire), // select from CU
    .out(muxop)
);

regfile rg (
    .addr_r1(imtoreg[19:15]), // rs1 from instruction
    .addr_r2(imtoreg[24:20]), // rs2 from instruction
    .addr_w1(imtoreg[11:7]), // rd from instruction
    .write(dmmuxop), // data to write (ALU/DM mux)
    .write_enable(regw), // regwrite from CU
    .read1(regtoalu1), // output to ALU
    .read2(regtoalu2), // output to ALU
    .clk(clk),
    .rst_n(rst_n)
);

extender immex (
    .inp(imtoreg), // instruction input
    .out(imexttoalu), // extended immediate to ALU
    .immsrc(immsrcwire) // type of immediate from CU
);

ctrlunit cu (
    .opcode(imtoreg[6:0]),
    .zero(zero_wire),
    .f3(imtoreg[14:12]),
    .f7(imtoreg[31:25]),
    .memtoreg(resultsrc),
    .alusrc(alusrcwire),
    .regwrite(regw),
    .memread(),
    .memwrite(memwr),
    .pcsrc(),
    .alucontrol(cutoalu),
    .immsrc(immsrcwire)
);

singlecyclealu alu (
    .i1(regtoalu1),
    .i2(muxop),
    .sel(cutoalu),
    .out(aluresult),
    .zero_flag(zero_wire),
    .negative_flag(),
    .carry_flag(),
    .overflow_flag()
);

datafile dm (
    .addr(aluresult[9:0]),
    .write_e(memwr),
    .write(regtoalu2),
    .read(dmtoreg),
    .clk(clk),
    .rst_n(rst_n)
);

pcadder pa (
    .i1(pctoaddr),
    .i2(32'd4),
    .sum(pc4)
);

multiplexer mxdmtorg (
    .i1(aluresult),
    .i2(dmtoreg),
    .sel(resultsrc),
    .out(dmmuxop)
);

endmodule