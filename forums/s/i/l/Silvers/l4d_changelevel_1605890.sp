#include <sourcemod>

// 1.1 = 215 downloads

static bool:g_bLeft4Dead2;

public Plugin:myinfo =
{
	name = "[L4D & L4D2] Change Level",
	author = "SilverShot",
	description = "Allows admins to change level with simple commands.",
	version = "1.2",
	url = "https://www.sourcemod.net/plugins.php?author=Silvers&search=1&sortby=title&order=0"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public OnPluginStart()
{
	if( !g_bLeft4Dead2 )
	{
		RegAdminCmd("11", CC1M1, ADMFLAG_ROOT);
		RegAdminCmd("12", CC1M2, ADMFLAG_ROOT);
		RegAdminCmd("13", CC1M3, ADMFLAG_ROOT);
		RegAdminCmd("14", CC1M4, ADMFLAG_ROOT);
		RegAdminCmd("15", CC1M5, ADMFLAG_ROOT);
		RegAdminCmd("21", CC2M1, ADMFLAG_ROOT);
		RegAdminCmd("22", CC2M2, ADMFLAG_ROOT);
		RegAdminCmd("31", CC3M1, ADMFLAG_ROOT);
		RegAdminCmd("32", CC3M2, ADMFLAG_ROOT);
		RegAdminCmd("33", CC3M3, ADMFLAG_ROOT);
		RegAdminCmd("34", CC3M4, ADMFLAG_ROOT);
		RegAdminCmd("35", CC3M5, ADMFLAG_ROOT);
		RegAdminCmd("41", CC4M1, ADMFLAG_ROOT);
		RegAdminCmd("42", CC4M2, ADMFLAG_ROOT);
		RegAdminCmd("43", CC4M3, ADMFLAG_ROOT);
		RegAdminCmd("44", CC4M4, ADMFLAG_ROOT);
		RegAdminCmd("45", CC4M5, ADMFLAG_ROOT);
		RegAdminCmd("51", CC5M1, ADMFLAG_ROOT);
		RegAdminCmd("52", CC5M2, ADMFLAG_ROOT);
		RegAdminCmd("53", CC5M3, ADMFLAG_ROOT);
		RegAdminCmd("54", CC5M4, ADMFLAG_ROOT);
		RegAdminCmd("55", CC5M5, ADMFLAG_ROOT);
		RegAdminCmd("61", CC6M1, ADMFLAG_ROOT);
		RegAdminCmd("62", CC6M2, ADMFLAG_ROOT);
		RegAdminCmd("63", CC6M3, ADMFLAG_ROOT);

		RegAdminCmd("v11", VC1M1, ADMFLAG_ROOT);
		RegAdminCmd("v12", VC1M2, ADMFLAG_ROOT);
		RegAdminCmd("v13", VC1M3, ADMFLAG_ROOT);
		RegAdminCmd("v14", VC1M4, ADMFLAG_ROOT);
		RegAdminCmd("v15", VC1M5, ADMFLAG_ROOT);
		RegAdminCmd("v21", VC2M1, ADMFLAG_ROOT);
		RegAdminCmd("v22", VC2M2, ADMFLAG_ROOT);
		RegAdminCmd("v31", VC3M1, ADMFLAG_ROOT);
		RegAdminCmd("v32", VC3M2, ADMFLAG_ROOT);
		RegAdminCmd("v33", VC3M3, ADMFLAG_ROOT);
		RegAdminCmd("v34", VC3M4, ADMFLAG_ROOT);
		RegAdminCmd("v35", VC3M5, ADMFLAG_ROOT);
		RegAdminCmd("v41", VC4M1, ADMFLAG_ROOT);
		RegAdminCmd("v42", VC4M2, ADMFLAG_ROOT);
		RegAdminCmd("v43", VC4M3, ADMFLAG_ROOT);
		RegAdminCmd("v44", VC4M4, ADMFLAG_ROOT);
		RegAdminCmd("v45", VC4M5, ADMFLAG_ROOT);
		RegAdminCmd("v51", VC5M1, ADMFLAG_ROOT);
		RegAdminCmd("v52", VC5M2, ADMFLAG_ROOT);
		RegAdminCmd("v53", VC5M3, ADMFLAG_ROOT);
		RegAdminCmd("v54", VC5M4, ADMFLAG_ROOT);
		RegAdminCmd("v55", VC5M5, ADMFLAG_ROOT);
	}

	else if( g_bLeft4Dead2 )
	{
		RegAdminCmd("11", C1M1, ADMFLAG_ROOT);
		RegAdminCmd("12", C1M2, ADMFLAG_ROOT);
		RegAdminCmd("13", C1M3, ADMFLAG_ROOT);
		RegAdminCmd("14", C1M4, ADMFLAG_ROOT);
		RegAdminCmd("21", C2M1, ADMFLAG_ROOT);
		RegAdminCmd("22", C2M2, ADMFLAG_ROOT);
		RegAdminCmd("23", C2M3, ADMFLAG_ROOT);
		RegAdminCmd("24", C2M4, ADMFLAG_ROOT);
		RegAdminCmd("25", C2M5, ADMFLAG_ROOT);
		RegAdminCmd("31", C3M1, ADMFLAG_ROOT);
		RegAdminCmd("32", C3M2, ADMFLAG_ROOT);
		RegAdminCmd("33", C3M3, ADMFLAG_ROOT);
		RegAdminCmd("34", C3M4, ADMFLAG_ROOT);
		RegAdminCmd("41", C4M1, ADMFLAG_ROOT);
		RegAdminCmd("42", C4M2, ADMFLAG_ROOT);
		RegAdminCmd("43", C4M3, ADMFLAG_ROOT);
		RegAdminCmd("44", C4M4, ADMFLAG_ROOT);
		RegAdminCmd("45", C4M5, ADMFLAG_ROOT);
		RegAdminCmd("51", C5M1, ADMFLAG_ROOT);
		RegAdminCmd("52", C5M2, ADMFLAG_ROOT);
		RegAdminCmd("53", C5M3, ADMFLAG_ROOT);
		RegAdminCmd("54", C5M4, ADMFLAG_ROOT);
		RegAdminCmd("55", C5M5, ADMFLAG_ROOT);
		RegAdminCmd("61", C6M1, ADMFLAG_ROOT);
		RegAdminCmd("62", C6M2, ADMFLAG_ROOT);
		RegAdminCmd("63", C6M3, ADMFLAG_ROOT);
		RegAdminCmd("71", C7M1, ADMFLAG_ROOT);
		RegAdminCmd("72", C7M2, ADMFLAG_ROOT);
		RegAdminCmd("73", C7M3, ADMFLAG_ROOT);
		RegAdminCmd("81", C8M1, ADMFLAG_ROOT);
		RegAdminCmd("82", C8M2, ADMFLAG_ROOT);
		RegAdminCmd("83", C8M3, ADMFLAG_ROOT);
		RegAdminCmd("84", C8M4, ADMFLAG_ROOT);
		RegAdminCmd("85", C8M5, ADMFLAG_ROOT);
		RegAdminCmd("91", C9M1, ADMFLAG_ROOT);
		RegAdminCmd("92", C9M2, ADMFLAG_ROOT);
		RegAdminCmd("101", C10M1, ADMFLAG_ROOT);
		RegAdminCmd("102", C10M2, ADMFLAG_ROOT);
		RegAdminCmd("103", C10M3, ADMFLAG_ROOT);
		RegAdminCmd("104", C10M4, ADMFLAG_ROOT);
		RegAdminCmd("105", C10M5, ADMFLAG_ROOT);
		RegAdminCmd("111", C11M1, ADMFLAG_ROOT);
		RegAdminCmd("112", C11M2, ADMFLAG_ROOT);
		RegAdminCmd("113", C11M3, ADMFLAG_ROOT);
		RegAdminCmd("114", C11M4, ADMFLAG_ROOT);
		RegAdminCmd("115", C11M5, ADMFLAG_ROOT);
		RegAdminCmd("121", C12M1, ADMFLAG_ROOT);
		RegAdminCmd("122", C12M2, ADMFLAG_ROOT);
		RegAdminCmd("123", C12M3, ADMFLAG_ROOT);
		RegAdminCmd("124", C12M4, ADMFLAG_ROOT);
		RegAdminCmd("125", C12M5, ADMFLAG_ROOT);
		RegAdminCmd("131", C13M1, ADMFLAG_ROOT);
		RegAdminCmd("132", C13M2, ADMFLAG_ROOT);
		RegAdminCmd("133", C13M3, ADMFLAG_ROOT);
		RegAdminCmd("134", C13M4, ADMFLAG_ROOT);
		RegAdminCmd("141", C14M1, ADMFLAG_ROOT);
		RegAdminCmd("142", C14M2, ADMFLAG_ROOT);
	}
}



// No Mercy
public Action:CC1M1(client, args)
{
	ForceChangeLevel("l4d_hospital01_apartment", "Admin");
	return Plugin_Handled;
}

public Action:CC1M2(client, args)
{
	ForceChangeLevel("l4d_hospital02_subway", "Admin");
	return Plugin_Handled;
}

public Action:CC1M3(client, args)
{
	ForceChangeLevel("l4d_hospital03_sewers", "Admin");
	return Plugin_Handled;
}

public Action:CC1M4(client, args)
{
	ForceChangeLevel("l4d_hospital04_interior", "Admin");
	return Plugin_Handled;
}

public Action:CC1M5(client, args)
{
	ForceChangeLevel("l4d_hospital05_rooftop", "Admin");
	return Plugin_Handled;
}


// VERSUS No Mercy
public Action:VC1M1(client, args)
{
	ForceChangeLevel("l4d_vs_hospital01_apartment", "Admin");
	return Plugin_Handled;
}

public Action:VC1M2(client, args)
{
	ForceChangeLevel("l4d_vs_hospital02_subway", "Admin");
	return Plugin_Handled;
}

public Action:VC1M3(client, args)
{
	ForceChangeLevel("l4d_vs_hospital03_sewers", "Admin");
	return Plugin_Handled;
}

public Action:VC1M4(client, args)
{
	ForceChangeLevel("l4d_vs_hospital04_interior", "Admin");
	return Plugin_Handled;
}

public Action:VC1M5(client, args)
{
	ForceChangeLevel("l4d_vs_hospital05_rooftop", "Admin");
	return Plugin_Handled;
}


// Crash Course
public Action:CC2M1(client, args)
{
	ForceChangeLevel("l4d_garage01_alleys", "Admin");
	return Plugin_Handled;
}

public Action:CC2M2(client, args)
{
	ForceChangeLevel("l4d_garage02_lots", "Admin");
	return Plugin_Handled;
}


// VERSUS Crash Course
public Action:VC2M1(client, args)
{
	ForceChangeLevel("l4d_vs_garage01_alleys", "Admin");
	return Plugin_Handled;
}

public Action:VC2M2(client, args)
{
	ForceChangeLevel("l4d_vs_garage02_lots", "Admin");
	return Plugin_Handled;
}


// Death Toll
public Action:CC3M1(client, args)
{
	ForceChangeLevel("l4d_smalltown01_caves", "Admin");
	return Plugin_Handled;
}

public Action:CC3M2(client, args)
{
	ForceChangeLevel("l4d_smalltown02_drainage", "Admin");
	return Plugin_Handled;
}

public Action:CC3M3(client, args)
{
	ForceChangeLevel("l4d_smalltown03_ranchhouse", "Admin");
	return Plugin_Handled;
}

public Action:CC3M4(client, args)
{
	ForceChangeLevel("l4d_smalltown04_mainstreet", "Admin");
	return Plugin_Handled;
}

public Action:CC3M5(client, args)
{
	ForceChangeLevel("l4d_smalltown05_houseboat", "Admin");
	return Plugin_Handled;
}


// VERSUS Death Toll
public Action:VC3M1(client, args)
{
	ForceChangeLevel("l4d_vs_smalltown01_caves", "Admin");
	return Plugin_Handled;
}

public Action:VC3M2(client, args)
{
	ForceChangeLevel("l4d_vs_smalltown02_drainage", "Admin");
	return Plugin_Handled;
}

public Action:VC3M3(client, args)
{
	ForceChangeLevel("l4d_vs_smalltown03_ranchhouse", "Admin");
	return Plugin_Handled;
}

public Action:VC3M4(client, args)
{
	ForceChangeLevel("l4d_vs_smalltown04_mainstreet", "Admin");
	return Plugin_Handled;
}

public Action:VC3M5(client, args)
{
	ForceChangeLevel("l4d_vs_smalltown05_houseboat", "Admin");
	return Plugin_Handled;
}


// Dead Air
public Action:CC4M1(client, args)
{
	ForceChangeLevel("l4d_airport01_greenhouse", "Admin");
	return Plugin_Handled;
}
public Action:CC4M2(client, args)
{
	ForceChangeLevel("l4d_airport02_offices", "Admin");
	return Plugin_Handled;
}
public Action:CC4M3(client, args)
{
	ForceChangeLevel("l4d_airport03_garage", "Admin");
	return Plugin_Handled;
}
public Action:CC4M4(client, args)
{
	ForceChangeLevel("l4d_airport04_terminal", "Admin");
	return Plugin_Handled;
}

public Action:CC4M5(client, args)
{
	ForceChangeLevel("l4d_airport05_runway", "Admin");
	return Plugin_Handled;
}


// VERSUS Dead Air
public Action:VC4M1(client, args)
{
	ForceChangeLevel("l4d_vs_airport01_greenhouse", "Admin");
	return Plugin_Handled;
}
public Action:VC4M2(client, args)
{
	ForceChangeLevel("l4d_vs_airport02_offices", "Admin");
	return Plugin_Handled;
}
public Action:VC4M3(client, args)
{
	ForceChangeLevel("l4d_vs_airport03_garage", "Admin");
	return Plugin_Handled;
}
public Action:VC4M4(client, args)
{
	ForceChangeLevel("l4d_vs_airport04_terminal", "Admin");
	return Plugin_Handled;
}

public Action:VC4M5(client, args)
{
	ForceChangeLevel("l4d_vs_airport05_runway", "Admin");
	return Plugin_Handled;
}


// Blood Harvest
public Action:CC5M1(client, args)
{
	ForceChangeLevel("l4d_farm01_hilltop", "Admin");
	return Plugin_Handled;
}

public Action:CC5M2(client, args)
{
	ForceChangeLevel("l4d_farm02_traintunnel", "Admin");
	return Plugin_Handled;
}

public Action:CC5M3(client, args)
{
	ForceChangeLevel("l4d_farm03_bridge", "Admin");
	return Plugin_Handled;
}

public Action:CC5M4(client, args)
{
	ForceChangeLevel("l4d_farm04_barn", "Admin");
	return Plugin_Handled;
}

public Action:CC5M5(client, args)
{
	ForceChangeLevel("l4d_farm05_cornfield", "Admin");
	return Plugin_Handled;
}


// VERSUS Blood Harvest
public Action:VC5M1(client, args)
{
	ForceChangeLevel("l4d_vs_farm01_hilltop", "Admin");
	return Plugin_Handled;
}

public Action:VC5M2(client, args)
{
	ForceChangeLevel("l4d_vs_farm02_traintunnel", "Admin");
	return Plugin_Handled;
}

public Action:VC5M3(client, args)
{
	ForceChangeLevel("l4d_vs_farm03_bridge", "Admin");
	return Plugin_Handled;
}

public Action:VC5M4(client, args)
{
	ForceChangeLevel("l4d_vs_farm04_barn", "Admin");
	return Plugin_Handled;
}

public Action:VC5M5(client, args)
{
	ForceChangeLevel("l4d_vs_farm05_cornfield", "Admin");
	return Plugin_Handled;
}


// Sacrifice
public Action:CC6M1(client, args)
{
	ForceChangeLevel("l4d_river01_docks", "Admin");
	return Plugin_Handled;
}

public Action:CC6M2(client, args)
{
	ForceChangeLevel("l4d_river02_barge", "Admin");
	return Plugin_Handled;
}

public Action:CC6M3(client, args)
{
	ForceChangeLevel("l4d_river03_port", "Admin");
	return Plugin_Handled;
}








// DEAD CENTER
public Action:C1M1(client, args)
{
	ForceChangeLevel("c1m1_hotel", "Admin");
	return Plugin_Handled;
}

public Action:C1M2(client, args)
{
	ForceChangeLevel("c1m2_streets", "Admin");
	return Plugin_Handled;
}

public Action:C1M3(client, args)
{
	ForceChangeLevel("c1m3_mall", "Admin");
	return Plugin_Handled;
}

public Action:C1M4(client, args)
{
	ForceChangeLevel("c1m4_atrium", "Admin");
	return Plugin_Handled;
}


// DARK CARNIVAL
public Action:C2M1(client, args)
{
	ForceChangeLevel("c2m1_highway", "Admin");
	return Plugin_Handled;
}

public Action:C2M2(client, args)
{
	ForceChangeLevel("c2m2_fairgrounds", "Admin");
	return Plugin_Handled;
}

public Action:C2M3(client, args)
{
	ForceChangeLevel("c2m3_coaster", "Admin");
	return Plugin_Handled;
}

public Action:C2M4(client, args)
{
	ForceChangeLevel("c2m4_barns", "Admin");
	return Plugin_Handled;
}

public Action:C2M5(client, args)
{
	ForceChangeLevel("c2m5_concert", "Admin");
	return Plugin_Handled;
}


// SWAMP FEVER
public Action:C3M1(client, args)
{
	ForceChangeLevel("c3m1_plankcountry", "Admin");
	return Plugin_Handled;
}

public Action:C3M2(client, args)
{
	ForceChangeLevel("c3m2_swamp", "Admin");
	return Plugin_Handled;
}

public Action:C3M3(client, args)
{
	ForceChangeLevel("c3m3_shantytown", "Admin");
	return Plugin_Handled;
}

public Action:C3M4(client, args)
{
	ForceChangeLevel("c3m4_plantation", "Admin");
	return Plugin_Handled;
}


// HARD RAIN
public Action:C4M1(client, args)
{
	ForceChangeLevel("c4m1_milltown_a", "Admin");
	return Plugin_Handled;
}
public Action:C4M2(client, args)
{
	ForceChangeLevel("c4m2_sugarmill_a", "Admin");
	return Plugin_Handled;
}
public Action:C4M3(client, args)
{
	ForceChangeLevel("c4m3_sugarmill_b", "Admin");
	return Plugin_Handled;
}
public Action:C4M4(client, args)
{
	ForceChangeLevel("c4m4_milltown_b", "Admin");
	return Plugin_Handled;
}

public Action:C4M5(client, args)
{
	ForceChangeLevel("c4m5_milltown_escape", "Admin");
	return Plugin_Handled;
}


// THE PARISH
public Action:C5M1(client, args)
{
	ForceChangeLevel("c5m1_waterfront", "Admin");
	return Plugin_Handled;
}

public Action:C5M2(client, args)
{
	ForceChangeLevel("c5m2_park", "Admin");
	return Plugin_Handled;
}

public Action:C5M3(client, args)
{
	ForceChangeLevel("c5m3_cemetery", "Admin");
	return Plugin_Handled;
}

public Action:C5M4(client, args)
{
	ForceChangeLevel("c5m4_quarter", "Admin");
	return Plugin_Handled;
}

public Action:C5M5(client, args)
{
	ForceChangeLevel("c5m5_bridge", "Admin");
	return Plugin_Handled;
}


// THE PASSING
public Action:C6M1(client, args)
{
	ForceChangeLevel("c6m1_riverbank", "Admin");
	return Plugin_Handled;
}

public Action:C6M2(client, args)
{
	ForceChangeLevel("c6m2_bedlam", "Admin");
	return Plugin_Handled;
}

public Action:C6M3(client, args)
{
	ForceChangeLevel("c6m3_port", "Admin");
	return Plugin_Handled;
}


// THE SACRIFICE
public Action:C7M1(client, args)
{
	ForceChangeLevel("c7m1_docks", "Admin");
	return Plugin_Handled;
}

public Action:C7M2(client, args)
{
	ForceChangeLevel("c7m2_barge", "Admin");
	return Plugin_Handled;
}

public Action:C7M3(client, args)
{
	ForceChangeLevel("c7m3_port", "Admin");
	return Plugin_Handled;
}


// NO MERCY
public Action:C8M1(client, args)
{
	ForceChangeLevel("c8m1_apartment", "Admin");
	return Plugin_Handled;
}

public Action:C8M2(client, args)
{
	ForceChangeLevel("c8m2_subway", "Admin");
	return Plugin_Handled;
}

public Action:C8M3(client, args)
{
	ForceChangeLevel("c8m3_sewers", "Admin");
	return Plugin_Handled;
}

public Action:C8M4(client, args)
{
	ForceChangeLevel("c8m4_interior", "Admin");
	return Plugin_Handled;
}

public Action:C8M5(client, args)
{
	ForceChangeLevel("c8m5_rooftop", "Admin");
	return Plugin_Handled;
}


// CRASH SOURCE
public Action:C9M1(client, args)
{
	ForceChangeLevel("c9m1_alleys", "Admin");
	return Plugin_Handled;
}

public Action:C9M2(client, args)
{
	ForceChangeLevel("c9m2_lots", "Admin");
	return Plugin_Handled;
}


// DEATH TOLL
public Action:C10M1(client, args)
{
	ForceChangeLevel("c10m1_caves", "Admin");
	return Plugin_Handled;
}

public Action:C10M2(client, args)
{
	ForceChangeLevel("c10m2_drainage", "Admin");
	return Plugin_Handled;
}

public Action:C10M3(client, args)
{
	ForceChangeLevel("c10m3_ranchhouse", "Admin");
	return Plugin_Handled;
}

public Action:C10M4(client, args)
{
	ForceChangeLevel("c10m4_mainstreet", "Admin");
	return Plugin_Handled;
}

public Action:C10M5(client, args)
{
	ForceChangeLevel("c10m5_houseboat", "Admin");
	return Plugin_Handled;
}


// DEAD AIR
public Action:C11M1(client, args)
{
	ForceChangeLevel("c11m1_greenhouse", "Admin");
	return Plugin_Handled;
}

public Action:C11M2(client, args)
{
	ForceChangeLevel("c11m2_offices", "Admin");
	return Plugin_Handled;
}

public Action:C11M3(client, args)
{
	ForceChangeLevel("c11m3_garage", "Admin");
	return Plugin_Handled;
}

public Action:C11M4(client, args)
{
	ForceChangeLevel("c11m4_terminal", "Admin");
	return Plugin_Handled;
}

public Action:C11M5(client, args)
{
	ForceChangeLevel("c11m5_runway", "Admin");
	return Plugin_Handled;
}


// BLOOD HARVEST
public Action:C12M1(client, args)
{
	ForceChangeLevel("c12m1_hilltop", "Admin");
	return Plugin_Handled;
}

public Action:C12M2(client, args)
{
	ForceChangeLevel("c12m2_traintunnel", "Admin");
	return Plugin_Handled;
}

public Action:C12M3(client, args)
{
	ForceChangeLevel("c12m3_bridge", "Admin");
	return Plugin_Handled;
}

public Action:C12M4(client, args)
{
	ForceChangeLevel("c12m4_barn", "Admin");
	return Plugin_Handled;
}

public Action:C12M5(client, args)
{
	ForceChangeLevel("c12m5_cornfield", "Admin");
	return Plugin_Handled;
}


// COLD STREAM
public Action:C13M1(client, args)
{
	ForceChangeLevel("c13m1_alpinecreek", "Admin");
	return Plugin_Handled;
}

public Action:C13M2(client, args)
{
	ForceChangeLevel("c13m2_southpinestream", "Admin");
	return Plugin_Handled;
}

public Action:C13M3(client, args)
{
	ForceChangeLevel("c13m3_memorialbridge", "Admin");
	return Plugin_Handled;
}

public Action:C13M4(client, args)
{
	ForceChangeLevel("c13m4_cutthroatcreek", "Admin");
	return Plugin_Handled;
}


// LAST STAND
public Action:C14M1(client, args)
{
	ForceChangeLevel("c14m1_junkyard", "Admin");
	return Plugin_Handled;
}

public Action:C14M2(client, args)
{
	ForceChangeLevel("c14m2_lighthouse", "Admin");
	return Plugin_Handled;
}