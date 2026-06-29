#pragma semicolon 1
#include <sourcemod>
#include <adminmenu>
#include <sdktools>
#pragma newdecls required

#tryinclude <l4d2_changelevel>

TopMenu hTopMenuHandle;

char m1[40];
char m2[40];
char m3[40];
char m4[40];
char m5[40];
char m6[40];
char sName[120];

char sBuffer[64];

#if defined _l4d2_changelevel_included
bool g_bChangeLevel;
#endif

public Plugin myinfo = 
{
	name = "[l4d2] List maps admins",
	author = "dr.lex (Exclusive Coop-17)",
	description = "",
	version = "1.3.1",
	url = "https://forums.alliedmods.net/showthread.php?p=2736182"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_amaps", Cmd_AMenuMaps, ADMFLAG_UNBAN, "");
	
	TopMenu hTop_Menu;
	if (LibraryExists("adminmenu") && ((hTop_Menu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(hTop_Menu);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
#if defined _l4d2_changelevel_included
	else
	{
		if (PluginExists("l4d2_changelevel.smx"))
		{
			g_bChangeLevel = true;
		}
		else
		{
			g_bChangeLevel = false;
		}
	}
#endif
	return APLRes_Success;
}

stock bool PluginExists(const char[] plugin_name)
{
	Handle iter = GetPluginIterator();
	Handle plugin = null;
	char name[64];

	while (MorePlugins(iter))
	{
		plugin = ReadPlugin(iter);
		GetPluginFilename(plugin, name, sizeof(name));
		if (StrEqual(name, plugin_name))
		{
			delete iter;
			return true;
		}
	}

	delete iter;
	return false;
}

public void OnAdminMenuReady(Handle topmenu)
{
	if (topmenu == hTopMenuHandle)
	{
		return;
	}
	
	hTopMenuHandle = view_as<TopMenu>(topmenu);
	TopMenuObject ServerCmdCategory = hTopMenuHandle.FindCategory(ADMINMENU_SERVERCOMMANDS);
	if (ServerCmdCategory != INVALID_TOPMENUOBJECT)
	{
		hTopMenuHandle.AddItem("sm_amaps", AdminMenu_Maps, ServerCmdCategory, "sm_amaps", ADMFLAG_UNBAN);
	}
}

public void AdminMenu_Maps(TopMenu Top_Menu, TopMenuAction action, TopMenuObject object_id, int param, char[] Buffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: Format(Buffer, maxlength, "List of Companies (Maps)");
		case TopMenuAction_SelectOption: Cmd_AMenuMaps(param, 0);
	}
}

public Action Cmd_AMenuMaps(int client, int args)
{
	char mode[32];
	ConVar g_Mode = FindConVar("mp_gamemode");
	GetConVarString(g_Mode, mode, sizeof(mode));
	if (strcmp(mode, "coop") || strcmp(mode, "realism") || strcmp(mode, "versus")  == 0)
	{
		Menu menu = new Menu(MenuHandlerCoop);
		menu.SetTitle("List of Companies (Maps)");
		menu.AddItem("1", "1. Dead Center");
		menu.AddItem("6", "2. The Passing");
		menu.AddItem("2", "3. Dark Carnival");
		menu.AddItem("3", "4. Swamp Fever");
		menu.AddItem("4", "5. Hard Rain");
		menu.AddItem("5", "6. The Parish");
		menu.AddItem("7", "7. The Sacrifice");
		menu.AddItem("8", "8. No Mercy");
		menu.AddItem("9", "9. Crash Course");
		menu.AddItem("10", "10. Death Toll");
		menu.AddItem("11", "11. Dead Air");
		menu.AddItem("12", "12. Blood Harvest");
		menu.AddItem("13", "13. Cold Stream");
		menu.AddItem("14", "14. The Last Stand");
		if (FileExists("missions/bts.txt", true))
		{
			menu.AddItem("D1", "DLC: Back To School");
		}
		if (FileExists("missions/blackoutbasement.txt", true))
		{
			menu.AddItem("D2", "DLC: Blackout Basement");
		}
		if (FileExists("missions/bloodproof.txt", true))
		{
			menu.AddItem("D3", "DLC: Blood Proof");
		}
		if (FileExists("missions/city17l4d2.txt", true))
		{
			menu.AddItem("D4", "DLC: City 17");
		}
		if (FileExists("missions/chernobyl_mission.txt", true))
		{
			menu.AddItem("D5", "DLC: Chernobyl: Chapter One");
		}
		if (FileExists("missions/damit.txt", true))
		{
			menu.AddItem("D6", "DLC: Dam it 2! The Director's Cut");
		}
		if (FileExists("missions/damitrm.txt", true))
		{
			menu.AddItem("D7", "DLC: Dam It [Remastered]");
		}
		if (FileExists("missions/darkwood.txt", true))
		{
			menu.AddItem("D8", "DLC: Dark Wood (Extended)");
		}
		if (FileExists("missions/dbdextended.txt", true))
		{
			menu.AddItem("D9", "DLC: Dead Before Dawn (Extended)");
		}
		if (FileExists("missions/deadcity2.txt", true))
		{
			menu.AddItem("D10", "DLC: Dead City II");
		}
		if (FileExists("missions/deadbeat.txt", true))
		{
			menu.AddItem("D11", "DLC: Deadbeat Escape");
		}
		if (FileExists("missions/deathrow.txt", true))
		{
			menu.AddItem("D12", "DLC: Death Row");
		}
		if (FileExists("missions/draxmap2_missions.txt", true))
		{
			menu.AddItem("D13", "DLC: Death Strip");
		}
		if (FileExists("missions/devilmountain.txt", true))
		{
			menu.AddItem("D14", "DLC: Devil Mountain");
		}
		if (FileExists("missions/l4d2_diescraper_362.txt", true))
		{
			menu.AddItem("D15", "DLC: Diescraper Redux");
		}
		if (FileExists("missions/fallindeath.txt", true))
		{
			menu.AddItem("D16", "DLC: Fall in Death");
		}
		if (FileExists("missions/farewell_chenming.txt", true))
		{
			menu.AddItem("D17", "DLC: Farewell Chenming");
		}
		if (FileExists("missions/highway.txt", true))
		{
			menu.AddItem("D33", "DLC: Highway To Hell");
		}
		if (FileExists("missions/ihatemountains.txt", true))
		{
			menu.AddItem("D19", "DLC: I Hate Mountains");
		}
		if (FileExists("missions/behind.txt", true))
		{
			menu.AddItem("D20", "DLC: Left Behind");
		}
		if (FileExists("missions/lockdown.txt", true))
		{
			menu.AddItem("D35", "DLC: Lockdown");
		}
		if (FileExists("missions/l4d2_planb_v051.txt", true))
		{
			menu.AddItem("D22", "DLC: Plan B");
		}
		if (FileExists("missions/precinct84.txt", true))
		{
			menu.AddItem("D23", "DLC: Precinct 84");
		}
		if (FileExists("missions/red.txt", true))
		{
			menu.AddItem("D24", "DLC: RedemptionII");
		}
		if (FileExists("missions/suicideblitz2.txt", true))
		{
			menu.AddItem("D25", "DLC: Suicide Blitz 2");
		}
		if (FileExists("missions/l4d2_thebloodymoors.txt", true))
		{
			menu.AddItem("D26", "DLC: The Bloody Moors");
		}
		if (FileExists("missions/tot.txt", true))
		{
			menu.AddItem("D27", "DLC: Tour of Terror");
		}
		if (FileExists("missions/urbanflight.txt", true))
		{
			menu.AddItem("D28", "DLC: Urban Flight");
		}
		if (FileExists("missions/viennacalling.txt", true))
		{
			menu.AddItem("D29", "DLC: Vienna Calling 1");
		}
		if (FileExists("missions/viennacalling2.txt", true))
		{
			menu.AddItem("D34", "DLC: Vienna Calling 2");
		}
		if (FileExists("missions/warcelona.txt", true))
		{
			menu.AddItem("D30", "DLC: Warcelona");
		}
		if (FileExists("missions/ravenholmwarmission2.txt", true))
		{
			menu.AddItem("D31", "DLC: We Don't Go To Ravenholm");
		}
		if (FileExists("missions/yama.txt", true))
		{
			menu.AddItem("D32", "DLC: Yama");
		}
		menu.ExitBackButton = true;
		menu.Display(client, 30);
	}
	if (strcmp(mode, "survival")  == 0)
	{
		Menu menu = new Menu(MenuHandlerSurvival);
		menu.SetTitle("List of Companies (Maps)");
		menu.AddItem("1", "1. Dead Center");
		menu.AddItem("6", "2. The Passing");
		menu.AddItem("2", "3. Dark Carnival");
		menu.AddItem("3", "4. Swamp Fever");
		menu.AddItem("4", "5. Hard Rain");
		menu.AddItem("5", "6. The Parish");
		menu.AddItem("7", "7. The Sacrifice");
		menu.AddItem("8", "8. No Mercy");
		menu.AddItem("9", "9. Crash Course");
		menu.AddItem("10", "10. Death Toll");
		menu.AddItem("11", "11. Dead Airl");
		menu.AddItem("12", "12. Blood Harvest");
		menu.AddItem("13", "13. Cold Stream");
		menu.AddItem("14", "14. The Last Stand");
		if (FileExists("missions/darkwood.txt", true))
		{
			menu.AddItem("D1", "DLC: Dark Wood (Extended)");
		}
		if (FileExists("missions/devilmountain.txt", true))
		{
			menu.AddItem("D2", "DLC: Devil Mountain");
		}
		if (FileExists("missions/l4d2_diescraper_362.txt", true))
		{
			menu.AddItem("D3", "DLC: Diescraper Redux");
		}
		if (FileExists("missions/fallindeath.txt", true))
		{
			menu.AddItem("D4", "DLC: Fall in Death");
		}
		if (FileExists("missions/farewell_chenming.txt", true))
		{
			menu.AddItem("D5", "DLC: Farewell Chenming");
		}
		if (FileExists("missions/behind.txt", true))
		{
			menu.AddItem("D7", "DLC: Left Behind");
		}
		if (FileExists("missions/precinct84.txt", true))
		{
			menu.AddItem("D8", "DLC: Precinct 84");
		}
		if (FileExists("missions/suicideblitz2.txt", true))
		{
			menu.AddItem("D9", "DLC: Suicide Blitz 2");
		}
		if (FileExists("missions/l4d2_thebloodymoors.txt", true))
		{
			menu.AddItem("D10", "DLC: The Bloody Moors");
		}
		if (FileExists("missions/tot.txt", true))
		{
			menu.AddItem("D11", "DLC: Tour of Terror");
		}
		if (FileExists("missions/urbanflight.txt", true))
		{
			menu.AddItem("D12", "DLC: Urban Flight");
		}
		if (FileExists("missions/ravenholmwarmission2.txt", true))
		{
			menu.AddItem("D13", "DLC: We Don't Go To Ravenholm");
		}
		if (FileExists("missions/yama.txt", true))
		{
			menu.AddItem("D14", "DLC: Yama");
		}
		menu.ExitBackButton = true;
		menu.Display(client, 30);
	}
	if (strcmp(mode, "scavenge")  == 0)
	{
		Menu menu = new Menu(MenuHandlerScavenge);
		menu.SetTitle("List of Companies (Maps)");
		menu.AddItem("1", "1. Dead Center");
		menu.AddItem("6", "2. The Passing");
		menu.AddItem("2", "3. Dark Carnival");
		menu.AddItem("3", "4. Swamp Fever");
		menu.AddItem("4", "5. Hard Rain");
		menu.AddItem("5", "6. The Parish");
		menu.AddItem("7", "7. The Sacrifice");
		menu.AddItem("8", "8. No Mercy");
		menu.AddItem("9", "9. Crash Course");
		menu.AddItem("10", "10. Death Toll");
		menu.AddItem("11", "11. Dead Air");
		menu.AddItem("12", "12. Blood Harvest");
		menu.AddItem("13", "13. The Last Stand");
		menu.ExitBackButton = true;
		menu.Display(client, 30);
	}
	return Plugin_Handled;
}

public int MenuHandlerCoop(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info, "1") == 0)
			{
				Campaign(param1, 1, 4);
			}
			if (strcmp(info, "2") == 0)
			{
				Campaign(param1, 2, 5);
			}		
			if (strcmp(info, "3") == 0)
			{
				Campaign(param1, 3, 4);
			}
			if (strcmp(info, "4") == 0)
			{
				Campaign(param1, 4, 5);
			}
			if (strcmp(info, "5") == 0)
			{
				Campaign(param1, 5, 5);
			}
			if (strcmp(info, "6") == 0)
			{
				Campaign(param1, 6, 3);
			}
			if (strcmp(info, "7") == 0)
			{
				Campaign(param1, 7, 3);
			}
			if (strcmp(info, "8") == 0)
			{
				Campaign(param1, 8, 5);
			}
			if (strcmp(info, "9") == 0)
			{
				Campaign(param1, 9, 2);
			}
			if (strcmp(info, "10") == 0)
			{
				Campaign(param1, 10, 5);
			}
			if (strcmp(info, "11") == 0)
			{
				Campaign(param1, 11, 5);
			}
			if (strcmp(info, "12") == 0)
			{
				Campaign(param1, 12, 5);
			}
			if (strcmp(info, "13") == 0)
			{
				Campaign(param1, 13, 4);
			}
			if (strcmp(info, "14") == 0)
			{
				Campaign(param1, 14, 2);
			}
			if (strcmp(info, "D1") == 0)
			{
				CampaignDcl(param1, 1, 6);
			}
			if (strcmp(info, "D2") == 0)
			{
				CampaignDcl(param1, 2, 4);
			}		
			if (strcmp(info, "D3") == 0)
			{
				CampaignDcl(param1, 3, 3);
			}
			if (strcmp(info, "D4") == 0)
			{
				CampaignDcl(param1, 4, 5);
			}
			if (strcmp(info, "D5") == 0)
			{
				CampaignDcl(param1, 5, 5);
			}
			if (strcmp(info, "D6") == 0)
			{
				CampaignDcl(param1, 6, 4);
			}
			if (strcmp(info, "D7") == 0)
			{
				CampaignDcl(param1, 7, 3);
			}
			if (strcmp(info, "D8") == 0)
			{
				CampaignDcl(param1, 8, 5);
			}
			if (strcmp(info, "D9") == 0)
			{
				CampaignDcl(param1, 9, 6);
			}
			if (strcmp(info, "D10") == 0)
			{
				CampaignDcl(param1, 10, 6);
			}
			if (strcmp(info, "D11") == 0)
			{
				CampaignDcl(param1, 11, 4);
			}
			if (strcmp(info, "D12") == 0)
			{
				CampaignDcl(param1, 12, 4);
			}
			if (strcmp(info, "D13") == 0)
			{
				CampaignDcl(param1, 13, 6);
			}
			if (strcmp(info, "D14") == 0)
			{
				CampaignDcl(param1, 14, 5);
			}
			if (strcmp(info, "D15") == 0)
			{
				CampaignDcl(param1, 15, 4);
			}
			if (strcmp(info, "D16") == 0)
			{
				CampaignDcl(param1, 16, 4);
			}
			if (strcmp(info, "D17") == 0)
			{
				CampaignDcl(param1, 17, 4);
			}
			if (strcmp(info, "D19") == 0)
			{
				CampaignDcl(param1, 19, 5);
			}
			if (strcmp(info, "D20") == 0)
			{
				CampaignDcl(param1, 20, 4);
			}
			if (strcmp(info, "D22") == 0)
			{
				CampaignDcl(param1, 22, 3);
			}
			if (strcmp(info, "D23") == 0)
			{
				CampaignDcl(param1, 23, 4);
			}
			if (strcmp(info, "D24") == 0)
			{
				CampaignDcl(param1, 24, 5);
			}
			if (strcmp(info, "D25") == 0)
			{
				CampaignDcl(param1, 25, 5);
			}
			if (strcmp(info, "D26") == 0)
			{
				CampaignDcl(param1, 26, 5);
			}
			if (strcmp(info, "D27") == 0)
			{
				CampaignDcl(param1, 27, 5);
			}
			if (strcmp(info, "D28") == 0)
			{
				CampaignDcl(param1, 28, 4);
			}
			if (strcmp(info, "D29") == 0)
			{
				CampaignDcl(param1, 29, 5);
			}
			if (strcmp(info, "D30") == 0)
			{
				CampaignDcl(param1, 30, 4);
			}
			if (strcmp(info, "D31") == 0)
			{
				CampaignDcl(param1, 31, 4);
			}
			if (strcmp(info, "D32") == 0)
			{
				CampaignDcl(param1, 32, 5);
			}
			if (strcmp(info, "D33") == 0)
			{
				CampaignDcl(param1, 33, 5);
			}
			if (strcmp(info, "D34") == 0)
			{
				CampaignDcl(param1, 34, 6);
			}
			if (strcmp(info, "D35") == 0)
			{
				CampaignDcl(param1, 35, 5);
			}
		}
	}
}

