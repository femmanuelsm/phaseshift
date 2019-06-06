LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY teste IS
	GENERIC (
		MAX_PHASE					: INTEGER := 90;
		CHANNELS      				: INTEGER := 2	
	);
	
	PORT ( 	
		CLOCK				:	IN		STD_LOGIC;
		
		-- weak pull-ups foram designados para estes pinos no Pin Planner
		Arduino_IO9		:	IN		STD_LOGIC;
		Arduino_IO10	:	IN		STD_LOGIC;
		Arduino_IO11	:	IN		STD_LOGIC;
		Arduino_IO12	:	IN		STD_LOGIC;
		
		LED1, LED2, LED3, LED4, LED5 : OUT STD_LOGIC;
		
		Arduino_IO0	:	OUT	STD_LOGIC;
		Arduino_IO1	:	OUT	STD_LOGIC;
		Arduino_IO2	:	OUT	STD_LOGIC;
		Arduino_IO3	:	OUT	STD_LOGIC
	);
END teste;
	
	
ARCHITECTURE top OF teste IS

	SIGNAL wire_phase	:	INTEGER RANGE 0 TO 360;
	SIGNAL wire_up, wire_down, wire_reset, wire_default		:	STD_LOGIC;
	
	COMPONENT debounce
		PORT (
			noisy				: IN  STD_LOGIC;                                    
			clk				: IN  STD_LOGIC;                                    
			debounced		: OUT  STD_LOGIC                                  
		);
	END COMPONENT;
	
BEGIN
	
		pwm1 : entity work.pwm
		generic map (
			CHANNELS => CHANNELS
		)
		port map (
			clk				=>	CLOCK,
			reset_n			=>	'1',
			phase				=> wire_phase,
			
			pwm_out(0) 		=>	Arduino_IO0,
			pwm_n_out(0)	=> Arduino_IO1,
			pwm_out(1) 		=>	Arduino_IO2,
			pwm_n_out(1)	=> Arduino_IO3
		);
		
		pg	:	entity work.phase_gen(full)
		generic map (
			MAX_PHASE => MAX_PHASE
		)
		port map (
			clk		=>	CLOCK,
			up_b 		=> wire_up,
			down_b	=> wire_down,
			reset_b	=> wire_reset,
			default_b => wire_default,
			
			leds(0) => LED1,
			leds(1) => LED2,
			leds(2) => LED3,
			leds(3) => LED4,
			leds(4) => LED5,
			phase		=>	wire_phase
		);
		
		deb0 : debounce
		port map (
			noisy => Arduino_IO12,
			clk	=> CLOCK,
			debounced => wire_up
		);
		
		deb1 : debounce
		port map (
			noisy => Arduino_IO11,
			clk	=> CLOCK,
			debounced => wire_down
		);
		
		deb2 : debounce
		port map (
			noisy => Arduino_IO10,
			clk	=> CLOCK,
			debounced => wire_reset
		);
		
		deb3 : debounce
		port map (
			noisy => Arduino_IO9,
			clk	=> CLOCK,
			debounced => wire_default
		);
		
END top;