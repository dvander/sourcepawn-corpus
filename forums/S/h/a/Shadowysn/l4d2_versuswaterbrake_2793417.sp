#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1.1b"
#define DEFAULT_FLAGS FCVAR_NONE|FCVAR_NOTIFY

#define FRAMESKIP 						3	// Our OnGameFrame function will only trigger every third Frame
#define FULL_SPEED						1.0
#define JUMP_PENALTY						0.25	// gets added to the velocitymodifier on jumping
#define INDEX_REBUILD_DELAY				0.3

#define MOVE_SPEED_ENTPROP		"m_flLaggedMovementValue"
 
bool isSlowedDown[MAXPLAYERS+1];
bool isJockeyed[MAXPLAYERS+1];
bool isAllowedMode;

bool g_bEnabled 							= true;
float g_fWaterSlow 						= 0.75;
bool g_bJockeySlow						= false;
bool g_bLowHealthSlow						= false;
float g_fLimpHealth						= 40.0;
float g_fPillsDecay						= 0.27;
int everyXFrame							= 0;

ConVar g_hCvar_Enabled,
g_hCvar_WaterSlow,
g_hCvar_JockeySlow,
g_hCvar_LowHealthSlow,
g_hCvar_LimpHealth,
g_hCvar_PillsDecay,
g_hCvar_GameMode,
g_hCvar_GameModeActive;

int survivorCount;
int survivorIndex[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{ return APLRes_Success; }
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

#define FOR_EACH_ALIVE_SURVIVOR_INDEXED(%1)									\
	for(int %1 = 0, indexnumber = 1; indexnumber <= survivorCount; indexnumber++)	\
		if(((%1 = survivorIndex[indexnumber])) || true)			

public Plugin myinfo = 
{
	name = "L4D2 Versus Waterbrake",
	author = "AtomicStryker",
	description = " Allows slowing down Survivors in Water for Versus ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1045232"
}

public void OnPluginStart()
{
	CreateConVar("l4d2_vswaterbrake_version", PLUGIN_VERSION, " Version of L4D2 Versus Water Brake on this Server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	g_hCvar_Enabled = CreateConVar("l4d2_vswaterbrake_enabled", "1", " Turn Water Brake on or off ", DEFAULT_FLAGS);
	g_hCvar_Enabled.AddChangeHook(CC_VWB_EnabledOrModeChange);
	
	g_hCvar_WaterSlow = CreateConVar("l4d2_vswaterbrake_slow", "0.75", " How much slower will a Survivor be in water - 0.75 equals 75% speed ", DEFAULT_FLAGS);
	g_hCvar_WaterSlow.AddChangeHook(CC_VWB_WaterSlow);
	
	g_hCvar_JockeySlow = CreateConVar("l4d2_vswaterbrake_jockeyslow", "0", " Will a Jockeyed Survivor also be slowed down? ", DEFAULT_FLAGS);
	g_hCvar_JockeySlow.AddChangeHook(CC_VWB_JockeySlow);
	
	g_hCvar_LowHealthSlow = CreateConVar("l4d2_vswaterbrake_at_low_health", "0", " Enable or Disable Water Brake for low Health Survivors ", DEFAULT_FLAGS);
	g_hCvar_LowHealthSlow.AddChangeHook(CC_VWB_LowHealthSlow);
	
	g_hCvar_GameModeActive = CreateConVar("l4d2_vswaterbrake_gamemodeactive", "versus,teamversus,scavenge,teamscavenge,mutation12,mutation13", " Set the game mode for which the plugin should be activated (same usage as sv_gametypes, i.e. add all game modes where you want it active separated by comma) ");
	g_hCvar_GameModeActive.AddChangeHook(CC_VWB_EnabledOrModeChange);
	g_hCvar_GameMode = FindConVar("mp_gamemode");
	g_hCvar_GameMode.AddChangeHook(CC_VWB_EnabledOrModeChange);
	
	g_hCvar_LimpHealth = FindConVar("survivor_limp_health");
	g_hCvar_LimpHealth.AddChangeHook(CC_VWB_LimpHealth);
	g_hCvar_PillsDecay = FindConVar("pain_pills_decay_rate");
	g_hCvar_PillsDecay.AddChangeHook(CC_VWB_PillsDecay);
	
	AutoExecConfig(true, "l4d2_versuswaterbrake");
	SetCvarValues();
	
	/*HookConVarChange(g_hCvar_Enabled, WB_ConvarsChanged);
	HookConVarChange(g_hCvar_WaterSlow, WB_ConvarsChanged);
	HookConVarChange(g_hCvar_LimpHealth, WB_ConvarsChanged);
	HookConVarChange(g_hCvar_PillsDecay, WB_ConvarsChanged);
	HookConVarChange(g_hCvar_LowHealthSlow, WB_ConvarsChanged);
	HookConVarChange(g_hCvar_GameMode, WB_ConvarsChanged);
	
	WB_OnPluginEnabled();*/
}

/*void WB_ConvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = g_hCvar_Enabled.BoolValue;
	g_fWaterSlow = g_hCvar_WaterSlow.FloatValue;
	g_fLimpHealth = g_hCvar_LimpHealth.FloatValue;
	g_fPillsDecay = g_hCvar_PillsDecay.FloatValue;
	g_bLowHealthSlow = g_hCvar_LowHealthSlow.BoolValue;
	CheckAllowedGameMode();
	
	if (g_bEnabled)
		WB_OnPluginEnabled();
	else
		WB_OnPluginDisabled();
}*/

void CC_VWB_EnabledOrModeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_Enabled) g_bEnabled = convar.BoolValue;
	
	CheckAllowedGameMode();
	if (g_bEnabled)
		WB_OnPluginEnabled();
	else
		WB_OnPluginDisabled();
}
void CC_VWB_WaterSlow(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fWaterSlow =			convar.FloatValue;	}
void CC_VWB_JockeySlow(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_bJockeySlow =		convar.BoolValue;		}
void CC_VWB_LowHealthSlow(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bLowHealthSlow =	convar.BoolValue;		}
void CC_VWB_LimpHealth(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fLimpHealth =	convar.FloatValue;	}
void CC_VWB_PillsDecay(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fPillsDecay =	convar.FloatValue;	}
void SetCvarValues()
{
	CC_VWB_EnabledOrModeChange(g_hCvar_Enabled, "", "");
	CC_VWB_WaterSlow(g_hCvar_WaterSlow, "", "");
	CC_VWB_JockeySlow(g_hCvar_JockeySlow, "", "");
	CC_VWB_LowHealthSlow(g_hCvar_LowHealthSlow, "", "");
	CC_VWB_LimpHealth(g_hCvar_LimpHealth, "", "");
	CC_VWB_PillsDecay(g_hCvar_PillsDecay, "", "");
}

