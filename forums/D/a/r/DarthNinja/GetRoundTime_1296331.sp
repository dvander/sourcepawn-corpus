#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>


#define PLUGIN_VERSION "1.0.0"

new g_StartTime;
new g_AdditionalTime = 0;

public Plugin:myinfo = 
{
	name = "[DEV] Get Round Time Left",
	author = "DarthNinja",
	description = "This was a BITCH",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	CreateConVar("sm_roundtime_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_roundtime", Command_Debug);

	HookEvent("teamplay_setup_finished", EventSetupEnd);
	HookEvent("teamplay_timer_time_added", EventTimeAdded);
}

public Action:EventSetupEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_StartTime = GetTime()
	PrintToChatAll("RoundStart TimeStamp Logged: %i", g_StartTime)
	g_AdditionalTime = 0;
}

public Action:EventTimeAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAddedTime = GetEventInt(event, "seconds_added")
	g_AdditionalTime = g_AdditionalTime + iAddedTime;
	PrintToChatAll("Time added: %i", iAddedTime)
}


public Action:Command_Debug(client, args)
{
	PrintToChatAll("-----------------------------------------")
	
	//Alright bitch, play tiemz ovar
	new SecElapsed = GetTime() - g_StartTime;
	PrintToChatAll("%i Seconds have elapsed since the round started", SecElapsed)
	
	//Get round time that the round started with
	new ent = FindEntityByClassname(MaxClients+1, "team_round_timer");
	new Float:RoundStartLength = GetEntPropFloat(ent, Prop_Send, "m_flTimeRemaining");
	PrintToChatAll("Float:RoundStartLength == %f", RoundStartLength)
	new iRoundStartLength = RoundToZero(RoundStartLength)
	PrintToChatAll("Int:iRoundStartLength == %i", iRoundStartLength)
	
	
	//g_AdditionalTime = time added this round
	PrintToChatAll("TimeAdded This Round: %i", g_AdditionalTime)
	
	new TimeBuffer = iRoundStartLength + g_AdditionalTime;
	new TimeLeft = TimeBuffer - SecElapsed;
	PrintToChatAll("TimeLeft Sec: %i", TimeLeft)
	
	PrintToChatAll("TimeLeft Min: %i~", TimeLeft/60)
	
	new timeleftMIN = TimeLeft/60;
	new Sec = TimeLeft-(timeleftMIN*60)
	PrintToChatAll("<<EXACT TIME LEFT>> :: |||%i:%02i|||", TimeLeft/60,Sec)
	
	PrintToChatAll("-----------------------------------------")
	return Plugin_Handled;
}