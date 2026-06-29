
#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>

public Plugin:myinfo = {
    name = "Chdata's fix for bad ragdolls",
    author = "Chdata",
    description = "Hexy.",
    version = "0x01",
    url = "http://steamcommunity.com/groups/tf2data"
};

public OnPluginStart()
{
    HookEvent("player_death", evDeath, EventHookMode_Pre);
    // HookEvent("player_hurt", evHurt, EventHookMode_Pre);
}

public Action:evDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

    DoDelayedDeath(iClient);

    return Plugin_Continue;
}

/*public Action:evHurt(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
    new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    new iDmg = GetEventInt(hEvent, "damageamount");

    if (iDmg > GetClientHealth(iClient))
    {
        DoDelayedDeath(iClient);
    }

    return Plugin_Continue;
}*/

DoDelayedDeath(iClient)
{
    SetEntProp(iClient, Prop_Send, "m_iHealth", 1);
        
    SetVariantString("");
    AcceptEntityInput(iClient, "SetCustomModel");
    SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1);
    // SetEntProp(Hale, Prop_Send, "m_nBody", body);

    CreateTimer(0.1, ContinueDeath, GetClientUserId(iClient));
    // ForceTeamWin(GetClientTeam(iClient)==2?3:2);
}

// public ContinueDeath(any:UserId)
public Action:ContinueDeath(Handle:hTimer, any:UserId)
{
    new iClient = GetClientOfUserId(UserId);

    if (IsValidClient(iClient))
    {
        RemoveCond(iClient, TFCond_HalloweenKart);
        ForcePlayerSuicide(iClient);
        // FakeClientCommand(iClient, "explode"); //  334 "bombinomicon death effect"
        // SDKHooks_TakeDamage(iClient, 0, 0, 900000.0, DMG_BLAST|DMG_PREVENT_PHYSICS_FORCE);
    }
}

stock bool:IsValidClient(iClient)
{
    return (0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

stock RemoveCond(iClient, TFCond:iCond)
{
    if (TF2_IsPlayerInCondition(iClient, iCond))
    {
        TF2_RemoveCondition(iClient, iCond);
    }
}

stock ForceTeamWin(iTeam)
{
    new iEnt = FindEntityByClassname2(-1, "team_control_point_master");

    if (iEnt == -1)
    {
        iEnt = CreateEntityByName("team_control_point_master");
        DispatchSpawn(iEnt);
        AcceptEntityInput(iEnt, "Enable");
    }

    SetVariantInt(iTeam);
    AcceptEntityInput(iEnt, "SetWinner");
}