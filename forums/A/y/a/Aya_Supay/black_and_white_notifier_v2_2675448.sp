#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.56"

ConVar bawnAnnounce, bawnAnnounceMode, bawnLeftNotify, bawnLeftCounter, cvarGameMode,
	cvarMaxIncapCount;

int iAnnounce, iAnnounceMode, iMaxIncapCount, iBWEnt[MAXPLAYERS+1];
bool bLeftNotify, bLeftCounter, bCheckFix;
char sGameMode[16];

char sSurvivorNames[9][] =
{
	"Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis", "Ada"
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

public Plugin myinfo =
{
	name = "Black And White Notifier (Reloaded)",
	author = "cravenge",
	description = "Notifies Everyone When Someone Is Going To Die.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/forumdisplay.php?f=108"
};

public void OnPluginStart()
{
	cvarGameMode = FindConVar("mp_gamemode");
	cvarMaxIncapCount = FindConVar("survivor_max_incapacitated_count");
	
	iMaxIncapCount = cvarMaxIncapCount.IntValue;
	
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	cvarGameMode.AddChangeHook(OnBAWNCVarsChanged);
	cvarMaxIncapCount.AddChangeHook(OnBAWNCVarsChanged);
	
	CreateConVar("black_and_white_notifier_version", PLUGIN_VERSION, "Black And White Notifier (Reloaded) Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	bawnAnnounce = CreateConVar("bawn_notify", "1", "Notifications: 0=Off, 1=Survivors Only, 2=On, 3=Infected Only", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	bawnAnnounceMode = CreateConVar("bawn_notify_mode", "1", "Notifications Mode: 0=Chat Text, 1=Hint Box", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bawnLeftNotify = CreateConVar("bawn_left_announce", "1", "Enable/Disable Players Left Announcements", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	bawnLeftCounter = CreateConVar("bawn_left_counter", "1", "Enable/Disable Players Left Counter", FCVAR_SPONLY|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	iAnnounce = bawnAnnounce.IntValue;
	iAnnounceMode = bawnAnnounceMode.IntValue;
	
	bLeftNotify = bawnLeftNotify.BoolValue;
	bLeftCounter = bawnLeftCounter.BoolValue;
	
	bawnAnnounce.AddChangeHook(OnBAWNCVarsChanged);
	bawnAnnounceMode.AddChangeHook(OnBAWNCVarsChanged);
	bawnLeftNotify.AddChangeHook(OnBAWNCVarsChanged);
	bawnLeftCounter.AddChangeHook(OnBAWNCVarsChanged);
	
	AutoExecConfig(true, "black_and_white_notifier");
	
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("player_death", OnPlayerDeath);
	if ( IsL4D2() ) HookEvent("defibrillator_used", OnDefibrillatorUsed);	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	
	CreateTimer(0.1, BWOutlineCheck, _, TIMER_REPEAT);
}

public void OnBAWNCVarsChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	iMaxIncapCount = cvarMaxIncapCount.IntValue;
	
	cvarGameMode.GetString(sGameMode, sizeof(sGameMode));
	
	iAnnounce = bawnAnnounce.IntValue;
	iAnnounceMode = bawnAnnounceMode.IntValue;
	
	bLeftNotify = bawnLeftNotify.BoolValue;
	bLeftCounter = bawnLeftCounter.BoolValue;
}

public Action BWOutlineCheck(Handle timer)
{
	if (!IsServerProcessing() || !bCheckFix)
	{
		return Plugin_Continue;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
		{
			continue;
		}
		
		if (GetEntProp(i, Prop_Send, "m_currentReviveCount") < iMaxIncapCount)
		{
			NotifyBWState(i, false);
		}
		else
		{
			NotifyBWState(i, true);
		}
	}
	
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
		{
			continue;
		}
		if (GetEntProp(i, Prop_Send, "m_currentReviveCount") >= iMaxIncapCount)
		{
			NotifyBWState(i, false);
		}
	}
}

public void OnClientDisconnect(int client)
{
	NotifyBWState(client, false);
}

