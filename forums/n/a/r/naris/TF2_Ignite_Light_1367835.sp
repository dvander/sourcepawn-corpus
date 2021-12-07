#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

new Handle:g_hEnabled;

new g_iFlamethrower[MAXPLAYERS+1] = -1;

new g_bHooked[MAXPLAYERS+1] = false;

public Plugin:myinfo = {
    name = "[TF2] Ignite Light",
    author = "Mecha the Slag",
    description = "Adds dynamic lighting to the Pyro's flamethrower",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    // Check if the plugin is being run on the proper mod.
    decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
    if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");

    CreateConVar("ignitelight_version", PLUGIN_VERSION, "[TF2] Ignite Light version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled = CreateConVar("ignitelight_enable", "1", "Enable/disable the [TF2] Ignite Light plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    
    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public OnClientPutInServer(iClient) {
    ResetClient(iClient);
    SDKHook(iClient, SDKHook_PreThink, OnPreThink);
}

public OnClientDisconnect(iClient) {
    ResetClient(iClient);
    HookClient(iClient, false);
}

public OnPreThink(iClient) {
    if (!GetConVarBool(g_hEnabled)) return;
    
    new iButtons = GetClientButtons(iClient);
    decl String:strWeapon[52];
    GetClientWeapon(iClient, strWeapon, sizeof(strWeapon));
    if ((iButtons & IN_ATTACK) && !(iButtons & IN_ATTACK2) && TF2_GetPlayerClass(iClient) == TFClass_Pyro && StrEqual(strWeapon, "tf_weapon_flamethrower")) {
        if (g_iFlamethrower[iClient] == -1 && !IsEntLimitReached(.message="unable to create light_dynamic")) {
            new iEntity = CreateLightEntity(iClient);
            if (IsLightEntity(iEntity)) g_iFlamethrower[iClient] = EntIndexToEntRef(iEntity);
        }
    }
    else {
        if (g_iFlamethrower[iClient] != -1) {
            new iEntity = EntRefToEntIndex(g_iFlamethrower[iClient]);
            if (IsLightEntity(iEntity)) RemoveEdict(iEntity);
            g_iFlamethrower[iClient] = -1;
        }
    }
}
    
ResetClient(iClient) {
    new iLight;
    iLight = EntRefToEntIndex(g_iFlamethrower[iClient]);
    if (IsLightEntity(iLight)) RemoveEdict(iLight);
    g_iFlamethrower[iClient] = -1;
}

CreateLightEntity(iClient) {
    if (!IsValidClient(iClient)) return -1;
    if (!IsPlayerAlive(iClient)) return -1;
    new iEntity = CreateEntityByName("light_dynamic");
    if (IsValidEntity(iEntity)) {
        DispatchKeyValue(iEntity, "inner_cone", "0");
        DispatchKeyValue(iEntity, "cone", "80");
        DispatchKeyValue(iEntity, "brightness", "7");
        DispatchKeyValueFloat(iEntity, "spotlight_radius", 240.0);
        DispatchKeyValueFloat(iEntity, "distance", 250.0);
        DispatchKeyValue(iEntity, "_light", "255 100 10 50");
        DispatchKeyValue(iEntity, "pitch", "-90");
        DispatchKeyValue(iEntity, "style", "5");
        DispatchSpawn(iEntity);
        
        decl Float:fPos[3];
        decl Float:fAngle[3];
        decl Float:fAngle2[3];
        decl Float:fForward[3];
        decl Float:fOrigin[3];
        GetClientEyePosition(iClient, fPos);
        GetClientEyeAngles(iClient, fAngle);
        GetClientEyeAngles(iClient, fAngle2);
        
        fAngle2[0] = 0.0;
        fAngle2[2] = 0.0;
        GetAngleVectors(fAngle2, fForward, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(fForward, 100.0);
        fForward[2] = 0.0;
        AddVectors(fPos, fForward, fOrigin);
        
        fAngle[0] += 90.0;
        fOrigin[2] -= 100.0;
        TeleportEntity(iEntity, fOrigin, fAngle, NULL_VECTOR);
        
        decl String:strName[32];
        Format(strName, sizeof(strName), "target%i", iClient);
        DispatchKeyValue(iClient, "targetname", strName);
                
        DispatchKeyValue(iEntity, "parentname", strName);
        SetVariantString("!activator");
        AcceptEntityInput(iEntity, "SetParent", iClient, iEntity, 0);
        SetVariantString("head");
        AcceptEntityInput(iEntity, "SetParentAttachmentMaintainOffset", iClient, iEntity, 0);
        AcceptEntityInput(iEntity, "TurnOn");
    }
    return iEntity;
}

public PlayerDeath(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    ResetClient(iClient);
    HookClient(iClient, false);
}

public PlayerSpawn(Handle:hEvent, String:strName[], bool:bDontBroadcast) {
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    ResetClient(iClient);
    HookClient(iClient);
}

HookClient(iClient, bHook = true) {
    if (bHook && !g_bHooked[iClient]) {
        SDKHook(iClient, SDKHook_PreThink, OnPreThink);
    }
    if (!bHook && g_bHooked[iClient]) {
        SDKUnhook(iClient, SDKHook_PreThink, OnPreThink);
    }
    g_bHooked[iClient] = bHook;
}

stock bool:IsLightEntity(iEntity) {
    if (iEntity > 0) {
        if (IsValidEdict(iEntity)) {
            decl String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            if (StrEqual(strClassname, "light_dynamic", false)) return true;
        }
    }
    return false;
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

