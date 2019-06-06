--------------------------------------------------------------------------------
--
--		Observações:
--			* Duty cycle é de 50% e igual para todos os cainais;
--       * As bordas de subida dos sinais PWM iniciam em fase, mas a defasagem já é aplicada nas bordas de descida. 
--			* A defasagem é aplicada entre cada canal subsequente. Assim, para 3 canais e defasagem de 20 graus, o primeiro é a referencia,
--				o segundo atrasado em 20 graus em relação ao 1 e o terceiro está atrasado em 40 graus em relação ao 1;
--			O valor atribuido à variável phase não deve resultar em defasagem maior que 360/CHANNELS. A lógica de proteção deve ser externa;
--			Quando a variável phase se encontra no valor máximo da escala, todos os bits em 1, a defasagem é de 360 graus;
--			Uma defasagem de 360 graus corresponde a um pulso de atraso;
--			Podem haver erros no duty cycle caso a freq. do PWM não divida de forma exata o clock do sistema;
--			Podem haver erros na defasagem de fase caso o número de pulsos de clock, em relação à freq. do pwm, não seja um valor
--				exato para gerar a defasagem requerida.
--
--		TODO:
--			Tratar defasagem negativa. Defasagem negativa equivale a um atraso de mais de 180.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY pwm IS

  GENERIC (
--  	Simulaçao
--		pwm_freq 	       		: INTEGER := 1_000_000;
		
      sys_clk     	    		: INTEGER := 50_000_000; 	-- system clock frequency in Hz
      pwm_freq 	       		: INTEGER := 10_000;    	-- PWM switching frequency in Hz
		CHANNELS       	   	: INTEGER := 2					-- number of output pwms
	);      
   
  PORT (
      clk      : IN  STD_LOGIC;                                -- system clock
      reset_n  : IN  STD_LOGIC;                                -- asynchronous reset
		phase		: IN	INTEGER RANGE 0 TO 360;							-- defasagem de fase
		pwm_out  : OUT STD_LOGIC_VECTOR(CHANNELS-1 DOWNTO 0);	   -- pwm outputs
		pwm_n_out: OUT STD_LOGIC_VECTOR(CHANNELS-1 DOWNTO 0)		-- saída pwm complementar
	);         
		
END pwm;


ARCHITECTURE logic OF pwm IS

  CONSTANT  period_ticks		:  INTEGER := sys_clk/pwm_freq;	-- (-1) pq o contador inicia em zero e não em 1
  CONSTANT	DUTY					:	INTEGER := (period_ticks)/2; -- ajustando por causa do -1 anterior
  
  CONSTANT 	rounding				:	INTEGER := 180; -- arredondamento para 0,5 grau (0,5*360)
  
  -- data type for array of period counters
  TYPE	counters IS ARRAY (0 TO CHANNELS-1) OF INTEGER RANGE 0 TO period_ticks-1;  	
  SIGNAL count        	:  counters := (OTHERS => 0);		-- array of period counters
  
  -- número de pulsos de clock para defasagem de fase
  SIGNAL phase_ticks	:	INTEGER RANGE 0 TO period_ticks-1 := 0;

BEGIN
  PROCESS (clk, reset_n)
  BEGIN
  
    IF (reset_n = '0') THEN					-- asynchronous reset
      -- clear counters and pwm outputs
		count <= (OTHERS => 0);             
      pwm_out <= (OTHERS => '0');
		pwm_n_out <= (OTHERS => '0');
		
	 ELSIF(rising_edge(clk)) THEN	-- rising system clock edge
	 
		-- Cria os contadores
		-- Defasamento inicia na borda de descida se defasagem aumenta e na borda de subida se defasagem diminui.
		FOR i IN 0 TO CHANNELS-1 LOOP
			IF (count(i) = period_ticks-1) THEN
				-- atualiza fase
				IF (phase = 0) THEN
					phase_ticks <= 0;
				ELSE
					phase_ticks <= (period_ticks*phase - rounding)/360;
				END IF;
				
				IF (i = 0 AND phase = 0) THEN
					count <= (OTHERS => 0);			-- reset todos se fase zero
				ELSE
					count(i) <= 0;						-- reset apenas o contador que estorou
				END IF;
				
			ELSIF (count(0) = i*phase_ticks AND count(0) /= 0) THEN -- reset se fase alcançada
				count(i) <= 0;
			ELSE
				count(i) <= count(i) + 1;			-- incremento padrao
			END IF;
		END LOOP;

		-- Controla a saída de cada canal
		FOR i IN 0 TO CHANNELS-1 LOOP
			IF (count(i) = 0) THEN
				pwm_out(i) <= '1';
				pwm_n_out(i) <= '0';		
		  ELSIF (count(i) = DUTY) THEN
				pwm_out(i) <= '0';      
				pwm_n_out(i) <= '1';
		  END IF;
		END LOOP;
    
	 END IF;
  END PROCESS;
END logic;
