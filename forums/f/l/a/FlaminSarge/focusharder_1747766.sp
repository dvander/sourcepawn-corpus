#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define REPLAY_PAUSE "replay/enterperformancemode.wav"
#define REPLAY_RESUME "replay/exitperformancemode.wav"

#define PLUGIN_NAME		"[TF2] Focus Harder"
#define PLUGIN_AUTHOR		"FlaminSarge"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"http://forums.alliedmods.net/"

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description	= PLUGIN_NAME,
	version		= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
};
public OnMapStart()
{
	PrecacheSound(REPLAY_PAUSE, true);
	PrecacheSound(REPLAY_RESUME, true);
}
public OnPluginStart()
{
	CreateConVar("focusharder_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_PLUGIN);
}
public TF2_OnConditionAdded(client, TFCond:cond)
{
	if (IsFakeClient(client)) return;
	if (_:cond == 46 && TF2_IsPlayerInCondition(client, TFCond_Zoomed))
	{
		EmitSoundToClient(client, REPLAY_PAUSE);
		EmitSoundToClient(client, REPLAY_PAUSE);
		FadeClientVolume(client, 80.0, 2.2, 200.0, 2.2);
	}
	else if (cond == TFCond_Zoomed && TF2_IsPlayerInCondition(client, TFCond:46))
	{
		FadeClientVolume(client, 80.0, 0.2, 200.0, 0.2);
	}
}
public TF2_OnConditionRemoved(client, TFCond:cond)
{
	if (IsFakeClient(client)) return;
	if (_:cond == 46)
	{
		FadeClientVolume(client, 0.0, 0.8, 200.0, 0.8);
		if (IsPlayerAlive(client))
		{
			EmitSoundToClient(client, REPLAY_RESUME);
			EmitSoundToClient(client, REPLAY_RESUME);
		}
	}
	else if (cond == TFCond_Zoomed && TF2_IsPlayerInCondition(client, TFCond:46))
	{
		FadeClientVolume(client, 0.0, 0.2, 0.0, 0.2);
	}
}