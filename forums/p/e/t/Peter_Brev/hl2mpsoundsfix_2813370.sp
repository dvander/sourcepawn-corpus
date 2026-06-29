/******************************
COMPILE OPTIONS
******************************/

#pragma semicolon 1
#pragma newdecls required

/******************************
NECESSARY INCLUDES
******************************/

#include <sourcemod>
#include <sdktools>

/******************************
PLUGIN DEFINES
******************************/

/*Setting static strings*/
static const char
	/*Plugin Info*/
	PL_NAME[]		   = "Additional HL2MP Fixes",
	PL_AUTHOR[]		   = "Peter Brev",
	PL_DESCRIPTION[]   = "Additional HL2MP Fixes",
	PL_VERSION[]	   = "1.0.0";

/******************************
PLUGIN STRINGS
******************************/
char g_sWepSnds[8][75] = {
	"weapons/crossbow/bolt_load1.wav",
	"weapons/crossbow/bolt_load2.wav",
	"weapons/physcannon/physcannon_claws_close.wav",
	"weapons/physcannon/physcannon_claws_open.wav",
	"weapons/physcannon/physcannon_tooheavy.wav",
	"weapons/physcannon/physcannon_pickup.wav",
	"weapons/physcannon/physcannon_drop.wav",
	"weapons/physcannon/hold_loop.wav"
};

/******************************
PLUGIN FLOATS
******************************/
float gfVolume = 1.0;

/******************************
PLUGIN INFO
******************************/
public Plugin myinfo =
{
	name		= PL_NAME,
	author		= PL_AUTHOR,
	description = PL_DESCRIPTION,
	version		= PL_VERSION
};

/******************************
INITIALIZE PLUGIN
******************************/
public void OnPluginStart()
{
	AddNormalSoundHook(OnSound);
	AddNormalSoundHook(OnSoundGravGunClose);
	AddNormalSoundHook(OnSoundGravGunOpen);
	AddNormalSoundHook(OnSoundGravGunPull);
	AddNormalSoundHook(OnSoundGravGunPickUp);
	AddNormalSoundHook(OnSoundGravGunDrop);
	AddNormalSoundHook(OnSoundGravGunHold);
	AddNormalSoundHook(OnSoundGrenadeThrow);

	for (int i = 1; i < sizeof(g_sWepSnds); i++)
	{
		PrecacheSound(g_sWepSnds[i]);
	}
}

public void OnMapStart()
{
	for (int i = 1; i < sizeof(g_sWepSnds); i++)
	{
		PrecacheSound(g_sWepSnds[i]);
	}
}

/******************************
PLUGIN FUNCTIONS
******************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) return Plugin_Handled;

	/*if (!IsPlayerAlive(client)) //Disabled for now, due to players not being able to spawn with scripts tied to +use
	{
		if ((buttons & IN_USE) == IN_USE)
		{
			return Plugin_Handled;
		}
	}*/
	return Plugin_Continue;
}

public Action OnSound(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/crossbow/bolt_load", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/crossbow/bolt_load%i.wav", GetRandomInt(1, 2));
	}

	if (StrContains(sSample, "weapons/crossbow/bolt_load", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunClose(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/physcannon_claws_close", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_close.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/physcannon_claws_close", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunOpen(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/physcannon_claws_open", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_open.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/physcannon_claws_open", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunPull(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/physcannon_tooheavy", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_tooheavy.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/physcannon_tooheavy", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunPickUp(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/physcannon_pickup", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_pickup.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/physcannon_pickup", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunDrop(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/physcannon_drop", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_drop.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/physcannon_drop", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGravGunHold(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/physcannon/hold_loop", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/hold_loop.wav");
	}

	if (StrContains(sSample, "weapons/physcannon/hold_loop", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}

public Action OnSoundGrenadeThrow(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (StrContains(sSample, "weapons/slam/throw", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/slam/throw.wav");
	}

	if (StrContains(sSample, "weapons/slam/throw.wav", false) == -1)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Changed;
}