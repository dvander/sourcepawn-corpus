#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define CONSISTENCY_CHECK 1.0
#define PLUGIN_VERSION "1.5.4"
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

new Handle:SpawnTimer = INVALID_HANDLE;
new Handle:KickTimer = INVALID_HANDLE;
new Handle:SurvivorLimit = INVALID_HANDLE;
new Handle:InfectedLimit = INVALID_HANDLE;
new Handle:L4DSurvivorLimit = INVALID_HANDLE;
new Handle:L4DInfectedLimit = INVALID_HANDLE;
new bool:Useful[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Super Versus",
	author = "DDRKhat",
	description = "Allows Versus To Maximize Both Team Limits.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=92713"
};

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));
	if(!StrEqual(ModName, "left4dead", false) && !StrEqual(ModName, "left4dead2", false))
	{
		SetFailState("[SV] Plugin Supports L4D and L4D2 Only!");
	}
	
	CreateConVar("super_versus_version", PLUGIN_VERSION, "Super Versus Version", CVAR_FLAGS);
	
	L4DSurvivorLimit = FindConVar("survivor_limit");
	L4DInfectedLimit = FindConVar("z_max_player_zombies");
	
	SurvivorLimit = CreateConVar("super_versus_survivor_limit", "13", "Maximum Amount of Survivors", CVAR_FLAGS, true, 4.00, true, 13.00);
	InfectedLimit = CreateConVar("super_versus_infected_limit", "13", "Maximum Amount of Infected", CVAR_FLAGS, true, 4.00, true, 13.00);
	
	SetConVarBounds(L4DSurvivorLimit, ConVarBound_Upper, true, 13.0);
	SetConVarBounds(L4DInfectedLimit, ConVarBound_Upper, true, 13.0);
	HookConVarChange(L4DSurvivorLimit, FSL);
	HookConVarChange(SurvivorLimit, FSL);
	HookConVarChange(L4DInfectedLimit, FIL);
	HookConVarChange(InfectedLimit, FIL);
	
	RegConsoleCmd("sm_jointeam3", JoinInfTeam, "Join Infected Team");
	RegConsoleCmd("sm_infected", JoinInfTeam, "Join Infected Team");
	RegConsoleCmd("sm_survivors", JoinSurTeam, "Join Survivors Team");
	RegConsoleCmd("sm_jointeam2", JoinSurTeam, "Join Survivors Team");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("heal_begin", OnUsefulBegin);
	HookEvent("heal_end", OnUsefulEnd);
	HookEvent("revive_begin", OnUsefulBegin);
	HookEvent("revive_end", OnUsefulEnd);
	HookEvent("finale_vehicle_leaving", OnFinaleVehicleLeaving);
	
	AutoExecConfig(true, "super_versus");
}

public FSL(Handle:c, const String:o[], const String:n[])
{
	SetConVarInt(L4DSurvivorLimit, GetConVarInt(SurvivorLimit), true, false);
}

public FIL(Handle:c, const String:o[], const String:n[])
{
	SetConVarInt(L4DInfectedLimit, GetConVarInt(InfectedLimit), true, false);
}

public OnMapEnd()
{
	if (SpawnTimer != INVALID_HANDLE)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
	}
	
	if (KickTimer != INVALID_HANDLE)
	{
		KillTimer(KickTimer);
		KickTimer = INVALID_HANDLE;
	}
}

public Action:JoinInfTeam(client, args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		PrintToConsole(client, "[JBTP] In-Game Command Only!");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) == 3)
	{
		PrintHintText(client, "[JBTP] Already In Infected Team!");
	}
	else
	{
		ChangeClientTeam(client, 3);
		PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Infected Team\x01!", client);
	}
	return Plugin_Handled;
}

