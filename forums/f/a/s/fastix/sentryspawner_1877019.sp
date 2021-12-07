#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <events>
#include <clients> 
  
#define PLUGIN_VERSION "0.4f"
  
  // Plugin definitions
public Plugin:myinfo =
{
	name = "SentrySpawner",
	author = "HL-SDK",
	description = "Spawns a sentry when a player dies where a player dies.",
	version = PLUGIN_VERSION,
	url = "."
} 
 
new gSentRemaining[MAXPLAYERS+1];    // how many sentries player has available
 
new Handle:g_IsSpawnSentryOn = INVALID_HANDLE;
new Handle:g_SentryInitLevel = INVALID_HANDLE;
new Handle:g_NumSentries = INVALID_HANDLE;
new Handle:g_SpawnSentryChance = INVALID_HANDLE;


public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre)
	HookEvent("object_destroyed", Event_ObjectDestroyed, EventHookMode_Post)
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_Post)

	CreateConVar("sm_spawnsentry", PLUGIN_VERSION, "Spawnsentry version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)

	g_IsSpawnSentryOn = CreateConVar("sm_spawnsentry_enabled", "1", "Enable/Disable spawning a sentry when a player dies. <0|1>", 0, true,0.0, true, 1.0);
	g_SentryInitLevel = CreateConVar("sm_spawnsentry_initlevel", "1", "Initial upgrade level of sentry that is placed when a player dies. <1-3>", 1, true,1.0, true, 3.0);
	g_NumSentries = CreateConVar("sm_spawnsentry_maxsentries", "5", "How many sentries allowable to be created upon player death. <1-20>", 1, true,1.0, true, 20.0);
	g_SpawnSentryChance = CreateConVar("sm_spawnsentry_chance", "1.0", "Probability that a sentry will be placed on death (0.5 = 50%, 1.0 = 100%, etc.)", FCVAR_PLUGIN);
}

public OnClientConnected(client)
{
	gSentRemaining[client] = GetConVarInt(g_NumSentries);	//Set init sentry count.
	return true;
}

public OnClientDisconnect(client) //Destroy all of a player's sentries when he/she disconnects Credit to loop goes to bl4nk
{
	new maxentities = GetMaxEntities();
	for (new i = MAXPLAYERS+1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i))
			continue;

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectSentrygun") && GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(i, "RemoveHealth");
		}
	}
}

public Action:Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) //Destroy all of a player's sentries when he/she Changes teams
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));							//The deal with this is, it seems that the player changes

	new maxentities = GetMaxEntities();														//Teams before he/she dies... so the sentry will still be of the
	for (new i = MAXPLAYERS+1; i <= maxentities; i++)										//team switched to :(
	{
		if (!IsValidEntity(i))
			continue;

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectSentrygun") && GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(i, "RemoveHealth");
		}
	}
	
	gSentRemaining[client] = GetConVarInt(g_NumSentries);
	
	return Plugin_Continue
}

public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)	//Keep track of a player's sentry count
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));							//I don't know how to determine whether a sentry was created
																							//by this plugin or by engie as build 
	new maxentities = GetMaxEntities();
	for (new i = MAXPLAYERS+1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i))
			continue;

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectSentrygun") && GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
		{
			gSentRemaining[client]+=1;			
			return Plugin_Continue
		}
	}
	return Plugin_Continue
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)		//Meaty code goodness
{
	if (GetConVarInt(g_IsSpawnSentryOn) == 1)
	{
		new userid = GetEventInt(event, "userid")
		
		decl String:vicname[64]
		new client = GetClientOfUserId(userid)
		GetClientName(client, vicname, sizeof(vicname))

		new Float:vicorigvec[3];
		GetClientAbsOrigin(client, Float:vicorigvec)
		
		new Float:angl[3];
		angl[0] = 0.0;
		angl[1] = 0.0;
		angl[2] = 0.0;
		
		new Float:rand = GetRandomFloat(0.0, 1.0);
		
		if (gSentRemaining[client]>0 && GetConVarFloat(g_SpawnSentryChance) >= rand)
		{
			BuildSentry(client, vicorigvec, angl, GetConVarInt(g_SentryInitLevel))
			
			gSentRemaining[client]-=1;
			
			PrintToChat(client, "[SM] You have %d deathsentries remaining", gSentRemaining[client])
		}
	}
	
	return Plugin_Continue
}

BuildSentry(iBuilder, Float:flOrigin[3], Float:flAngles[3], iLevel=1) //borrowed from the RTD plugin v0.4.3.4
{
	new String:strModel[100];

	new Float:fSentryMaxs[] = {20.0, 20.0, 66.0};
	
	new iTeam = GetClientTeam(iBuilder);
	new iShells, iHealth;
	new iRockets = 20;
	if(iLevel == 2)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry2.mdl");
		iShells = 200;
		iHealth = 180;
	}else if(iLevel == 3)
	{
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry3.mdl");
		iShells = 200;
		iHealth = 216;
	}else{
		// Assume level 1
		strcopy(strModel, sizeof(strModel), "models/buildables/sentry1.mdl");
		iShells = 150;
		iHealth = 150;
	}
	
	new iSentry = CreateEntityByName("obj_sentrygun");
	if(iSentry > MaxClients && IsValidEntity(iSentry))
	{
		DispatchSpawn(iSentry);
		
		TeleportEntity(iSentry, flOrigin, flAngles, NULL_VECTOR);
		
		SetEntityModel(iSentry, strModel);
		
		SetEntProp(iSentry, Prop_Send, "m_iAmmoShells", iShells);
		SetEntProp(iSentry, Prop_Send, "m_iHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iObjectType", _:TFObject_Sentry);
		SetEntProp(iSentry, Prop_Send, "m_iState", 1);
		
		SetEntProp(iSentry, Prop_Send, "m_iTeamNum", iTeam);
		SetEntProp(iSentry, Prop_Send, "m_nSkin", iTeam-2);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", iRockets);
		
		SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", iBuilder);
		
		SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 1.0);
		
		SetEntPropVector(iSentry, Prop_Send, "m_vecBuildMaxs", fSentryMaxs);
		
		return iSentry;
	}
	
	return 0;
}
  