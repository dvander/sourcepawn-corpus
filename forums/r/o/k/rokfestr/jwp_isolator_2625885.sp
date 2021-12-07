#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <jwp>
#include <emitsoundany>

#pragma newdecls required

#define PLUGIN_VERSION "1.2"
#define ITEM "isolator"

int g_iIsolatorIndex[MAXPLAYERS+1], g_iIsolatorBeamIndex[MAXPLAYERS+1];

ConVar	g_CvarIsolatorWall, g_CvarIsolatorWall_Dist,
		g_CvarIsolatorRoof, g_CvarIsolatorRoof_Dist,
		g_CvarIsolator_Sound;

char g_cIsolatorWall[PLATFORM_MAX_PATH], g_cIsolatorRoof[PLATFORM_MAX_PATH], g_cIsolatorSound[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "[JWP] Isolator",
	description = "Warden can push terrorists to isolator",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://hlmod.ru"
};

public void OnPluginStart()
{
	g_CvarIsolatorWall = CreateConVar("jwp_isolator_wall", "models/props/de_train/chainlinkgate.mdl", "Модель стен карцера", _);
	g_CvarIsolatorWall_Dist = CreateConVar("jwp_isolator_wall_dist", "80", "Расстояние от центра карцера до его боковых стен", _, true, 15.0, true, 200.0);
	g_CvarIsolatorRoof = CreateConVar("jwp_isolator_roof", "", "Модель крыши карцера", _);
	g_CvarIsolatorRoof_Dist = CreateConVar("jwp_isolator_roof_dist", "125", "Расстояние от пола карцера до его крыши", _, true, 50.0, true, 500.0);
	g_CvarIsolator_Sound = CreateConVar("jwp_isolator_sound", "ambient/machines/power_transformer_loop_1.wav", "Звук в карцере. Оставьте пустым, чтобы отключить.", _);
	
	g_CvarIsolatorWall.AddChangeHook(OnCvarChange);
	g_CvarIsolatorWall_Dist.AddChangeHook(OnCvarChange);
	g_CvarIsolatorRoof.AddChangeHook(OnCvarChange);
	g_CvarIsolatorRoof_Dist.AddChangeHook(OnCvarChange);
	g_CvarIsolator_Sound.AddChangeHook(OnCvarChange);
	
	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("player_team", Event_OnPlayerTeam);
	
	if (JWP_IsStarted()) JWP_Started();
	AutoExecConfig(true, ITEM, "jwp");
	
	LoadTranslations("jwp_modules.phrases");
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	g_CvarIsolatorWall.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 'm')
		PrecacheModel(buffer, true);
	g_CvarIsolatorRoof.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 'm')
		PrecacheModel(buffer, true);
	g_CvarIsolator_Sound.GetString(buffer, sizeof(buffer));
	if (buffer[0] == 's')
		PrecacheSoundAny(buffer);
}

public void JWP_Started()
{
	JWP_AddToMainMenu(ITEM, OnFuncDisplay, OnFuncSelect);
}

public void OnPluginEnd()
{
	JWP_RemoveFromMainMenu();
}

public void OnConfigsExecuted()
{
	g_CvarIsolatorWall.GetString(g_cIsolatorWall, sizeof(g_cIsolatorWall));
	g_CvarIsolatorRoof.GetString(g_cIsolatorRoof, sizeof(g_cIsolatorRoof));
	g_CvarIsolator_Sound.GetString(g_cIsolatorSound, sizeof(g_cIsolatorSound));
}

public void OnCvarChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (cvar == g_CvarIsolatorWall)
		strcopy(g_cIsolatorWall, sizeof(g_cIsolatorWall), newValue);
	else if (cvar == g_CvarIsolatorRoof)
		strcopy(g_cIsolatorRoof, sizeof(g_cIsolatorRoof), newValue);
	else if (cvar == g_CvarIsolator_Sound)
		strcopy(g_cIsolatorSound, sizeof(g_cIsolatorSound), newValue);
}

public void JWP_OnWardenResigned(int client, bool himself)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && JWP_IsPrisonerIsolated(i))
		{
			TryKillIsolator(i);
			JWP_PrisonerIsolated(i, false);
		}
	}
}

public void Event_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TryKillIsolator(client);
}

public void Event_OnPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TryKillIsolator(client);
}

public void OnClientDisconnect_Post(int client)
{
	TryKillIsolator(client);
}

public bool OnFuncDisplay(int client, char[] buffer, int maxlength, int style)
{
	FormatEx(buffer, maxlength, "%T", "Isolator_Menu", LANG_SERVER); // [#] in isolator
	return true;
}

