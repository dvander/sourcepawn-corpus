#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION	"1.2.2"

new Handle:h_PLUGIN_ENABLED = INVALID_HANDLE;
new Handle:h_PLUGIN_DEFAULTMODE = INVALID_HANDLE;
new Handle:h_PLUGIN_MAPS_CASUAL = INVALID_HANDLE;
new Handle:h_PLUGIN_MAPS_COMPETITIVE = INVALID_HANDLE;
new Handle:h_PLUGIN_MAPS_ARMSRACE = INVALID_HANDLE;
new Handle:h_PLUGIN_MAPS_DEMOLITION = INVALID_HANDLE;
new Handle:h_SERVER_GAME_TYPE = INVALID_HANDLE;
new Handle:h_SERVER_GAME_MODE = INVALID_HANDLE;
new Handle:h_SOURCEMOD_NEXTMAP = INVALID_HANDLE;
new Handle:h_SOURCEMOD_HALFTIME = INVALID_HANDLE;

new bool:g_PLUGIN_ENABLED = true;
new bool:g_OVERRIDE = false;
new g_NEXTMAPMODE = 0;

public Plugin:myinfo = 
{
	name = "Next Map Mode",
	author = "Jasperman/Sheepdude/Teki",
	description = "This plugin will allow a server to configure a Game Type and Mode for the next map",
	version = PLUGIN_VERSION,
	url = "http://www.totalbantercommunity.com"
};


