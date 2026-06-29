#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "2.1"

ConVar bawnAnnounce, bawnAnnounceMode, bawnOutline;
int iAnnounce, iAnnounceMode, iGameMode;
bool bIsL4D1, bOutline, bIsBW[MAXPLAYERS+1], bIsFatal[MAXPLAYERS+1];

char sSurvivorNames[9][] =
{
	"Nick",
	"Rochelle",
	"Coach",
	"Ellis",
	"Bill",
	"Zoey",
	"Francis",
	"Louis",
	"Ada"
};

char sSurvivorModels[9][] =
{
	"models/survivors/survivor_gambler.mdl",
	"models/survivors/survivor_producer.mdl",
	"models/survivors/survivor_coach.mdl",
	"models/survivors/survivor_mechanic.mdl",
	"models/survivors/survivor_namvet.mdl",
	"models/survivors/survivor_teenangst.mdl",
	"models/survivors/survivor_biker.mdl",
	"models/survivors/survivor_manager.mdl",
	"models/survivors/survivor_adawong.mdl"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (StrEqual(sGameName, "left4dead2", false))
	{
		bIsL4D1 = false;
	}
	else
	{
		if (StrEqual(sGameName, "left4dead", false))
		{
			bIsL4D1 = true;
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
		return;
	}
	
	bool state = view_as<bool>(GetNativeCell(2));
	
	bIsBW[client] = state;
	SurvivorGlow(client, state);
}

public Plugin myinfo =
{
	name = "Black And White Notifier",
	author = "DarkNoghri, madcap, Merudo, cravenge",
	description = "Notifies Everyone When Someone Is Going To Die.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	CreateConVar("black_and_white_notifier_version", PLUGIN_VERSION, "Black And White Notifier Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
	bawnAnnounce = CreateConVar("black_and_white_notifier_notify", "1", "Notifications: 0=Off, 1=Survivors Only, 2=On, 3=Infected Only", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	bawnAnnounceMode = CreateConVar("black_and_white_notifier_notify_mode", "1", "Notifications Mode: 0=Chat Text, 1=Hint Box", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bawnOutline = CreateConVar("black_and_white_notifier_glow", "1", "Enable/Disable Glow", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	iAnnounce = bawnAnnounce.IntValue;
	iAnnounceMode = bawnAnnounceMode.IntValue;
	bOutline = bawnOutline.BoolValue;
	
	HookConVarChange(bawnAnnounce, OnBAWNCVarsChanged);
	HookConVarChange(bawnAnnounceMode, OnBAWNCVarsChanged);
	HookConVarChange(bawnOutline, OnBAWNCVarsChanged);
	
	AutoExecConfig(true, "black_and_white_notifier");
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("heal_success", OnHealSuccess);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	HookEvent("round_end", OnRoundEnd);
}

public void OnBAWNCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iAnnounce = bawnAnnounce.IntValue;
	iAnnounceMode = bawnAnnounceMode.IntValue;
	bOutline = bawnOutline.BoolValue;
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			bIsBW[i] = false;
			bIsFatal[i] = false;
		}
	}
	
	CreateTimer(5.0, CheckPlayers);
	return Plugin_Continue;
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
			bIsBW[i] = true;
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
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (!IsSurvivor(revived))
	{
		return Plugin_Continue;
	}
	
	if (bOutline)
	{
		bIsBW[revived] = true;
		SurvivorGlow(revived, true);
	}
	
	int iNumMatch = -1;
	
	char sSubjectModel[128];
	GetClientModel(revived, sSubjectModel, sizeof(sSubjectModel));
	for (int i = 0; i < 9; i++)
	{
		if (StrEqual(sSubjectModel, sSurvivorModels[i]))
		{
			iNumMatch = i;
			break;
		}
	}
	
	switch (iAnnounceMode)
	{
		case 0:
		{
			switch (iAnnounce)
			{
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(revived) || IsFakeClient(i))
						{
							continue;
						}
						
						if (!bIsL4D1)
						{
							if (IsFakeClient(revived))
							{
								PrintToChat(i, "%N Is About To Die!", revived);
							}
							else
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
						}
						else
						{
							if (!IsFakeClient(revived))
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", revived);
							}
						}
					}
				}
				case 2:
				{
					if (bIsL4D1)
					{
						if (!IsFakeClient(revived))
						{
							PrintToChatAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
						}
						else
						{
							PrintToChatAll("%N Is About To Die!", revived);
						}
					}
					else
					{
						if (IsFakeClient(revived))
						{
							PrintToChatAll("%N Is About To Die!", revived);
						}
						else
						{
							PrintToChatAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(revived) || IsFakeClient(i))
						{
							continue;
						}
						
						if (!bIsL4D1)
						{
							if (IsFakeClient(revived))
							{
								PrintToChat(i, "%N Is About To Die!", revived);
							}
							else
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
						}
						else
						{
							if (!IsFakeClient(revived))
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", revived);
							}
						}
					}
				}
			}
		}
		case 1:
		{
			switch (iAnnounce)
			{
				case 1:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(revived) || IsFakeClient(i))
						{
							continue;
						}
						
						if (bIsL4D1)
						{
							if (IsFakeClient(revived))
							{
								PrintHintText(i, "%N Is About To Die!", revived);
							}
							else
							{
								PrintHintText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
							}
						}
						else
						{
							if (!IsFakeClient(revived))
							{
								PrintHintText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintHintText(i, "%N Is About To Die!", revived);
							}
						}
					}
				}
				case 2:
				{
					if (!bIsL4D1)
					{
						if (!IsFakeClient(revived))
						{
							PrintHintTextToAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
						}
						else
						{
							PrintHintTextToAll("%N Is About To Die!", revived);
						}
					}
					else
					{
						if (IsFakeClient(revived))
						{
							PrintHintTextToAll("%N Is About To Die!", revived);
						}
						else
						{
							PrintHintTextToAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
						}
					}
				}
				case 3:
				{
					for (int i = 1; i <= MaxClients; i++)
					{
						if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(revived) || IsFakeClient(i))
						{
							continue;
						}
						
						if (bIsL4D1)
						{
							if (IsFakeClient(revived))
							{
								PrintHintText(i, "%N Is About To Die!", revived);
							}
							else
							{
								PrintHintText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch + 4]);
							}
						}
						else
						{
							if (!IsFakeClient(revived))
							{
								PrintHintText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintHintText(i, "%N Is About To Die!", revived);
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
	
	if (bOutline)
	{
		bIsBW[healed] = false;
		SurvivorGlow(healed, false);
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
	
	if (bOutline)
	{
		bIsBW[died] = false;
		SurvivorGlow(died, false);
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
	int player = GetClientOfUserId(event.GetInt("player")),
		bot = GetClientOfUserId(event.GetInt("bot"));
	
	if (player <= 0 || !IsClientInGame(player) || IsFakeClient(player))
	{
		return Plugin_Continue;
	}
	
	if (StrEqual(name, "player_bot_replace"))
	{
		bIsBW[bot] = bIsBW[player];
		bIsBW[player] = false;
		
		SurvivorGlow(bot, bIsBW[bot]);
	}
	else if (StrEqual(name, "bot_player_replace"))
	{
		if (GetClientTeam(player) == 2)
		{
			bIsBW[player] = bIsBW[bot];
			bIsBW[bot] = false;
			
			SurvivorGlow(player, bIsBW[player]);
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
			bIsBW[i] = false;
			SurvivorGlow(i, false);
		}
	}
	
	return Plugin_Continue;
}

void CheckGameMode()
{
	char sGameMode[16];
	FindConVar("mp_gamemode").GetString(sGameMode, sizeof(sGameMode));
	if (StrEqual(sGameMode, "coop", false) || (!bIsL4D1 && StrEqual(sGameMode, "realism", false)))
	{
		iGameMode = 1;
	}
	else if (StrContains(sGameMode, "versus", false) != -1 || (!bIsL4D1 && StrContains(sGameMode, "scavenge", false) != -1))
	{
		iGameMode = 2;
	}
	else if (StrEqual(sGameMode, "survival", false))
	{
		iGameMode = 3;
	}
	else
	{
		iGameMode = 0;
	}
}

void SurvivorGlow(int client, bool bApply)
{
	if (bApply)
	{
		if (bIsL4D1)
		{
			bIsFatal[client] = true;
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, _, 0, 0);
			
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
		if (!bIsL4D1)
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
		}
		else
		{
			bIsFatal[client] = false;
			
			SetEntityRenderMode(client, RENDER_NONE);
			SetEntityRenderColor(client);
		}
	}
}

public Action ChangeGlow(Handle timer, any client)
{
	if (!IsClientInGame(client) || !IsValidEntity(client))
	{
		return Plugin_Stop;
	}
	
	if (!bIsBW[client])
	{
		SetEntityRenderMode(client, RENDER_NONE);
		SetEntityRenderColor(client);
		
		return Plugin_Stop;
	}
	
	if (bIsFatal[client])
	{
		bIsFatal[client] = false;
		
		SetEntityRenderMode(client, RENDER_NONE);
		SetEntityRenderColor(client);
	}
	else
	{
		bIsFatal[client] = true;
		
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, _, 0, 0);
	}
	
	return Plugin_Continue;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

