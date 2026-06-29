#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Plugin fields used in multiple places
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "dcx2"
#define PLUGIN_NAME "L4D2 Dead Infected Ghosts"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY

// Debug flags to minimize chatter
#define DEBUG_FLAG_DEATH 0x01
#define DEBUG_FLAG_FADEIN 0x02
#define DEBUG_FLAG_FADEOUT 0x04

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_INGAME(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))

#define IS_VALID_SURVIVOR(%1) (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define FADE_IN_LIMIT 50
#define STEADY_LIMIT 100
#define FADE_OUT_LIMIT 240

// todo: somehow there's a second missing in the countdown?

new g_GhostColorCounter[MAXPLAYERS+1];

enum L4D2GlowType
{
    L4D2Glow_None = 0,
    L4D2Glow_OnUse,
    L4D2Glow_OnLookAt,
    L4D2Glow_Constant
}

new Handle:g_cvarEnable = INVALID_HANDLE;
new g_EnabledFlags;
new Handle:g_cvarDebug = INVALID_HANDLE;
new g_DebugFlags;
new Handle:g_cvarHunterColor = INVALID_HANDLE;
new Handle:g_cvarSmokerColor = INVALID_HANDLE;
new Handle:g_cvarBoomerColor = INVALID_HANDLE;
new Handle:g_cvarChargerColor = INVALID_HANDLE;
new Handle:g_cvarSpitterColor = INVALID_HANDLE;
new Handle:g_cvarJockeyColor = INVALID_HANDLE;
new Handle:g_cvarTankColor = INVALID_HANDLE;
new g_GhostColorValue[9][3];

// g_GhostColorValue has 9 indices, but indexes 0 and 7 will be unused
// This way we can easily convert infected class directly into array index

#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
#define ZC_WITCH 7
#define ZC_TANK 8

// game mode enable/disable/toggle taken from SilverShot's plugins
static	Handle:g_hCvarMPGameMode,
		Handle:g_hCvarModes,
		Handle:g_hCvarModesOff,
		Handle:g_hCvarModesTog,
		bool:g_bCvarAllow;



public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Shows a temporary ghost where a Special Infected died",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
};

public OnPluginStart()
{
	// Desired order
	// 1) Create cvars
	// 2) Hook cvar changes
	// 3) AutoExec loads user's specific defaults
	// 4) Cache the newly loaded cvars
	// 5) Hook events
	
	g_cvarEnable = 				CreateConVar("l4d2_deadghost_enable", 		"1", 			"Enables plugin", CVAR_FLAGS);
	g_cvarHunterColor = 		CreateConVar("l4d2_deadghost_huntercolor", 	"255,0,0", 		"Comma-separated RGB color for hunter's ghost", CVAR_FLAGS);
	g_cvarSmokerColor = 		CreateConVar("l4d2_deadghost_smokercolor", 	"0,0,255", 		"Comma-separated RGB color for smoker's ghost", CVAR_FLAGS);
	g_cvarBoomerColor = 		CreateConVar("l4d2_deadghost_boomercolor", 	"0,255,100", 	"Comma-separated RGB color for boomer's ghost", CVAR_FLAGS);
	g_cvarChargerColor = 		CreateConVar("l4d2_deadghost_chargercolor", "255,70,0", 	"Comma-separated RGB color for charger's ghost", CVAR_FLAGS);
	g_cvarSpitterColor = 		CreateConVar("l4d2_deadghost_spittercolor", "100,255,0", 	"Comma-separated RGB color for spitter's ghost", CVAR_FLAGS);
	g_cvarJockeyColor = 		CreateConVar("l4d2_deadghost_jockeycolor", 	"255,255,0", 	"Comma-separated RGB color for jockey's ghost", CVAR_FLAGS);
	g_cvarTankColor = 			CreateConVar("l4d2_deadghost_tankcolor", 	"255,170,0", 	"Comma-separated RGB color for tank's ghost", CVAR_FLAGS);
	g_cvarDebug = 				CreateConVar("l4d2_deadghost_debug", 		"0", 			"Print debug output (7=all)", CVAR_FLAGS);
	CreateConVar							("l4d2_deadghost_version", 		PLUGIN_VERSION, PLUGIN_NAME, CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	HookConVarChange(g_cvarEnable, 			OnDeadGhostEnableChanged);
	HookConVarChange(g_cvarHunterColor, 	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarSmokerColor, 	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarBoomerColor, 	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarChargerColor,	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarSpitterColor,	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarJockeyColor, 	OnDeadGhostColorChanged);
	HookConVarChange(g_cvarTankColor, 		OnDeadGhostColorChanged);
	HookConVarChange(g_cvarDebug,			OnDeadGhostDebugChanged);
	
	AutoExecConfig(true, "L4D2DeadGhost");
	
	g_EnabledFlags = GetConVarInt(g_cvarEnable);
	ParseCommaRGBStringCvar(g_cvarHunterColor, 	g_GhostColorValue[ZC_HUNTER]);
	ParseCommaRGBStringCvar(g_cvarSmokerColor, 	g_GhostColorValue[ZC_SMOKER]);
	ParseCommaRGBStringCvar(g_cvarBoomerColor, 	g_GhostColorValue[ZC_BOOMER]);
	ParseCommaRGBStringCvar(g_cvarChargerColor,	g_GhostColorValue[ZC_CHARGER]);
	ParseCommaRGBStringCvar(g_cvarSpitterColor,	g_GhostColorValue[ZC_SPITTER]);
	ParseCommaRGBStringCvar(g_cvarJockeyColor, 	g_GhostColorValue[ZC_JOCKEY]);
	ParseCommaRGBStringCvar(g_cvarTankColor, 	g_GhostColorValue[ZC_TANK]);
	g_DebugFlags = GetConVarInt(g_cvarDebug);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	
	// Mode enable/disable/toggle were taken from SilverShot's plugins
	g_hCvarModes =		CreateConVar(	"l4d2_deadghost_modes",		"",		"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_deadghost_modes_off",	"",		"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_deadghost_modes_tog",	"0",	"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarMPGameMode = FindConVar(		"mp_gamemode");
	
	HookConVarChange(g_hCvarMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,		ConVarChanged_Allow);
}

public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_cvarEnable);
	new bool:bAllowMode = IsAllowedGameMode();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == INVALID_HANDLE )
		return false;

	new iCvarModesTog = GetConVarInt(g_hCvarModesTog);
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		new entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hCvarMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public OnGamemode(const String:output[], caller, activator, Float:delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

public OnDeadGhostEnableChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_EnabledFlags = StringToInt(newVal);
}

public OnDeadGhostColorChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new class = 0;
	if (cvar == g_cvarHunterColor) 			class = ZC_HUNTER;
	else if (cvar == g_cvarSmokerColor) 	class = ZC_SMOKER;
	else if (cvar == g_cvarBoomerColor) 	class = ZC_BOOMER;
	else if (cvar == g_cvarChargerColor) 	class = ZC_CHARGER;
	else if (cvar == g_cvarSpitterColor) 	class = ZC_SPITTER;
	else if (cvar == g_cvarJockeyColor) 	class = ZC_JOCKEY;
	else if (cvar == g_cvarTankColor) 		class = ZC_TANK;

	ParseCommaRGBString(newVal, g_GhostColorValue[class]);
}

public OnDeadGhostDebugChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_DebugFlags = StringToInt(newVal);
}

public ParseCommaRGBString(const String:CommaRGB[], RGBArray[])
{
	decl String:ExplodeArray[3][7];
	ExplodeString(CommaRGB, ",", ExplodeArray, 3, 7);
	TrimString(ExplodeArray[0]);
	TrimString(ExplodeArray[1]);
	TrimString(ExplodeArray[2]);
	RGBArray[0] = StringToInt(ExplodeArray[0]);
	RGBArray[1] = StringToInt(ExplodeArray[1]);
	RGBArray[2] = StringToInt(ExplodeArray[2]);
}

public ParseCommaRGBStringCvar(const Handle:stringCvar, RGBArray[])
{
	decl String:cvarString[32];
	GetConVarString(stringCvar, cvarString, sizeof(cvarString));
	ParseCommaRGBString(cvarString, RGBArray);
}

// When a player dies, if they are infected, activate their ghost counter
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_EnabledFlags || !g_bCvarAllow) return Plugin_Continue;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IS_VALID_INFECTED(victim)) return Plugin_Continue;
	
	g_GhostColorCounter[victim] = 1;
	// Sometimes 0,0,0 shows a full glow, so we use 1,1,1 instead which is practically invisible
	L4D2_SetEntGlow(victim, L4D2Glow_Constant, 0, 0, { 1, 1, 1 } , false);
	
	if (g_DebugFlags & DEBUG_FLAG_DEATH) PrintToChatAll("Activating dead ghost for \x04%N\x01", victim);
	
	return Plugin_Continue;
}

