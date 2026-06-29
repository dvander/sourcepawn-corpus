#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Give scar instead of G3SG1",
	author = "Cruze",
	description = "Give scar instead of G3SG1",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public Action CS_OnBuyCommand(int client, const char[] szWeapon)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (StrContains(szWeapon, "g3sg1", false) != -1)
    {
        GivePlayerItem(client, "weapon_scar20");
        return Plugin_Handled;
    }
	return Plugin_Continue;
}