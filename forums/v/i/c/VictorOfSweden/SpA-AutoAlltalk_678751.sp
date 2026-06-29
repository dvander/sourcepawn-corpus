/**
 * SpecialAttack Auto-Alltalk
 * 2008-08-08 (VictorOfSweden)
 *
 * Based on a plugin by ferret
 * http://forums.alliedmods.net/showthread.php?t=65158
 *
 */

#include <sourcemod>

#pragma semicolon 1

/* Plugin metadata */
public Plugin:myinfo =
{
	name = "SpecialAttack Auto-Alltalk",
	author = "SpecialAttack",
	description = "Automatically toggles sv_alltalk. Based on a plugin by ferret.",
	version = "1.0.4",
	url = "http://www.specialattack.net/"
};

/* CVARs */
new Handle:g_cvar_alltalk = INVALID_HANDLE;
new Handle:g_cvar_limit = INVALID_HANDLE;
new Handle:g_cvar_limitmode = INVALID_HANDLE;
new Handle:g_cvar_roundend = INVALID_HANDLE;
new Handle:g_cvar_roundendmode = INVALID_HANDLE;

/* Other global variables */
new g_alltalk_original;

/* Called when the plugin is fully initialized and all known external references are resolved. */
public OnPluginStart(){
	/* Load phrases */
	LoadTranslations("specialattack.phrases");
	
	/* Alltalk cvar */
	g_cvar_alltalk = FindConVar("sv_alltalk");
	g_alltalk_original = GetConVarInt(g_cvar_alltalk);
	
	/* Limit mode settings */
	g_cvar_limit = CreateConVar("sm_spa_atlimit", "8", "Number of players needed to toggle alltalk (0 = turn off).", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, MAXPLAYERS);
	g_cvar_limitmode = CreateConVar("sm_spa_atlimitmode", "0", "When the player limit is reached, turn alltalk on/off (1/0).", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	/* Round end settings */
	g_cvar_roundend = CreateConVar("sm_spa_atroundend", "1", "Turn toggeling of alltalk at round end on/off (1/0).", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_cvar_roundendmode = CreateConVar("sm_spa_atroundendmode", "1", "When a round is over, turn alltalk on/off (1/0).", FCVAR_PLUGIN|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	
	/* Execute config file */
	AutoExecConfig(true, "specialattack");
	
	/* Hook events */
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
	HookEvent("teamplay_game_over", OnRoundEnd, EventHookMode_Post);
	/* HookEvent("teamplay_round_stalemate", OnRoundEnd, EventHookMode_Post); */
	
	/* Hook CVAR change */
	HookConVarChange(g_cvar_alltalk, OnConVarChange_Alltalk);
	
	/* Hide original notification of change */
	new flags = GetConVarFlags(g_cvar_alltalk);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_cvar_alltalk, flags);
	
	/* Do the first toggle (if neccesary) */
	ToggleAlltalkLimit();
}

/* Called when the plugin is about to be unloaded. */
public OnPluginEnd(){	
	/* Restore original alltalk value */
	if(GetConVarBool(g_cvar_alltalk) != g_alltalk_original){
		SetConVarBool(g_cvar_alltalk, g_alltalk_original);
	}
}

/* Called when a new round is about to start */
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	ToggleAlltalkLimit();
	return Plugin_Continue;
}

/* Called when a round has ended */
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	/* Store mode cvar value */
	new mode = GetConVarBool(g_cvar_roundendmode);
	
	/* If round end is enabled, compare value with mode cvar. If different, change it */
	if(GetConVarBool(g_cvar_roundend)){
		if(GetConVarBool(g_cvar_alltalk) != mode){
			SetConVarBool(g_cvar_alltalk, mode);
		}
	}
	
	return Plugin_Continue;
}

/* Called on client connection. */
public bool:OnClientConnect(client, String:rejectmsg[], maxlen){
	ToggleAlltalkLimit();
	return true;
}

/* Called when a client is disconnecting from the server. */
public OnClientDisconnect(client){
	ToggleAlltalkLimit();
}

/* Function to toggle alltalk based on player limit */
ToggleAlltalkLimit(){
	/* If limit is 0, do nothing */
	if (!GetConVarInt(g_cvar_limit)){
		return;
	}
	
	new clientcount = GetClientCount(false);
	new limit = GetConVarInt(g_cvar_limit);
	new alltalk = GetConVarBool(g_cvar_alltalk);
	new limitmode = GetConVarBool(g_cvar_limitmode);
	
	/* If player limit is exceeded and alltalk has the wrong value, toggle it */
	if (limit <= clientcount && alltalk != limitmode){
		SetConVarBool(g_cvar_alltalk, GetConVarBool(g_cvar_limitmode));
	}
	/* If player limit is not exceeded and alltalk has the wrong value, toggle it */
	else if(clientcount < limit && alltalk == limitmode){
		SetConVarBool(g_cvar_alltalk, !GetConVarBool(g_cvar_limitmode));
	}
}

/* Called when the cvar sv_alltalk is changed (makes prettier output) */
public OnConVarChange_Alltalk(Handle:cvar, const String:oldVal[], const String:newVal[]){
	if(GetConVarBool(g_cvar_alltalk)){
		PrintToChatAll("\x03%t", "alltalk_on");
	}else{
		PrintToChatAll("\x03%t", "alltalk_off");
	}
	return;
}