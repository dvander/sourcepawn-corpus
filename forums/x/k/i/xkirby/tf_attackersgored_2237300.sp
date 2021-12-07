#pragma semicolon 1

// Includes
#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

// Defines
#define AVD_VERSION "1.0"

// Plugin Info
public Plugin:myinfo =
{
	name = "[TF2 CTF]Attackers Go Red",
	author = "X Kirby",
	description = "RED tries to Cap while BLU Defends in this custom gamemode!",
	version = AVD_VERSION,
	url = "http://www.sourcemod.net/",
}

// Handles
new Handle:avd_ver;
new Handle:avd_TimeLimit;

// On Plugin Start
public OnPluginStart()
{
	avd_ver = CreateConVar("avd_version", AVD_VERSION, "Version cvar.", FCVAR_NOTIFY);
	avd_TimeLimit = CreateConVar("tf_avd_timelimit", "15", "How many minutes in a match of AVD.");
	
	SetConVarString(avd_ver, AVD_VERSION);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("teamplay_waiting_ends", Event_RoundStart);
}

// On Player Spawn
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	switch(GetClientTeam(client))
	{
		case 2: PrintCenterText(client, "RED Attacks! Go grab the Intel!");
		case 3: PrintCenterText(client, "BLU Defends! Protect the Intel!");
	}
}

// On Map Start
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get Current Map Type
	new String:mapname[256];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if(StrContains(mapname, "ctf", false) >= 0)
	{
		// Create New Timer
		new ent = FindEntityByClassname(ent, "team_round_timer");
		if(ent == -1)
		{
			ent = CreateEntityByName("team_round_timer");
		}
		DispatchSpawn(ent);
		SetVariantInt(GetConVarInt(avd_TimeLimit)*60);
		AcceptEntityInput(ent, "SetTime");
		SetVariantInt(1);
		AcceptEntityInput(ent, "ShowInHUD");
		AcceptEntityInput(ent, "Enable");
		HookSingleEntityOutput(ent, "OnFinished", OnRoundTimerEnd);
		
		// Remove RED Team's Flag
		new flag = -1;
		while((flag = FindEntityByClassname(flag, "item_teamflag")) != -1)
		{
			if(GetEntProp(flag, Prop_Data, "m_iInitialTeamNum") == 2)
			{
				AcceptEntityInput(flag, "Kill");
			}
		}
	}
}

// Copied straight out of VSH. Sorry.
public OnRoundTimerEnd(const String:output[], caller, activator, Float:delay)
{
	ForceTeamWin(3);
}

public ForceTeamWin(team)
{
	new ent = FindEntityByClassname(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}