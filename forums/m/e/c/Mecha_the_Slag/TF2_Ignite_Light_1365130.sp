#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.2"
#define MAX_STRENGTH    13

new Handle:g_hEnabled;
new Handle:g_hBrightness;

new g_iFlamethrower[MAXPLAYERS+1] = -1;
new g_iFlamethrowerTrash[MAXPLAYERS+1] = -1;

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
    g_hBrightness = CreateConVar("ignitelight_brightness", "5", "Set the [TF2] Ignite Light brightness.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    
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
    
    new iEntity;
    decl String:strWeapon[52];
    GetClientWeapon(iClient, strWeapon, sizeof(strWeapon));
    new Float:fStrength = GetFlamethrowerStrength(iClient);
    if (fStrength > 0.0) {
        // If no light is present, let's spawn it
        if (g_iFlamethrower[iClient] == -1) {
            iEntity = CreateLightEntity(iClient);
            if (IsLightEntity(iEntity)) {
                KillFlamethrowerTrash(iClient);
                g_iFlamethrower[iClient] = iEntity;
            }
        }
        
        // If the light is already there, let's increase its strength
        iEntity = g_iFlamethrower[iClient];
        if (IsLightEntity(iEntity)) {
            AdjustLight(iClient, iEntity);
        }
    }
    else {
        // if there is a light, let's trash it
        if (g_iFlamethrower[iClient] != -1) {
            iEntity = g_iFlamethrower[iClient];
            if (IsLightEntity(iEntity)) {
                // If there's already trash, kill the trash
                KillFlamethrowerTrash(iClient);
                g_iFlamethrowerTrash[iClient] = iEntity;
            }
            g_iFlamethrower[iClient] = -1;
        }
        
        // decrease the trash's strength
        iEntity = g_iFlamethrowerTrash[iClient];
        if (IsLightEntity(iEntity)) {
            if (fStrength <= 0.0) {
                KillFlamethrowerTrash(iClient);
            } else {
                AdjustLight(iClient, iEntity);
            }
        }
    }
}
    
ResetClient(iClient) {
    new iLight;
    
    iLight = g_iFlamethrower[iClient];
    if (IsLightEntity(iLight)) RemoveEdict(iLight);
    
    KillFlamethrowerTrash(iClient);
    
    g_iFlamethrower[iClient] = -1;
}

CreateLightEntity(iClient) {
    if (!IsValidClient(iClient)) return -1;
    if (!IsPlayerAlive(iClient)) return -1;
    new iEntity = CreateEntityByName("light_dynamic");
    if (IsValidEntity(iEntity)) {
        DispatchKeyValue(iEntity, "inner_cone", "0");
        DispatchKeyValue(iEntity, "cone", "80");
        DispatchKeyValue(iEntity, "brightness", "0");
        DispatchKeyValueFloat(iEntity, "spotlight_radius", 240.0);
        DispatchKeyValueFloat(iEntity, "distance", 250.0);
        DispatchKeyValue(iEntity, "_light", "255 100 10 255");
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

stock bool:IsFlamethrower(iEntity) {
    if (iEntity > 0) {
        if (IsValidEdict(iEntity)) {
            decl String:strClassname[32];
            GetEdictClassname(iEntity, strClassname, sizeof(strClassname));
            if (StrEqual(strClassname, "tf_weapon_flamethrower", false)) return true;
        }
    }
    return false;
}

KillFlamethrowerTrash(iClient) {
    if (g_iFlamethrowerTrash[iClient] != -1) {
        new iEntity = g_iFlamethrowerTrash[iClient];
        if (IsLightEntity(iEntity)) RemoveEdict(iEntity);
        g_iFlamethrowerTrash[iClient] = -1;
    }
}

AdjustLight(iClient, iEntity) {
    new Float:fValue;
    new iValue;
    fValue = GetFlamethrowerStrength(iClient) * float(GetConVarInt(g_hBrightness));
    iValue = RoundFloat(fValue);
    SetVariantInt(iValue);
    AcceptEntityInput(iEntity, "Brightness");
}

Float:GetFlamethrowerStrength(iClient) {
    if (!IsValidClient(iClient)) return 0.0;
    if (!IsPlayerAlive(iClient)) return 0.0;
    new iEntity = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    if (IsFlamethrower(iEntity)) {
        new iStrength = GetEntProp(iEntity, Prop_Send, "m_iActiveFlames");
        new Float:fStrength = (float(iStrength) / float(MAX_STRENGTH));
        if (fStrength > 1.0) fStrength = 1.0;
        return fStrength;
    }
    return 0.0;
}