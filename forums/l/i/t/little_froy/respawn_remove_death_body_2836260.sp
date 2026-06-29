#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <survivor_auto_respawn>

public Plugin myinfo =
{
	name = "Respawn Remove Death Body",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347163"
};

public void SurvivorAutoRespawn_OnRespawned(int client)
{
    if(IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        int model = GetEntProp(client, Prop_Data, "m_nModelIndex");
        int entity = -1;
        while((entity = FindEntityByClassname(entity, "survivor_death_model")) != -1)
        {
            if(GetEntProp(entity, Prop_Data, "m_nModelIndex") == model)
            {
                RemoveEntity(entity);
            }
        }
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("respawn_remove_death_body_version", PLUGIN_VERSION, "version of Respawn Remove Death Body", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
