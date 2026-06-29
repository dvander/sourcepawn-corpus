#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.0"

float g_fVoteUnlock_Countdown [MAXPLAYERS+1];

ConVar g_Cvar_VoteBlocker_Enable;
ConVar g_Cvar_VoteBlocker_Timers;

public void OnPluginStart()
{
	CreateConVar ("l4d_voteblocker_timer", PLUGIN_VERSION, "L4D VoteBlocker Timer" ,FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_Cvar_VoteBlocker_Enable = CreateConVar("l4d_voteblocker_enable", "1", "0 = Plugin Disable, 1 = Enable With Timer, 2 = Enable With Permenant Block", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_Cvar_VoteBlocker_Timers = CreateConVar("l4d_voteblocker_timers", "60.0", "How Long You Want To Block Call Votes After A Player Connects (In Seconds)", FCVAR_NOTIFY);
	AutoExecConfig (true, "L4D_VoteBlocker_Timer");
	
	HookEvent("player_connect_full", Event_PlayerConnected);
	AddCommandListener(Command_CallVote_Block, "callvote"); 
}

public void Event_PlayerConnected(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client) || IsFakeClient(client) || GetConVarInt(g_Cvar_VoteBlocker_Enable) != 1) return;
	
	g_fVoteUnlock_Countdown[client] = g_Cvar_VoteBlocker_Timers.FloatValue;
	CreateTimer(1.0, Timer_CallVote_Countdown, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public Action Timer_CallVote_Countdown(Handle timer, int client)
{
	int timeleft = RoundToNearest(g_fVoteUnlock_Countdown[client]--);
	if (timeleft > 0) return Plugin_Continue;
	else return Plugin_Stop;
}

public Action Command_CallVote_Block(int client, char [] command, int args)
{
	int timeleft = RoundToNearest(g_fVoteUnlock_Countdown[client]);
	if (timeleft > 0 && GetConVarInt(g_Cvar_VoteBlocker_Enable) == 1)
	{
		PrintToChat(client, "\x04[Vote Blocker] \x01Please wait: \x05%d Seconds", timeleft);
		return Plugin_Handled;
	}
	else if(GetConVarInt(g_Cvar_VoteBlocker_Enable) == 2)
	{
		PrintToChat(client, "\x04[Vote Blocker] \x01This feature is \x05permenantly blocked\x01.");
		return Plugin_Handled;
	}
	else return Plugin_Continue;
}