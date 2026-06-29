#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 	"1.0"

ConVar g_BotReportLog;
ConVar g_BotReportChat;
ConVar g_BotTeleport;

float lastpos[MAXPLAYERS+1][3];
bool allowedteleport[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "[RCBOT2] teleportation detect/undo",
	author = "requested by INsane",
	description = "detect/undo teleportation bug for bots",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=350861"
};

public void OnPluginStart()
{
	CreateConVar("rcbot2_fix_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_BotReportLog	= CreateConVar("rcbot2_fix_log_info", "1", "Write to log teleport start/end/distance", FCVAR_NONE, true, 0.0, true, 1.0);
	g_BotReportChat = CreateConVar("rcbot2_fix_chat_info", "0", "Write to chat teleport start/end/distance", FCVAR_NONE, true, 0.0, true, 1.0);
	g_BotTeleport = CreateConVar("rcbot2_fix_teleport", "1", "Teleport back to teleport start location", FCVAR_NONE, true, 0.0, true, 1.0);
	HookEvent("player_spawn", PlayerSpawnEvent);
}


public void OnGameFrame()
{
	for(int i = 1; i<=MaxClients; i++)
	{
		if(ValidPlayer(i, true) && IsFakeClient(i))
		{
			float vecBotPosition[3];
			GetClientAbsOrigin(i, vecBotPosition);
			
			//first teleport right after spawn is normal (allowed)
			if (!allowedteleport[i])
				allowedteleport[i] = true;
			else
			{
				//check if distance is too far ... assuming not allowed teleportation (change distance if needed)
				float distancemoved = GetVectorDistance(lastpos[i], vecBotPosition);
				if (distancemoved > 50)
				{
					if (g_BotReportLog)
						LogMessage("Bot: %N teleport from: %d %d %d to: %d %d %d (distance: %d)", i, RoundToNearest(lastpos[i][0]), RoundToNearest(lastpos[i][1]), RoundToNearest(lastpos[i][2]), RoundToNearest(vecBotPosition[0]), RoundToNearest(vecBotPosition[1]), RoundToNearest(vecBotPosition[2]), RoundToNearest(distancemoved));
					if (g_BotReportChat)
						PrintToChatAll("\x01[\x05RcBot2 Report\x01] \x04%N\x01 teleport from: \x04%d %d %d \x01to: \x04%d %d %d \x01(distance: \x04%d\x01)", i, RoundToNearest(lastpos[i][0]), RoundToNearest(lastpos[i][1]), RoundToNearest(lastpos[i][2]), RoundToNearest(vecBotPosition[0]), RoundToNearest(vecBotPosition[1]), RoundToNearest(vecBotPosition[2]), RoundToNearest(distancemoved));
					if (g_BotTeleport)
					{
						allowedteleport[i] = false;
						TeleportEntity(i, lastpos[i], NULL_VECTOR, NULL_VECTOR);	
					}
				}
			}
			lastpos[i][0] = vecBotPosition[0];
			lastpos[i][1] = vecBotPosition[1];
			lastpos[i][2] = vecBotPosition[2];
		}
	}
}

public void PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	allowedteleport[iClient] = false;
}

stock bool:ValidPlayer(client,bool:check_alive=false,bool:alivecheckbyhealth=false) {
  if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
  {
    if(check_alive && !IsPlayerAlive(client))
    {
      return false;
    }
    if(alivecheckbyhealth&&GetClientHealth(client)<1) {
      return false;
    }
    return true;
  }
  return false;
}