void WB_OnPluginEnabled()
{
	HookEvent("round_start", WB_RoundStart_Event);
	HookEvent("round_end", WB_RoundEnd_Event);
	HookEvent("jockey_ride", WB_PlayerJockeyed_Event);
	HookEvent("jockey_ride_end", WB_JockeyRideEnd_Event);
	
	HookEvent("round_start", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", SI_TempStop_Event, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_death", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("defibrillator_used", RebuildIndex_Event, EventHookMode_PostNoCopy);
	HookEvent("player_team", SI_DelayedIndexRebuild_Event, EventHookMode_PostNoCopy);
}

void WB_OnPluginDisabled()
{
	UnhookEvent("round_start", WB_RoundStart_Event);
	UnhookEvent("round_end", WB_RoundEnd_Event);
	UnhookEvent("jockey_ride", WB_PlayerJockeyed_Event);
	UnhookEvent("jockey_ride_end", WB_JockeyRideEnd_Event);
	
	UnhookEvent("round_start", SI_TempStop_Event, EventHookMode_PostNoCopy);
	UnhookEvent("round_end", SI_TempStop_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_disconnect", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_bot_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("bot_player_replace", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("defibrillator_used", RebuildIndex_Event, EventHookMode_PostNoCopy);
	UnhookEvent("player_team", SI_DelayedIndexRebuild_Event, EventHookMode_PostNoCopy);
	
	FOR_EACH_ALIVE_SURVIVOR_INDEXED(i)
	{
		if (isSlowedDown[i])
		{
			isSlowedDown[i] = false;
			SetEntPropFloat(i, Prop_Send, MOVE_SPEED_ENTPROP, FULL_SPEED);
		}
	}
}

void CheckAllowedGameMode()
{
	char gamemode[64], gamemodeactive[64];
	g_hCvar_GameMode.GetString(gamemode, sizeof(gamemode));
	g_hCvar_GameModeActive.GetString(gamemodeactive, sizeof(gamemodeactive));
	isAllowedMode = (StrContains(gamemodeactive, gamemode) != -1);
}

void WB_RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	CheckAllowedGameMode();
	
	for (int i = 1; i <= MaxClients; i++)
		isJockeyed[i] = false;
}

void WB_RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	isAllowedMode = false;
}

