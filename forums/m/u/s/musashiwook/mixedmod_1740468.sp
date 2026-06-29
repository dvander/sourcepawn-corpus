

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define Version	"1.1"

new Handle:CvarMode;
new Handle:SetNextMode;
new Handle:ShowMessage;
new MinGameMode = 1;
new MaxGameMode = 3;
new Handle:game_type;
new Handle:game_mode;
new Handle:g_Nextmap;
new Random;
new	ArmsRaceMap;
new HostageMap;



public Plugin:myinfo = 
{
	name = "Mixed Modes",
	author = "ShoGun|KmKz",
	description = "This plugin set random game modes for CS:GO",
	version = Version,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_mixedmode_version", Version,"CS:GO Mixed Mode version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	CvarMode = CreateConVar("sm_game_mode", "1", "Get server game mode", FCVAR_PLUGIN);
	SetNextMode = CreateConVar("sm_nextgamemode", "1", "Set next server game mode", FCVAR_PLUGIN);
	ShowMessage = CreateConVar("sm_modesmessages", "1", "Enable or Disable messages", FCVAR_PLUGIN);
	
	RegConsoleCmd("sm_nextmode", NextModeCmd); 
	
	
	ArmsRaceMap = false;
	HostageMap = false;
	MaxGameMode = 3;
	
	// Find server cvars
	game_type = FindConVar("game_type");
	game_mode = FindConVar("game_mode");
	g_Nextmap = FindConVar("sm_nextmap");
	if (g_Nextmap != INVALID_HANDLE)
	{
		HookConVarChange(g_Nextmap, OnNextMapChange);
	}
	
	HookEvent("round_start", Event_RoundStart);
	
}

// If new nextmap is set, randomly choose new nextmap game mode
public OnNextMapChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ArmsRaceMap = false;
	HostageMap = false;
	OnMapStart();
	{ 
	if(GetConVarInt(ShowMessage) == 1)
		{
			PrintToServer("[Mixed Modes] NextMap changed to %s ,new game mode will set",newVal);
		}
	}
}

// Chat "nextmode" commande to display nextmap mode
public Action:NextModeCmd(client, args)
{
	for (new i = 1; i <= GetMaxClients(); i++)
	{		
		
		// Classic Casual
		if(GetConVarInt(SetNextMode) == 1)
		{
			PrintToChatAll("[Mixed Modes] Next Mode : Classic Casual Mode");
			PrintToServer("[Mixed Modes] Next Mode : Classic Casual Mode");
			return;
		}
	
		// Arms Race
		if (GetConVarInt(SetNextMode) == 2)
		{
			PrintToChatAll("[Mixed Modes] Next Mode : Arms Race Mode");
			PrintToServer("[Mixed Modes] Next Mode : Arms Race Mode");
			return;
		}
	
		// Demolition
		if (GetConVarInt(SetNextMode) == 3)
		{
			PrintToChatAll("[Mixed Modes] Next Mode : Demolition Mode");
			PrintToServer("[Mixed Modes] Next Mode : Demolition Mode");
			return;
		}
	}
}

// On round start display current game mode and nextmap game mode on chat
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(ShowMessage) == 1)
	{
	CurrentGameMode();
	NextGameMode();
	}
}

public CurrentGameMode()
{
	// Classic Casual
	if(GetConVarInt(CvarMode) == 1)
	{
		PrintToChatAll("[Mixed Modes] Classic Casual Mode");
	}
	
	// Arms Race
	if(GetConVarInt(CvarMode) == 2)
	{
		PrintToChatAll("[Mixed Modes] Arms Race Mode");
	}
	
	// Demolition
	if(GetConVarInt(CvarMode) == 3)
	{
		PrintToChatAll("[Mixed Modes] Demolition Mode");
	}
}

public NextGameMode()
{
	// Classic Casual
	if(GetConVarInt(SetNextMode) == 1)
	{
		PrintToChatAll("[Mixed Modes] Next Mode : Classic Casual Mode");
	}
	
	// Arms Race
	if (GetConVarInt(SetNextMode) == 2)
	{
		PrintToChatAll("[Mixed Modes] Next Mode : Arms Race Mode");
	}
	
	// Demolition
	if (GetConVarInt(SetNextMode) == 3)
	{
		PrintToChatAll("[Mixed Modes] Next Mode : Demolition Mode");
	}
}

//When map is start, remove demolition choice for the nextmap if a rescue hostage map is set or set "ArmsRace" mode for ArmsRace map.
public OnMapStart()
{
	decl String:mapname[128];
	GetNextMap(mapname, sizeof(mapname));
	{
		if (strncmp(mapname, "ar_", 3) == 0)
		{
			ArmsRaceMap = true;
			SetConVarInt(SetNextMode, 2);
			if(GetConVarInt(ShowMessage) == 1)
			{
				PrintToServer("[Mixed Modes] Arms Race Next Map Detected");
			}
			return;
		}
		
		if (strncmp(mapname, "cs_", 3) == 0)
		{
			HostageMap = true;
			MaxGameMode = 2;
			ChooseMode();
			if(GetConVarInt(ShowMessage) == 1)
			{
				PrintToServer("[Mixed Modes] Hostage Next Map Detected");
			}
		}
		
		else if ((!ArmsRaceMap) || (!HostageMap))
		{
			MaxGameMode = 3;
			ChooseMode();
			if(GetConVarInt(ShowMessage) == 1)
			{
				PrintToServer("[Mixed Modes] No Hostage Or Arms Race Next Map Detected");
			}
		}
	}
	
}

// Random Mode
public ChooseMode()
{	
	Random = GetRandomInt((MinGameMode), (MaxGameMode));
	SetConVarInt(SetNextMode, Random);
}

// On map end, set the new game_type and game_mode cvar 
public OnMapEnd()
{
	if (GetConVarInt(SetNextMode) == 1)
	{
		SetConVarInt(game_type, 0);
		SetConVarInt(game_mode, 0);
		SetConVarInt(CvarMode, 1);
		
		if(GetConVarInt(ShowMessage) == 1)
		{
			PrintToServer("[Mixed Modes] Classic Casual Mode");
		}
	}
	
	if(GetConVarInt(SetNextMode) == 2)
	{
		SetConVarInt(game_type, 1);
		SetConVarInt(game_mode, 0);
		SetConVarInt(CvarMode, 2);
		
		if(GetConVarInt(ShowMessage) == 1)
		{
			PrintToServer("[Mixed Modes] Arms Race Mode");
		}
	}
	
	if(GetConVarInt(SetNextMode) == 3)
	{
		SetConVarInt(game_type, 1);
		SetConVarInt(game_mode, 1);
		SetConVarInt(CvarMode, 3);
		
		if(GetConVarInt(ShowMessage) == 1)
		{
			PrintToServer("[Mixed Modes] Demolition Mode");
		}
	}
}



	
