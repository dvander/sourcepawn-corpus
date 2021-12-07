#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2] Bots Fix",
	author = "BHaType",
	description = "Disallow bots reviev survivor while them take damage",
	version = "0.0.0",
	url = "N/A"
}

Handle sdkStopBeingRevievd;

public void OnPluginStart()
{	
	Handle hGameConf = LoadGameConfigFile("l4d2_bots_fix_gamedata");
	
	StartPrepSDKCall(SDKCall_Player);
	if (PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorPlayer::StopBeingRevived") == false)
		SetFailState("Bad siganture \"CTerrorPlayer::StopBeingRevived\"");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByRef);
	sdkStopBeingRevievd = EndPrepSDKCall();
	if (sdkStopBeingRevievd == null)	
		SetFailState("Null handle");
		
	HookEvent("player_hurt", eEvent);
}

public Action eEvent (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client || !IsClientInGame(client) || !IsFakeClient(client) || !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
		return;
		
	SDKCall(sdkStopBeingRevievd, client, true);
}