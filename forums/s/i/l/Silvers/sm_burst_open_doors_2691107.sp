#define PLUGIN_VERSION 		"1.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Burst Open Doors
*	Author	:	SilverShot
*	Descrp	:	Burst through doors simply by running into them. Idea taken from CoD Warzone.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322865
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.1 (06-Apr-2020)
	- Fixed "m_eDoorState" error. Thanks to "Cruze" for reporting.

1.0 (06-Apr-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

ConVar g_hCvarAllow, g_hCvarSpeed, g_hCvarTeam, g_hCvarType;
bool g_bCvarAllow, g_bLeft4Dead;
int g_iCvarTeam, g_iCvarType;
float g_fCvarSpeed, g_fLastUse[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Burst Open Doors",
	author = "SilverShot",
	description = "Burst through doors simply by running into them. Idea taken from CoD Warzone.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322865"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead || test == Engine_Left4Dead2 )
		g_bLeft4Dead = true;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =	CreateConVar(	"sm_burst_open_doors_allow",		"1",						"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarSpeed =	CreateConVar(	"sm_burst_open_doors_speed",		"180.0",					"0.0=Any speed. How fast someone must be moving to push open the door.", CVAR_FLAGS );
	g_hCvarTeam =	CreateConVar(	"sm_burst_open_doors_team",			g_bLeft4Dead ? "2" : "6",	"Which team to allow usage: 1=Team 1, 2=Team 2, 4=Team 3, 8=Team 4. (etc). Add numbers together.", CVAR_FLAGS );
	g_hCvarType =	CreateConVar(	"sm_burst_open_doors_type",			g_bLeft4Dead ? "3" : "1",	"1=Default (prop_door_rotating). L4D1/2: 2=Saferoom Doors (prop_door_rotating_checkpoint). 3=Both.", CVAR_FLAGS );
	CreateConVar(					"sm_burst_open_doors_version",		PLUGIN_VERSION,				"Burst Doors Open plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,			"sm_burst_open_doors");

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarSpeed.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTeam.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
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

void GetCvars()
{
	g_fCvarSpeed = g_hCvarSpeed.FloatValue;
	g_iCvarTeam = g_hCvarTeam.IntValue;
	g_iCvarType = g_hCvarType.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true )
	{
		g_bCvarAllow = true;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKHook(i, SDKHook_TouchPost, TouchPost);
			}
		}
	}

	else if( g_bCvarAllow == true && bCvarAllow == false )
	{
		g_bCvarAllow = false;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_TouchPost, TouchPost);
			}
		}
	}
}



// ====================================================================================================
//					RESET
// ====================================================================================================
public void OnMapEnd()
{
	ResetPlugin();
}

void ResetPlugin()
{
	for( int i = 0; i <= MaxClients; i++ )
		g_fLastUse[i] = 0.0;
}



// ====================================================================================================
//					HOOKS
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	if( g_bCvarAllow )
		SDKHook(client, SDKHook_TouchPost, TouchPost);
}

public void TouchPost(int client, int entity)
{
	if( g_bCvarAllow && entity > MaxClients && GetGameTime() > g_fLastUse[client] && IsPlayerAlive(client) )
	{
		// Team check
		int team = GetClientTeam(client) - 1;
		if( g_iCvarTeam & (1<<team) == 0 ) return;

		// Velocity check
		// float velocity; // To open the door slowly if not moving quick. Maybe future update. Must be able to push again while still opening. m_eDoorState 1 or something shows in rotation.
		if( g_fCvarSpeed )
		{
			float vVel[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel);
			if( GetVectorLength(vVel) < g_fCvarSpeed ) return;
			// velocity = GetVectorLength(vVel);
			// if( velocity < g_fCvarSpeed ) return;
		}

		// Classname check
		bool allow;
		static char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));

		switch( g_iCvarType )
		{
			case 1:	allow = strcmp(classname, "prop_door_rotating") == 0;
			case 2:	allow = strcmp(classname, "prop_door_rotating_checkpoint") == 0;
			case 3:	allow = strncmp(classname, "prop_door_rotating", 18) == 0 ;
		}

		// Door closed check
		if(	allow && GetEntProp(entity, Prop_Data, "m_eDoorState") == 0 )
		{
			g_fLastUse[client] = GetGameTime() + 0.5;

			// Fling open faster than normal
			float speed = GetEntPropFloat(entity, Prop_Data, "m_flSpeed");
			SetEntPropFloat(entity, Prop_Data, "m_flSpeed", 500.0);
			// velocity *= 2;
			// SetEntPropFloat(entity, Prop_Data, "m_flSpeed", velocity > 500.0 ? 500.0 : velocity);

			// Open
			AcceptEntityInput(entity, "PlayerOpen", client);

			// Reset open speed
			SetEntPropFloat(entity, Prop_Data, "m_flSpeed", speed);
		}
	}
}