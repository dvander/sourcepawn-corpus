#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D] Random Gravity",
	author = "Dragokas",
	description = "Funny plugin to change global gravity randomly in time",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

ConVar 	g_hCvarEnable;
ConVar	g_hCvarGravity;

bool g_bLate;
bool g_bMsgDisplayed;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("gravity_random.phrases");

	CreateConVar(						"sm_gravity_random_version",	PLUGIN_VERSION,		"Plugin version", FCVAR_DONTRECORD );
	g_hCvarEnable = CreateConVar(		"sm_gravity_random_enable",		"1",				"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	
	AutoExecConfig(true,			"sm_gravity_random");
	
	g_hCvarGravity = FindConVar("sv_gravity");
	g_hCvarGravity.Flags &= ~FCVAR_NOTIFY;
	
	HookConVarChange(g_hCvarEnable,			ConVarChanged);
	
	InitHook();
	
	if (g_bLate)
		DisturbGravity(0.1);
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if (g_hCvarEnable.BoolValue) {
		if (!bHooked) {
			HookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("round_start",			Event_RoundStart, 	EventHookMode_PostNoCopy);
			g_hCvarGravity.SetInt(800, true, false);
			bHooked = false;
		}
	}
}

public void Event_RoundStart(Event event, const char[] sEvName, bool bDontBroadcast)
{
	g_bMsgDisplayed = false;
	DisturbGravity(60.0);
}

void DisturbGravity(float delay)
{
	CreateTimer(delay, Timer_BeginDisturb, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_BeginDisturb(Handle timer)
{
	static int iGrav;
	static float fMinDelay;
	static float fMaxDelay;

	if (!g_bMsgDisplayed) {
		g_bMsgDisplayed = true;
		CPrintToChatAll("\x04%t", "Moon"); // "Луна сошла с орбиты !!!");
	}
	
	if (GetRandomInt(1, 20) < 20) {
		if (GetRandomInt(1,2) == 1) {
			// low gravity
			iGrav = GetRandomInt(1000, 1200);
			fMinDelay = 3.0;
			fMaxDelay = 4.0;
		}
		else {
			// strong gravity
			iGrav = GetRandomInt(200, 400);
			fMinDelay = 1.0;
			fMaxDelay = 2.0;
		}
		#if (DEBUG)
			PrintToChatAll("New gravity = %i", iGrav);
		#endif	
		g_hCvarGravity.SetInt(iGrav, true, false);
		CreateTimer(GetRandomFloat(fMinDelay, fMaxDelay), Timer_BeginDisturb, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else {
		// normalize
		#if (DEBUG)
			PrintToChatAll("Gravity is normalized");
		#endif
		g_hCvarGravity.SetInt(800, true, false);
		CreateTimer(20.0, Timer_BeginDisturb, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock void CPrintToChatAll(const char[] format, any ...)
{
	char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			PrintToChat(i, buffer);
		}
	}
}
