#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0.1_CT"

bool enabled;

public Plugin myinfo =
{
	name		= "NoBlock",
	author		= "Samantha",
	description	= "Players dont collide if there on the same team.",
	version		= VERSION,
	url 		= "www.foxyden.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_noblockteam_version", VERSION, "Version of Noblock Team Filter", FCVAR_REPLICATED|FCVAR_NOTIFY);
	ConVar CVar;
	HookConVarChange((CVar = CreateConVar("sm_noblockteam_enable", "1", "0/1 - Disable/Enable messages", FCVAR_NOTIFY, true, 0.0, true, 1.0)), CVarChange);
	enabled = CVar.BoolValue;
}

public void CVarChange(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	enabled = CVar.BoolValue;
}

public void OnclientPutInServer(int client)
{
	SDKHook(client, SDKHook_StartTouch, OnTouch);
}

public void OnTouch(int client, int ent)
{
	if(enabled && 0 < ent <= MaxClients && GetClientTeam(client) == 3 && GetClientTeam(ent) == 3) SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
	else SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
}