public bool OnFuncSelect(int client)
{
	if (JWP_IsWarden(client))
	{
		char langbuffer[40];
		Menu IsolatorMenu = new Menu(IsolatorMenu_Callback);
		
		Format(langbuffer, sizeof(langbuffer), "%T:\n%T", "Isolator_Menu", LANG_SERVER, "Isolator_Menu_Info", LANG_SERVER);
		
		IsolatorMenu.SetTitle(langbuffer);
		char id[4], name[MAX_NAME_LENGTH];
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (CheckClient(i))
			{
				IntToString(i, id, sizeof(id));
				if (JWP_IsPrisonerIsolated(i))
					Format(name, sizeof(name), "[#]%N", i);
				else
					Format(name, sizeof(name), "%N", i);
				IsolatorMenu.AddItem(id, name);
			}
		}
		if (!IsolatorMenu.ItemCount)
		{
			Format(langbuffer, sizeof(langbuffer), "%T", "Isolator_NoMore_Prisoners", LANG_SERVER);
			IsolatorMenu.AddItem("", langbuffer, ITEMDRAW_DISABLED);
		}
		IsolatorMenu.ExitBackButton = true;
		IsolatorMenu.Display(client, MENU_TIME_FOREVER);
		return true;
	}
	return false;
}

public int IsolatorMenu_Callback(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_End: menu.Close();
		case MenuAction_Cancel:
		{
			if (slot == MenuCancel_ExitBack && JWP_IsWarden(client))
				JWP_ShowMainMenu(client);
		}
		case MenuAction_Select:
		{
			if (JWP_IsWarden(client))
			{
				char info[4];
				menu.GetItem(slot, info, sizeof(info));
				
				int target = StringToInt(info);
				if (target && IsClientInGame(target) && GetClientTeam(target) == CS_TEAM_T)
				{
					if (JWP_IsPrisonerIsolated(target))
					{
						TryKillIsolator(target);
						JWP_ActionMsgAll("%T", "Isolator_Action_Released", LANG_SERVER, client, target);
						JWP_PrisonerIsolated(target, false);
					}
					else if (TryPushPrisonerInIsolator(client, target))
					{
						JWP_ActionMsgAll("%T", "Isolator_Action_Isolated", LANG_SERVER, client, target);
						JWP_PrisonerIsolated(target, true);
					}
					else
						JWP_ActionMsg(client, "%T", "Isolator_FailedToIsolate", LANG_SERVER, target);
				}
				else
					JWP_ActionMsg(client, "%T", "Isolator_FailedToIsolate_Leave", LANG_SERVER);
				OnFuncSelect(client);
			}
		}
	}
}

bool CheckClient(int client)
{
	return (IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client) && (GetClientTeam(client) == CS_TEAM_T) && IsPlayerAlive(client));
}

bool IsValidIsolator(int& ent, char[] name)
{
	if (ent <= MaxClients || !IsValidEntity(ent))
	{
		ent = 0;
		return false;
	}
	
	char cName[16];
	cName[0] = '\0';
	GetEntPropString(ent, Prop_Data, "m_iName", cName, sizeof(cName));
	if (StrContains(cName, name, true))
	{
		ent = 0;
		return false;
	}
	return true;
}


