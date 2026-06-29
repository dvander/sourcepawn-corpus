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
	PL_VERSION[]	   = "1.1.0";

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
Action OnSound(int iClients[MAXPLAYERS], int &iNumClients, char sSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &fVolume, int &iLevel, int &iPitch, int &iFlags, char sEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (iEntity < 1 || iEntity > MaxClients || !IsClientInGame(iEntity))
		return Plugin_Continue;

	if (strcmp(sSample, "weapons/crossbow/bolt_load1.wav", false) == 0 || strcmp(sSample, "weapons/crossbow/bolt_load2.wav", false) == 0)
	{
		Format(sSample, sizeof(sSample), "weapons/crossbow/bolt_load%i.wav", GetRandomInt(1, 2));
	}

	if (strcmp(sSample, "weapons/physcannon/physcannon_tooheavy.wav", false) == 0)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_tooheavy.wav");
	}

	if (strcmp(sSample, ")weapons/physcannon/physcannon_claws_close.wav", false) == 0) // No idea why it needs a closed bracket here.
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_close.wav");
	}

	if (strcmp(sSample, ")weapons/physcannon/physcannon_claws_open.wav", false) == 0) // Same thing here.
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_claws_close.wav");
	}

	if (strcmp(sSample, ")weapons/physcannon/physcannon_pickup.wav", false) == 0) // Same thing here.
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_pickup.wav");
	}

	if (StrContains(sSample, ")weapons/physcannon/physcannon_drop.wav", false) != -1)
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/physcannon_drop.wav");
	}

	if (strcmp(sSample, "weapons/physcannon/hold_loop.wav", false) == 0) // This one seems broken or not included in the sound hook. I will leave it in there in case Sourcemod gets updated with it working.
	{
		Format(sSample, sizeof(sSample), "weapons/physcannon/hold_loop.wav");
	}

	if (strcmp(sSample, "weapons/slam/throw.wav", false) == 0)
	{
		Format(sSample, sizeof(sSample), "weapons/slam/throw.wav");
	}

	if (strcmp(sSample, "weapons/physcannon/physcannon_tooheavy.wav", false) != 0 && strcmp(sSample, "weapons/slam/throw.wav", false) != 0 && 
	strcmp(sSample, "weapons/crossbow/bolt_load1.wav", false) != 0 && strcmp(sSample, "weapons/crossbow/bolt_load2.wav", false) != 0 &&
	strcmp(sSample, "weapons/physcannon/physcannon_claws_close.wav", false) != 0 &&
	strcmp(sSample, "weapons/physcannon/physcannon_claws_open.wav", false) != 0 &&
	strcmp(sSample, "weapons/physcannon/physcannon_pickup.wav", false) != 0 && 
	strcmp(sSample, "weapons/physcannon/physcannon_drop.wav", false) != 0 &&
	strcmp(sSample, "weapons/physcannon/hold_loop.wav", false) != 0)
	{
		return Plugin_Continue;
	}

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientConnected(iClient) || !IsClientInGame(iClient))
			continue;

		EmitSoundToClient(iClient, sSample, iEntity, iChannel, iLevel, iFlags, fVolume * gfVolume, iPitch);
	}

	return Plugin_Handled;
}