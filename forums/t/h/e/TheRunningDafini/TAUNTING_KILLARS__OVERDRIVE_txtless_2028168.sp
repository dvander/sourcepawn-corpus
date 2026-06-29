#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>


#define PL_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Taunt Killars OVERDRIVE",
	author = "Dafini",
	description = "Taunt after YOU HURT SOMEONE",
	version = PL_VERSION,
	url = "http://www.sourcemod.net"
}

//SM CALLBACKS

new Handle:TheKiller = INVALID_HANDLE;
new Handle:KillerClient = INVALID_HANDLE;
new Handle:TheHurt = INVALID_HANDLE;
new Handle:HurtClient = INVALID_HANDLE;

public OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
    HookEvent("npc_hurt", OnNpcHurt, EventHookMode_Post);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    TheKiller = GetEventInt(event, "attacker");
    KillerClient = GetClientOfUserId(TheKiller);
    FakeClientCommand(KillerClient, "taunt");
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    TheHurt = GetEventInt(event, "attacker");
    HurtClient = GetClientOfUserId(TheHurt);
    FakeClientCommand(HurtClient, "taunt");
}

public Action:OnNpcHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    TheHurt = GetEventInt(event, "attacker_Player");
    HurtClient = GetClientOfUserId(TheHurt);
    FakeClientCommand(HurtClient, "taunt");
}