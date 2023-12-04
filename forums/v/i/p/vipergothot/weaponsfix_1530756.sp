#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.1"

new Handle:hRemoveWeapons = INVALID_HANDLE;
new String:breaker[] = "_";
new String:prefix[12];

public Plugin:myinfo = 
{
	name = "Dodgebal weaponiser",
	author = "Kemsan",
	description = "Remove Shotgun / Axe in dodgeball!",
	version = PLUGIN_VERSION,
	url = "http://kemsan.pl"
}

public OnPluginStart()
{
	CreateConVar("dodgebal_weponiser", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hRemoveWeapons = CreateConVar("sm_remove_weapons", "0", "Enable/Disable(1/0) remove 2 and 3 slot weapons", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookEvent("teamplay_broadcast_audio", Event_RoundStart);
	HookEvent("player_spawn", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:currentMap[64];
	GetCurrentMap(currentMap, 64);
	SplitString(currentMap, breaker, prefix, sizeof(prefix));
	if(GetConVarBool(hRemoveWeapons) && StrEqual( prefix, "tfdb" ) )
	{
		for (new i = 1; i <= MaxClients; i ++)
		{
			if (IsClientInGame(i) )
			{
				TF2_RemoveWeaponSlot(i, 1);       
				TF2_RemoveWeaponSlot(i, 2);  
        			TF2_RemoveWeaponSlot(i, 3);
				TF2_RemoveWeaponSlot(i, 4);  
				TF2_RemoveWeaponSlot(i, 5);  
			}
		}
	}
	return Plugin_Continue;
}