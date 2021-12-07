#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.2"
 
new Handle:runspeed = INVALID_HANDLE;
new Handle:knifehealth = INVALID_HANDLE;
 
public Plugin:myinfo = {
        name        = "CS:GO Knife Speed & Health",
        author      = "Darkranger & Feuersturm",
        description = "changes the Speed & Health when on ArmsRace Knife Level",
        version     = PLUGIN_VERSION,
        url         = "http://dark.asmodis.at"
}
 
public OnPluginStart()
{
	CreateConVar("csgo_knife_speed_version", PLUGIN_VERSION, "CS:GO ArmsRace Knife Speed & Health Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	runspeed = CreateConVar("csgo_knife_speed",    "1.3", "CS:GO Speed for ArmsRace Knife Level", FCVAR_PLUGIN, true, 1.0, true, 2.0)
	knifehealth = CreateConVar("csgo_knife_health",    "0.0", "CS:GO +Health a Player becomes on ArmsRace Knife Level", FCVAR_PLUGIN, true, 0.0, true, 100.0)
	AutoExecConfig(true, "csgo_knife_speed", "csgo_knife_speed")
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
}
 
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost)
}
 
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckSpeedSpawn(client)
}

public OnWeaponEquipPost(client, weapon)
{
	CheckSpeed(client)
}
 
public CheckSpeed(client)
{
	if(LastLevel(client) == true)
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(runspeed))
		new health = GetClientHealth(client)
		new healthkitadd = GetConVarInt(knifehealth)
		SetEntityHealth(client, health + healthkitadd)
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0)
	}
}

public CheckSpeedSpawn(client)
{
	if(LastLevel(client) == true)
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", GetConVarFloat(runspeed))
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0)
		SetEntityHealth(client, 100)
	}
}
 
public bool:LastLevel(client)
{
        if(IsValidClient(client) && IsPlayerAlive(client))
        {
                new weapon_count = 0
                for(new i = 0; i <= 4; i++)
                {
                        new wpn = GetPlayerWeaponSlot(client, i)
                        if(wpn != -1)
                        {
                                weapon_count++
                        }
                }
                if(weapon_count == 1)
                {
                        // hat nur das Messer!
                        return true
                }
                else
                {
                        // noch weitere Waffen!
                        return false
                }
        }
        return false
}
 
public bool:IsValidClient(client)
{
        if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        {
                return false
        }
        return true
}