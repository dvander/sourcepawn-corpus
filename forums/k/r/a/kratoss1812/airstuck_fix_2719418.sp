#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Air Stuck Exploit Fix",
	author = "kRatoss",
};

public Action OnPlayerRunCmd(int Client, int& Buttons, int& Imp, float Vel[3], float Angles[3], int& Weapon, int& Subtype, int& CMDnum, int& Tickcount, int& Seed, int Mouse[2])
{
	if(Client > 0 && IsClientInGame(Client))
	{
		if(Tickcount == 0 && Vel[0] == 0.0 && Vel[1] == 0.0 && Vel[2] == 0.0 && !(Buttons & IN_ATTACK))
		{
			CreateTimer(0.1, SlayPlayerDelayed, Client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action SlayPlayerDelayed(Handle pTimer, int Client)
{
	if(Client > 0 && IsClientInGame(Client) && IsPlayerAlive(Client))
	{
		// Announce the Player few times that he is not allowed to air stuck
		PrintToChat(Client, " \x07 [ANTI-AIRSTUCK]\x02 AirStuck is not allowed on this server.");
		PrintToChat(Client, " \x07 [ANTI-AIRSTUCK]\x02 AirStuck is not allowed on this server.");
		PrintToChat(Client, " \x07 [ANTI-AIRSTUCK]\x02 AirStuck is not allowed on this server.");
		
		// Announce the other players
		PrintToChatAll(" \x07 [ANTI-AIRSTUCK]\x01 Player\x06 %N\x01 was\x07 slayed\x01 because he tried to\x07 AIR-STUCK\x01.", Client);
		ForcePlayerSuicide(Client);
	}
}