#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.03"

public Plugin:myinfo =
{
	name = "Explode",
	author = "Heartless",
	description = "Shiny things come out of your socks!",
	version = PLUGIN_VERSION,
	url = "http://www.badnetwork.net/"
};

public OnPluginStart()
{
	// Perform one-time startup tasks ...
	CreateConVar("sm_explode_version", PLUGIN_VERSION, "Explode version");
	RegAdminCmd("sm_explode", Command_Explode, ADMFLAG_SLAY);
}

public OnMapStart()
{
	PrecacheSound("weapons/hegrenade/explode3.wav", true);
}

public Action:Command_Explode(client, args)
{
	new Float:g_fOrigin[3];	
	new Float:g_fDir[3];
	GetClientAbsOrigin(client, g_fOrigin);
	TE_SetupSparks(g_fOrigin, g_fDir, 100, 100);
	TE_SendToAll();
	
	EmitAmbientSound("weapons/hegrenade/explode3.wav", g_fOrigin, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, 0.0);
	
	return Plugin_Handled;
}