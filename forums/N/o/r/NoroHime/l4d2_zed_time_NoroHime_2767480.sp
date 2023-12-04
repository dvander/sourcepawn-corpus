#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required


#define PLUGIN_VERSION "2.0"

ConVar Enable;bool enable;
ConVar TeamRestrict;int teamRestrict;
ConVar ZedInfectedchance;int zedInfectedchance;
ConVar ZedSurvivorchance;int zedSurvivorchance;
ConVar ZedPipeChance;int zedPipeChance;
ConVar ZedExplosionChance;int zedExplosionChance;
ConVar ZedModes;bool isAllowedGameMode;
ConVar ZedTank;int zedTank;
ConVar ZedWitch;int zedWitch;
ConVar ZedTimer;float zedTimer;
ConVar ZedExtremeDistance;int zedExtremeDistance;
ConVar ZedCharger;bool zedCharger;
ConVar ZedSmoker;bool zedSmoker;
ConVar ZedJockey;bool zedJockey;
ConVar ZedHunter;bool zedHunter;
ConVar ZedBoomer;bool zedBoomer;
ConVar ZedMaxAliveHuman;int zedMaxAliveHuman;
ConVar ZedHeadshotMultiplier;float zedHeadshotMultiplier;
ConVar ZedNormalKillEnable;bool zedNormalKillEnable;
ConVar ZedHighlightKillChance;int zedHighlightKillChance;
ConVar ZedHighlightKillCount;int zedHighlightKillCount;
ConVar ZedHighlightKillInterval;float zedHighlightKillInterval;
ConVar ZedHighlightKillRequireIncrease;float zedHighlightKillRequireIncrease;

static float TimeFirstKill[MAXPLAYERS+1];
static int CountKilled[MAXPLAYERS+1];

#define Sound "ui/menu_countdown.wav"


bool ZedTimeGoing;

public Plugin myinfo = 
{
	name = "[L4D2] Zed Time",
	author = "McFlurry & NoroHime",
	description = "Zed Time like Killing Floor.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1238319"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));

	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateNative("ZedTime", Native_ZedTime);
	return APLRes_Success; 
}

public int Native_ZedTime(Handle plugin, int numParams)
{
	bool isDetect = GetNativeCell(1);
	ZedTime(isDetect);
	return 0;
}


public void OnConfigsExecuted()
{
	ApplyCvars();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	ApplyCvars();
}


public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	ApplyCvars();
}


public void ApplyCvars(){
	enable = Enable.BoolValue;
	teamRestrict = TeamRestrict.IntValue;
	zedInfectedchance = ZedInfectedchance.IntValue;
	zedSurvivorchance = ZedSurvivorchance.IntValue;
	zedPipeChance = ZedPipeChance.IntValue;
	zedExplosionChance = ZedExplosionChance.IntValue;
	zedTank = ZedTank.IntValue;
	zedWitch = ZedWitch.IntValue;
	zedTimer = ZedTimer.FloatValue;
	zedExtremeDistance = ZedExtremeDistance.IntValue;
	zedCharger = ZedCharger.BoolValue;
	zedSmoker = ZedSmoker.BoolValue;
	zedJockey = ZedJockey.BoolValue;
	zedHunter = ZedHunter.BoolValue;
	zedBoomer = ZedBoomer.BoolValue;
	zedMaxAliveHuman = ZedMaxAliveHuman.IntValue;
	zedHeadshotMultiplier = ZedHeadshotMultiplier.FloatValue;
	zedNormalKillEnable = ZedNormalKillEnable.BoolValue;
	zedHighlightKillChance = ZedHighlightKillChance.IntValue;
	zedHighlightKillCount = ZedHighlightKillCount.IntValue;
	zedHighlightKillInterval = ZedHighlightKillInterval.FloatValue;
	zedHighlightKillRequireIncrease = ZedHighlightKillRequireIncrease.FloatValue;

	char gamemode[24], gamemodeactive[64];
	FindConVar("mp_gamemode").GetString(gamemode, sizeof(gamemode));
	ZedModes.GetString(gamemodeactive, sizeof(gamemodeactive));
	isAllowedGameMode = !~StrContains(gamemodeactive, gamemode);
}

