#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.2"

new Handle:hSpawnInterval = INVALID_HANDLE;
new Handle:hTimer = INVALID_HANDLE;
new prevTime;
new flagPlugin;

public Plugin:myinfo =  
{
	name = "L4D2 ADD Special Infected",
	author = "NiCo-op",
	description = "L4D2 ADD Special Infected",
	version = PLUGIN_VERSION,
	url = "http://nico-op.forjp.net/"
};

public OnPluginStart()
{
	CreateConVar("l4d2_addsp_version",
		PLUGIN_VERSION,
		"L4D2 ADD Special Infected",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
	);

	hSpawnInterval = CreateConVar(
		"l4d2_addsp",
		"90",
		"special infected spawn interval",
		FCVAR_NOTIFY,
		true,
		5.0,
		true,
		300.0
	);
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	flagPlugin = 0;
	prevTime = GetTime();
	decl String:mode[16];
	GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
	if(!StrEqual(mode, "versus") && !StrEqual(mode, "scavenge")  ) flagPlugin = 1;

	return Plugin_Continue;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new nowTime = GetTime();
	if(!flagPlugin || nowTime - prevTime < GetConVarInt(hSpawnInterval)){
		return Plugin_Continue;
	}
	prevTime = nowTime;

	decl String:class[128];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client && IsValidEntity(client) && GetClientTeam(client) == 3){
		GetClientModel(client, class, sizeof(class));
		if(StrContains(class, "tank", false) == -1
		  && StrContains(class, "hulk", false) == -1){
			hTimer = CreateTimer(0.5, TimerInfectedSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	return Plugin_Continue;
}

public Action:TimerInfectedSpawn(Handle:timer, any:value)
{
	if(timer != hTimer) return Plugin_Stop;

	new infected = GetConVarInt(FindConVar(
		(flagPlugin == 1) ? "z_minion_limit" : "survival_max_specials"
	));
	new hunter = GetConVarInt(FindConVar("z_hunter_limit"));
	new smoker = GetConVarInt(FindConVar("z_smoker_limit"));
	new boomer = GetConVarInt(FindConVar("z_boomer_limit"));
	new jockey = GetConVarInt(FindConVar("z_jockey_limit"));
	new spitter = GetConVarInt(FindConVar("z_spitter_limit"));
	new charger = GetConVarInt(FindConVar("z_charger_limit"));
	new i = hunter + smoker + boomer + jockey + spitter + charger;
	if(infected > i) infected = i;

	new client = 0;
	i = GetMaxClients();
	decl String:class[128];
	do{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2){
			if(IsPlayerAlive(i)) client = i;
		}
		else if(IsClientConnected(i) && IsFakeClient(i) && GetClientTeam(i) == 3){
			infected--;
			GetClientModel(i, class, sizeof(class));
			if(StrContains(class, "hunter", false) != -1) hunter--;
			else if(StrContains(class, "smoker", false) != -1) smoker--;
			else if(StrContains(class, "boome", false) != -1) boomer--;
			else if(StrContains(class, "jockey", false) != -1) jockey--;
			else if(StrContains(class, "spitter", false) != -1) spitter--;
			else if(StrContains(class, "charger", false) != -1) charger--;
		}
	}while(--i > 0);
	if(!client) return Plugin_Stop;


	new zmax = GetConVarInt(FindConVar("z_max_player_zombies"));
	new limit = GetTeamClientCount(3);
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	while(limit++ < zmax && infected-- > 0){
		new bot = CreateFakeClient("Infected Bot");
		if(bot){
			ChangeClientTeam(bot, 3);
			CreateTimer(0.1, TimerKickFakeClient, bot, TIMER_FLAG_NO_MAPCHANGE);
		}
		new retry = 10;
		do{
			new type = GetRandomInt(1, 6);
			if(type == 1 && hunter-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn hunter auto"); }
			else if(type == 2 && smoker-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn smoker auto"); }
			else if(type == 3 && boomer-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn boomer auto"); }
			else if(type == 4 && jockey-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn jockey auto"); }
			else if(type == 5 && spitter-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn spitter auto"); }
			else if(type == 6 && charger-- > 0){ retry = 0; FakeClientCommand(client, "z_spawn charger auto"); }
		}while(--retry > 0);
	}
	SetCommandFlags("z_spawn", flags);
	return Plugin_Stop;
}

public Action:TimerKickFakeClient(Handle:timer, any:client)
{
	if(client && IsClientConnected(client) && IsFakeClient(client)){
		KickClient(client, "AddInfected");
	}
	return Plugin_Stop;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(flagPlugin){
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientConnected(client)
		  && IsFakeClient(client) && GetClientTeam(client) == 3){
			CreateTimer(0.1, TimerKickFakeClient, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(flagPlugin){
		new i = GetMaxClients();
		do{
			if(IsClientConnected(i)
			  && IsFakeClient(i)
			  && GetClientTeam(i) == 3){
				KickClient(i, "AddInfected");
			}
		}while(--i > 0);
	}
	return Plugin_Continue;
}
