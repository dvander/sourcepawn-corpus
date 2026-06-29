#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "4.0"

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Spray Blocker",
	description = "Blocks all client sprays with chat command",
	author = "Mystik Spiral + edit by Sunyata",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332342"
}

bool g_SprayBlockEnabled = false;
bool g_HookAdded = false;

public void OnPluginStart()
{
	CreateConVar("sprayblock_version", PLUGIN_VERSION, "Blocks client sprays", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("togglespray", DisableAllPlayerSpraysNoWarningMessage, ADMFLAG_GENERIC, "Brings up a menu of players/bots for teleporting"); // this one does not print wrning message
	RegConsoleCmd("!togglespray", DisableAllPlayerSprays); //member only chat command is "/!togglespray" - but this one also prints warnig message to offender
	AddTempEntHook("Player Decal", SprayBlock);
	g_HookAdded = true;
	//HookEvent("round_start", Event_Round, EventHookMode_Pre);
	HookEvent("map_transition", Event_Round, EventHookMode_Pre);
	
	SetConVarInt(FindConVar("decalfrequency"), 20); //set respray time value for every 20 seconds - default is 10 seconds in vanilla game
}
 
//disable sprays for all players in map until next map starts - - with warning message
public Action DisableAllPlayerSprays(int client, int args)
{
	if (g_SprayBlockEnabled)
	{
		if (g_HookAdded)
		{
			RemoveTempEntHook("Player Decal", SprayBlock);
			g_HookAdded = false;
		}
		g_SprayBlockEnabled = false;
		//PrintToChatAll("*\x04 ALL PLAYER SPRAYS ON");
	}
	else
	{
		if (!g_HookAdded)
		{
			AddTempEntHook("Player Decal", SprayBlock);
			g_HookAdded = true;
		}
		g_SprayBlockEnabled = true;
		//PrintToChatAll("*\x04 ALL PLAYER SPRAYS OFF");
		CreateTimer(2.0, Timer_PrintMessageFiveTimes, client, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

//disable sprays for all players in map until next map starts - no warning message
public Action DisableAllPlayerSpraysNoWarningMessage(int client, int args)
{
	if (g_SprayBlockEnabled)
	{
		if (g_HookAdded)
		{
			RemoveTempEntHook("Player Decal", SprayBlock);
			g_HookAdded = false;
		}
		g_SprayBlockEnabled = false;
		PrintToChat(client, "*\x04 [Admin info] Player sprays ON");
	}
	else
	{
		if (!g_HookAdded)
		{
			AddTempEntHook("Player Decal", SprayBlock);
			g_HookAdded = true;
		}
		g_SprayBlockEnabled = true;
		PrintToChat(client, "*\x04 [Admin info] Player sprays OFF");
	}
	return Plugin_Handled;
}
 
public Action SprayBlock(const char[] name, const int[] Players, int numClients, float delay)
{
	if (g_SprayBlockEnabled)
	{
		return Plugin_Stop;
	}
	else
	{
		return Plugin_Continue;
	}
}

//re-enable sprays for all players on new map
public void Event_Round(Event event, const char[] name, bool dontBroadcast)
{
	if (g_HookAdded)
	{
		RemoveTempEntHook("Player Decal", SprayBlock);
		g_HookAdded = false;
		g_SprayBlockEnabled = false;
	}
	//PrintToChatAll("*\x04 TEST Sprays re-enabled"); 
}

public Action Timer_PrintMessageFiveTimes(Handle timer, any client)
{
    static int numPrinted = 0;
    if (numPrinted >= 3) 
	{
        numPrinted = 0;
        return Plugin_Stop;
    }
    PrintHintTextToAll("All player SPRAYS are temporarily DISABLED");
    PrintToChatAll("* \x03Don't use offensive SPRAYS. Avoid being kicked from game.");
    numPrinted++;
    return Plugin_Continue;
}
