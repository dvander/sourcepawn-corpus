#include <sourcemod>
#include <psyrtd>

#define PLUGIN_NAME "[psyRTD] Example Module"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESC "[psyRTD] Example Module for mucho exampleness"

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "YOUR NAME",
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = "YOUR WEBSITE"
}

new g_iMyEffectId = -1;

public OnPluginLoad()
{
	CreateConVar("myawesomeeffectpack_version", PLUGIN_VERSION, PLUGIN_DESC, FCVAR_PLUGIN|FCVAR_NOTIFY);
}

public OnAllPluginsLoaded()
{
	if (!LibraryExists("psyrtd"))
	{
		SetFailState("psyRTD Not Found!");
	}
	g_iMyEffectId = psyRTD_RegisterEffect(psyRTDEffectType_Bad, "My Effect's Name", MyEffectCallback);
	// if you're feeling nice, you can also make "good" effects with psyRTDEffectType_Good
}

public OnPluginUnload()
{
	if (g_iMyEffectId > -1)
	{
		psyRTD_UnregisterEffect(g_iMyEffectId, psyRTDEffectType_Bad);
	}
}

public psyRTDAction:MyEffectCallback(client)
{
	if (psyRTD_GetGame() == psyRTDGame_FOF)
	{
		// No one plays this game so I didn't test it.
		// Let the core re-roll and choose another effect.
		return psyRTD_Reroll;
	}
	
	// Our actual effect, or perhaps even the start of a timer for one that lasts
	PrintToChat(client, "EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM!\nEXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM!\nEXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM! EXAMPLE EFFECT SPAMMM!");
	
	return psyRTD_Continue;
}