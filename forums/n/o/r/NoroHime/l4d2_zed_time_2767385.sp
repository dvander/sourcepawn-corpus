#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

new Handle:Enable;
new Handle:TeamRestrict;
new Handle:ZedInfectedchance;
new Handle:ZedSurvivorchance;
new Handle:ZedPipeChance;
new Handle:ZedExplosionChance;
new Handle:ZedModes;
new Handle:ZedTank;
new Handle:ZedWitch;
new Handle:ZedTimer;
new Handle:ZedAmazing;
new Handle:ZedCharger;
new Handle:ZedSmoker;
new Handle:ZedJockey;
new Handle:ZedHunter;
new Handle:ZedBoomer;
new Handle:ZedMaxAliveHuman;
new Handle:ZedHeadshotMultiplier;

static const String:Sound1[] = "./ui/menu_countdown.wav";

new bool:ZedTimeGoing;

public Plugin:myinfo = 
{
	name = "[L4D2] Zed Time",
	author = "McFlurry & NoroHime",
	description = "Zed Time like Killing Floor.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	CreateNative("ZedTime", Native_ZedTime);
	return APLRes_Success; 
}

public int Native_ZedTime(Handle plugin, int numParams)
{
	bool isDetect = GetNativeCell(1);
	ZedTime(isDetect);
	return 0;
}


public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	CreateConVar("l4d2_zed_time_version", PLUGIN_VERSION, "Version of Zed Time", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enable = CreateConVar("l4d2_zed_time_enable", "1", "Zed Time enable", FCVAR_NOTIFY);
	ZedSurvivorchance = CreateConVar("l4d2_zed_surv_chance", "40", "1 in chance of a survivor triggering Zed Time", FCVAR_NOTIFY);
	ZedInfectedchance = CreateConVar("l4d2_zed_infct_chance", "20", "1 in chance of a infected triggering Zed Time", FCVAR_NOTIFY);
	ZedPipeChance = CreateConVar("l4d2_zed_pipe_chance", "10", "1 in chance of a pipe bomb explosion triggering Zed Time", FCVAR_NOTIFY);
	ZedExplosionChance = CreateConVar("l4d2_zed_boomer_explosion_chance", "10", "1 in chance of an exploding boomer triggering Zed Time", FCVAR_NOTIFY);
	TeamRestrict = CreateConVar("l4d2_zed_restrict", "1", "Restrict Zed Time to team 1(survivors), 2(infected), or 3(allow all teams)", FCVAR_NOTIFY);
	ZedModes = CreateConVar("l4d2_zed_modes", "coop,versus,realism,teamversus", "Which modes should this plugin be enabled in?", FCVAR_NOTIFY);
	ZedWitch = CreateConVar("l4d2_zed_witch", "10", "Witch Zed time chance when killed", FCVAR_NOTIFY);
	ZedAmazing = CreateConVar("l4d2_zed_extreme_shot", "150", "The distance required to increase the chance of Zed time happening on a kill.", FCVAR_NOTIFY);
	ZedTank = CreateConVar("l4d2_zed_tank", "2", "Tank Zed time chance when killed", FCVAR_NOTIFY);
	ZedTimer = CreateConVar("l4d2_zed_timer", "1.0", "How long time stays slowed down.", FCVAR_NOTIFY);
	ZedCharger = CreateConVar("l4d2_zed_charger", "1", "Enable Zed time for Chargers?", FCVAR_NOTIFY);
	ZedSmoker = CreateConVar("l4d2_zed_smoker", "1", "Enable Zed time for Smokers?", FCVAR_NOTIFY);
	ZedJockey = CreateConVar("l4d2_zed_jockey", "1", "Enable Zed time for Jockeys?", FCVAR_NOTIFY);
	ZedHunter = CreateConVar("l4d2_zed_hunter", "1", "Enable Zed time for Hunters?", FCVAR_NOTIFY);
	ZedBoomer = CreateConVar("l4d2_zed_boomer", "1", "Enable Zed time for Boomers?", FCVAR_NOTIFY);
	ZedMaxAliveHuman = CreateConVar("l4d2_zed_max_alive_human", "4", "trigger Zed time when alive human equal or less", FCVAR_NOTIFY);
	ZedHeadshotMultiplier = CreateConVar("l4d2_zed_headshot_multiplier_chance", "1.5", "chance of headshot multiplier", FCVAR_NOTIFY);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("melee_kill", Event_Melee);
	HookEvent("tank_killed", Event_TankDeath);
	HookEvent("witch_killed", Event_WitchDeath);
	HookEvent("hegrenade_detonate", Event_PipeExplode);
	AutoExecConfig(true, "l4d2_zed_time");
}	

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(ZedModes, gamemodeactive, sizeof(gamemodeactive));

	return (StrContains(gamemodeactive, gamemode) != -1);
}
	
