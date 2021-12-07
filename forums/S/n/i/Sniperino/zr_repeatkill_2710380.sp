#pragma semicolon 1

#include <sourcemod>
#include <zepremium>

#define PLUGIN_NAME 	"ZR Repeat Kill Detector"
#define PLUGIN_VERSION 	"1.0.3"

Handle g_hRespawnDelay = INVALID_HANDLE;
float g_fDeathTime[MAXPLAYERS+1];
bool g_bBlockRespawn = false;
 
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony & Sniper007",
	description = "Disables respawning on maps with repeat killers (version for Zombie Escape Premium)",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{		
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", OnPlayerDeath);
}

public OnClientDisconnect(client)
{
	g_fDeathTime[client] = 0.0;
}

public void Event_RoundStart(Event event, const char[] name, bool bDontBroadcast)
{
	g_bBlockRespawn = false;
}

public OnPlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	if (g_bBlockRespawn)
		return;
		
	char weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim && !attacker && StrEqual(weapon, "trigger_hurt"))
	{
		float fGameTime = GetGameTime();
		
		if (fGameTime - g_fDeathTime[victim] - 1.0 < 5.0)
		{
			PrintToChatAll(" \x04[Zombie-Escape]\x01 Repeat killer detected. Disabling respawn for this round.");
			g_bBlockRespawn = true;
			int respawn = 1;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					ZR_RespawnAction(i, respawn);
				}
			}
		}
		
		g_fDeathTime[victim] = fGameTime;
	}
}

stock bool IsValidClient(int client, bool alive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && (alive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	
	return false;
}

