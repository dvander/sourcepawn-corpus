#pragma semicolon 1
#include <sourcemod>
#include <devzones>

ConVar g_cvGravity;
float g_fGravity;

public Plugin myinfo =
{
	name = "SM DEV Zones - Gravity",
	author = "SlidyBat",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	g_cvGravity = CreateConVar("sm_devzones_gravity", "0.5", "Value gravity is set to when player enters gravity zone", FCVAR_NOTIFY);
	g_cvGravity.AddChangeHook(OnConVarChanged);
}

public int Zone_OnClientEntry(int client, char[] zone)
{
	if(!IsValidClient(client)) 
		return;
		
	if(StrContains(zone, "gravity", false) != 0)
		return;
	
	SetEntityGravity(client, g_fGravity);
}

public int Zone_OnClientLeave(int client, char[] zone)
{
	if(!IsValidClient(client)) 
		return;
		
	if(StrContains(zone, "gravity", false) != 0)
		return;
	
	SetEntityGravity(client, 1.0);
}

public bool IsValidClient(int client) 
{ 
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || !IsPlayerAlive(client)) 
        return false; 
     
    return true; 
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fGravity = g_cvGravity.FloatValue;
}