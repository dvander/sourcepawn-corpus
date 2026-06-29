#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Stop HintText Sound",
	author = "Tauphi, exvel",
	description = "Stops annoying HintText sound in some games based on the OrangeBox engine (CS:S, TF2, etc.). All credits for the idea about how to stop such sound goes to Tauphi.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new UserMsg:umHintText = INVALID_MESSAGE_ID;

new bool:g_bPluginEnabled = true;
new Handle:g_hPluginEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_stop_ht_sound_version", PLUGIN_VERSION, "Stop HintText Sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPluginEnabled = CreateConVar("sm_stop_ht_sound", "1", "Enabled/Disabled Stop HintText Sound functionality, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hPluginEnabled, OnCVarChange);
	
	umHintText = GetUserMessageId("HintText");
	
	if (umHintText == INVALID_MESSAGE_ID)
		SetFailState("This game doesn't support HintText");
	
	HookUserMessage(umHintText, MsgHook_HintText);
}

public Action:MsgHook_HintText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!g_bPluginEnabled)
		return;
	
	for (new i = 0; i < playersNum; i++)
	{
		if (players[i] != 0 && IsClientInGame(players[i]) && !IsFakeClient(players[i]))
		{
			StopSound(players[i], SNDCHAN_STATIC, "UI/hint.wav");
		}
	}
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	g_bPluginEnabled = GetConVarBool(g_hPluginEnabled);
}