public void OnMapStart()
{ 
	if (!IsModelPrecached("materials/sprites/skull_icon.vmt")) PrecacheModel("materials/sprites/skull_icon.vmt", true);
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	if (!event.GetBool("lastlife"))
	{
		return;
	}
	
	int revived = GetClientOfUserId(event.GetInt("subject"));
	if (IsSurvivor(revived))
	{
		int iNumMatch = -1;
		
		char sSubjectModel[128];
		GetEntPropString(revived, Prop_Data, "m_ModelName", sSubjectModel, sizeof(sSubjectModel));
		
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
							
							if (!IsFakeClient(revived) && iNumMatch != -1)
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", revived);
							}
						}
					}
					case 2:
					{
						if (IsFakeClient(revived) || iNumMatch == -1)
						{
							PrintToChatAll("%N Is About To Die!", revived);
						}
						else
						{
							PrintToChatAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
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
							
							if (!IsFakeClient(revived) && iNumMatch != -1)
							{
								PrintToChat(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintToChat(i, "%N Is About To Die!", revived);
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
							
							if (!IsFakeClient(revived) && iNumMatch != -1)
							{
								PrintHintText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintHintText(i, "%N Is About To Die!", revived);
							}
						}
					}
					case 2:
					{
						if (IsFakeClient(revived) || iNumMatch == -1)
						{
							PrintHintTextToAll("%N Is About To Die!", revived);
						}
						else
						{
							PrintHintTextToAll("%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
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
							
							if (!IsFakeClient(revived) && iNumMatch != -1)
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
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(died))
	{
		return;
	}
	
	NotifyBWState(died, false);
	
	if (bLeftNotify)
	{
		if (!bCheckFix)
		{
			return;
		}
		
		int killer = GetClientOfUserId(event.GetInt("attacker"));
		if (killer > 0 && killer != died)
		{
			if (bLeftCounter)
			{
				PrintHintTextToAll("%N Killed %N!\n%d %s %s!", killer, died, GetProperSurvivorsCount(), (GetProperSurvivorsCount() != 1) ? "Survivors" : "Survivor", (GetProperSurvivorsCount() == 1) ? "Remains" : "Remain");
			}
			else
			{
				PrintHintTextToAll("%N Killed %N!", killer, died);
			}
		}
		else
		{
			if (!bLeftCounter)
			{
				PrintHintTextToAll("%N Died!", died);
			}
			else
			{
				PrintHintTextToAll("%N Died!\n%d %s %s!", died, GetProperSurvivorsCount(), (GetProperSurvivorsCount() == 1) ? "Survivor" : "Survivors", (GetProperSurvivorsCount() != 1) ? "Remain" : "Remains");
			}
		}
	}
}

public void OnDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (!bLeftNotify)
	{
		return;
	}
	
	int defibber = GetClientOfUserId(event.GetInt("userid")),
		defibbed = GetClientOfUserId(event.GetInt("subject"));
	
	if (IsSurvivor(defibber) && IsSurvivor(defibbed))
	{
		if (bLeftCounter)
		{
			PrintHintTextToAll("%N Defibbed %N!\n%d %s %s!", defibber, defibbed, GetProperSurvivorsCount(), (GetProperSurvivorsCount() != 1) ? "Survivors" : "Survivor", (GetProperSurvivorsCount() == 1) ? "Remains" : "Remain");
		}
		else
		{
			PrintHintTextToAll("%N Defibbed %N!", defibber, defibbed);
		}
	}
}

public void OnRoundEvents(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "round_end"))
	{
		if (StrContains(sGameMode, "versus", false) != -1 || StrContains(sGameMode, "scavenge", false) != -1)
		{
			bCheckFix = false;
		}
		else
		{
			return;
		}
	}
	else if (StrEqual(name, "round_start"))
	{
		bCheckFix = true;
	}
	else
	{
		bCheckFix = false;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			NotifyBWState(i, false);
		}
	}
}

public void OnReplaceEvents(Event event, const char[] name, bool dontBroadcast)
{
	int player = GetClientOfUserId(event.GetInt("player")),
		bot = GetClientOfUserId(event.GetInt("bot"));
	
	if (player < 1 || !IsClientInGame(player) || IsFakeClient(player))
	{
		return;
	}
	
	if (StrEqual(name, "player_bot_replace"))
	{
		NotifyBWState(player, false);
	}
	else if (StrEqual(name, "bot_player_replace"))
	{
		if (GetClientTeam(player) != 2)
		{
			return;
		}
		
		NotifyBWState(bot, false);
	}
}

void NotifyBWState(int client, bool bApply)
{
	if (bApply)
	{
		if (IsValidEntRef(iBWEnt[client]))
		{
			return;
		}
		
		int iGraveEnt = CreateEntityByName("env_sprite"); //env_sprite_oriented
		if (iGraveEnt != -1)
		{
			DispatchKeyValue(iGraveEnt, "model", "materials/sprites/skull_icon.vmt");
			DispatchKeyValue(iGraveEnt, "fadescale", "1");
			DispatchKeyValue(iGraveEnt, "fademindist", "20000");
			DispatchKeyValue(iGraveEnt, "fademaxdist", "22000");
			SetVariantString("!activator");
			AcceptEntityInput(iGraveEnt, "SetParent", client);
			SetVariantString("eyes");
			AcceptEntityInput(iGraveEnt, "SetParentAttachment");
			AcceptEntityInput(iGraveEnt, "ShowSprite");
			char buffer[12];
			Format(buffer, sizeof(buffer), "%i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255));
			DispatchKeyValue(iGraveEnt, "RenderColor", buffer);
			DispatchKeyValue(iGraveEnt, "RenderAmt", "255");
			TeleportEntity(iGraveEnt, view_as<float>({-3.0, 0.0, 6.0}), NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(iGraveEnt);
			
			iBWEnt[client] = EntIndexToEntRef(iGraveEnt);
		}
		else
		{
			NotifyBWState(client, true);
		}			
	}
	else
	{
		if (!IsValidEntRef(iBWEnt[client]))
		{
			return;
		}
	
		AcceptEntityInput(iBWEnt[client], "HideSprite");
		AcceptEntityInput(iBWEnt[client], "ClearParent");
		AcceptEntityInput(iBWEnt[client], "Kill");
		
		iBWEnt[client] = 0;
	}
}

int GetProperSurvivorsCount()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			iCount += 1;
		}
	}
	return iCount;
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool IsSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

stock bool IsL4D2()
{
	EngineVersion engine = GetEngineVersion();
	return ( engine == Engine_Left4Dead2 );
}