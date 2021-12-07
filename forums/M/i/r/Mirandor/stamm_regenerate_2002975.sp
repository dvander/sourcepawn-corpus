#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <stamm>
#include <autoexecconfig>

#pragma semicolon 1

new hp;

new v_level;

new Handle:c_hp;
new Handle:ClientTimers[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Stamm Feature RegenerateHP",
	author = "Popoklopsi",
	version = "1.1",
	description = "Regenerate HP of VIP's",
	url = "https://forums.alliedmods.net/showthread.php?t=142073"
};

public OnAllPluginsLoaded()
{
	if (!LibraryExists("stamm")) SetFailState("Can't Load Feature, Stamm is not installed!");
	
	STAMM_LoadTranslation();

	STAMM_AddFeature("VIP HP Regenerate", "", true, false);
}

public OnPluginStart()
{
	AutoExecConfig_SetFile("regenerate", "stamm/features");
	
	c_hp = AutoExecConfig_CreateConVar("regenerate_hp", "2", "HP regeneration of a VIP, every second");
	
	AutoExecConfig(true, "regenerate", "stamm/features");
	
	AutoExecConfig_CleanFile();
	
	HookEvent("player_spawn", PlayerSpawn);
}

public STAMM_OnFeatureLoaded(String:basename[])
{
	decl String:description[64];
	Format(description, sizeof(description), "%T", "GetRegenerate", LANG_SERVER, hp);
	
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
		if (STAMM_IsClientVip(client, v_level) && STAMM_WantClientFeature(client))
		{
			if (ClientTimers[client] != INVALID_HANDLE) KillTimer(ClientTimers[client]);
			
			ClientTimers[client] = CreateTimer(1.0, GiveHealth, client, TIMER_REPEAT);
		}
	}
}

public Action:GiveHealth(Handle:timer, any:client)
{
	if (STAMM_IsClientValid(client))
	{
		if (STAMM_IsClientVip(client, v_level) && STAMM_WantClientFeature(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3))
		{
			new maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
			new oldHP = GetClientHealth(client);
			new newHP = oldHP + hp;
			
			if (newHP > maxHealth)
			{
				if (oldHP < maxHealth) newHP = maxHealth;
				else return Plugin_Continue;
			}
			
			SetEntityHealth(client, newHP);
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}