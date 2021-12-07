#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.1.2"
#define AUTHOR "Jasperman/Sheepdude/Teki"
#define TBC_URL "http://www.totalbantercommunity.com"
#define OUTPUT_PREFIX "[NMM]"

new Handle:PLUGIN_ENABLED = INVALID_HANDLE;
new Handle:PLUGIN_DEFAULTMODE = INVALID_HANDLE;
new Handle:PLUGIN_MAPS_CASUAL = INVALID_HANDLE;
new Handle:PLUGIN_MAPS_COMPETITIVE= INVALID_HANDLE;
new Handle:PLUGIN_MAPS_ARMSRACE= INVALID_HANDLE;
new Handle:PLUGIN_MAPS_DEMOLITION= INVALID_HANDLE;
new Handle:PLUGIN_NEXTMAP_SETMODE = INVALID_HANDLE;
new Handle:SERVER_GAME_TYPE= INVALID_HANDLE;
new Handle:SERVER_GAME_MODE = INVALID_HANDLE;
new Handle:SOURCEMOD_NEXTMAP = INVALID_HANDLE;
new Handle:SOURCEMOD_MAPLIST = INVALID_HANDLE;

new bool:plugin_enabled = true;
new bool:manual_change = true;
new over_Write_Next_Map_Mode = false;
new next_map_mode = 0;
new game_type = 0;
new game_mode = 0;
new maplistserial = -1;

public Plugin:myinfo = 
{
	name = "Next Map Mode",
	author = AUTHOR,
	description = "This plugin will allow a server to configure a Game Type and Mode for the next map",
	version = PLUGIN_VERSION,
	url = TBC_URL
};


public OnPluginStart()
{
	CreateConVar("sm_nextmapmode_version", PLUGIN_VERSION, "Version of Next Map Mode Plugin For Sourcemod",FCVAR_NOTIFY);
	PLUGIN_ENABLED = CreateConVar("nextmapmode_enable", "1", "Enable(1) or Disable(0) Next Map Mode. Default: 1",FCVAR_NOTIFY);
	PLUGIN_DEFAULTMODE = CreateConVar("nextmapmode_defaultmode", "1", "Default Mode for undefined maps. 1-Casual, 2-Competitive, 3-Armsrace, 4-Demolition. Default:1",FCVAR_NOTIFY);
	PLUGIN_MAPS_CASUAL = CreateConVar("nextmapmode_maps_casual", "", "List of Comma(,) Seperated Maps for casual games",FCVAR_NOTIFY);
	PLUGIN_MAPS_COMPETITIVE = CreateConVar("nextmapmode_maps_competitive", "", "List of Comma(,) Seperated Maps for competitive games",FCVAR_NOTIFY);
	PLUGIN_MAPS_ARMSRACE = CreateConVar("nextmapmode_maps_armsrace", "", "List of Comma(,) Seperated Maps for armsrace games",FCVAR_NOTIFY);
	PLUGIN_MAPS_DEMOLITION = CreateConVar("nextmapmode_maps_demolition", "", "List of Comma(,) Separated Maps for demolition games",FCVAR_NOTIFY);
	PLUGIN_NEXTMAP_SETMODE = CreateConVar("nextmapmode_set_nextmap_mode", "", "Set the next maps mode 1-Casual, 2-Competitive, 3-Armsrace, 4-Demolition This will Overwrite the next maps mode (ignoring the defined maplists).",FCVAR_NOTIFY);
	
	//Get Server CVARS
	SERVER_GAME_TYPE = FindConVar("game_type");
	SERVER_GAME_MODE = FindConVar("game_mode");
	SOURCEMOD_NEXTMAP = FindConVar("sm_nextmap");
	SOURCEMOD_MAPLIST = ReadMapList(SOURCEMOD_MAPLIST, maplistserial, "default", MAPLIST_FLAG_CLEARARRAY);

	if (PLUGIN_NEXTMAP_SETMODE != INVALID_HANDLE)
	{
		HookConVarChange(PLUGIN_NEXTMAP_SETMODE, setNextMapModeEnabled);
	}
	AddCommandListener(changelevel, "changelevel");
	AddCommandListener(changelevel, "sm_map");
}