public OnMapStart()
{
	PrefetchSound(Sound1);
	PrecacheSound(Sound1);
	if(!IsAllowedGameMode()) return;
	if(GetConVarInt(Enable) == 0) return;
	if(GetConVarInt(TeamRestrict) > 1)
	{
		if(GetConVarInt(ZedHunter) == 1)
		{
			HookEvent("lunge_pounce", Event_Pounce);
			HookEvent("hunter_headshot", Event_Win);
		}
		else
		{
			UnhookEvent("lunge_pounce", Event_Pounce);
			UnhookEvent("hunter_headshot", Event_Win);
		}
		if(GetConVarInt(ZedJockey) == 1)
		{
			HookEvent("jockey_ride", Event_Ride);
		}	
		else
		{
			UnhookEvent("jockey_ride", Event_Ride);
		}	
		if(GetConVarInt(ZedSmoker) == 1)
		{
			HookEvent("toungue_grab", Event_Grab);
		}
		else
		{
			UnhookEvent("toungue_grab", Event_Grab);
		}	
		if(GetConVarInt(ZedCharger) == 1)
		{
			HookEvent("charger_carry_start", Event_Charge);
			HookEvent("charger_impact", Event_Impact);
		}
		else
		{
			UnhookEvent("charger_carry_start", Event_Charge);
			UnhookEvent("charger_impact", Event_Impact);
		}
		if(GetConVarInt(ZedBoomer) == 1)
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
	if(GetConVarInt(TeamRestrict) == 2)
	{
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("melee_kill", Event_Melee);
		UnhookEvent("tank_killed", Event_TankDeath);
	}	
	ZedTimeGoing = false;
}	

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	if(GetConVarInt(Enable) == 0) return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:headshot = GetEventBool(event, "headshot");

	if(attacker && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{	
		if(GetRandomInt(1, GetConVarInt(ZedSurvivorchance)) == 1)
		{
			if(victim && IsClientInGame(victim) && GetClientTeam(victim) == 2) return;
			if(GetConVarInt(Enable) == 0) return;
			if(IsFakeClient(attacker)) return;
			if(ZedTimeGoing) return;
			ZedTime();
			FadeClientVolume(attacker, 90.0, 0.2, GetConVarFloat(ZedTimer)-0.2, 0.2);
			EmitSoundToAll(Sound1, attacker);
		}
		if(headshot)
		{
			if(GetRandomInt(1, RoundToCeil(GetConVarInt(ZedSurvivorchance) / GetConVarFloat(ZedHeadshotMultiplier))) == 1)
			{
				if(victim && IsClientInGame(victim) && GetClientTeam(victim) == 2) return;
				if(GetConVarInt(Enable) == 0) return;
				if(IsFakeClient(attacker)) return;
				if(ZedTimeGoing) return;
				ZedTime();
				EmitSoundToAll(Sound1, attacker);
			}
		}
		decl Float:pos1[3], Float:pos2[3];
		if(victim == 0) return;
		if(attacker == 0) return;
		GetClientAbsOrigin(attacker, pos1);
		GetClientAbsOrigin(victim, pos2);
		if(GetVectorDistance(pos1, pos2, false) > GetConVarInt(ZedAmazing)*16)
		{
			if(GetRandomInt(1, GetConVarInt(ZedSurvivorchance)) == 1)
			{
				if(victim && IsClientInGame(victim) && GetClientTeam(victim) == 2) return;
				if(GetConVarInt(Enable) == 0) return;
				if(IsFakeClient(attacker)) return;
				if(ZedTimeGoing) return;
				ZedTime();	
				EmitSoundToAll(Sound1, attacker);
			}
		}	
	}	
}	

public Action:Event_PipeExplode(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3) return;
	if(!IsAllowedGameMode()) return;
	if(GetRandomInt(1, GetConVarInt(ZedPipeChance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}	

public Action:Event_Explosion(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3) return;
	if(!IsAllowedGameMode()) return;
	if(GetRandomInt(1, GetConVarInt(ZedExplosionChance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}	

public Action:Event_Melee(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3) return;
	if(GetRandomInt(1, GetConVarInt(ZedSurvivorchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}	

public Action:Event_TankDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker && IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
	{
		if(GetRandomInt(1, GetConVarInt(ZedTank)) == 1)
		{
			if(GetConVarInt(Enable) == 0) return;
			if(IsFakeClient(attacker)) return;
			if(ZedTimeGoing) return;
			ZedTime(false);
			EmitSoundToAll(Sound1, attacker);
		}	
	}
}

public Action:Event_Pounce(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}

public Action:Event_Win(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventBool(event, "userid"));
	new islunging = GetClientOfUserId(GetEventBool(event, "islunging"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3) return;
	if(islunging)
	{
		if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)/10) == 1)
		{
			if(GetConVarInt(Enable) == 0) return;
			if(IsFakeClient(client)) return;
			if(ZedTimeGoing) return;
			ZedTime();
			EmitSoundToAll(Sound1, client);
		}
	}	
}

public Action:Event_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}

public Action:Event_Grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}

public Action:Event_Charge(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}

public Action:Event_Impact(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(client)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, client);
	}
}

