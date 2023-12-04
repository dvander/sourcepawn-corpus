#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo=
{
	name = "WitchLight",
	author = "BHaType (Fork by Fragokas)",
	description = "Неплохое улучшения визуализации глаз вичек.",
	version = "0.0.8.6",
	url = "https://steamcommunity.com/id/fallinourblood/"
};

/*
	0.0.8.6
	 - Witch precaching is returned back, because I have an info it can crash the server (strange?).

	0.0.8.5
	 - Two different colors are not mixed now
	 - Added entity render color (just for tagging current color of witch light for another plugin)

	0.0.8.4
	 - Added check for valid witch entity.
	 - Removed unused "beam_spotlight" entity creation.
	 - Removed model precaching. Why do I need this?
	 - Removed unused stock.

	0.0.8.3
	 - Removed ConVars, removed alpha because it is not suitable.
	 - Added color random by special scheme (previous version with HDRColorScale 0.6 is too bright).
	 - Converted to methodmaps.

*/

int g_iLight[3];
//bool g_bFirstMap;

public void OnMapStart()
{
	if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
	if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
	//g_bFirstMap = IsFirstMap();
}

public void OnPluginStart()
{
	HookEvent("witch_spawn", hWitchSpawned);
}

public void hWitchSpawned(Event event, const char[] name, bool dontBroadcast)
{
	//if (!g_bFirstMap)
	//	return;

	int Witch = event.GetInt("witchid");
	if (Witch && IsValidEntity(Witch)) {
	
		float flOrigin[3], flAngles[3];

		GetEntPropVector(Witch, Prop_Send, "m_vecOrigin", flOrigin);
		GetEntPropVector(Witch, Prop_Send, "m_angRotation", flAngles);
		
		int color[3];
		
		color[0] = GetRandomInt(50, 100);
		color[1] = GetRandomInt(50, 100);
		color[2] = GetRandomInt(50, 100);
		
		color[GetRandomInt(0,2)] = GetRandomInt(100, 140);
		color[GetRandomInt(0,2)] = 0;
		
		SetEntityRenderColor(Witch, color[0], color[1], color[2], 255);
		
		for (int iLight = 0; iLight < 2; iLight++)
		{
			vLightProp(Witch, iLight, flOrigin, flAngles, color);
		}
	}
}

static void vLightProp(int Witch, int light, float origin[3], float angles[3], int color[3])
{
	g_iLight[light] = CreateEntityByName("beam_spotlight");
	DispatchKeyValueVector(g_iLight[light], "origin", origin);
	DispatchKeyValueVector(g_iLight[light], "angles", angles);
	SetEntityRenderColor(g_iLight[light], color[0], color[1], color[2], 255);
	DispatchKeyValue(g_iLight[light], "spotlightwidth", "10");
	DispatchKeyValue(g_iLight[light], "spotlightlength", "120");
	DispatchKeyValue(g_iLight[light], "spawnflags", "3");
	DispatchKeyValue(g_iLight[light], "maxspeed", "100");
	DispatchKeyValue(g_iLight[light], "HDRColorScale", "0.6");
	DispatchKeyValue(g_iLight[light], "fadescale", "1");
	DispatchKeyValue(g_iLight[light], "fademindist", "-1");
	
	vSetEntityParent(g_iLight[light], Witch);
	
	switch (light)
	{
		case 0:
		{
			SetVariantString("reye");
			vSetVector(angles, 0.0, 0.0, 0.0);
		}
		case 1:
		{
			SetVariantString("leye");
			vSetVector(angles, 0.0, 0.0, 0.0);
		}
	}

	AcceptEntityInput(g_iLight[light], "SetParentAttachment");
	AcceptEntityInput(g_iLight[light], "Enable");
	AcceptEntityInput(g_iLight[light], "DisableCollision");

	SetEntPropEnt(g_iLight[light], Prop_Send, "m_hOwnerEntity", Witch);
	TeleportEntity(g_iLight[light], NULL_VECTOR, angles, NULL_VECTOR);
	DispatchSpawn(g_iLight[light]);
}

stock void vSetEntityParent(int entity, int parent)
{
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", parent);
}

stock void vSetVector(float target[3], float x, float y, float z)
{
	target[0] = x;
	target[1] = y;
	target[2] = z;
}

stock bool IsFirstMap()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (StrEqual(sMap, "l4d_hospital01_apartment", false) ||
		StrEqual(sMap, "l4d_garage01_alleys", false) ||
		StrEqual(sMap, "l4d_smalltown01_caves", false) ||
		StrEqual(sMap, "l4d_airport01_greenhouse", false) ||
		StrEqual(sMap, "l4d_farm01_hilltop", false) ||
		StrEqual(sMap, "l4d_river01_docks", false)) {
	
		return true;
	}
	return false;
	
}