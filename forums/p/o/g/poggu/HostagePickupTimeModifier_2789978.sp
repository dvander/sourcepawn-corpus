#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar g_cvPickupDefuserTime;
ConVar g_cvPickupTime;

public Plugin myinfo =
{
	name = "Hostage Pickup Time Modifier",
	author = "Poggu",
	description = "Changes the hostage pickup time with 2 convars",
	version = "1.0"
};

public void OnPluginStart()
{
	// I recommend not using lower decimal numbers, e.g. 3.1, 3.2, 3.3 as the progress bar line will start in a weird position
	// due to how the plugin accounts for the float precision
	g_cvPickupTime = CreateConVar("hptm_time", "4.0", "Determines how long it takes to pick up a hostage without a defuser.", _, true, 0.0, true, 16.0);
	g_cvPickupDefuserTime = CreateConVar("hptm_defuserTime", "1.0", "Determines how long it takes to pick up with a defuser.", _, true, 0.0, true, 16.0);

	int hostageEnt = -1;
	while((hostageEnt = FindEntityByClassname(hostageEnt, "hostage_entity")) != -1)
	{
		SDKHook(hostageEnt, SDKHook_UsePost, OnHostageUsed);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "hostage_entity"))
	{
		SDKHook(entity, SDKHook_UsePost, OnHostageUsed);
	}
}

public void OnHostageUsed(int entity, int activator, int caller, UseType type, float value)
{
	if(!IsValidClient(activator)) return;

	float gameTime = GetGameTime();
	float fProgressTime = (HasClientDefuser(activator) ? g_cvPickupDefuserTime.FloatValue : g_cvPickupTime.FloatValue);
	int iProgressTime = RoundToCeil(fProgressTime);

	SetEntProp(activator, Prop_Send, "m_iProgressBarDuration", iProgressTime);
	SetEntPropFloat(activator, Prop_Send, "m_flProgressBarStartTime", gameTime - (iProgressTime - fProgressTime)); // Be float accurate
	SetEntPropFloat(entity, Prop_Send, "m_flGrabSuccessTime", gameTime + fProgressTime);
}

// IsClientInGame would be sufficent but would throw errors on non-client indices.
stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool HasClientDefuser(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bHasDefuser");
}