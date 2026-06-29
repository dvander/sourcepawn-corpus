#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

ConVar cvPlayToSelf;
bool bCloaked[MAXPLAYERS+1];
bool bPlayToSelf;

public Plugin myinfo =
{
	name = "Cheater Detector",
	author = "cravenge (requested by SilentBr)",
	description = "Lets root admins be able to detect cheaters.",
	version = "1.2",
	url = "https://forums.alliedmods.net/forumdisplay.php?f=108"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_cdetect", OnCDCmd, ADMFLAG_ROOT, "Apply cloaking function");
	CreateConVar("cheater_detector_version", "1.2", "Cheater Detector Version", FCVAR_NOTIFY);
	cvPlayToSelf = CreateConVar("cd_play_to_self", "0", "Play own sounds to yourself?");
	cvPlayToSelf.AddChangeHook(OnCDCVarChanged);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	AddAmbientSoundHook(OnAdminASCheck);
	AddNormalSoundHook(OnAdminNSCheck);
	AutoExecConfig(true, "cheater_detector");
}

public void OnCDCVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	bPlayToSelf = cvPlayToSelf.BoolValue;
}

public Action OnCDCmd(int client, int args)
{
	if(client == 0 || !IsClientInGame(client) || GetClientTeam(client) != 3 || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}

	if(bCloaked[client])
	{
		SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit);
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, 255);
		bCloaked[client] = false;
	}

	else
	{
		bCloaked[client] = true;
		SetEntityRenderMode(client, RENDER_TRANSALPHA);
		SetEntityRenderColor(client, _, _, _, 0);
		SDKHook(client, SDKHook_SetTransmit, OnSetTransmit);
	}

	return Plugin_Handled;
}

public Action OnSetTransmit(int entity, int other)
{
	if(bIsRootAdmin(other))
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action OnAdminASCheck(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	if(!bIsInfected(entity) || !bIsRootAdmin(entity) || !bCloaked[entity])
	{
		return Plugin_Continue;
	}

	return Plugin_Stop;
}

public Action OnAdminNSCheck(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!bIsInfected(entity) || !bIsRootAdmin(entity) || !bCloaked[entity])
	{
		return Plugin_Continue;
	}

	if(!bPlayToSelf)
	{
		return Plugin_Stop;
	}

	numClients = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && bIsRootAdmin(i) && i == entity)
		{
			clients[numClients] = i;
			numClients++;
		}
	}

	return Plugin_Changed;
}

public void OnPluginEnd()
{
	cvPlayToSelf.RemoveChangeHook(OnCDCVarChanged);
	delete cvPlayToSelf;
	UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	RemoveAmbientSoundHook(OnAdminASCheck);
	RemoveNormalSoundHook(OnAdminNSCheck);
}

public void OnClientDisconnect(int client)
{
	if(!bIsRootAdmin(client) || !bCloaked[client])
	{
		return;
	}

	bCloaked[client] = false;
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmit);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int idied = GetClientOfUserId(event.GetInt("userid"));
	int ikiller = GetClientOfUserId(event.GetInt("attacker"));
	if(bIsInfected(idied) && bIsRootAdmin(idied) && bCloaked[idied] && bIsSurvivor(ikiller))
	{
		bCloaked[idied] = false;
		SDKUnhook(idied, SDKHook_SetTransmit, OnSetTransmit);
		SetEntityRenderMode(idied, RENDER_NORMAL);
		SetEntityRenderColor(idied, _, _, _, 255);
		PrintToChat(idied, "\x05[\x03CD\x05]\x04 %N\x01 killed you while you were cloaked!", ikiller);
	}

	return Plugin_Continue;
}

public void OnMapEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && bCloaked[i])
		{
			bCloaked[i] = false;
			SDKUnhook(i, SDKHook_SetTransmit, OnSetTransmit);
		}
	}
}

bool bIsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2);
}

bool bIsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 3);
}

bool bIsRootAdmin(int client)
{
	return (CheckCommandAccess(client, "sm_cdetect", ADMFLAG_ROOT, false));
}