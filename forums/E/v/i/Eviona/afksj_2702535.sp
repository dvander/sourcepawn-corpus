#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
	name        = "Afk Oyunculara Target Atma SonJeton",
	author      = "Eviona`",
	description = "AFK Target",
	version     = "1.0",
};

new Handle:g_PluginTagi = INVALID_HANDLE;

new iSonHareket[MAXPLAYERS+1];

public OnPluginStart() 
{
	HookEvent("round_start", Event_Round_Start);
	AddMultiTargetFilter("@afk", AFKOyuncu, "AFK Oyuncular", false);
}

public Action:Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new i, zaman = GetTime() + 10;
	for(i=1;i<=MaxClients;i++)
		iSonHareket[i] = zaman;
	CreateTimer(30.0, AfkKontrol);
}


public Action AfkKontrol(Handle timer)
{
	new i;
	for(i=1;i<=MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(iSonHareket[i] + 20 <= GetTime())
			{
			}
		}
	}
}

public bool:AFKOyuncu(const String:pattern[], Handle:clients)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(iSonHareket[i] + 20 <= GetTime())
			{
				PushArrayCell(clients, i);
			}
		}
	}
	return true;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if((buttons & IN_FORWARD) || (buttons & IN_JUMP) || (buttons & IN_MOVELEFT) || (buttons & IN_BACK) || (buttons & IN_MOVERIGHT) || (buttons & IN_DUCK) || (buttons & IN_SPEED) || (buttons & IN_USE) || (buttons & IN_ATTACK) || (buttons & IN_ATTACK2))
	{
		if(GetTime() > iSonHareket[client])
			iSonHareket[client] = GetTime() + 1;
	}
}
