#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define CVAR_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY
#pragma newdecls required

bool TeleportReady;

public Plugin myinfo =
{
	name = "L4D2 MultiSlots",
	description = "Handles bots in a 4+ coop game.",
	author = "SwiftReal, MI 5",
	version = "3.7.8",
	url = "N/A"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_join1", JoinTeam1, 	"Attempt to join spectator.", 0);
	RegConsoleCmd("sm_join2", JoinTeam2, 	"Attempt to join survivors.", 0);
	RegConsoleCmd("sm_join3", JoinTeam3, 	"Attempt to join zombie.", 0);

	HookEvent("player_activate", ePlayerActivate);
	HookEvent("bot_player_replace", bot_player_replace);
	HookEvent("finale_vehicle_leaving", eFinaleVehicleLeaving);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_first_spawn", eplayer_first_spawn);
}

public Action JoinTeam1(int client, int args)
{
	if (client)
	{
		ChangeClientTeam(client, 1);
	}
	return Plugin_Handled;
}

public Action JoinTeam3(int client, int args)
{
	if (client)
	{
		ChangeClientTeam(client, 3);
	}
	return Plugin_Handled;
}

public void OnMapStart()
{
	TweakSettings();
	TeleportReady = false;
	CreateTimer(60.0, TimerUnblockTeleport, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerUnblockTeleport(Handle timer)
{
	TeleportReady = true;
}

public Action JoinTeam2(int client, int args)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 3)
		{
			ChangeClientTeam(client, 1);
		}

		if (GetClientTeam(client) == 2 || IsClientIdle(client))
		{
			return Plugin_Handled;
		}

		if (TotalFreeBots() == 0)
			{
				SpawnFakeClient();
				CreateTimer(1.5, Timer_AutoJoinTeamPA, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		else
			{
				TakeOverBot(client, false);
			}
	}
	return Plugin_Handled;
}

public Action ePlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) != 2 && !IsFakeClient(client) && !IsClientIdle(client) && GetClientTeam(client) != 3)
			{
				CreateTimer(5.0, Timer_AutoJoinTeamPA, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));

	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2 || IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (TeleportReady)
	{
		CreateTimer(1.0, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action eplayer_first_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client || !IsClientInGame(client) || GetClientTeam(client) != 2 || IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	if (TeleportReady)
	{
		CreateTimer(10.0, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action eFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	int edict_index = FindEntityByClassname(-1, "info_survivor_position");
	if (edict_index != -1)
		{
			float pos[3];
			GetEntPropVector(edict_index, Prop_Send, "m_vecOrigin", pos);
			for (int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
						{
							if (!IsFakeClient(i))
								{
									if(GetClientTeam(i) == 2 && IsPlayerAlive(i))
										{
											TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
										}
								}
						}
				}
		}
}

public Action Timer_AutoJoinTeamPA(Handle timer, int client)
{
	if (client)
	{
		if(IsClientInGame(client))
		{
			if (!IsFakeClient(client) && GetClientTeam(client) != 3)
			{
				if (GetClientTeam(client) != 2 || !IsClientIdle(client))
				{
					JoinTeam2(client, 0);
				}
			}
		}
	}
}

public Action evtBotReplacedPlayer(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(GetEventInt(event, "bot"));
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	
	if(GetClientTeam(bot) == 2 && client)
		{
			CreateTimer(5.0, Timer_KickNoNeededBot, bot);
		}
}

public Action Timer_KickNoNeededBot(Handle timer, int bot)
{
	if(IsClientInGame(bot) && TotalSurvivors() > 4)
	{
		char BotName[100];
		GetClientName(bot, BotName, sizeof(BotName));
		if(StrEqual(BotName, "FakeClient", true))
			return;

		if(!HasIdlePlayer(bot) && GetClientTeam(bot) == 2)
		{
			KickClient(bot, "Kicking No Needed Bot");
		}
	}
}

public Action Timer_KickFakeBot(Handle timer, int userid)
{
	int fakeclient = GetClientOfUserId(userid);
	if (fakeclient && IsClientInGame(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");
	}
}

public Action Timer_CheckClient(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2 && GetClientTeam(i) != 3 && client != i)
				{
					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);

					CreateTimer(5.0, Mortal, client);
					CreateTimer(5.0, Mortal, i);

					float pos[3] = 0.0;
					GetClientAbsOrigin(i, pos);
					TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
					return;
				}
			}
		}
	}
}

