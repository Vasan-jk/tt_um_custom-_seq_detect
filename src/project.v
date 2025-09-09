
// ==================================================
// Adaptive Pattern Detector using only neuron blocks
// ==================================================

module tt_um_adaptive_neuron (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena,
    input  wire [7:0] ui_in,    // expected pattern bits
    input  wire [7:0] uio_in,   // uio_in[3:0] = length, uio_in[4] = serial stream
    output reg  [7:0] uo_out,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe
);

    // -------------------------------
    // Inputs
    // -------------------------------
    wire [3:0] pat_length = uio_in[3:0];  // pattern length
    wire       din        = uio_in[4];    // serial input stream

    // -------------------------------
    // Shift register for input bits
    // -------------------------------
    reg [7:0] shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 8'd0;
        else if (ena)
            shift_reg <= {shift_reg[6:0], din};
    end

    // -------------------------------
    // Compare each bit using neurons
    // -------------------------------
    wire [7:0] compare_out;

    genvar i;
    generate
        for (i=0; i<8; i=i+1) begin : COMPARE
            bit_compare_neuron BC (
                .clk(clk),
                .rst_n(rst_n),
                .a(shift_reg[i]),
                .b(ui_in[i]),
                .y(compare_out[i])
            );
        end
    endgenerate

    // -------------------------------
    // Final match detector
    // -------------------------------
    reg match;
    always @(clk or rst_n or ena or ui_in or uio_in) begin
        case (pat_length)
            4'd1: match = compare_out[0];
            4'd2: match = &compare_out[1:0];
            4'd3: match = &compare_out[2:0];
            4'd4: match = &compare_out[3:0];
            4'd5: match = &compare_out[4:0];
            4'd6: match = &compare_out[5:0];
            4'd7: match = &compare_out[6:0];
            4'd8: match = &compare_out[7:0];
            default: match = 1'b0;
        endcase
    end

    // -------------------------------
    // Pulse-hold logic: output stays 1 for 5 cycles
    // -------------------------------
    reg [2:0] hold_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uo_out   <= 8'd0;
            hold_cnt <= 3'd0;
        end
        else if (match && hold_cnt == 0) begin
            uo_out   <= 8'b00000001;
            hold_cnt <= 3'd3;
        end
        else if (hold_cnt > 0) begin
            hold_cnt <= hold_cnt - 1;
            if (hold_cnt == 1)
                uo_out <= 8'd0;
        end
    end

    assign uio_out = 8'd0;
    assign uio_oe  = 8'd0;

endmodule



// ==================================================
// Original Neuron module (kept clean)
// ==================================================
module neuron #(
    parameter W0 = 1,
    parameter W1 = 1,
    parameter BIAS = 0,
    parameter THRESH = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [3:0] x0,
    input  wire [3:0] x1,
    output reg  y
);

    wire [7:0] p0  = W0 * x0;
    wire [7:0] p1  = W1 * x1;
    wire [8:0] sum = p0 + p1 + BIAS;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            y <= 1'b0;
        else
            y <= (sum > THRESH);
    end

endmodule


// ==================================================
// Bit comparator using neuron primitive
// ==================================================
module bit_compare_neuron (
    input  wire clk,
    input  wire rst_n,
    input  wire a,
    input  wire b,
    output wire y
);

    wire [3:0] xa = {3'b000, a};
    wire [3:0] xb = {3'b000, b};

    // y = 1 if (a == b)
    neuron #(.W0(1), .W1(-1), .BIAS(0), .THRESH(0)) cmp (
        .clk(clk),
        .rst_n(rst_n),
        .x0(xa),
        .x1(xb),
        .y(y)
    );

endmodule
