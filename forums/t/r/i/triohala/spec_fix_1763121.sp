#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Spectator FIX",
	author = "triohala",
	description = "Fix gun bug in spectate mode",
	version = "0.1",
	url = ""
};

public OnPluginStart( )
{
	RegConsoleCmd("jointeam", Fix);
	RegConsoleCmd("spectate", Fix);
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnClientDisconnect(client) 
{ 
    SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:Fix(client, args)
{
	StripAllWeapons(client);
	return Plugin_Continue;
}

stock StripAllWeapons(iClient)
{
    new iEnt;
    for (new i = 0; i <= 4; i++)
    {
        while ((iEnt = GetPlayerWeaponSlot(iClient, i)) != -1)
        {
            RemovePlayerItem(iClient, iEnt);
            RemoveEdict(iEnt);
        }
    }
}

public Action:OnWeaponCanUse(client, weapon)
{
	if (IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	return Plugin_Handled;
}