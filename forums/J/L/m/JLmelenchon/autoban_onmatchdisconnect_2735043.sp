#include <sourcemod>
#include <sdktools>
#include <colors>
#include <readyup>

#define DATA "0.9"

public Plugin myinfo =
{
	name = "AutoBan on match disconnect (L4D2 only)",
	author = "Franc1sco franug & Lunatix",
	description = "Ban players if they do not reconnect while a competitive match before a determined amount of time.",
	version = DATA,
	url = ""
}

Handle array_players_ids, array_players_time, array_players_name;

ConVar cv_enable, cv_bantime, cv_time, cv_spectators;

public void OnPluginStart()
{
	CreateConVar("sm_autobanmatchdisc_version", DATA, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	

	cv_enable = CreateConVar("sm_autobandisconnect_enable", "0", "Enable or disable the functions of this plugin");
	cv_bantime = CreateConVar("sm_autobandisconnect_bantime", "1440", "Ban time for people that disconnect on match live");
	cv_time = CreateConVar("sm_autobandisconnect_time", "300", "Time for wait people to reconnect until apply the ban");
	cv_spectators = CreateConVar("sm_autobandisconnect_excludespectators", "1", "Exclude spectators from the ban countdown?");
	
	AutoExecConfig(true, "autoban_onmatchdisconnect");
	
	
	HookConVarChange(cv_enable, CVarEnableChange);
	
	HookEvent("player_left_start_area", EventHook:PlayerLeftStartArea_Event, EventHookMode_PostNoCopy);
	HookEvent("versus_match_finished", EventHook:VersusMatchFinished_Event, EventHookMode_PostNoCopy);
	
	array_players_ids = CreateArray(64);
	array_players_time  = CreateArray();
	array_players_name  = CreateArray(128);
	
	CreateTimer(1.0, Timer_Checker, _, TIMER_REPEAT);
}

public void CVarEnableChange(Handle convar_hndl, const char[] oldValue, const char[] newValue) {
	CleanAll();
}

public OnMapStart()
{
	CleanAll();
}

public Action Timer_Checker(Handle timer)
{
	if(!cv_enable.BoolValue)
		return;
		
	int size = GetArraySize(array_players_time);
	
	if (size == 0)return;
	
	char steamid[64], name[128];
	
	for (int i = 0; i < size; i++)
	{
		if(GetTime() > GetArrayCell(array_players_time, i)+cv_time.IntValue)
		{
			GetArrayString(array_players_ids, i, steamid, sizeof(steamid));
			GetArrayString(array_players_name, i, name, sizeof(name));
			
			ServerCommand("sm_addban %i %s Match abandoned by %s", cv_bantime.IntValue, steamid, name);
			
			CPrintToChatAll("{olive}%s {default}was banned {green}1 day {default}for abandoning the match.", name);
			
			RemoveFromArray(array_players_time, i);
			RemoveFromArray(array_players_ids, i);
			RemoveFromArray(array_players_name, i);
		}
	}
}

public OnClientPostAdminCheck(int client)
{
	if(!cv_enable.BoolValue)
		return;
		
	char steamid[64];
	if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		return; // prevent fail on auth
	
	int index = FindStringInArray(array_players_ids, steamid);
	
	if (index == -1)return;
	
	RemoveFromArray(array_players_time, index);
	RemoveFromArray(array_players_ids, index);
	RemoveFromArray(array_players_name, index);
	
}

public OnClientDisconnect(client)
{
	if(!cv_enable.BoolValue || CheckCommandAccess(client, "bancountdown_inmunity", ADMFLAG_ROOT)
	|| (cv_spectators.BoolValue && GetClientTeam(client) < 2))
		return;
	
	char steamid[64], name[128];
	if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		return; // prevent fail on auth
	
	int index = FindStringInArray(array_players_ids, steamid);
	
	if (index != -1)return; // prevent duplication
	
	GetClientName(client, name, sizeof(name));
	
	PushArrayString(array_players_ids, steamid);
	PushArrayCell(array_players_time, GetTime());
	PushArrayString(array_players_name, name);
}


CleanAll()
{
	ClearArray(array_players_ids);
	ClearArray(array_players_time);
	ClearArray(array_players_name);
}


// Auto enable or disable banning cvar when match is live or not
public PlayerLeftStartArea_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsInReady() == false)
		SetConVarBool(cv_enable, true);
	else
		SetConVarBool(cv_enable, false);
}

// Disable ban function when the versus match is over.
public VersusMatchFinished_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarBool(cv_enable, false);
	CleanAll();
}