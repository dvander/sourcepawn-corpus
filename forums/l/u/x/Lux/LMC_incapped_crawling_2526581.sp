#define PLUGIN_VERSION 		"1.4" 
//no touchie the plugin version :D (by LUX)

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Incapped Crawling with Animation
*	Author	:	SilverShot
*	Descrp	:	Allows incapped survivors to crawl and sets crawling animation.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=137381

========================================================================================
	Change Log:
1.4(27-June-2017)
	-Added Workaround for Coach No Animations (Workaround requires LMC)(by Lux)
	-NOTE@ possible to cause bugs onlmc because of not calling the LMC forwards example: LMC_OnClientModelApplied()
1.33(6-June-2017)
	-Added LMC support for overlay models (by Lux) 
	-Thanks mastermind420 for helping me test.

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
	- Added UnhookEvents
	- Optimized some code
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
native LMC_GetClientOverlayModel(iClient);// remove this and enable the include to compile with the include this is just here for AM compiler
native LMC_SetClientOverlayModel(iClient, String:sModel[PLATFORM_MAX_PATH]);


static	Handle:g_hCvarCrawl, Handle:g_hCvarSpeed, Handle:g_hMPGameMode,
		Handle:g_hCvarAllow, Handle:g_hCvarGlow, Handle:g_hCvarHint, Handle:g_hCvarHintS, Handle:g_hCvarHurt, Handle:g_hCvarModes, Handle:g_hCvarModesOff,
		Handle:g_hCvarModesTog, Handle:g_hCvarRate, Handle:g_hCvarSpeeds, Handle:g_hCvarSpit, Handle:g_hCvarView, Handle:g_hTmrHurt;

static	bool:g_bCvarAllow, bool:g_bGlow, bool:g_bSpit, bool:g_bView, g_iHint, g_iHints, g_iHurt, g_iRate, g_iSpeed, bool:g_bTranslation, bool:g_bRoundOver,
		g_iPlayerEnum[MAXPLAYERS], g_iClone[MAXPLAYERS], g_iDisplayed[MAXPLAYERS];
	

enum (<<=1)
{
	ENUM_INCAPPED = 1,
	ENUM_INSTART,
	ENUM_BLOCKED,
	ENUM_POUNCED,
	ENUM_ONLEDGE,
	ENUM_INREVIVE,
	ENUM_INSPIT
}

//LMC
static bool:bLMC_Available = false;

static bool:bHadOverlayModel[MAXPLAYERS+1] = {false, ...};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("LMC_GetClientOverlayModel");
	MarkNativeAsOptional("LMC_SetClientOverlayModel");
	return APLRes_Success;
}

public OnAllPluginsLoaded()
{
	bLMC_Available = LibraryExists("L4D2ModelChanger");
}

public OnLibraryAdded(const String:sName[])
{
	if(StrEqual(sName, "L4D2ModelChanger"))
	bLMC_Available = true;
}

public OnLibraryRemoved(const String:sName[])
{
	if(StrEqual(sName, "L4D2ModelChanger"))
	bLMC_Available = false;
}
//LMC

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D2] Incapped Crawling with Animation",
	author = "SilverShot",
	description = "Allows incapped survivors to crawl and sets crawling animation.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=137381"
}

