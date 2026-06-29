#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Strip Nades",
	author = "Potatoz",
	description = "Strip all players from nades on spawn.",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn",SpawnEvent);
} 

public Action:SpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
    new client_id = GetEventInt(event, "userid");
    new client = GetClientOfUserId(client_id);

    CreateTimer(1.0, Timer_StripNades, client, TIMER_REPEAT);
}

public Action Timer_StripNades(Handle timer, any client)
{
	StripGrenades(client);
	return Plugin_Continue;
}

public StripGrenades(client) {
    for(new i = 0; i < 4; i++) {
	if(IsValidClient(client)) {
        new ent = GetPlayerWeaponSlot(client, i);
		
		decl String:weapon_name[32];  
		GetEdictClassname(ent, weapon_name, sizeof(weapon_name)); 

        if(ent != -1) {
			if(StrEqual(weapon_name, "weapon_hegrenade", false) || StrEqual(weapon_name, "weapon_smokegrenade", false) ||  StrEqual(weapon_name, "weapon_flashbang", false) ||  StrEqual(weapon_name, "weapon_incgrenade", false) || StrEqual(weapon_name, "weapon_decoy", false)) {
			RemovePlayerItem(client, ent);
			RemoveEdict(ent);
			}	
        }
	 }
    }
} 

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}  