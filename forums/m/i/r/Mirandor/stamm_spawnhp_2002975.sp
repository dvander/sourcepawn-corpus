#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <autoexecconfig>

#pragma semicolon 1

new hp;
new v_level;

new Handle:c_hp;

public Plugin:myinfo =
{
	name = "Stamm Feature SpawnHP",
	author = "Popoklopsi",
	version = "1.2",
	description = "Give VIP's more HP on spawn",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP SpawnHP", "", true, false);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("spawnhp", "stamm/features");
	
	c_hp = AutoExecConfig_CreateConVar("spawnhp_hp", "50", "HP a VIP gets every spawn more");
	
	AutoExecConfig(true, "spawnhp", "stamm/features");
	
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", PlayerSpawn);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	Format(description, sizeof(description), "%T", "GetSpawnHP", LANG_SERVER, hp);
	
	STAMM_AddFeatureText(STAMM_GetLevel(), description);
}

public OnConfigsExecuted()
{
	hp = GetConVarInt(c_hp);
}

public PlayerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_IsClientVip(client, v_level) && STAMM_WantClientFeature(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)) CreateTimer(0.5, changeHealth, client);
	}
}

public Action:changeHealth(Handle:timer, any:client)
{
	new newHP = GetClientHealth(client) + hp;
	
	SetEntProp(client, Prop_Data, "m_iMaxHealth", newHP);
	SetEntityHealth(client, newHP);
}