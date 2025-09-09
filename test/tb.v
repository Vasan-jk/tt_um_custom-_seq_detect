

  // Dump the signals to a VCD file. You can view it with gtkwave or surfer.


  // Wire up the inputs and outputs:
 `timescale 1ns/1ps

module tb_adaptive_neuron;

    reg        clk;
    reg        rst_n;
    reg        ena;
    reg  [7:0] ui_in;     // pattern input
    reg  [7:0] uio_in;    // includes serial bit + length
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // DUT instantiation
    tt_um_adaptive_neuron dut (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .ui_in(ui_in),
        .uio_in(uio_in),
        .uo_out(uo_out),
        .uio_out(uio_out),
        .uio_oe(uio_oe)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // Task to shift in a bit
    task send_bit;
        input din;
        begin
            uio_in[4] = din;
            @(posedge clk);
        end
    endtask

    initial begin
        // Initialize
        rst_n = 0;
        ena   = 0;
        ui_in = 8'b00000000;
        uio_in = 8'b00000000;
        #20;

        // Release reset
        rst_n = 1;
        ena   = 1;

        // ---------------------------------
        // TEST 1: Detect pattern "101" (length 3)
        // ---------------------------------
        ui_in = 8'b00000101;   // pattern = 101
        uio_in[3:0] = 4'd3;   // length = 3

        $display("=== TEST 1: Pattern 101, Length=3 ===");
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);  // match
        $display("uo_out = %b (expected 1)", uo_out[0]);

        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b0);  // mismatch
        $display("uo_out = %b (expected 0)", uo_out[0]);

        // ---------------------------------
        // TEST 2: Detect pattern "1101" (length 4)
        // ---------------------------------
        ui_in = 8'b00001101;   // pattern = 1101
        uio_in[3:0] = 4'd4;   // length = 4

        $display("=== TEST 2: Pattern 1101, Length=4 ===");
        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);  // match
        $display("uo_out = %b (expected 1)", uo_out[0]);

        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b1);  // mismatch
        $display("uo_out = %b (expected 0)", uo_out[0]);

        // ---------------------------------
        // TEST 3: Detect pattern "110011" (length 6)
        // ---------------------------------
        ui_in = 8'b110011;     // pattern = 110011
        uio_in[3:0] = 4'd6;    // length = 6

        $display("=== TEST 3: Pattern 110011, Length=6 ===");
        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);  // match
        $display("uo_out = %b (expected 1)", uo_out[0]);

        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b1);  // mismatch
        $display("uo_out = %b (expected 0)", uo_out[0]);

        // ---------------------------------
        // TEST 4: Detect pattern "0000" (length 4)
        // ---------------------------------
        ui_in = 8'b00000000;   // pattern = 0000
        uio_in[3:0] = 4'd4;    // length = 4

        $display("=== TEST 4: Pattern 0000, Length=4 ===");
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b0);  // match
        $display("uo_out = %b (expected 1)", uo_out[0]);

        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b0);
        send_bit(1'b0);  // mismatch
        $display("uo_out = %b (expected 0)", uo_out[0]);

        // Finish simulation
        #50;
        $finish;
    end
     initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

endmodule
