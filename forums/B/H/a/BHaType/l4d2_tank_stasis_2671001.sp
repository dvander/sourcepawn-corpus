#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle g_hLeave;

public Plugin myinfo = 
{
	name = "[L4D2] Tank Stasis",
	author = "BHaType",
	description = "Tank leave stasis while spawn",
	version = "0.0",
	url = "SDKCall"
};


public void OnPluginStart()
{
	GameData hData = new GameData("l4d2_stasis_control");
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "Tank::LeaveStasis"))
		SetFailState("Signature set fault");
	g_hLeave = EndPrepSDKCall();
	
	HookEvent("tank_spawn", eSpawn);
}

public void eSpawn (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(2.0, tLeaveStasis, GetClientUserId(client));
}

public Action tLeaveStasis (Handle timer, int client)
{
	if ((client = GetClientOfUserId(client)) > MaxClients || !IsClientInGame(client) || !IsFakeClient(client))
		return;
		
	SDKCall(g_hLeave, client);
}