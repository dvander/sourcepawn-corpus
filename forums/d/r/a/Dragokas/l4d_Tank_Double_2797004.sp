#define PLUGIN_VERSION		"1.1"

/*
========================================================================================
	Change Log:

	1.0 (12-Jan-2023)
	- First commit
	
	1.1 (03-Feb-2023)
	 - Added ConVar "l4d_tank_double_enable" - Enable plugin (1 - Yes, 0 - No)

========================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY

ConVar g_hCvarEnable;

bool g_bLock;
bool g_bLeft4Dead2;
bool g_bEnabled;

public Plugin myinfo = 
{
	name = "Tank Double",
	author = "Alex Dragokas",
	description = "Creates second tank when director spawns the tank",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_tank_double_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	
	g_hCvarEnable 		= CreateConVar("l4d_tank_double_enable", 		"1", 	"Enable plugin (1 - Yes, 0 - No)", CVAR_FLAGS );
	
	AutoExecConfig(true, "l4d_tank_double");
	
	GetCvars();

	g_hCvarEnable.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	InitHook();
}

void InitHook()
{
	static bool bHooked;
	
	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Pre);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Pre);
			bHooked = false;
		}
	}
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool DontBroadcast)
{
	if( g_bLock ) return;
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if( client && IsClientInGame(client) )
	{
		int anyclient = GetAnyClient();
		if( anyclient != -1 )
		{
			g_bLock = true;
			CheatCommand(anyclient, g_bLeft4Dead2 ? "z_spawn_old" : "z_spawn", "tank auto");
			g_bLock = false;
		}
	}
}

stock int GetAnyClient() 
{
	for (int target = 1; target <= MaxClients; target++) 
	{
		if (IsClientInGame(target)) return target; 
	}
	return -1; 
}

stock void CheatCommand(int client, char[] command, char[] arguments = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}