#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS				FCVAR_NOTIFY

#define PLUGIN_VERSION 		"1.0"

#define ZOMBIECLASS_SMOKER  1
#define ZOMBIECLASS_BOOMER  2
#define ZOMBIECLASS_HUNTER  3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_WITCH 7
#define ZOMBIECLASS_TANK 8

// Cvar Handles/Variables
ConVar g_hCvarSmokMax, g_hCvarSmokMin, g_hCvarBoomMax, g_hCvarBoomMin, g_hCvarHuntMax, g_hCvarHuntMin, g_hCvarSpitMax, g_hCvarSpitMin, g_hCvarJockMax, g_hCvarJockMin, g_hCvarCharMax, g_hCvarCharMin, g_hCvarWitchMax, g_hCvarWitchMin, g_hCvarTankMax, g_hCvarTankMin, g_hCvarAllow; 
int  g_iCvarSmokMax, g_iCvarSmokMin, g_iCvarBoomMax, g_iCvarBoomMin, g_iCvarHuntMax, g_iCvarHuntMin, g_iCvarSpitMax, g_iCvarSpitMin, g_iCvarJockMax, g_iCvarJockMin, g_iCvarCharMax, g_iCvarCharMin, g_iCvarWitchMax, g_iCvarWitchMin, g_iCvarTankMax, g_iCvarTankMin;
bool g_bCvarAllow;

public Plugin myinfo = 
{
	name = "[L4D2] Random Color SI",
	author = "Toranks, AlexMy",
	description = "Changes the color of any SI every time spawns with a different color",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2780746"
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_color_si_allow",			"1",			"Activate or deactivate plugin", CVAR_FLAGS );
	g_hCvarSmokMax =		CreateConVar(	"l4d_color_si_spitter_max",			"255",			"Set maximum Smoker color value", CVAR_FLAGS );
	g_hCvarSmokMin =		CreateConVar(	"l4d_color_si_spitter_min",			"155",			"Set minimum Smoker color value", CVAR_FLAGS );
	g_hCvarBoomMax =		CreateConVar(	"l4d_color_si_boomer_max",			"255",			"Set maximum Boomer color value", CVAR_FLAGS );
	g_hCvarBoomMin =		CreateConVar(	"l4d_color_si_boomer_min",			"155",			"Set minimum Boomer color value", CVAR_FLAGS );
	g_hCvarHuntMax =		CreateConVar(	"l4d_color_si_hunter_max",			"255",			"Set maximum Hunter color value", CVAR_FLAGS );
	g_hCvarHuntMin =		CreateConVar(	"l4d_color_si_hunter_min",			"155",			"Set minimum Hunter color value", CVAR_FLAGS );
	g_hCvarSpitMax =		CreateConVar(	"l4d_color_si_spitter_max",			"255",			"Set maximum Spitter color value", CVAR_FLAGS );
	g_hCvarSpitMin =		CreateConVar(	"l4d_color_si_spitter_min",			"155",			"Set minimum Spitter color value", CVAR_FLAGS );
	g_hCvarJockMax =		CreateConVar(	"l4d_color_si_jockey_max",			"255",			"Set maximum Jockey color value", CVAR_FLAGS );
	g_hCvarJockMin =		CreateConVar(	"l4d_color_si_jockey_min",			"155",			"Set minimum Jockey color value", CVAR_FLAGS );
	g_hCvarCharMax =		CreateConVar(	"l4d_color_si_charger_max",			"255",			"Set maximum Charger color value", CVAR_FLAGS );
	g_hCvarCharMin =		CreateConVar(	"l4d_color_si_charger_min",			"155",			"Set minimum Charger color value", CVAR_FLAGS );
	g_hCvarWitchMax =		CreateConVar(	"l4d_color_si_witch_max",			"255",			"Set maximum Witch color value", CVAR_FLAGS );
	g_hCvarWitchMin =		CreateConVar(	"l4d_color_si_witch_min",			"155",			"Set minimum Witch color value", CVAR_FLAGS );
	g_hCvarTankMax =		CreateConVar(	"l4d_color_si_tank_max",			"255",			"Set maximum Tank color value", CVAR_FLAGS );
	g_hCvarTankMin =		CreateConVar(	"l4d_color_si_tank_min",			"155",			"Set minimum Tank color value", CVAR_FLAGS );
	CreateConVar(						"l4d_color_si_version",		PLUGIN_VERSION,	"Random Color SI plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_random_color_si");
	g_hCvarSmokMax.AddChangeHook(ColorCvarChange);
	g_hCvarSmokMin.AddChangeHook(ColorCvarChange);
	g_hCvarBoomMax.AddChangeHook(ColorCvarChange);
	g_hCvarBoomMin.AddChangeHook(ColorCvarChange);
	g_hCvarHuntMax.AddChangeHook(ColorCvarChange);
	g_hCvarHuntMin.AddChangeHook(ColorCvarChange);
	g_hCvarSpitMax.AddChangeHook(ColorCvarChange);
	g_hCvarSpitMin.AddChangeHook(ColorCvarChange);
	g_hCvarJockMax.AddChangeHook(ColorCvarChange);
	g_hCvarJockMin.AddChangeHook(ColorCvarChange);
	g_hCvarCharMax.AddChangeHook(ColorCvarChange);
	g_hCvarCharMin.AddChangeHook(ColorCvarChange);
	g_hCvarWitchMax.AddChangeHook(ColorCvarChange);
	g_hCvarWitchMin.AddChangeHook(ColorCvarChange);
	g_hCvarTankMax.AddChangeHook(ColorCvarChange);
	g_hCvarTankMin.AddChangeHook(ColorCvarChange);
	g_hCvarAllow.AddChangeHook(ColorCvarChange);	
	HookEvent("player_spawn", PlayerSpawn_Event);
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void PlayerSpawn_Event(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3) 
	{
		return;
	}
    
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (g_bCvarAllow)
	{
		ApplyColor(class, client);
	}
}

