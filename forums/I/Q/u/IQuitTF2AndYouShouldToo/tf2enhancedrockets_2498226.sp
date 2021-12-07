/**
 * =============================================================================
 * [TF2] Enhanced Rockets
 * Adds custom rocket models because Valve said they couldn't do it.
 * (And then went and did it with the Air Strike)
 * =============================================================================
 * Special Thanks To:
 *
 * Elbagast - Created models for the Direct Hit, Black Box, Rocket Jumper, Liberty Launcher and the Original
 * N-Cognito - Created models for everything else (big thanks!)
 * Benoist3012 - Model index overrides suggestion + many other helpful tips
 * nosoop - Australium weapon check
 *
 */
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks> // TF2 Stocks (+ TF2 & SDKTools)
#undef REQUIRE_PLUGIN
#include <tf2attributes> // Required for the Australium checks
#include <tf2items> // Required for the Test Rocket Launchers
#define REQUIRE_PLUGIN

#file "[TF2] Enhanced Rockets"

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "19w34a"

ConVar g_cvEnablePlugin;
ConVar g_cvEnableFestives;
ConVar g_cvEnableAustraliums;
ConVar g_cvEnableBotkillers;
ConVar g_cvEnableTCDirectHit;
ConVar g_cvEnableTCRocketJumper;

// Rocket model indices
int iRocketEnhanced = -1;
int iRocketFestive = -1;
int iRocketDirectHit = -1;
int iRocketBlackBox = -1;
int iRocketFestiveBlackBox = -1;
int iRocketRocketJumper = -1;
int iRocketLibertyLauncher = -1;
int iRocketOriginal = -1;
int iRocketBeggarsBazooka = -1;
int iRocketBKHeavy1 = -1;
int iRocketBKHeavy2 = -1;
int iRocketBKEngy = -1;

bool g_bTF2Attributes;

