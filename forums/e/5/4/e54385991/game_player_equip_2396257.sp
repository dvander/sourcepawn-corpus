#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 	"1.1.02"



public Plugin:myinfo = {
	name = "Game_Player_Equip Fix",
	author = "Mitch",
	description = "Fixes player stripping",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd,EventHookMode_Pre);
	
	CreateConVar("sm_game_player_equip_version", PLUGIN_VERSION, "Game_Player_Equip Fix", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}



public void OnConfigsExecuted(){
	ServerCommand("mp_ct_default_melee \"\";mp_ct_default_secondary \"\";mp_ct_default_primary \"\";mp_t_default_melee \"\";mp_t_default_secondary \"\";mp_t_default_primary \"\";");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	new ent = -1; 
	while((ent = FindEntityByClassname(ent, "game_player_equip")) != -1) {
		if(!(GetEntProp(ent, Prop_Data, "m_spawnflags") & 1)) {
			SetEntProp(ent, Prop_Data, "m_spawnflags", GetEntProp(ent, Prop_Data, "m_spawnflags")|2);
			AcceptEntityInput(ent, "TriggerForAllPlayers");
		}
	}
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast){
		CreateTimer(0.3 ,RemoveWeapon ,_,TIMER_FLAG_NO_MAPCHANGE);
}


public Action RemoveWeapon(Handle Timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1)
		{
			StripAllWeapons(i);
		}
	}
	
	int maxent = GetMaxEntities();
	char weapon[64];
	for (int i=GetMaxClients();i<maxent;i++)
	{
		if (IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (StrContains(weapon, "weapon_") != -1)
				RemoveEdict(i);
		}
	}
	return Plugin_Stop;
}



stock void StripAllWeapons(int client)
{
	int iEnt;
	for(int i = 0; i <=4; ++i)
	{
		while ((iEnt = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iEnt);
			AcceptEntityInput(iEnt, "Kill");
		}
	}
}
