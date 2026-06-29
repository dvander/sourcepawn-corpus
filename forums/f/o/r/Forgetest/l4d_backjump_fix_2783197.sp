#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
	name = "[L4D & 2] Backjump Fix",
	author = "Forgetest",
	description = "Fix hunter being unable to pounce off non-static props",
	version = PLUGIN_VERSION,
	url = "https://github.com/Target5150/MoYu_Server_Stupid_Plugins"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return;
	
	SDKHook(client, SDKHook_TouchPost, SDK_OnTouch_Post);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client)
		return;
	
	int oldteam = event.GetInt("oldteam");
	if (oldteam != 3 || oldteam == event.GetInt("team"))
		return;
	
	SDKUnhook(client, SDKHook_TouchPost, SDK_OnTouch_Post);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || GetClientTeam(client) != 3 || GetEntProp(client, Prop_Send, "m_zombieClass") != 3)
		return;
	
	SDKUnhook(client, SDKHook_TouchPost, SDK_OnTouch_Post);
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(event.GetInt("bot"), event.GetInt("player"));
}

void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	HandlePlayerReplace(event.GetInt("player"), event.GetInt("bot"));
}

void HandlePlayerReplace(int replacer, int replacee)
{
	replacer = GetClientOfUserId(replacer);
	if (!replacer || GetClientTeam(replacer) != 3 || GetEntProp(replacer, Prop_Send, "m_zombieClass") != 3)
		return;
	
	replacee = GetClientOfUserId(replacee);
	if (!replacee || !IsClientInGame(replacee))
		return;
	
	SDKUnhook(replacee, SDKHook_TouchPost, SDK_OnTouch_Post);
}

void SDK_OnTouch_Post(int entity, int other)
{
	if (!IsClientInGame(entity))
		return;
	
	int ability = GetEntPropEnt(entity, Prop_Send, "m_customAbility");
	if (ability == -1)
	{
		SDKUnhook(entity, SDKHook_TouchPost, SDK_OnTouch_Post);
		return;
	}
	
	if (GetEntPropEnt(entity, Prop_Send, "m_hGroundEntity") != -1)
		return;

	if (GetEntPropFloat(ability, Prop_Send, "m_lungeAgainTimer", 1) != GetGameTime() + 0.5)
		return;
	
	if (other != 0)
		return;
	
	static float vPos[3], vEnd[3];
	GetClientEyePosition(entity, vPos);
	
	vEnd[0] = vPos[0];
	vEnd[1] = vPos[1];
	vEnd[2] = vPos[2] + 50.0;
	
	static Handle tr;
	tr = TR_TraceRayFilterEx(vPos, vEnd, MASK_VISIBLE, RayType_EndPoint, TraceFilter_NoSelf, entity);
	if (TR_DidHit(tr))
	{
		if (TR_GetSurfaceFlags(tr) & (SURF_SKY2D|SURF_SKY))
		{
			SetEntPropFloat(ability, Prop_Send, "m_lungeAgainTimer", -1.0, 1);
		}
	}
	
	delete tr;
}

bool TraceFilter_NoSelf(int entity, int contentsMask, any data)
{
	return entity != data;
}

// https://forums.alliedmods.net/showthread.php?t=147732
#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004
/**
 * Checks whether the entity is solid or not.
 *
 * @param entity            Entity index.
 * @return                    True if the entity is solid, false otherwise.
 */
stock bool Entity_IsSolid(int entity)
{
    return (GetEntProp(entity, Prop_Send, "m_nSolidType", 1) != SOLID_NONE &&
            !(GetEntProp(entity, Prop_Send, "m_usSolidFlags", 2) & FSOLID_NOT_SOLID));
}