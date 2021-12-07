#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>
#define CVAR_FLAGS					FCVAR_PLUGIN|FCVAR_NOTIFY
#pragma newdecls required

Handle l4d2_join_debuglog;

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
	LoadTranslations("join.phrases");

	RegConsoleCmd("sm_join", JoinTeam, "Attempt to join survivors.", 0);
	RegAdminCmd("sm_afk", Spec, ADMFLAG_ROOT);

	HookEvent("player_activate", 			ePlayerActivate);											// 
	HookEvent("bot_player_replace", 		bot_player_replace);										// Игрок заменил бот
	HookEvent("finale_vehicle_leaving", 	eFinaleVehicleLeaving);										// Спасательный транспорт уходит
	HookEvent("player_bot_replace", 		evtBotReplacedPlayer);										// Бот заменил игрока
	HookEvent("player_first_spawn", 		eplayer_first_spawn);										// Игрок впервые появился в данной миссии
	HookEvent("round_start", 				Event_RoundStart, 				EventHookMode_PostNoCopy);	// Старт раунда

	l4d2_join_debuglog = CreateConVar("l4d2_join_debuglog", "1", "Debugger on/off", FCVAR_PLUGIN);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(15.0, CheckFackeBots, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action CheckFackeBots(Handle timer, any client)
{
	if (TotalSurvivors() > 4)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2 && IsFakeClient(i) && TotalSurvivors() > 4)
				{
					LogDebug("Кикаю лишнего бота %N.", i);
					KickClient(i, "Kicking No Needed Bot");
				}
			}
		}
	}
}

public void OnMapStart()
{
	TweakSettings();
	TeleportReady = false;
	CreateTimer(60.0, TimerUnblockTeleport, _, TIMER_FLAG_NO_MAPCHANGE);
	LogDebug("Старт карты. Разблокировка телепорта через 60 сек.");
}

public Action TimerUnblockTeleport(Handle timer)
{
	LogDebug("Телепорт разблокирован.");
	TeleportReady = true;
}

public void OnMapEnd()
{
	LogDebug("Конец карты.");
}

public Action Spec(int client, int args)
{
	if (client)
	{
		ChangeClientTeam(client, 1);
	}
	return Plugin_Handled;
}

public Action JoinTeam(int client, int args)
{
	if (IsClientInGame(client))
	{
		if (IsClientIdle(client))
		{
			LogDebug("Джоинтеам => игрок %N наблюдает за ботом.", client);
			CPrintToChat(client, "%t", "ClientIdle");
			return Plugin_Handled;
		}

		if (GetClientTeam(client) == 2)
		{
			LogDebug("Джоинтеам => игрок %N в команде 2.", client);
			CPrintToChat(client, "%t", "ClientTeam2");
			return Plugin_Handled;
		}

		if (TotalFreeBots() == 0)
		{
			LogDebug("Джоинтеам => нет свободных ботов для игрока %N", client);
			SpawnFakeClient();
			CreateTimer(1.5, Timer_AutoJoinTeamPA, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogDebug("Джоинтеам => есть свободный бот для игрока %N", client);
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
			if (!IsFakeClient(client))
			{
				LogDebug("Подключился игрок %N", client);
				if (GetClientTeam(client) != 2 && !IsClientIdle(client))
				{
					CreateTimer(5.0, Timer_AutoJoinTeamPA, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action bot_player_replace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "player"));
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client))
			{
				LogDebug("%N заменил бота!", client);
				if (TeleportReady)
				{
					LogDebug("%N заменил бота, телепортация разрешена!", client);
					CreateTimer(10.0, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					LogDebug("%N заменил бота, телепортация блокирована!", client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action eplayer_first_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (GetClientTeam(client) == 2 && !IsFakeClient(client) && IsPlayerAlive(client))
			{
				LogDebug("%N впервые появился в данной миссии", client);
				if (TeleportReady)
				{
					LogDebug("%N впервые появился в данной миссии, заменил бота. Телепортация разрешена", client);
					CreateTimer(10.0, Timer_CheckClient, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				else
				{
					LogDebug("%N впервые появился в данной миссии, заменил бота. Телепортация запрещена", client);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action eFinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	kickbots();
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
						LogDebug("Телепортирую игрока %N в безопасную зону.", i);
						TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
						LogDebug("Телепортация игрока %N завершена.", i);
					}
					else if((GetClientTeam(i) == 2) && !IsPlayerAlive(i))
					{
						LogDebug("Игрок мертв %N и не может быть телепортирован.", i);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void kickbots()
{
	LogDebug("Спасательный транспорт уходит. Кикаю ботов.");
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			if (IsFakeClient(i) && GetClientTeam(i) == 3)
			{
				KickClient(i);
			}
		}
		i++;
	}
	LogDebug("Боты кикнуты!");
}

public Action Timer_AutoJoinTeamPA(Handle timer, int client)
{
	if (client)
	{
		if(IsClientInGame(client))
		{
			if (!IsFakeClient(client))
			{
				if (GetClientTeam(client) != 2 || !IsClientIdle(client))
				{
					LogDebug("Перезапущен 'JoinTeam' для игрока %N.", client);
					JoinTeam(client, 0);
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
		LogDebug("Игрока %N заменил бот %N", client, bot);
		CreateTimer(20.0, Timer_KickNoNeededBot, bot, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
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
			LogDebug("Бот %s кикнут.", BotName);
		}
	}
}

public Action Timer_KickFakeBot(Handle timer, int fakeclient)
{
	if (fakeclient && IsClientInGame(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient ???");
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
					LogDebug("Для телепортации %N выбран %N", client, i);

					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); 	// телепортируемый
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1); 		// на кого телепортируют

					CreateTimer(5.0, Mortal, client);
					CreateTimer(5.0, Mortal, i);

					float pos[3] = 0.0;
					GetClientAbsOrigin(i, pos);
					TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);

					LogDebug("%N телепортирован на %N", client, i);
					return;
				}
			}
			LogDebug("Не найден игрок для телепортации %N", client);
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
					LogDebug("'There are no survivor bots to take over %N'", client);
					return;
				}
				
				LogDebug("Передача свободного бота игроку %N", client);

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
				LogDebug("Передача свободного бота игроку %N завершена.", client);
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
	LogDebug("Начало создания нового бота.");

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
	LogDebug("Бот создан.");
	return fakeclientKicked;
}

int TotalSurvivors()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				count++;
			}
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

void LogDebug(const char[] format, any:...)
{
	if (GetConVarInt(l4d2_join_debuglog) == 1)
	{
		char buffer[512];
		VFormat(buffer, sizeof(buffer), format, 2);
		LogMessage("%s", buffer);
	}
}