#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.5"

char survivorName[8][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis"
};

public Plugin myinfo =
{
	name = "Black And White Notifier",
	author = "DarkNoghri, madcap, Merudo, cravenge",
	description = "Notifies Everyone When Someone Is Going To Die.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

ConVar cNotify, cNotifyMode, cGlow;
int iNotify, iNotifyMode, iGameMode;
bool isL4D1, bGlow, isDying[MAXPLAYERS+1], isChanging[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char playedGame[12];
	GetGameFolderName(playedGame, sizeof(playedGame));
	if (StrEqual(playedGame, "left4dead2", false))
	{
		isL4D1 = false;
	}
	else
	{
		if (StrEqual(playedGame, "left4dead", false))
		{
			isL4D1 = true;
		}
		else
		{
			strcopy(error, err_max, "[BAWN] Plugin Supports L4D And L4D2 Only!");
			return APLRes_SilentFailure;
		}
	}
	
	CreateNative("UpdateGlow", BAWN_UpdateGlow);
	
	RegPluginLibrary("bawn_helpers");
	return APLRes_Success;
}

public BAWN_UpdateGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsSurvivor(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Must Be A Survivor!");
	}
	
	bool state = bool:GetNativeCell(2);
	
	isDying[client] = state;
	SurvivorGlow(client, state);
}

