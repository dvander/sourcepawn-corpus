#include <sourcemod>
#include <tf2_stocks>

#define __VERSION__ "1.2"

new bool:IsBonusRound = false;

public Plugin:myinfo =
{
        name = "bonusroundrespawn",
        author = "Ratty",
        description = "Respawns everyone at bonusround.",
        version = __VERSION__,
        url = ""
}

public OnPluginStart()
{

	CreateConVar("sm_bonusroundrespawn_ver", __VERSION__, "AddTime Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

        HookEvent("teamplay_round_win", Event_RoundWin, EventHookMode_PostNoCopy)
        HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_PostNoCopy)
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Timer_Respawnall(Handle:timer, any:client)
{
    for (new i = 1; i <= GetMaxClients(); i++) {
        if (IsClientConnected(i) && IsClientInGame(i)) {
            if (!IsPlayerAlive(i)) TF2_RespawnPlayer(i);
        }
    }
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
        IsBonusRound = true;
	CreateTimer(1.0, Timer_Respawnall);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
        IsBonusRound = false;
}

public OnMapStart() {
        IsBonusRound = false;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.1, Timer_Respawn, client);
    return Plugin_Continue;
}

public Action:Timer_Respawn(Handle:timer, any:client) {
    if (!IsFakeClient(client) && IsBonusRound && IsClientConnected(client) && IsClientInGame(client))
       TF2_RespawnPlayer(client);
}

