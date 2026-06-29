#pragma semicolon 1

#define PLUGIN_AUTHOR "Tenchuu"
#define PLUGIN_VERSION "1.0.0"

Handle hRespawnCT        = INVALID_HANDLE;
Handle hRespawnT         = INVALID_HANDLE;
Handle hDeathDropGun     = INVALID_HANDLE;
Handle hDeathDropDefuser = INVALID_HANDLE;
Handle hDeathDropGrenade = INVALID_HANDLE;
Handle hDeathDropBomb    = INVALID_HANDLE;

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
    name = "[CS:GO] CSS:DM Fix",
    author = PLUGIN_AUTHOR,
    description = "Temporary fix. Wait until CSS:DM has been updated ;)",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
	hRespawnCT = CreateConVar("mp_respawn_on_death_ct", "1");
	hRespawnT = CreateConVar("mp_respawn_on_death_t", "1");
	hDeathDropGun = CreateConVar("mp_death_drop_gun", "0");
	hDeathDropDefuser = CreateConVar("mp_death_drop_defuser", "0");
	hDeathDropGrenade = CreateConVar("mp_death_drop_grenade", "0");
	hDeathDropBomb = CreateConVar("mp_death_drop_bomb", "0");

	CreateConVar("download_version", PLUGIN_VERSION);
    
    AutoExecConfig(true, "respawn_dm");
}

public void OnMapStart()
{
	//RespawnCT
	int RespawnCT = GetConVarInt(hRespawnCT);
	if (RespawnCT != 1)
    {
        ServerCommand("mp_respawn_on_death_ct 1");
    }
    else
    {
        CloseHandle(hRespawnCT);
    }
	
	//RespawnT
	int RespawnT = GetConVarInt(hRespawnT);
	if (RespawnT != 1)
    {
        ServerCommand("mp_respawn_on_death_t 1");
    }
    else
    {
        CloseHandle(hRespawnT);
    }
	
	//DeathDropGun
	int DeathDropGun = GetConVarInt(hDeathDropGun);
	if (DeathDropGun != 1)
    {
        ServerCommand("mp_death_drop_gun 1");
    }
    else
    {
        CloseHandle(hDeathDropGun);
    }
	
	//DeathDropDefuser
	int DeathDropDefuser = GetConVarInt(hDeathDropDefuser);
	if (DeathDropDefuser != 1)
    {
        ServerCommand("mp_death_drop_defuser 1");
    }
    else
    {
        CloseHandle(hDeathDropDefuser);
    }
	
	//DeathDropGrenade
	int DeathDropGrenade = GetConVarInt(hDeathDropGrenade);
	if (DeathDropGrenade != 1)
    {
        ServerCommand("mp_death_drop_grenade 1");
    }
    else
    {
        CloseHandle(hDeathDropGrenade);
    }

	//DeathDropBomb
	int DeathDropBomb = GetConVarInt(hDeathDropBomb);
	if (DeathDropBomb != 1)
    {
        ServerCommand("mp_death_drop_bomb 1");
    }
    else
    {
        CloseHandle(hDeathDropBomb);
    }
}