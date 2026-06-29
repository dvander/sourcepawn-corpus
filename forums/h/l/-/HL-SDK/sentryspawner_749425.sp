#include <sourcemod>
#include <sdktools>
#include <events>
#include <clients> 
  
#define PLUGIN_VERSION "0.4"
  
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

BuildSentry(iBuilder, Float:fOrigin[3], Float:fAngle[3], iLevel=1)							//Not my code, credit goes to The JCS and Muridas
{
    new Float:fBuildMaxs[3];
    fBuildMaxs[0] = 24.0;
    fBuildMaxs[1] = 24.0;
    fBuildMaxs[2] = 66.0;

    new Float:fMdlWidth[3];
    fMdlWidth[0] = 1.0;
    fMdlWidth[1] = 0.5;
    fMdlWidth[2] = 0.0;
    
    new String:sModel[64];
    
    new iTeam = GetClientTeam(iBuilder);
    
    new iShells, iHealth, iRockets;
    
    if(iLevel == 1)
    {
        sModel = "models/buildables/sentry1.mdl";
        iShells = 100;
        iHealth = 150;
    }
    else if(iLevel == 2)
    {
        sModel = "models/buildables/sentry2.mdl";
        iShells = 120;
        iHealth = 180;
    }
    else if(iLevel == 3)
    {
        sModel = "models/buildables/sentry3.mdl";
        iShells = 144;
        iHealth = 216;
        iRockets = 20;
    }
    
    new iSentry = CreateEntityByName("obj_sentrygun");
    
    DispatchSpawn(iSentry);
    
    TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);
    
    SetEntityModel(iSentry,sModel);
    
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nNewSequenceParity"),         4, 4 , true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nResetEventsParity"),         4, 4 , true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoShells") ,                 iShells, 4, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iMaxHealth"),                 iHealth, 4, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iHealth"),                     iHealth, 4, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bBuilding"),                 0, 2, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bPlacing"),                     0, 2, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bDisabled"),                 0, 2, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iObjectType"),                 3, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iState"),                     1, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeMetal"),             0, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bHasSapper"),                 0, 2, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSkin"),                     (iTeam-2), 1, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_bServerOverridePlacement"),     1, 1, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iUpgradeLevel"),             iLevel, 4, true);
    SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_iAmmoRockets"),                 iRockets, 4, true);
    
    SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_nSequence"), 0, true);
    SetEntDataEnt2(iSentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"),     iBuilder, true);
    
    SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flCycle"),                     0.0, true);
    SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPlaybackRate"),             1.0, true);
    SetEntDataFloat(iSentry, FindSendPropOffs("CObjectSentrygun","m_flPercentageConstructed"),     1.0, true);
    
    SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
    SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
    SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
    SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);
    
    SetVariantInt(iTeam);
    AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

    SetVariantInt(iTeam);
    AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0); 
}  