#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION	"1.4.0"

#define CASUAL        0
#define COMPETITIVE   1
#define ARMSRACE      2
#define DEMOLITION    3
#define DEATHMATCH    4
#define MAXMODES      5

// Plugin convar handles
new Handle:h_cvarVersion;
new Handle:h_cvarEnable;
new Handle:h_cvarDefaultMode;
new Handle:h_cvarRandom;
new Handle:h_cvarMapList[MAXMODES];
new Handle:h_cvarMapCycle[MAXMODES];

// Convar handles
new Handle:h_cvarGameType;
new Handle:h_cvarGameMode;
new Handle:h_cvarNextMap;
new Handle:h_cvarMatchRestartDelay;
new Handle:h_cvarMapCycleFile;

// Convar variables
new bool:g_cvarEnable;
new g_cvarDefaultMode;
new bool:g_cvarRandom;
new String:g_cvarMapList[MAXMODES][PLATFORM_MAX_PATH];
new String:g_cvarMapCycle[MAXMODES][PLATFORM_MAX_PATH];
new Float:g_cvarMatchRestartDelay;

// Plugin variables
new bool:g_Override;
new g_NextMapMode;
new g_InChange;

public Plugin:myinfo = 
{
	name = "Next Map Mode",
	author = "Jasperman/Sheepdude/Teki",
	description = "Change game mode and game type based on the next map in the rotation",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com/"
};

/******
 *Load*
*******/

