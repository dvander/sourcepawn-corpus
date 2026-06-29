#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define M4_PRICE 2900
#define CZ_PRICE 500
#define R8_PRICE 600
#define MP5_PRICE 1500

bool g_UsedUSP[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name = "Off Buy Menu",
    author = "jo-soa",
    description = "Buy weapons not available in the buy menu.",
    version = "1.1.0"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_m4", Command_M4);
    RegConsoleCmd("sm_usp", Command_USP);
    RegConsoleCmd("sm_cz", Command_CZ);
    RegConsoleCmd("sm_r8", Command_R8);
    RegConsoleCmd("sm_mp5", Command_MP5);

    HookEvent("round_start", Event_RoundStart);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        g_UsedUSP[i] = false;
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

public Action Command_M4(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You can't use this command while dead.");
        return Plugin_Handled;
    }

    if (GetClientTeam(client) != CS_TEAM_CT)
    {
        PrintToChat(client, "Only \x0BCTs\x01 can use \x09!m4\x01.");
        return Plugin_Handled;
    }

    if (!GetEntProp(client, Prop_Send, "m_bInBuyZone"))
    {
        PrintToChat(client, "You must be in a buy zone.");
        return Plugin_Handled;
    }

    int money = GetEntProp(client, Prop_Send, "m_iAccount");

    if (money < M4_PRICE)
    {
        PrintToChat(client, "Not enough money for \x09M4A1-S\x01 (\x05$2900\x01).");
        return Plugin_Handled;
    }

    SetEntProp(client, Prop_Send, "m_iAccount", money - M4_PRICE);
    GivePlayerItem(client, "weapon_m4a1_silencer");

    PrintToChat(client, "You bought a \x09M4A1-S\x01 for \x05$2900\x01.");

    return Plugin_Handled;
}

public Action Command_USP(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You can't use this command while dead.");
        return Plugin_Handled;
    }

    if (GetClientTeam(client) != CS_TEAM_CT)
    {
        PrintToChat(client, "Only \x0BCTs\x01 can use \x09!usp\x01.");
        return Plugin_Handled;
    }

    if (g_UsedUSP[client])
    {
        PrintToChat(client, "Already used \x09!usp\x01 this round.");
        return Plugin_Handled;
    }

    int pistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);

    if (pistol != -1)
    {
        RemovePlayerItem(client, pistol);
        AcceptEntityInput(pistol, "Kill");
    }

    GivePlayerItem(client, "weapon_usp_silencer");
    g_UsedUSP[client] = true;

    PrintToChat(client, "You received a \x09USP-S\x01.");

    return Plugin_Handled;
}

public Action Command_CZ(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You can't use this command while dead.");
        return Plugin_Handled;
    }

    if (!GetEntProp(client, Prop_Send, "m_bInBuyZone"))
    {
        PrintToChat(client, "You must be in a buy zone.");
        return Plugin_Handled;
    }

    int money = GetEntProp(client, Prop_Send, "m_iAccount");

    if (money < CZ_PRICE)
    {
        PrintToChat(client, "Not enough money for \x09CZ75-Auto\x01 (\x05$500\x01).");
        return Plugin_Handled;
    }

    int pistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);

    if (pistol != -1)
    {
        RemovePlayerItem(client, pistol);
        AcceptEntityInput(pistol, "Kill");
    }

    SetEntProp(client, Prop_Send, "m_iAccount", money - CZ_PRICE);
    GivePlayerItem(client, "weapon_cz75a");

    PrintToChat(client, "You bought a \x09CZ75-Auto\x01 for \x05$500\x01.");

    return Plugin_Handled;
}

public Action Command_R8(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You can't use this command while dead.");
        return Plugin_Handled;
    }

    if (!GetEntProp(client, Prop_Send, "m_bInBuyZone"))
    {
        PrintToChat(client, "You must be in a buy zone.");
        return Plugin_Handled;
    }

    int money = GetEntProp(client, Prop_Send, "m_iAccount");

    if (money < R8_PRICE)
    {
        PrintToChat(client, "Not enough money for \x09R8 Revolver\x01 (\x05$600\x01).");
        return Plugin_Handled;
    }

    int pistol = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);

    if (pistol != -1)
    {
        RemovePlayerItem(client, pistol);
        AcceptEntityInput(pistol, "Kill");
    }

    SetEntProp(client, Prop_Send, "m_iAccount", money - R8_PRICE);
    GivePlayerItem(client, "weapon_revolver");

    PrintToChat(client, "You bought a \x09R8 Revolver\x01 for \x05$600\x01.");

    return Plugin_Handled;
}

public Action Command_MP5(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    if (!IsPlayerAlive(client))
    {
        PrintToChat(client, "You can't use this command while dead.");
        return Plugin_Handled;
    }

    if (!GetEntProp(client, Prop_Send, "m_bInBuyZone"))
    {
        PrintToChat(client, "You must be in a buy zone.");
        return Plugin_Handled;
    }

    int money = GetEntProp(client, Prop_Send, "m_iAccount");

    if (money < MP5_PRICE)
    {
        PrintToChat(client, "Not enough money for \x09MP5-SD\x01 (\x05$1500\x01).");
        return Plugin_Handled;
    }

    SetEntProp(client, Prop_Send, "m_iAccount", money - MP5_PRICE);
    GivePlayerItem(client, "weapon_mp5sd");

    PrintToChat(client, "You bought a \x09MP5-SD\x01 for \x05$1500\x01.");

    return Plugin_Handled;
}