public void OnPluginStart()
{
	ValidateGame();
	
	CreateConVar("black_and_white_notifier_version", PLUGIN_VERSION, "Black And White Notifier Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("heal_success", OnHealSuccess);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	HookEvent("round_end", OnRoundEnd);
	
	cNotify = CreateConVar("black_and_white_notifier_notify", "1", "Notifications: 0=Off, 1=Survivors Only, 2=On, 3=Infected Only", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	cNotifyMode = CreateConVar("black_and_white_notifier_notify_mode", "1", "Notifications Mode: 0=Chat Text, 1=Hint Box", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cGlow = CreateConVar("black_and_white_notifier_glow", "1", "Enable/Disable Glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	iNotify = cNotify.IntValue;
	iNotifyMode = cNotifyMode.IntValue;
	bGlow = cGlow.BoolValue;
	
	HookConVarChange(cNotify, ChangeVars);
	HookConVarChange(cNotifyMode, ChangeVars);
	HookConVarChange(cGlow, ChangeVars);
	
	AutoExecConfig(true, "black_and_white_notifier");
}

public void ChangeVars(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iNotify = cNotify.IntValue;
	iNotifyMode = cNotifyMode.IntValue;
	bGlow = cGlow.BoolValue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			isDying[i] = false;
			isChanging[i] = false;
		}
	}
	
	CreateTimer(5.0, CheckPlayers);
}

public Action CheckPlayers(Handle timer)
{
	if (iGameMode != 1)
	{
		return Plugin_Stop;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_currentReviveCount") == FindConVar("survivor_max_incapacitated_count").IntValue)
		{
			isDying[i] = true;
			SurvivorGlow(i, true);
		}
	}
	
	return Plugin_Stop;
}

public Action OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!event.GetBool("lastlife"))
	{
		return Plugin_Continue;
	}
	
	int dying = GetClientOfUserId(event.GetInt("subject"));
	if (!IsSurvivor(dying))
	{
		return Plugin_Continue;
	}
	
	if (bGlow)
	{
		isDying[dying] = true;
		SurvivorGlow(dying, true);
	}
	
	switch (iNotifyMode)
	{
		case 0:
		{
			switch (iNotify)
			{
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(dying) || IsFakeClient(i))
						{
							continue;
						}
						
						if (!isL4D1)
						{
							if (IsFakeClient(dying))
							{
								PrintToChat(i, "%N Is About To Die!", dying);
							}
							else
							{
								PrintToChat(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
							}
						}
						else
						{
							if (!IsFakeClient(dying))
							{
								PrintToChat(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", dying);
							}
						}
					}
				}
				case 2:
				{
					if (isL4D1)
					{
						if (!IsFakeClient(dying))
						{
							PrintToChatAll("%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
						}
						else
						{
							PrintToChatAll("%N Is About To Die!", dying);
						}
					}
					else
					{
						if (IsFakeClient(dying))
						{
							PrintToChatAll("%N Is About To Die!", dying);
						}
						else
						{
							PrintToChatAll("%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(dying) || IsFakeClient(i))
						{
							continue;
						}
						
						if (!isL4D1)
						{
							if (IsFakeClient(dying))
							{
								PrintToChat(i, "%N Is About To Die!", dying);
							}
							else
							{
								PrintToChat(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
							}
						}
						else
						{
							if (!IsFakeClient(dying))
							{
								PrintToChat(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", dying);
							}
						}
					}
				}
			}
		}
		case 1:
		{
			switch (iNotify)
			{
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(dying) || IsFakeClient(i))
						{
							continue;
						}
						
						if (isL4D1)
						{
							if (IsFakeClient(dying))
							{
								PrintHintText(i, "%N Is About To Die!", dying);
							}
							else
							{
								PrintHintText(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
							}
						}
						else
						{
							if (!IsFakeClient(dying))
							{
								PrintHintText(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
							}
							else
							{
								PrintHintText(i, "%N Is About To Die!", dying);
							}
						}
					}
				}
				case 2:
				{
					if (!isL4D1)
					{
						if (!IsFakeClient(dying))
						{
							PrintHintTextToAll("%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
						}
						else
						{
							PrintHintTextToAll("%N Is About To Die!", dying);
						}
					}
					else
					{
						if (IsFakeClient(dying))
						{
							PrintHintTextToAll("%N Is About To Die!", dying);
						}
						else
						{
							PrintHintTextToAll("%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(dying) || IsFakeClient(i))
						{
							continue;
						}
						
						if (isL4D1)
						{
							if (IsFakeClient(dying))
							{
								PrintHintText(i, "%N Is About To Die!", dying);
							}
							else
							{
								PrintHintText(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter") + 4]);
							}
						}
						else
						{
							if (!IsFakeClient(dying))
							{
								PrintHintText(i, "%N (%s) Is About To Die!", dying, survivorName[GetEntProp(dying, Prop_Send, "m_survivorCharacter")]);
							}
							else
							{
								PrintHintText(i, "%N Is About To Die!", dying);
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int healed = GetClientOfUserId(event.GetInt("subject"));
	if (!IsSurvivor(healed))
	{
		return Plugin_Continue;
	}
	
	if (bGlow)
	{
		SurvivorGlow(healed, false);
		isDying[healed] = false;
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(died))
	{
		return Plugin_Continue;
	}
	
	if (bGlow)
	{
		SurvivorGlow(died, false);
		isDying[died] = false;
	}
	
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	if (killer > 0 && killer != died)
	{
		PrintHintTextToAll("%N Killed %N!", killer, died);
	}
	else
	{
		PrintHintTextToAll("%N Is Dead!", died);
	}
	return Plugin_Continue;
}

public Action OnReplaceEvents(Event event, const char[] name, bool dontBroadcast)
{
	int replace1 = GetClientOfUserId(event.GetInt("player"));
	int replace2 = GetClientOfUserId(event.GetInt("bot"));
	
	if (replace1 <= 0 || !IsClientInGame(replace1) || IsFakeClient(replace1))
	{
		return Plugin_Continue;
	}
	
	if (StrEqual(name, "player_bot_replace"))
	{
		isDying[replace2] = isDying[replace1];
		isDying[replace1] = false;
		
		SurvivorGlow(replace2, isDying[replace2]);
	}
	else if (StrEqual(name, "bot_player_replace"))
	{
		if (GetClientTeam(replace1) == 2)
		{
			isDying[replace1] = isDying[replace2];
			isDying[replace2] = false;
			
			SurvivorGlow(replace1, isDying[replace1]);
		}
	}
	return Plugin_Continue;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (iGameMode != 2)
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SurvivorGlow(i, false);
			isDying[i] = false;
		}
	}
	
	return Plugin_Continue;
}

void ValidateGame()
{
	char currentGameMode[16];
	FindConVar("mp_gamemode").GetString(currentGameMode, sizeof(currentGameMode));
	if (StrEqual(currentGameMode, "coop", false) || (!isL4D1 && StrEqual(currentGameMode, "realism", false)))
	{
		iGameMode = 1;
	}
	else if (StrContains(currentGameMode, "versus", false) != -1 || (!isL4D1 && StrContains(currentGameMode, "scavenge", false) != -1))
	{
		iGameMode = 2;
	}
	else if (StrEqual(currentGameMode, "survival", false))
	{
		iGameMode = 3;
	}
	else
	{
		iGameMode = 0;
	}
}

void SurvivorGlow(int client, bool apply)
{
	if (apply)
	{
		if (isL4D1)
		{
			isChanging[client] = true;
			SetEntityRenderColor(client, 255, 0, 0, 255);
			
			CreateTimer(2.0, ChangeGlow, client, TIMER_REPEAT);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 3);
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 16777215);
		}
	}
	else
	{
		if (!isL4D1)
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		}
		else
		{
			SetEntityRenderColor(client);
			isChanging[client] = false;
		}
	}
}

public Action ChangeGlow(Handle timer, any client)
{
	if (!isDying[client])
	{
		return Plugin_Stop;
	}
	
	if (isChanging[client])
	{
		SetEntityRenderColor(client);
		isChanging[client] = false;
	}
	else
	{
		isChanging[client] = true;
		SetEntityRenderColor(client, 255, 0, 0, 255);
	}
	return Plugin_Continue;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