public OnPluginStart()
{
	CreateConVar("sm_nmm_version", PLUGIN_VERSION, "Version of Next Map Mode Plugin for Sourcemod", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	h_PLUGIN_ENABLED = CreateConVar("sm_nmm_enable", "1", "Enable (1) or Disable( 0) Next Map Mode. Default: 1", FCVAR_NOTIFY);
	h_PLUGIN_DEFAULTMODE = CreateConVar("sm_nmm_defaultmode", "1", "Default Mode for undefined maps. 0-Casual, 1-Competitive, 2-Armsrace, 3-Demolition. Default:0", FCVAR_NOTIFY);
	h_PLUGIN_MAPS_CASUAL = CreateConVar("sm_nmm_maps_casual", "", "List of Comma(,) delimited maps for casual games", FCVAR_NOTIFY);
	h_PLUGIN_MAPS_COMPETITIVE = CreateConVar("sm_nmm_maps_competitive", "", "List of Comma(,) delimited maps for competitive games", FCVAR_NOTIFY);
	h_PLUGIN_MAPS_ARMSRACE = CreateConVar("sm_nmm_maps_armsrace", "", "List of Comma(,) delimited maps for armsrace games", FCVAR_NOTIFY);
	h_PLUGIN_MAPS_DEMOLITION = CreateConVar("sm_nmm_maps_demolition", "", "List of Comma(,) delimited maps for demolition games", FCVAR_NOTIFY);
	
	//Get Server CVARS
	h_SERVER_GAME_TYPE = FindConVar("game_type");
	h_SERVER_GAME_MODE = FindConVar("game_mode");
	h_SOURCEMOD_NEXTMAP = FindConVar("sm_nextmap");
	h_SOURCEMOD_HALFTIME = FindConVar("mp_halftime_duration");

	HookEvent("cs_win_panel_match", onIntermission, EventHookMode_Pre);
	RegConsoleCmd("nmm_version", command_Version);
	RegAdminCmd("sm_nmm", override_Mode, ADMFLAG_CHANGEMAP, "Overrides mode for next map (0-Casual, 1-Competitive, 2-Arms Race, 3-Demolition.)");
	AddCommandListener(changeLevel, "changelevel");
}

public Action:override_Mode(client, args)
{
	if(args < 1)
	{
		PrintToConsole(client, "[SM] Usage: sm_nmm <int> (0-Casual, 1-Competitive, 2-Arms Race, 3-Demolition)");
		return Plugin_Handled;
	}
	new String:argstring[256];
	GetCmdArgString(argstring, sizeof(argstring));
	new temp = StringToInt(argstring);
	g_OVERRIDE = (temp >= 0 && temp < 4);
	if(g_OVERRIDE)
	{
		g_NEXTMAPMODE = temp;
		if(g_NEXTMAPMODE == 0)
			PrintToConsole(client, "Next Map Mode changed to Casual.");
		else if(g_NEXTMAPMODE == 1)
			PrintToConsole(client, "Next Map Mode changed to Competitive.");
		else if(g_NEXTMAPMODE == 2)
			PrintToConsole(client, "Next Map Mode changed to Arms Race.");
		else
			PrintToConsole(client, "Next Map Mode changed to Demolition.");
	}
	return Plugin_Handled;
}

public onIntermission(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:delay = GetConVarFloat(h_SOURCEMOD_HALFTIME) - 0.1;
	CreateTimer(delay, onIntermissionPost);
}

public Action:onIntermissionPost(Handle:timer)
{
	decl String:nextMap[64];
	GetConVarString(h_SOURCEMOD_NEXTMAP, nextMap, sizeof(nextMap));
	setNextMapMode(nextMap);
}

public Action:changeLevel(client, const String:command[], argc)
{
	decl String:argString[64];
	GetCmdArgString(argString, sizeof(argString));
	setNextMapMode(argString);
}

public Action:command_Version(client, args)
{
	if(GetCmdReplySource() == SM_REPLY_TO_CHAT)
		PrintToChat(client, "Please view your console for more information.");
	PrintToConsole(client, "NextMapMode Information:\n   Version: Unofficial %s   Author: Jasperman/Sheepdude/Teki", PLUGIN_VERSION);
	PrintToConsole(client, "   Website: http://www.totalbantercommunity.com\n   Compiled Time: 15:14, 4 October 2012");
	return Plugin_Handled;
}

getNextMapMode(const String:nextMap[])
{
	new String:casualMaps[32][32];
	new String:competitiveMaps[32][32];
	new String:armsraceMaps[32][32];
	new String:demolitionMaps[32][32];
	decl String:ca[512];
	decl String:co[512];
	decl String:ar[512];
	decl String:de[512];
	GetConVarString(h_PLUGIN_MAPS_CASUAL, ca, sizeof(ca));
	GetConVarString(h_PLUGIN_MAPS_COMPETITIVE, co, sizeof(co));
	GetConVarString(h_PLUGIN_MAPS_ARMSRACE, ar, sizeof(ar));
	GetConVarString(h_PLUGIN_MAPS_DEMOLITION, de, sizeof(de));
	ExplodeString(ca, ",", casualMaps, sizeof(casualMaps), sizeof(casualMaps[]), false);
	ExplodeString(co, ",", competitiveMaps, sizeof(competitiveMaps), sizeof(competitiveMaps[]), false);
	ExplodeString(ar, ",", armsraceMaps, sizeof(armsraceMaps), sizeof(armsraceMaps[]), false);
	ExplodeString(de, ",", demolitionMaps, sizeof(demolitionMaps), sizeof(demolitionMaps[]), false);
	new bool:match = false;
	for(new i = 0; i < sizeof(casualMaps); i++)
		if(strcmp(casualMaps[i], nextMap, false) == 0)
		{
			g_NEXTMAPMODE = 0;
			match = true;
			break;
		}
	if(!match)
		for(new i = 0; i < sizeof(competitiveMaps); i++)
			if(strcmp(competitiveMaps[i], nextMap, false) == 0)
			{
				g_NEXTMAPMODE = 1;
				match = true;
				break;
			}
	if(!match)
		for(new i = 0; i < sizeof(armsraceMaps); i++)
			if(strcmp(armsraceMaps[i], nextMap, false) == 0)
			{
				g_NEXTMAPMODE = 2;
				match = true;
				break;
			}
	if(!match)
		for(new i = 0; i < sizeof(demolitionMaps); i++)
			if(strcmp(demolitionMaps[i], nextMap, false) == 0)
			{
				g_NEXTMAPMODE = 3;
				match = true;
				break;
			}
	if(!match)
	{
		new defaultMode = GetConVarInt(h_PLUGIN_DEFAULTMODE);
		if(defaultMode >= 0 && defaultMode < 4)
			g_NEXTMAPMODE = defaultMode;
		else
			g_NEXTMAPMODE = 0;
	}
}

setNextMapMode(const String:nextMap[])
{
	g_PLUGIN_ENABLED = (GetConVarInt(h_PLUGIN_ENABLED) == 1);
	if(g_PLUGIN_ENABLED)
	{
		if(!g_OVERRIDE)
			getNextMapMode(nextMap);
		else
			g_OVERRIDE = false;
		decl String:modeName[36] = "Casual";
		new gameType = 0;
		new gameMode = 0;
		switch(g_NEXTMAPMODE)
		{
			case 1: 
			{
				gameMode = 1;
				modeName = "Competitive";
			}
			case 2: 
			{
				gameType = 1;
				modeName = "Arms Race";
			}
			case 3: 
			{
				gameType = 1;
				gameMode = 1;
				modeName = "Demolition";
			}
		}
		SetConVarInt(h_SERVER_GAME_TYPE, gameType);
		SetConVarInt(h_SERVER_GAME_MODE, gameMode);
		PrintToChatAll("[NMM] Next Map Game Mode is %s", modeName);
		PrintToServer("[NMM] Next Map Game Mode is %s", modeName);
	}
}