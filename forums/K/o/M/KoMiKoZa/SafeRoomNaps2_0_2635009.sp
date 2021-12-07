#pragma semicolon 1
#include <sourcemod>
#include <sdktools_sound>
#include <sethealthstock>
#define PLUGIN_VERSION "1.0" 


public Plugin:myinfo = 
{
	name = "Saferoom Naps: Spawn Next Map With 50 HP",
	author = "ConnerRia. Fork. by Dragokas & KoMiKoZa",
	description = "Prevent metagaming in harder gamemodes. If you have less than 50hp, spawn in saferooms with 50hp. ",
	version = PLUGIN_VERSION,
	url = "N/A"
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
	
	CreateConVar("SafeRoomNaps_Version", PLUGIN_VERSION, "SafeRoomNaps Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	hUseCustomValue = CreateConVar("SafeRoomNaps_CanWeUseCustomValue", "0", "Set to 1 if you want to input your own saferoom hp value. Uses the z_survivor_respawn_health value otherwise. Disabled by default.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hCustomSaferoomHealth = CreateConVar("SafeRoomNaps_CustomSaferoomHealth", "50", "Not used unless hUseCustomValue is enabled. If your health is lower than the set value, it will be modified to that value when the next map loads. ", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hRemoveBlackAndWhite = CreateConVar("SafeRoomNaps_RemoveBlackAndWhite", "1.0", "Whether to remove black-and-white from players. Set to 0 to disable this feature. ", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AutoExecConfig(true, "SaferoomNaps 2.0");
	
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
			if (GetClientHealth(i) < iHealthToSet) 
			{
				SetHealth(i, iHealthToSet);
			}	
			if (iRemoveBlackAndWhite == 1)
			{
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(i, SNDCHAN_AUTO, "player/heartbeatloop.wav");
			}
		}
	}
}