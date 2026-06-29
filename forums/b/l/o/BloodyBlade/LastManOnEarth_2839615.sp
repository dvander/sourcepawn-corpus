#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define LAST_MAN_ON_EARTH
#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

ConVar cvarEnable, cvarBuffHP, cvarPillsHeal, cvarAdrenHeal, hSurvivorMaxIncapacitatedCount, hBackgroundLimit, hCommonLimit, hGhostDelayMax, hGhostDelayMin;
bool bHooked = false, isIncapped[MAXPLAYERS + 1] = {false, ...}, isPillsHeal = false, isAdrenHeal = false;
int iBuffHP = 0, BufferHP = -1, Revived = 0;

public Plugin myinfo = 
{
	name = "[L4D2] Last Man On Earth",
	author = "Mortiegama(Edit. by BloodyBlade)",
	description = "Creates the Last Man On Earth Mutation.",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("sm_lastman_version", "1", "[L4D2] Last Man On Earth plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	cvarEnable = CreateConVar("sm_lastman_enable", "1", "Enable/Disable plugin (Def 1)", CVAR_FLAGS, true, 0.0, true, 1.0);
	cvarBuffHP = CreateConVar("sm_lastman_buffhp", "10", "Amount of bonus HP Survivor revives with (Def 10)", CVAR_FLAGS, true, 0.0, true, 100.0);
	cvarAdrenHeal = CreateConVar("sm_lastman_adrenheal", "1", "Amount of bonus HP Survivor revives with (Def 10)", CVAR_FLAGS, true, 0.0, true, 100.0);
	cvarPillsHeal = CreateConVar("sm_lastman_pillsheal", "1", "Amount of bonus HP Survivor revives with (Def 10)", CVAR_FLAGS, true, 0.0, true, 100.0);

	BufferHP = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	Revived = FindSendPropInfo("CTerrorPlayer","m_currentReviveCount");
	hSurvivorMaxIncapacitatedCount = FindConVar("survivor_max_incapacitated_count");
	hBackgroundLimit = FindConVar("z_background_limit");
	hCommonLimit = FindConVar("z_common_limit");
	hGhostDelayMax = FindConVar("z_ghost_delay_max");
	hGhostDelayMin = FindConVar("z_ghost_delay_min");

	AutoExecConfig(true, "sm_lastman");

	cvarEnable.AddChangeHook(OnConVarEnableChanged);
	cvarBuffHP.AddChangeHook(OnConVarsChanged);
	cvarAdrenHeal.AddChangeHook(OnConVarsChanged);
	cvarPillsHeal.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnableChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iBuffHP = cvarBuffHP.IntValue;
	isAdrenHeal = cvarAdrenHeal.BoolValue;
	isPillsHeal = cvarPillsHeal.BoolValue;
	hSurvivorMaxIncapacitatedCount.SetInt(1, false, false);
	hBackgroundLimit.SetInt(0, false, false);
	hCommonLimit.SetInt(0, false, false);
	hGhostDelayMax.SetInt(10, false, false);
	hGhostDelayMin.SetInt(15, false, false);
}

void IsAllowed()
{
	bool bPluginOn = cvarEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		OnConVarsChanged(null, "", "");
		HookEvent("player_left_start_area", Events);
		HookEvent("player_left_checkpoint", Events);
		HookEvent("player_incapacitated", Events);
		HookEvent("heal_success", Events);
		HookEvent("adrenaline_used", Events);
		HookEvent("pills_used", Events);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		UnhookEvent("player_left_start_area", Events);
		UnhookEvent("player_left_checkpoint", Events);
		UnhookEvent("player_incapacitated", Events);
		UnhookEvent("heal_success", Events);
		UnhookEvent("adrenaline_used", Events);
		UnhookEvent("pills_used", Events);
	}
}

public void OnClientPutInServer(int client)
{
	if(client > 0 && !IsFakeClient(client))
	{
		CreateTimer(1.0, Timer_LastMan);
	}
}

void Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "player_left_start_area") == 0 || strcmp(name, "player_left_checkpoint") == 0)
	{
		if (LeftStartArea())
		{
			int client = GetClientOfUserId(event.GetInt("userid"));
			if (IsValidClient(client))
			{
				isIncapped[client] = false;
			}
		}
	}
	else if(strcmp(name, "player_incapacitated") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (IsValidClient(client) && !isIncapped[client])
		{
			SetHealth(client, true);
		}
		else if (IsValidClient(client) && isIncapped[client])
		{
			ForcePlayerSuicide(client);
		}
	}
	else if (strcmp(name, "heal_success") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("subject"));
		if (IsValidClient(client) && !isIncapped[client])
		{
			SetHealth(client, false);
		}
	}
	else if(strcmp(name, "adrenaline_used") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (isAdrenHeal && IsValidClient(client))
		{
			SetHealth(client, false);
		}
	}
	else if (strcmp(name, "pills_used") == 0)
	{
		int client = GetClientOfUserId(event.GetInt("subject"));
		if (isPillsHeal && IsValidClient(client))
		{
			SetHealth(client, false);
		}
	}
}

Action Timer_LastMan(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsFakeClient(client))
		{
			KickClient(client,"Kick");
		}
	}
	return Plugin_Stop;
}

void SetHealth(int client, bool bFromIncap)
{
	if(bFromIncap)
	{
		isIncapped[client] = true;
		SetEntData(client, Revived, 1, 1);
		int flags3 = GetCommandFlags("give");
		SetCommandFlags("give", flags3 & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give health");
		SetCommandFlags("give", flags3);
		SetEntityHealth(client, 1);
		float sBuff = GetEntDataFloat(client, BufferHP);
		SetEntDataFloat(client, BufferHP, sBuff + iBuffHP, true);
	}
	else
	{
		isIncapped[client] = false;
		SetEntProp(client, Prop_Send, "m_iHealth", 80, 1);
		SetEntDataFloat(client, BufferHP, 0.0, true);
	}
}

stock bool LeftStartArea()
{
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients + 1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char cNetClass[64];
			GetEntityNetClass(i, cNetClass, sizeof(cNetClass));

			if (StrEqual(cNetClass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}

	if (ent > -1)
	{
		int offset = FindSendPropInfo("CTerrorPlayerResource", "m_hasAnySurvivorLeftSafeArea");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

stock bool IsValidClient(int client)
{
	return client > 0 && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2;
}
