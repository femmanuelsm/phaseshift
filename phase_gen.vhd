--*****************************************************************************
-- Generates the phase values by a 5 degree step
--******************************************************************************/
--------------------------------------------------------------------------------
--
--		Observações:
--			Phase: min phase is 0 degrees
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY phase_gen IS

	GENERIC (
		MAX_PHASE					: INTEGER := 90;
		MIN_PHASE					: INTEGER := 0;
		NUMBER_OF_LEDS				: INTEGER := 5;
		STEP							: INTEGER := 5
	);
	
	PORT (
		clk			: IN STD_LOGIC;
		up_b			: IN STD_LOGIC;
		down_b		: IN STD_LOGIC;
		reset_b		: IN STD_LOGIC;
		default_b	: IN STD_LOGIC;
		
		leds	: OUT	STD_LOGIC_VECTOR(NUMBER_OF_LEDS-1 DOWNTO 0);
		phase	: OUT	INTEGER RANGE 0 TO 360
		
	);

END phase_gen;

-- Arch linked to the clk event
ARCHITECTURE full OF phase_gen IS
	
	SIGNAL phase_i	: INTEGER RANGE 0 TO 360 := 0;
	SIGNAL leds_i	: INTEGER RANGE 0 TO 31  := 0;
	SIGNAL last_up_state, last_down_state : STD_LOGIC;
	
BEGIN
	PROCESS (clk)
	BEGIN
	
		IF (rising_edge(clk)) THEN
			IF (reset_b = '1') THEN
				phase_i <= 0;
				leds_i  <= 0;
			END IF;
				
			IF (default_b = '1') THEN
				phase_i <= 30;
				leds_i  <= 6;
			END IF;
			
			-- nao precisa ser depois do if, lembrar que ´e logica combinacional
			last_up_state <= up_b;
			last_down_state <= down_b;
			
			IF (up_b = '1' AND last_up_state = '0' AND phase_i < MAX_PHASE) THEN
				phase_i	<= phase_i + STEP;
				leds_i  	<= leds_i + 1; 
			ELSIF (down_b = '1' AND last_down_state = '0' AND phase_i > MIN_PHASE) THEN
				phase_i 	<= phase_i - STEP;
				leds_i	<= leds_i - 1;
			END IF;
			
			-- atraso de um ciclo de clock, pegando phase_i anterior e nao o atual
			leds  <= NOT std_logic_vector(to_unsigned(leds_i, NUMBER_OF_LEDS));
			phase <= phase_i;	
			
		END IF;
		
	END PROCESS;
END full;