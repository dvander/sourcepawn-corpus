#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Common Infected Regulator",
	author = "chinagreenelvis",
	description = "Decrease or increase infected numbers based on number of living survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

new bool:Enabled = false;
new survivors = 0;

new Handle:lt4d_z = INVALID_HANDLE;
new Handle:lt4d_z_01players = INVALID_HANDLE;
new Handle:lt4d_z_background_01players = INVALID_HANDLE;
new Handle:lt4d_z_density_01players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_01players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_01players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_01players = INVALID_HANDLE;
new Handle:lt4d_z_02players = INVALID_HANDLE;
new Handle:lt4d_z_background_02players = INVALID_HANDLE;
new Handle:lt4d_z_density_02players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_02players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_02players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_02players = INVALID_HANDLE;
new Handle:lt4d_z_03players = INVALID_HANDLE;
new Handle:lt4d_z_background_03players = INVALID_HANDLE;
new Handle:lt4d_z_density_03players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_03players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_03players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_03players = INVALID_HANDLE;
new Handle:lt4d_z_04players = INVALID_HANDLE;
new Handle:lt4d_z_background_04players = INVALID_HANDLE;
new Handle:lt4d_z_density_04players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_04players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_04players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_04players = INVALID_HANDLE;
new Handle:lt4d_z_05players = INVALID_HANDLE;
new Handle:lt4d_z_background_05players = INVALID_HANDLE;
new Handle:lt4d_z_density_05players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_05players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_05players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_05players = INVALID_HANDLE;
new Handle:lt4d_z_06players = INVALID_HANDLE;
new Handle:lt4d_z_background_06players = INVALID_HANDLE;
new Handle:lt4d_z_density_06players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_06players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_06players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_06players = INVALID_HANDLE;
new Handle:lt4d_z_07players = INVALID_HANDLE;
new Handle:lt4d_z_background_07players = INVALID_HANDLE;
new Handle:lt4d_z_density_07players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_07players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_07players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_07players = INVALID_HANDLE;
new Handle:lt4d_z_08players = INVALID_HANDLE;
new Handle:lt4d_z_background_08players = INVALID_HANDLE;
new Handle:lt4d_z_density_08players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_08players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_08players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_08players = INVALID_HANDLE;
new Handle:lt4d_z_09players = INVALID_HANDLE;
new Handle:lt4d_z_background_09players = INVALID_HANDLE;
new Handle:lt4d_z_density_09players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_09players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_09players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_09players = INVALID_HANDLE;
new Handle:lt4d_z_10players = INVALID_HANDLE;
new Handle:lt4d_z_background_10players = INVALID_HANDLE;
new Handle:lt4d_z_density_10players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_10players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_10players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_10players = INVALID_HANDLE;
new Handle:lt4d_z_11players = INVALID_HANDLE;
new Handle:lt4d_z_background_11players = INVALID_HANDLE;
new Handle:lt4d_z_density_11players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_11players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_11players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_11players = INVALID_HANDLE;
new Handle:lt4d_z_12players = INVALID_HANDLE;
new Handle:lt4d_z_background_12players = INVALID_HANDLE;
new Handle:lt4d_z_density_12players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_12players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_12players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_12players = INVALID_HANDLE;
new Handle:lt4d_z_13players = INVALID_HANDLE;
new Handle:lt4d_z_background_13players = INVALID_HANDLE;
new Handle:lt4d_z_density_13players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_13players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_13players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_13players = INVALID_HANDLE;
new Handle:lt4d_z_14players = INVALID_HANDLE;
new Handle:lt4d_z_background_14players = INVALID_HANDLE;
new Handle:lt4d_z_density_14players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_14players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_14players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_14players = INVALID_HANDLE;
new Handle:lt4d_z_15players = INVALID_HANDLE;
new Handle:lt4d_z_background_15players = INVALID_HANDLE;
new Handle:lt4d_z_density_15players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_15players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_15players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_15players = INVALID_HANDLE;
new Handle:lt4d_z_16players = INVALID_HANDLE;
new Handle:lt4d_z_background_16players = INVALID_HANDLE;
new Handle:lt4d_z_density_16players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_16players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_16players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_16players = INVALID_HANDLE;
new Handle:lt4d_z_17players = INVALID_HANDLE;
new Handle:lt4d_z_background_17players = INVALID_HANDLE;
new Handle:lt4d_z_density_17players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_17players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_17players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_17players = INVALID_HANDLE;
new Handle:lt4d_z_18players = INVALID_HANDLE;
new Handle:lt4d_z_background_18players = INVALID_HANDLE;
new Handle:lt4d_z_density_18players = INVALID_HANDLE;
new Handle:lt4d_z_megamob_18players = INVALID_HANDLE;
new Handle:lt4d_z_mobmin_18players = INVALID_HANDLE;
new Handle:lt4d_z_mobmax_18players = INVALID_HANDLE;

