#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"0.92"
#define CVAR_FLAGS			FCVAR_NOTIFY|FCVAR_SPONLY
#define HIGH_FF_TOLERANCE	1000000
#define AUTOPICKUP_AREA		350
#define AUTOPICKUP_INTERVAL	0.5

ConVar g_hFH_Enabled, g_hFH_VersusOnly, g_hFH_AutoPickupKit, g_hFH_AutoPickupPistol, g_hFriendlyFireTolerance_Convar;
bool g_bHooked = false, g_bGameHaveBegun = false, g_bVersusOnly = false, g_bAutoPickupPistol = false, g_bAutoPickupKit = false;

public Plugin myinfo = 
{
	name = "Friendly House",
	author = "Mr. Zero",
	description = "Disables friendly fire while survivors is still in safehouse, also includes other features such as auto pick up of medkits.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=101064"
}

public void OnPluginStart()
{
	CreateConVar("l4d_fh_version", PLUGIN_VERSION, "Friendly House Version", CVAR_FLAGS|FCVAR_NOTIFY);
	g_hFH_Enabled = CreateConVar("l4d_fh_enable",	"1", "Sets whether the plugin is active.", CVAR_FLAGS);
	g_hFH_VersusOnly = CreateConVar("l4d_fh_versusonly",	"1", "Sets whether its only in Versus the plugin is active. If 0 then it will also be active in Coop.", CVAR_FLAGS);
	g_hFH_AutoPickupKit = CreateConVar("l4d_fh_autopickupkit", "1", "Sets whether the plugin will make the survivors automaticly pick up medkits in safe house (only working in versus).", CVAR_FLAGS);
	g_hFH_AutoPickupPistol = CreateConVar("l4d_fh_autopickuppistol", "1", "Sets whether the plugin will make the survivors automaticly pick up a 2nd pistol in safe house, if available (only working in versus).", CVAR_FLAGS);
	g_hFriendlyFireTolerance_Convar = FindConVar("survivor_ff_tolerance");

	AutoExecConfig(true,"FriendlyHouse");

	g_hFH_Enabled.AddChangeHook(OnConVarEnabledChanged);
	g_hFH_VersusOnly.AddChangeHook(OnConVarsChanged);
	g_hFH_AutoPickupKit.AddChangeHook(OnConVarsChanged);
	g_hFH_AutoPickupPistol.AddChangeHook(OnConVarsChanged);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void OnConVarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bVersusOnly = g_hFH_VersusOnly.BoolValue;
	g_bAutoPickupKit = g_hFH_AutoPickupKit.BoolValue;
	g_bAutoPickupPistol = g_hFH_AutoPickupPistol.BoolValue;
}

void IsAllowed()
{
	bool bPluginOn = g_hFH_Enabled.BoolValue;
	OnConVarsChanged(null, "", "");
	if(!g_bHooked && bPluginOn && (IsGameMode("versus") || (IsGameMode("coop") && !g_bVersusOnly)))
	{
		g_bHooked = true;
		HookEvent("round_start", Events);
		HookEvent("door_open", Events);
		HookEvent("player_left_start_area", Events);
	}
	else if(g_bHooked && (!bPluginOn || !IsGameMode("versus") && !IsGameMode("coop")))
	{
		g_bHooked = false;
		UnhookEvent("round_start", Events);
		UnhookEvent("door_open", Events);
		UnhookEvent("player_left_start_area", Events);
	}
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	if (strcmp(name, "round_start") == 0)
	{
		g_bGameHaveBegun = false;
		g_hFriendlyFireTolerance_Convar.SetInt(HIGH_FF_TOLERANCE, true, false);
		if(IsGameMode("versus"))
		{
			if(g_bAutoPickupKit)
			{
				CreateTimer(AUTOPICKUP_INTERVAL, AutoPickupKitTimer, INVALID_HANDLE, TIMER_REPEAT);
			}

			if(g_bAutoPickupPistol)
			{
				CreateTimer(AUTOPICKUP_INTERVAL, AutoPickupPistolTimer, INVALID_HANDLE, TIMER_REPEAT);
			}
		}
	}
	else if(strcmp(name, "door_open") == 0)
	{
		if(g_bGameHaveBegun)
		{
			return Plugin_Continue;
		}

		bool wasCheckpointDoor = event.GetBool("checkpoint");
		if(wasCheckpointDoor)
		{
			g_bGameHaveBegun = true;
			ResetConVar(g_hFriendlyFireTolerance_Convar);
		}
	}
	else if(strcmp(name, "player_left_start_area") == 0)
	{
		g_bGameHaveBegun = true;
		ResetConVar(g_hFriendlyFireTolerance_Convar);
	}
	return Plugin_Continue;
}

Action AutoPickupPistolTimer(Handle timer)
{
	if(AutoPickupPistol())
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

Action AutoPickupKitTimer(Handle timer)
{
	if(AutoPickupKit())
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock bool AutoPickupPistol()
{
	int surClient = FindValidSurvivor();
	if(surClient == 0)
	{
		return false;
	}

	float surOrigin[3];
	GetClientAbsOrigin(surClient, surOrigin);

	int ent = 0, count = 0, maxcount = FindConVar("survivor_limit").IntValue;
	while ((ent = FindEntityByClassnameNearby("weapon_pistol_spawn", surOrigin, AUTOPICKUP_AREA)) != -1)
	{
		if(count == maxcount)
		{
			break;
		}

		RemoveEdict(ent);
		count ++;
	}

	if(count == 0)
	{
		return true;
	}

	GiveSurvivorItems("weapon_pistol", count);

	return true;
}

stock bool AutoPickupKit()
{
	int surClient = FindValidSurvivor();
	if(surClient == 0)
	{
		return false;
	}

	float surOrigin[3];
	GetClientAbsOrigin(surClient, surOrigin);

	int ent = 0, count = 0, maxcount = FindConVar("survivor_limit").IntValue;
	while ((ent = FindEntityByClassnameNearby("weapon_first_aid_kit_spawn", surOrigin, AUTOPICKUP_AREA)) != -1)
	{
		if(count == maxcount)
		{
			break;
		}

		RemoveEdict(ent);
		count ++;
	}

	if(count == 0)
	{
		return true;
	}

	GiveSurvivorItems("weapon_first_aid_kit", count);

	return true;
}

stock int FindEntityByClassnameNearby(char[] classname, const float origin[3], const int maxDistant)
{
	int curent = -1, prevent = 0;
	while ((curent = FindEntityByClassname(curent, classname)) != -1)
	{
		float entOrigin[3];
		GetEntPropVector(curent,Prop_Send,"m_vecOrigin",entOrigin);
		if(RoundToNearest(GetVectorDistance(entOrigin,origin)) > maxDistant)
		{
			continue;
		}

		if(prevent)
		{
			return prevent;
		}

		prevent = curent;
	}

	if(prevent)
	{
		return prevent;
	}

	return -1;
}

stock int FindValidSurvivor()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidSurvivor(client))
		{
			return client;
		}
	}
	return 0;
}

stock void GiveSurvivorItems(char[] item, int maxcount)
{
	int count = 0;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsValidSurvivor(client) && count < maxcount)
		{
			GivePlayerItem(client, item);
			count ++;
		}
	}
}

stock bool IsValidSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock bool IsGameMode(char GameModeName[16])
{
	char GameMode[sizeof(GameModeName)];
	FindConVar("mp_gamemode").GetString(GameMode, sizeof(GameMode));
	return StrContains(GameMode, GameModeName, false) != -1;
}
