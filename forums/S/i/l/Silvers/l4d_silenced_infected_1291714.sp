#define PLUGIN_VERSION		"1.2"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D / L4D2] Silenced Infected
*	Author	:	SilverShot
*	Descp	:	Disable common, special, tank and witch sounds.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=137397
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Various optimizations and fixes.
	- Various changes to tidy up code.

1.1.1 (01-Jul-2019)
	- Var name changes. Update has no affect and is not required.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.0 (05-Sep-2010)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>


char g_sCommon[5][] =
{
	"npc/infected/action/",
	"npc/infected/alert/",
	"npc/infected/hit/",
	"npc/infected/idle/",
	"npc/infected/miss/"
};
int g_iCommonLen[sizeof(g_sCommon)];

char g_sInfected[6][] =
{
	"player/boomer/",
	"player/charger/",
	"player/hunter/",
	"player/jockey/",
	"player/smoker/",
	"player/spitter/"
};
int g_iInfectedLen[sizeof(g_sInfected)];

char g_sTank[2][] =
{
	"player/tank/attack",
	"player/tank/voice/"
};
int g_iTankLen[sizeof(g_sTank)];

char g_sWitch[1][] =
{
	"npc/witch/"
};
// int g_iWitchLen[sizeof(g_sWitch)];

ConVar g_CvarCommon, g_CvarEnable, g_CvarInfect, g_CvarTank, g_CvarWitch;
int g_iCommon, g_iInfected, g_iTank, g_iWitch;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Silenced Infected",
	author = "SilverShot",
	description = "Disable common, special, tank and witch sounds.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=137397"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Cvars
	g_CvarEnable =	CreateConVar("l4d_silenced_enable",		"1", "0=Disables plugin, 1=Enables plugin.", FCVAR_NOTIFY);
	g_CvarCommon =	CreateConVar("l4d_silenced_common",		"1", "0=Enables sounds, 1=Disables common infected sounds.", FCVAR_NOTIFY);
	g_CvarInfect =	CreateConVar("l4d_silenced_infected",	"1", "0=Enables sounds, 1=Disables special infected sounds.", FCVAR_NOTIFY);
	g_CvarTank =	CreateConVar("l4d_silenced_tank",		"1", "0=Enables sounds, 1=Disables tank sounds.", FCVAR_NOTIFY);
	g_CvarWitch =	CreateConVar("l4d_silenced_witch",		"1", "0=Enables sounds, 1=Disables witch sounds.", FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_silenced_infecetd");

	g_CvarEnable.AddChangeHook(ConVarChanged_Enable);
	g_CvarCommon.AddChangeHook(ConVarChanged_Infected);
	g_CvarInfect.AddChangeHook(ConVarChanged_Infected);
	g_CvarTank.AddChangeHook(ConVarChanged_Infected);
	g_CvarWitch.AddChangeHook(ConVarChanged_Infected);

	g_iCommon = g_CvarCommon.IntValue;
	g_iInfected = g_CvarInfect.IntValue;
	g_iTank = g_CvarTank.IntValue;
	g_iWitch = g_CvarWitch.IntValue;
	HookEvents();

	// Str Lengths
	for( int i = 0; i < sizeof(g_sCommon); i++ )
		g_iCommonLen[i] = strlen(g_sCommon[i]);

	for( int i = 0; i < sizeof(g_sInfected); i++ )
		g_iInfectedLen[i] = strlen(g_sInfected[i]);

	for( int i = 0; i < sizeof(g_sTank); i++ )
		g_iTankLen[i] = strlen(g_sTank[i]);

	// for( int i = 0; i < sizeof(g_sWitch); i++ )
		// g_iWitchLen[i] = strlen(g_sWitch[i]);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void ConVarChanged_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	if( StringToInt(newValue) > 0 )
	{
		HookEvents();
	} else {
		UnhookEvents();
	}
}

public void ConVarChanged_Infected(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCommon = g_CvarCommon.IntValue;
	g_iInfected = g_CvarInfect.IntValue;
	g_iTank = g_CvarTank.IntValue;
	g_iWitch = g_CvarWitch.IntValue;
}

void HookEvents()
{
	AddNormalSoundHook(SoundHook);
}

void UnhookEvents()
{
	RemoveNormalSoundHook(SoundHook);
}



// ====================================================================================================
//					SOUND HOOK
// ====================================================================================================
public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	// Common sounds
	if( g_iCommon == 1 && strncmp(sample, "npc/infected/", 13) == 0 )
	{
		for( int i = 0; i < sizeof(g_sCommon); i++ )
		{
			if( strncmp(sample[13], g_sCommon[i][13], g_iCommonLen[i] - 13, false) == 0 )
			{
				volume = 0.0;
				return Plugin_Changed;
			}
		}
	}

	// Infected sounds
	if( g_iInfected == 1 && strncmp(sample, "player/", 7) == 0 )
	{
		for( int i = 0; i < sizeof(g_sInfected); i++ )
		{
			if( strncmp(sample[7], g_sInfected[i][7], g_iInfectedLen[i] - 7, false) == 0 )
			{
				volume = 0.0;
				return Plugin_Changed;
			}
		}
	}

	// Tank sounds
	if( g_iTank == 1 && strncmp(sample, "player/tank/", 12) == 0 )
	{
		for( int i = 0; i < sizeof(g_sTank); i++ )
		{
			if( strncmp(sample[12], g_sTank[i][12], g_iTankLen[i] - 12, false) == 0 )
			{
				volume = 0.0;
				return Plugin_Changed;
			}
		}
	}

	// Witch sounds
	if( g_iWitch == 1 )
	{
		for( int i = 0; i < sizeof(g_sWitch); i++ )
		{
			if( strcmp(sample, g_sWitch[i], false) == 0 )
			{
				volume = 0.0;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}