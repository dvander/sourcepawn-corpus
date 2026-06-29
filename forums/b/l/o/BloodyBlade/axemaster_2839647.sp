#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "axe master",
	author = "gamemann",
	description = "gives clients axes at player_spawn",
	version = "1.0",
	url =  ""
};

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
}

public void OnMapStart()
{
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl");
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl");
}

void PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
    {
        PrintToChat(client, "\x03 you are getting an \x01 fireaxe");
        GivePlayerItem(client, "fireaxe");
    }
}