public Action Campaign(int client, int campaigns, int maps)
{
	switch (campaigns)
	{
		case 1:
		{
			sName = "Dead Center";
			m1 = "c1m1_hotel";
			m2 = "c1m2_streets";
			m3 = "c1m3_mall";
			m4 = "c1m4_atrium";
		}
		case 2:
		{
			sName = "Dark Carnival";
			m1 = "c2m1_highway";
			m2 = "c2m2_fairgrounds";
			m3 = "c2m3_coaster";
			m4 = "c2m4_barns";
			m5 = "c2m5_concert";
		}
		case 3:
		{
			sName = "Swamp Fever";
			m1 = "c3m1_plankcountry";
			m2 = "c3m2_swamp";
			m3 = "c3m3_shantytown";
			m4 = "c3m4_plantation";
		}
		case 4:
		{
			sName = "Hard Rain";
			m1 = "c4m1_milltown_a";
			m2 = "c4m2_sugarmill_a";
			m3 = "c4m3_sugarmill_b";
			m4 = "c4m4_milltown_b";
			m5 = "c4m5_milltown_escape";
		}
		case 5:
		{
			sName = "The Parish";
			m1 = "c5m1_waterfront";
			m2 = "c5m2_park";
			m3 = "c5m3_cemetery";
			m4 = "c5m4_quarter";
			m5 = "c5m5_bridge";
		}
		case 6:
		{
			sName = "The Passing";
			m1 = "c6m1_riverbank";
			m2 = "c6m2_bedlam";
			m3 = "c6m3_port";
		}
		case 7:
		{
			sName = "The Sacrifice";
			m1 = "c7m1_docks";
			m2 = "c7m2_barge";
			m3 = "c7m3_port";
		}
		case 8:
		{
			sName = "No Mercy";
			m1 = "c8m1_apartment";
			m2 = "c8m2_subway";
			m3 = "c8m3_sewers";
			m4 = "c8m4_interior";
			m5 = "c8m5_rooftop";
		}
		case 9:
		{
			sName = "Crash Course";
			m1 = "c9m1_alleys";
			m2 = "c9m2_lots";
		}
		case 10:
		{
			sName = "Death Toll";
			m1 = "c10m1_caves";
			m2 = "c10m2_drainage";
			m3 = "c10m3_ranchhouse";
			m4 = "c10m4_mainstreet";
			m5 = "c10m5_houseboat";
		}
		case 11:
		{
			sName = "Dead Airl";
			m1 = "c11m1_greenhouse";
			m2 = "c11m2_offices";
			m3 = "c11m3_garage";
			m4 = "c11m4_terminal";
			m5 = "c11m5_runway";
		}
		case 12:
		{
			sName = "Blood Harvest";
			m1 = "c12m1_hilltop";
			m2 = "c12m2_traintunnel";
			m3 = "c12m3_bridge";
			m4 = "c12m4_barn";
			m5 = "c12m5_cornfield";
		}
		case 13:
		{
			sName = "Cold Stream";
			m1 = "c13m1_alpinecreek";
			m2 = "c13m2_southpinestream";
			m3 = "c13m3_memorialbridge";
			m4 = "c13m4_cutthroatcreek";
		}
		case 14:
		{
			sName = "The Last Stand";
			m1 = "c14m1_junkyard";
			m2 = "c14m2_lighthouse";
		}
	}
	
	Menu menu = new Menu(CampaignHandler);
	menu.SetTitle("%s [Maps]", sName);
	Format(sBuffer, sizeof(sBuffer)-1, "Start > %s", m1);
	menu.AddItem("1", sBuffer);
	Format(sBuffer, sizeof(sBuffer)-1, "Map #2: %s", m2);
	menu.AddItem("2", sBuffer);
	if (maps > 2)
	{
		Format(sBuffer, sizeof(sBuffer)-1, "Map #3: %s", m3);
		menu.AddItem("3", sBuffer);
		if (maps > 3)
		{
			Format(sBuffer, sizeof(sBuffer)-1, "Map #4: %s", m4);
			menu.AddItem("4", sBuffer);
			if (maps > 4)
			{
				Format(sBuffer, sizeof(sBuffer)-1, "Map #5: %s", m5);
				menu.AddItem("5", sBuffer);
			}
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int MenuHandlerSurvival(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (strcmp(info, "1") == 0)
			{
				CampaignSurvival(param1, 1, 2);
			}
			if (strcmp(info, "2") == 0)
			{
				CampaignSurvival(param1, 2, 3);
			}		
			if (strcmp(info, "3") == 0)
			{
				CampaignSurvival(param1, 3, 3);
			}
			if (strcmp(info, "4") == 0)
			{
				CampaignSurvival(param1, 4, 3);
			}
			if (strcmp(info, "5") == 0)
			{
				CampaignSurvival(param1, 5, 5);
			}
			if (strcmp(info, "6") == 0)
			{
				CampaignSurvival(param1, 6, 3);
			}
			if (strcmp(info, "7") == 0)
			{
				CampaignSurvival(param1, 7, 3);
			}
			if (strcmp(info, "8") == 0)
			{
				CampaignSurvival(param1, 8, 4);
			}
			if (strcmp(info, "9") == 0)
			{
				CampaignSurvival(param1, 9, 2);
			}
			if (strcmp(info, "10") == 0)
			{
				CampaignSurvival(param1, 10, 4);
			}
			if (strcmp(info, "11") == 0)
			{
				CampaignSurvival(param1, 11, 4);
			}
			if (strcmp(info, "12") == 0)
			{
				CampaignSurvival(param1, 12, 3);
			}
			if (strcmp(info, "13") == 0)
			{
				CampaignSurvival(param1, 13, 2);
			}
			if (strcmp(info, "14") == 0)
			{
				CampaignSurvival(param1, 14, 2);
			}
			if (strcmp(info, "D1") == 0)
			{
				CampaignSurvivalDLC(param1, 1, 1);
			}
			if (strcmp(info, "D2") == 0)
			{
				CampaignSurvivalDLC(param1, 2, 2);
			}		
			if (strcmp(info, "D3") == 0)
			{
				CampaignSurvivalDLC(param1, 3, 2);
			}
			if (strcmp(info, "D4") == 0)
			{
				CampaignSurvivalDLC(param1, 4, 2);
			}
			if (strcmp(info, "D5") == 0)
			{
				CampaignSurvivalDLC(param1, 5, 1);
			}
			if (strcmp(info, "D7") == 0)
			{
				CampaignSurvivalDLC(param1, 7, 1);
			}
			if (strcmp(info, "D8") == 0)
			{
				CampaignSurvivalDLC(param1, 8, 1);
			}
			if (strcmp(info, "D9") == 0)
			{
				CampaignSurvivalDLC(param1, 9, 3);
			}
			if (strcmp(info, "D10") == 0)
			{
				CampaignSurvivalDLC(param1, 10, 5);
			}
			if (strcmp(info, "D11") == 0)
			{
				CampaignSurvivalDLC(param1, 11, 4);
			}
			if (strcmp(info, "D12") == 0)
			{
				CampaignSurvivalDLC(param1, 12, 2);
			}
			if (strcmp(info, "D13") == 0)
			{
				CampaignSurvivalDLC(param1, 13, 2);
			}
			if (strcmp(info, "D14") == 0)
			{
				CampaignSurvivalDLC(param1, 14, 3);
			}
		}
	}
}

public Action CampaignSurvival(int client, int campaigns, int maps)
{
	switch (campaigns)
	{
		case 1:
		{
			sName = "Dead Center";
			m1 = "c1m2_streets";
			m2 = "c1m4_atrium";
		}
		case 2:
		{
			sName = "Dark Carnival";
			m1 = "c2m1_highway";
			m2 = "c2m4_barns";
			m3 = "c2m5_concert";
		}
		case 3:
		{
			sName = "Swamp Fever";
			m1 = "c3m1_plankcountry";
			m2 = "c3m3_shantytown";
			m3 = "c3m4_plantation";
		}
		case 4:
		{
			sName = "Hard Rain";
			m1 = "c4m1_milltown_a";
			m2 = "c4m2_sugarmill_a";
			m3 = "c4m3_sugarmill_b";
		}
		case 5:
		{
			sName = "The Parish";
			m1 = "c5m1_waterfront";
			m2 = "c5m2_park";
			m3 = "c5m3_cemetery";
			m4 = "c5m4_quarter";
			m5 = "c5m5_bridge";
		}
		case 6:
		{
			sName = "The Passing";
			m1 = "c6m1_riverbank";
			m2 = "c6m2_bedlam";
			m3 = "c6m3_port";
		}
		case 7:
		{
			sName = "The Sacrifice";
			m1 = "c7m1_docks";
			m2 = "c7m2_barge";
			m3 = "c7m3_port";
		}
		case 8:
		{
			sName = "No Mercy";
			m1 = "c8m2_subway";
			m2 = "c8m3_sewers";
			m3 = "c8m4_interior";
			m4 = "c8m5_rooftop";
		}
		case 9:
		{
			sName = "Crash Course";
			m1 = "c9m1_alleys";
			m2 = "c9m2_lots";
		}
		case 10:
		{
			sName = "Death Toll";
			m1 = "c10m2_drainage";
			m2 = "c10m3_ranchhouse";
			m3 = "c10m4_mainstreet";
			m4 = "c10m5_houseboat";
		}
		case 11:
		{
			sName = "Dead Airl";
			m1 = "c11m2_offices";
			m2 = "c11m3_garage";
			m3 = "c11m4_terminal";
			m4 = "c11m5_runway";
		}
		case 12:
		{
			sName = "Blood Harvest";
			m1 = "c12m2_traintunnel";
			m2 = "c12m3_bridge";
			m3 = "c12m5_cornfield";
		}
		case 13:
		{
			sName = "Cold Stream";
			m1 = "c12m2_traintunnel";
			m2 = "c12m3_bridge";
		}
		case 14:
		{
			sName = "The Last Stand";
			m1 = "c14m1_junkyard";
			m2 = "c14m2_lighthouse";
		}
	}
	
	Menu menu = new Menu(CampaignHandler);
	menu.SetTitle("%s [Maps]", sName);
	Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m1);
	menu.AddItem("1", sBuffer);
	if (maps > 1)
	{
		Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m2);
		menu.AddItem("2", sBuffer);
		if (maps > 2)
		{
			Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m3);
			menu.AddItem("3", sBuffer);
			if (maps > 3)
			{
				Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m4);
				menu.AddItem("4", sBuffer);
			}
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int MenuHandlerScavenge(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
				CampaignScavenge(param1, 1, 1);
			}
			if (strcmp(info,"2") == 0)
			{
				CampaignScavenge(param1, 2, 1);
			}		
			if (strcmp(info,"3") == 0)
			{
				CampaignScavenge(param1, 3, 1);
			}
			if (strcmp(info,"4") == 0)
			{
				CampaignScavenge(param1, 4, 3);
			}
			if (strcmp(info,"5") == 0)
			{
				CampaignScavenge(param1, 5, 1);
			}
			if (strcmp(info,"6") == 0)
			{
				CampaignScavenge(param1, 6, 3);
			}
			if (strcmp(info,"7") == 0)
			{
				CampaignScavenge(param1, 7, 2);
			}
			if (strcmp(info,"8") == 0)
			{
				CampaignScavenge(param1, 8, 2);
			}
			if (strcmp(info,"9") == 0)
			{
				CampaignScavenge(param1, 9, 1);
			}
			if (strcmp(info,"10") == 0)
			{
				CampaignScavenge(param1, 10, 1);
			}
			if (strcmp(info,"11") == 0)
			{
				CampaignScavenge(param1, 11, 1);
			}
			if (strcmp(info,"12") == 0)
			{
				CampaignScavenge(param1, 12, 1);
			}
			if (strcmp(info,"13") == 0)
			{
				CampaignScavenge(param1, 13, 2);
			}
		}
	}
}