public Action:Event_Boomed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!IsAllowedGameMode()) return;
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker && IsClientInGame(attacker) && GetClientTeam(attacker) == 2) return;
	if(GetRandomInt(1, GetConVarInt(ZedInfectedchance)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(IsFakeClient(attacker)) return;
		if(ZedTimeGoing) return;
		ZedTime();
		EmitSoundToAll(Sound1, attacker);
	}
}

public Action:Event_WitchDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client) && GetClientTeam(client) == 3) return;
	if(!IsAllowedGameMode()) return;
	new headshot = GetEventBool(event, "oneshot");
	if(headshot)
	{
		if(GetRandomInt(1, RoundToCeil(GetConVarInt(ZedWitch) / GetConVarFloat(ZedHeadshotMultiplier))) == 1)
		{
			if(GetConVarInt(Enable) == 0) return;
			if(ZedTimeGoing) return;
			ZedTime(false);
			EmitSoundToAll(Sound1, client);
		}
	}	
	if(GetRandomInt(1, GetConVarInt(ZedWitch)) == 1)
	{
		if(GetConVarInt(Enable) == 0) return;
		if(ZedTimeGoing) return;
		ZedTime(false);
		EmitSoundToAll(Sound1, client);
	}
}
		
ZedTime(bool isHumanDetect = true)
{
	if(getAliveHumanSurvivors() > GetConVarInt(ZedMaxAliveHuman) && isHumanDetect)
		return;

	ZedTimeGoing = true;
	decl i_Ent, Handle:h_pack;
	i_Ent = CreateEntityByName("func_timescale");
	DispatchKeyValue(i_Ent, "desiredTimescale", "0.2");
	DispatchKeyValue(i_Ent, "acceleration", "2.0");
	DispatchKeyValue(i_Ent, "minBlendRate", "1.0");
	DispatchKeyValue(i_Ent, "blendDeltaMultiplier", "2.0");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "Start");
	h_pack = CreateDataPack();
	WritePackCell(h_pack, i_Ent);
	CreateTimer(GetConVarFloat(ZedTimer), ZedBlendBack, h_pack);
}

public Action:ZedBlendBack(Handle:Timer, Handle:h_pack)
{
	decl i_Ent;
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
		PrintToServer("[SM] i_Ent is not a valid edict!");
	}
}

int getAliveHumanSurvivors (){
	int players = 0;
	for(int client = 1; client <= MaxClients; client++){
		if(isClient(client) && isHumanSurvivor(client) && IsPlayerAlive(client))
			players++;
	}
	return players;
}

bool isClient(int client){
	return IsClientConnected(client) && IsClientInGame(client);
}

bool isHumanSurvivor(int client){
	return !IsFakeClient(client) && GetClientTeam(client) == 2;
}