#include <sourcemod>

#pragma newdecls required

int g_iArmorOffset;
int g_iHelmetOffset;

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
    g_iArmorOffset = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
    g_iHelmetOffset = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsValidClient(client) && CheckCommandAccess(client, "sm_armor_override", ADMFLAG_CUSTOM1))
    {
        SetEntData(client, g_iArmorOffset, 100);
        SetEntData(client, g_iHelmetOffset, 1);
    }
}

bool IsValidClient(int client)
{
    if (!(0 < client <= MaxClients)) return false;
    if (!IsClientInGame(client)) return false;
    return true;
}