#define PLUGIN_VERSION	"3.5"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Block Self Revive Thanks Scene",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=346447"
};

int Block_scene_count[MAXPLAYERS+1];

void frame_delete(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1)
	{
		RemoveEntity(entity);
	}
}

void OnSpawnPost(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwner");
	if(owner > 0 && owner <= MaxClients && Block_scene_count[owner] > 0)
	{
		char file[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_iszSceneFile", file, sizeof(file));
		if(StrContains(file, "thanks", false) != -1)
		{
			Block_scene_count[owner]--;
			SetEntPropFloat(entity, Prop_Data, "m_flPreDelay", 999.0);
			RequestFrame(frame_delete, EntIndexToEntRef(entity));
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity < 1)
	{
		return;
	}
	if(strcmp(classname, "instanced_scripted_scene") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
	}
}

void reset_player(int client)
{
    Block_scene_count[client] = 0;
}

public void OnClientDisconnect_Post(int client)
{
    reset_player(client);
}

void event_revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if(client > 0 && IsClientInGame(client) && GetClientOfUserId(event.GetInt("userid")) == client)
	{
        Block_scene_count[client]++;
	}
}

void event_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
	}
}

void event_player_team(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
	}
}

void event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && IsClientInGame(client))
	{
        reset_player(client);
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
    HookEvent("revive_success", event_revive_success);
	HookEvent("player_spawn", event_player_spawn);
	HookEvent("player_team", event_player_team);
    HookEvent("player_death", event_player_death);

    CreateConVar("block_self_revive_thanks_scene_version", PLUGIN_VERSION, "version of Block Self Revive Thanks Scene", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