void WB_PlayerJockeyed_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bJockeySlow) return; // if its disabled, it wont ever set the isJockeyed bool true

	int victimId = GetClientOfUserId(event.GetInt("victim", 0));
	if (victimId == 0 || victimId > MAXPLAYERS) return;
	
	isJockeyed[victimId] = true;
	
	if (isSlowedDown[victimId]) // if a slow was in effect already
	{
		isSlowedDown[victimId] = false;
		SetEntPropFloat(victimId, Prop_Send, MOVE_SPEED_ENTPROP, FULL_SPEED); // reset plugin saved status and ingame speed
	}
}

void WB_JockeyRideEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	int victimId = GetClientOfUserId(event.GetInt("victim", 0));
	if (victimId == 0 || victimId > MAXPLAYERS) return;
	
	isJockeyed[victimId] = false;
}

public void OnGameFrame()
{
	if (!IsServerProcessing()) return;
	if (!isAllowedMode || !g_bEnabled) return;
	if (!survivorCount) return;
	
	everyXFrame++;
	if (everyXFrame >= FRAMESKIP)
	{
		everyXFrame = 1;
		
		FOR_EACH_ALIVE_SURVIVOR_INDEXED(i)
		{
			if (!IsValidEntity(i)) continue;
			
			int flags = GetEntityFlags(i);
			if (flags & FL_INWATER) // case Survivor in water
			{
				if (!isSlowedDown[i] && !isJockeyed[i]) // and not jockeyed and not yet slowed
				{
					if (!g_bLowHealthSlow && 
					(GetClientHealth(i) + GetTempHealth(i)) < g_fLimpHealth) return; // if Survivor Health is low and Low Health Brake not enabled return
					
					isSlowedDown[i] = true;
					SetEntPropFloat(i, Prop_Send, MOVE_SPEED_ENTPROP, g_fWaterSlow); // tell the plugin the Survivor is now slow and apply it
				}
				else if (isSlowedDown[i] && isJockeyed[i]) // is slowed but got jockeyed (now)
				{
					isSlowedDown[i] = false;
					SetEntPropFloat(i, Prop_Send, MOVE_SPEED_ENTPROP, FULL_SPEED); // remove slowdown
				}
			}
			else if (isSlowedDown[i]) // case Survivor not in water but slowed
			{
				isSlowedDown[i] = false;
				SetEntPropFloat(i, Prop_Send, MOVE_SPEED_ENTPROP, FULL_SPEED); // remove slowdown
				
				if (flags & IN_JUMP) // if the survivor is jumping aswell
				{
					SetEntPropFloat(i, Prop_Send, "m_flVelocityModifier", g_fWaterSlow - JUMP_PENALTY); // apply velocity modifier with penalty so bunny hopping wont make you faster
																									// note: does not take effect until you touch ground again. pretty realistic actually.
					
					// also note: i could make Water Brake work with the velocity modifier entirely, but it causes microstuttering. laggedMovement is smooth
					// fun fact: whenever youre hit by a zombie you actually get microstuttering, valve covers it up by shaking your view
				}
			}
		}
	}
}

public void OnMapStart()
{
	survivorCount = 0;
}

public void OnMapEnd()
{
	survivorCount = 0;
}

public void OnClientDisconnect()
{
	SurvivorIndex_Rebuild();
}

void SI_DelayedIndexRebuild_Event(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(INDEX_REBUILD_DELAY, SI_RebuildIndex_Timer);
}

Action SI_RebuildIndex_Timer(Handle timer)
{
	SurvivorIndex_Rebuild();
	return Plugin_Continue;
}

void SI_TempStop_Event(Event event, const char[] name, bool dontBroadcast)
{
	survivorCount = 0;	// to get rid of GetEntProp Entity errors before and after Mapchange
	CreateTimer(INDEX_REBUILD_DELAY, SI_RebuildIndex_Timer);
}

void RebuildIndex_Event(Event event, const char[] name, bool dontBroadcast)
{
	SurvivorIndex_Rebuild();
}

void SurvivorIndex_Rebuild()
{
	if (!IsServerProcessing()) return;

	survivorCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i)!=2) continue;
		if (!IsPlayerAlive(i)) continue;
		
		survivorCount++;
		survivorIndex[survivorCount] = i;
	}
}

// woops, thanks Silvers
stock float GetTempHealth(int client)
{
    float fGameTime = GetGameTime();
    float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
    float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
    fHealth -= (fGameTime - fHealthTime) * g_fPillsDecay;
    return fHealth < 0.0 ? 0.0 : fHealth;
}