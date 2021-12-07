#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Transparent Cars (with color)",
	author = "Alex Dragokas",
	description = "Replaces some car properties",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
};

bool g_bLate;
bool g_bSpawnHooked;
int g_iCvarR, g_iCvarG, g_iCvarB, g_iCvarA, g_iCvarRndColor, g_iCvarRndAlpha;
ConVar g_ConVarEnable, g_ConVarR, g_ConVarG, g_ConVarB, g_ConVarA, g_ConVarRandomColor, g_ConVarRandomAlpha;

public void OnPluginStart()
{
	CreateConVar("l4d_transparent_cars_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD | CVAR_FLAGS);
	
	( g_ConVarEnable = 			CreateConVar("l4d_transparent_cars_enabled", 		"1", 	"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS)).AddChangeHook(ConVarChanged);
	( g_ConVarR = 				CreateConVar("l4d_transparent_cars_red", 			"255", 	"Color level of RED", CVAR_FLAGS, true, 0.0, true, 255.0)).AddChangeHook(ConVarChanged);
	( g_ConVarG = 				CreateConVar("l4d_transparent_cars_green", 			"0", 	"Color level of GREEN", CVAR_FLAGS, true, 0.0, true, 255.0)).AddChangeHook(ConVarChanged);
	( g_ConVarB = 				CreateConVar("l4d_transparent_cars_blue", 			"0", 	"Color level of BLUE", CVAR_FLAGS, true, 0.0, true, 255.0)).AddChangeHook(ConVarChanged);
	( g_ConVarA = 				CreateConVar("l4d_transparent_cars_alpha", 			"75", 	"Level of Alpha (transparency), 0 - invisible, 255 - fully visible", CVAR_FLAGS, true, 0.0, true, 255.0)).AddChangeHook(ConVarChanged);
	( g_ConVarRandomColor = 	CreateConVar("l4d_transparent_cars_random_color", 	"0", 	"0 - use color pre-defined by convars. 1 - generate random colors", CVAR_FLAGS)).AddChangeHook(ConVarChanged);
	( g_ConVarRandomAlpha = 	CreateConVar("l4d_transparent_cars_random_alpha", 	"0", 	"0 - use alpha pre-defined by convar. 1 - generate random transparency", CVAR_FLAGS)).AddChangeHook(ConVarChanged);
	
	AutoExecConfig(true,		"l4d_transparent_cars");
	
	GetCvars();
	
	if( g_bLate )
	{
		MakeCarSemitransparent();
	}
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarR = g_ConVarR.IntValue;
	g_iCvarG = g_ConVarG.IntValue;
	g_iCvarB = g_ConVarB.IntValue;
	g_iCvarA = g_ConVarA.IntValue;
	g_iCvarRndColor = g_ConVarRandomColor.IntValue;
	g_iCvarRndAlpha = g_ConVarRandomAlpha.IntValue;

	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_ConVarEnable.BoolValue )
	{
		if( !bHooked ) {
			HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public void OnMapEnd()
{
	Reset();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

void Reset()
{
	g_bSpawnHooked = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_bSpawnHooked )
	{
		g_bSpawnHooked = true;
		HookEvent("player_first_spawn",		Event_PlayerFirstSpawn,	EventHookMode_PostNoCopy);
	}
}

public void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client && IsClientInGame(client) && !IsFakeClient(client) )
	{
		UnhookEvent("player_first_spawn",	Event_PlayerFirstSpawn,	EventHookMode_PostNoCopy);
		g_bSpawnHooked = false;
		
		CreateTimer(0.1, 	tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(7.0, 	tmrStart, _, TIMER_FLAG_NO_MAPCHANGE); // repeat - just to be sure
		CreateTimer(10.5, 	tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action tmrStart(Handle timer)
{
	MakeCarSemitransparent();
}

void MakeCarSemitransparent()
{
	static char sModel[PLATFORM_MAX_PATH];
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")) )
	{
		if( HasEntProp(ent, Prop_Data, "m_ModelName") )
		{
			GetEntPropString(ent, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
			
			if( StrContains(sModel, "props_vehicles", false) != -1 )
			{
				SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
				
				if( g_iCvarRndColor )
				{
					g_iCvarR = GetRandomInt(0, 255);
					g_iCvarG = GetRandomInt(0, 255);
					g_iCvarB = GetRandomInt(0, 255);
				}
				if( g_iCvarRndAlpha )
				{
					g_iCvarA = GetRandomInt(0, 255);
				}
				
				SetEntityRenderColor(ent, g_iCvarR, g_iCvarG, g_iCvarB, g_iCvarA);
			}
		}
	}
}
