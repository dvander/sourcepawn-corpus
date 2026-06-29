#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Block Flashlight Sound",
	author = "iDragon",
	description = "Block the dammned flashlight sound!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_block_flashlight_sound_version", PLUGIN_VERSION, "Block flashlight sound Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddNormalSoundHook(StopFlashLightSound);
}

public Action:StopFlashLightSound(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (StrEqual(sample, "items/flashlight1.wav", false))
		return Plugin_Stop;
	
	return Plugin_Continue;
} 