#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

new Handle:sm_ctf_powerplay = INVALID_HANDLE;
new Handle:tf_ctf_bonus_time = INVALID_HANDLE;
new Handle:tf_flag_caps_per_round = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "CTF PowerPlay Boost",
	author = "spidEY",
	description = "Replaces the standard critical bonus in CTF with PowerPlay",
	version = "1.0.2",
	url = "http://spideyworks.com/"
};

public OnPluginStart()
{
	sm_ctf_powerplay = CreateConVar("sm_ctf_powerplay", "1", "Turns PowerPlay bonus in CTF games on or off.", _, true, 0.0, true, 1.0);
	
	tf_ctf_bonus_time = FindConVar("tf_ctf_bonus_time");
	tf_flag_caps_per_round = FindConVar("tf_flag_caps_per_round");

	HookEvent("ctf_flag_captured", OnFlagCapture);
}

public Action:OnFlagCapture(Handle:event, const String:name[], bool:dontBroadcast)
{
	new CappingTeam = GetEventInt(event, "capping_team");
	new CappingTeamScore = GetEventInt(event, "capping_team_score");

	if (GetConVarInt(tf_ctf_bonus_time) == 0 || CappingTeamScore == GetConVarInt(tf_flag_caps_per_round) || GetConVarInt(sm_ctf_powerplay) == 0)
	{
		return Plugin_Continue;
	}

	new ClientCount = GetClientCount();

	for (new i = 1; i <= ClientCount; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CappingTeam)
		{
			continue;
		}

		TF2_SetPlayerPowerPlay(i, true);
	}

	CreateTimer(float(GetConVarInt(tf_ctf_bonus_time)), DisablePowerPlay, CappingTeam);

	return Plugin_Continue;
}

public Action:DisablePowerPlay(Handle:timer, any:CappingTeam)
{
	new ClientCount = GetClientCount();

	for (new i = 1; i <= ClientCount; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || GetClientTeam(i) != CappingTeam)
		{
			continue;
		}

		TF2_SetPlayerPowerPlay(i, false);
	}
}