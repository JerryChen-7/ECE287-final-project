module final(
	input clk,
	input rst,
	input [3:0] button,
	output VGA_CLK,
	output VGA_HS,
	output VGA_VS,
	output VGA_BLANK_N,
	output VGA_SYNC_N,
	output [7:0] VGA_G,
	output [7:0] VGA_R,
	output [7:0] VGA_B,
	output [6:0] disp_score_p1,
	output [6:0] disp_score_p2
);

// Found VGA on GitHub (Credited in citation)
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
reg [2:0]p1_score;
reg [2:0]p2_score;


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
	GAME_OVER		= 6'd20,
	ERROR 			= 6'hFFFFFF;

	// Calling clock to display
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

		if (~rst)
			S = START;

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
			ball_x = 8'd40;		// Placement of ball
			ball_y = 8'd40; 	// Placement of ball
			ball_x = ball_x + 1'b1; // moves ball right
			x = ball_x;
			y = ball_y;
			colour = 3'b111;
			S = IDLE;
		end
		
		IDLE:
			if (frame)
			S = ERASE_P1;	//Should be Erase_paddle
	
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
			if (~button[2] && pad1_y < -8'd152) pad1_y = pad1_y + 1'b1; // Moves paddle up (Changes lower bound)
			if (~button[3] && pad1_y > 8'd0) pad1_y = pad1_y - 1'b1; // Moves paddle down (Changes upper bound)							
			S = UPDATE_P2;
		end

		UPDATE_P2: 
		begin
			if (~button[0] && pad2_y < -8'd152) pad2_y = pad2_y + 1'b1; // Moves paddle up (Changes lower bound)
			if (~button[1] && pad2_y > 8'd0) pad2_y = pad2_y - 1'b1; // Moves paddle down (Changes upper bound)							
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
				(ball_y <= pad1_y + 8'd15)) // Ball collide with paddle1
				ball_xdir = ~ball_xdir;

			if 	((~ball_xdir) && (ball_x < pad2_x) &&
			   	(ball_x > pad2_x - 8'd2) && (ball_y >= pad2_y) && 
				(ball_y <= pad2_y + 8'd15)) // Ball collide with paddle2
				ball_xdir = ~ball_xdir;

			if ((ball_y == 8'd0) || (ball_y == -8'd136))
				ball_ydir = ~ball_ydir;
			/*
			if (ball_x <= 8'd0) // x boundary below paddle 
				S = GAME_OVER;
			else
			*/
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
			ball_x = 8'd40;		// Placement of ball
			ball_y = 8'd40; 	// Placement of ball
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
			ball_x = 8'd120;		// Placement of ball
			ball_y = 8'd40; 		// Placement of ball
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
		end

		P2_WIN:
		begin
			x = draw[7:0];
			y = draw[16:8];
			draw = draw + 1'b1;
			colour = 3'b001;
			p2_score = 1'b0;
		end

		GAME_OVER: 
		begin
			if (draw < 17'b10000000000000000)
			begin
				x = draw[7:0];
				y = draw[16:8];
				draw = draw + 1'b1;
				colour = 3'b100;
			end
		end
	endcase
	end

// instantiating seven segment for score
seven_segment p1_s(p1_score, disp_score_p1);
seven_segment p2_s(p2_score, disp_score_p2);

endmodule
	

//display module (from GitHub)
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
