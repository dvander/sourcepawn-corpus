// vim: set ai et ts=4 sw=4 syntax=sourcepawn :

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "KillGod"
#define PLUGIN_VERSION "1.00"

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = "Sneakret <sneakret@sodahappy.com>",
    description = "Grants temporary god mode on every kill.",
    version = PLUGIN_VERSION,
    url = "http://www.sodahappy.com/"
};

Handle:CreateVersionConVar()
{
    new String:versionCvarName[60];
    Format(
        versionCvarName,
        sizeof(versionCvarName),
        "sm_%s_version",
        PLUGIN_NAME);

    new cvarNameLength = strlen(versionCvarName);
    for (new i = 0; i < cvarNameLength; i++)
    {
        versionCvarName[i] = CharToLower(versionCvarName[i]);
        if (versionCvarName[i] == ' ')
        {
            versionCvarName[i] = '_';
        }
    }

    new String:versionCvarDescription[60];
    Format(
        versionCvarDescription,
        sizeof(versionCvarDescription),
        "%s plugin version number.",
        PLUGIN_NAME);

    return CreateConVar(
        versionCvarName,
        PLUGIN_VERSION,
        versionCvarDescription,
        FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
}

new Handle:killGodModeTimeoutSecondsConVarHandle = INVALID_HANDLE;

// Timer handles for god mode revocation, indexed by client entity (slot 0 has
// no meaning).
new Handle:revokeGodModeTimerHandleByClientEntity[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

public OnPluginStart()
{
    CreateVersionConVar();

    killGodModeTimeoutSecondsConVarHandle =
        CreateConVar("sm_kill_god_timeout_seconds", "3.0", "Seconds of god mode granted on kill.");

    HookEvent("player_death", OnPlayerDeath);
}

OnClientConnect(clientEntity)
{
    revokeGodModeTimerHandleByClientEntity[clientEntity] = INVALID_HANDLE;
}

public Action:OnPlayerDeath(
    Handle:eventHandle,
    const String:eventName[],
    bool:dontBroadcast)
{
    new victimEntity = GetClientOfUserId(GetEventInt(eventHandle, "userid"));
    new attackerEntity = GetClientOfUserId(GetEventInt(eventHandle, "attacker"));
    if (victimEntity == attackerEntity)
    {
        // It was a suicide.
        // Do nothing.
        return Plugin_Continue;
    }

    GrantGodMode(attackerEntity);


    if (revokeGodModeTimerHandleByClientEntity[attackerEntity] != INVALID_HANDLE)
    {
        KillTimer(revokeGodModeTimerHandleByClientEntity[attackerEntity]);
    }

    revokeGodModeTimerHandleByClientEntity[attackerEntity] = CreateTimer(
        GetConVarFloat(killGodModeTimeoutSecondsConVarHandle),
        OnRevokeGodModeTimer,
        GetClientUserId(attackerEntity));

    return Plugin_Continue;
}

GrantGodMode(clientEntity)
{
    SetEntProp(clientEntity, Prop_Data, "m_takedamage", 1, 1);
}

RevokeGodMode(clientEntity)
{
    SetEntProp(clientEntity, Prop_Data, "m_takedamage", 2, 1);
}

public Action:OnRevokeGodModeTimer(Handle:timerHandle, any:clientUserId)
{
    new clientEntity = GetClientOfUserId(clientUserId);
    if (clientEntity == 0)
    {
        // The client has disconnected.
        // Do nothing.
        return Plugin_Continue;
    }

    revokeGodModeTimerHandleByClientEntity[clientEntity] = INVALID_HANDLE;

    if (IsClientConnected(clientEntity) && IsClientInGame(clientEntity))
    {
        RevokeGodMode(clientEntity);
    }

    return Plugin_Continue;
}
