--------------------------------------------------------------------------------
-- Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    Vendor: Xilinx 
-- \   \   \/     Version : 14.3
--  \   \         Application : xaw2vhdl
--  /   /         Filename : dcm_60to100.vhd
-- /___/   /\     Timestamp : 07/31/2013 08:55:21
-- \   \  /  \ 
--  \___\/\___\ 
--
--Command: xaw2vhdl-intstyle /home/neiser/FPGA/vitek/xilinx-fpga/ipcore_dir/dcm_60to100.xaw -st dcm_60to100.vhd
--Design Name: dcm_60to100
--Device: xc3s1000-4ft256
--
-- Module dcm_60to100
-- Generated by Xilinx Architecture Wizard
-- Written for synthesis tool: XST
-- Period Jitter (unit interval) for block DCM_INST = 0.08 UI
-- Period Jitter (Peak-to-Peak) for block DCM_INST = 0.76 ns

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.ALL;

-- only renamed the port signal names and removed Ibufg_out of clkin signal
entity dcm_60to100 is
	port(CLK60_IN   : in  std_logic;
		   CLK100_OUT : out std_logic;
		   CLK60_OUT  : out std_logic;
		   LOCKED_OUT : out std_logic);
end dcm_60to100;

architecture BEHAVIORAL of dcm_60to100 is
	signal CLKFB_IN    : std_logic;
	signal CLKFX_BUF   : std_logic;
	signal CLK60_IBUFG : std_logic;
	signal CLK0_BUF    : std_logic;
	signal LOCKED      : std_logic;
	signal RST         : std_logic            := '1';
begin
	LOCKED_OUT <= LOCKED;
	
	CLK60_BUFG_INST : BUFGCE
		port map(I  => CLK0_BUF,
			       O  => CLK60_OUT,
			       CE => LOCKED);
	
	CLKFX_BUFG_INST : BUFGCE
		port map(I  => CLKFX_BUF,
			       O  => CLK100_OUT,
			       CE => LOCKED);

	CLKIN_IBUFG_INST : IBUFG
		port map(I => CLK60_IN,
			       O => CLK60_IBUFG);


	CLK0_BUFG_INST : BUFG
		port map(I  => CLK0_BUF,
			       O  => CLKFB_IN);
			       
	SRL16_INST : SRL16 
	generic map(
		INIT => x"FFFF"
	)
	port map(
		Q   => RST,
		A0  => '1',
		A1  => '1',
		A2  => '1',
		A3  => '1',
		CLK => CLK60_IBUFG,
		D   => '0'
	);

	DCM_INST : DCM
		generic map(CLK_FEEDBACK          => "1X",
			          CLKDV_DIVIDE          => 2.0,
			          CLKFX_DIVIDE          => 3,
			          CLKFX_MULTIPLY        => 5,
			          CLKIN_DIVIDE_BY_2     => FALSE,
			          CLKIN_PERIOD          => 16.667,
			          CLKOUT_PHASE_SHIFT    => "NONE",
			          DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
			          DFS_FREQUENCY_MODE    => "LOW",
			          DLL_FREQUENCY_MODE    => "LOW",
			          DUTY_CYCLE_CORRECTION => TRUE,
			          FACTORY_JF            => x"8080",
			          PHASE_SHIFT           => 0,
			          STARTUP_WAIT          => TRUE)
		port map(CLKFB    => CLKFB_IN,
			       CLKIN    => CLK60_IBUFG,
			       DSSEN    => '0',
			       PSCLK    => '0',
			       PSEN     => '0',
			       PSINCDEC => '0',
			       RST      => RST,
			       CLKDV    => open,
			       CLKFX    => CLKFX_BUF,
			       CLKFX180 => open,
			       CLK0     => CLK0_BUF,
			       CLK2X    => open,
			       CLK2X180 => open,
			       CLK90    => open,
			       CLK180   => open,
			       CLK270   => open,
			       LOCKED   => LOCKED,
			       PSDONE   => open,
			       STATUS   => open);



end BEHAVIORAL;