public Action:JoinSurTeam(client, args)
{
	if (client <= 0 || !IsClientInGame(client))
	{
		PrintToConsole(client, "[JBTP] In-Game Command Only!");
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) == 2)
	{
		PrintHintText(client, "[JBTP] Already In Survivors Team!");
	}
	else
	{
		ChangeClientTeam(client, 2);
		PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Survivors Team\x01!", client);
	}
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	if (SpawnTimer == INVALID_HANDLE && TeamPlayers(2) < GetConVarInt(SurvivorLimit))
	{
		SpawnTimer = CreateTimer(CONSISTENCY_CHECK, SpawnTick, _, TIMER_REPEAT);
	}
	
	if (KickTimer == INVALID_HANDLE && TeamPlayers(2) > GetConVarInt(SurvivorLimit))
	{
		KickTimer = CreateTimer(CONSISTENCY_CHECK, KickTick, _, TIMER_REPEAT);
	}
}

public TeamPlayers(any:team)
{
	new players = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team)
		{
			continue;
		}
		
		players++;
	}
	
	return players;
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			CreateTimer(0.1, KickFakeClient, i);
		}
	}
}

SpawnFakeClient()
{
	new Bot = CreateFakeClient("SurvivorBot");
	if (Bot == 0)
	{
		return;
	}
	
	ChangeClientTeam(Bot, 2);
	DispatchKeyValue(Bot, "classname", "SurvivorBot");
	
	CreateTimer(0.1, KickFakeClient, Bot);
}

public Action:SpawnTick(Handle:hTimer, any:Junk)
{
	new NumSurvivors = TeamPlayers(2);
	if (NumSurvivors < 4)
	{
		KillTimer(SpawnTimer);
		SpawnTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new MaxSurvivors = GetConVarInt(SurvivorLimit);
	for (; NumSurvivors < MaxSurvivors; NumSurvivors++)
	{
		SpawnFakeClient();
	}
	
	KillTimer(SpawnTimer);
	SpawnTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:KickTick(Handle:hTimer, any:Junk)
{
	new NumSurvivors = TeamPlayers(2);
	if (NumSurvivors < 4)
	{
		KillTimer(KickTimer);
		KickTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new MaxSurvivors = GetConVarInt(SurvivorLimit);
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && IsUseless(i) && NumSurvivors > MaxSurvivors)
		{
			CreateTimer(0.0, KickFakeClient, i);
			NumSurvivors--;
		}
	}
	
	KillTimer(KickTimer);
	KickTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:KickFakeClient(Handle:hTimer, any:Client)
{
	if (!IsClientConnected(Client))
	{
		return Plugin_Stop;
	}
	
	KickClient(Client, "Kicked Fake Client!");
	return Plugin_Stop;
}

bool:IsUseless(client)
{
	if(!Useful[client])
	{
		return true;
	}
	
	return false;
}

public Action:OnFinaleVehicleLeaving(Handle:event, const String:name[], bool:dontBroadcast)
{
	new edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
	{
		decl Float:pos[3];
		GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
		for (new i=1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
			{
				continue;
			}
			
			TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

public Action:OnUsefulBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer) || GetClientTeam(healer) != 2)
	{
		return;
	}
	
	Useful[healer] = true;
	
	new healed = GetClientOfUserId(GetEventInt(event, "subject"));
	if (healed <= 0 || healed > MaxClients || !IsClientInGame(healed) || GetClientTeam(healed) != 2)
	{
		return;
	}
	
	Useful[healed] = true;
}

public Action:OnUsefulEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (healer <= 0 || healer > MaxClients || !IsClientInGame(healer) || GetClientTeam(healer) != 2)
	{
		return;
	}
	
	Useful[healer] = false;
	
	new healed = GetClientOfUserId(GetEventInt(event, "subject"));
	if (healed <= 0 || healed > MaxClients || !IsClientInGame(healed) || GetClientTeam(healed) != 2)
	{
		return;
	}
	
	Useful[healed] = false;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (SpawnTimer == INVALID_HANDLE && TeamPlayers(2) < GetConVarInt(SurvivorLimit))
	{
		SpawnTimer = CreateTimer(CONSISTENCY_CHECK, SpawnTick, _, TIMER_REPEAT);
	}
	
	if (KickTimer == INVALID_HANDLE && TeamPlayers(2) > GetConVarInt(SurvivorLimit))
	{
		KickTimer = CreateTimer(CONSISTENCY_CHECK, KickTick, _, TIMER_REPEAT);
	}
}

