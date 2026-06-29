#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <zombiereloaded>

public Plugin myinfo =
{
	name = "zr_zombie_killfeed",
	author = "Karolis_",
	description = "Custom killfeed icon for zombies",
    version = "1.0",
};


public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}


public Action:OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid" ));

    char weapon[20];
    GetEventString(event, "weapon", weapon, sizeof(weapon));

    if(client && IsClientInGame(client) && IsPlayerAlive(client) && ZR_IsClientZombie(client)) 
    {
        if(StrEqual(weapon, "knife", false))
        {
            SetEventString(event, "weapon", "zombie_walking_csgo");
            SetEventString(event, "weapon_logclassname", "zombie_walking_csgo");
        }
    }
} 