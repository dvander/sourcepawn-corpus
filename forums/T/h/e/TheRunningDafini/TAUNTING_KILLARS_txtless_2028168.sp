#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Taunt Killars",
	author = "Dafini",
	description = "Taunt after EVERY GODDAMN KILL",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

new Handle:TheKiller = INVALID_HANDLE;
new Handle:KillerClient = INVALID_HANDLE;

public OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    TheKiller = GetEventInt(event, "attacker");
    KillerClient = GetClientOfUserId(TheKiller);
    FakeClientCommand(KillerClient, "taunt");
}