#define PLUGIN_VERSION 		"1.42"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Incapped Crawling with Animation
*	Author	:	SilverShot
*	Descrp	:	Allows incapped survivors to crawl and sets crawling animation.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=137381
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.42 (08-Aug-2018)
	- Fixed the tank death animation being frozen in place, due to "survivor_allow_crawling" bug - Thanks to "Uncle Jessie" for the initial find.

1.41 (24-Jul-2018)
	- Fixed error with LMC - Thanks to MasterMind420.

1.40 (21-Jul-2018)
	- Added Hungarian translations - Thanks to KasperH.
	- No other changes.

1.40 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Removed instructor hints due to Valve: FCVAR_SERVER_CAN_EXECUTE prevented server running command: gameinstructor_enable.

1.33 (06-Jun-2017)
	- Update by "Lux":
	- Added LMC support for overlay models.
	- Thanks "mastermind420" for helping test.

1.32 (10-May-2012)
	- Reloading or turning on the plugin now allows incapped players to crawl, instead of requiring the player_incapacitated event to fire first.

1.31 (30-Mar-2012)
	- Added Russian translations - Thanks to disawar1.
	- Added cvar "l4d2_crawling_modes" to control which game modes the plugin works in.
	- Added cvar "l4d2_crawling_modes_off" same as above.
	- Added cvar "l4d2_crawling_modes_tog" same as above.

1.30 (19-Feb-2012)
	- Added French translations (thanks to John2022).
	- Added Spanish translations (thanks to Januto).
	- Removes clones when the plugin is unloaded.
	- Removed logging errors when invalid model.

1.29 (18-Oct-2011)
	- Re-added team check to stop error log filling up.

1.28 (14-Oct-2011)
	- Fixed animation number due to Valve update.
	- Added reset on round_start and removed previous update.

1.27 (14-Oct-2011)
	- Added team check to stop error log filling up.

1.26 (22-May-2011)
	- Added cvar "l4d2_crawling_hint_num". How many times to display hints or instructor hint timeout.
	- Fixed duplicate hint messages being displayed (2 events fire for player_incapacitated ?!)
	- Fixed players gun disappearing when being revived and trying to crawl.
	- Fixed Coach not receiving damage when crawling.
	- Optimized some code.

1.25 (17-May-2011)
	- Fixed bugs created by previous update.

1.24 (15-May-2011)
	- Fixed cvars not changing the crawl speed.

1.23 (16-Apr-2011)
	- Changed the Hint Box notification to only appear once per round.
	- Fixed crawling not working for all players?

1.22 (02-Jan-2011)
	- Changed thirdperson view because of Valve patching some client commands.
	- Positioned the model better and removed the timer creating the model.

1.21 (26-Nov-2010)
	- Fixed Instructor Hint not using translation.

1.20 (25-Nov-2010)
	- Fixed invalid convar handles.

1.19 (19-Nov-2010)
	- Added Instructor Hints (thanks to McFlurry).

1.18 (18-Nov-2010)
	- Added hints, "l4d2_crawling_hint" and translation file.

1.17 (18-Nov-2010)
	- Cleaned up some code.
	- Enables "survivor_allow_crawling" on plugin start.
	- Fixed not setting "survivor_crawl_speed" on round start.
	- Increased delay on player_incapacitated before allowing crawling from 1.0s to 1.5s.

1.16 (04-Nov-2010)
	- Sets "survivor_allow_crawling" to 0 when plugin unloaded.

1.15 (04-Nov-2010)
	- Added cvar "l4d_crawling_speed" to change "survivor_crawl_speed" cvar (default 15).
	- Added cvar "l4d_crawling_rate" to set the animation playback speed (default 15).

1.14 (12-Oct-2010)
	- Fixed "GetClientHealth" reported: Client is not in game.

1.13 (10-Oct-2010)
	- Removed.

1.12 (07-Oct-2010)
	- Removed.

1.11 (06-Oct-2010)
	- Fixed animation numbers due to The Sacrifice update.

1.10 (05-Oct-2010)
	- Added Bill's animation number for L4D2.

