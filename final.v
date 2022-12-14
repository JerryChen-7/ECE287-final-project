module final(
	input clk,
	input rst,
	input [3:0] button,
	output VGA_CLK,
	output VGA_HS,
	output VGA_VS,
	output VGA_BLANK_N,
	output VGA_SYNC_N,
	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output [6:0] disp_score_p1,
	output [6:0] disp_score_p2,
	output reg light
);

// VGA module (from GitHub): https://github.com/Navash914/Verilog-HDL/blob/master/Lab7/vga_adapter.v
vga_adapter VGA(
  .resetn(1'b1),
  .clock(clk),
  .colour(colour),
  .x(x),
  .y(y),
  .plot(1'b1),
  .VGA_R(VGA_R),
  .VGA_G(VGA_G),
  .VGA_B(VGA_B),
  .VGA_HS(VGA_HS),
  .VGA_VS(VGA_VS),
  .VGA_BLANK(VGA_BLANK_N),
  .VGA_SYNC(VGA_SYNC_N),
  .VGA_CLK(VGA_CLK));
defparam VGA.RESOLUTION = "160x120";
defparam VGA.MONOCHROME = "FALSE";
defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
defparam VGA.BACKGROUND_IMAGE = "black.mif";
// end VGA module

reg [5:0] S;
reg border_init;
reg paddle_init;
reg ball_init;
reg [7:0]x;
reg [7:0]y;
reg [7:0]pad1_x, pad1_y;
reg [7:0]pad2_x, pad2_y;
reg [7:0]ball_x, ball_y;
reg [2:0]colour;
reg ball_xdir, ball_ydir;
reg [17:0]draw;
wire frame;
reg [3:0]p1_score;
reg [3:0]p2_score;


// from Chris Lallo: https://github.com/ChrisLalloMiami
parameter 
	flagBits = 512'b00000111111000011000011111100001000001111110000000000111111000000000011111100000000001111110000010000111111000011000011111100001100001111110000110000111111000010000011111100000000001111110000000000111111000000000011111100000100001111110000110000111111000011000011111100001100001111110000100000111111000000000011111100000000001111110000000000111111000001000011111100001100001111110000110000111111000011000011111100001000001111110000000000111111000000000011111100000000001111110000010000111111000011000011111100001,
	flagWidth = 5'd31,
	flagHeight = 5'd16,
	flagStart = 9'd511;

reg [63:0]imageX;
reg [63:0]imageY;
reg [63:0]counter;

parameter 
	initX = 63'd15,
	initY = 63'd15;
// end from Chris Lallo


parameter
	START			= 6'd0,
	INIT_P1  		= 6'd1,
	INIT_P2  		= 6'd2,
	INIT_BALL  		= 6'd3,
	IDLE         	= 6'd4,
	ERASE_P1 		= 6'd5,
	UPDATE_P1		= 6'd6,
	DRAW_P1  		= 6'd7,
	ERASE_P2 		= 6'd8,
	UPDATE_P2		= 6'd9,
	DRAW_P2  		= 6'd10,
	ERASE_BALL   	= 6'd11,
	UPDATE_BALL  	= 6'd12,
	DRAW_BALL    	= 6'd13,
	P1_SCORE		= 6'd14,
	P2_SCORE		= 6'd15,
	P1_START		= 6'd16,
	P2_START		= 6'd17,
	P1_WIN			= 6'd18,
	P2_WIN			= 6'd19,

/*	CURRENTLY DOES NOT WORK
	START_DRAW_FLAG		= 6'd20,
	INIT_DRAW_FLAG 		= 6'd21,
	COND_DRAW_FLAG 		= 6'd22,
	DRAW_FLAG 			= 6'd23,
	BITCOND_DRAW_FLAG 	= 6'd24,
	INCX_DRAW_FLAG 		= 6'd25,
	INCY_DRAW_FLAG 		= 6'd26,
	DEC_COUNTER_DRAW_FLAG 	= 6'd27,
	EXIT_DRAW_FLAG 		= 6'd28,
*/
	ERROR 			= 6'hFFFFFF;

// Calling clock to display (From GitHub)
clock(.clock(clk), .clk(frame));


// FSM
always @(posedge clk) 
begin
	border_init = 1'b0;
	paddle_init = 1'b0;
	ball_init = 1'b0;
	colour = 3'b000; // Background colour
	x = 8'b00000000;
	y = 8'b00000000;
	light = 1'b1;

	imageX = 64'b0;
	imageY = 64'b0;
	counter = 64'b0;

	if (~rst)
		S = START;
	else begin end

	case (S)
	
		START: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				ball_x = ball_x + 1'b1; // moves ball right
				S = INIT_P1;
			end
		end
		
		INIT_P1: 
		begin
			if (draw < 6'b10000)
			begin
				pad1_x = 8'd10;			//Placement of paddle
				pad1_y = 8'd52; 		// Placement of paddle
				x = pad1_x + draw[8];	//size of paddle (x)
				y = pad1_y + draw[3:0];	//size of paddle (y)
				draw = draw + 1'b1;
				colour = 3'b100;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = INIT_P2;
			end
		end

		INIT_P2: 
		begin
			if (draw < 6'b10000)
			begin
				pad2_x = 8'd150;		//Placement of paddle
				pad2_y = 8'd52; 		//Placement of paddle
				x = pad2_x + draw[8];	//size of paddle (x)
				y = pad2_y + draw[3:0];	//size of paddle (y)
				draw = draw + 1'b1;
				colour = 3'b001;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = INIT_BALL;
			end
		end
		
		INIT_BALL: 
		begin
			ball_x = 8'd40;			// Placement of ball
			ball_y = 8'd40; 		// Placement of ball
			ball_x = ball_x + 1'b1; // moves ball right
			x = ball_x;
			y = ball_y;
			colour = 3'b111;
			S = IDLE;
		end
		
		IDLE:
			if (frame)
			S = ERASE_P1;

		ERASE_P1:
		begin
			if (draw < 6'b100000) 
			begin
				x = pad1_x + draw[8]; // Same as init_paddle
				y = pad1_y + draw[3:0];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = ERASE_P2;
			end
		end
	
		ERASE_P2:
		begin
			if (draw < 6'b100000) 
			begin
				x = pad2_x + draw[8]; // Same as init_paddle
				y = pad2_y + draw[3:0];
				draw = draw + 1'b1;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = UPDATE_P1;
			end
		end

		UPDATE_P1: 
		begin
			if (~button[2] && pad1_y < -8'd152) 
				pad1_y = pad1_y + 1'b1; // Moves paddle up (Changes lower bound)
			if (~button[3] && pad1_y > 8'd0) 
				pad1_y = pad1_y - 1'b1; // Moves paddle down (Changes upper bound)							
			S = UPDATE_P2;
		end

		UPDATE_P2: 
		begin
			if (~button[0] && pad2_y < -8'd152) 
				pad2_y = pad2_y + 1'b1; // Moves paddle up (Changes lower bound)
			if (~button[1] && pad2_y > 8'd0) 
				pad2_y = pad2_y - 1'b1; // Moves paddle down (Changes upper bound)							
			S = DRAW_P1;
		end
		
		DRAW_P1: 
		begin
			if (draw < 6'b100000) 
			begin
				x = pad1_x + draw[8];
				y = pad1_y + draw[3:0];
				draw = draw + 1'b1;
				colour = 3'b100;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = DRAW_P2;
			end
		end
		
		DRAW_P2: 
		begin
			if (draw < 6'b100000) 
			begin
				x = pad2_x + draw[8];
				y = pad2_y + draw[3:0];
				draw = draw + 1'b1;
				colour = 3'b001;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = ERASE_BALL;
			end
		end

		ERASE_BALL: 
		begin
			x = ball_x;
			y = ball_y;
			S = UPDATE_BALL;
		end
		
		UPDATE_BALL: 
		begin
			if (~ball_xdir)
				ball_x = ball_x + 1'b1; // moves ball right
			else
				ball_x = ball_x - 1'b1; // moves ball left
				
			if (ball_ydir) 
				ball_y = ball_y + 1'b1; // moves ball up
			else 
				ball_y = ball_y - 1'b1; // moves ball down
			
			if	((ball_xdir) && (ball_x > pad1_x) &&
			   	(ball_x < pad1_x + 8'd2) && (ball_y >= pad1_y) && 
				(ball_y <= pad1_y + 8'd16)) // Ball collide with paddle1
				ball_xdir = ~ball_xdir;

			if 	((~ball_xdir) && (ball_x < pad2_x) &&
			   	(ball_x > pad2_x - 8'd2) && (ball_y >= pad2_y) && 
				(ball_y <= pad2_y + 8'd16)) // Ball collide with paddle2
				ball_xdir = ~ball_xdir;

			if ((ball_y == 8'd0) || (ball_y == -8'd136))
				ball_ydir = ~ball_ydir;

			if 	(ball_x <= 8'd0) // Ball boundary x direction
				S = P2_SCORE;
			else if (ball_x >= 8'd160)
				S = P1_SCORE;
			else
				S = DRAW_BALL;
			
		end
		
		DRAW_BALL:
		begin
			x = ball_x;
			y = ball_y;
			colour = 3'b111;
			S = IDLE;
		end

		P1_SCORE:
		begin
			p1_score <= p1_score + 1'b1;
			if (p1_score >= 4)
				S = P1_WIN;
			else
				S = P1_START;
		end

		P1_START:
		begin
			ball_x = 8'd20;		// Placement of ball
			ball_y = 8'd50; 	// Placement of ball
			ball_x = ball_x + 1'b1; // moves ball right
			x = ball_x;
			y = ball_y;
			colour = 3'b111;
			S = IDLE;
		end

		P2_SCORE:
		begin
			p2_score <= p2_score + 1'b1;
			if (p2_score >= 4)
				S = P2_WIN;
			else
				S = P2_START;		
		end

		P2_START:
		begin
			ball_x = 8'd140;		// Placement of ball
			ball_y = 8'd50; 		// Placement of ball
			ball_x = ball_x - 1'b1; // moves ball left
			x = ball_x;
			y = ball_y;
			colour = 3'b111;
			S = IDLE;
		end

		P1_WIN:
		begin
			x = draw[7:0];
			y = draw[16:8];
			draw = draw + 1'b1;
			colour = 3'b100;
			p1_score = 1'b0;
			p2_score = 1'b0;
		end

		P2_WIN:
		begin
			x = draw[7:0];
			y = draw[16:8];
			draw = draw + 1'b1;
			colour = 3'b001;
			p1_score = 1'b0;
			p2_score = 1'b0;
		end

/*	CURRENTLY DOES NOT WORK

		P1_WIN:
		begin
			x = draw[7:0];
			y = draw[16:8];
			draw = draw + 1'b1;
			colour = 3'b000;
			p1_score = 1'b0;
			p2_score = 1'b0;
			S = START_DRAW_FLAG;
		end

		P2_WIN:
		begin
			x = draw[7:0];
			y = draw[16:8];
			draw = draw + 1'b1;
			colour = 3'b000;
			p1_score = 1'b0;
			p2_score = 1'b0;
			S = START_DRAW_FLAG;
		end
*/

/*	CURRENTLY DOES NOT WORK

		P1_WIN: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
				colour = 3'b100;
				p1_score = 1'b0;
				p2_score = 1'b0;
				light = 1'b0;			
			end 
			else 
			begin
				draw = 8'b00000000;
				S = START_DRAW_FLAG;
			end
		end

		P2_WIN: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
				colour = 3'b001;
				p1_score = 1'b0;
				p2_score = 1'b0;
				light = 1'b0;
			end 
			else 
			begin
				draw = 8'b00000000;
				S = START_DRAW_FLAG;
			end
		end
*/

/*	CURRENTLY DOES NOT WORK

		START_DRAW_FLAG:
		begin
			S = INIT_DRAW_FLAG;
			light = 1'b0;
		end

		INIT_DRAW_FLAG: 
		begin
			counter = appleStart;
			S = COND_DRAW_FLAG;
		end

		COND_DRAW_FLAG:
		begin
			if (appleBits[counter] == 1'b1)
				S = DRAW_FLAG;
			else
				S = BITCOND_DRAW_FLAG;
		end

		DRAW_FLAG:
		begin
			colour <= 3'b100;
			x = initX + imageX;
			y = initY + imageY;
			S = BITCOND_DRAW_FLAG;
		end

		BITCOND_DRAW_FLAG:
		begin
			if (imageX >= appleWidth)
				S = INCY_DRAW_FLAG;
			else
				S = INCX_DRAW_FLAG;
		end

		INCX_DRAW_FLAG:
		begin
			imageX = imageX + 1'b1;
			S = DEC_COUNTER_DRAW_FLAG;
		end

		INCY_DRAW_FLAG:
		begin
			imageX <= 64'b0;
			imageY <= imageY + 1'b1;
			S = DEC_COUNTER_DRAW_FLAG;
		end

		DEC_COUNTER_DRAW_FLAG:
		begin
			counter = counter - 1'b1;
			if (imageY < appleHeight)
				S = COND_DRAW_FLAG;
			else
				S = EXIT_DRAW_FLAG;
		end

		EXIT_DRAW_FLAG: begin end
*/

	endcase
end

// instantiating seven segment for score
seven_segment p1_s(p1_score, disp_score_p1);
seven_segment p2_s(p2_score, disp_score_p2);

endmodule
	

// part of display module (from GitHub): https://github.com/Navash914/Verilog-HDL/blob/master/Lab7/vga_adapter.v
module clock (
  input clock,
  output clk
);

reg [19:0] frame_counter;
reg frame;

always@(posedge clock)
  	begin
		if (frame_counter == 20'b0) begin
			frame_counter = 20'd833332;  // This divisor gives us ~60 frames per second
			frame = 1'b1;
		end 
		else 
		begin
			frame_counter = frame_counter - 1'b1;
			frame = 1'b0;
		end
  	end

assign clk = frame;
endmodule
// end part of display module