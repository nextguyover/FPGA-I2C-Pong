`define fb_fsm_standby 4'd0
`define fb_fsm_send_addr_page 4'd1
`define fb_fsm_send_addr_col_msb 4'd2
`define fb_fsm_send_addr_col_lsb 4'd3
`define fb_fsm_send_data 4'd4
`define fb_fsm_ptr_increment 4'd5
`define fb_fsm_send_auto_inc_col 4'd6

module frame_buffer(
    input rst,
    input clk,

    output reg[7:0] fb_data,
    output reg[7:0] fb_addr,

    input fb_start,

    input tx_done,

	input[63:0] fb_col_w_data,
    input[6:0] fb_col_sel,
    input fb_write,

    output reg[3:0] fsm_state,

    output wire full_screen_refreshed
);

    reg[63:0] fb[128];
    reg[6:0] col_ptr;     //0->127
    reg[3:0] page_ptr;     //0->7

    reg clk_div;

    reg[1:0] pattern;

    integer i;

    assign full_screen_refreshed = (col_ptr == 7'b1111111 && page_ptr == 4'b1111);

    always @(posedge clk or posedge rst) begin
        
        if(rst) begin
            fsm_state <= `fb_fsm_standby;

            col_ptr <= 0;
            page_ptr <= 0;

        end else begin 
            clk_div <= ~clk_div;

            if(clk_div == 1 && tx_done == 1) begin
                case(fsm_state)
                    `fb_fsm_standby: begin                //wait for start signal
                        if(fb_start == 1) begin
                            fsm_state <= `fb_fsm_send_auto_inc_col;
                        end
                    end
                    `fb_fsm_send_auto_inc_col: begin        //enable auto increment
                        fb_addr <= 8'b0;
                        fb_data <= 8'b11100000;
                        fsm_state <= `fb_fsm_send_addr_page;
                    end
                    `fb_fsm_send_addr_page: begin           //set page (row of 8 pixels)
                        fb_addr <= 8'b0;
                        fb_data <= {4'b1011, page_ptr};
                        fsm_state <= `fb_fsm_send_addr_col_msb;
                    end
                    `fb_fsm_send_addr_col_msb: begin        //set most significant bit of column
                        fb_addr <= 8'b0;
                        fb_data <= {5'b00010, col_ptr[6:4]};
                        fsm_state <= `fb_fsm_send_addr_col_lsb;
                    end
                    `fb_fsm_send_addr_col_lsb: begin        //set least significant bit of column
                        fb_addr <= 8'b0;
                        fb_data <= {4'b0000, col_ptr[3:0]};
                        fsm_state <= `fb_fsm_send_data;
                    end
                    `fb_fsm_send_data: begin                //set display data
                        fb_addr <= 8'h40;
                        fb_data <= fb[col_ptr] >> page_ptr * 8;

                        col_ptr <= col_ptr + 1;             //increment column

                        if(col_ptr == 7'b1111111) begin     //if we've reached the end of the screen
                            page_ptr <= page_ptr + 1;       //increment page (row of 8 pixels)
                            fsm_state <= `fb_fsm_send_addr_page;    //go to set the page
                        end else begin
                            fsm_state <= `fb_fsm_send_data; // if not at end of screen, stay in same state
                        end
                    end
                endcase
            end
        end
    end

    always @(posedge fb_write) begin
        fb[fb_col_sel] <= fb_col_w_data;
    end

endmodule