module clk_div(input clk_in, output reg div_out);

    parameter [31:0] DIVISION_RATE = 16'hFFFF;

    reg[31:0] counter;

    always @(posedge clk_in) begin
        counter = counter + 1'b1;

        if(counter == DIVISION_RATE) begin
            counter = 32'h00000000;

            div_out = div_out == 0 ? 1 : 0;
        end
    end

endmodule