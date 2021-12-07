/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define VERSION ".8"

new NumberIncaps = 0;
new Float:IncapScoreLoss;
new Handle:MaxIncaps;
new Handle:SurvivalPoints;
new Handle:l4d1score;
new Handle:TieBreakerBonus;

public Plugin:myinfo = 
{
	name = "Roadkill's Competive Scoring l4d2",
	author = "Roadkill",
	description = "Changes scoring system for more competive games, closer to l4d1 style.  Maxium of half your score is based on incaps",
	version = "VERSION",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("rk_compscore_version", VERSION, "Tells you the version", FCVAR_PLUGIN|FCVAR_NOTIFY);
	TieBreakerBonus = CreateConVar("l4d2_TiePoints", "100", "Sets the tiebreaker score value", FCVAR_PLUGIN|FCVAR_NOTIFY);
	l4d1score = CreateConVar("CompScoring_enable", "1", "Enables the Plugin", FCVAR_PLUGIN|FCVAR_NOTIFY);
	SurvivalPoints = CreateConVar("l4d2_SurvivalPoints", "100", "Sets the maxium score per survivors alive at the end of the round", FCVAR_PLUGIN|FCVAR_NOTIFY);
	MaxIncaps = CreateConVar("l4d2_NumIncaps", "8", "Set the number of incaps you can have until you have no survival bonus", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig(true, "rkCompScoring");
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action:Event_RoundStart(Handle:event, const String:Name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d1score) == 1)
	{
		SetConVarFloat(FindConVar("vs_survival_bonus"), GetConVarFloat(SurvivalPoints));
		SetConVarFloat(FindConVar("vs_tiebreak_bonus"), GetConVarFloat(TieBreakerBonus));
		IncapScoreLoss = GetConVarFloat(SurvivalPoints)/GetConVarFloat(MaxIncaps);
		NumberIncaps = 0;
	}
}

public Action:Event_PlayerIncap(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(NumberIncaps < GetConVarInt(MaxIncaps) && GetConVarInt(l4d1score) == 1)
	{
		NumberIncaps++;
		SetConVarFloat(FindConVar("vs_survival_bonus"), ((GetConVarFloat(MaxIncaps)-NumberIncaps)*IncapScoreLoss));
	}
}