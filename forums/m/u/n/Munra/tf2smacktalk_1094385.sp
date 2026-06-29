#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Global Definitions
#define PLUGIN_VERSION "2.0.0"

new g_smack_clients;
new g_WaitRound;
new Handle:g_Cvar_AllTalk;
new Handle:g_Cvar_extendalltalk;
new Handle:g_Cvar_smackwarntime;
new Handle:g_Cvar_waitroundalltalk;
new Handle:g_Cvar_smackcvarsuppress;
new bool:g_AllTalk;
new Float:g_Warntime;

public Plugin:myinfo =
{
	name = "Round-End Smack talk/Alltalk",
	author = "Munra",
	description = "Toggles alltalk at roundend/roundstart",
	version = PLUGIN_VERSION,
	url = "http://anbservers.net"
}

public OnPluginStart()
{
	//Autocreate.cfg
	AutoExecConfig(true,"plugin.tf2smacktalk","sourcemod");
	
	//Plugin version cvar
	CreateConVar("tf2smacktalk_version", PLUGIN_VERSION, "SmackTalk Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
        
	//Cvar to enable/disable Wait round alltalk
	g_Cvar_waitroundalltalk = CreateConVar("sm_waitroundalltalk", "1", "Enable/Disable alltalk during the Waiting for players round, 1 = ON 0 = OFF", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//Cvar to suppress alltalk has changed messages
	g_Cvar_smackcvarsuppress = CreateConVar("sm_smackcvarsuppress", "1", "Enable/Disable suppression of the server cvar sv_alltalk has changed messages, 1 = ON 0 = OFF", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	//Cvar to extend alltalk after roundstart
	g_Cvar_extendalltalk = CreateConVar("sm_extendalltalk", "15", "The amount of time in seconds to extend alltalk after round start", FCVAR_NOTIFY, true, 0.0, true, 60.0);
  
	//Cvar to give warning in X seconds when alltalk is turning off
	g_Cvar_smackwarntime = CreateConVar("sm_smackwarntime", "5", "Set the time befor alltalk is turned off to print a warning", FCVAR_NOTIFY, true, 0.0, true, 59.0);
  
	//Hook the events
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_round_win", Event_RoundEnd); 

	g_Cvar_AllTalk = FindConVar("sv_alltalk");
	if (g_Cvar_AllTalk == INVALID_HANDLE)
	{
		SetFailState("Unable to find convar: sv_alltalk");
	}
}

public OnMapStart()
{
	//Math for the timer to broadcast the message
	g_Warntime = GetConVarFloat(g_Cvar_extendalltalk) - GetConVarFloat(g_Cvar_smackwarntime);
	g_WaitRound = 0;
	if (g_Warntime < 0.0)
	{
		g_Warntime = 0.0;
	}
}

public OnClientDisconnect_Post()
{
	g_smack_clients = GetNoBotClientCount();
	if (g_smack_clients == 0)
	{
		SetConVarBool(g_Cvar_AllTalk, false);
	}
}

stock GetNoBotClientCount()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
		count++;
		}
	}
	return count;
}	

public TF2_OnWaitingForPlayersStart()
{
	if (GetConVarBool(g_Cvar_waitroundalltalk))
	{
		AllTalkToggle(true);
		PrintToChatAll("\x04Waiting For Players SmackTalk Enabled");
	}
	else
	{
		g_WaitRound++;
	}
}       

// Timer to turn off alltalk on roundstart
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
	{
		return;
	}
	
	if (g_WaitRound != 0 && GameRules_GetProp("m_bInSetup"))
	{
		g_WaitRound = 0;
		return;
	}
	else if (!g_AllTalk && g_WaitRound == 0)
	{
		//PrintToChatAll("fuck off 3");
		CreateTimer (g_Warntime, printmessage);
		CreateTimer(GetConVarFloat(g_Cvar_extendalltalk), extendalltalk);
	}
}

// Turns alltalk on at on roundend or ignores alltalk if its set to true before roundend.
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{  
   g_AllTalk = GetConVarBool(g_Cvar_AllTalk);
   if(!g_AllTalk)
   {
		AllTalkToggle(true);
		PrintToChatAll("\x04SmackTalk Enabled");
   }
}

//Turning off alltalk
public Action:extendalltalk(Handle:timer)
{
	AllTalkToggle(false);
	PrintToChatAll("\x04SmackTalk Disabled");
}

// Prints how much alltalk time is left
public Action:printmessage(Handle:timer)
{
	if (GetConVarFloat(g_Cvar_smackwarntime) == 0.0||GetConVarFloat(g_Cvar_smackwarntime) >= GetConVarFloat(g_Cvar_extendalltalk))
	{
		return;
	}
	else
	{
		PrintToChatAll("\x03SmackTalk will turn off in \"%.0f\" seconds", GetConVarFloat(g_Cvar_smackwarntime));
	}
}

stock AllTalkToggle(bool:on) 
{
	new flags = GetConVarFlags(g_Cvar_AllTalk);
        
	// Remove the notify flag if needed
	if (GetConVarBool(g_Cvar_smackcvarsuppress))
	{
		if (flags & FCVAR_NOTIFY)
		{
			SetConVarFlags(g_Cvar_AllTalk, flags & ~FCVAR_NOTIFY);
		}
		SetConVarBool(g_Cvar_AllTalk, on);
		// Restore the flags
		SetConVarFlags(g_Cvar_AllTalk, flags);
	}
	else
	{	
		SetConVarBool(g_Cvar_AllTalk, on);
	}
}
