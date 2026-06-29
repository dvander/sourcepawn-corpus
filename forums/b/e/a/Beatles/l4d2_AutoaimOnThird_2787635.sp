#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 		"1.1"
#define CVAR_FLAGS			FCVAR_NOTIFY

bool g_isInThirdPerson, g_bCvarHide, gc_bIsHost[MAXPLAYERS+1];
ConVar g_hCvarDistance, g_hCvarRate, g_hCvarShadows, g_hCvarHide;
float g_fCvarRate;
Handle g_hCheckTimer;
int g_iCvarShadows, g_iClientHost;
bool g_bLeft4Dead;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D/L4D2] ThirdPerson Autoaim",
	author = "Toranks",
	description = "Precise ThirdPerson Aim (Listen only)",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337956"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead)
	{
		g_bLeft4Dead = true;
	}
	else if (test == Engine_Left4Dead2)
	{
		g_bLeft4Dead = false;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	if (IsDedicatedServer())
	{
		strcopy(error, err_max, "This plugin ONLY works on Listen servers.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarRate = CreateConVar("l4d_autoaim_rate", "0.5", "Time between each aim adjustment.", CVAR_FLAGS);
	g_hCvarHide = CreateConVar("l4d_autoaim_hide_shadows", "1", "Set if you want to turn off dynamic flashlight shadows to avoid your own body shadows obstructing the vision only while on thirdperson.", CVAR_FLAGS);
	CreateConVar("l4d_autoaim_version", PLUGIN_VERSION,	"Autoaim plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_autoaim");
	
	g_hCvarDistance = FindConVar("c_thirdpersonshoulderaimdist");
	
	if (g_bLeft4Dead)
	{
		g_hCvarShadows = FindConVar("cl_maxrenderable_dist");
	}
	else
	{
		g_hCvarShadows = FindConVar("cl_max_shadow_renderable_dist");
	}
	
	g_hCvarRate.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHide.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarShadows.AddChangeHook(ConVarChanged_Cvars);
	
	int flags = GetConVarFlags(g_hCvarShadows);
	flags &= ~FCVAR_CHEAT;
	SetConVarFlags(g_hCvarShadows, flags);
	
	g_hCheckTimer = CreateTimer(g_fCvarRate, Check_Aim, _, TIMER_REPEAT);
}

public void OnAllPluginsLoaded()
{
	// ThirdPersonShoulder_Detect
	if (FindConVar("ThirdPersonShoulder_Detect_Version") == null)
	{
		SetFailState("\n==========\nMissing required plugin: \"ThirdPersonShoulder_Detect\".\nRead installation instructions again.\n==========");
	}
}

public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
		return;

	char ip[4];
	GetClientIP(client, ip, sizeof(ip));

	bool host = (ip[0] == 'l' || StrEqual(ip, "127")); // loopback/localhost or 127.X.X.X
	gc_bIsHost[client] = host;

	if (host)
		g_iClientHost = client;
}

public void OnClientDisconnect(int client)
{
	if (g_iClientHost == client)
		g_iClientHost = 0;

	gc_bIsHost[client] = false;
}

public void OnConfigsExecuted()
{
	GetCvars();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarRate = g_hCvarRate.FloatValue;
	g_bCvarHide = g_hCvarHide.BoolValue;
	g_iCvarShadows = g_hCvarShadows.IntValue;

	delete g_hCheckTimer;
	g_hCheckTimer = CreateTimer(g_fCvarRate, Check_Aim, _, TIMER_REPEAT);
}

Action Check_Aim(Handle timer)
{
	if (!IsValidClient(g_iClientHost))
		return Plugin_Continue;
		
	if (g_isInThirdPerson == true)
	{
		CmdDistDir(g_iClientHost);
	}
	return Plugin_Continue;
}

Action CmdDistDir(int iClient)
{
	float vOrigin[3], vEnd[3];
	float dist;

	if (GetDirectionEndPoint(iClient, vEnd))
	{
		GetClientAbsOrigin(iClient, vOrigin);
		dist = GetVectorDistance(vOrigin, vEnd);
		g_hCvarDistance.SetInt(RoundFloat(dist));
	}
	return Plugin_Handled;
}

bool GetDirectionEndPoint(int iClient, float vEndPos[3])
{
	float vDir[3], vPos[3];
	GetClientEyePosition(iClient, vPos);
	GetClientEyeAngles(iClient, vDir);

	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, iClient);
	if (hTrace != null)
	{
		if (TR_DidHit(hTrace))
		{
			TR_GetEndPosition(vEndPos, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

bool TraceRayNoPlayers(int entity, int mask, any data)
{
	if (entity == data || (entity >= 1 && entity <= MaxClients))
	{
		return false;
	}
	return true;
}

public void TP_OnThirdPersonChanged(int iClient, bool bIsThirdPerson)
{
	if (bIsThirdPerson == true)
	{
		g_isInThirdPerson = true;
		if (g_bCvarHide == true)
		{
			ClientCommand(iClient, "cl_max_shadow_renderable_dist 0");
		}
	}
	else if (bIsThirdPerson == false)
	{
		g_isInThirdPerson = false;
		if (g_iCvarShadows == 0)
		{
			ClientCommand(iClient, "cl_max_shadow_renderable_dist 3000");
		}
	}
}


// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client		Client index.
 * @return			  True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
	return (1 <= client <= MaxClients);
}

/**
 * Validates if is a valid client.
 *
 * @param client		  Client index.
 * @return				True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
	return (IsValidClientIndex(client) && IsClientInGame(client));
}