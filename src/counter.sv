module counter #(
    parameter WIDTH = 8
)(
    input  logic clk_i,
    input  logic rst_i,
    input  logic en_i,

    output logic [WIDTH-1:0] count_o
);

logic [WIDTH-1:0] count_reg;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        count_reg <= '0;
    end else if (en_i) begin
        if (count_reg == (1 << WIDTH) - 1) begin 
            count_reg <= '0;
        end else begin
            count_reg <= count_reg + 1;
        end
    end else begin
        count_reg <= count_reg;
    end
end

assign count_o = count_reg;

endmodule