public Plugin myinfo =
{
	name = "[TF2] Enhanced Rockets 2",
	author = "404",
	description = "Custom rocket models for each rocket launcher!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public void OnPluginStart()
{
	CreateConVar("sm_er2_version", PLUGIN_VERSION, "TF2: Enhanced Rockets plugin version.", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_cvEnablePlugin = CreateConVar("sm_er2_enable", "1", "Enable Enhanced Rockets?", _, true, 0.0, true, 1.0);
	g_cvEnableFestives = CreateConVar("sm_er2_festives", "0", "Enable Festive Rockets?", _, true, 0.0, true, 1.0);
	g_cvEnableAustraliums = CreateConVar("sm_er2_australiums", "0", "Enable Australium Rockets?", _, true, 0.0, true, 1.0);
	g_cvEnableBotkillers = CreateConVar("sm_er2_botkillers", "0", "Enable Botkiller Rockets?", _, true, 0.0, true, 1.0);
	g_cvEnableTCDirectHit = CreateConVar("sm_er2_tcdirecthit", "0", "Enable team-colored Direct Hit rocket skins?", _, true, 0.0, true, 1.0);
	g_cvEnableTCRocketJumper = CreateConVar("sm_er2_tcrocketjumper", "0", "Enable BLU cream spirit team-colored Rocket Jumper rocket skin?", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "tf2enhancedrockets");

	RegAdminCmd("sm_er2rockets", Command_TestRockets, ADMFLAG_ROOT, "Use special rocket launchers to test if your rocket models are working.");
	RegAdminCmd("sm_er2settings", Command_Settings, ADMFLAG_ROOT, "Change ConVar settings.");

	g_bTF2Attributes = LibraryExists("tf2attributes");
}

// Thank you nosoop for your lovely custom Australium weapon check. Very useful!
public void OnAllPluginsLoaded()
{
	g_bTF2Attributes = LibraryExists("tf2attributes");
}
 
public void OnLibraryRemoved(const char[] strName)
{
	if(StrEqual(strName, "tf2attributes"))
	{
		g_bTF2Attributes = false;
	}
}
 
public void OnLibraryAdded(const char[] strName)
{
	if(StrEqual(strName, "tf2attributes"))
	{
		g_bTF2Attributes = true;
	}
}

public void OnMapStart()
{
	if(g_cvEnablePlugin.BoolValue == true)
	{
		// Stock Rocket Enhanced/Festive Stock Rocket - Models created by N-Cog
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_enhanced.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_enhanced.vtf");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_enhanced_gold.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_enhanced_gold.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_enhanced.vvd");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festive.vvd");

		// Direct Hit Rocket - Model created by Elbagast
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit.vtf");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit_blue.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit_blue.vtf");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit_red.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_directhit_red.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_directhit.vvd");
		
		// Black Box Rocket/Festive Black Box Rocket 
		// Normal model created by Elbagast - Festive model created by N-Cog
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_blackbox.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_blackbox.vtf");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_blackbox_gold.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_blackbox_gold.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_blackbox.vvd");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_festiveblackbox.vvd");
		
		// Rocket Jumper Rocket - Model created by Elbagast
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_rocketjumper.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_rocketjumper.vtf");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_rocketjumper_blue.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_rocketjumper_blue.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_rocketjumper.vvd");
		
		// Liberty Launcher Rocket - Model created by Elbagast
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_libertylauncher.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_libertylauncher.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_libertylauncher.vvd");
		
		// Original Rocket - Model created by Elbagast
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_original.vmt");
		AddFileToDownloadsTable("materials/models/enhancedrockets2/w_rocket_original.vtf");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_original.vvd");
		
		// Beggar's Bazooka Rocket - Model created by N-Cog
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_beggarsbazooka.vvd");
		
		// Botkiller v2 Rocket (Gold/Silver) - Model created by N-Cog
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkengy.vvd");

		// Botkiller v1 Rocket (Silver/Gold/Blood/Rust) - Model created by N-Cog
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy.vvd");

		// Botkiller v1 Rocket (Carbonado/Diamond) - Model created by N-Cog
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.dx80.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.dx90.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.mdl");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.phy");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.sw.vtx");
		AddFileToDownloadsTable("models/enhancedrockets2/w_rocket_bkheavy2.vvd");
		
		// Precache the models
		iRocketEnhanced = PrecacheModel("models/enhancedrockets2/w_rocket_enhanced.mdl", true);
		iRocketFestive = PrecacheModel("models/enhancedrockets2/w_rocket_festive.mdl", true);
		iRocketDirectHit = PrecacheModel("models/enhancedrockets2/w_rocket_directhit.mdl", true);
		iRocketBlackBox = PrecacheModel("models/enhancedrockets2/w_rocket_blackbox.mdl", true);
		iRocketFestiveBlackBox = PrecacheModel("models/enhancedrockets2/w_rocket_blackbox_festive.mdl", true);
		iRocketLibertyLauncher = PrecacheModel("models/enhancedrockets2/w_rocket_libertylauncher.mdl", true);
		iRocketOriginal	= PrecacheModel("models/enhancedrockets2/w_rocket_original.mdl", true);
		iRocketRocketJumper = PrecacheModel("models/enhancedrockets2/w_rocket_rocketjumper.mdl", true);
		iRocketBeggarsBazooka = PrecacheModel("models/enhancedrockets2/w_rocket_beggarsbazooka.mdl", true);
		iRocketBKHeavy1 = PrecacheModel("models/enhancedrockets2/w_rocket_bkheavy1.mdl", true);
		iRocketBKHeavy2 = PrecacheModel("models/enhancedrockets2/w_rocket_bkheavy2.mdl", true);
		iRocketBKEngy = PrecacheModel("models/enhancedrockets2/w_rocket_bkengy.mdl", true);
	}
}