1.09 (01-Oct-2010)
	- Added 1 second delay on player_incapacitated before allowing crawling.

1.08 (22-Sep-2010)
	- Added charger carry event.
	- Fixed version cvar.

1.07 (15-Sep-2010)
	- Animation playback rate now set according to survivor_crawl_speed.
	- Added player_spawn hook to unblock animation, just incase.

1.06 (14-Sep-2010)
	- Added UnhookEvents.
	- Optimized some code.
	- Added version cvar.

1.05 (13-Sep-2010)
	- Added cvar to enable/disable crawling in spitter acid.
	- Added cvar to damage players every second of crawling.
	- Hooked ledge hang to stop animation playing.
	- Hooked charger and smoker grab to stop animation playing.

1.04 (11-Sep-2010)
	- Added McFlurry's code to stop crawling whilst pounced.
	- Fixed crawling breaking on round restart.

1.03 (10-Sep-2010)
	- Added cvar to enable thirdperson view on crawling.
	- Stopped crawling on round end.

1.02 (10-Sep-2010)
	- Fixed silly mistake.

1.01 (10-Sep-2010)
	- Positioned the clone better.
	- Added a cvar to enable/disable glow on crawling.
	- Delayed the animation by 0.1 to correct angles.

1.0 (05-Sep-2010)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "javalia" for the first and thirdperson view stocks
	http://forums.alliedmods.net/showthread.php?t=122946

*	Thanks to this thread for invisibility
	http://forums.alliedmods.net/showthread.php?t=87626

*	Thanks to "McFlurry" for "[L4D & L4D2] Survivor Crawl Pounce Fix"
	http://forums.alliedmods.net/showthread.php?t=137969

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define ANIM_L4D2_NICK		631
#define ANIM_L4D2_ELLIS		636
#define ANIM_L4D2_ROCH		639
#define ANIM_L4D2_ZOEY		529
#define ANIM_L4D2_LOUIS		539
#define ANIM_L4D2_FRANCIS	542
#define ANIM_L4D2_BILL		539

//LMC
// #include <L4D2ModelChanger>
native int LMC_GetClientOverlayModel(int iClient);// remove this and enable the include above to compile with the include this is just here for AM compiler
//LMC

Handle g_hTmrHurt;
ConVar g_hCvarAllow, g_hCvarCrawl, g_hCvarGlow, g_hCvarHint, g_hCvarHintS, g_hCvarHurt, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRate, g_hCvarSpeed, g_hCvarSpeeds, g_hCvarSpit, g_hCvarView;
int g_iClone[MAXPLAYERS], g_iDisplayed[MAXPLAYERS], g_iHint, g_iHints, g_iHurt, g_iPlayerEnum[MAXPLAYERS], g_iRate, g_iSpeed;
bool g_bCvarAllow, g_bGlow, g_bRoundOver, g_bSpit, g_bTranslation, g_bView;

enum ()
{
	ENUM_INCAPPED	= (1 << 0),
	ENUM_INSTART	= (1 << 1),
	ENUM_BLOCKED	= (1 << 2),
	ENUM_POUNCED	= (1 << 3),
	ENUM_ONLEDGE	= (1 << 4),
	ENUM_INREVIVE	= (1 << 5),
	ENUM_INSPIT		= (1 << 6)
}

//LMC
bool bLMC_Available = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("L4D2ModelChanger");
}

