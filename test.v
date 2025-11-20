`timescale 1ns/1ps

module tb_singletop;

reg clk;
reg rst_n;

// Instantiate DUT
singletop dut(
    .clk(clk),
    .rst_n(rst_n)
);

// Generate 10ns clock
always #5 clk = ~clk;

// Monitor register x5 and PC every cycle
always @(posedge clk) begin
    $display("Time=%0t  PC=%0d  x5=%h", $time, dut.pctoaddr, dut.rg.registerarray[5]);
end

initial begin
    clk = 0;
    rst_n = 0;

    $display("Applying reset...");
    #20 rst_n = 1;          // release reset after 20ns

    // Initialize registers
    dut.rg.registerarray[6] = 32'h12345678;   // NEW non-palindrome test value
    dut.rg.registerarray[5] = 32'h0;


    $display("Initial x6 = %h", dut.rg.registerarray[6]);

    // Let CPU run instructions
    #200;

    $display("\n--- FINAL RESULT ---");
    $display("x5 = %h", dut.rg.registerarray[5]);
    $finish;
end

endmodule
