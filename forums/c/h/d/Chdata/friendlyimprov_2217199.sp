#pragma semicolon 1

#include <sourcemod>
#include <friendly>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "0x01"

new bool:g_bEnabled = true;

enum f_validclientlevel {
    VCLIENT_VALIDINDEX,
    VCLIENT_CONNECTED,
    VCLIENT_INGAME,
    VCLIENT_ONATEAM,
    VCLIENT_ONAREALTEAM,
    VCLIENT_ALIVE,
};

// Functions
public Plugin:myinfo =
{
    name = "Friendly Mode Improvements",
    author = "Chdata",
    description = "Additions to how friendly mode works",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/groups/tf2data"
};

public OnAllPluginsLoaded()
{
    g_bEnabled = LibraryExists("[TF2] Friendly Mode");
    LogMessage("[TF2] Friendly Mode Additional Improvements is %sabled.", g_bEnabled ? "en" : "dis");

    if (!g_bEnabled)
    {
        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "[TF2] Friendly Mode"))
    {
        g_bEnabled = true;
    }
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "[TF2] Friendly Mode"))
    {
        g_bEnabled = false;

        for (new i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

public OnPluginStart()
{
    if (!g_bEnabled)
    {
        return;
    }

    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public OnClientPostAdminCheck(iClient)
{
    if (!g_bEnabled)
    {
        return;
    }

    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(iVictim, &iAtker, &iInflictor, &Float:flDamage, &iDmgType, &iWeapon, Float:vDmgForce[3], Float:vDmgPos[3], iDmgCustom)
{
    if (TF2Friendly_IsFriendly(iVictim))
    {
        decl String:s[16];
        GetEdictClassname(iAtker, s, sizeof(s));
        if (StrEqual(s, "trigger_hurt", false))
        {
            TeleportToSpawn(iVictim, GetClientTeam(iVictim));
        }

        if (!IsValidClient(iAtker)) // Attempt to stop knockback from non-player damage sources
        {
            ScaleVector(vDmgForce, 0.0);
            iDmgType |= DMG_PREVENT_PHYSICS_FORCE;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

/*
 Teleports a client to a random spawn location

 iClient - Client to teleport
 iTeam - Team of spawn points to use. If not specified or invalid team number, teleport to ANY spawn point.

 @NoReturn

*/
stock TeleportToSpawn(iClient, iTeam = 0)
{
    decl Float:vPos[3];
    decl Float:vAng[3];
    new Handle:hArray = CreateArray();

    new iEnt = -1;
    while ((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
    {
        if (iTeam <= 1) // Not RED (2) nor BLU (3) is specified so we use all spawn locations
        {
            PushArrayCell(hArray, iEnt);
        }
        else // Only use spawns that match our team
        {
            new iSpawnTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
            if (iSpawnTeam == iTeam)
            {
                PushArrayCell(hArray, iEnt);
            }
        }
    }

    iEnt = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray) - 1));
    CloseHandle(hArray);

    // Technically you'll never find a map without a spawn point.
    GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);
    GetEntPropVector(iEnt, Prop_Send, "m_angRotation", vAng);
    TeleportEntity(iClient, vPos, vAng, NULL_VECTOR);

    /*if (GetArraySize(hArray) <= 0)
    {
        // No iEnt was found. This should be impossible.
    }
    else
    {
        iEnt = GetArrayCell(hArray, GetRandomInt(0, GetArraySize(hArray) - 1))
    }*/
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
    while (startEnt > -1 && !IsValidEntity(startEnt))
    {
        startEnt--;
    }

    return FindEntityByClassname(startEnt, classname);
}

public TF2Friendly_OnRefreshFriendly_Post(iClient)
{
    SetExtraFriendlyAttribs(iClient, true);
}

public TF2Friendly_OnDisableFriendly_Pre(iClient)
{
    SetExtraFriendlyAttribs(iClient, false);
}

stock SetExtraFriendlyAttribs(iClient, bool:bOn)
{
    if (bOn)
    {
        TF2Attrib_SetByName(iClient, "damage force reduction", 0.0);
        TF2Attrib_SetByName(iClient, "cancel falling damage", 1.0);
        TF2Attrib_SetByName(iClient, "afterburn immunity", 1.0);
        TF2Attrib_SetByName(iClient, "airblast disabled", 1.0);

        /*if (GetIndexOfWeaponSlot(iClient) == 44)
        {
            TF2Attrib_SetByName(iClient, "maxammo grenades1 increased", 0.0); // Remove sandman ball
        }*/
    }
    else
    {
        TF2Attrib_RemoveByName(iClient, "cancel falling damage");
        TF2Attrib_RemoveByName(iClient, "damage force reduction");
        TF2Attrib_RemoveByName(iClient, "afterburn immunity");
        TF2Attrib_RemoveByName(iClient, "airblast disabled");

        /*if (GetIndexOfWeaponSlot(iClient) == 44)
        {
            TF2Attrib_RemoveByName(iClient, "maxammo grenades1 increased");
        }*/
    }
}

stock GetIndexOfWeaponSlot(iClient, iSlot)
{
    new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
    return (iWeapon > MaxClients && IsValidEntity(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (!g_bEnabled)
    {
        return;
    }

    if (StrEqual(classname, "tf_projectile_stun_ball", false) || StrEqual(classname, "tf_projectile_ball_ornament", false))
    {
        SDKHook(entity, SDKHook_StartTouch, OnTouchingBalls);
        SDKHook(entity, SDKHook_Touch, OnTouchingBalls);
    }

}

public Action:OnTouchingBalls(iBall, iClient)
{
    if (!g_bEnabled || TF2Friendly_IsFriendly(iClient)) // Using this as IsValidClient too
    {
        return Plugin_Continue;
    }

    if (TF2Friendly_IsFriendly(GetThrower(iBall, iClient)))
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

stock GetThrower(iEnt, iOther)
{
    new iOwnerEntity = GetEntPropEnt(iEnt, Prop_Data, "m_hOwnerEntity");
    if (iOwnerEntity != iOther && IsValidClient(iOwnerEntity))
    {
        return iOwnerEntity;
    }
    return -1;
}  

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) return false;
    if (GetEntProp(iClient, Prop_Send, "m_bIsCoaching")) return false;
    return true;
}