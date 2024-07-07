module i2c_TB;
    reg clk;
    reg rst;

    initial begin
        rst = 1;
        #50;
        clk = 0;
    end

    always begin
        #50;
        clk = ~clk;
        rst = 0;
    end

    wire TX_DONE;
    wire I2C_ERR;
    wire DISP_I2C_SCL;
    wire DISP_I2C_SDA;
    

    i2c_transmitter test_inst(
        .rst(rst), 
        .fast_clk(clk), 
        .scl(DISP_I2C_SCL), 
        .sda(DISP_I2C_SDA), 
        .slave_addr(7'b1010101), 
        .reg_addr(8'b10101010), 
        .tx_data(8'b10101010), 
        .tx_en(1), 
        .tx_done(TX_DONE), 
        .err(I2C_ERR)
    );
endmodule