public OnPluginStart()
{
	// Translations
	LoadTranslations("core.phrases");
	
	// Find server convars
	h_cvarGameType = FindConVar("game_type");
	h_cvarGameMode = FindConVar("game_mode");
	h_cvarNextMap = FindConVar("sm_nextmap");
	h_cvarMatchRestartDelay = FindConVar("mp_match_restart_delay");
	h_cvarMapCycleFile = FindConVar("mapcyclefile");
	
	// Kill plugin if convars don't exist
	if(h_cvarGameType == INVALID_HANDLE)
		SetFailState("Cannot find game_type cvar.");
	if(h_cvarGameMode == INVALID_HANDLE)
		SetFailState("Cannot find game_mode cvar.");
	if(h_cvarNextMap == INVALID_HANDLE)
		SetFailState("Cannot find sm_nextmap cvar.");
	
	// Create plugin convars
	h_cvarVersion = CreateConVar("sm_nmm_version", PLUGIN_VERSION, "Version of Next Map Mode Plugin for SourceMod", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	h_cvarEnable = CreateConVar("sm_nmm_enable", "1", "Enable (1) or Disable( 0) Next Map Mode. Default: 1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarDefaultMode = CreateConVar("sm_nmm_defaultmode", "0", "Default Mode for undefined maps. 0-Casual, 1-Competitive, 2-Armsrace, 3-Demolition, 4-Deathmatch. Default: 0", FCVAR_NOTIFY, true, 0.0, true, 4.0);
	h_cvarRandom = CreateConVar("sm_nmm_random", "0", "Randomize the mode each map? Default: 0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarMapList[CASUAL] = CreateConVar("sm_nmm_maplist_casual", "cfg/maplist_casual.txt", "Text file list of casual maps");
	h_cvarMapList[COMPETITIVE] = CreateConVar("sm_nmm_maplist_competitive", "cfg/maplist_competitive.txt", "Text file list of competitive maps");
	h_cvarMapList[ARMSRACE] = CreateConVar("sm_nmm_maplist_armsrace", "cfg/maplist_armsrace.txt", "Text file list of armsrace maps");
	h_cvarMapList[DEMOLITION] = CreateConVar("sm_nmm_maplist_demolition", "cfg/maplist_demolition.txt", "Text file list of demolition maps");
	h_cvarMapList[DEATHMATCH] = CreateConVar("sm_nmm_maplist_deathmatch", "cfg/maplist_deathmatch.txt", "Text file list of deathmatch maps");
	h_cvarMapCycle[CASUAL] = CreateConVar("sm_nmm_mapcycle_casual", "", "Mapcyclefile for casual mode (Leave blank for no change)");
	h_cvarMapCycle[COMPETITIVE] = CreateConVar("sm_nmm_mapcycle_competitive", "", "Mapcyclefile for competitive mode (Leave blank for no change)");
	h_cvarMapCycle[ARMSRACE] = CreateConVar("sm_nmm_mapcycle_armsrace", "", "Mapcyclefile for arms mode (Leave blank for no change)");
	h_cvarMapCycle[DEMOLITION] = CreateConVar("sm_nmm_mapcycle_demolition", "", "Mapcyclefile for demolition mode (Leave blank for no change)");
	h_cvarMapCycle[DEATHMATCH] = CreateConVar("sm_nmm_mapcycle_deathmatch", "", "Mapcyclefile for deathmatch mode (Leave blank for no change)");
	
	// Convar hooks
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	HookConVarChange(h_cvarEnable, OnConvarChanged);
	HookConVarChange(h_cvarDefaultMode, OnConvarChanged);
	HookConVarChange(h_cvarRandom, OnConvarChanged);
	HookConVarChange(h_cvarMatchRestartDelay, OnConvarChanged);
	for(new i = 0; i < MAXMODES; i++)
	{
		HookConVarChange(h_cvarMapList[i], OnConvarChanged);
		HookConVarChange(h_cvarMapCycle[i], OnConvarChanged);
	}

	// Console commands
	RegConsoleCmd("sm_nmm", SetModeCmd, "Overrides mode for next map (0 = Casual, 1 = Competitive, 2 = Arms Race, 3 = Demolition, 4 = Deathmatch)");
	AddCommandListener(OnMapChanged, "changelevel");
	
	// Event hooks
	HookEvent("cs_win_panel_match", OnMatchEnd);
	
	// Execute configuration file
	AutoExecConfig(true, "nextmapmode");
	UpdateAllConvars();
}

/*********
 *Globals*
**********/

public OnConfigsExecuted()
{
	UpdateAllConvars();
}

/**********
 *Commands*
***********/

public Action:SetModeCmd(client, args)
{
	if(!IsValidClient(client) || !g_cvarEnable)
		return Plugin_Handled;
	
	if(!CheckCommandAccess(client, "sm_nmm", ADMFLAG_CHANGEMAP, true))
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "No Access");
		return Plugin_Handled;
	}
	
	if(args < 1)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Usage: \x05sm_nmm <mode>\x01 (0 = Casual, 1 = Competitive, 2 = Arms Race, 3 = Demolition, 4 = Deathmatch)");
		return Plugin_Handled;
	}
	
	decl String:argstring[32];
	GetCmdArgString(argstring, sizeof(argstring));
	
	// True if client input a valid integer argument
	g_Override = StringToIntEx(argstring, g_NextMapMode) == 1 && g_NextMapMode >= 0 && g_NextMapMode < MAXMODES;
	
	// Check if the client input a string argument
	if(!g_Override)
	{
		g_NextMapMode = -1;
		if(StrEqual(argstring, "Casual", false))
			g_NextMapMode = CASUAL;
		else if(StrEqual(argstring, "Competitive", false))
			g_NextMapMode = COMPETITIVE;
		else if(StrEqual(argstring, "Armsrace", false) || StrEqual(argstring, "Arms_race", false) || StrEqual(argstring, "Arms Race", false))
			g_NextMapMode = ARMSRACE;
		else if(StrEqual(argstring, "Demolition", false))
			g_NextMapMode = DEMOLITION;
		else if(StrEqual(argstring, "Deathmatch", false) || StrEqual(argstring, "Death_Match", false) || StrEqual(argstring, "Death Match", false))
			g_NextMapMode = DEATHMATCH;
		g_Override = g_NextMapMode != -1;
	}
	
	// Client has input a valid string or integer argument
	if(g_Override)
	{
		if(g_NextMapMode == CASUAL)
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Next Map Mode changed to Casual.");
		else if(g_NextMapMode == COMPETITIVE)
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Next Map Mode changed to Competitive.");
		else if(g_NextMapMode == ARMSRACE)
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Next Map Mode changed to Arms Race.");
		else if(g_NextMapMode == DEMOLITION)
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Next Map Mode changed to Demolition.");
		else
			ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Next Map Mode changed to Deathmatch.");
	}
	else
	{
		g_NextMapMode = g_cvarDefaultMode;
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Usage: \x05sm_nmm <mode>\x01 (0 = Casual, 1 = Competitive, 2 = Arms Race, 3 = Demolition, 4 = Deathmatch)");
	}
	return Plugin_Handled;
}

/********
 *Events*
*********/

