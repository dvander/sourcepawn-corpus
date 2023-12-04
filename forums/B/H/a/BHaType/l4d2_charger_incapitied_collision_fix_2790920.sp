#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <sourcescramble>

public void OnPluginStart()
{
    GameData data = new GameData("l4d2_charger_incapitied_collision_fix");
    MemoryPatch patch = MemoryPatch.CreateFromConf(data, "CCharge::HandleCustomCollision::IsIncapacitated");
    
    if (patch == null)
        SetFailState("Failed to patch: CCharge::HandleCustomCollision::IsIncapacitated");
    
    patch.Enable();
    delete data;

    HookEvent("charger_carry_start", charger_carry);
    HookEvent("charger_carry_end", charger_carry);
}

public void charger_carry(Event event, const char[] name, bool noReplicate)
{
    int victim = GetClientOfUserId(event.GetInt("victim"));

    if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2)
        return;

    if (!L4D_IsPlayerIncapacitated(victim))
        return;

    switch(strcmp(name, "charger_carry_start") == 0)
    {
        case true: AnimHookEnable(victim, ActivityHookCharged);
        case false: AnimHookDisable(victim, ActivityHookCharged);
    }
}

public Action ActivityHookCharged(int client, int &sequence)
{
    sequence = L4D2_ACT_TERROR_CARRIED;
    return Plugin_Changed;
}