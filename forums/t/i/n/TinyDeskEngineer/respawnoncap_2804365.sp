#include <sourcemod>
#include <events>
#include <tf2>

public Plugin myinfo =
{
	name = "[TF2] Respawn on Capture",
	description = "Instantly respawns all dead players when a control point is captured",
	author = "Tiny Desk Engineer",
	version = "1.0",
	url = ""
};

ConVar respawnMode;

public void OnPluginStart()
{
	HookEvent("teamplay_point_captured", Event_PointCaptured, EventHookMode_Post);
	respawnMode = CreateConVar("sm_capturerespawn_mode", "3", "Mode to respawn players after a capture with.", FCVAR_SERVER_CAN_EXECUTE | FCVAR_NOTIFY, true, 0.0, true, 3.0)
}

public Action Event_PointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam attackTeam = view_as<TFTeam>(event.GetInt("team"));
	
	switch (respawnMode.IntValue)
	{
		case 0:
		{
			return Plugin_Continue;
		}
		case 1:
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (view_as<TFTeam>(GetClientTeam(client)) == attackTeam && !IsPlayerAlive(client))
				{
					TF2_RespawnPlayer(client);
				}
			}
			
			return Plugin_Continue;
		}
		case 2:
		{
			TFTeam defendTeam;
			
			switch (attackTeam)
			{
				case TFTeam_Blue:
				{
					defendTeam = TFTeam_Red;
				}
				case TFTeam_Red:
				{
					defendTeam = TFTeam_Blue;
				}
			}
			
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					if (view_as<TFTeam>(GetClientTeam(client)) == defendTeam && !IsPlayerAlive(client))
					{
						TF2_RespawnPlayer(client);
					}
				}
			}
			
			return Plugin_Continue;
		}
		case 3:
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					if (view_as<TFTeam>(GetClientTeam(client)) != TFTeam_Spectator && !IsPlayerAlive(client))
					{
						TF2_RespawnPlayer(client);
					}
				}
			}
			
			return Plugin_Continue;
		}
	}
	
	return Plugin_Continue;
}