public void OnPluginStart()
{
	
	CreateConVar("l4d2_zed_time_version", PLUGIN_VERSION, "Version of Zed Time", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable = CreateConVar("l4d2_zed_time_enable", "1", "Zed Time enable", FCVAR_NOTIFY);
	ZedSurvivorchance = CreateConVar("l4d2_zed_surv_chance", "40", "1 in chance of a survivor triggering Zed Time", FCVAR_NOTIFY);
	ZedInfectedchance = CreateConVar("l4d2_zed_infct_chance", "20", "1 in chance of a infected triggering Zed Time", FCVAR_NOTIFY);
	ZedPipeChance = CreateConVar("l4d2_zed_pipe_chance", "5", "1 in chance of a pipe bomb explosion triggering Zed Time", FCVAR_NOTIFY);
	ZedExplosionChance = CreateConVar("l4d2_zed_boomer_explosion_chance", "10", "1 in chance of an exploding boomer triggering Zed Time", FCVAR_NOTIFY);
	TeamRestrict = CreateConVar("l4d2_zed_restrict", "1", "Restrict Zed Time to team 1(survivors), 2(infected), or 3(allow all teams)", FCVAR_NOTIFY);
	ZedModes = CreateConVar("l4d2_zed_modes", "coop,versus,realism,teamversus", "Which modes should this plugin be enabled in?", FCVAR_NOTIFY);
	ZedWitch = CreateConVar("l4d2_zed_witch", "1", "Witch Zed time chance when killed", FCVAR_NOTIFY);
	ZedExtremeDistance = CreateConVar("l4d2_zed_extreme_shot", "1200", "The distance required to increase the chance of Zed time happening on a kill.", FCVAR_NOTIFY);
	ZedTank = CreateConVar("l4d2_zed_tank", "1", "Tank Zed time chance when killed", FCVAR_NOTIFY);
	ZedTimer = CreateConVar("l4d2_zed_timer", "0.67", "How long time stays slowed down.", FCVAR_NOTIFY);
	ZedCharger = CreateConVar("l4d2_zed_charger", "1", "Enable Zed time for Chargers?", FCVAR_NOTIFY);
	ZedSmoker = CreateConVar("l4d2_zed_smoker", "1", "Enable Zed time for Smokers?", FCVAR_NOTIFY);
	ZedJockey = CreateConVar("l4d2_zed_jockey", "1", "Enable Zed time for Jockeys?", FCVAR_NOTIFY);
	ZedHunter = CreateConVar("l4d2_zed_hunter", "1", "Enable Zed time for Hunters?", FCVAR_NOTIFY);
	ZedBoomer = CreateConVar("l4d2_zed_boomer", "1", "Enable Zed time for Boomers?", FCVAR_NOTIFY);
	ZedMaxAliveHuman = CreateConVar("l4d2_zed_max_alive_human", "3", "trigger Zed time when alive human equal or less", FCVAR_NOTIFY);
	ZedHeadshotMultiplier = CreateConVar("l4d2_zed_headshot_multiplier_chance", "3", "chance of headshot multiplier, 3 = 3x of surv_chance", FCVAR_NOTIFY);
	ZedNormalKillEnable = CreateConVar("l4d2_zed_normal_kill_enable", "0", "trigger enable if survivor normal kill zombies without special", FCVAR_NOTIFY);
	ZedHighlightKillChance = CreateConVar("l4d2_zed_highligh_kill_chance", "1", "1 in chance of kill multiple zombies", FCVAR_NOTIFY);
	ZedHighlightKillCount = CreateConVar("l4d2_zed_highligh_kill_count", "4", "count killed to trigger highlight ZedTime ", FCVAR_NOTIFY);
	ZedHighlightKillInterval = CreateConVar("l4d2_zed_highligh_kill_interval", "0.2", "interval(second) between killed first and killed last zombie", FCVAR_NOTIFY);
	ZedHighlightKillRequireIncrease = CreateConVar("l4d2_zed_highligh_kill_require_increase", "1.33", "how many highlight kills ZedTime trigger requirement inreases start at highligh_kill_count allow float but round\nif 7 human alive, you should one time to kill \n4+(7-3)*1.33=10.3(zombies) round to 10", FCVAR_NOTIFY);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("melee_kill", Event_Melee);
	HookEvent("tank_killed", Event_TankDeath);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("hegrenade_detonate", Event_PipeExplode);
	AutoExecConfig(true, "l4d2_zed_time");
}	


	
public void OnMapStart()
{
	PrefetchSound(Sound);
	PrecacheSound(Sound);
	if(isAllowedGameMode) return;
	if(!enable) return;
	if(GetConVarInt(TeamRestrict) > 1)
	{
		if(zedHunter)
		{
			HookEvent("lunge_pounce", Event_Pounce);
			HookEvent("hunter_headshot", Event_Win);
		}
		else
		{
			UnhookEvent("lunge_pounce", Event_Pounce);
			UnhookEvent("hunter_headshot", Event_Win);
		}
		if(zedJockey)
		{
			HookEvent("jockey_ride", Event_Ride);
		}	
		else
		{
			UnhookEvent("jockey_ride", Event_Ride);
		}	
		if(zedSmoker)
		{
			HookEvent("toungue_grab", Event_Grab);
		}
		else
		{
			UnhookEvent("toungue_grab", Event_Grab);
		}	
		if(zedCharger)
		{
			HookEvent("charger_carry_start", Event_Charge);
			HookEvent("charger_impact", Event_Impact);
		}
		else
		{
			UnhookEvent("charger_carry_start", Event_Charge);
			UnhookEvent("charger_impact", Event_Impact);
		}
		if(zedBoomer)
		{
			HookEvent("boomer_exploded", Event_Explosion);
			HookEvent("player_now_it", Event_Boomed);
		}
		else
		{
			UnhookEvent("boomer_exploded", Event_Explosion);
			UnhookEvent("player_now_it", Event_Boomed);
		}
	}	
	if(teamRestrict == 2)
	{
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("melee_kill", Event_Melee);
		UnhookEvent("tank_killed", Event_TankDeath);
	}
	ZedTimeGoing = false;
}	

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode || !enable) return Plugin_Continue;

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	bool headshot = GetEventBool(event, "headshot");

	if(!isAliveHumanSurvivor(attacker)) return Plugin_Continue;  //trigger alive human survivor only

	if(victim && IsClientInGame(victim) && GetClientTeam(victim) == 2) return Plugin_Continue; //do not victim survivor trigger

	if(attacker && isAliveHumanSurvivor(attacker)){
		float time = GetEngineTime();
		CountKilled[attacker]++;
		if(TimeFirstKill[attacker] && (time - TimeFirstKill[attacker]) < zedHighlightKillInterval){
			int aliveHumanSurvivorDiff = getAliveHumanSurvivors() - zedMaxAliveHuman;
			int requireKills = aliveHumanSurvivorDiff >= 0 ?
				(zedHighlightKillCount + RoundToNearest(aliveHumanSurvivorDiff * zedHighlightKillRequireIncrease)) :
				zedHighlightKillCount;

			// PrintToChatAll("diff: %d, required: %d, kills: %d", aliveHumanSurvivorDiff, requireKills, CountKilled[attacker]);

			if(CountKilled[attacker] >= requireKills)
				if(GetRandomInt(1, zedHighlightKillChance) == 1){
					if(ZedTimeGoing) return Plugin_Continue;

					TimeFirstKill[attacker] = time;
					CountKilled[attacker] = 0;
					ZedTime(false);
					FadeClientVolume(attacker, 90.0, 0.2, zedTimer - 0.2, 0.2);
					EmitSoundToAll(Sound, attacker);
				}

		}else{
			TimeFirstKill[attacker] = time;
			CountKilled[attacker] = 1;
		}
	}

	if(attacker && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{	
		if(zedNormalKillEnable && GetRandomInt(1, zedSurvivorchance) == 1)
		{
			if(ZedTimeGoing) return Plugin_Continue;
			ZedTime();
			FadeClientVolume(attacker, 90.0, 0.2, zedTimer - 0.2, 0.2);
			EmitSoundToAll(Sound, attacker);
		}

		if(headshot)
		{
			if(GetRandomInt(1, RoundToCeil(zedSurvivorchance / zedHeadshotMultiplier)) == 1)
			{
				if(ZedTimeGoing) return Plugin_Continue;
				ZedTime();
				EmitSoundToAll(Sound, attacker);
			}
		}

		float pos1[3], pos2[3];
		if(!victim || attacker) return Plugin_Continue;
		GetClientAbsOrigin(attacker, pos1);
		GetClientAbsOrigin(victim, pos2);

		if(GetVectorDistance(pos1, pos2, false) > zedExtremeDistance)
		{
			if(GetRandomInt(1, zedSurvivorchance) == 1)
			{
				if(ZedTimeGoing) return Plugin_Continue;
				ZedTime();	
				EmitSoundToAll(Sound, attacker);
			}
		}
	}
	return Plugin_Continue;
}	

