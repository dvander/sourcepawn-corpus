#pragma semicolon 1

//Includes
#include <sourcemod>
#include <sdktools>
#include <adminmenu>

// Global Definitions
#define PLUGIN_VERSION "2.0"

new Handle:g_Adverts;
new Handle:g_AdInterval;
new Handle:g_AdTimer;
new Handle:g_Fullscreen;
new Handle:g_CustomAd;
new Float:g_AdvertTime;
new String:g_Message[128];

public Plugin:myinfo =
{
	//Thanks to 11530 http://forums.alliedmods.net/member.php?u=153725 for fixes to the code
    name = "TF2 OutPost Trades",
    author = "Munra",
    description = "Opens MOTD with clients TF2OutPost.com Trades",
    version = PLUGIN_VERSION,
    url = "http://anbservers.net"
}
public OnPluginStart()
{
	//Create Cvars
	CreateConVar("outpost_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Adverts = CreateConVar("outpost_advert", "0", "Enable or disable plugin adverts", 0, true, 0.0, true, 1.0);
	g_AdInterval = CreateConVar("outpost_adtime", "300", "Number of seconds between adverts", 0, true, 5.0, true, 900.0);
	g_Fullscreen = CreateConVar("outpost_fullscreen", "1", "Enable or disable fullscreen windows", 0, true, 0.0, true, 1.0);
	g_CustomAd = CreateConVar("outpost_message", "View a players TF2OutPost trades by typing !op or !op [playername]", "Set a custom advert message");
		
	RegAdminCmd("sm_outpost", outpost, 0, "View TF2OutPost Trades by typing !outpost or !outpost [playername]");
	RegAdminCmd("sm_op", outpost, 0, "View TF2OutPost Trades by typing !op or !op [playername]");
	LoadTranslations("common.phrases");
	
	GetConVarString(g_CustomAd, g_Message, sizeof(g_Message));
	
	//Advert timer
	g_AdvertTime = GetConVarFloat(g_AdInterval);
	if (GetConVarBool(g_Adverts))
	{
		StartTimer();
	}
	
	HookConVarChange(g_Adverts, OnAdvertsChange);
	HookConVarChange(g_AdInterval, OnAdtimeChange);
	HookConVarChange(g_CustomAd, OnMessageChange);
	AutoExecConfig(true,"plugin.motd.outpost","sourcemod");
}

StartTimer()
{
	g_AdTimer = CreateTimer(g_AdvertTime, AdvertTimer, _, TIMER_REPEAT);
}

//Displays given player's OutPost Trades
public Action:outpost(client, args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Cannot use command from RCON");
		return Plugin_Handled;
	}
	if (args == 0)
	{
		DisplayOutPostMenu(client);
		return Plugin_Handled;
	}
	
	//Gets target client
	new target;
	decl String:argstring[128];
	GetCmdArgString(argstring, sizeof(argstring));
	StripQuotes(argstring);
	target = FindTarget(client, argstring, true, false);
	
	if (target == -1) 
	{
		DisplayOutPostMenu(client);
		return Plugin_Handled;
	}
	DisplayOutPost(client, target);
	return Plugin_Handled;
}

DisplayOutPostMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_OutPost);
	SetMenuTitle(menu, "Choose a player");
	SetMenuExitBackButton(menu, true);
	
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_OutPost(Handle:menu, MenuAction:action, param1, param2)
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
				PrintToChat(param1, "[SM] %t", "Player no longer available");
			}
			else
			{
				DisplayOutPost(param1, target);
			}
		}
	}
}

public DisplayOutPost(client, target)
{
 	decl String:steamid[32];
	decl String:itemsurl[128];
	
	GetClientAuthString(target, steamid, sizeof(steamid));
	Format(itemsurl, sizeof(itemsurl), "http://www.tf2outpost.com/user/%s", steamid);
	
	new Handle:Kv = CreateKeyValues("motd");
	KvSetString(Kv, "title", "TF2OutPost Trades");
	KvSetNum(Kv, "type", MOTDPANEL_TYPE_URL);
	KvSetString(Kv, "msg", itemsurl);
	if (GetConVarBool(g_Fullscreen))
	{
		KvSetNum(Kv, "customsvr", 1);
	}

	ShowVGUIPanel(client, "info", Kv);
	CloseHandle(Kv);

}

//Timer for adverts
public Action:AdvertTimer(Handle:timer)
{
	PrintToChatAll("\x03%s", g_Message);
	return Plugin_Continue;
}

public OnAdvertsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:adsOn = (StringToInt(newValue)!=0);
	if (adsOn && g_AdTimer == INVALID_HANDLE)
	{
		StartTimer();
	}
	else if (!adsOn && g_AdTimer != INVALID_HANDLE)
	{
		KillTimer(g_AdTimer);
		g_AdTimer = INVALID_HANDLE;
	}
}

public OnAdtimeChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_AdvertTime = StringToFloat(newValue);
	
	if (GetConVarBool(g_Adverts))
	{
		if (g_AdTimer != INVALID_HANDLE)
		{
			KillTimer(g_AdTimer);
			g_AdTimer = INVALID_HANDLE;
		}
		StartTimer();
	}
}

public OnMessageChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_Message, sizeof(g_Message), newValue);
}