public void OnLibraryAdded(const char[] sName)
{
	if(StrEqual(sName, "L4D2ModelChanger"))
	bLMC_Available = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if(StrEqual(sName, "L4D2ModelChanger"))
	bLMC_Available = false;
}
//LMC



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Incapped Crawling with Animation",
	author = "SilverShot, mod by Lux",
	description = "Allows incapped survivors to crawl and sets crawling animation.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137381"
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "%s", "translations/incappedcrawling.phrases.txt");

	if( !FileExists(sPath) )
		g_bTranslation = false;
	else
	{
		LoadTranslations("incappedcrawling.phrases");
		g_bTranslation = true;
	}

	g_hCvarAllow =		CreateConVar(	"l4d2_crawling",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGlow =		CreateConVar(	"l4d2_crawling_glow",		"0",			"0=Disables survivor glow on crawling, 1=Enables glow if not realism.", CVAR_FLAGS);
	g_hCvarHint =		CreateConVar(	"l4d2_crawling_hint",		"2",			"0=Dislables, 1=Chat text, 2=Hint box.", CVAR_FLAGS);
	g_hCvarHintS =		CreateConVar(	"l4d2_crawling_hint_num",	"2",			"How many times to display hints.", CVAR_FLAGS);
	g_hCvarHurt =		CreateConVar(	"l4d2_crawling_hurt",		"2",			"Damage to apply every second of crawling, 0=No damage when crawling.", CVAR_FLAGS);
	g_hCvarModes =		CreateConVar(	"l4d2_crawling_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_crawling_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_crawling_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRate =		CreateConVar(	"l4d2_crawling_rate",		"15",			"Sets the playback speed of the crawling animation.", CVAR_FLAGS);
	g_hCvarSpeeds =		CreateConVar(	"l4d2_crawling_speed",		"15",			"Changes 'survivor_crawl_speed' cvar.", CVAR_FLAGS);
	g_hCvarSpit =		CreateConVar(	"l4d2_crawling_spit",		"1",			"0=Disables crawling in spitter acid, 1=Enables crawling in spit.", CVAR_FLAGS);
	g_hCvarView =		CreateConVar(	"l4d2_crawling_view",		"1",			"0=Firstperson view when crawling, 1=Thirdperson view when crawling.", CVAR_FLAGS);
	CreateConVar(						"l4d2_crawling_version",	PLUGIN_VERSION, "Incapped Crawling plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_incapped_crawling");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarGlow.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHintS.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHurt.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarView.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpeeds.AddChangeHook(ConVarChanged_Speed);

	g_hCvarCrawl = FindConVar("survivor_allow_crawling");
	g_hCvarSpeed = FindConVar("survivor_crawl_speed");

	for( int i = 0; i < MAXPLAYERS; i++ )
		g_iClone[i] = -1;
}

public void OnPluginEnd()
{
	g_hCvarCrawl.IntValue = 0;

	for( int i = 1; i <= MaxClients; i++ )
	if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		RemoveClone(i);
}

public void OnClientPutInServer(int client)
{
	g_iDisplayed[client] = 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Speed(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iSpeed = g_hCvarSpeeds.IntValue;
	g_hCvarSpeed.IntValue = g_iSpeed;
}

void GetCvars()
{
	g_bGlow = g_hCvarGlow.BoolValue;
	g_iHint = g_hCvarHint.IntValue;
	g_iHints = g_hCvarHintS.IntValue;
	g_iHurt = g_hCvarHurt.IntValue;
	g_iRate = g_hCvarRate.IntValue;
	g_iSpeed = g_hCvarSpeeds.IntValue;
	g_bSpit = g_hCvarSpit.BoolValue;
	g_bView = g_hCvarView.BoolValue;

	if( g_iHint > 2 ) g_iHint = 1; // Can no longer support instructor hints
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();
		g_hCvarCrawl.IntValue = 1;
		g_hCvarSpeed.IntValue = g_iSpeed;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && GetEntProp(i, Prop_Send, "m_isIncapacitated", 1) == 1 )
			{
				g_iPlayerEnum[i] |= ENUM_INCAPPED;
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();
		g_hCvarCrawl.IntValue = 0;
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
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



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("player_incapacitated",	Event_Incapped);		// Delay crawling by 1 second
	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("player_ledge_grab",		Event_LedgeGrab);		// Stop crawling anim whilst ledge handing
	HookEvent("revive_begin",			Event_ReviveStart);		// Revive start/stop
	HookEvent("revive_end",				Event_ReviveEnd);
	HookEvent("revive_success",			Event_ReviveSuccess);	// Revived
	HookEvent("player_death",			Event_Unblock);			// Player died,			unblock all
	HookEvent("player_spawn",			Event_Unblock);			// Player spawned,		unblock all
	HookEvent("player_hurt",			Event_PlayerHurt);		// Apply damage in spit
	HookEvent("charger_pummel_start",	Event_BlockStart);		// Charger
	HookEvent("charger_carry_start",	Event_BlockStart);
	HookEvent("charger_carry_end",		Event_BlockEnd);
	HookEvent("charger_pummel_end",		Event_BlockEnd);
	HookEvent("lunge_pounce",			Event_BlockHunter);		// Hunter
	HookEvent("pounce_end",				Event_BlockEndHunt);
	HookEvent("tongue_grab",			Event_BlockStart);		// Smoker
	HookEvent("tongue_release",			Event_BlockEnd);
}

void UnhookEvents()
{
	UnhookEvent("player_incapacitated",		Event_Incapped);
	UnhookEvent("round_start",				Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("round_end",				Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("player_ledge_grab",		Event_LedgeGrab);
	UnhookEvent("revive_begin",				Event_ReviveStart);
	UnhookEvent("revive_end",				Event_ReviveEnd);
	UnhookEvent("revive_success",			Event_ReviveSuccess);
	UnhookEvent("player_death",				Event_Unblock);
	UnhookEvent("player_spawn",				Event_Unblock);
	UnhookEvent("player_hurt",				Event_PlayerHurt);
	UnhookEvent("charger_pummel_start",		Event_BlockStart);
	UnhookEvent("charger_carry_start",		Event_BlockStart);
	UnhookEvent("charger_carry_end",		Event_BlockEnd);
	UnhookEvent("charger_pummel_end",		Event_BlockEnd);
	UnhookEvent("lunge_pounce",				Event_BlockHunter);
	UnhookEvent("pounce_end",				Event_BlockEndHunt);
	UnhookEvent("tongue_grab",				Event_BlockStart);
	UnhookEvent("tongue_release",			Event_BlockEnd);
}

// ====================================================================================================
//					EVENT - ROUND START / END
// ====================================================================================================
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = false;
	CreateTimer(1.0, tmrRoundStart);
}

public Action tmrRoundStart(Handle timer)
{
	g_bCvarAllow = g_hCvarAllow.BoolValue;

	if( g_bCvarAllow )
	{
		g_hCvarCrawl.IntValue = 1;
		g_hCvarSpeed.IntValue = g_iSpeed;
	}

	for( int i = 0; i < MAXPLAYERS; i++ )
	{
		g_iClone[i] = -1;
		g_iPlayerEnum[i] = 0;
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = true;
	g_hCvarCrawl.IntValue = 0;
}



// ====================================================================================================
//					EVENT - PLAYER HURT
// ====================================================================================================
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bSpit && event.GetInt("type") == 263168 )	// Crawling in spit not allowed & acid damage type
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if( client > 0 && client <= MaxClients && !(g_iPlayerEnum[client] & ENUM_INSPIT) && !IsFakeClient(client) )
		{
			g_iPlayerEnum[client] |= ENUM_INSPIT;
			CreateTimer(2.0, tmrResetSpit, client);
		}
	}
}

public Action tmrResetSpit(Handle timer, any client)
{
	g_iPlayerEnum[client] &= ~ENUM_INSPIT;
}



// ====================================================================================================
//					EVENT - LEDGE / REIVE
// ====================================================================================================
public void Event_LedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_ONLEDGE;
}