public void ColorCvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarSmokMax = g_hCvarSmokMax.IntValue;
	g_iCvarSmokMin = g_hCvarSmokMin.IntValue;
	g_iCvarBoomMax = g_hCvarBoomMax.IntValue;
	g_iCvarBoomMin = g_hCvarBoomMin.IntValue;
	g_iCvarHuntMax = g_hCvarHuntMax.IntValue;
	g_iCvarHuntMin = g_hCvarHuntMin.IntValue;
	g_iCvarSpitMax = g_hCvarSpitMax.IntValue;
	g_iCvarSpitMin = g_hCvarSpitMin.IntValue;
	g_iCvarJockMax = g_hCvarJockMax.IntValue;
	g_iCvarJockMin = g_hCvarJockMin.IntValue;
	g_iCvarCharMax = g_hCvarCharMax.IntValue;
	g_iCvarCharMin = g_hCvarCharMin.IntValue;
	g_iCvarWitchMax = g_hCvarWitchMax.IntValue;
	g_iCvarWitchMin = g_hCvarWitchMin.IntValue;
	g_iCvarTankMax = g_hCvarTankMax.IntValue;
	g_iCvarTankMin = g_hCvarTankMin.IntValue;
	g_bCvarAllow = g_hCvarAllow.BoolValue;
}

void ApplyColor(int class, int client)
{
	if (class == ZOMBIECLASS_SPITTER)
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarSpitMin, g_iCvarSpitMax), GetRandomInt(g_iCvarSpitMin, g_iCvarSpitMax), GetRandomInt(g_iCvarSpitMin, g_iCvarSpitMax), 255);
	}
	else if (class == ZOMBIECLASS_JOCKEY) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarJockMin, g_iCvarJockMax), GetRandomInt(g_iCvarJockMin, g_iCvarJockMax), GetRandomInt(g_iCvarJockMin, g_iCvarJockMax), 255);
	}
	else if (class == ZOMBIECLASS_BOOMER) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarBoomMin, g_iCvarBoomMax), GetRandomInt(g_iCvarBoomMin, g_iCvarBoomMax), GetRandomInt(g_iCvarBoomMin, g_iCvarBoomMax), 255);
	}
	else if (class == ZOMBIECLASS_CHARGER) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarCharMin, g_iCvarCharMax), GetRandomInt(g_iCvarCharMin, g_iCvarCharMax), GetRandomInt(g_iCvarCharMin, g_iCvarCharMax), 255);
	}
	else if (class == ZOMBIECLASS_HUNTER) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarHuntMin, g_iCvarHuntMax), GetRandomInt(g_iCvarHuntMin, g_iCvarHuntMax), GetRandomInt(g_iCvarHuntMin, g_iCvarHuntMax), 255);
	}
	else if (class == ZOMBIECLASS_SMOKER) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarSmokMin, g_iCvarSmokMax), GetRandomInt(g_iCvarSmokMin, g_iCvarSmokMax), GetRandomInt(g_iCvarSmokMin, g_iCvarSmokMax), 255);
	}
	else if (class == ZOMBIECLASS_WITCH) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarWitchMin, g_iCvarWitchMax), GetRandomInt(g_iCvarWitchMin, g_iCvarWitchMax), GetRandomInt(g_iCvarWitchMin, g_iCvarWitchMax), 255);
	}
	else if (class == ZOMBIECLASS_TANK) 
	{
			SetEntityRenderColor(client, GetRandomInt(g_iCvarTankMin, g_iCvarTankMax), GetRandomInt(g_iCvarTankMin, g_iCvarTankMax), GetRandomInt(g_iCvarTankMin, g_iCvarTankMax), 255);
	}
}