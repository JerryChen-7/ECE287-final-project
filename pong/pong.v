module pong (
    input clk;
    input rst;
    input [1:0]p1;
    input [1:0]p2;
    input start;
    output VGA_CLK;
    output VGA_VS;
    output VGA_HS;
    output VGA_R;
    output VGA_G;
    output VGA_B;

reg [7:0]S;
reg [7:0]NS;

parameter 	
		START       = 8'd0,
		INIT_P1     = 8'd1,
        INIT_P2     = 8'd2,
        INIT_BALL   = 8'd3,
		MOVE_P1     = 8'd4,
		DISP_P1     = 8'd5,
        MOVE_P2     = 8'd6,
        DISP_P2     = 8'd7,
        MOVE_BALL   = 8'd8,
        DISP_BALL   = 8'b9,
        P1_SCORE    = 8'd10,
        P2_SCORE    = 8'd12,
        P1_RST      = 8'd13,
        P2_RST      = 8'd14,
        P1_WIN      = 8'd15,
        P2_WIN      = 8'd16,
		ERROR       = 8'hffffffff;
			
always @(*)
begin
	case (S)
		START:
		begin
			if (start == 1'b1)
				NS = INIT_P1;
			else
				NS = START;
		end

        INIT_P1:
        begin
            //draw paddle 1
            NS = INIT_P2;
        end

        INIT_P2:
        begin
            //draw paddle 2
            NS = INIT_BALL;
        end

        INIT_BALL:
        begin
            //draw ball
            NS = MOVE_P1;
        end

        MOVE_P1:
        begin
            //move paddle 1
            NS = DISP_P1;
        end

        DISP_P1:
        begin
            //display paddle 1
            NS = MOVE_P2
        end

        MOVE_P2:
        begin
            //move paddle 2
            NS = DISP_P2;
        end

        DISP_P2:
        begin
            //display paddle 2
            NS = MOVE_BALL;
        end

        MOVE_BALL:
        begin
            //move ball
            NS = DISP_BALL;
        end

        DISP_BALL:
        begin
            //display ball
            NS = P1_SCORE;
        end

        P1_SCORE:
        begin
            //paddle 1 score
            NS = P2_SCORE;
        end

        P2_SCORE:
        begin
            //paddle 2 score
            NS = P1_RST;
        end

        P1_RST:
        begin
            //ball starts at paddle 1
            NS = P2_RST;
        end

        P2_RST:
        begin
            //ball starts at paddle 2
            NS = P1_WIN;
        end

        P1_WIN:
        begin
            //paddle 1 win
            NS = P2_WIN;
        end

        P2_WIN:
        begin
            //paddle 2 win
        end

		default:NS = ERROR;

	endcase
end

always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		i <= 1'b0;
		count <= 1'b0;
		done <= 1'b0;
	end
	else
		case (S)
			START:	temp_num <= input_number;

			FCOND:	begin end
			CHECK:	begin end

			ADD: 	count <= count + 1'b1;
			MOVE:	temp_num <= (temp_num[31:1]);
			INC:	i <= i + 1'b1;
			EXIT:	done <= 1'b1;
		endcase
end

/* FSM init and NS always */
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		S <= START;
	end
	else
	begin
		S <= NS;
	end
end


);
    
endmodule