public Action Command_Settings(int iClient, int iArgs)
{
	if (IsClientInGame(iClient))
	{
	//	char strMenuItemText[256];
		Menu hSettings = new Menu(MenuHandler_Settings, MENU_ACTIONS_ALL);
		hSettings.SetTitle("[ER2] ConVar Settings");
		hSettings.AddItem("#desc", "Select an entry below to toggle that ConVar's status.");

		if (g_cvEnablePlugin.BoolValue)
		{
			hSettings.AddItem("#plugin", "Plugin Status: Enabled");
		}
		else
		{
			hSettings.AddItem("#plugin", "Plugin Status: Disabled");
		}
		
		if (g_cvEnableFestives.BoolValue)
		{
			hSettings.AddItem("#festives", "Festive Rockets: Enabled");
		}
		else
		{
			hSettings.AddItem("#festives", "Festive Rockets: Disabled");
		}

		if (g_cvEnableAustraliums.BoolValue)
		{
			hSettings.AddItem("#australiums", "Australium Rockets: Enabled");
		}
		else
		{
			hSettings.AddItem("#australiums", "Australium Rockets: Disabled");
		}

		if (g_cvEnableBotkillers.BoolValue)
		{
			hSettings.AddItem("#botkillers", "Botkiller Rockets: Enabled");
		}
		else
		{
			hSettings.AddItem("#botkillers", "Botkiller Rockets: Disabled");
		}

		if (g_cvEnableTCDirectHit.BoolValue)
		{
			hSettings.AddItem("#tcdirecthit", "Team-Colored Direct Hit Rockets: Enabled");
		}
		else
		{
			hSettings.AddItem("#tcdirecthit", "Team-Colored Direct Hit Rockets: Disabled");
		}

		if (g_cvEnableTCRocketJumper.BoolValue)
		{
			hSettings.AddItem("#tcrocketjumper", "Team-Colored Rocket Jumper Rockets: Enabled");
		}
		else
		{
			hSettings.AddItem("#tcrocketjumper", "Team-Colored Rocket Jumper Rockets: Disabled");
		}

		hSettings.ExitButton = true;
		hSettings.Display(iClient, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

public int MenuHandler_Settings(Menu hSettings, MenuAction iAction, int iClient, int iParam2)
{
	char strInfo[32];
	int iStyle;
	hSettings.GetItem(iParam2, strInfo, sizeof(strInfo), iStyle);
	// Set up any disabled lines.
	if (iAction == MenuAction_DrawItem)
	{
		return StrEqual(strInfo, "#desc") ? ITEMDRAW_RAWLINE : iStyle;
	}
	else if (iAction == MenuAction_DisplayItem)
	{
		if (StrEqual(strInfo, "#botkillers"))
		{
			char strDisplay[64];
			Format(strDisplay, sizeof(strDisplay), "Botkiller Rockets: %s", g_cvEnableBotkillers.BoolValue ? "Enabled" : "Disabled");
			return RedrawMenuItem(strDisplay);
		}
	}
	else if (iAction == MenuAction_Select)
	{
		if (StrEqual(strInfo, "#desc"))
		{
			LogError("[ER2] Descriptive Entries: Player somehow selected option despite ITEMDRAW_RAWLINE. FIXME.");
		}
		else if (StrEqual(strInfo, "#plugin"))
		{
			g_cvEnablePlugin.BoolValue = !g_cvEnablePlugin.BoolValue;

			if (g_cvEnablePlugin.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Plugin has been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Plugin has been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#festives"))
		{
			g_cvEnableFestives.BoolValue = !g_cvEnableFestives.BoolValue;
			if (g_cvEnableFestives.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Festive Rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Festive Rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#australiums"))
		{
			g_cvEnableAustraliums.BoolValue = !g_cvEnableAustraliums.BoolValue;
			if (g_cvEnableAustraliums.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Australium Rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Australium Rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#botkillers"))
		{
			g_cvEnableBotkillers.BoolValue = !g_cvEnableBotkillers.BoolValue;
			if (g_cvEnableBotkillers.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Botkiller Rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Botkiller Rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#tcdirecthit"))
		{
			g_cvEnableTCDirectHit.BoolValue = !g_cvEnableTCDirectHit.BoolValue;
			if (g_cvEnableTCDirectHit.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Team-Colored Direct Hit rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Team-Colored Direct Hit rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#tcrocketjumper"))
		{
			g_cvEnableTCRocketJumper.BoolValue = !g_cvEnableTCRocketJumper.BoolValue;
			if (g_cvEnableTCRocketJumper.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Team-Colored Rocket Jumper rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Team-Colored Rocket Jumper rockets have been disabled.");
			}
		}
	}
	else if (iAction == MenuAction_Select)
	{
		if (StrEqual(strInfo, "#desc"))
		{
			LogError("[ER2] Descriptive Entries: Player somehow selected option despite ITEMDRAW_RAWLINE. FIXME.");
		}
		else if (StrEqual(strInfo, "#plugin"))
		{
			if (g_cvEnablePlugin.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Plugin has been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Plugin has been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#botkillers"))
		{
			if (g_cvEnableBotkillers.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Botkiller Rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Botkiller Rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#tcdirecthit"))
		{
			if (g_cvEnableTCDirectHit.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Team-Colored Direct Hit rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Team-Colored Direct Hit rockets have been disabled.");
			}
		}
		else if (StrEqual(strInfo, "#tcrocketjumper"))
		{
			if (g_cvEnableTCRocketJumper.BoolValue)
			{
				PrintToChat(iClient, "[ER2] Team-Colored Rocket Jumper rockets have been enabled.");
			}
			else
			{
				PrintToChat(iClient, "[ER2] Team-Colored Rocket Jumper rockets have been disabled.");
			}
		}
	}
	else if (iAction == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", iClient, iParam2);
	}
	else if (iAction == MenuAction_End)
	{
		delete hSettings;
	}
	return 0;
}

// Command: Test Rockets
public Action Command_TestRockets(int iClient, int iArgs)
{
	Menu hRocketMenu = new Menu(MenuHandler_RocketMenu);
	hRocketMenu.SetTitle("Select a Rocket Launcher:");
	hRocketMenu.AddItem("18", "Rocket Launcher");
	if (g_cvEnableFestives.BoolValue)
	{
		hRocketMenu.AddItem("658", "Festive Rocket Launcher");
	}
	if(g_cvEnableAustraliums.BoolValue && g_bTF2Attributes)
	{
		hRocketMenu.AddItem("18A", "Australium Rocket Launcher");
	}
	hRocketMenu.AddItem("127", "Direct Hit");
	hRocketMenu.AddItem("228", "Black Box");
	if (g_cvEnableFestives.BoolValue)
	{
		hRocketMenu.AddItem("1085", "Festive Black Box");
	}
	if(g_cvEnableAustraliums.BoolValue && g_bTF2Attributes)
	{
		hRocketMenu.AddItem("228A", "Australium Black Box");
	}
	hRocketMenu.AddItem("237", "Rocket Jumper");
	hRocketMenu.AddItem("414", "Liberty Launcher");
	hRocketMenu.AddItem("513", "Original");
	hRocketMenu.AddItem("730", "Beggar's Bazooka");

	if(g_cvEnableBotkillers.BoolValue)
	{
		hRocketMenu.AddItem("800", "Silver Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("809", "Gold Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("889", "Rust Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("898", "Blood Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("907", "Carbonado Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("916", "Diamond Botkiller Rocket Launcher Mk.I");
		hRocketMenu.AddItem("965", "Silver Botkiller Rocket Launcher Mk.II");
		hRocketMenu.AddItem("974", "Gold Botkiller Rocket Launcher Mk.II");
	}
	hRocketMenu.ExitBackButton = true;
	hRocketMenu.Display(iClient, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler_RocketMenu(Menu hRocketMenu, MenuAction iAction, int iClient, int iParam2)
{
	// Set up any disabled lines.
	if (iAction == MenuAction_DrawItem)
	{
		int iStyle;
		char strInfo[32];
		hRocketMenu.GetItem(iParam2, strInfo, sizeof(strInfo), iStyle);

		if (StrEqual(strInfo, "18A") || StrEqual(strInfo, "228A"))
		{
			// Australium handling
			return g_bTF2Attributes ? iStyle : ITEMDRAW_DISABLED;
		}
		else if (StrEqual(strInfo, "800") || StrEqual(strInfo, "809") || 
				StrEqual(strInfo, "889") || StrEqual(strInfo, "898") || 
				StrEqual(strInfo, "907") || StrEqual(strInfo, "916") || 
				StrEqual(strInfo, "965") || StrEqual(strInfo, "974"))
		{
			// Botkiller handling
			return g_cvEnableBotkillers.BoolValue ? iStyle : ITEMDRAW_DISABLED;
		}
		else
		{
			return iStyle;
		}
	}
	else if (iAction == MenuAction_Select)
	{
		char strInfo[32];
		hRocketMenu.GetItem(iParam2, strInfo, sizeof(strInfo));
		int iInfo = StringToInt(strInfo);
		int iFlags = 0;
		Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);

		TF2Items_SetLevel(hWeapon, 100);
		iFlags |= OVERRIDE_ITEM_LEVEL;

		TF2Items_SetQuality(hWeapon, 8);
		iFlags |= OVERRIDE_ITEM_QUALITY;

		TF2Items_SetClassname(hWeapon, "tf_weapon_rocketlauncher");

		TF2Items_SetFlags(hWeapon, iFlags);

		if (StrEqual(strInfo, "#desc"))
		{
			LogError("[ER2] Descriptive Entries: Player somehow selected option despite ITEMDRAW_RAWLINE. FIXME.");
		}
		else if (StrEqual(strInfo, "18A") || StrEqual(strInfo, "228A"))
		{
			if (StrEqual(strInfo, "18A"))
			{
				TF2Items_SetItemIndex(hWeapon, 18);
			}
			else if (StrEqual(strInfo, "228A"))
			{
				TF2Items_SetItemIndex(hWeapon, 228);
			}

			TF2Items_SetNumAttributes(hWeapon, 4);
			TF2Items_SetAttribute(hWeapon, 0, 104, 0.0001);
			TF2Items_SetAttribute(hWeapon, 1, 2027, 1.0);
			TF2Items_SetAttribute(hWeapon, 2, 2022, 1.0);
			TF2Items_SetAttribute(hWeapon, 3, 542, 1.0);
		}
		else
		{
			TF2Items_SetItemIndex(hWeapon, iInfo);
			TF2Items_SetNumAttributes(hWeapon, 1);
			TF2Items_SetAttribute(hWeapon, 0, 104, 0.0001);
		}
		TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Primary);
		int iNewWeapon = TF2Items_GiveNamedItem(iClient, hWeapon);

		if (IsValidEntity(iNewWeapon))
		{
			EquipPlayerWeapon(iClient, iNewWeapon);
		}

		delete hWeapon;
		delete hRocketMenu;
	}
	else if (iAction == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", iClient, iParam2);
	}
	else if (iAction == MenuAction_End)
	{
		delete hRocketMenu;
	}
	return 0;
}


public void OnEntityCreated(int iEntity, const char[] strClassname)
{
	if(g_cvEnablePlugin.BoolValue == true)
	{
		if(StrEqual(strClassname, "tf_projectile_rocket"))
		{
			SDKHook(iEntity, SDKHook_SpawnPost, Projectile_RocketSpawnPost);
		}
	}
}

public void Projectile_RocketSpawnPost(int iRocket)
{
	if(IsValidEntity(iRocket) /* && iClient > 0 */)
	{
		int iClient = GetEntPropEnt(iRocket, Prop_Data, "m_hOwnerEntity");
		int iWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
		int iWeaponId = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
		if(iWeapon && IsValidEdict(iWeapon))
		{
			switch(iWeaponId)
			{
				// Stock Rocket Launcher, Renamed/Strange Stock Rocket Launcher
				case 18, 205:
				{
					SetRocketModel(iRocket, iRocketEnhanced);

					if (g_cvEnableAustraliums.BoolValue && TF2_IsWeaponAustralium(iWeapon))
					{
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 1);
					}

					SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
				}
				// Festive Rocket Launcher
				case 658: 
				{
					if (g_cvEnableFestives.BoolValue)
					{
						SetRocketModel(iRocket, iRocketFestive);

						// 2 = RED, 3 = BLU
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient)-2);
					}
					else
					{
						SetRocketModel(iRocket, iRocketEnhanced);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
					}
				}
				// All the various "Decorated" Rocket Launchers.
				case 15006, 15014, 15028, 15043, 15052, 15057, 15081, 15104, 15015, 15129, 15130, 15150: 
				{
					SetRocketModel(iRocket, iRocketEnhanced);
					SetEntProp(iRocket, Prop_Send, "m_nSkin", 0); // 0 - Normal
				}
				// Direct Hit
				case 127: 
				{
					SetRocketModel(iRocket, iRocketDirectHit);
					// 8 - Non-Teamcolored, 9 - RED, 10 - BLU
					SetEntProp(iRocket, Prop_Send, "m_nSkin", (g_cvEnableTCDirectHit.BoolValue ? 0 : GetClientTeam(iClient)-2));
				}
				// Black Box
				case 228: 
				{
					SetRocketModel(iRocket, iRocketBlackBox);
					// 4 - Normal, 5 - Australium
					if (g_cvEnableAustraliums.BoolValue && TF2_IsWeaponAustralium(iWeapon))
					{
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 1);
					}
					else
					{
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
					}
				}
				// Festive Black Box
				case 1085: 
				{
					if (g_cvEnableFestives.BoolValue)
					{
						SetRocketModel(iRocket, iRocketFestiveBlackBox);
						// 6 - RED, 7 - BLU
						SetEntProp(iRocket, Prop_Send, "m_nSkin", (GetClientTeam(iClient)-2));
					}
					else
					{
						SetRocketModel(iRocket, iRocketBlackBox);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
					}
				}
				// Rocket Jumper
				case 237: 
				{
					SetRocketModel(iRocket, iRocketRocketJumper);
					// 13 - Non-Teamcolored, 14 - Optional BLU
					SetEntProp(iRocket, Prop_Send, "m_nSkin", (g_cvEnableTCRocketJumper.BoolValue ? 0 : GetClientTeam(iClient)-2));
				}
				// Liberty Launcher
				case 414: 
				{
					SetRocketModel(iRocket, iRocketLibertyLauncher);
					SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
				}
				// The Original
				case 513: 
				{
					SetRocketModel(iRocket, iRocketOriginal);
					SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
				}
				// Beggar's Bazooka
				case 730: 
				{
					SetRocketModel(iRocket, iRocketBeggarsBazooka);
					SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
				}
				// Air Strike
				case 1104: 
				{
					/* Do nothing */
				}
			}
			if(g_cvEnableBotkillers.BoolValue == true)
			{
				switch(iWeaponId)
				{
					// Silver Botkiller Rocket Launcher Mk.I
					case 800: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy1);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient)-2);
					}
					// Gold Botkiller Rocket Launcher Mk.I
					case 809: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy1);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient));
					}
					// Rust Botkiller Rocket Launcher Mk.I
					case 889: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy1);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient)+2);
					}
					// Blood Botkiller Rocket Launcher Mk.I
					case 898: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy1);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient)+4);
					}
					// Carbonado Botkiller Rocket Launcher Mk.I
					case 907: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy2);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 0);
					}
					// Diamond Botkiller Rocket Launcher Mk.I
					case 916: 
					{
						SetRocketModel(iRocket, iRocketBKHeavy2);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", 1);
					}
					// Silver Botkiller Rocket Launcher Mk.II
					case 965: 
					{
						SetRocketModel(iRocket, iRocketBKEngy);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient)-2);
					}
					// Gold Botkiller Rocket Launcher Mk.II
					case 974: 
					{
						SetRocketModel(iRocket, iRocketBKEngy);
						SetEntProp(iRocket, Prop_Send, "m_nSkin", GetClientTeam(iClient));
					}
				}
			}
		}
	}
}

