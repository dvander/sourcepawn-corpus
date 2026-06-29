#include <sourcemod>

int g_offsCollisionGroup;
ConVar sm_noblock;
ConVar sm_noblock_nade;

public Plugin myinfo = 
{
	name = "NoBlock",
	author = "Otstrel.ru Team, Xines",
	description = "Removes player collisions!",
	version = "2.0",
	url = ""
};

public void OnPluginStart()
{
	g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1) {
		PrintToServer("* FATAL ERROR: Failed to get offset for CBaseEntity::m_CollisionGroup");
	}
	else {
		HookEvent("player_spawn", OnSpawn, EventHookMode_Post);
		sm_noblock = CreateConVar("sm_noblock", "1", "Removes player vs. player collisions", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		sm_noblock_nade = CreateConVar("sm_noblock_nade", "0", "Removes player vs. nade collisions", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		HookConVarChange(sm_noblock, OnConVarChange);
	}
}

public void OnConVarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	switch (StringToInt(newValue))
	{
		case 0:
		{
			UnhookEvent("player_spawn", OnSpawn, EventHookMode_Post);
			Setblock();
		}
		case 1:
		{
			HookEvent("player_spawn", OnSpawn, EventHookMode_Post);
			Setblock();
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(GetConVarBool(sm_noblock) && GetConVarBool(sm_noblock_nade))
	{
		if (StrEqual(classname, "hegrenade_projectile") ||
			StrEqual(classname, "flashbang_projectile") ||
			StrEqual(classname, "smokegrenade_projectile")) {
			SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
		}
	}
}

void Setblock()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(!GetConVarBool(sm_noblock)) {
				SetEntData(i, g_offsCollisionGroup, 5, 4, true);
			}
			if(GetConVarBool(sm_noblock)) {
				SetEntData(i, g_offsCollisionGroup, 2, 4, true);
			}
		}
	}
}

public Action OnSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int entity = GetClientOfUserId(event.GetInt("userid"));
	SetEntData(entity, g_offsCollisionGroup, 2, 4, true);
	return Plugin_Continue;
}