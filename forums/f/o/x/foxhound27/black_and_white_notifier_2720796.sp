#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <glow>

#define PLUGIN_VERSION "1.56"

#define SKULL_ICON "materials/sprites/skull_icon.vmt"

ConVar bawnAnnounce, bawnAnnounceMode, bawnLeftNotify, bawnLeftCounter, cvarGameMode,
	cvarMaxIncapCount;

int iAnnounce, iAnnounceMode, iMaxIncapCount, iBWEnt[MAXPLAYERS+1];
bool bLeftNotify, bLeftCounter, bIsL4D1, bCheckFix, bLateLoad;
char sGameMode[16], sMap[64];

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

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evRetVal = GetEngineVersion();
	if (evRetVal != Engine_Left4Dead && evRetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[BAWN] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	bIsL4D1 = (evRetVal == Engine_Left4Dead) ? true : false;
	
	bLateLoad = late;
	return APLRes_Success;
}

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
	
	if (!bIsL4D1)
	{
		HookEvent("defibrillator_used", OnDefibrillatorUsed);
	}
	
	HookEvent("round_start", OnRoundEvents);
	HookEvent("round_end", OnRoundEvents);
	HookEvent("mission_lost", OnRoundEvents);
	HookEvent("map_transition", OnRoundEvents);
	
	HookEvent("player_bot_replace", OnReplaceEvents);
	HookEvent("bot_player_replace", OnReplaceEvents);
	
	CreateTimer(0.1, BWOutlineCheck, _, TIMER_REPEAT);
	
	if (bLateLoad)
	{
		if (!bIsL4D1)
		{
			return;
		}
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
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
		
		if (bIsL4D1)
		{
			SDKUnhook(i, SDKHook_PostThinkPost, OnPostThinkPost);
		}
		
		if (GetEntProp(i, Prop_Send, "m_currentReviveCount") >= iMaxIncapCount)
		{
			NotifyBWState(i, false);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!bIsL4D1)
	{
		return;
	}
	
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnPostThinkPost(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}
	
	if (IsValidEntRef(iBWEnt[client]))
	{
		if (GetClientTeam(client) != 2 || !IsPlayerAlive(client) || GetEntProp(client, Prop_Send, "m_currentReviveCount") < iMaxIncapCount)
		{
			return;
		}
		
		int iGlowSequence, iGlowAnimTime;
		float fGlowPoseParam[5], fGlowCycle;
		
		iGlowSequence = GetEntProp(client, Prop_Send, "m_nSequence");
		iGlowAnimTime = GetEntProp(client, Prop_Send, "m_flAnimTime");
		
		for (int i = 0; i < 5; i++)
		{
			fGlowPoseParam[i] = GetEntPropFloat(client, Prop_Send, "m_flPoseParameter", i);
		}
		fGlowCycle = GetEntPropFloat(client, Prop_Send, "m_flCycle");
		
		SetEntProp(iBWEnt[client], Prop_Send, "m_nSequence", iGlowSequence);
		SetEntProp(iBWEnt[client], Prop_Send, "m_flAnimTime", iGlowAnimTime);
		
		for (int i = 0; i < 5; i++)
		{
			SetEntPropFloat(iBWEnt[client], Prop_Send, "m_flPoseParameter", fGlowPoseParam[i], i);
		}
		SetEntPropFloat(iBWEnt[client], Prop_Send, "m_flCycle", fGlowCycle);
	}
}

