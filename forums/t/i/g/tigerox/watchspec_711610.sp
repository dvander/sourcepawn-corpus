/*
 *
 *	WatchSpec
 *
 *		Nicolous
 */

#include <sourcemod>

#define __VERSION__ "1.1ox" 

public Plugin:myinfo = 
{
	name = "WatchSpec",
	author = "Nicolous",
	description = "Watch and punish the spectators when they are observer since too long time",
	version = __VERSION__,
	url = "http://www.sourcemod.net/"
}

new Handle:timersList[MAXPLAYERS+1] = INVALID_HANDLE
new playersWarns[MAXPLAYERS+1]

new Handle:watchspec_max_warnings
new Handle:watchspec_sanction
new Handle:watchspec_ban_time

public OnPluginStart()
{
	CreateConVar("watchspec_version",__VERSION__,"Version of the Nicolous's WatchSpec SourceMod plugin", FCVAR_REPLICATED|FCVAR_NOTIFY, false, 0.0, false, 0.0)

	watchspec_max_warnings = CreateConVar("watchspec_max_warnings","0","WatchSpec : max warnings before sanction (0 = off)", _, true, 0.0, false, 0.0)
	watchspec_sanction = CreateConVar("watchspec_sanction","0","WatchSpec : sanction for spectators", _, true, 0.0, true, 1.0)
	watchspec_ban_time = CreateConVar("watchspec_ban_time","0","WatchSpec : ban time if watchspec_sanction is \"1\"", _, true, 0.0, false, 0.0)
	
	for (new i=0;i<MAXPLAYERS+1;i++)
		timersList[i] = INVALID_HANDLE
		
	HookEvent("player_activate", GameEvents, EventHookMode_Pre)
	HookEvent("player_disconnect", GameEvents, EventHookMode_Pre)
	HookEvent("player_team", GameEvents, EventHookMode_Post)
}

public OnMapStart()
{
	AutoExecConfig()
	LoadTranslations("plugin.WatchSpec")
	for (new i=0;i<MAXPLAYERS+1;i++)
		playersWarns[i] = 0
}

public OnMapEnd()
{
	for (new i=0; i<MAXPLAYERS+1;i++)
	{	
		if(timersList[i] != INVALID_HANDLE)
		{
			KillTimer(timersList[i])
			timersList[i] = INVALID_HANDLE
		}
	}
}

public GameEvents(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetEventInt(event, "userid")
	new index = GetClientOfUserId(clientId)
	
	if (index)
	{
		if(!IsFakeClient(index))
		{
			if (StrEqual(name,"player_activate"))
			{
				timersList[index] = CreateTimer(120.0,checkSpec, index, TIMER_REPEAT)
				playersWarns[index] = 0
			}
			else if (StrEqual(name,"player_disconnect"))
			{	
				if (timersList[index] != INVALID_HANDLE)
				{
					KillTimer(timersList[index])
					timersList[index] = INVALID_HANDLE
				}
			}
			else if (StrEqual(name,"player_team"))
			{
				if (timersList[index] != INVALID_HANDLE)
				{
					KillTimer(timersList[index])
					timersList[index] = INVALID_HANDLE
				}
				if (GetEventInt(event,"team") < 2)
				{
					timersList[index] = CreateTimer(120.0,checkSpec, index, TIMER_REPEAT)
				}
			}
		}
	}
}

public Action:checkSpec(Handle:timer, any:index)
{
	//if somehow disconnected without the timer stopping
	if(!IsClientConnected(index))
	{
		timersList[index] = INVALID_HANDLE
		return Plugin_Stop
	}
		
	new AdminId:aidUserAdmin = INVALID_ADMIN_ID;
	aidUserAdmin = GetUserAdmin(index)
	
	if(aidUserAdmin != INVALID_ADMIN_ID)
	{
		if(GetAdminFlag(aidUserAdmin,Admin_Generic, Access_Effective))
			return Plugin_Continue
		else
			playersWarns[index]++
	}
	else
		playersWarns[index]++
		
		
	new maxWarn = GetConVarInt(watchspec_max_warnings)
	
	if (playersWarns[index] <= maxWarn)
	{
		new String:pseudo[32]
		GetClientName(index,pseudo,sizeof(pseudo))
		PrintToChatAll("%t","warning",pseudo,playersWarns[index],maxWarn)
	}
	else
	{
		new sanction = GetConVarInt(watchspec_sanction)
		if (sanction == 0)
		{
			ServerCommand("kickid %i Spectator",GetClientUserId(index))
			//new String:pseudo[32]
			//GetClientName(index,pseudo,sizeof(pseudo))
			//PrintToChatAll("%t","kick",pseudo,playersWarns[index])
		}
		else
		{
			new bantime = GetConVarInt(watchspec_ban_time)
			new userid = GetClientUserId(index)
			ServerCommand("banid %i %i",bantime,userid)
			ServerCommand("kickid %i Spectator",userid)
			
			new String:pseudo[32]
			GetClientName(index,pseudo,sizeof(pseudo))
			if (bantime == 0)
			{
				ServerCommand("writeid")
				PrintToChatAll("%t","perm_ban",pseudo,playersWarns[index])
			}
			else
				PrintToChatAll("%t","temp_ban",pseudo,bantime,playersWarns[index])
		}
	}
	return Plugin_Continue
}
