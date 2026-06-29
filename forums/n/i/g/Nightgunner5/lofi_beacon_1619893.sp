#pragma semicolon 1

#include <sourcemod>
#include <clients>
#include <sdktools_functions>
#include <sdktools_engine>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <events>

public Plugin:myinfo =
{
	name = "Lo-Fi Beacon",
	author = "Nightgunner5 (Chris Cats)",
	description = "Make a beacon on Lo-Fi Longwaves when a KritzKast episode is being recorded",
	version = "0.1.1",
	url = "http://steamcommunity.com/id/nightgunner5"
};

new g_KnownHats[MAXPLAYERS + 1] = { -1, ... };

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_EquipItem,  EventHookMode_Post);
}

new g_BeamSprite = -1;
new g_HaloSprite = -1;
new g_BeaconColor[4] = {255, 128, 0, 192};
public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	CreateTimer(2.5, Timer_CheckLoFi, INVALID_HANDLE, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Event_EquipItem(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userId = GetEventInt(event, "userid");
	new clientId = GetClientOfUserId(userId);
	g_KnownHats[clientId] = -1;

	new entId = -1;
	while ((entId = FindEntityByClassname(entId, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(entId, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(entId, Prop_Send, "m_iItemDefinitionIndex");
			if (idx == 470 && GetEntPropEnt(entId, Prop_Send, "m_hOwnerEntity") == clientId)
			{
				g_KnownHats[userId] = entId;
				break;
			}
		}
	}

	return Plugin_Continue;
}

bool:isShowRecording()
{
	decl String:current[8];
	decl String:known[8];
	FormatTime(current, sizeof(current), "%w_%H", GetTime());
	FormatTime(known, sizeof(known), "%w_%H", 1324839600);
	return StrEqual(current, known);
}

public Action:Timer_CheckLoFi(Handle:timer)
{
	if (!isShowRecording())
		return Plugin_Continue;

	for (new i = 0; i <= MAXPLAYERS; i++)
	{
		if (g_KnownHats[i] == -1)
			continue;
		if (!IsValidEntity(g_KnownHats[i]))
		{
			g_KnownHats[i] = -1;
			continue;
		}
		new Float:vec[3];
		GetClientEyePosition(GetClientOfUserId(i), vec);
		vec[2] += 8.0;
		TE_SetupBeamRingPoint(vec, 0.01, 24.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, g_BeaconColor, 10, 0);
		TE_SendToAll();
	}

	return Plugin_Continue;
}
