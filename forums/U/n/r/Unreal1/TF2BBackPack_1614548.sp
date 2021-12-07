#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

// Global Definitions
#define PLUGIN_VERSION "2.0"

new Handle:g_PluginVersion;
new Handle:g_Adverts;
new Handle:g_Adtime;
new Handle:g_Adtimer;
new Float:g_AdvertTime;

public Plugin:myinfo =
{
    name = "TF2B backpack",
    author = "Munra, bottiger, modded by unreal1",
    description = "Opens MOTD with clients TF2B.com backpack",
    version = PLUGIN_VERSION,
    url = "http://anbservers.net and unrealserver.info"
}
public OnPluginStart()
{
	//Create Cvars
	g_PluginVersion = CreateConVar("motdbp_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
	g_Adverts = CreateConVar("motdbp_advert", "0", "Enable or disable plugin adverts", 0, true, 0.0, true, 1.0);
	g_Adtime = CreateConVar("motdbp_adtime", "60", "Length of time between adverts", 0, true, 5.0, true, 600.0);
	
	RegConsoleCmd("sm_backpack", bakpak, "Aim at someone and type !backpack or !backpack [playername]");
	RegConsoleCmd("sm_bp", bakpak, "Aim at someone and type !bp or !bp [playername]");
	LoadTranslations("common.phrases");
	
	//Advert timer
	g_AdvertTime = GetConVarFloat(g_Adtime);
	StartTimer();
	
	HookConVarChange(g_Adverts, OnAdvertsChange);
	HookConVarChange(g_Adtime, OnAdtimeChange);
}

public OnMapStart()
{
	// hax against valve fail Thanks psychonic 
	if (GuessSDKVersion() == SOURCE_SDK_EPISODE2VALVE)
		SetConVarString(g_PluginVersion, PLUGIN_VERSION);
}

StartTimer()
{
	g_Adtimer = CreateTimer (g_AdvertTime, Adverttimer, _, TIMER_REPEAT);
}

//Displays given player's backpack
public Action:bakpak(client, args) {
	if (client == 0)
		ReplyToCommand(client, "%s", "TF2B: Can't do command from console");
	
	if (args == 0)
	{
		DisplayBackpackMenu(client);
		return Plugin_Handled;
	}
	
	//Gets target client
	new target;
	decl String:argstring[128];
	GetCmdArgString(argstring, sizeof(argstring));
	target = FindTarget(client, argstring, true, false);
	
	if (target == -1) 
	{
	DisplayBackpackMenu(client);
	return Plugin_Handled;
    	}
	DisplayBackpack(client, target);
	return Plugin_Handled;
}

DisplayBackpackMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Backpack);
	SetMenuTitle(menu, "Choose a player");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu(menu, 0, true, false);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Backpack(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:info[32];
			new userid, target;
			
			GetMenuItem(menu, param2, info, sizeof(info));
			userid = StringToInt(info);

			if ((target = GetClientOfUserId(userid)) == 0)
			{
				PrintToChat(param1, "%t", "Player no longer available");
			}
			else
			{
				DisplayBackpack(param1, target);
			}
		}
	}
}

public DisplayBackpack(client, target) {
    decl String:communityid[32];
    decl String:itemsurl[128];

    GetClientAuthString(target, communityid, sizeof(communityid));
    Format(itemsurl, sizeof(itemsurl), "http://www.tf2b.com/?id=%s", communityid);
    ShowMOTDPanel(client, "Backpack", itemsurl, MOTDPANEL_TYPE_URL);
}

//Timer for adverts
public Action:Adverttimer(Handle:timer)
{
	PrintToChatAll("\x03 Aim at someone and type !bp or !backpack [playername]");
	return Plugin_Continue;
}

public OnAdvertsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:adsOn = (StringToInt(newValue)!=0);
	if (adsOn && g_Adtimer == INVALID_HANDLE)
	{
		StartTimer();
	}
	else if (!adsOn && g_Adtimer != INVALID_HANDLE)
	{
		KillTimer(g_Adtimer);
		g_Adtimer = INVALID_HANDLE;
	}
}

public OnAdtimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_AdvertTime = StringToFloat(newValue);
	
	if (GetConVarBool(g_Adverts))
	{
		if (g_Adtimer != INVALID_HANDLE)
		{
			KillTimer(g_Adtimer);
		}
		StartTimer();
	}
}