public Action Mortal(Handle timer, int client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}

void TweakSettings()
{
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
}

void TakeOverBot(int client, bool completely)
{
	if (IsClientInGame(client))
	{
		if (!IsFakeClient(client))
		{
			if (GetClientTeam(client) != 2)
			{
				int bot = FindBotToTakeOver();
				if (bot==0)
				{
					LogMessage("'There are no survivor bots to take over %N'", client);
					return;
				}

				Handle hSetHumanSpec;
				if (!hSetHumanSpec)
				{
					Handle hGameConf = LoadGameConfigFile("multislots");
					StartPrepSDKCall(SDKCall_Player);
					PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
					PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
					hSetHumanSpec = EndPrepSDKCall();
				}
				Handle hTakeOverBot;
				if (!hTakeOverBot)
				{
					Handle hGameConf = LoadGameConfigFile("multislots");
					StartPrepSDKCall(SDKCall_Player);
					PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
					PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
					hTakeOverBot = EndPrepSDKCall();
				}
				if (completely)
				{
					SDKCall(hSetHumanSpec, bot, client);
					SDKCall(hTakeOverBot, client, true);
				}
				else
				{
					SDKCall(hSetHumanSpec, bot, client);
					SetEntProp(client, Prop_Send, "m_iObserverMode", 5);
				}
			}
		}
	}
}

int FindBotToTakeOver()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2 && !HasIdlePlayer(i))
			{
				return i;
			}
		}
	}
	return 0;
}

int SpawnFakeClient()
{
	int fakeclient = CreateFakeClient("FakeClient");
	bool fakeclientKicked;

	if (fakeclient)
	{
		ChangeClientTeam(fakeclient, 2);
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			if (DispatchSpawn(fakeclient) == true)
			{
				CreateTimer(0.1, Timer_KickFakeBot, fakeclient);
				fakeclientKicked = true;
			}
		}
		if (fakeclientKicked)
		{
			KickClient(fakeclient, "Kicking FakeClient");
		}
		else
		{
			KickClient(fakeclient, "Kicking FakeClient: error");
		}
	}
	return fakeclientKicked;
}

int TotalSurvivors()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
			if (GetClientTeam(i) == 2)
			{
				count++;
			}
	}
	return count;
}

int TotalFreeBots()
{
	int count = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 2)
			{
				if (!HasIdlePlayer(i))
				{
					count++;
				}
			}
		}
	}
	return count;
}

bool HasIdlePlayer(int bot)
{
	if (IsValidEntity(bot))
	{
		char sClass[64];
		static PropFieldType type;

		if (IsClientInGame(bot))
		{
			if (GetClientTeam(bot) == 2 && IsPlayerAlive(bot))
			{
				GetEntityNetClass(bot, sClass, 64);
				if (IsFakeClient(bot) && FindSendPropInfo(sClass, "m_humanSpectatorUserID", type) > 0)
				{
					int idler = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
					if (idler)
					{
						if (IsClientInGame(idler) && !IsFakeClient(idler) && GetClientTeam(idler) == 1)
						{
							return true;
						}
					}
				}
			}
		}
	}
	return false;
}

bool IsClientIdle(int client)
{
	if (IsValidEntity(client))
	{
		char sClass[64];
		static PropFieldType type;
		for(int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2 && IsPlayerAlive(i))
				{
					GetEntityNetClass(i, sClass, 64);
					if (IsFakeClient(i) && FindSendPropInfo(sClass, "m_humanSpectatorUserID", type) > 0)
					{
						int idler = GetClientOfUserId(GetEntProp(i, Prop_Send, "m_humanSpectatorUserID"));
						if (client == idler)
						{
							if (IsClientInGame(idler) && !IsFakeClient(idler) && GetClientTeam(idler) == 1)
							{
								return true;
							}
						}
					}
				}
			}
		}
	}
	return false;
}