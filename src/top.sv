module top (
    input  logic clk_i,
    input  logic rst_i,

    output logic count_toggle_o
);

localparam WIDTH = 8;

logic [WIDTH-1:0] count;
logic count_toggle_reg;

counter counter_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .en_i(1'b1),
    .count_o(count)
);

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        count_toggle_reg <= 1'b0;
    end else begin
        if (count == (1 << WIDTH) - 1) begin
            count_toggle_reg <= ~count_toggle_reg;
        end
    end
end

assign count_toggle_o = count_toggle_reg;

endmodule 