// A client has changed the map (with changelevel, map, or sm_map)
public Action:OnMapChanged(client, const String:command[], argc)
{
	if(argc < 1)
		return Plugin_Continue;
	decl String:argstring[64];
	GetCmdArgString(argstring, sizeof(argstring));
	if(IsMapValid(argstring))
		SetNextMapMode(argstring);
	return Plugin_Continue;
}

// Change mode before the map change occurs so that the next map overview text blurb displays the correct mode
public OnMatchEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Delay changing the mode until just before the actual map change, so that the end-of-match scoreboard displays correctly
	if(g_cvarMatchRestartDelay)
		CreateTimer(g_cvarMatchRestartDelay - 0.2, OnIntermissionPost);
	else
	{
		decl String:buffer[64];
		GetConVarString(h_cvarNextMap, buffer, sizeof(buffer));
		SetNextMapMode(buffer);
	}	
}

/********
 *Plugin*
*********/

SetNextMapMode(const String:NextMap[])
{
	if(g_cvarEnable && !g_InChange)
	{
		// Next Map Mode has been manually set
		if(g_Override)
			g_Override = false;
		
		// Mode is randomized
		else if(g_cvarRandom)
			g_NextMapMode = GetRandomInt(0, MAXMODES - 1);
		
		// We need to find what the next map mode should be
		else
			g_NextMapMode = GetNextMapMode(NextMap);
		
		decl String:ModeName[24] = "Casual";
		new Type;
		new Mode;
		switch(g_NextMapMode)
		{
			case COMPETITIVE: 
			{
				Mode = 1;
				ModeName = "Competitive";
			}
			case ARMSRACE: 
			{
				Type = 1;
				ModeName = "Arms Race";
			}
			case DEMOLITION: 
			{
				Type = 1;
				Mode = 1;
				ModeName = "Demolition";
			}
			case DEATHMATCH:
			{
				Type = 1;
				Mode = 2;
				ModeName = "Deathmatch";
			}
		}
		SetConVarInt(h_cvarGameType, Type);
		SetConVarInt(h_cvarGameMode, Mode);
		if(FileExists(g_cvarMapCycle[g_NextMapMode]))
			SetConVarString(h_cvarMapCycleFile, g_cvarMapCycle[g_NextMapMode]);
		PrintToServer("[SM] Next Map Mode will be %s", ModeName);
		
		// Prevent function from being called twice due to changelevel command
		g_InChange = true;
	}
}

GetNextMapMode(const String:NextMap[])
{
	new String:Line[64];
	new linecount;
	for(new i = 0; i < MAXMODES; i++)
	{
		linecount = 0;
		if(!FileExists(g_cvarMapList[i]))
			continue;
		new Handle:File = OpenFile(g_cvarMapList[i], "r");
		if(File == INVALID_HANDLE)
		{
			LogError("Unable to read from \"%s\"", g_cvarMapList[i]);
			continue;
		}
		while(!IsEndOfFile(File))
		{
			ReadFileLine(File, Line, sizeof(Line));
			TrimString(Line);
			StripQuotes(Line);
			if(StrEqual(Line, NextMap, false))
				return i;
			linecount++;
		}
	}
	return g_cvarDefaultMode;
}

/********
 *Timers*
*********/

public Action:OnIntermissionPost(Handle:timer)
{
	decl String:buffer[64];
	GetConVarString(h_cvarNextMap, buffer, sizeof(buffer));
	SetNextMapMode(buffer);
	return Plugin_Handled;
}

/*********
 *Convars*
**********/

UpdateAllConvars()
{
	ResetConVar(h_cvarVersion);
	g_cvarEnable = GetConVarBool(h_cvarEnable);
	g_cvarDefaultMode = GetConVarInt(h_cvarDefaultMode);
	g_cvarRandom = GetConVarBool(h_cvarRandom);
	g_cvarMatchRestartDelay = GetConVarFloat(h_cvarMatchRestartDelay);
	for(new i = 0; i < MAXMODES; i++)
	{
		GetConVarString(h_cvarMapList[i], g_cvarMapList[i], sizeof(g_cvarMapList[]));
		GetConVarString(h_cvarMapCycle[i], g_cvarMapCycle[i], sizeof(g_cvarMapCycle[]));
	}
	g_InChange = false;
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateAllConvars();
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client))
		return true;
	return false;
}