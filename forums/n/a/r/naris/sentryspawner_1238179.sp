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

/**
 * Description: Functions to spawn buildings.
 */
#tryinclude <tf2_build>
#if !defined _tf2_build_included
    stock BuildSentry(hBuilder, const Float:fOrigin[3], const Float:fAngle[3], iLevel=1, 
                      bool:bDisabled=false, bool:bMini=false, bool:bShielded=false,
                      iHealth=-1, iMaxHealth=-1, iShells=-1, iRockets=-1)
    {
        static const Float:fBuildMaxs[3] = { 24.0, 24.0, 66.0 };
        //static const Float:fMdlWidth[3] = { 1.0, 0.5, 0.0 };

        new iTeam = GetClientTeam(hBuilder);

        new iSentryHealth;
        new iMaxSentryShells;
        new iMaxSentryRockets;
        if (iLevel >= 1 && iLevel <= 3)
        {
            iSentryHealth = TF2_SentryHealth[iLevel];
            iMaxSentryShells = TF2_MaxSentryShells[iLevel];
            iMaxSentryRockets = TF2_MaxSentryRockets[iLevel];
        }
        else if (iLevel == 4)
        {
            iLevel = 3;
            iSentryHealth = (TF2_SentryHealth[3]+TF2_SentryHealth[4])/2;
            iMaxSentryShells = (TF2_MaxSentryShells[3]+TF2_MaxSentryShells[4])/2;
            iMaxSentryRockets = (TF2_MaxSentryRockets[3]+TF2_MaxSentryRockets[4])/2;
        }
        else if (iLevel < 1 || bMini)
        {
            iLevel = 1;
            iSentryHealth = TF2_SentryHealth[0];
            iMaxSentryShells = TF2_MaxSentryShells[0];
            iMaxSentryRockets = TF2_MaxSentryRockets[0];
        }
        else
        {
            iLevel = 3;
            iSentryHealth = TF2_SentryHealth[4];
            iMaxSentryShells = TF2_MaxSentryShells[4];
            iMaxSentryRockets = TF2_MaxSentryRockets[4];
        }

        if (iShells < 0)
            iRockets = iMaxSentryRockets;

        if (iShells < 0)
            iShells = iMaxSentryShells;

        if (iMaxHealth < 0)
            iMaxHealth = iSentryHealth;

        if (iHealth < 0 || iHealth > iMaxHealth)
            iHealth = iMaxHealth;

        new iSentry = CreateEntityByName(TF2_ObjectClassNames[TFObjectType_Sentrygun]);
        if (iSentry)
        {
            DispatchSpawn(iSentry);

            TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);

            decl String:sModel[64];
            if (bMini)
                strcopy(sModel, sizeof(sModel),"models/buildables/sentry1.mdl");
            else
                Format(sModel, sizeof(sModel),"models/buildables/sentry%d.mdl", iLevel);

            SetEntityModel(iSentry,sModel);

            // m_bPlayerControlled is set to make m_bShielded work,
            // but it gets reset almost immediately :(

            SetEntProp(iSentry, Prop_Send, "m_iMaxHealth", 				        iMaxHealth, 4);
            SetEntProp(iSentry, Prop_Send, "m_iHealth", 					    iHealth, 4);
            SetEntProp(iSentry, Prop_Send, "m_bDisabled", 				        bDisabled, 2);
            SetEntProp(iSentry, Prop_Send, "m_bShielded", 				        bShielded, 2);
            SetEntProp(iSentry, Prop_Send, "m_bPlayerControlled", 				bShielded, 2);
            SetEntProp(iSentry, Prop_Send, "m_bMiniBuilding", 				    bMini, 2);
            SetEntProp(iSentry, Prop_Send, "m_iObjectType", 				    _:TFObjectType_Sentrygun, 1);
            SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel", 			        iLevel, 4);
            SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets", 				    iRockets, 4);
            SetEntProp(iSentry, Prop_Send, "m_iAmmoShells" , 				    iShells, 4);
            SetEntProp(iSentry, Prop_Send, "m_iState" , 				        (bShielded ? 2 : 0), 4);
            SetEntProp(iSentry, Prop_Send, "m_iObjectMode", 				    0, 2);
            SetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal", 			        0, 2);
            SetEntProp(iSentry, Prop_Send, "m_bBuilding", 				        0, 2);
            SetEntProp(iSentry, Prop_Send, "m_bPlacing", 					    0, 2);
            SetEntProp(iSentry, Prop_Send, "m_iState", 					        1, 1);
            SetEntProp(iSentry, Prop_Send, "m_bHasSapper", 				        0, 2);
            SetEntProp(iSentry, Prop_Send, "m_nNewSequenceParity", 		        4, 4);
            SetEntProp(iSentry, Prop_Send, "m_nResetEventsParity", 		        4, 4);
            SetEntProp(iSentry, Prop_Send, "m_bServerOverridePlacement", 	    1, 1);
            SetEntProp(iSentry, Prop_Send, "m_nSequence",                       0);

            SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder", 	                hBuilder);

            SetEntPropFloat(iSentry, Prop_Send, "m_flCycle", 					0.0);
            SetEntPropFloat(iSentry, Prop_Send, "m_flPlaybackRate", 			1.0);
            SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed", 	1.0);
            SetEntPropFloat(iSentry, Prop_Send, "m_flModelWidthScale", 	        1.0);

            SetEntPropVector(iSentry, Prop_Send, "m_vecOrigin", 			    fOrigin);
            SetEntPropVector(iSentry, Prop_Send, "m_angRotation", 		        fAngle);
            SetEntPropVector(iSentry, Prop_Send, "m_vecBuildMaxs", 		        fBuildMaxs);
            //SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),	fMdlWidth, true);

            if (bMini)
            {
                SetEntProp(iSentry, Prop_Send, "m_nSkin", 					    iTeam, 1);
                SetEntProp(iSentry, Prop_Send, "m_nBody", 					    5, 1);
            }
            else
            {
                SetEntProp(iSentry, Prop_Send, "m_nSkin", 					    (iTeam-2), 1);
                SetEntProp(iSentry, Prop_Send, "m_nBody", 					    0, 1);
            }

            SetVariantInt(iTeam);
            AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

            SetVariantInt(iTeam);
            AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0);

            SetVariantInt(hBuilder);
            AcceptEntityInput(iSentry, "SetBuilder", -1, -1, 0);

            new Handle:event = CreateEvent("player_builtobject");
            if (event != INVALID_HANDLE)
            {
                SetEventInt(event, "userid", GetClientUserId(hBuilder));
                SetEventInt(event, "object", _:TFObjectType_Sentrygun);
                SetEventInt(event, "index", iSentry);
                SetEventBool(event, "sourcemod", true);
                FireEvent(event);
            }

            g_WasBuilt[iSentry] = true;
            g_HasBuilt[hBuilder] |= HasBuiltSentry;
        }
        return iSentry;
    }
#endif