public OnPluginStart()
{
	decl String:sGameName[12];
	GetGameFolderName(sGameName, sizeof(sGameName));
	if( strcmp(sGameName, "left4dead2", false) )
		SetFailState("Plugin only supports Left4Dead 2.");

	decl String:sPath[PLATFORM_MAX_PATH];
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
	g_hCvarHint =		CreateConVar(	"l4d2_crawling_hint",		"2",			"0=Dislables, 1=Chat text, 2=Hint box, 3=Instructor hint.", CVAR_FLAGS);
	g_hCvarHintS =		CreateConVar(	"l4d2_crawling_hint_num",	"10",			"How many times to display hints or instructor hint timeout.", CVAR_FLAGS);
	g_hCvarHurt =		CreateConVar(	"l4d2_crawling_hurt",		"2",			"Damage to apply every second of crawling, 0=No damage when crawling.", CVAR_FLAGS);
	g_hCvarModes =		CreateConVar(	"l4d2_crawling_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_crawling_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_crawling_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRate =		CreateConVar(	"l4d2_crawling_rate",		"15",			"Sets the playback speed of the crawling animation.", CVAR_FLAGS);
	g_hCvarSpeeds =		CreateConVar(	"l4d2_crawling_speed",		"15",			"Changes 'survivor_crawl_speed' cvar.", CVAR_FLAGS);
	g_hCvarSpit =		CreateConVar(	"l4d2_crawling_spit",		"1",			"0=Disables crawling in spitter acid, 1=Enables crawling in spit.", CVAR_FLAGS);
	g_hCvarView =		CreateConVar(	"l4d2_crawling_view",		"1",			"0=Firstperson view when crawling, 1=Thirdperson view when crawling.", CVAR_FLAGS);
	CreateConVar(						"l4d2_crawling_version",	PLUGIN_VERSION, "Incapped Crawling plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_incapped_crawling");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesTog,	ConVarChanged_Allow);
	HookConVarChange(g_hCvarGlow,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHint,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHintS,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHurt,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpit,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarView,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarRate,		ConVarChanged_Cvars);
	HookConVarChange(g_hCvarSpeeds,		ConVarChanged_Speed);

	g_hCvarCrawl = FindConVar("survivor_allow_crawling");
	g_hCvarSpeed = FindConVar("survivor_crawl_speed");

	for( new i = 0; i < MAXPLAYERS; i++ )
		g_iClone[i] = -1;
}

public OnPluginEnd()
{
	SetConVarInt(g_hCvarCrawl, 0);

	for( new i = 1; i <= MaxClients; i++ )
	if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		RemoveClone(i);
}

public OnClientPutInServer(client)
{
	g_iDisplayed[client] = 0;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
	GetCvars();

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

public ConVarChanged_Speed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iSpeed = GetConVarInt(g_hCvarSpeeds);
	SetConVarInt(g_hCvarSpeed, g_iSpeed);
}

GetCvars()
{
	g_bGlow = GetConVarBool(g_hCvarGlow);
	g_iHint = GetConVarInt(g_hCvarHint);
	g_iHints = GetConVarInt(g_hCvarHintS);
	g_iHurt = GetConVarInt(g_hCvarHurt);
	g_iRate = GetConVarInt(g_hCvarRate);
	g_iSpeed = GetConVarInt(g_hCvarSpeeds);
	g_bSpit = GetConVarBool(g_hCvarSpit);
	g_bView = GetConVarBool(g_hCvarView);
}

IsAllowed()
{
	new bool:bCvarAllow = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();
		SetConVarInt(g_hCvarCrawl, 1);
		SetConVarInt(g_hCvarSpeed, g_iSpeed);

		for( new i = 1; i <= MaxClients; i++ )
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
		SetConVarInt(g_hCvarCrawl, 0);
	}
}

static g_iCurrentMode;

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
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
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
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



// ====================================================================================================
//					EVENTS
// ====================================================================================================
HookEvents()
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

UnhookEvents()
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
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = false;
	CreateTimer(1.0, tmrRoundStart);
}

public Action:tmrRoundStart(Handle:timer)
{
	g_bCvarAllow = GetConVarBool(g_hCvarAllow);

	if( g_bCvarAllow )
	{
		SetConVarInt(g_hCvarCrawl, 1);
		SetConVarInt(g_hCvarSpeed, g_iSpeed);
	}

	for( new i = 0; i < MAXPLAYERS; i++ )
	{
		g_iClone[i] = -1;
		g_iPlayerEnum[i] = 0;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bRoundOver = true;
	SetConVarInt(g_hCvarCrawl, 0);
}



// ====================================================================================================
//					EVENT - PLAYER HURT
// ====================================================================================================
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if( !g_bSpit && GetEventInt(event, "type") == 263168 )	// Crawling in spit not allowed & acid damage type
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if( client > 0 && client <= MaxClients && !(g_iPlayerEnum[client] & ENUM_INSPIT) && !IsFakeClient(client) )
		{
			g_iPlayerEnum[client] |= ENUM_INSPIT;
			CreateTimer(2.0, tmrResetSpit, client);
		}
	}
}