// Thanks Benoist3012 for the tip about using m_nModelIndexOverrides!
void SetRocketModel(int iRocket, int iModelIndex = 0)
{
	if(!HasEntProp(iRocket, Prop_Send, "m_nModelIndexOverrides"))
	{
		PrintToServer("[ER2] Missing prop \"m_nModelIndexOverrides\" on entity %d", iRocket);
	}
	// Set the model index overrides for all four vision types
	for(int i = 0; i < 4; i++)
	{
		SetEntProp(iRocket, Prop_Send, "m_nModelIndexOverrides", iModelIndex, _, i);
	}
}

// Australium weapon check.
bool TF2_IsWeaponAustralium(int iWeapon)
{
	// If TF2Attributes doesn't exist, that's too bad.
	if(g_bTF2Attributes)
	{
		if(TF2Attrib_GetByName(iWeapon, "is australium item") != Address_Null)
		{
			return true;
		}
		else
		{
			// item server-specific value? uhhhhhh
			int iAttribIndices[16];
			float fAttribValues[16];
			
			int iAttribs = TF2Attrib_GetSOCAttribs(iWeapon, iAttribIndices, fAttribValues);
			
			for(int i = 0; i < iAttribs; i++)
			{
				if(iAttribIndices[i] == 2027)
				{
					return true;
				}
			}
		}
	}
	return false;
}