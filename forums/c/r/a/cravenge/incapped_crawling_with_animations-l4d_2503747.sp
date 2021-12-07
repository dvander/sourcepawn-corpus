#define PLUGIN_VERSION "1.32"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY

#define ANIM_L4D_ZOEY 509
#define ANIM_L4D_LOUIS 546
#define ANIM_L4D_FRANCIS 547
#define ANIM_L4D_BILL 546

ConVar g_hCvarCrawl, g_hCvarSpeed, g_hMPGameMode, g_hCvarAllow, g_hCvarHint, g_hCvarHintS,
	g_hCvarHurt, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRate,
	g_hCvarSpeeds, g_hCvarView;

Handle g_hTmrHurt = null;
bool g_bCvarAllow, g_bView, g_bTranslation, g_bRoundOver;
int g_iHint, g_iHints, g_iHurt, g_iRate, g_iSpeed, g_iPlayerEnum[MAXPLAYERS],
	g_iClone[MAXPLAYERS], g_iDisplayed[MAXPLAYERS];

enum (<<=1)
{
	ENUM_INCAPPED = 1,
	ENUM_INSTART,
	ENUM_BLOCKED,
	ENUM_POUNCED,
	ENUM_ONLEDGE,
	ENUM_INREVIVE
}

public Plugin myinfo =
{
	name = "[L4D] Incapped Crawling with Animations",
	author = "SilverShot",
	description = "Allows Incapacitated Survivors To Crawl And Adds Animations.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137381"
};

public void OnPluginStart()
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead", false))
	{
		SetFailState("[ICWA] Plugin Supports L4D Only!");
	}
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/iwca.phrases.txt");
	if (!FileExists(sPath))
	{
		g_bTranslation = false;
	}
	else
	{
		LoadTranslations("iwca.phrases");
		g_bTranslation = true;
	}
	
	g_hCvarAllow = CreateConVar("iwca-l4d_on", "1", "Enable/Disable Plugin", CVAR_FLAGS);
	g_hCvarHint = CreateConVar("iwca-l4d_hint", "3", "Notifications Mode: 1=Chat Text, 2=Hint Box, 3=Instructor Hint", CVAR_FLAGS);
	g_hCvarHintS = CreateConVar("iwca-l4d_hint_num", "2", "Times The Notifications Appear", CVAR_FLAGS);
	g_hCvarHurt = CreateConVar("iwca-l4d_hurt", "0", "Damage Applied When Crawling", CVAR_FLAGS);
	g_hCvarModes = CreateConVar("iwca-l4d_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS);
	g_hCvarModesOff = CreateConVar("iwca-l4d_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS);
	g_hCvarModesTog = CreateConVar("iwca-l4d_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS);
	g_hCvarRate = CreateConVar("iwca-l4d_rate", "30", "Playback Rate Of Animation", CVAR_FLAGS);
	g_hCvarSpeeds = CreateConVar("iwca-l4d_speed", "30", "Speed Applied To Incapped Crawling", CVAR_FLAGS);
	g_hCvarView = CreateConVar("iwca-l4d_view", "1", "Incapped Crawling View Mode: 0=First Person, 1=Third Person", CVAR_FLAGS);
	CreateConVar("iwca-l4d_version", PLUGIN_VERSION, "Incapped Crawling With Animation Version", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "iwca-l4d");
	
	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode, ConVarChanged_Allow);
	
	HookConVarChange(g_hCvarAllow, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff, ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog, ConVarChanged_Allow);
	HookConVarChange(g_hCvarHint, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHintS, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHurt, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarView, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRate, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpeeds, ConVarChanged_Speed);
	
	g_hCvarCrawl = FindConVar("survivor_allow_crawling");
	g_hCvarSpeed = FindConVar("survivor_crawl_speed");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_iClone[i] = -1;
		}
	}
}

public void OnPluginEnd()
{
	g_hCvarCrawl.SetInt(0, true, false);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			RemoveClone(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	g_iDisplayed[client] = 0;
}

public void OnConfigsExecuted()
{
	IsAllowed();
	GetCvars();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Speed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSpeed = g_hCvarSpeeds.IntValue;
	g_hCvarSpeed.SetInt(g_iSpeed, true, false);
}

void GetCvars()
{
	g_bView = g_hCvarView.BoolValue;
	
	g_iHint = g_hCvarHint.IntValue;
	g_iHints = g_hCvarHintS.IntValue;
	g_iHurt = g_hCvarHurt.IntValue;
	g_iRate = g_hCvarRate.IntValue;
	g_iSpeed = g_hCvarSpeeds.IntValue;
}

void IsAllowed()
{
	GetCvars();
	
	bool bCvarAllow = g_hCvarAllow.BoolValue, bAllowMode = IsAllowedGameMode();
	if (!g_bCvarAllow && bCvarAllow && bAllowMode)
	{
		g_bCvarAllow = true;
		
		HookEvents();
		
		g_hCvarCrawl.SetInt(1, true, false);
		g_hCvarSpeed.SetInt(g_iSpeed, true, false);
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2 && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1))
			{
				g_iPlayerEnum[i] |= ENUM_INCAPPED;
			}
		}
	}
	else if (g_bCvarAllow && (!bCvarAllow || !bAllowMode))
	{
		g_bCvarAllow = false;
		
		UnhookEvents();
		
		g_hCvarCrawl.SetInt(0, true, false);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if(g_hMPGameMode == null)
	{
		return false;
	}

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog != 0)
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");
		
		if (g_iCurrentMode == 0)
		{
			return false;
		}
		
		if (!(iCvarModesTog & g_iCurrentMode))
		{
			return false;
		}
	}
	
	char sGameModes[64], sGameMode[64];
	g_hMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	
	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	
	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (strcmp(sGameModes, ""))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	
	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if (strcmp(output, "OnCoop") == 0)
	{
		g_iCurrentMode = 1;
	}
	else if (strcmp(output, "OnSurvival") == 0)
	{
		g_iCurrentMode = 2;
	}
	else if (strcmp(output, "OnVersus") == 0)
	{
		g_iCurrentMode = 4;
	}
}

