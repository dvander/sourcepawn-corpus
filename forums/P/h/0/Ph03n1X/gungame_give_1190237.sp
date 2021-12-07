#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <gungame>
#include <colors>

#define GG_SLOTINDEX_KNIFE 2
#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "GunGame:SM Give Weapon",
	author = "PhO3n1X",
	description = "Gives the player the current weapon they are on.",
	version = PLUGIN_VERSION,
	url = "http://www.gungame.lv"
};

new g_Players[MAXPLAYERS + 1] = {0, ...};
new Handle:g_Limit;

public OnPluginStart()
{
	CreateConVar("gungame_give_version", PLUGIN_VERSION, "GunGame Give version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Limit = CreateConVar("sm_give_limit", "5", "The number of times a user can use give command per round (0 = no limit)", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);
	
	RegConsoleCmd("sm_give", Command_Give);
	HookEvent("round_start", Round_Start, EventHookMode_PostNoCopy);
	
	LoadTranslations("gungame_give");
}

public OnClientPutInServer(client)
{
	g_Players[client] = 0;
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<=MaxClients; i++) {
		g_Players[i] = 0;
	}
}

public Action:Command_Give(client, args)
{
	if ( !client || !IsPlayerAlive(client) || GG_IsWarmupInProgress() ) {
		CPrintToChat(client, "%t", "You can not use this command");
		return Plugin_Handled;
	}
	
	new givelimit = GetConVarInt(g_Limit);
	if (g_Players[client] >= givelimit && givelimit) {
		CPrintToChat(client, "%t", "Command limit reached", givelimit);
		return Plugin_Handled;
	}
	
	new level = GG_GetClientLevel(client);
	decl String:weapon[64];
	GG_GetLevelWeaponName(level, weapon, sizeof(weapon));
	
	if ( StrEqual(weapon, "hegrenade") || StrEqual(weapon, "knife") ) {
		CPrintToChat(client, "%t", "This command can not be used on level", weapon);
		return Plugin_Handled;
	}
	
	StripWeaponsButKnife(client);
	Format(weapon, sizeof(weapon), "weapon_%s", weapon);
	GivePlayerItem(client, weapon);
	
	if ( StrEqual(weapon, "glock") || StrEqual(weapon, "usp") || StrEqual(weapon, "p228") || 
	StrEqual(weapon, "deagle") || StrEqual(weapon, "fiveseven") || StrEqual(weapon, "elite")) {
		ClientCommand( client, "slot2" );
	} else {
		ClientCommand( client, "slot1" );
	}
	
	if (givelimit > 0) {
		g_Players[client]++;
	}
	
	return Plugin_Handled;
}

// Thanks to MistaGee's JailMod for this part
StripWeaponsButKnife(client)
{
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i < 5; i++ ) {
		if( i == GG_SLOTINDEX_KNIFE ) continue; // You can leeeeave your knife on...
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ) {
			RemovePlayerItem( client, wepIdx );
		}
	}
}