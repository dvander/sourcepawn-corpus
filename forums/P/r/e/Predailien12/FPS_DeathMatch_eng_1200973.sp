#include <sourcemod>
#include <sdktools>
#define Version "1.0.0"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8

public Plugin:myinfo =
{
	name = "FPS 모드 - 개인전",
	author = "Rayne",
	description = "일반 FPS 게임처럼 생존자끼리 싸울 수 있습니다.",
	version = Version,
	url = ""
};

//외에..
new PlayerTeam[MAXPLAYERS+1]
//데미지 요소
new Handle:FFDmg
new Handle:FBDmg
new Handle:GKick
//콘솔 명령어ㅋ
new Handle:FZD
new Handle:FFF
new Handle:FFB
new Handle:FGK
new Handle:FRST

public OnPluginStart()
{
	CreateConVar("l4d2_FPS_DeathMatch_Version", Version, "FPS plugin version.", CVAR_FLAGS);
	
	//명령어 생성해주고..
	FFDmg = CreateConVar("FPS_FFdmg", "1.0", "The Damage by Gun. 1.0 means doubled damage.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	FBDmg = CreateConVar("FPS_FBdmg", "2.0", "The Damage by Fire. 2.0 means doubled damage.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	GKick = CreateConVar("FPS_GKick", "1", "Gun Rebound. 1 is proper", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	FRST = CreateConVar("FPS_FRST", "120.0", "How much time should be elapsed to start?", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY)
	
	//콘솔 명령어를 받자
	FZD = FindConVar("z_common_limit")
	FFF = FindConVar("survivor_friendly_fire_factor_expert")
	FFB = FindConVar("survivor_burn_factor_expert")
	FGK = FindConVar("z_gun_kick")
	
	HookEvent("player_spawn", Event_PS)
	HookEvent("player_team", Event_PT)
	HookEvent("round_start", Event_RS)
	HookEvent("mission_lost", Event_ML)
	
	AutoExecConfig(true, "L4D2_FPS_DeathMatch")
}

public OnMapStart()
{
	SetConVarString(FindConVar("z_difficulty"), "impossible")
	SetConVarString(FindConVar("mp_gamemode"), "realism")
	SetConVarInt(FZD, 0)
	SetConVarInt(FGK, GetConVarInt(GKick))
	PrintToChatAll("\x04FPS Mod \x03ON!!")
}

public Action:Event_PT(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new teamid = GetEventInt(event,"team");
	if(1 <= client <= MaxClients)
	{
		PlayerTeam[client] = teamid;
	}
}

public Action:Event_PS(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(PlayerTeam[client] == TEAM_INFECTED)
	{
		ForcePlayerSuicide(client)
	}
}

public Action:Event_RS(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	SetConVarFloat(FFF, 0.0)
	SetConVarFloat(FFB, 0.0)
	PrintToChatAll("\x03 %d \x04seconds left until the game start.", RoundToNearest(GetConVarFloat(FRST)))
	CreateTimer(GetConVarFloat(FRST), Announce, _, TIMER_REPEAT)
}

public Action:Announce(Handle:timer)
{
	PrintToChatAll("\x04It's TIME To WAR!!")
	SetConVarFloat(FFF, GetConVarFloat(FFDmg))
	SetConVarFloat(FFB, GetConVarFloat(FBDmg))
	
	return Plugin_Stop
}

public Action:Event_ML(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	SetConVarFloat(FFF, 0.0)
	SetConVarFloat(FFB, 0.0)
	CreateTimer(GetConVarFloat(FRST), Announce, _, TIMER_REPEAT)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