public Action Event_PipeExplode(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInfected(client)) return Plugin_Continue;
	if(isAllowedGameMode) return Plugin_Continue;
	if(GetRandomInt(1, zedPipeChance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Explosion(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInfected(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedExplosionChance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}	

public Action Event_Melee(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInfected(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedSurvivorchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_TankDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(GetRandomInt(1, zedTank) == 1)
	{
		if(!enable || ZedTimeGoing) return Plugin_Continue;
		ZedTime(false);
		EmitSoundToAll(Sound, attacker);
	}
	return Plugin_Continue;
}

public Action Event_Pounce(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isSurvivor(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Win(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventBool(event, "userid"));
	int islunging = GetClientOfUserId(GetEventBool(event, "islunging"));
	if(isInfected(client)) return Plugin_Continue;
	if(islunging)
	{
		if(GetRandomInt(1, zedInfectedchance / 10) == 1)
		{
			if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
			ZedTime();
			EmitSoundToAll(Sound, client);
		}
	}	
	return Plugin_Continue;
}

public Action Event_Ride(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isSurvivor(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Grab(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isSurvivor(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Charge(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isSurvivor(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Impact(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isSurvivor(client)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(client) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}

public Action Event_Boomed(Event event, const char[] name, bool dontBroadcast)
{
	if(isAllowedGameMode) return Plugin_Continue;
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(isSurvivor(attacker)) return Plugin_Continue;
	if(GetRandomInt(1, zedInfectedchance) == 1)
	{
		if(!enable || IsFakeClient(attacker) || ZedTimeGoing) return Plugin_Continue;
		ZedTime();
		EmitSoundToAll(Sound, attacker);
	}
	return Plugin_Continue;
}

public Action Event_WitchDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(isInfected(client)) return Plugin_Continue;
	if(isAllowedGameMode) return Plugin_Continue;
	bool headshot = GetEventBool(event, "oneshot");
	if(headshot)
	{
		if(GetRandomInt(1, RoundToCeil(zedWitch / zedHeadshotMultiplier)) == 1)
		{
			if(!enable || ZedTimeGoing) return Plugin_Continue;
			ZedTime(false);
			EmitSoundToAll(Sound, client);
		}
	}	
	if(GetRandomInt(1, zedWitch) == 1)
	{
		if(!enable || ZedTimeGoing) return Plugin_Continue;
		ZedTime(false);
		EmitSoundToAll(Sound, client);
	}
	return Plugin_Continue;
}
		
void ZedTime(bool isHumanDetect = true)
{
	if(getAliveHumanSurvivors() > zedMaxAliveHuman && isHumanDetect)
		return;

	ZedTimeGoing = true;
	any i_Ent;
	DataPack h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(i_Ent, "desiredTimescale", "0.2");
	DispatchKeyValue(i_Ent, "acceleration", "2.0");
	DispatchKeyValue(i_Ent, "minBlendRate", "1.0");
	DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "2.0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	CreateTimer(zedTimer, ZedBlendBack, h_pack);
}

public Action ZedBlendBack(Handle Timer, DataPack h_pack)
{
	any i_Ent;
	ResetPack(h_pack, false);
	i_Ent = ReadPackCell(h_pack);
	CloseHandle(h_pack);
	if(IsValidEdict(i_Ent))
	{
		AcceptEntityInput(i_Ent, "Stop");
		ZedTimeGoing = false;
	}
	else
	{
		PrintToServer("[ZedTime] i_Ent is not a valid edict!");
	}
	return Plugin_Continue;
}

int getAliveHumanSurvivors (){
	int players = 0;
	for(int client = 1; client <= MaxClients; client++){
		if(isAliveHumanSurvivor(client))
			players++;
	}
	return players;
}
bool isAliveHumanSurvivor(int client){
	return client && isClient(client) && isHumanSurvivor(client) && IsPlayerAlive(client);
}

bool isClient(int client){
	return client && IsClientConnected(client) && IsClientInGame(client);
}

bool isHumanSurvivor(int client){
	return client && !IsFakeClient(client) && GetClientTeam(client) == 2;
}

bool isSurvivor(int client){
	return client && !IsClientConnected(client) && GetClientTeam(client) == 2;
}
bool isInfected(int client){
	return client && !IsClientConnected(client) && GetClientTeam(client) == 3;
}