library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity vitek_fpga_xc3s1000 is
	port(
		-- signals local to the micromodule itself
		-- this is the 60 MHz clock input (selected via UTMI_databus16_8)
		CLK60_IN         : in    std_logic;
		UTMI_databus16_8 : out   std_logic; -- 1 = 30MHz, 0 = 60MHz
		UTMI_reset       : out   std_logic;
		UTMI_xcvrselect  : out   std_logic;
		UTMI_termselect  : out   std_logic;
		UTMI_opmode1     : out   std_logic;
		UTMI_txvalid     : out   std_logic;
		LED_module       : out   std_logic; -- active low

		-- the names are according to the schematic provided
		-- by Klaus Weindel
		-- general input / output
		O_NIM            : out   std_logic_vector(4 downto 1); -- NIM output
		I_NIM            : in    std_logic_vector(4 downto 1); -- NIM input
		EO               : out   std_logic_vector(16 downto 1); -- ECL output
		EI               : in    std_logic_vector(16 downto 1); -- ECL input
		A_X              : out   std_logic_vector(8 downto 1); -- AVR microprocessor
		OHO_RCLK         : out   std_logic; -- 3x7 segment display
		OHO_SCLK         : out   std_logic; -- 3x7 segment display
		OHO_SER          : out   std_logic; -- 3x7 segment display
		V_V              : out   std_logic_vector(10 downto 1); -- another VITEK card

		-- delay stuff
		D_IN             : out   std_logic_vector(5 downto 1); -- to delay input
		D_OUT            : in    std_logic_vector(5 downto 1); -- from delay ouput
		D_D              : out   std_logic;
		D_Q              : out   std_logic;
		D_MS             : out   std_logic;
		D_LE             : out   std_logic;
		D_CLK            : out   std_logic;

		-- VME / CPLD communication
		F_D              : inout std_logic_vector(15 downto 0); -- VME Data (must be tri-state!)
		C_F_in           : out   std_logic_vector(3 downto 1); -- to CPLD (= "in" port there)
		C_F_out          : in    std_logic_vector(7 downto 4); -- from CPLD (= "out" port there)
		I_A              : in    std_logic_vector(10 downto 1) -- VME address		
	);
end vitek_fpga_xc3s1000;

architecture arch1 of vitek_fpga_xc3s1000 is
	-- clock handling
	signal clk, clk60, clk100 : std_logic;
	component dcm_60to100
		port(CLK60_IN   : in  std_logic;
			   CLK100_OUT : out std_logic;
			   CLK60_OUT  : out std_logic);
	end component dcm_60to100;

	-- VME CPLD handling
	constant vme_addr_size : integer := 4; -- 2^4=16 vme registers maximum (currently)
	component vme_cpld_handler
		generic(vme_addr_size : integer);
		port(clk     : in    std_logic;
			   F_D     : inout std_logic_vector(15 downto 0);
			   C_F_in  : out   std_logic_vector(3 downto 1);
			   C_F_out : in    std_logic_vector(7 downto 4);
			   I_A     : in    std_logic_vector(10 downto 1);
			   b_clk   : in    std_logic;
			   b_wr    : in    std_logic;
			   b_addr  : in    std_logic_vector(vme_addr_size - 1 downto 0);
			   b_din   : in    std_logic_vector(15 downto 0);
			   b_dout  : out   std_logic_vector(15 downto 0));
	end component vme_cpld_handler;

	-- ram updater writes and reads port b
	component ram_updater
		port(clk        : in  std_logic;
			   O_NIM      : out std_logic_vector(4 downto 1);
			   I_NIM      : in  std_logic_vector(4 downto 1);
			   EO         : out std_logic_vector(16 downto 1);
			   EI         : in  std_logic_vector(16 downto 1);
			   b_wr       : out std_logic;
			   b_addr     : out std_logic_vector(2 downto 0);
			   b_din      : out std_logic_vector(15 downto 0);
			   b_dout     : in  std_logic_vector(15 downto 0);
			   EVENTID_IN : in  std_logic_vector(31 downto 0);
			   STATUS_IN  : in  std_logic_vector(10 downto 0));
	end component ram_updater;

	-- eventid receiver
	component eventid_recv
		port(CLK               : in  std_logic;
			   TIMER_TICK_1US_IN : in  std_logic;
			   SERIAL_IN         : in  std_logic;
			   EXT_TRG_IN        : in  std_logic;
			   EVENTID_OUT       : out std_logic_vector(31 downto 0);
			   STATUS_OUT        : out std_logic_vector(10 downto 0));
	end component eventid_recv;

	-- generate 1us ticks, can also be useful somewhere else
	component timer_ticks
		generic(ticks : integer);
		port(clk  : in  std_logic;
			   tick : out std_logic);
	end component timer_ticks;

	-- port b connections for ram_updater
	signal b_wr          : std_logic;
	signal b_addr        : std_logic_vector(vme_addr_size downto 1) := (others => '0');
	signal b_din, b_dout : std_logic_vector(15 downto 0);

	-- event id receiver 
	signal eventid        : std_logic_vector(31 downto 0);
	signal eventid_status : std_logic_vector(10 downto 0);
	signal timer_tick_1us : std_logic;

