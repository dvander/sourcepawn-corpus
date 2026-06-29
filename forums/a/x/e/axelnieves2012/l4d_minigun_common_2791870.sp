#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <left4dhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define DEBUG 0

//#define TEAM_UNASSIGNED 0
//#define TEAM_SPECTATE 1
#define TEAM_SURVIVOR	2
//#define TEAM_INFECTED	3
#define TIMER_THIS_MAP	TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE

ConVar l4d_minigun_common_enable, l4d_minigun_common_50cal, l4d_minigun_common_minigun, l4d_minigun_common_penalty, l4d_minigun_common_penalty_incapped;
int g_iTarget[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
Handle g_hTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
float g_fPenalty[MAXPLAYERS+1] = {0.0, ...};
//int g_bLeft4Dead1;

public Plugin myinfo = 
{
	name = "L4D Minigun Common Infected",
	author = "Axel Juan Nieves",
	description = "Common infected will target people using minigun.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2791870"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if ( test == Engine_Left4Dead ) {/*g_bLeft4Dead1=true;*/}
    else if( test == Engine_Left4Dead2 ) {/*g_bLeft4Dead1=false;*/}
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_minigun_common_version", PLUGIN_VERSION, "", 0);
	l4d_minigun_common_enable = CreateConVar("l4d_minigun_common_enable", "1", "Enable/Disable this plugin", 0);
	l4d_minigun_common_minigun = CreateConVar("l4d_minigun_common_minigun", "1", "Target people using minigun?", 0);
	l4d_minigun_common_50cal = CreateConVar("l4d_minigun_common_50cal", "1", "Target people using 50cal?", 0);
	l4d_minigun_common_penalty = CreateConVar("l4d_minigun_common_penalty", "10", "How many seconds will take zombies stop focusing you after releasing minigun (0=immediate)", 0, true, 0.1);
	l4d_minigun_common_penalty_incapped = CreateConVar("l4d_minigun_common_penalty_incapped", "0", "Keep focusing if incapped?", 0);

	AutoExecConfig(true, "l4d_minigun_common");
	//HookEvent("player_team", event_player_team, EventHookMode_Post);
	HookEvent("player_death", event_player_, EventHookMode_Post);
	
	HookEvent("round_freeze_end", event_round_, EventHookMode_PostNoCopy);
	HookEvent("round_start", event_round_, EventHookMode_PostNoCopy);
	HookEvent("round_end", event_round_, EventHookMode_PostNoCopy);
}

public void OnEntityCreated(int ent, const char[] classname)
{
	if ( GetConVarBool(l4d_minigun_common_minigun) && StrEqual("prop_minigun", classname, false) )
		SDKHook(ent, SDKHook_Use, OnEntityUse);
	else if ( GetConVarBool(l4d_minigun_common_50cal) && StrEqual("prop_mounted_machine_gun", classname, false) )
		SDKHook(ent, SDKHook_Use, OnEntityUse);
}

public Action OnEntityUse(int ent, int client)
{
	if ( GetConVarBool(l4d_minigun_common_enable)==false )
	{
		ResetVariables();	
		return Plugin_Continue;
	}
	
	if ( !IsValidClientInGame(client) )
		return Plugin_Continue;

	if ( !IsPlayerAlive(client) )
		return Plugin_Continue;

	if ( GetClientTeam(client)!=TEAM_SURVIVOR )
		return Plugin_Continue;

	if ( !IsValidEntity(ent) )
		return Plugin_Continue;
	
	int focus = EntRefToEntIndex(g_iTarget[client]);
	if ( !IsValidEntity(focus) )
	{
		focus = CreateEntityByName("info_goal_infected_chase");
		if ( IsValidEntity(focus) )
		{
			DispatchSpawn(focus);
			AcceptEntityInput(focus, "Enable");
			SetVariantString("!activator");
			AcceptEntityInput(focus, "SetParent", client);
			TeleportEntity(focus, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
			g_iTarget[client] = EntIndexToEntRef(focus);
			
			if ( g_hTimer[client]==INVALID_HANDLE )
				g_hTimer[client] = CreateTimer(0.1, HookOnUnuse, GetClientUserId(client), TIMER_THIS_MAP);
		}
	}
	return Plugin_Continue;
}

public Action HookOnUnuse(Handle timer, int clientID)
{
	int client = GetClientOfUserId(clientID);
	if ( !IsValidClientInGame(client) )
	{
		if ( IsValidClientIndex(client) )
			g_hTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if ( GetConVarBool(l4d_minigun_common_enable)==false )
	{
		ResetVariables();
		return Plugin_Stop;
	}
	
	if ( !IsUsingMountedMachineGun(client) )
	{
		g_fPenalty[client] = GetConVarFloat(l4d_minigun_common_penalty);
		g_hTimer[client] = CreateTimer(0.1, PenaltyCountdown, GetClientUserId(client), TIMER_THIS_MAP);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action PenaltyCountdown(Handle timer, int clientID)
{
	if ( GetConVarBool(l4d_minigun_common_enable)==false )
		ResetVariables();
		
	int client = GetClientOfUserId(clientID);
	
	if ( !IsValidClientInGame(client) )
	{
		#if DEBUG > 0
			PrintToChatAll("!IsValidClientInGame");
		#endif
		RemoveFocus(client);
		return Plugin_Stop;
	}
	
	int team = GetClientTeam(client);
	if ( team>TEAM_SURVIVOR )
	{
		#if DEBUG > 0
			PrintToChatAll("team>survivor %i", team);
		#endif
		RemoveFocus(client);
		return Plugin_Stop;
	}
	
	if ( IsUsingMountedMachineGun(client) )
	{
		g_hTimer[client] = CreateTimer(0.1, HookOnUnuse, GetClientUserId(client), TIMER_THIS_MAP);
		return Plugin_Stop;
	}
	
	//if survivor becomes spectator/idle keep penalty timer running...
	else if ( team<TEAM_SURVIVOR )
	{
		#if DEBUG > 0
			PrintToChatAll("team<survivor %i", team);
		#endif
		return Plugin_Continue;
	}
		
	if ( GetConVarBool(l4d_minigun_common_penalty_incapped)==false && GetEntProp(client, Prop_Send, "m_isIncapacitated") )
	{
		//if hanging from ledge keep pealty timer running...
		if ( GetEntProp(client, Prop_Send, "m_isHangingFromLedge") )
		{
			#if DEBUG > 0
				PrintToChatAll("hanging, dont remove");
			#endif
			return Plugin_Continue;
		}
		
		//if incapped, remove focus...
		#if DEBUG > 0
			PrintToChatAll("Incapped, remove focus");
		#endif
		RemoveFocus(client);
		return Plugin_Stop;
	}
	
	g_fPenalty[client] -= 0.1;
	#if DEBUG > 0
		PrintToChatAll("timer: %i", RoundFloat(g_fPenalty[client]) );
	#endif
	
	if ( g_fPenalty[client] <= 0.0 )
	{
		#if DEBUG > 0
			PrintToChatAll("timer runned out, remove focus");
		#endif
		RemoveFocus(client);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

stock int IsUsingMountedMachineGun(int client)
{
	char classname[32];
	if ( HasEntProp(client, Prop_Send, "m_hUseEntity") )
	{
		int entity = GetEntPropEnt(client, Prop_Send, "m_hUseEntity");
		if ( IsValidEntity(entity) )
		{
			GetEdictClassname(entity, classname, sizeof(classname));
			
			if ( GetConVarBool(l4d_minigun_common_minigun) && StrEqual(classname, "prop_minigun") )
				return 1;
			else if ( GetConVarBool(l4d_minigun_common_50cal) && StrEqual(classname, "prop_mounted_machine_gun") )
				return 2;
			
		}
		else //if not holding any mounted machine gun...
			return 0;
	}
	return 0;
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	RemoveFocus(client);
	return true;
}

public void OnClientDisconnect(int client)
{
	RemoveFocus(client);
}

public void event_player_(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(client) )
		return;
		
	RemoveFocus(client);
}

public void event_round_(Handle event, const char[] name, bool dontBroadcast)
{
	ResetVariables();
}

stock void RemoveFocus(int client)
{
	if ( !IsValidClientIndex(client) )
		return;
		
	int focus = EntRefToEntIndex(g_iTarget[client]);
	if ( IsValidEntity(focus) )
	{
		AcceptEntityInput(focus, "ClearParent");
		AcceptEntityInput(focus, "Kill");
	}
	
	/*if ( g_hTimer[client]!=INVALID_HANDLE )
		KillTimer(g_hTimer[client]);*/
	
	g_iTarget[client] = INVALID_ENT_REFERENCE;
	g_hTimer[client] = INVALID_HANDLE;
	g_fPenalty[client] = 0.0;
}

stock void ResetVariables()
{
	for ( int i=1; i<=MAXPLAYERS; i++ )
		RemoveFocus(i);
}

stock bool IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return true;
	}
	return false;
}

stock bool IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return true;
	}
	return false;
}

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}
