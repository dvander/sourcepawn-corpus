#pragma semicolon 1
#include <sourcemod>
#include <sdktools_sound>
#include <sethealthstock>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.1"
public Plugin:myinfo =
{
	name = "[L4D1]Saferoom HP Restore",
	author = "ConnerRia, Dragokas, KoMiKoZa edited by Re:Creator",
	description = "Prevent metagaming in harder gamemodes. If you have less than 50hp, spawn in saferooms with 50hp. ",
	version = PLUGIN_VERSION,
}
int iSurvivorRespawnHealth, iCustomSaferoomHealth, iUseCustomValue, iRemoveBlackAndWhite, iHealthToSet;
ConVar hUseCustomValue, hCustomSaferoomHealth, hRemoveBlackAndWhite;
public void OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	CreateConVar("hpr_version", PLUGIN_VERSION, "Saferoom HP Restore version", FCVAR_PROTECTED|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	hUseCustomValue = CreateConVar("hpr_customvalue", "1", "Set to 1 if you want to input your own saferoom hp value. Uses the z_survivor_respawn_health value otherwise. Disabled by default.", FCVAR_PROTECTED|FCVAR_REPLICATED);
	hCustomSaferoomHealth = CreateConVar("hpr_customhealth", "50", "Not used unless hUseCustomValue is enabled. If your health is lower than the set value, it will be modified to that value when the next map loads. ", FCVAR_PROTECTED|FCVAR_REPLICATED);
	hRemoveBlackAndWhite = CreateConVar("hpr_removebw", "1.0", "Whether to remove black-and-white from players. Set to 0 to disable this feature. ", FCVAR_PROTECTED|FCVAR_REPLICATED);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
}
public Action: Event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	iCustomSaferoomHealth = hCustomSaferoomHealth.IntValue;
	iUseCustomValue = hUseCustomValue.IntValue;
	iSurvivorRespawnHealth = FindConVar("z_survivor_respawn_health").IntValue;
	iRemoveBlackAndWhite = hRemoveBlackAndWhite.IntValue;
	if (iUseCustomValue == 1)
	{
		iHealthToSet = iCustomSaferoomHealth;
	}
	else
	{
		iHealthToSet = iSurvivorRespawnHealth;
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetClientTeam(i) == 2)
		{
			if (GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
			{
				SetEntProp(i, Prop_Send, "m_isIncapacitated", 0);
				SetHealth(i, iHealthToSet);
			}
			if (GetClientHealth(i) < iHealthToSet)
			{
				SetHealth(i, iHealthToSet);
			}
			if (iRemoveBlackAndWhite == 1)
			{
				SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
				SetEntProp(i, Prop_Send, "m_iHideHUD", 64);
				SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
				StopSound(i, SNDCHAN_AUTO, "player/heartbeatloop.wav");
			}
			
		}
	}
}