begin

	-- Configure USB chip on micromodule (UTMI USB3250), 
	-- currently only used as convenient clock source
	UTMI_databus16_8 <= '0';            -- change to 1 to get 30MHz CLK instead of 60MHz
	UTMI_reset       <= '0';
	UTMI_xcvrselect  <= '1';
	UTMI_termselect  <= '1';
	UTMI_opmode1     <= '0';
	UTMI_txvalid     <= '0';

	-- turn off the LED (active low)
	LED_module <= '1';

	-- currently unused outputs
	A_X      <= (others => '0');        -- AVR microprocessor
	OHO_RCLK <= '0';                    -- 3x7 segment display
	OHO_SCLK <= '0';                    -- 3x7 segment display
	OHO_SER  <= '0';                    -- 3x7 segment display
	V_V      <= (others => '0');        -- another VITEK card
	D_IN     <= (others => '0');
	D_D      <= '0';
	D_Q      <= '0';
	D_MS     <= '0';
	D_LE     <= '0';
	D_CLK    <= '0';

	dcm_1 : component dcm_60to100
		port map(CLK60_IN   => CLK60_IN,
			       CLK100_OUT => CLK100,
			       CLK60_OUT  => CLK60);
	-- we drive everything at 100MHz at the moment
	-- pay attention to the eventid receiver and the timer ticks,
	-- which rely on 100MHz as the clk
	clk <= clk100;

	-- port b can be used to handle the VME data transparently (see ram_updater entity)
	vme_cpld_handler_1 : component vme_cpld_handler
		generic map(vme_addr_size => vme_addr_size)
		port map(clk     => clk,
			       F_D     => F_D,
			       C_F_in  => C_F_in,
			       C_F_out => C_F_out,
			       I_A     => I_A,
			       b_clk   => clk,
			       b_wr    => b_wr,
			       b_addr  => b_addr,
			       b_din   => b_din,
			       b_dout  => b_dout);

	-- ram updater stuff
	-- we do not use the upper half of port b at the moment, 
	-- thus via port a testing of VME access is possible at those addresses
	b_addr(4) <= '0';
	ram_updater_1 : component ram_updater
		port map(clk        => clk,
			       O_NIM      => O_NIM,
			       I_NIM      => I_NIM,
			       EO         => EO,
			       EI         => EI,
			       b_wr       => b_wr,
			       b_addr     => b_addr(3 downto 1),
			       b_din      => b_din,
			       b_dout     => b_dout,
			       EVENTID_IN => eventid,
			       STATUS_IN  => eventid_status);

	-- event id receiver including timer tick generation
	eventid_recv_1 : component eventid_recv
		port map(CLK               => clk,
			       TIMER_TICK_1US_IN => timer_tick_1us,
			       SERIAL_IN         => I_NIM(2), -- second one is serial in
			       EXT_TRG_IN        => I_NIM(1), -- first nim input is interrupt/trigger
			       EVENTID_OUT       => eventid,
			       STATUS_OUT        => eventid_status);

	timer_ticks_1 : component timer_ticks
		generic map(ticks => 100)
		port map(clk  => clk,
			       tick => timer_tick_1us);

end arch1;

