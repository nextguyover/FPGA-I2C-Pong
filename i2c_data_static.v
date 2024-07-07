`define fsm_

module i2c_data_static(
    input rst,
    input clk,

    output[7:0] reg_addr,
    output[7:0] tx_data,

    output reg tx_en,
    input tx_done,

    output reg init_complete
);

    reg[7:0] data_ptr;

    reg[7:0] reg_addr_arr[10];
    reg[7:0] tx_data_arr[10];

    assign reg_addr = reg_addr_arr[data_ptr];
    assign tx_data = tx_data_arr[data_ptr];

    reg clk_div;

    always @(posedge clk or posedge rst) begin
        
        if(rst) begin
            data_ptr <= 0;
            init_complete <= 0;

            reg_addr_arr[0] <= 8'b0;
            tx_data_arr[0] <= 8'hE2;    //software reset

            reg_addr_arr[1] <= 8'b0;
            tx_data_arr[1] <= 8'hA2;    //set bias select

            reg_addr_arr[2] <= 8'b0;
            tx_data_arr[2] <= 8'hA0;    //set scan direction left to right
            reg_addr_arr[3] <= 8'b0;
            tx_data_arr[3] <= 8'hC8;    //flip vertical direction (starts zero at top)

            reg_addr_arr[4] <= 8'b0;
            tx_data_arr[4] <= 8'h25;    //set regulation ratio for regulator driving LCD (adjusts contrast)

            reg_addr_arr[5] <= 8'b0;
            tx_data_arr[5] <= 8'h81;    //start setting EV level
            reg_addr_arr[6] <= 8'b0;
            tx_data_arr[6] <= 8'h20;    //set EV level

            reg_addr_arr[7] <= 8'b0;
            tx_data_arr[7] <= 8'h2F;    //enable power control circuits

            reg_addr_arr[8] <= 8'b0;
            tx_data_arr[8] <= 8'hAF;   //display on
            reg_addr_arr[9] <= 8'b0;
            tx_data_arr[9] <= 8'h40;   //set initial display line to zero

            tx_en <= 1;

        end else begin 
            clk_div <= ~clk_div;

            if(clk_div == 1 && tx_done == 1) begin
                if(data_ptr < 10) begin
                    data_ptr <= data_ptr + 1;   // increment through all static data and send
                    tx_en <= 1;
                end else begin
                    init_complete <= 1;
                end
            end 
        end
    end

endmodule