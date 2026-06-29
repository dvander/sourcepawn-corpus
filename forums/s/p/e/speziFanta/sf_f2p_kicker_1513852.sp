#pragma semicolon 1

#include <sourcemod>
#include <steamtools>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#define PLUGIN_VERSION "0.0.9"

new Handle:g_hF2PKicker = INVALID_HANDLE;
new Handle:g_hQuickPlayOff = INVALID_HANDLE;
new Handle:g_hMaxF2PSlots = INVALID_HANDLE;
new Handle:g_hReservedSlots = INVALID_HANDLE;
new Handle:g_hServerTags = INVALID_HANDLE;
new g_iQuickPlayOffStatus = 0;

public Plugin:myinfo =
{
    name = "F2P Kicker",
    author = "Asherkin, spezi|Fanta",
    description = "Kicks non-premium players before the server gets full. This way premium players always get a slot",
    version = PLUGIN_VERSION,
    url = "http://www.schlachtfestchen.de/"
};

public OnPluginStart()
{
    CreateConVar("sm_f2p_kicker_version", PLUGIN_VERSION, "Free 2 Play Kicked", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    g_hF2PKicker = CreateConVar("sm_f2p_kicker", "1", "Status of Free 2 Play Kicker. If set to 1 it'll be activated (default). 0 is off.", 0, true, 0.0, true, 1.0);
    g_hQuickPlayOff = FindConVar("tf_server_identity_disable_quickplay");
    g_hReservedSlots = FindConVar("sm_reserved_slots");
    g_hServerTags = FindConVar("sv_tags");
    g_hMaxF2PSlots = CreateConVar("sm_f2p_max", "22", "Maximum F2P slots before F2P users get blocked on join.", 0, true, 0.0);

    // Hooks
    HookConVarChange(g_hF2PKicker, OnF2PKickerChange);
    HookConVarChange(g_hMaxF2PSlots, OnF2PSlotsChange);

    // Save Quick play status
    g_iQuickPlayOffStatus = GetConVarInt(g_hQuickPlayOff);

    // Remove notification on change
    SetConVarFlags(g_hQuickPlayOff, GetConVarFlags(g_hQuickPlayOff) & ~FCVAR_NOTIFY);
    SetConVarFlags(g_hServerTags, GetConVarFlags(g_hQuickPlayOff) & ~FCVAR_NOTIFY);

    checkPlayers();
}

public OnF2PKickerChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) == 0)
    {
        SetConVarInt(g_hQuickPlayOff, g_iQuickPlayOffStatus);
    }
}

public OnF2PSlotsChange(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    new realSlots = MaxClients - GetConVarInt(g_hReservedSlots);
    new maxF2PSlots = realSlots - 1;

    if (StringToInt(newValue)  > maxF2PSlots)
    {
        SetConVarInt(g_hMaxF2PSlots, maxF2PSlots);
    }
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if (!GetConVarBool(g_hF2PKicker))
    {
        return true;
    }

    if (isFree2Play(client))
    {
        if (GetClientCount(false) >= GetConVarInt(g_hMaxF2PSlots))
        {
             new String:name[MAX_NAME_LENGTH];
             GetClientName(client, name, sizeof(name));

             LogToGame("[SM][F2P] F2P User \"%s\" got rejeced.", name);
             Format(rejectmsg, maxlen, "Sorry, there are currently no Free2Play slots available.");
             return false;
        }
    }

    return true;
}

public OnClientPostAdminCheck(client)
{
    new String:name[MAX_NAME_LENGTH];
    new String:authID[32];
    GetClientName(client, name, sizeof(name));
    GetClientAuthString(client, authID, sizeof(authID));

    if (isFree2Play(client))
    {
        LogToGame("[SM][F2P] F2P User \"%s\" <%s> joined the game.", name, authID);
    }
    else
    {
        LogToGame("[SM][F2P] Premium User \"%s\" <%s> joined the game.", name, authID);
    }

    checkPlayers();
    return;
}

public checkPlayers()
{
    if (!GetConVarBool(g_hF2PKicker))
    {
        return;
    }

    // Turn off Quickplay to stop attracting F2P users
    if (GetClientCount(false) >= GetConVarInt(g_hMaxF2PSlots) - 2)
    {
        SetConVarInt(g_hQuickPlayOff, 1);
    }

    // Turn Quickplay back on (if used) to keep server filled
    if ((GetClientCount(false) <= GetConVarInt(g_hMaxF2PSlots) - 4) && !g_iQuickPlayOffStatus)
    {
        SetConVarInt(g_hQuickPlayOff, 0);
    }

    new realSlots = MaxClients - GetConVarInt(g_hReservedSlots);

    if (GetClientCount(false) < (realSlots - 1))
    {
        return;
    }

    new currentF2PUser = -1;
    new Float:playTime = -1.0;

    for (new client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client))
        {
             continue;
        }

        if (isFree2Play(client))
        {
            if (GetClientTime(client) > playTime)
            {
                playTime = GetClientTime(client);
                currentF2PUser = client;
            }
        }
    }

    if (currentF2PUser != -1)
    {
        new client = currentF2PUser;

        // Get name and SteamID
        new String:name[MAX_NAME_LENGTH];
        new String:authID[32];
        GetClientName(client, name, sizeof(name));
        GetClientAuthString(client, authID, sizeof(authID));

        KickClient(currentF2PUser, "Sorry, you got kicked by a reserved slot.");
        LogToGame("[SM][F2P] F2P User \"%s\" <%s> got kicked by a new player", name, authID);
    }
    else
    {
        LogToGame("[SM][F2P] Server is running Free2Play free.");
    }

    return;
}

// This part was taken form asherkin's "Free2BeKicked" plugin
// URL: http://forums.alliedmods.net/showthread.php?t=160049
public bool:isFree2Play(client)
{
    if (CheckCommandAccess(client, "BypassPremiumCheck", ADMFLAG_ROOT, true))
    {
        return false;
    }

    if (Steam_CheckClientSubscription(client, 0) && !Steam_CheckClientDLC(client, 459))
    {
        return true;
    }

    return false;
}
