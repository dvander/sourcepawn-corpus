#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.5.1"

new g_smack_clients;
new g_Roundstarts;
new Handle:g_Cvar_AllTalk;
new Handle:g_Cvar_extendalltalk;
new Handle:g_Cvar_smackwarntime;
new Handle:g_Cvar_waitroundalltalk;
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
   //Cvar to enable/disable Wait round alltalk
   g_Cvar_waitroundalltalk = CreateConVar("sm_waitroundalltalk", "1", "Enable/Disable alltalk during the Waiting for players round", FCVAR_NOTIFY, true, 0.0, true, 1.0);
  
  //Cvar to extend alltalk after roundstart
   g_Cvar_extendalltalk = CreateConVar("sm_extendalltalk", "15", "The amount of time in seconds to extend alltalk after Round Start", FCVAR_NOTIFY, true, 0.0, true, 60.0);
   
   //Cvar to give warning in X seconds that alltalk is turning off
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
   g_Roundstarts = 0;
   
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
		g_Roundstarts = 0;
	}
}

stock GetNoBotClientCount()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++) if (IsClientInGame(i) && !IsFakeClient(i)) count++; return count;
}

// Timer to turn off alltalk on roundstart
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
   if (g_Roundstarts == 0&&GetConVarFloat(g_Cvar_waitroundalltalk))
   {
		g_Roundstarts++;
		AllTalkToggle(true);
		PrintToChatAll("\x04Waiting For Players SmackTalk On");
		
   }
   else if(g_Roundstarts == 1)
   {
		g_Roundstarts++;
		AllTalkToggle(false);
		PrintToChatAll("\x04Waiting For Players SmackTalk Off");
	}
   else if (!g_AllTalk)
   {
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
   }
}

//Turning off alltalk
public Action:extendalltalk(Handle:timer)
{
	AllTalkToggle(false);
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
	if (flags & FCVAR_NOTIFY)
		SetConVarFlags(g_Cvar_AllTalk, flags & ~FCVAR_NOTIFY);

	SetConVarBool(g_Cvar_AllTalk, on);
	
	// Restore the flags
	SetConVarFlags(g_Cvar_AllTalk, flags);
}