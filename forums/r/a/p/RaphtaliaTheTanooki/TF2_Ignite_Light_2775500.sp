#pragma semicolon 1

//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.3"
#define MAX_STRENGTH    13

new Handle:g_hEnabled;
new Handle:g_hBrightness;

new g_iFlamethrower[MAXPLAYERS+1] = -1;
new g_iFlamethrowerTrash[MAXPLAYERS+1] = -1;

new g_bHooked[MAXPLAYERS+1] = false;

public Plugin:myinfo = {
    name = "[TF2] Ignite Light",
    author = "Peanut",
    description = "Adds dynamic lighting to the Pyro's flamethrower, Original by: Mecha the Slag",
    version = PLUGIN_VERSION,
    url = "https://discord.gg/7sRn8Bt"
};

bool g_bHasDynamicLight[MAXPLAYERS + 1] = { false, ... };

public APLRes AskPluginLoad2()
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("This isn't TF2, try TF2 next time");
	}
	return APLRes_Success;
}

public OnPluginStart() {
	RegConsoleCmd("sm_firelighting", Command_AllowLight);
    CreateConVar("ignitelight_version", PLUGIN_VERSION, "[TF2] Ignite Light version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hEnabled = CreateConVar("ignitelight_enable", "1", "Enable/disable the [TF2] Ignite Light plugin.", FCVAR_PLUGIN|FCVAR_NOTIFY);
    g_hBrightness = CreateConVar("ignitelight_brightness", "5", "This CVar is unsued in this version", FCVAR_PLUGIN|FCVAR_NOTIFY);

    HookEvent("player_spawn", PlayerSpawn);
    HookEvent("player_death", PlayerDeath);

    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
    }
}

public Action Command_AllowLight(int client, int args) 
{
    g_bHasDynamicLight[client] = !g_bHasDynamicLight[client];

    if(g_bHasDynamicLight[client]) {
        ReplyToCommand(client, "[SM] Dynamic Light Enabled");
    } else {
        ReplyToCommand(client, "[SM] Dynamic Light Disabled");
    }

    return Plugin_Handled;
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}

public OnClientPutInServer(iClient) {
    ResetClient(iClient);
    g_bHasDynamicLight[iClient] = false;
    SDKHook(iClient, SDKHook_PreThink, OnPreThink);
}

public OnClientDisconnect(iClient) {
    ResetClient(iClient);
    HookClient(iClient, false);
}

public OnPreThink(iClient) {
    if (!GetConVarBool(g_hEnabled)) return;
    if (!g_bHasDynamicLight[iClient]) return;

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
        new iWeaponState = GetEntProp(iEntity, Prop_Send, "m_iWeaponState");
        // PrintToChatAll("Weapon state: %d", iWeaponState);
        if(iWeaponState == 1) {
            return 0.5;
        } else if(iWeaponState > 1) {
            return 1.0;
        }
        // new Float:fStrength = (float(iStrength) / float(MAX_STRENGTH));
        // if (fStrength > 1.0) fStrength = 1.0;
        // return fStrength;
    }
    return 0.0;
}