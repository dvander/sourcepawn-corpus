#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2"

#define CVAR_FLAGS FCVAR_NOTIFY
#define MAX_ALLOWED 64

#define PROP_CAR (1<<0)
#define PROP_CAR_ALARM (1<<1)
#define PROP_CONTAINER (1<<2)
#define PROP_LIFT (1<<3)

enum carProps
{
	collisionGroup,
	solidType
};

ConVar g_hCvarObjects, g_hCvarLimit, g_hCvarAllow, g_hCvarColor, g_hCvarRange, g_hMPGameMode;
Handle g_hTimerStart;
int g_iCvarColor, g_iCvarLimit, g_iCvarRange, g_iCount, g_iEntities[MAX_ALLOWED], entProp[2048+1][2];
bool g_bLoaded;

public Plugin myinfo =
{
	name = "[L4D2] Super Charge - Objects Glow",
	author = "SilverShot",
	description = "Creates Glows For Objects That Can Be Charged.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=186556"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	char sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if (strcmp(sGameName, "left4dead2", false))
	{
		strcopy(error, err_max, "[SC-OG] Plugin Supports L4D2 Only!");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar("super_charge_glow-l4d2_allow", "1", "Enable/Disable Plugin", CVAR_FLAGS);
	g_hCvarColor = CreateConVar("super_charge_glow-l4d2_color", "255 0 0", "Color Given To Chargeable Objects", CVAR_FLAGS);
	g_hCvarRange = CreateConVar("super_charge_glow-l4d2_range", "750", "Range Of Glow", CVAR_FLAGS);
	CreateConVar("super_charge_glow-l4d2_version", PLUGIN_VERSION, "Super Charge - Objects Glow Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true, "super_charge_glow-l4d2");
	
	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode, ConVarChanged_Allow);
	
	HookConVarChange(g_hCvarAllow, ConVarChanged_Allow);
	HookConVarChange(g_hCvarRange, ConVarChanged_Cvars);
	HookConVarChange(g_hCvarColor, ConVarChanged_Glow);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public OnAllPluginsLoaded()
{
	g_hCvarObjects = FindConVar("super_charge-l4d2_objects");
	if (g_hCvarObjects == INVALID_HANDLE)
	{
		SetFailState("[SCG] Plugin Requires Super Charge!");
	}
	
	g_hCvarLimit = FindConVar("super_charge-l4d2_push_limit");
	if (g_hCvarLimit != INVALID_HANDLE)
	{
		HookConVarChange(g_hCvarLimit, ConVarChanged_Cvars);
	}
}

void ResetPlugin()
{
	g_bLoaded = false;
	
	ToggleGlow(false);
	for (int i = 0; i < MAX_ALLOWED; i++)
	{
		entProp[g_iEntities[i]][collisionGroup] = -1;
		entProp[g_iEntities[i]][solidType] = -1;
		g_iEntities[i] = 0;
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
	GetCvars();
}

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarColor = GetColor(g_hCvarColor);
	if (g_hCvarLimit != INVALID_HANDLE)
	{
		g_iCvarLimit = g_hCvarLimit.IntValue;
	}
	g_iCvarRange = g_hCvarRange.IntValue;
}

public void ConVarChanged_Glow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarColor = GetColor(g_hCvarColor);
	for (int i = 0; i < MAX_ALLOWED; i++)
	{
		if (IsValidEntity(g_iEntities[i]) && IsValidEdict(g_iEntities[i]))
		{
			SetEntProp(g_iEntities[i], Prop_Send, "m_iGlowType", 3);
			SetEntProp(g_iEntities[i], Prop_Send, "m_glowColorOverride", g_iCvarColor);
			SetEntProp(g_iEntities[i], Prop_Send, "m_nGlowRange", g_iCvarRange);
		}
	}
}

int GetColor(ConVar cvar)
{
	char sTemp[12];
	cvar.GetString(sTemp, sizeof(sTemp));
	if (strcmp(sTemp, "") == 0)
	{
		return 0;
	}
	
	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, 3, 4);
	if (color != 3)
	{
		return 0;
	}
	
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	
	return color;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue, bAllowMode = IsAllowedGameMode();
	GetCvars();
	
	bool g_bCvarAllow;
	
	if (!g_bCvarAllow && bCvarAllow && bAllowMode)
	{
		g_bCvarAllow = true;
		g_hTimerStart = CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
		
		HookEvent("player_team", OnPlayerDeath);
		HookEvent("player_death", OnPlayerDeath);
		HookEvent("tank_frustrated", OnPlayerDeath);
		HookEvent("tank_spawn", OnPlayerDeath);
		HookEvent("player_spawn", OnPlayerSpawn);
		HookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	}
	else if (g_bCvarAllow && (!bCvarAllow || !bAllowMode))
	{
		g_bCvarAllow = false;
		
		ResetPlugin();
		
		g_iCount = 0;
		if (g_hTimerStart != INVALID_HANDLE)
		{
			KillTimer(g_hTimerStart);
			g_hTimerStart = INVALID_HANDLE;
		}
		
		UnhookEvent("player_team", OnPlayerDeath);
		UnhookEvent("player_death", OnPlayerDeath);
		UnhookEvent("tank_frustrated", OnPlayerDeath);
		UnhookEvent("tank_spawn", OnPlayerDeath);
		UnhookEvent("player_spawn", OnPlayerSpawn);
		UnhookEvent("round_end", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if (g_hMPGameMode == INVALID_HANDLE)
	{
		return false;
	}
	
	g_iCurrentMode = 0;
	
	int infoGM = CreateEntityByName("info_gamemode");
	DispatchSpawn(infoGM);
	HookSingleEntityOutput(infoGM, "OnVersus", OnGamemode, true);
	HookSingleEntityOutput(infoGM, "OnScavenge", OnGamemode, true);
	AcceptEntityInput(infoGM, "PostSpawnActivate");
	AcceptEntityInput(infoGM, "Kill");
	
	if (g_iCurrentMode == 0)
	{
		return false;
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
	else if (strcmp(output, "OnScavenge") == 0)
	{
		g_iCurrentMode = 8;
	}
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int died = GetClientOfUserId(event.GetInt("userid"));
	if (IsCharger(died))
	{
		ToggleGlow(false);
	}
}

void ToggleGlow(bool enabled)
{
	if (enabled)
	{
		for (int i = 0; i < MAX_ALLOWED; i++)
		{
			if (IsValidEntity(g_iEntities[i]) && IsValidEdict(g_iEntities[i]))
			{
				if (entProp[g_iEntities[i]][collisionGroup] != -1)
				{
					SetEntProp(g_iEntities[i], Prop_Send, "m_CollisionGroup", 0);
				}
				if (entProp[g_iEntities[i]][solidType] != -1)
				{
					SetEntProp(g_iEntities[i], Prop_Send, "m_nSolidType", 0);
				}
				SetEntProp(g_iEntities[i], Prop_Send, "m_iGlowType", 3);
				SetEntProp(g_iEntities[i], Prop_Send, "m_glowColorOverride", g_iCvarColor);
				SetEntProp(g_iEntities[i], Prop_Send, "m_nGlowRange", g_iCvarRange);
			}
		}
	}
	else
	{
		for (int i = 0; i < MAX_ALLOWED; i++)
		{
			if (IsValidEntity(g_iEntities[i]) && IsValidEdict(g_iEntities[i]))
			{
				if (entProp[g_iEntities[i]][collisionGroup] != -1)
				{
					SetEntProp(g_iEntities[i], Prop_Send, "m_CollisionGroup", entProp[g_iEntities[i]][collisionGroup]);
				}
				if (entProp[g_iEntities[i]][solidType] != -1)
				{
					SetEntProp(g_iEntities[i], Prop_Send, "m_nSolidType", entProp[g_iEntities[i]][collisionGroup]);
				}
				SetEntProp(g_iEntities[i], Prop_Send, "m_iGlowType", 0);
				SetEntProp(g_iEntities[i], Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(g_iEntities[i], Prop_Send, "m_nGlowRange", 0);
			}
		}
	}
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int spawned = GetClientOfUserId(event.GetInt("userid"));
	if (IsCharger(spawned))
	{
		ToggleGlow(true);
	}
	else
	{
		ToggleGlow(false);
	}
}

public void OnMapEnd()
{
	ResetPlugin();
	
	g_iCount = 0;
	if (g_hTimerStart != INVALID_HANDLE)
	{
		KillTimer(g_hTimerStart);
		g_hTimerStart = INVALID_HANDLE;
	}
}

public Action OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
	
	g_iCount = 0;
	if (g_hTimerStart != INVALID_HANDLE)
	{
		KillTimer(g_hTimerStart);
		g_hTimerStart = INVALID_HANDLE;
	}
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hTimerStart == INVALID_HANDLE)
	{
		g_hTimerStart = CreateTimer(4.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action tmrStart(Handle timer)
{
	g_hTimerStart = INVALID_HANDLE;
	
	if (g_bLoaded)
	{
		return Plugin_Stop;
	}
	
	g_bLoaded = true;
	g_iCount = 0;
	
	int ents = GetEntityCount();
	int iType = g_hCvarObjects.IntValue;
	
	for (int entity = MaxClients+1; entity < ents; entity++)
	{
		if (g_iCount >= MAX_ALLOWED)
		{
			break;
		}
		
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			if (GetEntityMoveType(entity) == MOVETYPE_VPHYSICS)
			{
				entProp[entity][solidType] = GetEntProp(entity, Prop_Send, "m_nSolidType");
				
				char sClassName[64], sModelName[64];
				GetEdictClassname(entity, sClassName, sizeof(sClassName));
				if ((iType & PROP_CAR_ALARM) && strcmp(sClassName, "prop_car_alarm") == 0)
				{
					g_iEntities[g_iCount++] = entity;
					entProp[g_iEntities[g_iCount++]][collisionGroup] = GetEntProp(g_iEntities[g_iCount++], Prop_Send, "m_CollisionGroup");
				}
				else if (strcmp(sClassName, "prop_physics") == 0)
				{
					GetEntPropString(entity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
					
					if ((iType & PROP_CAR) && (strcmp(sModelName, "models/props_vehicles/cara_69sedan.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/cara_82hatchback.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/cara_82hatchback_wrecked.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/cara_84sedan.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/cara_95sedan.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/cara_95sedan_wrecked.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/police_car_city.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/police_car_rural.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/taxi_cab.mdl") == 0 ))
					{
						g_iEntities[g_iCount++] = entity;
					}
					else if ((iType & PROP_CONTAINER) && (strcmp(sModelName, "models/props_junk/dumpster_2.mdl") == 0 || strcmp(sModelName, "models/props_junk/dumpster.mdl") == 0 ))
					{
						g_iEntities[g_iCount++] = entity;
					}
					else if ((iType & PROP_LIFT) && strcmp(sModelName, "models/props/cs_assault/forklift.mdl") == 0)
					{
						g_iEntities[g_iCount++] = entity;
					}
					else if (strcmp(sModelName, "models/props_fairgrounds/bumpercar.mdl") == 0 || strcmp(sModelName, "models/props_foliage/Swamp_FallenTree01_bare.mdl") == 0 || strcmp(sModelName, "models/props_foliage/tree_trunk_fallen.mdl") == 0 || strcmp(sModelName, "models/props_vehicles/airport_baggage_cart2.mdl") == 0 || strcmp(sModelName, "models/props_unique/airport/atlas_break_ball.mdl") == 0 || strcmp(sModelName, "models/props_unique/haybails_single.mdl") == 0)
					{
						g_iEntities[g_iCount++] = entity;
					}
				}
			}
		}
	}
	
	for (int i = 0; i < g_iCount; i++)
	{
		if (g_iCvarLimit != 0)
		{
			HookSingleEntityOutput(g_iEntities[i], "OnHealthChanged", OnHealthChanged);
		}
	}
	
	return Plugin_Stop;
}

public void OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if (IsValidEnt(caller) && GetEntProp(caller, Prop_Data, "m_iHealth") >= g_iCvarLimit)
	{
		UnhookSingleEntityOutput(caller, "OnHealthChanged", OnHealthChanged);
		AcceptEntityInput(caller, "Kill");
	}
}

stock bool IsCharger(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6 && !IsFakeClient(client));
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

