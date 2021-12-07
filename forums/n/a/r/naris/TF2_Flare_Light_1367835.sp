#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define MAX_ENTITIES 2097152

new Handle:g_hEnabled;

new g_iFlare[MAX_ENTITIES] = -1;
new g_iColors[2][3] = {{255, 0, 0}, {0, 0, 255}};

public Plugin:myinfo = {
    name = "[TF2] Flare Light",
    author = "Leonardo", // based on Mecha the Slag's Ignite Light
    description = "Adds dynamic lighting to the Pyro's flares",
    version = PLUGIN_VERSION,
    url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	decl String:strModName[32];
	GetGameFolderName(strModName, sizeof(strModName));
	if(!StrEqual(strModName, "tf"))
		SetFailState("This plugin is only for Team Fortress 2.");
	CreateConVar("flarelight_version", PLUGIN_VERSION, "Flare Light version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("flarelight_enable", "1", "Enable/disable the Flare Light plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	for(new iEntity = (MaxClients+1); iEntity < MAX_ENTITIES; iEntity++)
		if(g_iFlare[iEntity] != -1)
		{
			new iLightEntity = EntRefToEntIndex(g_iFlare[iEntity]);
			if(IsLightEntity(iLightEntity))
				RemoveEdict(iLightEntity);
			g_iFlare[iEntity] = -1;
		}
}

public OnMapStart()
{
	for(new iEntity = (MaxClients+1); iEntity < MAX_ENTITIES; iEntity++)
		if(g_iFlare[iEntity] != -1)
		{
			new iLightEntity = EntRefToEntIndex(g_iFlare[iEntity]);
			if(IsLightEntity(iLightEntity))
				RemoveEdict(iLightEntity);
			g_iFlare[iEntity] = -1;
		}
}

public OnEntityCreated(iEntity, const String:sClassName[])
{
	if(g_hEnabled)
		if(StrEqual("tf_projectile_flare", sClassName))
			if(g_iFlare[iEntity] == -1)
				CreateTimer(0.05, Timer_EntitySpawned, EntIndexToEntRef(iEntity));
}

public Action:Timer_EntitySpawned(Handle:hTimer, any:iEntRef)
{
	new iEntity = EntRefToEntIndex(iEntRef);
	if(IsValidEntity(iEntity))
	{
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(iClient) && !IsEntLimitReached(.message="unable to create light_dynamic"))
		{
			new iLightEntity = CreateLightEntity(iEntity);
			if(IsLightEntity(iLightEntity))
				g_iFlare[iEntity] = EntIndexToEntRef(iLightEntity);
		}
	}
	return Plugin_Handled;
}

public OnEntityDestroyed(iEntity)
{
	if(g_iFlare[iEntity] != -1)
	{
		new iLightEntity = EntRefToEntIndex(g_iFlare[iEntity]);
		if(IsLightEntity(iLightEntity))
			RemoveEdict(iLightEntity);
		g_iFlare[iEntity] = -1;
	}
}

stock _:CreateLightEntity(iEntity)
{
	if (!IsValidEntity(iEntity))
	{
		PrintToChatAll("Invalid Entity");
		return -1;
	}
	
	decl iTeam;
	iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum");
	if(iTeam<2 || iTeam>3)
	{
		PrintToChatAll("Invalid TeamNum (%i)", iTeam);
		return -1;
	}
	
	new iLightEntity = CreateEntityByName("light_dynamic");
	if (IsValidEntity(iLightEntity))
	{
		decl String:sColors[16];
		Format(sColors, sizeof(sColors), "%i %i %i 50", g_iColors[iTeam-2][0], g_iColors[iTeam-2][1], g_iColors[iTeam-2][2]);
		
		DispatchKeyValue(iLightEntity, "inner_cone", "0");
		DispatchKeyValue(iLightEntity, "cone", "80");
		DispatchKeyValue(iLightEntity, "brightness", "6");
		DispatchKeyValueFloat(iLightEntity, "spotlight_radius", 225.0);
		DispatchKeyValueFloat(iLightEntity, "distance", 350.0);
		DispatchKeyValue(iLightEntity, "_light", sColors);
		DispatchKeyValue(iLightEntity, "pitch", "-90");
		DispatchKeyValue(iLightEntity, "style", "5");
		DispatchSpawn(iLightEntity);

		decl Float:fOrigin[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fOrigin);
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

stock bool:IsLightEntity(iEntity)
{
	if(iEntity>0)
	{
		if(IsValidEdict(iEntity))
		{
			decl String:strClassname[32];
			GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "light_dynamic", false))
				return true;
		}
	}
	return false;
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

/**
 * Description: Function to check the entity limit.
 *              Use before spawning an entity.
 */
#tryinclude <entlimit>
#if !defined _entlimit_included
    stock bool:IsEntLimitReached(warn=20,critical=16,client=0,const String:message[]="")
    {
	return (EntitiesAvailable(warn,critical,client,message) < warn);
    }

    stock EntitiesAvailable(warn=20,critical=16,client=0,const String:message[]="")
    {
	new max = GetMaxEntities();
	new count = GetEntityCount();
	new remaining = max - count;
	if (remaining <= critical)
	{
	    PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
	    LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

	    if (client > 0)
	    {
		PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s",
			       count, max, remaining, message);
	    }
	}
	else if (remaining <= warn)
	{
	    PrintToServer("Caution: Entity count is getting high!");
	    LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

	    if (client > 0)
	    {
		PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s",
			       count, max, remaining, message);
	    }
	}
	return remaining;
    }
#endif
/*****************************************************************/