public Action:tmrResetSpit(Handle:timer, any:client)
	g_iPlayerEnum[client] &= ~ENUM_INSPIT;



// ====================================================================================================
//					EVENT - LEDGE / REIVE
// ====================================================================================================
public Event_LedgeGrab(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_ONLEDGE;
}

public Event_ReviveStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_INREVIVE;
}

public Event_ReviveEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_INREVIVE;
}

public Event_ReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "subject"));
	if( client > 0 )
		g_iPlayerEnum[client] = 0;
}

public Event_Unblock(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client > 0)
		g_iPlayerEnum[client] = 0;
}



// ====================================================================================================
//					EVENT - ENUM_INCAPPED BY INFECTED
// ====================================================================================================
public Event_BlockStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_BLOCKED;
}

public Event_BlockEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_BLOCKED;
}

public Event_BlockHunter(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if( client > 0 )
		g_iPlayerEnum[client] |= ENUM_POUNCED;
}

public Event_BlockEndHunt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "victim"));
	if( client > 0 )
		g_iPlayerEnum[client] &= ~ENUM_POUNCED;
}



// ====================================================================================================
//					EVENT - INCAPACITATED
// ====================================================================================================
public Event_Incapped(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( !(g_iPlayerEnum[client] & ENUM_INSTART) && !IsFakeClient(client) && GetClientTeam(client) == 2 )
	{
		g_iPlayerEnum[client] |= ENUM_INCAPPED | ENUM_INSTART;
		CreateTimer(1.5, tmrResetStart, GetClientUserId(client));
	}
}

