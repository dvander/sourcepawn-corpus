#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

#if SOURCEMOD_V_MINOR > 10
	#define PL_NAME	"Double Jump"
	#define PL_VER	"1.1.0"
#else
static const char
	PL_NAME[]	= "Double Jump",
	PL_VER[]	= "1.1.0";
#endif

bool
	bEnable,
	bEvent;
int
	iMax;
float
	flBoost;

public Plugin myinfo =
{
	name		= PL_NAME,
	version		= PL_VER,
	description	= "Allows double-jumping.",
	author		= "Paegus, Grey83",
	url			= "http://steamcommunity.com/groups/grey83ds"
}

public void OnPluginStart()
{
	CreateConVar("sm_doublejump_version", PL_VER, PL_NAME, FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);

	ConVar cvar;
	cvar = CreateConVar("sm_doublejump_enabled","1",	"Enables double-jumping.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEnable = cvar.BoolValue;

	cvar = CreateConVar("sm_doublejump_boost",	"260.0","The amount of vertical boost to apply to double jumps.", _, true, 260.0, true, 4095.0);
	cvar.AddChangeHook(CVarChanged_Boost);
	flBoost = cvar.FloatValue;

	cvar = CreateConVar("sm_doublejump_max",	"1",	"The maximum number of re-jumps allowed while already jumping. 0 = unlimited", _, true);
	cvar.AddChangeHook(CVarChanged_Max);
	iMax = cvar.IntValue;

	cvar = CreateConVar("sm_doublejump_event",	"0",	"Create event 'player_footstep' for other plugins.", _, true, _, true, 1.0);
	cvar.AddChangeHook(CVarChanged_Enable);
	bEvent = cvar.BoolValue;

	AutoExecConfig(true, "doublejump");
}

public void CVarChanged_Enable(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bEnable = cvar.BoolValue;
}

public void CVarChanged_Boost(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	flBoost = cvar.FloatValue;
}

public void CVarChanged_Max(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	iMax = cvar.IntValue;
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if(!bEnable || !IsPlayerAlive(client)) return Plugin_Continue;

	static bool ground, injump, wasjump[MAXPLAYERS+1], landed[MAXPLAYERS+1];
	ground = !!(GetEntityFlags(client) & FL_ONGROUND);
	injump = !!(GetClientButtons(client) & IN_JUMP);

	if(!landed[client])
	{
		if(iMax)
		{
			static int jumps[MAXPLAYERS+1];
			if(ground)
				jumps[client] = 0;
			else if(!wasjump[client] && injump && ++jumps[client] <= iMax)
				NewJump(client);
		}
		else if(!ground && !wasjump[client] && injump)
			NewJump(client);
	}

	landed[client]	= ground;
	wasjump[client]	= injump;

	return Plugin_Continue;
}

stock void NewJump(int client)
{
	static float vel[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
	vel[2] = flBoost;
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	if(!bEvent) return;

	Event event = CreateEvent("player_footstep");
	if(!event) return;

	event.SetInt("userid", GetClientUserId(client));
	event.Fire();
}