#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0.0"

ConVar sm_chapterhealth_medkit = null;

public Plugin myinfo =
{
	name = "[L4D & L4D2] Chapter Health",
	author = "XeroX",
	description = "On Mission start equip everyone with an m60 and refill health on each chapter",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=351935"
}


public void OnPluginStart()
{
    HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
    HookEvent("player_entered_checkpoint", Event_PlayerEnteredCheckPoint);

    CreateConVar("sm_chapterhealth_version", PLUGIN_VERSION, "Version of the Chapter Health Plugin", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    sm_chapterhealth_medkit = CreateConVar("sm_chapterhealth_medkit", "0", "Give survivors a medkit on each chapter aswell. 1 = Yes | 0 = No", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    AutoExecConfig();
}


public void Event_PlayerEnteredCheckPoint(Event event, const char[] szName, bool dontBroadcast)
{
    if(L4D_HasAnySurvivorLeftSafeArea()) return;
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client) return;
    if(!IsClientInGame(client)) return;
    if(GetClientTeam(client) != L4D_TEAM_SURVIVOR) return;

    int health = GetClientHealth(client);
    int maxhealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    if(health < maxhealth)
    {
        SetEntityHealth(client, maxhealth);
        L4D_SetTempHealth(client, 0.0);
    }
    if(sm_chapterhealth_medkit.BoolValue)
    {
        // Check if we have a medkit before giving out a new one.
        int medkit = GetPlayerWeaponSlot(client, view_as<int>(L4DWeaponSlot_FirstAid));
        if(medkit != INVALID_ENT_REFERENCE || IsValidEntity(medkit)) return;
        // Don't have a medkit give one out.
        GiveItem(client, "first_aid_kit");
    }
}
public void Event_PlayerFirstSpawn(Event event, const char[] szName, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client) return;
    if(!IsClientInGame(client)) return;
    if(GetClientTeam(client) != L4D_TEAM_SURVIVOR) return;
    if(L4D_IsFirstMapInScenario())
    {
        int weapon = GetPlayerWeaponSlot(client, view_as<int>(L4DWeaponSlot_Primary));
        if(weapon == INVALID_ENT_REFERENCE || !IsValidEntity(weapon))
        {
            GiveItem(client, "rifle_m60");
            GiveItem(client, "first_aid_kit");
        }
    }
}

void GiveItem(int client, const char[] szItem)
{
    int flags = GetCommandFlags("give");
    SetCommandFlags("give", (flags & ~FCVAR_CHEAT));
    FakeClientCommand(client, "give %s", szItem);
    SetCommandFlags("give", flags);
}


