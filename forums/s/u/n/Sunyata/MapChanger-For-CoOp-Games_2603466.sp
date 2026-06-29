#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION	"1.2"

public Plugin:myinfo =
{
	name = "Campaign/Map changer",
	author = "Allied Modders and Sunyata/Violetstreak",
	description = "Allows any player to change campaign maps ingame",
	version = PLUGIN_VERSION,
	url = "https://wiki.alliedmods.net/Menu_API_(SourceMod)#Simple_Vote"
}

Menu g_MapMenu = null;
 
public void OnPluginStart()
{
	RegConsoleCmd("sm_maps", Command_ChangeMap); // chat command !maps allows any player to change a map
}
 
public void OnMapStart()
{
	g_MapMenu = BuildMapMenu();
}
 
public void OnMapEnd()
{
	if (g_MapMenu != null)
	{
		delete(g_MapMenu);
		g_MapMenu = null;
	}
}
 
Menu BuildMapMenu()
{
	/* Open the file */
	File file = OpenFile("maplist.txt", "rt");
	if (file == null)
	{
		return null;
	}
 
	/* Create the menu Handle */
	Menu menu = new Menu(Menu_ChangeMap);
	char mapname[255];
	while (!file.EndOfFile() && file.ReadLine(mapname, sizeof(mapname)))
	{
		if (mapname[0] == ';' || !IsCharAlpha(mapname[0]))
		{
			continue;
		}
		/* Cut off the name at any whitespace */
		int len = strlen(mapname);
		for (int i=0; i<len; i++)
		{
			if (IsCharSpace(mapname[i]))
			{
				mapname[i] = '\0';
				break;
			}
		}
		/* Check if the map is valid */
		if (!IsMapValid(mapname))
		{
			continue;
		}
		/* Add it to the menu */
		//menu.AddItem(mapname, mapname); //  old map list disabled - replaced by new map list below
		//list of all offical L4D1 maps listed below
		menu.AddItem("l4d_hospital01_apartment", "No Mercy - Map 1");
		menu.AddItem("l4d_hospital02_subway", "No Mercy - Map 2");
		menu.AddItem("l4d_hospital03_sewers", "No Mercy - Map 3");
		menu.AddItem("l4d_hospital04_interior", "No Mercy - Map 4");
		menu.AddItem("l4d_hospital05_rooftop", "No Mercy - Map 5");
		menu.AddItem("l4d_garage01_alleys", "Crash Course - Map 1");
		menu.AddItem("l4d_garage02_lots", "Crash Course - Map 2");
		menu.AddItem("l4d_airport01_greenhouse", "Dead Air - Map 1");
		menu.AddItem("l4d_airport02_offices", "Dead Air - Map 2");
		menu.AddItem("l4d_airport03_garage", "Dead Air - Map 3");
		menu.AddItem("l4d_airport04_terminal", "Dead Air - Map 4");
		menu.AddItem("l4d_airport05_runway", "Dead Air - Map 5");
		menu.AddItem("l4d_smalltown01_caves", "Death Toll - Map 1");
		menu.AddItem("l4d_smalltown02_drainage", "Death Toll - Map 2");
		menu.AddItem("l4d_smalltown03_ranchhouse", "Death Toll - Map 3");
		menu.AddItem("l4d_smalltown04_mainstreet", "Death Toll - Map 4");
		menu.AddItem("l4d_smalltown05_houseboat", "Death Toll - Map 5");
		menu.AddItem("l4d_farm01_hilltop", "Blood Harvest - Map 1");
		menu.AddItem("l4d_farm02_traintunnel", "Blood Harvest - Map 2");
		menu.AddItem("l4d_farm03_bridge", "Blood Harvest - Map 3");
		menu.AddItem("l4d_farm04_barn", "Blood Harvest - Map 4");
		menu.AddItem("l4d_farm05_cornfield", "Blood Harvest - Map 5");
		menu.AddItem("l4d_river01_docks", "The Sacrifice - Map 1");
		menu.AddItem("l4d_river02_barge", "The Sacrifice - Map 2");
		menu.AddItem("l4d_river03_port", "The Sacrifice - Map 3");
		
		//add or remove any L4D1 addon maps here below:
		
 		menu.AddItem("l4d_7hours_later_01", "7 Hours Later"); 
		menu.AddItem("l4d_bs_mansion", "Bloody Sunday");	
		//menu.AddItem("carnage_jail", "Carnage");  //example of omitted map - commented out with "//" so it does not appear in menu
		menu.AddItem("l4d_city17_01", "City 17");
		menu.AddItem("l4d_coaldBlood01", "Coal'd Blood");
		menu.AddItem("l4d_coldfear01_smallforest", "Cold Fear");
		menu.AddItem("l4d_co_canal", "Crossing Over");
		menu.AddItem("l4d_darkblood01_tanker", "Dark Blood");
		menu.AddItem("l4d_dbd_citylights", "Dead Before Dawn");
		menu.AddItem("l4d_de01_sewers", "Dead Echo");	
		menu.AddItem("apartment", "Dead On Time");
		menu.AddItem("route_to_city", "Dead Run");
		menu.AddItem("hotel01_market_two", "Dead Vacation");
		menu.AddItem("l4d_deathaboard01_prison", "Dead Aboard");
		menu.AddItem("l4d_deathrow01_streets", "Death Row");
		menu.AddItem("l4d_draxmap0", "Death Stop");
		menu.AddItem("l4d_derailed_highway3ver", "Derailed");
		menu.AddItem("l4d_scream01_yards", "Die Screaming");
		menu.AddItem("Bus_Depot", "Die Trying");
		menu.AddItem("l4d_eft1_subsystem", "Escape from Toronto");
		menu.AddItem("l4d_fallen01_approach", "Fallen");
		menu.AddItem("l4d_noe1", "Fort Noesis");
		menu.AddItem("AirCrash", "Heaven Can Wait");	
		menu.AddItem("l4d_hospital01_apartmentmodse", "HEM No Mercy Special Edition");				
		menu.AddItem(" l4d_ihm01_forest", "I Hate Mountains");		
		menu.AddItem("l4d_ilogiccity_01", "Ilogic City Of The Dead");
		menu.AddItem("l4d_naniwa01_shoppingmall", "Naniwa City");			
		menu.AddItem("l4d_nt01_mansion", "Night Terror");		
		menu.AddItem("l4d_149_1", "One 9 Nine");
		menu.AddItem("l4d_noprecinct01_crash", "Precinct 84");				
		menu.AddItem("l4d_auburn", "Project Auburn");		
		menu.AddItem("l4d_cine", "Quedan 4x Morir");
		menu.AddItem("redemption-plantworks", "Redemption");				
		menu.AddItem("l4d_sh01_oldsh", "Silent Hill");		
		menu.AddItem("potc1", "Stargate SG-4");
		menu.AddItem("l4d_Stranded01_chopper_down", "Strandead");	
		menu.AddItem("l4d_stadium1_apartment", "Suicide Blitz");		
		menu.AddItem("l4d_sbtd_01", "Surrounded By The Dead");		
		menu.AddItem("c3m1_plankcountry", "Swamp Fever");
		menu.AddItem("l4d_jsarena01_town", "The Arena of the Dead");
		menu.AddItem("l4d_thewoods2_01", "The Woods 2");	
		menu.AddItem("l4d_viennacalling_city", "Vienna Calling");
		menu.AddItem("l4d_ravenholmwar_1", "We Don't Go To Ravenholm");
		
		//list of all offical L4D2 maps listed below
		menu.AddItem("c1m2_streets", "Dead Center - Map 2");
		menu.AddItem("c1m1_hotel", "Dead Center - Map 1"); 
		menu.AddItem("c1m3_mall", "Dead Center - Map 3");
		menu.AddItem("c1m4_atrium", "Dead Center - Map 4");
		menu.AddItem("c2m1_highway", "Dark Carnival - Map 1");
		menu.AddItem("c2m2_fairgrounds", "Dark Carnival - Map 2");
		menu.AddItem("c2m3_coaster", "Dark Carnival - Map 3");
		menu.AddItem("c2m4_barns", "Dark Carnival - Map 4");
		menu.AddItem("c2m5_concert", "Dark Carnival - Map 5");
		menu.AddItem("c3m1_plankcountry", "Swamp Fever - Map 1");
		menu.AddItem("hotel01_market_two", "Swamp Fever - Map 2");
		menu.AddItem("c3m3_shantytown", "Swamp Fever - Map 3");
		menu.AddItem("c3m4_plantation", "Swamp Fever - Map 4");		
		menu.AddItem("c5m1_waterfront", "The Parish - Map 1");
		menu.AddItem("c5m2_park", "The Parish - Map 2");
		menu.AddItem("c5m3_cemetery", "The Parish - Map 3");	
		menu.AddItem("c5m4_quarter", "The Parish - Map 4");				
		menu.AddItem("c5m5_bridge", "The Parish - Map 5");	
		menu.AddItem("c4m1_milltown_a", "Hard Rain - Map 1");
		menu.AddItem("c4m2_sugarmill_a", "Hard Rain - Map 2");
		menu.AddItem("c4m3_sugarmill_b", "Hard Rain - Map 3");
		menu.AddItem("c4m4_milltown_b", "Hard Rain - Map 4");
		menu.AddItem("c4m5_milltown_escape", "Hard Rain - Map 5");
		menu.AddItem("c6m1_riverbank", "The Passing - Map 1");
		menu.AddItem("c6m2_bedlam", "The Passing - Map 2");		
		menu.AddItem("c6m3_port", "The Passing - Map 3");	
		menu.AddItem("c7m1_docks", "The Sacrifice - Map 1"); 
		menu.AddItem("c7m2_barge", "The Sacrifice - Map 2");
		menu.AddItem("c7m3_port", "The Sacrifice - Map 3");
		menu.AddItem("c13m1_alpinecreek", "Cold Stream - Map 1");
		menu.AddItem("c13m2_southpinestream", "Cold Stream - Map 2");
		menu.AddItem("c13m3_memorialbridge", "Cold Stream - Map 3");
		menu.AddItem("c13m4_cutthroatcreek", "Cold Stream - Map 4");		
		menu.AddItem("c8m1_apartment", "No Mercy - Map 1"); 
		menu.AddItem("c8m2_subway", "No Mercy - Map 2");
		menu.AddItem("c8m3_sewers", "No Mercy - Map 3");
		menu.AddItem("c8m4_interior", "No Mercy - Map 4");
		menu.AddItem("c8m5_rooftop", "No Mercy - Map 5");
		menu.AddItem("c9m1_alleys", "Crash Course - Map 1");
		menu.AddItem("c9m2_lots", "Crash Course - Map 2");
		menu.AddItem("c11m1_greenhouse", "Dead Air - Map 1");
		menu.AddItem("c11m2_offices", "Dead Air - Map 2");
		menu.AddItem("c11m3_garage", "Dead Air - Map 3");
		menu.AddItem("c11m4_terminal", "Dead Air - Map 4");
		menu.AddItem("c11m5_runway", "Dead Air - Map 5");
		menu.AddItem("c10m1_caves", "Death Toll - Map 1");
		menu.AddItem("c10m2_drainage", "Death Toll - Map 2");
		menu.AddItem("c10m3_ranchhouse", "Death Toll - Map 3");
		menu.AddItem("c10m4_mainstreet", "Death Toll - Map 4");
		menu.AddItem("c10m5_houseboat", "Death Toll - Map 5");
		menu.AddItem("c12m1_hilltop", "Blood Harvest - Map 1");
		menu.AddItem("c12m2_traintunnel", "Blood Harvest - Map 2");
		menu.AddItem("c12m3_bridge", "Blood Harvest - Map 3");
		menu.AddItem("c12m4_barn", "Blood Harvest - Map 4");
		menu.AddItem("c12m5_cornfield", "Blood Harvest - Map 5");
		
		//add or remove any L4D2 addon maps listed below
		
		menu.AddItem("add_map_name_here", "campaign tba");
		menu.AddItem("add_map_name_here", "campaign tba"); 
		
		//end of map list 
	}
	/* Make sure we close the file! */
	file.Close();
 
	/* Finally, set the title */
	menu.SetTitle("Select Map To Play:");
	return menu;
}
 
public int Menu_ChangeMap(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
 
		/* Get item info */
		bool found = menu.GetItem(param2, info, sizeof(info));
 
		/* Tell the client */
		PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);
 
		/* Change the map */
		ServerCommand("changelevel %s", info);
	}
}
 
public Action Command_ChangeMap(int client, int args)
{
	if (g_MapMenu == null)
	{
		PrintToConsole(client, "The maplist.txt file was not found!");
		return Plugin_Handled;
	}	
 
	g_MapMenu.Display(client, MENU_TIME_FOREVER);
	PrintToChatAll("\x03Members can download \x01our server's addon map versions \x03from this link:\x04 www.tinyurl.com"); // add your own chat message here or comment out
 
	return Plugin_Handled;
}