// Display hint message, allow crawling
public Action:tmrResetStart(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	g_iPlayerEnum[client] &= ~ENUM_INSTART;

	if( g_bRoundOver || !g_iHint || (g_iHint < 3 && g_iDisplayed[client] >= g_iHints) || !IsValidClient(client) )
		return;

	g_iDisplayed[client]++;
	decl String:sBuffer[100];

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

		case 3:		// Instructor Hint
		{
			decl String:sTemp[32];

			if( g_bTranslation )
				Format(sBuffer, sizeof(sBuffer), "%T", "Crawl", client);
			else
				Format(sBuffer, sizeof(sBuffer), "Press FORWARD to crawl while incapped!");
			ReplaceString(sBuffer, sizeof(sBuffer), "\n", " ");

			new entity = CreateEntityByName("env_instructor_hint");
			FormatEx(sTemp, sizeof(sTemp), "hint%d", client);
			DispatchKeyValue(client, "targetname", sTemp);
			DispatchKeyValue(entity, "hint_target", sTemp);
			Format(sTemp, sizeof(sTemp), "%d", g_iHints);
			DispatchKeyValue(entity, "hint_timeout", sTemp);
			DispatchKeyValue(entity, "hint_range", "0.01");
			DispatchKeyValue(entity, "hint_icon_onscreen", "icon_key_up"); // icon_tip
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
}



// ====================================================================================================
//					ON PLAYER RUN CMD
// ====================================================================================================
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
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
public Action:PlayAnim(client)
{
	new iAnim = -1;
	decl String:sModel[42];
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
		if( g_hTmrHurt == INVALID_HANDLE )
			g_hTmrHurt = CreateTimer(1.0, tmrHurt, _, TIMER_REPEAT);
	}


	// Create survivor clone
	new clone = CreateEntityByName("prop_dynamic");
	if( clone == -1 )
	{
		LogError("Failed to create prop_dynamic '%s' (%N)", sModel, client);
		return;
	}
	
	//Coach workaround
	if(iAnim == -1 )
	{
		if(!bLMC_Available)
		{
			g_iClone[client] = 0;
			return;
		}
		SetEntityModel(clone, "models/survivors/survivor_gambler.mdl");
	}
	else
	{
		SetEntityModel(clone, sModel);
	}
	
	g_iClone[client] = EntIndexToEntRef(clone); // Global clone ID

	// Attach to survivor
	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", client);
	SetVariantString("bleedout");
	AcceptEntityInput(clone, "SetParentAttachment");

	// Correct angles and origin
	decl Float:vPos[3], Float:vAng[3];
	vPos[0] = -2.0;
	vPos[1] = -15.0;
	vPos[2] = -10.0;
	vAng[0] = -330.0;
	vAng[1] = -100.0;
	vAng[2] = 70.0;

	// Set angles and origin
	TeleportEntity(clone, vPos, vAng, NULL_VECTOR);

	// Set animation and playback rate
	if(iAnim == -1)
		SetEntProp(clone, Prop_Send, "m_nSequence", ANIM_L4D2_NICK);
	else
		SetEntProp(clone, Prop_Send, "m_nSequence", iAnim);
	
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", float(g_iRate) / 15); // Default speed = 15, normal rate = 1.0
	
	//LMC
	if(bLMC_Available)
	{
		static iEntity;
		iEntity = LMC_GetClientOverlayModel(client);
		if(iEntity > MaxClients && IsValidEntity(iEntity))
		{
			SetEntityRenderMode(client, RENDER_NONE);
			SetEntityRenderMode(clone, RENDER_NONE);
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "Detach");
			
			SetVariantString("!activator");
			AcceptEntityInput(iEntity, "SetAttached", clone);
			bHadOverlayModel[client] = true;
		}
		else if(iAnim == -1)
		{
			LMC_SetClientOverlayModel(client, "models/survivors/survivor_coach.mdl");
			iEntity = LMC_GetClientOverlayModel(client);
			if(iEntity != -1)
			{
				bHadOverlayModel[client] = false;
				SetEntityRenderMode(client, RENDER_NONE);
				SetEntityRenderMode(clone, RENDER_NONE);
				
				AcceptEntityInput(iEntity, "ClearParent");
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetParent", clone);
				
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "Detach");
				
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetAttached", clone);
			}
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
public Action:tmrHurt(Handle:timer)
{
	new bool:bIsCrawling;

	// Loop through players
	for( new i = 1; i <= MaxClients; i++ )
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
		g_hTmrHurt = INVALID_HANDLE;
	}
}

HurtPlayer(client)
{
	new iHealth = (GetClientHealth(client) - g_iHurt);
	if( iHealth > 0 )
		SetEntityHealth(client, iHealth);
}

GotoThirdPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

GotoFirstPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}

public IsValidClient(client)
{
	if( client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 )
		return true;
	return false;
}



// ====================================================================================================
//					RESTORE CLIENT
// ====================================================================================================
RestoreClient(client)
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
RemoveClone(client)
{
	new clone = g_iClone[client];
	g_iClone[client] = -1;

	if( clone && EntRefToEntIndex(clone) != INVALID_ENT_REFERENCE )
	{
		//LMC
		if(bLMC_Available)
		{
			static iEntity;
			iEntity = LMC_GetClientOverlayModel(client);
			if(iEntity > MaxClients && IsValidEntity(iEntity) && bHadOverlayModel[client])
			{
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "Detach");
			
				SetVariantString("!activator");
				AcceptEntityInput(iEntity, "SetAttached", client);
			}
			else if(iEntity > MaxClients && IsValidEntity(iEntity) && !bHadOverlayModel[client])
			{
				bHadOverlayModel[client] = false;
				SetEntityRenderMode(client, RENDER_NORMAL);
				AcceptEntityInput(iEntity, "kill");
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