public OnMapStart()
{
	manual_change = false;
}

public setNextMapModeEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new convar_value = GetConVarInt(PLUGIN_ENABLED);
	plugin_enabled = (convar_value == 1);
}

public Action:changelevel(client, const String:command[], argc)
{
	decl String:argstring[64];
	GetCmdArgString(argstring,sizeof(argstring));
	if (FindStringInArray(SOURCEMOD_MAPLIST, argstring) != -1)
	{
		manual_change = true;
		setNextMapMode(argstring);
	}
}

getnext_map_mode(const String:smnextmap[])
{
	decl String:casualmaps[512];
	decl String:competitivemaps[512];
	decl String:armsracemaps[512];
	decl String:demolitionmaps[512];
	GetConVarString(PLUGIN_MAPS_CASUAL,casualmaps,512);
	GetConVarString(PLUGIN_MAPS_COMPETITIVE,competitivemaps,512);
	GetConVarString(PLUGIN_MAPS_ARMSRACE,armsracemaps,512);
	GetConVarString(PLUGIN_MAPS_DEMOLITION,demolitionmaps,512);
	new thenext_map_mode = 1;
	new bool:iscasual = (StrContains(casualmaps,smnextmap,false) != -1);
	new bool:iscompetitive = (StrContains(competitivemaps,smnextmap,false) != -1);
	new bool:isarmsrace = (StrContains(armsracemaps,smnextmap,false) != -1);
	new bool:isdemolotion = (StrContains(demolitionmaps,smnextmap,false) != -1);

	if(iscasual)
	{
		thenext_map_mode = 1;
	}
	else if(iscompetitive)
	{
		thenext_map_mode = 2;
	}	
	else if(isarmsrace)
	{
		thenext_map_mode = 3;
	}	
	else if(isdemolotion)
	{
		thenext_map_mode = 4;
	}
	else
	{
		new defaultMode = GetConVarInt(PLUGIN_DEFAULTMODE);
		if((defaultMode < 5) && (defaultMode > 0))
		{
			thenext_map_mode = defaultMode;
		}
	}
	return thenext_map_mode;
}

setNextMapMode(const String:argstring[])
{
	plugin_enabled = (GetConVarInt(PLUGIN_ENABLED) == 1);
	if(plugin_enabled)
	{
		if(!over_Write_Next_Map_Mode)
		{
			next_map_mode = getnext_map_mode(argstring);
		}
		else
		{
			over_Write_Next_Map_Mode = false;
		}
		decl String:gameMode[36];
		switch(next_map_mode)
		{
			case 1: 
			{
				game_type = 0;
				game_mode = 0;
				gameMode = "Casual";
			}
			case 2: 
			{
				game_type = 0;
				game_mode = 1;
				gameMode = "Competitive";
			}
			case 3: 
			{
				game_type = 1;
				game_mode = 0;
				gameMode = "Arms Race";
			}
			case 4: 
			{
				game_type = 1;
				game_mode = 1;
				gameMode = "Demolition";
			}
		}
		SetConVarInt(SERVER_GAME_TYPE, game_type);
		SetConVarInt(SERVER_GAME_MODE, game_mode);
		PrintToChatAll("%s Next Map Game Mode is %s",OUTPUT_PREFIX,gameMode);
		PrintToServer("%s Next Map Game Mode is %s",OUTPUT_PREFIX,gameMode);
	}
}
public OnMapEnd()
{
	if(!manual_change && GetClientCount() != 0)
	{
		decl String:tempnextmap[64];
		GetConVarString(SOURCEMOD_NEXTMAP,tempnextmap,64);
		setNextMapMode(tempnextmap);
	}
}