void HookEvents()
{
	HookEvent("player_incapacitated", OnPlayerIncapacitated);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab", OnLedgeGrab);
	HookEvent("revive_begin", OnReviveStart);
	HookEvent("revive_end", OnReviveEnd);
	HookEvent("revive_success", OnReviveSuccess);
	HookEvent("player_death", OnUnblock);
	HookEvent("player_spawn", OnUnblock);
	HookEvent("lunge_pounce", OnBlockHunter);
	HookEvent("pounce_end", OnBlockEndHunt);
	HookEvent("tongue_grab", OnBlockStart);
	HookEvent("tongue_release", OnBlockEnd);
}

void UnhookEvents()
{
	UnhookEvent("player_incapacitated", OnPlayerIncapacitated);
	UnhookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
	UnhookEvent("player_ledge_grab", OnLedgeGrab);
	UnhookEvent("revive_begin", OnReviveStart);
	UnhookEvent("revive_end", OnReviveEnd);
	UnhookEvent("revive_success", OnReviveSuccess);
	UnhookEvent("player_death", OnUnblock);
	UnhookEvent("player_spawn", OnUnblock);
	UnhookEvent("lunge_pounce", OnBlockHunter);
	UnhookEvent("pounce_end", OnBlockEndHunt);
	UnhookEvent("tongue_grab", OnBlockStart);
	UnhookEvent("tongue_release", OnBlockEnd);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = false;
	CreateTimer(1.0, tmrRoundStart);
}

public Action tmrRoundStart(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			g_iClone[i] = -1;
			g_iPlayerEnum[i] = 0;
		}
	}
	
	g_bCvarAllow = g_hCvarAllow.BoolValue;
	if (g_bCvarAllow)
	{
		g_hCvarCrawl.SetInt(1, true, false);
		g_hCvarSpeed.SetInt(g_iSpeed, true, false);
	}
	
	return Plugin_Stop;
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = true;
	g_hCvarCrawl.SetInt(0, true, false);
}

public Action OnLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] |= ENUM_ONLEDGE;
	}
}

public Action OnReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] |= ENUM_INREVIVE;
	}
}

public Action OnReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
	}
}

public Action:OnReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] = 0;
	}
}

public Action OnUnblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] = 0;
	}
}

public Action OnBlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] |= ENUM_BLOCKED;
	}
}

public Action OnBlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
	}
}

public Action OnBlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] |= ENUM_POUNCED;
	}
}

public Action OnBlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		g_iPlayerEnum[client] &= ~ENUM_POUNCED;
	}
}

public Action OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) && !(g_iPlayerEnum[client] & ENUM_INSTART))
	{
		g_iPlayerEnum[client] |= ENUM_INCAPPED | ENUM_INSTART;
		CreateTimer(1.5, tmrResetStart, GetClientUserId(client));
	}
}

