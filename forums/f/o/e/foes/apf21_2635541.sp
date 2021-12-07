#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define TIME_TO_TICKS(%1)	(RoundToNearest((%1) / GetTickInterval()))

int m_nTickBase, cvar_tickbase_diff, cvar_simtime_diff, oldtickbase[MAXPLAYERS + 1];
float m_flSimulationTime, oldsimtime[MAXPLAYERS + 1];
bool ban[MAXPLAYERS + 1], apf_mode;

public Plugin myinfo =
{
	name		= "Anti Packets Flood",
	author		= "",
	version		= "",
	url			= ""
};

public void OnPluginStart()
{
	ConVar cvar, cvar2, cvar3;
	(cvar = CreateConVar("sm_apf_mode", "0", "0 - Kick / 1 - Ban", _, true, 0.0, true, 1.0)).AddChangeHook(OnModeChanged);
	apf_mode = cvar.BoolValue;
	
	(cvar2 = CreateConVar("sm_apf_tickdifference", "2000", "tickbase difference in ticks", _, true, 0.0, true, 1337.0)).AddChangeHook(OnModeChanged2);
	cvar_tickbase_diff = cvar2.IntValue;
	
	// 15 ticks - command queue, 100 or more should be timeout/lag exploit
	(cvar3 = CreateConVar("sm_apf_simtime", "200", "simulation time difference in ticks", _, true, 0.0, true, 1337.0)).AddChangeHook(OnModeChanged3);
	cvar_simtime_diff = cvar3.IntValue;

	if ((m_nTickBase = FindSendPropInfo("CCSPlayer", "m_nTickBase")) == -1)
    {
        SetFailState("Property not found CCSPlayer::m_nTickBase");
    }
	
	if ((m_flSimulationTime = FindSendPropInfo("CCSPlayer", "m_flSimulationTime")) == -1) // if ((m_flSimulationTime = FindSendPropInfo("CCSPlayer", "m_flSimulationTime"), 2) == -1)
    {
        SetFailState("Property not found CCSPlayer::m_flSimulationTime");
    }
}

public void OnModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	apf_mode = convar.BoolValue;
}

public void OnModeChanged2(ConVar convar, const char[] oldValue, const char[] newValue)
{
	cvar_tickbase_diff = convar.IntValue;
}

public void OnModeChanged3(ConVar convar, const char[] oldValue, const char[] newValue)
{
	cvar_simtime_diff = convar.IntValue;
}

public void OnClientPutInServer(int client)
{
	ban[client] = false;
	oldtickbase[client] = 0;
	oldsimtime[client] = 0.0;
}

public Action OnPlayerRunCmd(int client)
{
	// If player is a fake client, there wills be an error in GetClientAvgPackets
	if (IsFakeClient(client) || ban[client])
	{
		return;
	}

	// Get client m_nTickBase. Check it
	Ban(client, GetEntData(client, m_nTickBase), GetEntDataFloat(client, m_flSimulationTime));
}

void Ban(int client, int tickbase, float simulationtime)
{
	if (tickbase < 0)
	{
		ban[client] = true;
		LogToFileEx("addons/apf.log", "%L Tickbase (%d) is less than 0", client, tickbase);
		if (apf_mode) ServerCommand("sm_ban #%d 0 \"Tickbase is less than 0\"", GetClientUserId(client));
		else KickClient(client, "Tickbase is less than 0");
	}
	else
	{
		if (tickbase != 0 && oldtickbase[client] != 0)
		{
			if ((tickbase - oldtickbase[client]) > cvar_tickbase_diff)
			{
				ban[client] = true;
				LogToFileEx("addons/apf.log", "%L Tickbase difference is greater than %d: %d", client, cvar_tickbase_diff, (tickbase - oldtickbase[client]));
				if (apf_mode) ServerCommand("sm_ban #%d 0 \"Tickbase difference is greater than %d: %d\"", GetClientUserId(client), cvar_tickbase_diff, (tickbase - oldtickbase[client]));
				else KickClient(client, "Tickbase difference is greater than %d: %d", cvar_tickbase_diff, (tickbase - oldtickbase[client]));
			}
		}
	}
	
	if (simulationtime < 0.0) // invalid
	{
		ban[client] = true;
		KickClient(client, "lag exploit/bad tick difference");
	}
	else
	{
		if (simulationtime != 0.0 && oldsimtime[client] != 0.0)
		{
			float bigdiff = simulationtime - oldsimtime[client];
			int ticks = TIME_TO_TICKS(FloatAbs(bigdiff));
			
			if (ticks > cvar_simtime_diff)
			{
				ban[client] = true;
				LogToFileEx("addons/apf.log", "%L simulation time difference is %d ", client, ticks);
				if (apf_mode) ServerCommand("sm_ban #%d 0 \"lag exploit/bad tick difference\"", GetClientUserId(client));
				else KickClient(client, "lag exploit/bad cheat/bad tick difference");
			}
		}
	}
	
	oldtickbase[client] = tickbase;
	oldsimtime[client] = simulationtime;
}