public OnPluginStart() 
{
	lt4d_z = CreateConVar("lt4d_z", "1", "Allow common infected regulation? 1: Yes, 0: No", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_z_01players = CreateConVar("lt4d_z_01players", "15", "Number of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_02players = CreateConVar("lt4d_z_02players", "20", "Number of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_03players = CreateConVar("lt4d_z_03players", "25", "Number of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_04players = CreateConVar("lt4d_z_04players", "30", "Number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_05players = CreateConVar("lt4d_z_05players", "35", "Number of common infected for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_06players = CreateConVar("lt4d_z_06players", "40", "Number of common infected for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_07players = CreateConVar("lt4d_z_07players", "45", "Number of common infected for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_08players = CreateConVar("lt4d_z_08players", "50", "Number of common infected for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_09players = CreateConVar("lt4d_z_09players", "55", "Number of common infected for nine players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_10players = CreateConVar("lt4d_z_10players", "60", "Number of common infected for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_11players = CreateConVar("lt4d_z_11players", "65", "Number of common infected for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_12players = CreateConVar("lt4d_z_12players", "70", "Number of common infected for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_13players = CreateConVar("lt4d_z_13players", "75", "Number of common infected for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_14players = CreateConVar("lt4d_z_14players", "80", "Number of common infected for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_15players = CreateConVar("lt4d_z_15players", "85", "Number of common infected for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_16players = CreateConVar("lt4d_z_16players", "90", "Number of common infected for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_17players = CreateConVar("lt4d_z_17players", "95", "Number of common infected for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_18players = CreateConVar("lt4d_z_18players", "100", "Number of common infected for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_z_background_01players = CreateConVar("lt4d_z_background_01players", "8", "Background number of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_02players = CreateConVar("lt4d_z_background_02players", "12", "Background number of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_03players = CreateConVar("lt4d_z_background_03players", "16", "Background number of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_04players = CreateConVar("lt4d_z_background_04players", "20", "Background number of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_05players = CreateConVar("lt4d_z_background_05players", "24", "Background number of common infected for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_06players = CreateConVar("lt4d_z_background_06players", "28", "Background number of common infected for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_07players = CreateConVar("lt4d_z_background_07players", "32", "Background number of common infected for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_08players = CreateConVar("lt4d_z_background_08players", "36", "Background number of common infected for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_09players = CreateConVar("lt4d_z_background_09players", "40", "Background number of common infected for nine players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_10players = CreateConVar("lt4d_z_background_10players", "44", "Background number of common infected for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_11players = CreateConVar("lt4d_z_background_11players", "48", "Background number of common infected for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_12players = CreateConVar("lt4d_z_background_12players", "52", "Background number of common infected for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_13players = CreateConVar("lt4d_z_background_13players", "56", "Background number of common infected for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_14players = CreateConVar("lt4d_z_background_14players", "60", "Background number of common infected for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_15players = CreateConVar("lt4d_z_background_15players", "64", "Background number of common infected for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_16players = CreateConVar("lt4d_z_background_16players", "68", "Background number of common infected for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_17players = CreateConVar("lt4d_z_background_17players", "72", "Background number of common infected for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_background_18players = CreateConVar("lt4d_z_background_18players", "76", "Background number of common infected for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_z_density_01players = CreateConVar("lt4d_z_density_01players", "0.015", "Density of common infected for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_02players = CreateConVar("lt4d_z_density_02players", "0.02", "Density of common infected for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_03players = CreateConVar("lt4d_z_density_03players", "0.025", "Density of common infected for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_04players = CreateConVar("lt4d_z_density_04players", "0.03", "Density of common infected for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_05players = CreateConVar("lt4d_z_density_05players", "0.035", "Density of common infected for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_06players = CreateConVar("lt4d_z_density_06players", "0.04", "Density of common infected for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_07players = CreateConVar("lt4d_z_density_07players", "0.045", "Density of common infected for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_08players = CreateConVar("lt4d_z_density_08players", "0.05", "Density of common infected for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_09players = CreateConVar("lt4d_z_density_09players", "0.055", "Density of common infected for nine players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_10players = CreateConVar("lt4d_z_density_10players", "0.06", "Density of common infected for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_11players = CreateConVar("lt4d_z_density_11players", "0.065", "Density of common infected for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_12players = CreateConVar("lt4d_z_density_12players", "0.07", "Density of common infected for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_13players = CreateConVar("lt4d_z_density_13players", "0.075", "Density of common infected for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_14players = CreateConVar("lt4d_z_density_14players", "0.08", "Density of common infected for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_15players = CreateConVar("lt4d_z_density_15players", "0.085", "Density of common infected for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_16players = CreateConVar("lt4d_z_density_16players", "0.09", "Density of common infected for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_17players = CreateConVar("lt4d_z_density_17players", "0.095", "Density of common infected for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_density_18players = CreateConVar("lt4d_z_density_18players", "0.1", "Density of common infected for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	lt4d_z_megamob_01players = CreateConVar("lt4d_z_megamob_01players", "20", "Mega-mob size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_02players = CreateConVar("lt4d_z_megamob_02players", "30", "Mega-mob size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_03players = CreateConVar("lt4d_z_megamob_03players", "40", "Mega-mob size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_04players = CreateConVar("lt4d_z_megamob_04players", "50", "Mega-mob size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_05players = CreateConVar("lt4d_z_megamob_05players", "60", "Mega-mob size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_06players = CreateConVar("lt4d_z_megamob_06players", "70", "Mega-mob size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_07players = CreateConVar("lt4d_z_megamob_07players", "80", "Mega-mob size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_08players = CreateConVar("lt4d_z_megamob_08players", "90", "Mega-mob size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_09players = CreateConVar("lt4d_z_megamob_09players", "20", "Mega-mob size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_10players = CreateConVar("lt4d_z_megamob_10players", "30", "Mega-mob size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_11players = CreateConVar("lt4d_z_megamob_11players", "40", "Mega-mob size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_12players = CreateConVar("lt4d_z_megamob_12players", "50", "Mega-mob size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_13players = CreateConVar("lt4d_z_megamob_13players", "60", "Mega-mob size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_14players = CreateConVar("lt4d_z_megamob_14players", "70", "Mega-mob size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_15players = CreateConVar("lt4d_z_megamob_15players", "80", "Mega-mob size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_16players = CreateConVar("lt4d_z_megamob_16players", "90", "Mega-mob size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_17players = CreateConVar("lt4d_z_megamob_17players", "80", "Mega-mob size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_megamob_18players = CreateConVar("lt4d_z_megamob_18players", "90", "Mega-mob size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	lt4d_z_mobmin_01players = CreateConVar("lt4d_z_mobmin_01players", "4", "Minimum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_02players = CreateConVar("lt4d_z_mobmin_02players", "6", "Minimum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_03players = CreateConVar("lt4d_z_mobmin_03players", "8", "Minimum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_04players = CreateConVar("lt4d_z_mobmin_04players", "10", "Minimum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_05players = CreateConVar("lt4d_z_mobmin_05players", "12", "Minimum mob spawn size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_06players = CreateConVar("lt4d_z_mobmin_06players", "14", "Minimum mob spawn size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_07players = CreateConVar("lt4d_z_mobmin_07players", "16", "Minimum mob spawn size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_08players = CreateConVar("lt4d_z_mobmin_08players", "18", "Minimum mob spawn size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_09players = CreateConVar("lt4d_z_mobmin_09players", "20", "Minimum mob spawn size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_10players = CreateConVar("lt4d_z_mobmin_10players", "22", "Minimum mob spawn size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_11players = CreateConVar("lt4d_z_mobmin_11players", "24", "Minimum mob spawn size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_12players = CreateConVar("lt4d_z_mobmin_12players", "26", "Minimum mob spawn size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_13players = CreateConVar("lt4d_z_mobmin_13players", "28", "Minimum mob spawn size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_14players = CreateConVar("lt4d_z_mobmin_14players", "30", "Minimum mob spawn size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_15players = CreateConVar("lt4d_z_mobmin_15players", "32", "Minimum mob spawn size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_16players = CreateConVar("lt4d_z_mobmin_16players", "34", "Minimum mob spawn size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_17players = CreateConVar("lt4d_z_mobmin_17players", "36", "Minimum mob spawn size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmin_18players = CreateConVar("lt4d_z_mobmin_18players", "38", "Minimum mob spawn size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	lt4d_z_mobmax_01players = CreateConVar("lt4d_z_mobmax_01players", "10", "Maximum mob spawn size for one player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_02players = CreateConVar("lt4d_z_mobmax_02players", "20", "Maximum mob spawn size for two players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_03players = CreateConVar("lt4d_z_mobmax_03players", "25", "Maximum mob spawn size for three players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_04players = CreateConVar("lt4d_z_mobmax_04players", "30", "Maximum mob spawn size for four players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_05players = CreateConVar("lt4d_z_mobmax_05players", "35", "Maximum mob spawn size for five players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_06players = CreateConVar("lt4d_z_mobmax_06players", "40", "Maximum mob spawn size for six players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_07players = CreateConVar("lt4d_z_mobmax_07players", "45", "Maximum mob spawn size for seven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_08players = CreateConVar("lt4d_z_mobmax_08players", "50", "Maximum mob spawn size for eight players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_09players = CreateConVar("lt4d_z_mobmax_09players", "55", "Maximum mob spawn size for nine player", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_10players = CreateConVar("lt4d_z_mobmax_10players", "60", "Maximum mob spawn size for ten players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_11players = CreateConVar("lt4d_z_mobmax_11players", "65", "Maximum mob spawn size for eleven players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_12players = CreateConVar("lt4d_z_mobmax_12players", "70", "Maximum mob spawn size for twelve players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_13players = CreateConVar("lt4d_z_mobmax_13players", "75", "Maximum mob spawn size for thirteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_14players = CreateConVar("lt4d_z_mobmax_14players", "80", "Maximum mob spawn size for fourteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_15players = CreateConVar("lt4d_z_mobmax_15players", "85", "Maximum mob spawn size for fifteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_16players = CreateConVar("lt4d_z_mobmax_16players", "90", "Maximum mob spawn size for sixteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_17players = CreateConVar("lt4d_z_mobmax_17players", "95", "Maximum mob spawn size for seventeen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_z_mobmax_18players = CreateConVar("lt4d_z_mobmax_18players", "100", "Maximum mob spawn size for eighteen players", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_2_commonregulator");

	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("mission_lost", Event_MissionLost);
	
	Enabled = false;
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lt4d_z) == 1 && Enabled == false)
		{
			Enabled = true;
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lt4d_z) == 1 && Enabled == false)
		{
			Enabled = true;
			CreateTimer(3.0, Timer_DifficultySet);
		}
		if (GetConVarInt(lt4d_z) == 1 && Enabled == true)
		{
			CreateTimer(3.0, Timer_DifficultyCheck);
		}
	}
}

public Event_MissionLost(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultySet);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, Timer_DifficultyCheck);
}

public Action:Timer_DifficultySet(Handle:timer)
{
	if (GetConVarInt(lt4d_z) == 1)
	{
		//PrintToServer("DifficultySet");
		survivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(i)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2)
				{
					survivors++;
				}
			}
		}
		//PrintToServer("Survivors %i", survivors);
		if (survivors)
		{
			SetDifficulty();
			CreateTimer(5.0, Timer_Enable);
		}
		else
		{
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

public Action:Timer_Enable(Handle:timer)
{
	if (Enabled == false)
	{
		Enabled = true;
	}
}

public Action:Timer_DifficultyCheck(Handle:timer)
{
	if (GetConVarInt(lt4d_z) == 1 && Enabled == true)
	{
		//PrintToServer("DifficultyCheck");
		new alivesurvivors = 0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(i)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2) 
				{
					if (IsPlayerAlive(i))
					{
						alivesurvivors++;
					}
				}
			}
		}
		//PrintToServer("Alive survivors %i", alivesurvivors);
		if (alivesurvivors)
		{
			survivors = alivesurvivors;
			SetDifficulty();
		}
		else
		{
			CreateTimer(3.0, Timer_DifficultySet);
		}
	}
}

SetDifficulty()
{
	if (survivors <= 1)
	{
		//PrintToServer("Setting commons for one player.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_01players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_01players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_01players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_01players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_01players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_01players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_01players));
	}
	if (survivors == 2)
	{
		//PrintToServer("Setting commons for two players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_02players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_02players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_02players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_02players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_02players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_02players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_02players));
	}
	if (survivors == 3)
	{
		//PrintToServer("Setting commons for three players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_03players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_03players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_03players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_03players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_03players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_03players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_03players));
	}
	if (survivors == 4)
	{
		//PrintToServer("Setting commons for four players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_04players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_04players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_04players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_04players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_04players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_04players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_04players));
	}
	if (survivors == 5)
	{
		//PrintToServer("Setting commons for five players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_05players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_05players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_05players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_05players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_05players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_05players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_05players));
	}
	if (survivors == 6)
	{
		//PrintToServer("Setting commons for six players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_06players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_06players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_06players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_06players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_06players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_06players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_06players));
	}
	if (survivors == 7)
	{
		//PrintToServer("Setting commons for seven players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_07players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_07players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_07players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_07players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_07players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_07players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_07players));
	}
	if (survivors == 8)
	{
		//PrintToServer("Setting commons for eight players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_08players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_08players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_08players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_08players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_08players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_08players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_08players));
	}
	if (survivors == 9)
	{
		//PrintToServer("Setting commons for nine players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_09players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_09players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_09players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_09players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_09players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_09players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_09players));
	}
	if (survivors == 10)
	{
		//PrintToServer("Setting commons for ten players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_10players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_10players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_10players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_10players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_10players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_10players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_10players));
	}
	if (survivors == 11)
	{
		//PrintToServer("Setting commons for eleven players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_11players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_11players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_11players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_11players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_11players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_11players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_11players));
	}
	if (survivors == 12)
	{
		//PrintToServer("Setting commons for twelve players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_12players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_12players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_12players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_12players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_12players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_12players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_12players));
	}
	if (survivors == 13)
	{
		//PrintToServer("Setting commons for thirteen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_13players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_13players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_13players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_13players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_13players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_13players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_13players));
	}
	if (survivors == 14)
	{
		//PrintToServer("Setting commons for fourteen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_14players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_14players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_14players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_14players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_14players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_14players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_14players));
	}
	if (survivors == 15)
	{
		//PrintToServer("Setting commons for fifteen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_15players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_15players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_15players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_15players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_15players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_15players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_15players));
	}
	if (survivors == 16)
	{
		//PrintToServer("Setting commons for sixteen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_16players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_16players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_16players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_16players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_16players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_16players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_16players));
	}
	if (survivors == 17)
	{
		//PrintToServer("Setting commons for seventeen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_17players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_17players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_17players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_17players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_17players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_17players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_17players));
	}
	if (survivors == 18)
	{
		//PrintToServer("Setting commons for eighteen players.");
		SetConVarInt(FindConVar("z_common_limit"), GetConVarInt(lt4d_z_18players));
		SetConVarInt(FindConVar("z_background_limit"), GetConVarInt(lt4d_z_background_18players));
		SetConVarInt(FindConVar("z_wandering_density"), GetConVarInt(lt4d_z_density_18players));
		SetConVarInt(FindConVar("z_mega_mob_size"), GetConVarInt(lt4d_z_megamob_18players));
		SetConVarInt(FindConVar("z_mob_min_notify_count"), GetConVarInt(lt4d_z_mobmin_18players));
		SetConVarInt(FindConVar("z_mob_spawn_min_size"), GetConVarInt(lt4d_z_mobmin_18players));
		SetConVarInt(FindConVar("z_mob_spawn_max_size"), GetConVarInt(lt4d_z_mobmax_18players));
	}
}
