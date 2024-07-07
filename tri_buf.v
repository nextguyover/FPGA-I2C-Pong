module tri_buf(
        input in_val,
        output reg out_val,
        input enable
    );

    always @(enable, in_val) begin
        if (enable) begin
            out_val = in_val;
        end else begin
            out_val = 1'bz;
        end
    end
endmodule