public void Event_ReviveStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_INREVIVE;
}

public void Event_ReviveEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if( client > 0 )
		g_iPlayerEnum[client] = 0;
}

public void Event_Unblock(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client > 0)
		g_iPlayerEnum[client] = 0;
}



// ====================================================================================================
//					EVENT - ENUM_INCAPPED BY INFECTED
// ====================================================================================================
public void Event_BlockStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_BLOCKED;
}

public void Event_BlockEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
}

public void Event_BlockHunter(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_POUNCED;
}

public void Event_BlockEndHunt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_POUNCED;
}



// ====================================================================================================
//					EVENT - INCAPACITATED
// ====================================================================================================
public void Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !(g_iPlayerEnum[client] & ENUM_INSTART) && !IsFakeClient(client) && GetClientTeam(client) == 2 )
	{
		g_iPlayerEnum[client] |= ENUM_INCAPPED | ENUM_INSTART;
		CreateTimer(1.5, tmrResetStart, GetClientUserId(client));
	} else if( GetClientTeam(client) == 3 )
	{
		SetEntityMoveType(client, MOVETYPE_VPHYSICS);
	}
}

// Display hint message, allow crawling
public Action tmrResetStart(Handle timer, any client)
{
	client = GetClientOfUserId(client);
	g_iPlayerEnum[client] &= ~ENUM_INSTART;

	if( g_bRoundOver || !g_iHint || (g_iHint < 3 && g_iDisplayed[client] >= g_iHints) || !IsValidClient(client) )
		return;

	g_iDisplayed[client]++;
	char sBuffer[100];

	switch ( g_iHint )
	{
		case 1:		// Print to chat
		{
			if( g_bTranslation )
				Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 %T", "Crawl", client);
			else
				Format(sBuffer, sizeof(sBuffer), "\x04[\x01Incapped Crawling\x04]\x01 Press FORWARD to crawl while incapped");

			PrintToChat(client, sBuffer);
		}

		case 2:		// Display hint
		{
			if( g_bTranslation )
				Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] %T", "Crawl", client);
			else
				Format(sBuffer, sizeof(sBuffer), "[Incapped Crawling] - Press FORWARD to crawl while incapped");

			PrintHintText(client, sBuffer);
		}
	}
}



