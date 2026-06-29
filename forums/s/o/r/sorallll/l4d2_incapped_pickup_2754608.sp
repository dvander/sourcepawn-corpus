#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME			"[L4D2] Incapped Pickup Items"
#define PLUGIN_AUTHOR		"xZk"
#define PLUGIN_DESCRIPTION	"incapped survivors can pickup items and weapons"
#define PLUGIN_VERSION		"1.3.1"
#define PLUGIN_URL			"https://forums.alliedmods.net/showthread.php?t=320828"
#define GAMEDATA			"l4d2_incapped_pickup"

Handle
	g_hSDK_Call_FindUseEntity;

ConVar
	g_hUseRadius;

float
	g_fUseRadius;

bool
	g_bIsOnUse[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	vLoadGameData();

	g_hUseRadius = CreateConVar("incapped_use_radius", "192.0", "Use Radius");
	g_hUseRadius.AddChangeHook(vConVarChanged);
}

public void OnConfigsExecuted()
{
	vGetCvars();
}

public void vConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	vGetCvars();
}

void vGetCvars()
{
	g_fUseRadius = g_hUseRadius.FloatValue;
}

public void OnClientDisconnect_Post(int client)
{
	g_bIsOnUse[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsFakeClient(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || !GetEntProp(client, Prop_Send, "m_isIncapacitated") || GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || bIsPlayerCapped(client))
		return Plugin_Continue;

	if(buttons & IN_USE != 0 && !g_bIsOnUse[client])
	{
		g_bIsOnUse[client] = true;
		int iUseEntity = iFindUseEntity(client, g_fUseRadius);
		if(iUseEntity > MaxClients && IsValidEntity(iUseEntity))
		{
			int iOwner = GetEntPropEnt(iUseEntity, Prop_Data, "m_hOwnerEntity");
			if(iOwner == client || iOwner == -1)
				AcceptEntityInput(iUseEntity, "Use", client, iUseEntity);
		}
	}
	else if(buttons & IN_USE == 0 && g_bIsOnUse[client])
		g_bIsOnUse[client] = false;

	return Plugin_Continue;
}

bool bIsPlayerCapped(int client)
{	
	if(GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_carryAttacker") > 0)
		return true;
	if(GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0)
		return true;

	return false;
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorPlayer::FindUseEntity") == false)
		SetFailState("Failed to find offset: CTerrorPlayer::FindUseEntity");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDK_Call_FindUseEntity = EndPrepSDKCall();
	if(g_hSDK_Call_FindUseEntity == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::FindUseEntity");

	delete hGameData;
}

int iFindUseEntity(int client, float fUseRadius)
{
	return SDKCall(g_hSDK_Call_FindUseEntity, client, fUseRadius, 0.0, 0.0, false, false);
}