bool TryPushPrisonerInIsolator(int client, int prisoner)
{
	if (IsValidIsolator(g_iIsolatorIndex[prisoner], "isltr_")) return false;
	float center[3];
	int ent = TiB_GetAimInfo(client, center);
	if (ent > 0 && ent <= MaxClients)
	{
		PrintCenterText(client, "%T", "Isolator_NearPlayer", LANG_SERVER);
		return false;
	}
	float angles[3];
	TR_GetPlaneNormal(null, angles);
	GetVectorAngles(angles, angles);
	angles[0] = 0.0;
	
	float pOrigin[3];
	float wall_dist = g_CvarIsolatorWall_Dist.FloatValue + 150;
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (i != prisoner && IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i, pOrigin);
			if (GetVectorDistance(pOrigin, center, false) <= wall_dist)
			{
				PrintCenterText(client, "%T", "Isolator_CantCreate", LANG_SERVER);
				return false;
			}
		}
	}
	wall_dist -= 150.0;
	float direction[3];
	
	int prisoner_id = GetClientUserId(prisoner);
	char IsoLatorName[28];
	
	/* First wall & test if we can teleport player not in wall */
	angles[1] = 0.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist, true);
	if (!ent)
	{
		PrintHintText(client, "%T", "Isolator_FindAnotherLocation", LANG_SERVER);
		return false;
	}
	
	Format(IsoLatorName, sizeof(IsoLatorName), "isltr_%d", prisoner_id);
	DispatchKeyValue(ent, "targetname", IsoLatorName);
	
	SetVariantString(IsoLatorName);
	AcceptEntityInput(ent, "SetParent");
	g_iIsolatorIndex[prisoner] = ent;
	
	/* Second wall */
	angles[1] = 90.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* Third wall */
	angles[1] = 180.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* Fourth wall */
	angles[1] = 270.0;
	ent = EditWallPositionAndCreateWall(center, angles, direction, wall_dist);
	if (ent)
	{
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	
	/* Roof configuration */
	angles[2] += g_CvarIsolatorRoof_Dist.FloatValue;
	if ((ent = CreateProp(g_cIsolatorRoof)) > 0)
	{
		TeleportEntity(ent, center, NULL_VECTOR, NULL_VECTOR);
		SetEntityMoveType(ent, MOVETYPE_NONE);
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	
	/* Create Beam */
	/* Nothing else */
	/* End of creating beam */
	
	/* Create Sound */
	
	if (g_cIsolatorSound[0] && (ent = CreateEntityByName("ambient_generic")) > 0)
	{
		DispatchKeyValueVector(ent, "origin", center);
		DispatchKeyValue(ent, "message", g_cIsolatorSound);
		DispatchKeyValue(ent, "health", "10");
		DispatchKeyValue(ent, "radius", "2000");
		DispatchKeyValue(ent, "preset", "0");
		DispatchKeyValue(ent, "volstart", "10");
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "PlaySound");
		SetVariantString("!activator");
		AcceptEntityInput(ent, "SetParent", g_iIsolatorIndex[prisoner]);
	}
	/* End of creating sound */
	
	/* Teleport prisoner if isolator succesfully builded */
	center[2] += 20.0;
	TeleportEntity(prisoner, center, NULL_VECTOR, NULL_VECTOR);
	
	return true;
}

stock int EditWallPositionAndCreateWall(float wall_pos[3], float angles[3], float newpos[3], float dist, bool firstwall = false)
{
	int ent = CreateProp(g_cIsolatorWall);
	if (IsValidEntity(ent))
	{
		if (firstwall)
		{
			wall_pos[2] += 20.0;
			TeleportEntity(ent, wall_pos, angles, NULL_VECTOR);
			if (IsEntStucked(ent)) return 0;
			wall_pos[2] -= 20.0;
		}
		float direction[3];
		GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);
		newpos = wall_pos;
		newpos[0] += direction[0] * dist;
		newpos[1] += direction[1] * dist;
		newpos[2] += 6.0;
		TeleportEntity(ent, newpos, angles, NULL_VECTOR);
		SetEntityMoveType(ent, MOVETYPE_NONE);
	}
	
	return ent;
}

bool IsEntStucked(int ent)
{
	float vecMins[3], vecMaxs[3], vecOrigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMins);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMaxs);
	
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_SOLID, TREntityStuckFilter, ent);
	if (TR_GetEntityIndex() > MaxClients) return false;
	AcceptEntityInput(ent, "Kill");
	return true;
}

int CreateProp(char[] model)
{
	if (model[0] != 'm') return -1;
	int ent = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(ent))
	{
		DispatchKeyValue(ent, "model", model);
		DispatchKeyValue(ent, "Solid", "6");
		DispatchSpawn(ent);
	}
	return ent;
}

int TiB_GetAimInfo(int client, float end_origin[3])
{
	float angles[3];
	if (!GetClientEyeAngles(client, angles)) return -1;
	float origin[3];
	GetClientEyePosition(client, origin);
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, client);
	
	if (!TR_DidHit())
		return -1;
	
	TR_GetEndPosition(end_origin);
	
	return TR_GetEntityIndex();
}

public bool TraceFilter_Callback(int ent, int mask, any entity)
{
	return entity != ent;
}

bool TryKillIsolator(int client)
{
	bool kill;
	if (IsValidIsolator(g_iIsolatorIndex[client], "isltr_"))
	{
		AcceptEntityInput(g_iIsolatorIndex[client], "KillHierarchy");
		kill = true;
	}
	if (IsValidIsolator(g_iIsolatorBeamIndex[client], "bm_"))
	{
		AcceptEntityInput(g_iIsolatorBeamIndex[client], "Kill");
		kill = true;
	}
	g_iIsolatorIndex[client] = 0;
	g_iIsolatorBeamIndex[client] = 0;
	JWP_PrisonerIsolated(client, false);
	return kill;
}

public bool TREntityStuckFilter(int ent, int mask)
{
	return (ent > MaxClients);
}