// ====================================================================================================
//					ON PLAYER RUN CMD
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Plugin enabled, player incapped and holding forward, in an active round
	if( !g_bCvarAllow )
		return Plugin_Continue;

	if( g_iPlayerEnum[client] & ENUM_INCAPPED && buttons & IN_FORWARD && !g_bRoundOver && GetClientTeam(client) == 2 )
	{
		if( g_iPlayerEnum[client] & ENUM_POUNCED )		// Player pounced
		{
			buttons &= ~IN_FORWARD;					// Stop pressing forward!
			return Plugin_Handled;					// Plugin_Continue allows them to move slightly, handled does not but freezes progress bar when reviving.
		}

		if( g_iPlayerEnum[client] != ENUM_INCAPPED ) 	// Must be incapped only
		{
			RestoreClient(client);					// Stop anim
			buttons &= ~IN_FORWARD;					// Stop pressing forward!
			return Plugin_Continue;
		}

		// No clone, create
		if( g_iClone[client] == -1 )		// Animation not playing
		{
			PlayAnim(client);
		}
	}
	else // Not holding forward/round over/not incapped, will restore if animation was playing
	{
		RestoreClient(client);
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					ANIMATION
// ====================================================================================================
public Action PlayAnim(int client)
{
	int iAnim;
	char sModel[42];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

	if( sModel[26] == 'c' )
		iAnim = -1;
	else if( sModel[26] == 'g' )						// g = Gambler
		iAnim = ANIM_L4D2_NICK;
	else if( sModel[26] == 'm' && sModel[27] == 'e' )	// me = Mechanic
		iAnim = ANIM_L4D2_ELLIS;
	else if( sModel[26] == 'p' )						// p = Producer
		iAnim = ANIM_L4D2_ROCH;
	else if( sModel[26] == 't' )						// t = Teenangst
		iAnim = ANIM_L4D2_ZOEY;
	else if( sModel[26] == 'm' && sModel[27] == 'a')	// ma = Manager
		iAnim = ANIM_L4D2_LOUIS;
	else if( sModel[26] == 'b' )						// b = Biker
		iAnim = ANIM_L4D2_FRANCIS;
	else if( sModel[26] == 'n' )						// n = Namvet
		iAnim = ANIM_L4D2_BILL;
	else
		return;

	// Start hurting player
	if( g_iHurt > 0 )
	{
		HurtPlayer(client);
		if( g_hTmrHurt == null )
			g_hTmrHurt = CreateTimer(1.0, tmrHurt, _, TIMER_REPEAT);
	}

	// Coach
	if( iAnim == -1 )
	{
		g_iClone[client] = 0;
		return;
	}

	// Create survivor clone
	int clone = CreateEntityByName("commentary_dummy");
	if( clone == -1 )
	{
		LogError("Failed to create commentary_dummy '%s' (%N)", sModel, client);
		return;
	}

	SetEntityModel(clone, sModel);
	g_iClone[client] = EntIndexToEntRef(clone); // Global clone ID

	// Attach to survivor
	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", client);
	SetVariantString("bleedout");
	AcceptEntityInput(clone, "SetParentAttachment");

	// Correct angles and origin
	float vPos[3], vAng[3];
	vPos[0] = -2.0;
	vPos[1] = -15.0;
	vPos[2] = -10.0;
	vAng[0] = -330.0;
	vAng[1] = -100.0;
	vAng[2] = 70.0;

	// Set angles and origin
	TeleportEntity(clone, vPos, vAng, NULL_VECTOR);

	// Set animation and playback rate
	//SetEntProp(clone, Prop_Send, "m_nSequence", iAnim);
	SetVariantString("incap_crawl");
	AcceptEntityInput(clone, "SetAnimation");
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", float(g_iRate) / 15); // Default speed = 15, normal rate = 1.0

	//LMC
	if(bLMC_Available)
	{
		int iEntity;
		iEntity = LMC_GetClientOverlayModel(client);
		if(iEntity > MaxClients && IsValidEntity(iEntity))
		{
			SetEntityRenderMode(client, RENDER_NONE);
			SetEntityRenderMode(clone, RENDER_NONE);
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "Detach");

			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "SetAttached", clone);
		}
		else
		{
			// Make Survivor Invisible
			SetEntityRenderMode(client, RENDER_NONE);
		}
	}
	else
	{
		// Make Survivor Invisible
		SetEntityRenderMode(client, RENDER_NONE);
	}
	//LMC

	// Disable Glow
	if(!g_bGlow)
		SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 0);

	// Thirdperson view
	if( g_bView )
		GotoThirdPerson(client);
}



