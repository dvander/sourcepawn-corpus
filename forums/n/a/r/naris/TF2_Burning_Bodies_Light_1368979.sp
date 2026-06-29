#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#tryinclude <entlimit>

#define PLUGIN_VERSION "1.0"

new Handle:g_hEnabled;
new g_iOffsetPlayerCond = -1;

new g_iBody[MAXPLAYERS+1] = -1;

public Plugin:myinfo = {
    name = "[TF2] Burning Bodies Light",
    author = "Leonardo", // based on Mecha the Slag's Ignite Light
    description = "Adds dynamic lighting to a burning players",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:strModName[32];
	GetGameFolderName(strModName, sizeof(strModName));
	if(!StrEqual(strModName, "tf"))
		SetFailState("This plugin is only for Team Fortress 2.");
	CreateConVar("bodylight_version", PLUGIN_VERSION, "Burning Bodies Light version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("bodylight_enable", "1", "Enable/disable the Burning Bodies Light plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_iOffsetPlayerCond = FindSendPropInfo("CTFPlayer", "m_nPlayerCond");
	if(g_iOffsetPlayerCond<=0)
		SetFailState("Offset CTFPlayer::m_nPlayerCond isn't available");
}

public OnMapStart()
{
	for(new iClient = 0; iClient <= MAXPLAYERS; iClient++)
		g_iBody[iClient] = -1;
}

public OnGameFrame()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient) && (GetEntData(iClient, g_iOffsetPlayerCond) & TF_CONDFLAG_ONFIRE)==TF_CONDFLAG_ONFIRE && GetConVarBool(g_hEnabled))
		{
			if(g_iBody[iClient] == -1)
			{
				new iLightEntity = CreateLightEntity(iClient);
				if(iLightEntity > 0)
					g_iBody[iClient] = EntIndexToEntRef(iLightEntity);
			}
		}
		else
		{
			if(g_iBody[iClient] != -1)
			{
				new iLightEntity = EntRefToEntIndex(g_iBody[iClient]);
				if(iLightEntity > 0)
					RemoveEdict(iLightEntity);
				g_iBody[iClient] = -1;
			}
		}
}

stock _:CreateLightEntity(iEntity, bool:bRagdoll=false)
{
	if (IsEntLimitReached())
		return -1;
	
	if (!IsValidEdict(iEntity))
		return -1;
	
	new iLightEntity = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iLightEntity))
	{
		DispatchKeyValue(iLightEntity, "inner_cone", "0");
		DispatchKeyValue(iLightEntity, "cone", "80");
		DispatchKeyValue(iLightEntity, "brightness", "6");
		DispatchKeyValueFloat(iLightEntity, "spotlight_radius", 132.0);
		DispatchKeyValueFloat(iLightEntity, "distance", 225.0);
		DispatchKeyValue(iLightEntity, "_light", "255 100 10 41");
		DispatchKeyValue(iLightEntity, "pitch", "-90");
		DispatchKeyValue(iLightEntity, "style", "5");
		DispatchSpawn(iLightEntity);
		
		decl Float:fOrigin[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
        
		fOrigin[2] += 40.0;
		TeleportEntity(iLightEntity, fOrigin, NULL_VECTOR, NULL_VECTOR);

		decl String:strName[32];
		Format(strName, sizeof(strName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", strName);
				
		DispatchKeyValue(iLightEntity, "parentname", strName);
		SetVariantString("!activator");
		AcceptEntityInput(iLightEntity, "SetParent", iEntity, iLightEntity, 0);
		AcceptEntityInput(iLightEntity, "TurnOn");
	}
	return iLightEntity;
}

#if !defined _entlimit_included
stock bool:IsEntLimitReached(warn=20, critical=16, client=0, const String:message[]="entity not created")
	return EntitiesAvailable(warn, critical, client, message) < warn;

stock _:EntitiesAvailable(warn=20, critical=16, client=0, const String:message[]="entity not created")
{
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if(remaining <= critical)
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);
		if (client > 0)
			PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);
	}
	else if(remaining <= warn)
	{
		PrintToServer("Caution: Entity count is getting high!");
		LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);
		if (client > 0)
			PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);
	}
	return remaining;
}
#endif
