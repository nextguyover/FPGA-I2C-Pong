`define paddle_height 16

module process(
    input rst,
    input clk,

    output reg[63:0] fb_col_w_data,
    output reg[6:0] fb_col_sel,
    output reg fb_write,

    input [1:0] move_paddle_1,
    input [1:0] move_paddle_2
);

    reg[5:0] paddle_1;
    reg[5:0] paddle_2;

    integer i;

    wire input_clk, ball_clk;

    clk_div #(.DIVISION_RATE(32'h00A0000)) div_inst(clk, input_clk);    //divide clock for user input
    clk_div #(.DIVISION_RATE(32'h00A0000)) div_inst2(clk, ball_clk);    // divide clock for ball movement

    always @(posedge clk or posedge rst) begin  //on each clock, update a column of the frame buffer
        
        if(rst) begin
            fb_col_sel <= 0;

            fb_write <= 0;

        end else begin 
            fb_write = ~fb_write;

            fb_col_w_data = 64'h0;

            if(fb_write) begin
                // draw paddles
                if(fb_col_sel == 7'd0 || fb_col_sel == 7'd1 || fb_col_sel == 7'd127) begin
                    fb_col_w_data = fb_col_w_data | {`paddle_height{1'b1}} << paddle_1;
                end else if (fb_col_sel == 7'd124 || fb_col_sel == 7'd125 || fb_col_sel == 7'd126) begin
                    fb_col_w_data = fb_col_w_data | {`paddle_height{1'b1}} << paddle_2;
                end

                // draw ball
                if(fb_col_sel == ball_x_pos - 1 || fb_col_sel == ball_x_pos || fb_col_sel == ball_x_pos + 1) begin
                    fb_col_w_data = fb_col_w_data | 3'b111 << (ball_y_pos - 1);
                end

                fb_col_sel = fb_col_sel + 1;
            end
        end
    end

    always @(posedge input_clk or posedge rst) begin    //on each input_clk, update the paddle positions
        if(rst) begin
            paddle_1 <= 0;
            paddle_2 <= 0;
        end else begin
            if(move_paddle_1[0] != 1 ^ move_paddle_1[1] != 1) begin
                if (move_paddle_1[0] == 1 && paddle_1 < (64 - `paddle_height)) begin
                    paddle_1 <= paddle_1 + 1;
                end else if (move_paddle_1[1] == 1 && paddle_1 != 0) begin
                    paddle_1 <= paddle_1 - 1;
                end
            end
            if(move_paddle_2[0] != 1 ^ move_paddle_2[1] != 1) begin
                if (move_paddle_2[0] == 1 && paddle_2 < (64 - `paddle_height)) begin
                    paddle_2 <= paddle_2 + 1;
                end else if (move_paddle_2[1] == 1 && paddle_2 != 0) begin
                    paddle_2 <= paddle_2 - 1;
                end
            end
        end
    end

    reg[6:0] ball_x_pos;
    reg[5:0] ball_y_pos;

    reg[2:0] ball_x_velocity;
    reg[2:0] ball_y_velocity;

    reg ball_x_dir;
    reg ball_y_dir;

    reg[1:0] start_dir;

    always @(posedge ball_clk or posedge rst) begin // on each ball_clk, update the ball position
        if(rst) begin
            ball_x_velocity <= 3'b001;
            ball_y_velocity <= 3'b001;

            ball_x_pos <= 7'd64;
            ball_y_pos <= 6'd32;

            ball_x_dir <= 0;
            ball_y_dir <= 0;

            start_dir <= 2'b01;

        end else begin
            // check if ball hits paddle, if so, reverse x direction
            if(ball_x_pos == 7'd2 && (ball_y_pos <= (paddle_1 + `paddle_height) && ball_y_pos >= paddle_1)) begin
                ball_x_dir = ~ball_x_dir;
            end else if(ball_x_pos == 7'd124 && (ball_y_pos <= (paddle_2 + `paddle_height) && ball_y_pos >= paddle_2)) begin
                ball_x_dir = ~ball_x_dir;
            end

            if(ball_x_pos == 7'd0 || ball_x_pos == 7'd126) begin    // if ball goes out of bounds in x direction, reset
                ball_x_pos = 7'd64;
                ball_y_pos = 6'd32;

                case(start_dir)     //'randomize' the direction of the ball
                    2'b00: begin
                        ball_x_dir = 0;
                        ball_y_dir = 0;
                    end
                    2'b01: begin
                        ball_x_dir = 1;
                        ball_y_dir = 0;
                    end
                    2'b10: begin
                        ball_x_dir = 0;
                        ball_y_dir = 1;
                    end
                    2'b11: begin
                        ball_x_dir = 1;
                        ball_y_dir = 1;
                    end 
                endcase
                
                start_dir = start_dir + 1;
            end

            if(ball_y_pos == 6'd0 || ball_y_pos == 6'd63) begin   // if ball hits top or bottom of screen, reverse y direction
                ball_y_dir = ~ball_y_dir;
            end

            if(ball_x_dir) begin    // move the ball in the x direction
                ball_x_pos <= ball_x_pos + ball_x_velocity;
            end else begin
                ball_x_pos <= ball_x_pos - ball_x_velocity;
            end

            if(ball_y_dir) begin    // move the ball in the y direction
                ball_y_pos <= ball_y_pos + ball_y_velocity;
            end else begin
                ball_y_pos <= ball_y_pos - ball_y_velocity;
            end
        end
    end
        
endmodule