public Action CampaignScavenge(int client, int campaigns, int maps)
{
	switch (campaigns)
	{
		case 1:
		{
			sName = "Dead Center";
			m1 = "c1m4_atrium";
		}
		case 2:
		{
			sName = "Dark Carnival";
			m1 = "c2m1_highway";
		}
		case 3:
		{
			sName = "Swamp Fever";
			m1 = "c3m1_plankcountry";
		}
		case 4:
		{
			sName = "Hard Rain";
			m1 = "c4m1_milltown_a";
			m2 = "c4m2_sugarmill_a";
			m3 = "c4m3_sugarmill_b";
		}
		case 5:
		{
			sName = "The Parish";
			m1 = "c5m2_park";
		}
		case 6:
		{
			sName = "The Passing";
			m1 = "c6m1_riverbank";
			m2 = "c6m2_bedlam";
			m3 = "c6m3_port";
		}
		case 7:
		{
			sName = "The Sacrifice";
			m1 = "c7m1_docks";
			m2 = "c7m2_barge";
		}
		case 8:
		{
			sName = "No Mercy";
			m1 = "c8m1_apartment";
			m2 = "c8m5_rooftop";
		}
		case 9:
		{
			sName = "Crash Course";
			m1 = "c9m1_alleys";
		}
		case 10:
		{
			sName = "Death Toll";
			m1 = "c10m3_ranchhouse";
		}
		case 11:
		{
			sName = "Dead Airl";
			m1 = "c11m4_terminal";
		}
		case 12:
		{
			sName = "Blood Harvest";
			m1 = "c12m5_cornfield";
		}
		case 13:
		{
			sName = "The Last Stand";
			m1 = "c14m1_junkyard";
			m2 = "c14m2_lighthouse";
		}
	}
	
	Menu menu = new Menu(CampaignHandler);
	menu.SetTitle("%s [Maps]", sName);
	Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m1);
	menu.AddItem("1", sBuffer);
	if (maps > 1)
	{
		Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m2);
		menu.AddItem("2", sBuffer);
		if (maps > 2)
		{
			Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m3);
			menu.AddItem("3", sBuffer);
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int CampaignHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (strcmp(info,"1") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m1);
				}
				else
				{
					ServerCommand("changelevel %s", m1);
				}
			#else
				ServerCommand("changelevel %s", m1);
			#endif
			}
			if (strcmp(info,"2") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m2);
				}
				else
				{
					ServerCommand("changelevel %s", m2);
				}
			#else
				ServerCommand("changelevel %s", m2);
			#endif
			}
			if (strcmp(info,"3") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m3);
				}
				else
				{
					ServerCommand("changelevel %s", m3);
				}
			#else
				ServerCommand("changelevel %s", m3);
			#endif
			}
			if (strcmp(info,"4") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m4);
				}
				else
				{
					ServerCommand("changelevel %s", m4);
				}
			#else
				ServerCommand("changelevel %s", m4);
			#endif
			}
			if (strcmp(info,"5") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m5);
				}
				else
				{
					ServerCommand("changelevel %s", m5);
				}
			#else
				ServerCommand("changelevel %s", m5);
			#endif
			}
			if (strcmp(info,"6") == 0)
			{
			#if defined _l4d2_changelevel_included
				if (g_bChangeLevel)
				{
					L4D2_ChangeLevel(m6);
				}
				else
				{
					ServerCommand("changelevel %s", m6);
				}
			#else
				ServerCommand("changelevel %s", m6);
			#endif
			}
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Cmd_AMenuMaps(param1, 0);
			}
		}
	}
}

