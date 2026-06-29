#include <zombiereloaded>
#include <sdktools>
#include <sendproxy>

new DontPickTeams = false;
new DontPickTeams_2 = false;
new DefaultTeam[MAXPLAYERS+1] = 0;
new Float:StartHealth[MAXPLAYERS+1] = 0.0;
new PlayerManager;

new Handle:zrt_dead
new zr_dead = 0;

new Handle:zrt_team
new zr_team = 0;

public Plugin:myinfo = 
{
	name = "[CS:S & ZR] Yellow Team",
	author = "Oshizu",
	description = "After infection players will keep same teams while zombies will be moved into yellow team...",
	version = "1.0",
	url = "http://www.sourcemod.net"
}


public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Pre)
	HookEvent("round_start", ResetTeams, EventHookMode_Post)
	HookEvent("round_end", ResetTeams_End, EventHookMode_Post)
	
	zr_dead = 0;
	
	zrt_dead = CreateConVar("zr_zombies_show_as_dead", "0", "- Should game show zombie players status as dead on scoreboard? If set to 1 then it will disable showing zombies on radar too.")
	HookConVarChange(zrt_dead, OnConVarChanged)
	
	zr_team = 1; 
	
	zrt_team = CreateConVar("zr_zombies_team", "1", "- Zombie Team Presets. 0 - Zombies will shown on scoreboard on same team they were before 1 - Zombies won't be shown on scoreboard and dead players wont be shown in spectator scoreboard.")
	HookConVarChange(zrt_team, OnConVarChanged_Team)
}

public OnConfigsExecuted()
{
	zr_dead = GetConVarInt(zrt_dead)
	zr_team = GetConVarInt(zrt_team)
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	zr_dead = StringToInt(newValue)
}

public OnConVarChanged_Team(Handle:convar, const String:oldValue[], const String:newValue[])
{
	zr_team = StringToInt(newValue)
}

public OnClientPutInServer(client) 
{ 
	DefaultTeam[client] = 0;
	SendProxy_HookArrayProp(PlayerManager, "m_iTeam", client, Prop_Int, SendProxy_TeamNumber_HUD);
	SendProxy_HookArrayProp(PlayerManager, "m_bAlive", client, Prop_Int, SendProxy_TeamNumber_Alive);
	SendProxy_HookArrayProp(PlayerManager, "m_bPlayerSpotted", client, Prop_Int, SendProxy_ShowPlayer);
	SendProxy_Hook(client, "m_iTeamNum", Prop_Int, SendProxy_TeamNumber);
	SendProxy_Hook(client, "m_ArmorValue", Prop_Int, SendProxy_ArmorValue);
}

public OnMapStart()
{
	DontPickTeams = false;
	DontPickTeams_2 = false;
	PlayerManager = FindEntityByClassname(-1, "cs_player_manager");
	if(PlayerManager == -1)
	{
		new entity = CreateEntityByName("cs_player_manager");
		DispatchSpawn(entity);
		PlayerManager = entity;
	}
}
 
//public OnGameFrame()
//{
//	if(PlayerManager != -1)
//	{
//		for(new i = 1; i <= MaxClients; i++)
//		{
//			SetEntProp(PlayerManager, Prop_Send, "m_iPlayerVIP", i)
//		}
//	}
//}

public Action:ResetTeams(Handle:event, const String:name[], bool:dontBroadcast)
{
	DontPickTeams_2 = false;
//	DontPickTeams = false;
}

public Action:ResetTeams_End(Handle:event, const String:name[], bool:dontBroadcast)
{
//	DontPickTeams_2 = false;
	DontPickTeams = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!DontPickTeams)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		DefaultTeam[client] = GetClientTeam(client);
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(motherInfect) 
	{
		DontPickTeams = true;
		DontPickTeams_2 = true;
	}
	StartHealth[client] = float(GetClientHealth(client))
	SetEntProp(client, Prop_Send, "m_iHideHUD", ( 1<<4 ));
}

public Action:SendProxy_ArmorValue(entity, const String:propname[], &iValue, element)
{
	if(GetClientTeam(entity) == 2)
	{
		iValue = RoundFloat(float(GetClientHealth(entity))/StartHealth[entity]*100.0);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:SendProxy_TeamNumber_Alive(entity, const String:propname[], &iValue, element)
{
	if(IsClientInGame(element) && IsPlayerAlive(element))
	{
		if(ZR_IsClientZombie(element) && zr_dead)
		{
			iValue = 0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:SendProxy_TeamNumber_HUD(entity, const String:propname[], &iValue, element)
{
	if(!zr_team)
	{
		if(IsClientInGame(element) && !IsPlayerAlive(element))
		{
			iValue = 1;
			return Plugin_Changed;
		}
	
		if(DefaultTeam[element] > 1)
			iValue = DefaultTeam[element];
	}
	else
	{
		if(DefaultTeam[element] > 1)
			iValue = DefaultTeam[element];
		
		if(IsClientInGame(element) && GetClientTeam(element) == 2)
		{
			if(DontPickTeams_2)
				iValue = -4;
		}
	}
	return Plugin_Changed;
}

public Action:SendProxy_ShowPlayer(entity, const String:propname[], &iValue, element)
{
	if(IsClientInGame(element) && IsPlayerAlive(element) && ZR_IsClientHuman(element))
	{
		iValue = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action:SendProxy_TeamNumber(entity, const String:propname[], &iValue, element)
{
	new team = GetClientTeam(entity);
	if(team == 3)
	{
		if(DefaultTeam[entity] > 1)
			iValue = DefaultTeam[entity];
	}
	else if(team == 2)
	{
		if(DontPickTeams_2)
			iValue = -4;
	}
	return Plugin_Changed;
}