#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
    name = "[L4D1] Winter Party",
    author = "Dragokas",
    description = "Starts disco on finales and some maps",
    version = "1.0",
    url = "https://dragokas.com/"
}

float g_vecPos[3];
float g_Timeout;

public void OnPluginStart()
{
	//HookEvent("round_freeze_end", 		Event_RoundFreezeEnd,	EventHookMode_PostNoCopy);
	HookEvent("finale_escape_start",	Event_EscapeStart,		EventHookMode_PostNoCopy);
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	static char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (strcmp(sMap, "l4d_garage02_lots") == 0)
	{
		ServerCommand("sm_startdisco 7068.619140 6453.736328 410.154388");
	}
	else if (strcmp(sMap, "l4d_hospital05_rooftop") == 0)
	{
		ServerCommand("sm_startdisco 7333.937988 8559.072265 6347.650878");
	}
	else if (strcmp(sMap, "l4d_airport05_runway") == 0)
	{
		ServerCommand("sm_startdisco -4692.732421 8864.442382 119.419837");
	}
	else if (strcmp(sMap, "l4d_farm05_cornfield") == 0)
	{
		ServerCommand("sm_startdisco 6969.762207 554.360046 424.745330 ");
	}
	else if (strcmp(sMap, "l4d_smalltown05_houseboat") == 0)
	{
		ServerCommand("sm_startdisco 2631.690185 -5018.675292 525.896545 ");
	}
	else if (strcmp(sMap, "l4d_river03_port") == 0)
	{
		ServerCommand("sm_startdisco -7.869229 -1401.957397 284.103271");
	}
}

public void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	static char sMap[32], sName[64];
	int entity = -1;
	
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (strcmp(sMap, "l4d_garage01_alleys") == 0)
	{
		while (-1 != (entity = FindEntityByClassname(entity, "func_button")))
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			if (strcmp(sName, "fire_howitzer") == 0)
			{
				g_vecPos[0] = -1335.436279;
				g_vecPos[1] = -4965.171386;
				g_vecPos[2] = 364.517578;
				g_Timeout = 75.0;
				HookSingleEntityOutput(entity, "OnKilled", OnButtonAction, true);
				break;
			}
		}
	}
	else if (strcmp(sMap, "l4d_hospital04_interior") == 0)
	{
		while (-1 != (entity = FindEntityByClassname(entity, "func_button")))
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
			if (strcmp(sName, "elevator_button") == 0)
			{
				g_vecPos[0] = 13430.045898;
				g_vecPos[1] = 15247.212890;
				g_vecPos[2] = 5787.724609;
				g_Timeout = 80.0;
				HookSingleEntityOutput(entity, "OnPressed", OnButtonAction, true);
				break;
			}
		}
	}
}

void OnButtonAction(const char[] output, int caller, int activator, float delay)
{
	ServerCommand("sm_startdisco %f %f %f", g_vecPos[0], g_vecPos[1], g_vecPos[2]);
	if (g_Timeout != 0.0)
	{
		StopDiscoTimeout(g_Timeout);
	}
}

void StopDiscoTimeout(float sec)
{
	CreateTimer(sec, Timer_StopDisco, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_StopDisco(Handle timer)
{
	ServerCommand("sm_stopdisco");
}