public Action CampaignDcl(int client, int campaigns, int maps)
{
	switch (campaigns)
	{
		case 1:
		{
			sName = "Back To School";
			m1 = "l4d2_bts01_forest";
			m2 = "l4d2_bts02_station";
			m3 = "l4d2_bts03_town";
			m4 = "l4d2_bts04_cinema";
			m5 = "l4d2_bts05_church";
			m6 = "l4d2_bts06_school";
		}
		case 2:
		{
			sName = "Blackout Basement";
			m1 = "l4dblackoutbasement1";
			m2 = "l4dblackoutbasement2";
			m3 = "l4dblackoutbasement3";
			m4 = "l4dblackoutbasement4";
		}
		case 3:
		{
			sName = "Blood Proof";
			m1 = "cbm1_lake";
			m2 = "cbm2_town";
			m3 = "cbm3_bunker";
		}
		case 4:
		{
			sName = "City 17";
			m1 = "l4d2_city17_01";
			m2 = "l4d2_city17_02";
			m3 = "l4d2_city17_03";
			m4 = "l4d2_city17_04";
			m5 = "l4d2_city17_05";
		}
		case 5:
		{
			sName = "Chernobyl: Chapter One";
			m1 = "ch01_jupiter";
			m2 = "ch02_pripyat01";
			m3 = "ch03_pripyat02";
			m4 = "ch04_pripyat03";
			m5 = "ch05_pripyat04";
		}
		case 6:
		{
			sName = "Dam it 2! The Director's Cut";
			m1 = "damitdc1";
			m2 = "damitdc2";
			m3 = "damitdc3";
			m4 = "damitdc4";
		}
		case 7:
		{
			sName = "Dam It [Remastered]";
			m1 = "c14m1_orchard";
			m2 = "c14m2_campground";
			m3 = "c14m3_dam";
		}
		case 8:
		{
			sName = "Dark Wood (Extended)";
			m1 = "dw_woods";
			m2 = "dw_underground";
			m3 = "dw_complex";
			m4 = "dw_otherworld";
			m5 = "dw_final";
		}
		case 9:
		{
			sName = "Dead Before Dawn (Extended)";
			m1 = "l4d_dbde_citylights";
			m2 = "l4d_dbde_anna_is_gone";
			m3 = "l4d_dbde_the_mall";
			m4 = "l4d_dbdext_clean_up";
			m5 = "l4d_dbdext_undead_center";
			m6 = "l4d_dbdext_new_dawn";
		}
		case 10:
		{
			sName = "DeadCity II";
			m1 = "l4d2_deadcity01_riverside";
			m2 = "l4d2_deadcity02_backalley";
			m3 = "l4d2_deadcity03_bridge";
			m4 = "l4d2_deadcity04_outpost";
			m5 = "l4d2_deadcity05_plant";
			m6 = "l4d2_deadcity06_station";
		}
		case 11:
		{
			sName = "Deadbeat Escape";
			m1 = "deadbeat01_forest";
			m2 = "deadbeat02_alley";
			m3 = "deadbeat03_street";
			m4 = "deadbeat04_park";
		}
		case 12:
		{
			sName = "Death Row";
			m1 = "deathrow01_streets";
			m2 = "deathrow02_outskirts";
			m3 = "deathrow03_prison";
			m4 = "deathrow04_courtyard";
		}
		case 13:
		{
			sName = "Death Strip";
			m1 = "l4d2_draxmap1";
			m2 = "l4d2_draxmap2";
			m3 = "l4d2_draxmap3";
			m4 = "l4d2_draxmap4";
			m5 = "l4d2_draxmap5";
			m6 = "l4d2_draxmap6";
		}
		case 14:
		{
			sName = "Devil Mountain";
			m1 = "dm1_suburbs";
			m2 = "dm2_blastzone";
			m3 = "dm3_canyon";
			m4 = "dm4_caves";
			m5 = "dm5_summit";
		}
		case 15:
		{
			sName = "Diescraper Redux";
			m1 = "l4d2_diescraper1_apartment_361";
			m2 = "l4d2_diescraper2_streets_361";
			m3 = "l4d2_diescraper3_mid_361";
			m4 = "l4d2_diescraper4_top_361";
		}
		case 16:
		{
			sName = "Fall in Death";
			m1 = "l4d2_fallindeath01";
			m2 = "l4d2_fallindeath02";
			m3 = "l4d2_fallindeath03";
			m4 = "l4d2_fallindeath04";
		}
		case 17:
		{
			sName = "Farewell Chenming";
			m1 = "msd1_town";
			m2 = "msd2_gasstation";
			m3 = "msdnew_tccity_newway";
			m4 = "msd3_square";
		}
		case 18:
		{
			sName = "Fatal Freight";
			m1 = "l4d2_ff01_woods";
			m2 = "l4d2_ff02_factory";
			m3 = "l4d2_ff03_highway";
			m4 = "l4d2_ff04_plant";
			m5 = "l4d2_ff05_station";
		}
		case 19:
		{
			sName = "I Hate Mountains";
			m1 = "l4d_ihm01_forest";
			m2 = "l4d_ihm02_manor";
			m3 = "l4d_ihm03_underground";
			m4 = "l4d_ihm04_lumberyard";
			m5 = "l4d_ihm05_lakeside";
		}
		case 20:
		{
			sName = "Left Behind";
			m1 = "bhm1_outskirts";
			m2 = "bhm2_dam";
			m3 = "bhm3_station";
			m4 = "bhm4_base";
		}
		case 21:
		{
			sName = "Our Mutual Fiend";
			m1 = "omf_01";
			m2 = "omf_02";
			m3 = "omf_03";
		}
		case 22:
		{
			sName = "Plan B [Beta 0.51]";
			m1 = "l4d2_planb1_v051";
			m2 = "l4d2_planb2_v051";
			m3 = "l4d2_planb3_v051";
		}
		case 23:
		{
			sName = "Precinct 84";
			m1 = "p84m1_apartment";
			m2 = "p84m2_eltrain";
			m3 = "p84m3_tunnel";
			m4 = "p84m4_station";
		}
		case 24:
		{
			sName = "RedemptionII";
			m1 = "redemptionII-deadstop";
			m2 = "redemptionII-plantworks";
			m3 = "redemptionII-ceda-pt1";
			m4 = "redemptionii-ceda-pt2";
			m5 = "roundhouse";
		}
		case 25:
		{
			sName = "Suicide Blitz 2";
			m1 = "l4d2_stadium1_apartment";
			m2 = "l4d2_stadium2_riverwalk";
			m3 = "l4d2_stadium3_city1";
			m4 = "l4d2_stadium4_city2";
			m5 = "l4d2_stadium5_stadium";
		}
		case 26:
		{
			sName = "The Bloody Moors";
			m1 = "l4d_tbm_1";
			m2 = "l4d_tbm_2";
			m3 = "l4d_tbm_3";
			m4 = "l4d_tbm_4";
			m5 = "l4d_tbm_5";
		}
		case 27:
		{
			sName = "Tour of Terror";
			m1 = "eu01_residential_b16";
			m2 = "eu02_castle_b16";
			m3 = "eu03_oldtown_b16";
			m4 = "eu04_freeway_b16";
			m5 = "eu05_train_b16";
		}
		case 28:
		{
			sName = "Urban Flight";
			m1 = "uf1_boulevard";
			m2 = "uf2_rooftops";
			m3 = "uf3_harbor";
			m4 = "uf4_airfield";
		}
		case 29:
		{
			sName = "Vienna Calling 1";
			m1 = "l4d_viennacalling_city";
			m2 = "l4d_viennacalling_kaiserfranz";
			m3 = "l4d_viennacalling_gloomy";
			m4 = "l4d_viennacalling_donauinsel";
			m5 = "l4d_viennacalling_donauturm";
		}
		case 30:
		{
			sName = "Warcelona";
			m1 = "srocchurch";
			m2 = "plaza_espana";
			m3 = "maria_cristina";
			m4 = "mnac";
		}
		case 31:
		{
			sName = "We Don't Go To Ravenholm";
			m1 = "l4d2_ravenholmwar_1";
			m2 = "l4d2_ravenholmwar_2";
			m3 = "l4d2_ravenholmwar_3";
			m4 = "l4d2_ravenholmwar_4";
		}
		case 32:
		{
			sName = "Yama";
			m1 = "l4d_yama_1";
			m2 = "l4d_yama_2";
			m3 = "l4d_yama_3";
			m4 = "l4d_yama_4";
			m5 = "l4d_yama_5";
		}
		case 33:
		{
			sName = "Highway To Hell";
			m1 = "highway01_apt_20130613";
			m2 = "highway02_megamart_20130613";
			m3 = "highway03_hood01_20130614";
			m4 = "highway04_afb_a_02_20130616";
			m5 = "highway05_afb02_20130820";
		}
		case 34:
		{
			sName = "Vienna Calling 2";
			m1 = "l4d_viennacalling2_1";
			m2 = "l4d_viennacalling2_2";
			m3 = "l4d_viennacalling2_3";
			m4 = "l4d_viennacalling2_4";
			m5 = "l4d_viennacalling2_5";
			m6 = "l4d_viennacalling2_finale";
		}
		case 35:
		{
			sName = "Lockdown";
			m1 = "bt1";
			m2 = "bt2";
			m3 = "bt3";
			m4 = "bt4";
			m5 = "bt5";
		}
	}
	
	Menu menu = new Menu(CampaignHandler);
	menu.SetTitle("%s [Maps]", sName);
	Format(sBuffer, sizeof(sBuffer)-1, "Start > %s", m1);
	menu.AddItem("1", sBuffer);
	Format(sBuffer, sizeof(sBuffer)-1, "Map #2: %s", m2);
	menu.AddItem("2", sBuffer);
	if (maps > 2)
	{
		Format(sBuffer, sizeof(sBuffer)-1, "Map #3: %s", m3);
		menu.AddItem("3", sBuffer);
		if (maps > 3)
		{
			Format(sBuffer, sizeof(sBuffer)-1, "Map #4: %s", m4);
			menu.AddItem("4", sBuffer);
			if (maps > 4)
			{
				Format(sBuffer, sizeof(sBuffer)-1, "Map #5: %s", m5);
				menu.AddItem("5", sBuffer);
				if (maps > 6)
				{
					Format(sBuffer, sizeof(sBuffer)-1, "Map #6: %s", m6);
					menu.AddItem("6", sBuffer);
				}
			}
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, 30);
	return Plugin_Handled;
}

public Action CampaignSurvivalDLC(int client, int campaigns, int maps)
{
	switch (campaigns)
	{
		case 1:
		{
			sName = "Dark Wood (Extended)";
			m1 = "dw_final";
		}
		case 2:
		{
			sName = "Devil Mountain";
			m1 = "dm1_suburbs";
			m2 = "dm5_summit";
		}
		case 3:
		{
			sName = "Diescraper Redux";
			m1 = "l4d2_diescraper3_mid_361";
			m2 = "l4d2_diescraper4_top_361";
		}
		case 4:
		{
			sName = "Fall in Death";
			m1 = "l4d2_fallindeath02";
			m2 = "l4d2_fallindeath03";
		}
		case 5:
		{
			sName = "Farewell Chenming";
			m1 = "msd3_square";
		}
		case 6:
		{
			sName = "Fatal Freight";
			m1 = "l4d2_ff02_factory";
			m2 = "l4d2_ff03_highway";
			m3 = "l4d2_ff05_station";
		}
		case 7:
		{
			sName = "Left Behind";
			m1 = "bhm3_station";
		}
		case 8:
		{
			sName = "Precinct 84";
			m1 = "p84m1_apartments";
		}
		case 9:
		{
			sName = "Suicide Blitz 2";
			m1 = "l4d2_sv_stadium2_riverwalk";
			m2 = "l4d2_sv_stadium3_city1";
			m3 = "l4d2_sv_stadium4_city2";
		}
		case 10:
		{
			sName = "The Bloody Moors";
			m1 = "l4d_tbm_1";
			m2 = "l4d_tbm_2";
			m3 = "l4d_tbm_3";
			m4 = "l4d_tbm_4";
			m5 = "l4d_tbm_5";
		}
		case 11:
		{
			sName = "Tour of Terror";
			m1 = "sv_eu_park_b02";
			m2 = "sv_eu_castle_b01";
			m3 = "sv_eu_courtyard_b03";
			m4 = "sv_eu_freeway_b01";
		}
		case 12:
		{
			sName = "Urban Flight";
			m1 = "uf2_rooftops";
			m2 = "uf4_airfield";
		}
		case 13:
		{
			sName = "We Don't Go To Ravenholm 2";
			m1 = "l4d2_ravenholmwar_sv";
			m2 = "l4d2_ravenholmwar_4";
		}
		case 14:
		{
			sName = "Yama";
			m1 = "l4d_yama_1";
			m2 = "l4d_yama_3";
			m3 = "l4d_yama_5";
		}
	}
	
	Menu menu = new Menu(CampaignHandler);
	menu.SetTitle("%s [Maps]", sName);
	Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m1);
	menu.AddItem("1", sBuffer);
	if (maps > 1)
	{
		Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m2);
		menu.AddItem("2", sBuffer);
		if (maps > 2)
		{
			Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m3);
			menu.AddItem("3", sBuffer);
			if (maps > 3)
			{
				Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m4);
				menu.AddItem("4", sBuffer);
				if (maps > 4)
				{
					Format(sBuffer, sizeof(sBuffer)-1, "Map: %s", m5);
					menu.AddItem("5", sBuffer);
				}
			}
		}
	}
	menu.ExitBackButton = true;
	menu.ExitButton = false;
	menu.Display(client, 30);
	return Plugin_Handled;
}