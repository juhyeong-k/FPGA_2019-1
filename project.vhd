library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project is
    port ( rstb : in std_logic;
           rf_data : in std_logic_vector(2 downto 0) := "000";
           mtl : out std_logic_vector(3 downto 0);
           mtr : out std_logic_vector(3 downto 0);

           CLK_50M : in std_logic;
           SEG : out std_logic_vector(6 downto 0) := "0111111";
			  DP : out std_logic := '0'
    );
end project;

architecture Behavioral of project is

signal speed_l : integer range 0 to 250000;
signal speed_r : integer range 0 to 250000;
signal motor_lcnt : integer range 0 to 250000;
signal phase_lclk : std_logic;
signal motor_rcnt : integer range 0 to 250000;
signal phase_rclk : std_logic;
signal phase_lcnt : std_logic_vector(1 downto 0) := "00";
signal phase_lout : std_logic_vector(3 downto 0) := "0000";
signal phase_rcnt : std_logic_vector(1 downto 0) := "00";
signal phase_rout : std_logic_vector(3 downto 0) := "0000";
signal system_clk : std_logic := '0';
signal segment_clk : std_logic := '0';

shared variable seg_count : integer range 0 to 250000 := 250000;
shared variable seg_on : std_logic := '1';
shared variable left_selected : std_logic := '1';
shared variable right_selected : std_logic := '0';
shared variable btn_free : std_logic := '1';
shared variable mtl_speed : std_logic_vector(1 downto 0) := "00";
shared variable mtr_speed : std_logic_vector(1 downto 0) := "00";

begin

	process(rf_data)

	begin
		
		case rf_data is
			when "100" =>
				if btn_free = '1' then
					if left_selected = '0' then
						left_selected := '1';
						right_selected := '0';
						DP <= '1';
					else
						left_selected := '0';
						right_selected := '1';
						DP <= '0';
					end if;
							btn_free := '0';
				end if;
			when "001" =>
				if btn_free = '1' then
					if left_selected = '1' then
						case mtl_speed is
							when "11" =>
								mtl_speed := "10";
								speed_l <= 62500;
							when "10" =>
								mtl_speed := "01";
								speed_l <= 124999;
							when others =>
								mtl_speed := "00";
								speed_l <= 0;
						end case;
					elsif right_selected = '1' then
						case mtr_speed is
							when "11" =>
								mtr_speed := "10";
								speed_r <= 62500;
							when "10" =>
								mtr_speed := "01";
								speed_r <= 124999;
							when others =>
								mtr_speed := "00";
								speed_r <= 0;
						end case;
					end if;
				end if;
						btn_free := '0';
			when "010" =>
				if btn_free = '1' then
					if left_selected = '1' then
						case mtl_speed is
							when "00" =>
								mtl_speed := "01";
								speed_l <= 124999;
							when "01" =>
								mtl_speed := "10";
								speed_l <= 62500;
							when others =>
								mtl_speed := "11";
								speed_l <= 50000;
						end case;
					elsif right_selected = '1' then
						case mtr_speed is
							when "00" =>
								mtr_speed := "01";
								speed_r <= 124999;
							when "01" =>
								mtr_speed := "10";
								speed_r <= 62500;
							when others =>
								mtr_speed := "11";
								speed_r <= 50000;
						end case;
					end if;
				end if;
			btn_free := '0';
			when others => btn_free := '1';
		end case;

	end process;

	process(rstb, speed_l, system_clk)

	begin
	
		if rstb = '0' or speed_l = 0 then
			motor_lcnt <= 0;
			phase_lclk <= '0';
		elsif rising_edge(system_clk) then
			if motor_lcnt >= speed_l then
				motor_lcnt <= 0;
				phase_lclk <= not phase_lclk;
			else
				motor_lcnt <= motor_lcnt + 1;
			end if;
		end if;

	end process;

	process(rstb, speed_r, system_clk)

	begin
	
		if rstb = '0' or speed_r = 0 then
			motor_rcnt <= 0;
			phase_rclk <= '0';
		elsif rising_edge(system_clk) then
			if motor_rcnt >= speed_r then
				motor_rcnt <= 0;
				phase_rclk <= not phase_rclk;
			else
				motor_rcnt <= motor_rcnt + 1;
			end if;
		end if;

	end process;

	process(rstb, phase_lclk)

	begin

		if rstb = '0' then
			phase_lcnt <= (others => '0');
		elsif rising_edge(phase_lclk) then
			phase_lcnt <= phase_lcnt + 1;
		end if;

	end process;

	process(rstb, phase_lcnt)

	begin

		if rstb = '0' then
			phase_lout <= (others => '0');
		else
			case phase_lcnt is
				when "00" => phase_lout <= "1000";
				when "01" => phase_lout <= "0100";
				when "10" => phase_lout <= "0010";
				when "11" => phase_lout <= "0001";
				when others => phase_lout <= "0000";
			end case;
		end if;

	end process;

	process(rstb, phase_rclk)

	begin

		if rstb = '0' then
			phase_rcnt <= (others => '0');
		elsif rising_edge(phase_rclk) then
			phase_rcnt <= phase_rcnt + 1;
		end if;

	end process;
	
	process(rstb, phase_rcnt)

	begin

		if rstb = '0' then
			phase_rout <= (others => '0');
		else
			case phase_rcnt is
				when "00" => phase_rout <= "1000";
				when "01" => phase_rout <= "0100";
				when "10" => phase_rout <= "0010";
				when "11" => phase_rout <= "0001";
				when others => phase_rout <= "0000";
			end case;
		end if;

	end process;

	process(segment_clk)
	
	begin
		if rising_edge(segment_clk) then
			if left_selected = '1' then
				if seg_count >= (249999 - speed_l) then
					seg_count := 0;
					if seg_on = '1' then
						seg <= "0000000";
						seg_on := '0';
					else
						seg <= "0011111";
						seg_on := '1';
					end if;
				else
					seg_count := seg_count + 1;
				end if;
			else
				if seg_count >= (249999 - speed_r) then
					seg_count := 0;
					if seg_on = '1' then
						seg <= "0000000";
						seg_on := '0';
					else
						seg <= "0011111";
						seg_on := '1';
					end if;
				else
					seg_count := seg_count + 1;
				end if;
			end if;
		end if;
	end process;

	process(CLK_50M)
	
		variable cnt : integer range 0 to 3 := 0;	
	
	begin
		if rising_edge(CLK_50M) then
			if cnt = 3 then
				system_clk <= not system_clk;
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		else
			NULL;
		end if;
	end process;
	
	process(system_clk)
	
		variable cnt : integer range 0 to 44 := 0;
	
	begin
		if rising_edge(system_clk) then
			if cnt = 44 then
				segment_clk <= not segment_clk;
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		else
			NULL;
		end if;
	end process;

	mtl(0) <= phase_lout(0);
	mtl(1) <= phase_lout(1);
	mtl(2) <= phase_lout(2);
	mtl(3) <= phase_lout(3);

	mtr(0) <= phase_rout(3);
	mtr(1) <= phase_rout(2);
	mtr(2) <= phase_rout(1);
	mtr(3) <= phase_rout(0);

end Behavioral;