public void OnClientDisconnect(int client)
{
	if (bIsL4D1)
	{
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	}
	else
	{
		NotifyBWState(client, false);
	}
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (!bIsL4D1)
	{
		if (StrContains(sMap, "qe_", false) != -1 || StrContains(sMap, "l4d2_stadium", false) != -1 || StrEqual(sMap, "l4d2_vs_stadium2_riverwalk", false))
		{
			return;
		}
		
		if (!IsModelPrecached(SKULL_ICON))
		{
			PrecacheModel(SKULL_ICON, true);
		}
	}
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
							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Is About To Die!", revived);
                            }
						}
						else
						{

							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
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
								PrintCenterText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintCenterText(i, "%N Is About To Die!", revived);
							}
						}
					}
					case 2:
					{
						if (IsFakeClient(revived) || iNumMatch == -1)
						{

							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Is About To Die!", revived);
                            }
						}
						else
						{
							
							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
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
							
							if (!IsFakeClient(revived) && iNumMatch != -1)
							{
								PrintCenterText(i, "%N (%s) Is About To Die!", revived, sSurvivorNames[iNumMatch]);
							}
							else
							{
								PrintCenterText(i, "%N Is About To Die!", revived);
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


						    for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Killed %N!\n%d %s %s!", killer, died, GetProperSurvivorsCount(), (GetProperSurvivorsCount() != 1) ? "Survivors" : "Survivor", (GetProperSurvivorsCount() == 1) ? "Remains" : "Remain");
                            }

			}
			else
			{

							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Killed %N!", killer, died);
                            }
			}
		}
		else
		{
			if (!bLeftCounter)
			{
							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Died!", died);
                            }
			}
			else
			{

							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Died!\n%d %s %s!", died, GetProperSurvivorsCount(), (GetProperSurvivorsCount() == 1) ? "Survivor" : "Survivors", (GetProperSurvivorsCount() != 1) ? "Remain" : "Remains");
                            }

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
			
							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Defibbed %N!\n%d %s %s!", defibber, defibbed, GetProperSurvivorsCount(), (GetProperSurvivorsCount() != 1) ? "Survivors" : "Survivor", (GetProperSurvivorsCount() == 1) ? "Remains" : "Remain");
                            }
		}
		else
		{

							for(int i = 1; i <= MaxClients; i++) {
                            if(IsClientInGame(i) && (GetClientTeam(i) == 2)) 
                            PrintCenterText(i, "%N Defibbed %N!", defibber, defibbed);
                            }

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
		if (IsValidEnt(iBWEnt[client]))
		{
			return;
		}
		
		if (bIsL4D1)
		{
			float fPos[3], fAng[3];
			
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", fPos);
			GetEntPropVector(client, Prop_Send, "m_angRotation", fAng);
			
			char sModel[128];
			GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			int iGlowEnt = CreateEntityByName("prop_glowing_object");
			if (iGlowEnt == -1)
			{
				NotifyBWState(client, true);
			}
			else
			{
				DispatchKeyValue(iGlowEnt, "model", sModel);
				DispatchKeyValue(iGlowEnt, "GlowForTeam", "2");
				
				DispatchKeyValue(iGlowEnt, "fadescale", "1");
				DispatchKeyValue(iGlowEnt, "fademindist", "20000");
				DispatchKeyValue(iGlowEnt, "fadmaxdist", "22000");
				
				TeleportEntity(iGlowEnt, fPos, fAng, NULL_VECTOR);
				DispatchSpawn(iGlowEnt);
				ActivateEntity(iGlowEnt);
				
				SetEntityRenderFx(iGlowEnt, RENDERFX_FADE_FAST);
				
				SetVariantString("!activator");
				AcceptEntityInput(iGlowEnt, "SetParent", client, iGlowEnt);
				SetVariantString("!activator");
				AcceptEntityInput(iGlowEnt, "SetAttached", client);
				
				iBWEnt[client] = EntIndexToEntRef(iGlowEnt);
			}
		}
		else
		{
			if (StrContains(sMap, "qe_", false) == -1 && StrContains(sMap, "l4d2_stadium", false) == -1 && !StrEqual(sMap, "l4d2_vs_stadium2_riverwalk", false))
			{
				int iGraveEnt = CreateEntityByName("env_sprite");
				if (iGraveEnt != -1)
				{


		int R = GetRandomInt(1, 255); 
		int G = GetRandomInt(1, 255); 
		int B = GetRandomInt(1, 255); 


								DispatchKeyValue(iGraveEnt, "model", SKULL_ICON);
                                DispatchKeyValue(iGraveEnt, "spawnflags", "3");
                                //DispatchKeyValue(iGraveEnt, "rendercolor", "%i %i %i", R, G, B);
                                DispatchKeyValue(iGraveEnt, "rendermode", "9");
                                //DispatchKeyValue(iGraveEnt, "RenderAmt", "240");


                                SetEntityRenderColor(iGraveEnt, R, G, B, 200);


                                DispatchKeyValue(iGraveEnt, "scale", "0.001");
                                DispatchSpawn(iGraveEnt);
 

                                SetVariantString("!activator");
		                        AcceptEntityInput(iGraveEnt, "SetParent", client);
		
                         		SetVariantString("eyes");
		                        AcceptEntityInput(iGraveEnt, "SetParentAttachment");

                                TeleportEntity(iGraveEnt, view_as<float>({-3.0, 0.0, 6.0}), NULL_VECTOR, NULL_VECTOR);
					
					
					
                    
					//L4D2_SetEntGlow(iGraveEnt, L4D2Glow_Constant, 20000, 1, {255, 255, 255}, false);
					
					iBWEnt[client] = iGraveEnt;
					SDKHook(iBWEnt[client], SDKHook_SetTransmit, OnSetTransmit);
				}
				else
				{
					NotifyBWState(client, true);
				}
			}
			else
			{
				L4D2_SetEntGlow(client, L4D2Glow_Constant, 20000, 1, {255, 255, 255}, false);
			}
		}
	}
	else
	{
		if (!bIsL4D1)
		{
			if (StrContains(sMap, "qe_", false) != -1 || StrContains(sMap, "l4d2_stadium", false) != -1 || StrEqual(sMap, "l4d2_vs_stadium2_riverwalk", false))
			{
				L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			}
			else
			{
				if (!IsValidEnt(iBWEnt[client]))
				{
					return;
				}
				
				//L4D2_SetEntGlow(iBWEnt[client], L4D2Glow_None, 0, 0, {0, 0, 0}, false);
				
				SDKUnhook(iBWEnt[client], SDKHook_SetTransmit, OnSetTransmit);
				
				AcceptEntityInput(iBWEnt[client], "ClearParent");
				AcceptEntityInput(iBWEnt[client], "Kill");
				RemoveEdict(iBWEnt[client]);
			}
		}
		else
		{
			if (!IsValidEntRef(iBWEnt[client]))
			{
				return;
			}
			
			AcceptEntityInput(iBWEnt[client], "Detach");
			AcceptEntityInput(iBWEnt[client], "ClearParent");
			
			AcceptEntityInput(iBWEnt[client], "Kill");
			RemoveEdict(iBWEnt[client]);
		}
		
		iBWEnt[client] = 0;
	}
}

public Action OnSetTransmit(int entity, int client)
{
	if (entity != iBWEnt[client])
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(client) != 2)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
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

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

stock bool IsValidEntRef(int entity)
{
	return (entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE);
}

