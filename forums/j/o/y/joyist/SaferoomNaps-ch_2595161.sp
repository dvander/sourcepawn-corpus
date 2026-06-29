#pragma semicolon 1
#include <sourcemod>
#include <sdktools_sound>
#define PLUGIN_VERSION "1.0" 


public Plugin:myinfo = 
{
	name = "Saferoom Naps: Spawn Next Map With 50 HP",
	author = "ConnerRia",
	description = "Prevent metagaming in harder gamemodes. If you have less than 50hp, spawn in saferooms with 50hp. ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306348"
}

int iSurvivorRespawnHealth, iCustomSaferoomHealth, iUseCustomValue, iRemoveBlackAndWhite, iHealthToSet;
ConVar hUseCustomValue, hCustomSaferoomHealth, hRemoveBlackAndWhite, hTempHealthMultiplier, hVeryHealthyTempHealthMultiplier;
float fTempHealthMultiplier, fCurrentBufferHealth, fVeryHealthyTempHealthMultiplier;

public void OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{		
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	
	CreateConVar("SafeRoomNaps_Version", PLUGIN_VERSION, "SafeRoomNaps Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	hUseCustomValue = CreateConVar("SafeRoomNaps_CanWeUseCustomValue", "0", "如果您想输入自己的saferoom hp值，请设置为1。 否则使用z_survivor_respawn_health值。 默认情况下禁用.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hCustomSaferoomHealth = CreateConVar("SafeRoomNaps_CustomSaferoomHealth", "50", "除非启用hUseCustomValue，否则不使用。 如果您的健康状况低于设定值，则将在下一张地图加载时将其修改为该值. ", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hRemoveBlackAndWhite = CreateConVar("SafeRoomNaps_RemoveBlackAndWhite", "1.0", "是否消除玩家的黑白。 设置为0可禁用此功能. ", FCVAR_NOTIFY|FCVAR_REPLICATED);
	hTempHealthMultiplier = CreateConVar("SafeRoomNaps_TempHealthMultiplier", "0.0", "缓冲健康的乘数（从瘫痪复苏，止痛片，肾上腺素）来保持低健康水平。默认值为0.0，这意味着临时健康没保存。值为1表示所有缓冲区的健康状况保持不变. ", FCVAR_NOTIFY|FCVAR_REPLICATED);	
	hVeryHealthyTempHealthMultiplier = CreateConVar("SafeRoomNaps_VeryHealthyTempHealthMultiplier", "1.0", "缓冲健康的倍率，以保持那些没有被感染的高健康运动员。(超过50个真正的hp或设置的saferoom健康值)。默认值是1.0，这意味着所有的临时状态都保持不变.", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	AutoExecConfig(true, "SaferoomNaps");
	
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Pre);
	
}

public Action: Event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast) 
{	

	iCustomSaferoomHealth = hCustomSaferoomHealth.IntValue;
	iUseCustomValue = hUseCustomValue.IntValue;
	iSurvivorRespawnHealth = FindConVar("z_survivor_respawn_health").IntValue;
	iRemoveBlackAndWhite = hRemoveBlackAndWhite.IntValue;
	fTempHealthMultiplier = hTempHealthMultiplier.FloatValue;
	fVeryHealthyTempHealthMultiplier = hVeryHealthyTempHealthMultiplier.FloatValue;
	
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
			SetEntProp(i, Prop_Send, "m_iHideHUD", 64);
			if (iRemoveBlackAndWhite == 1)
			{
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(i, SNDCHAN_AUTO, "player/heartbeatloop.wav");
			}
			if (GetClientHealth(i) < iHealthToSet) 
			{
				fCurrentBufferHealth = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
				SetEntPropFloat(i, Prop_Send, "m_healthBuffer", fCurrentBufferHealth * fTempHealthMultiplier);
				SetEntityHealth(i, iHealthToSet);
			}
			else
			{
				fCurrentBufferHealth = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
				SetEntPropFloat(i, Prop_Send, "m_healthBuffer", fCurrentBufferHealth * fVeryHealthyTempHealthMultiplier);
			}	
		}
	}
}

