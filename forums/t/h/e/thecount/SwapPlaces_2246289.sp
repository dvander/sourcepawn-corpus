#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#include <tf2>
#include <cstrike>

public Plugin:myinfo = {
	name = "Swap Places",
	author = "The Count",
	description = "Swap places with whomever you're observing.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new bool:checkDeath[MAXPLAYERS + 1], String:mod[12];

public OnPluginStart(){
	GetGameFolderName(mod, sizeof(mod));
	if(!StrEqual(mod, "tf") && !StrEqual(mod, "csgo") && !StrEqual(mod, "cstrike")){
		PrintToServer("[SwapPlaces] Plugin DOES NOT support this game!");
		return;
	}
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_swap", Cmd_Swap, ADMFLAG_GENERIC, "Swap places with whomever you're observing.");
	HookEvent("player_death", Evt_Death, EventHookMode_Pre);
}

public Action:Cmd_Swap (client, args){
	if(args > 1){
		PrintToChat(client, "[SM] Usage: !swap [Optional Client]");
		return Plugin_Handled;
	}
	if(args == 1){
		new String:arg1[MAX_NAME_LENGTH];GetCmdArg(1, arg1, sizeof(arg1));
		new targ = FindTarget(client, arg1, false, false);
		if(targ == -1 || !IsPlayerAlive(targ)){
			return Plugin_Handled;
		}
		if(!IsPlayerAlive(client)){
			if(StrEqual(mod, "tf")){
				TF2_RespawnPlayer(client);
			}else if(StrEqual(mod, "csgo") || StrEqual(mod, "cstrike")){
				CS_RespawnPlayer(client);
			}
		}
		new Float:loc[3], Float:angs[3], Float:loc2[3], Float:angs2[3];
		GetClientAbsOrigin(targ, loc);GetClientAbsAngles(targ, angs);
		GetClientAbsOrigin(client, loc2);GetClientAbsAngles(client, angs2);
		TeleportEntity(targ, loc2, angs2, NULL_VECTOR);
		TeleportEntity(client, loc, angs, NULL_VECTOR);
		PrintToChat(client, "\x01[SM]\x04 Swap'd!");
		PrintToChat(targ, "\x01[SM] Admin \x04%N\x01 has swapped places with you!", client);
		return Plugin_Handled;
	}
	if(IsPlayerAlive(client)){
		PrintToChat(client, "[SM] But you're already alive!");
		return Plugin_Handled;
	}
	if(GetClientTeam(client) < 2){
		PrintToChat(client, "[SM] Must be on a team first.");
		return Plugin_Handled;
	}
	new targ = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if(targ <= 0 || targ > MaxClients || targ == client || !IsPlayerAlive(targ)){
		PrintToChat(client, "[SM] Invalid target being observed.");
		return Plugin_Handled;
	}
	if(StrEqual(mod, "tf")){
		TF2_RespawnPlayer(client);
	}else if(StrEqual(mod, "csgo") || StrEqual(mod, "cstrike")){
		CS_RespawnPlayer(client);
	}
	new Float:loc[3], Float:angs[3];GetClientAbsOrigin(targ, loc);GetClientAbsAngles(targ, angs);
	checkDeath[targ] = true;
	ForcePlayerSuicide(targ);
	TeleportEntity(client, loc, angs, NULL_VECTOR);
	PrintToChat(client, "\x01[SM]\x04 Swap'd!");
	PrintToChat(targ, "\x01[SM] Admin \x04%N\x01 has swapped places with you!", client);
	return Plugin_Handled;
}

public Action:Evt_Death(Handle:event, String:name[], bool:dontB){//Basically here to stop death from entering kill feed.
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(checkDeath[client]){
		checkDeath[client] = false;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}