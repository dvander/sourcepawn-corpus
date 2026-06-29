#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "Permanent Corpses",
    author      = "jahpeg",
    description = "prevents ragdoll deletion on respawn",
    version     = "1.0",
    url         = ""
};

public void OnPluginStart()
{
HookEvent("player_death", player_death, EventHookMode_Post);
}

public void player_death(Handle event, const char[] name, bool dontbroadcast)
{
	int userID = GetEventInt(event, "userid");
	int user = GetClientOfUserId(userID);

// this is retarded, but fixes weirdness
	CreateTimer(1.9, ConvertDeathRagdollToPermanent, user);
}

public Action ConvertDeathRagdollToPermanent(Handle timer, int user)
{
	SetEntPropEnt(user, Prop_Send, "m_hRagdoll", -1);
}