public Action tmrResetStart(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	g_iPlayerEnum[client] &= ~ENUM_INSTART;
	
	if (g_bRoundOver || !g_iHint || (g_iHint < 3 && g_iDisplayed[client] >= g_iHints) || !IsSurvivor(client))
	{
		return Plugin_Stop;
	}
	
	g_iDisplayed[client] += 1;
	char sBuffer[100];
	
	switch (g_iHint)
	{
		case 1:
		{
			if (g_bTranslation)
			{
				Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 %T", "Crawl", client);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 Press FORWARD To Crawl While Incapacitated!");
			}
			PrintToChat(client, sBuffer);
		}
		case 2:
		{
			if (g_bTranslation)
			{
				Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] %T", "Crawl", client);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] - Press FORWARD To Crawl While Incapacitated!");
			}
			PrintHintText(client, sBuffer);
		}
		case 3:
		{
			char sTemp[32];
			
			if (g_bTranslation)
			{
				Format(sBuffer, sizeof(sBuffer), "%T", "Crawl", client);
			}
			else
			{
				Format(sBuffer, sizeof(sBuffer), "Press FORWARD To Crawl While Incapacitated!");
			}
			ReplaceString(sBuffer, sizeof(sBuffer), "\n", " ");
			
			int entity = CreateEntityByName("env_instructor_hint");
			FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
			DispatchKeyValue(client, "targetname", sTemp);
			DispatchKeyValue(entity, "hint_target", sTemp);
			Format(sTemp, sizeof(sTemp), "%d", g_iHints);
			DispatchKeyValue(entity, "hint_timeout", sTemp);
			DispatchKeyValue(entity, "hint_range", "0.01");
			DispatchKeyValue(entity, "hint_icon_onscreen", "icon_key_up");
			DispatchKeyValue(entity, "hint_caption", sBuffer);
			DispatchKeyValue(entity, "hint_color", "255 255 255");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "ShowHint");
			
			Format(sTemp, sizeof(sTemp), "OnUser1 !self:Kill::%d:1", g_iHints);
			SetVariantString(sTemp);
			AcceptEntityInput(entity, "AddOutput");
			AcceptEntityInput(entity, "FireUser1");
		}
	}
	
	return Plugin_Stop;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!g_bCvarAllow)
	{
		return Plugin_Continue;
	}
	
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && (g_iPlayerEnum[client] & ENUM_INCAPPED) && (buttons & IN_FORWARD) && !g_bRoundOver)
	{
		if (g_iPlayerEnum[client] & ENUM_POUNCED)
		{
			buttons &= ~IN_FORWARD;
			return Plugin_Handled;
		}
		
		if (g_iPlayerEnum[client] != ENUM_INCAPPED)
		{
			RestoreClient(client);
			buttons &= ~IN_FORWARD;
			return Plugin_Continue;
		}
		
		if (g_iClone[client] == -1)
		{
			PlayAnim(client);
		}
	}
	else
	{
		RestoreClient(client);
	}

	return Plugin_Continue;
}

void PlayAnim(int client)
{
	int iAnim;
	
	char sModel[42];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (sModel[26] == 't')
	{
		iAnim = ANIM_L4D_ZOEY;
	}
	else if (sModel[26] == 'm' && sModel[27] == 'a')
	{
		iAnim = ANIM_L4D_LOUIS;
	}
	else if (sModel[26] == 'b')
	{
		iAnim = ANIM_L4D_FRANCIS;
	}
	else if (sModel[26] == 'n')
	{
		iAnim = ANIM_L4D_BILL;
	}
	else
	{
		return;
	}
	
	if (g_iHurt > 0)
	{
		HurtPlayer(client);
		if (g_hTmrHurt == null)
		{
			g_hTmrHurt = CreateTimer(1.0, tmrHurt, _, TIMER_REPEAT);
		}
	}
	
	if (iAnim == -1)
	{
		g_iClone[client] = 0;
		return;
	}
	
	int clone = CreateEntityByName("prop_dynamic");
	if (clone == -1)
	{
		return;
	}
	
	SetEntityModel(clone, sModel);
	g_iClone[client] = EntIndexToEntRef(clone);
	
	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", client);
	SetVariantString("bleedout");
	AcceptEntityInput(clone, "SetParentAttachment");
	
	float vPos[3], vAng[3];
	
	vPos[0] = -2.0;
	vPos[1] = -15.0;
	vPos[2] = -10.0;
	
	vAng[0] = -330.0;
	vAng[1] = -100.0;
	vAng[2] = 70.0;
	
	TeleportEntity(clone, vPos, vAng, NULL_VECTOR);
	
	SetEntProp(clone, Prop_Send, "m_nSequence", iAnim);
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", float(g_iRate) / 15);
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, 0);
	
	if (g_bView)
	{
		GotoThirdPerson(client);
	}
}

public Action tmrHurt(Handle timer)
{
	bool bIsCrawling;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (g_iClone[i] != -1)
			{
				bIsCrawling = true;
				HurtPlayer(i);
			}
		}
	}
	if (!bIsCrawling)
	{
		KillTimer(g_hTmrHurt);
		g_hTmrHurt = null;
	}
	
	return Plugin_Continue;
}

void HurtPlayer(int client)
{
	int iHealth = (GetClientHealth(client) - g_iHurt);
	if (iHealth > 0)
	{
		SetEntityHealth(client, iHealth);
	}
}

void GotoThirdPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

void GotoFirstPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2);
}

void RestoreClient(int client)
{
	if (g_iClone[client] == -1)
	{
		return;
	}
	else if (g_iClone[client] == 0)
	{
		g_iClone[client] = -1;
	}
	else
	{
		RemoveClone(client);
	}
}

void RemoveClone(int client)
{
	int clone = g_iClone[client];
	g_iClone[client] = -1;
	
	if (clone && EntRefToEntIndex(clone) != INVALID_ENT_REFERENCE)
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		AcceptEntityInput(clone, "kill");
	}
	
	if (g_bView)
	{
		GotoFirstPerson(client);
	}
}

