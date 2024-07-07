`define i2c_transmit_fsm_init 4'd0
`define i2c_transmit_fsm_start 4'd1
`define i2c_transmit_fsm_slave_addr_sending 4'd2
`define i2c_transmit_fsm_slave_addr_ack 4'd3
`define i2c_transmit_fsm_reg_addr_sending 4'd4
`define i2c_transmit_fsm_reg_addr_ack 4'd5
`define i2c_transmit_fsm_data_sending 4'd6
`define i2c_transmit_fsm_data_ack 4'd7
`define i2c_transmit_fsm_stop1 4'd8
`define i2c_transmit_fsm_stop2 4'd9
`define i2c_transmit_fsm_stop3 4'd10

// `define i2c_transmit_fsm_halt 4'd11

module i2c_transmitter(
    input rst,
    input fast_clk,

    output reg scl,
    inout sda,

    input[6:0] slave_addr,
    input[7:0] reg_addr,
    input[7:0] tx_data,
    
    input tx_en,

    output reg tx_done,
    output reg err,
    
    output reg[3:0] fsm_state,

    output reg sda_down
);

    reg[1:0] clk_counter;
    reg action_clk;

    reg[7:0] bit_cursor;

    wire[7:0] slave_addr_padded = {slave_addr, 1'b0};

    tri_buf tri_inst(.in_val(0), .out_val(sda), .enable(sda_down));

    always @(posedge fast_clk or posedge rst) begin
        
        if(rst == 1) begin
            fsm_state <= `i2c_transmit_fsm_start;
            scl <= 1;
            sda_down <= 0;
            clk_counter <= 0;
            tx_done <= 0;
            err <= 0;

        end else begin
            case(clk_counter)
                2'b00: begin
                    scl <= 1;
                end
                2'b10: begin
                    if(tx_en && !tx_done) begin
                        scl <= 0;
                    end
                end
            endcase

            clk_counter <= clk_counter + 1;
                
            if(clk_counter == 2'b01 || clk_counter == 2'b11) begin
                case(fsm_state)
                    `i2c_transmit_fsm_start: begin
                        if(scl && tx_en) begin
                            tx_done <= 0;
                            sda_down <= 1;
                            fsm_state <= `i2c_transmit_fsm_slave_addr_sending;
                            bit_cursor <= 8'b10000000;
                        end
                    end
                    
                    `i2c_transmit_fsm_slave_addr_sending: begin
                        if(~scl) begin
                            if(bit_cursor != 8'b0) begin
                                sda_down <= ~(| (slave_addr_padded & bit_cursor));
                            end else begin
                                sda_down <= 0;
                                fsm_state <= `i2c_transmit_fsm_slave_addr_ack;
                            end
                        end else begin
                            bit_cursor <= bit_cursor >> 1;
                        end
                    end
                    
                    `i2c_transmit_fsm_slave_addr_ack: begin 
                        if(~sda) begin 
                            fsm_state <= `i2c_transmit_fsm_reg_addr_sending;
                            bit_cursor <= 8'b10000000;
                        end else begin 
                            // err <= 1;
                            // tx_done <= 1;
                            fsm_state <= `i2c_transmit_fsm_start;   // retry if send failed
                        end 
                    end
                    
                    `i2c_transmit_fsm_reg_addr_sending: begin
                        if(~scl) begin
                            if(bit_cursor != 8'b0) begin
                                sda_down <= ~(| (reg_addr & bit_cursor));
                            end else begin
                                sda_down <= 0;
                                fsm_state <= `i2c_transmit_fsm_reg_addr_ack;
                            end
                        end else begin
                            bit_cursor <= bit_cursor >> 1;
                        end
                    end
                    
                    `i2c_transmit_fsm_reg_addr_ack: begin 
                        if(~sda) begin 
                            fsm_state <= `i2c_transmit_fsm_data_sending;
                            bit_cursor <= 8'b10000000;
                        end else begin 
                            // err <= 1;
                            // tx_done <= 1;
                            fsm_state <= `i2c_transmit_fsm_start;   // retry if send failed
                        end 
                    end
                    
                    
                    `i2c_transmit_fsm_data_sending: begin
                        if(~scl) begin
                            if(bit_cursor != 8'b0) begin
                                sda_down <= ~(| (tx_data & bit_cursor));
                            end else begin
                                sda_down <= 0;
                                fsm_state <= `i2c_transmit_fsm_data_ack;
                            end
                        end else begin
                            bit_cursor <= bit_cursor >> 1;
                        end
                    end

                    `i2c_transmit_fsm_data_ack: begin 
                        if(~sda) begin 
                            fsm_state <= `i2c_transmit_fsm_stop1;
                            bit_cursor <= 8'b10000000;
                        end else begin 
                            // err <= 1;
                            // tx_done <= 1;
                            fsm_state <= `i2c_transmit_fsm_start;   // retry if send failed
                        end
                    end
                    
                    `i2c_transmit_fsm_stop1: begin 
                        if(!scl) begin
                            sda_down <= 1;
                            fsm_state <= `i2c_transmit_fsm_stop2;
                        end
                    end

                    `i2c_transmit_fsm_stop2: begin 
                        sda_down <= 0;
                        fsm_state <= `i2c_transmit_fsm_stop3;
                        tx_done <= 1;
                    end

                    `i2c_transmit_fsm_stop3: begin
                        fsm_state <= `i2c_transmit_fsm_start;
                        tx_done <= 0;
                    end
                endcase
            end
        end
    end

endmodule