// ====================================================================================================
//					DAMAGE PLAYER
// ====================================================================================================
public Action tmrHurt(Handle timer)
{
	bool bIsCrawling;

	// Loop through players
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) )
		{
			// They are crawling
			if( g_iClone[i] != -1 )
			{
				bIsCrawling = true;
				HurtPlayer(i);		// Hurt them
			}
		}
	}

	// Looped through all potential clones, no one crawling
	if( !bIsCrawling )
	{
		// No damage to deal, kill timer
		KillTimer(g_hTmrHurt);
		g_hTmrHurt = null;
	}
}

void HurtPlayer(int client)
{
	int iHealth = (GetClientHealth(client) - g_iHurt);
	if( iHealth > 0 )
		SetEntityHealth(client, iHealth);
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

public bool IsValidClient(int client)
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
		return true;
	return false;
}



// ====================================================================================================
//					RESTORE CLIENT
// ====================================================================================================
void RestoreClient(int client)
{
	if( g_iClone[client] == -1 )		// No anim playing
		return;
	else if( g_iClone[client] == 0 )	// Coach
		g_iClone[client] = -1;
	else
		RemoveClone(client);			// Delete clone
}



// ====================================================================================================
//					DELETE CLONE
// ====================================================================================================
void RemoveClone(int client)
{
	int clone = g_iClone[client];
	g_iClone[client] = -1;

	if( clone && EntRefToEntIndex(clone) != INVALID_ENT_REFERENCE )
	{
		//LMC
		if(bLMC_Available)
		{
			int iEntity;
			iEntity = LMC_GetClientOverlayModel(client);
			if(iEntity > MaxClients && IsValidEntity(iEntity))
			{
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "Detach");

				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetAttached", client);
			}
			else
			{
				SetEntityRenderMode(client, RENDER_NORMAL);
			}
		}
		else
		{
			SetEntityRenderMode(client, RENDER_NORMAL);
		}
		//LMC

		AcceptEntityInput(clone, "kill");
	}

	if( g_bView )					// Firstperson view
		GotoFirstPerson(client);

	if( !g_bGlow )					// Enable Glow
		SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
}