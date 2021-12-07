#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define TONEMAP_CLASS "env_tonemap_controller"
#define WIND_CLASS "env_wind"

public Plugin:myinfo = 
{
	name = "SCRAP THE TONEMAP COMING FROM ANOTHER MAP: RAP (NOW WITH MORE CRAP)",
	author = "Crimson Jimson, the Handsome Ransom",
	description = "I believe it defaults lighting so your eyes ain't burnty - also wind, also shine",
	version = "1.3",
	url = "http://www.billyandthebazingos.com"
};

public OnPluginStart()
{
	HookEvent("announce_phase_end", ResetValues);
	HookEvent("round_prestart", PrepareEntities);
}


public OnEntityCreated(entity, const String:className[])
{
	SDKHook(entity, SDKHook_SpawnPost, MakeEntityGlow);
}

public MakeEntityGlow(entity)
{
	if (!IsValidEdict(entity)) return;

	new String:name[32];
	GetEdictClassname(entity, name, sizeof(name));
	if (StrContains(name, "prop_dynamic", false) != -1 || StrContains(name, "chicken", false) != -1)
	{
		if (GetEntPropFloat(entity, Prop_Send, "m_flGlowMaxDist") == 0.0)
			DispatchKeyValueFloat(entity, "glowdist", 5120.0);
	}
}

public Action:ResetValues(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check for a tonemap controller, leave if there is an unnamed one
	int tonemap = FindEntityByClassname(-1, TONEMAP_CLASS);
	if(tonemap != -1) SetDefaultToneValues(tonemap);

	// Check for wind, leave if there's nothing
	int wind = FindEntityByClassname(-1, WIND_CLASS);
	if(wind != -1) SetDefaultWindValues(wind);
	return Plugin_Handled;
}

public Action:PrepareEntities(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Run through all entities and set the glow distance property on dynamic props and chickens
	int entity = 65;
	
	while (entity < GetMaxEntities())
	{
		MakeEntityGlow(entity);
		entity++;
	}
	return Plugin_Handled;
}

public SetDefaultToneValues(any:tonemap)
{
	// Fire outputs setting the default
	FireOutput(tonemap, "SetTonemapMinAvgLum", "3");
	FireOutput(tonemap, "SetAutoExposureMin", "0.5");
	FireOutput(tonemap, "SetAutoExposureMax", "2");
	FireOutput(tonemap, "SetBloomScale", "1");
	FireOutput(tonemap, "SetTonemapRate", "1");
	FireOutput(tonemap, "BlendTonemapScale", "1");
	FireOutput(tonemap, "SetBloomExponent", "2.5");
	FireOutput(tonemap, "SetBloomSaturation", "1.0");
	FireOutput(tonemap, "SetTonemapPercentBrightPixels", "1");
}


public SetDefaultWindValues(any:wind)
{
	// Fire outputs setting the default
	FireOutput(wind, "AddOutput", "maxgust 0");
	FireOutput(wind, "AddOutput", "mingust 0");
	FireOutput(wind, "AddOutput", "maxwind 0");
	FireOutput(wind, "AddOutput", "minwind 0");
}

public FireOutput(int ent, const String:input[], const String:arg[])
{
	SetVariantString(arg);
	AcceptEntityInput(ent, input);
}