// Increment the ghost counter every frame
// NOTE: it appears that for about 1 second, OnPlayerRunCmd is not run for dead infected
//       we may want to do this different, either OnGameFrame or with timers
public Action:OnPlayerRunCmd(client, &buttons)
{
	if (g_GhostColorCounter[client] == 0)
	{
		return Plugin_Continue;
	}
	
	if (!IS_VALID_INFECTED(client))
	{
		g_GhostColorCounter[client] = 0;
		return Plugin_Continue;
	}
	
	if (g_GhostColorCounter[client] > 0)
	{
		g_GhostColorCounter[client]++;
		
		// Run this every third frame, to reduce load
		if (!(g_GhostColorCounter[client] % 3))
		{
			new Float:ratio;
			if (g_GhostColorCounter[client] < FADE_IN_LIMIT)
			{
				ratio = float(g_GhostColorCounter[client]) / float(FADE_IN_LIMIT);
				if (g_DebugFlags & DEBUG_FLAG_FADEIN) PrintToChatAll("%f: ratio %f, counter %d", GetGameTime(), ratio, g_GhostColorCounter[client]);
			}
			else if (g_GhostColorCounter[client] < STEADY_LIMIT)
			{
				ratio = 1.0;
			}
			else if (g_GhostColorCounter[client] < FADE_OUT_LIMIT)
			{
				ratio = float(FADE_OUT_LIMIT - g_GhostColorCounter[client]) / float(FADE_OUT_LIMIT - STEADY_LIMIT);
				if (g_DebugFlags & DEBUG_FLAG_FADEOUT) PrintToChatAll("%f: ratio %f, counter %d", GetGameTime(), ratio, g_GhostColorCounter[client]);
			}
			
			new class = GetInfectedClass(client);
			new ghostColors[3];
			
			ghostColors[0] = RoundToCeil(g_GhostColorValue[class][0] * ratio);
			ghostColors[1] = RoundToCeil(g_GhostColorValue[class][1] * ratio);
			ghostColors[2] = RoundToCeil(g_GhostColorValue[class][2] * ratio);

			// Saturate, just in case, even though this should never happen
			// Note that apparently a glow of 0,0,0 seems to glitch, so we use 1,1,1 as minimum
			if (ghostColors[0] < 1) ghostColors[0] = 1;
			else if (ghostColors[0] > 255) ghostColors[0] = 255;
			if (ghostColors[1] < 1) ghostColors[1] = 1;
			else if (ghostColors[1] > 255) ghostColors[1] = 255;
			if (ghostColors[2] < 1) ghostColors[2] = 1;
			else if (ghostColors[2] > 255) ghostColors[2] = 255;

			L4D2_SetEntGlow_ColorOverride(client, ghostColors);
		}
		
		// If we have reached the fade out limit, shut the glow off
		if (g_GhostColorCounter[client] >= FADE_OUT_LIMIT)
		{
			g_GhostColorCounter[client] = 0;
			L4D2_SetEntGlow(client, L4D2Glow_None, 0, 0, { 1, 1, 1 }, false);
		}
	}
	
	return Plugin_Continue;
}

// ======================= STOCKS =======================

stock GetInfectedClass(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

// Mr. Zero's glow stocks
/**
 * Set entity glow type.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Type(entity, L4D2GlowType:type)
{
    SetEntProp(entity, Prop_Send, "m_iGlowType", _:type);
}

/**
 * Set entity glow range.
 *
 * @param entity        Entity index.
 * @parma range            Glow range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Range(entity, range)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity        Entity index.
 * @parma minRange        Glow min range.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_MinRange(entity, minRange)
{
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity        Entity index.
 * @parma colorOverride    Glow color, RGB.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_ColorOverride(entity, colorOverride[3])
{
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity        Entity index.
 * @parma flashing        Whether glow will be flashing.
 * @noreturn
 * @error                Invalid entity index or entity does not support glow.
 */
stock L4D2_SetEntGlow_Flashing(entity, bool:flashing)
{
    SetEntProp(entity, Prop_Send, "m_bFlashing", _:flashing);
}

/**
 * Set entity glow. This is consider safer and more robust over setting each glow
 * property on their own because glow offset will be check first.
 *
 * @param entity        Entity index.
 * @parma type            Glow type.
 * @param range            Glow max range, 0 for unlimited.
 * @param minRange        Glow min range.
 * @param colorOverride Glow color, RGB.
 * @param flashing        Whether the glow will be flashing.
 * @return                True if glow was set, false if entity does not support
 *                        glow.
 */
stock bool:L4D2_SetEntGlow(entity, L4D2GlowType:type, range, minRange, colorOverride[3], bool:flashing)
{
    decl String:netclass[128];
    GetEntityNetClass(entity, netclass, 128);

    new offset = FindSendPropInfo(netclass, "m_iGlowType");
    if (offset < 1)
    {
        return false;    
    }

    L4D2_SetEntGlow_Type(entity, type);
    L4D2_SetEntGlow_Range(entity, range);
    L4D2_SetEntGlow_MinRange(entity, minRange);
    L4D2_SetEntGlow_ColorOverride(entity, colorOverride);
    L4D2_SetEntGlow_Flashing(entity, flashing);
    return true;
}