/*
*	Spray Trace No Menu
*
*	Spray Trace originally by Nican
*	Punishment menu added by mbalex (Aka Cpt.Moore)
*	Both versions combined by Lebson506th
*	No Menu version by Lebson506th
*
*	Description
*	-----------
*
*	This is a handy plugin for servers to trace a player's spray on any surface
*
*	Usage
*	-----
*
*	sm_spraynomenu_dista (default: 50.0) - maximum distance the plugin will trace the spray
*	sm_spraynomenu_refresh (default: 1.0) - How often sprays will be traced to show on HUD - 0.0 to disable feature
*	sm_spraynomenu_adminonly (default: 0) - Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.
*	sm_spraynomenu_fullhud (default: 0) - Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins
*	sm_spraynomenu_fullhudadmin (default: 1) - Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins
*	sm_spraynomenu_global (default: 1) - Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.
*	sm_spraynomenu_usehud (default: 1) - Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.
*	sm_spraynomenu_hudtime (default: 1.0) - How long the HUD messages are displayed.
*
*	To Do
*	----------
*	- Get translated into more languages
*
*	Change Log
*	----------
*
*	5/17/2011 - v5.8b
*	- Re-added the sm_spraynomenu_adminonly, sm_spraynomenu_fullhud, and sm_spraynomenu_fullhudadmin cvars
*
*	5/5/2011 - v5.8a
*	- Changed the versioning system to match the main plugin.
*
*	5/1/2011 - v1.0
*	- Initial release.
*/
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "v5.8b"
#define PLUGIN_ON 0
#define MAXDIS 1
#define REFRESHRATE 2
#define ADMINONLY 3
#define FULLHUD 4
#define FULLHUDADMIN 5
#define GLOBAL 6
#define USEHUD 7
#define HUDTIME 8
#define NUMCVARS 9

//Nican: I am doing all this global for those "happy" people who spray something and quit the server
float g_arrSprayTrace[MAXPLAYERS + 1][3], fMaxDis = 0.0, fHudTime = 0.0;
char g_arrSprayName[MAXPLAYERS + 1][64], g_arrSprayID[MAXPLAYERS + 1][32], g_arrMenuSprayID[MAXPLAYERS + 1][32];
int g_arrSprayTime[MAXPLAYERS + 1] = {0, ...}, g_iAdminOnly = 0;
// Misc. globals
ConVar g_arrCVars[NUMCVARS];
Handle g_hSprayTimer = null, g_hHUDMessage = null;
bool bHooked = false, g_bCanUseHUD = false, bUseHud = false, bFullHudAdmin = false, bFullHud = false, bGlobal = false;

public Plugin myinfo = 
{
	name = "Spray Tracer No Menu",
	author = "Nican132, CptMoore, Lebson506th",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart() 
{
	LoadTranslations("spraytracenomenu.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_spraynomenu_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	g_arrCVars[PLUGIN_ON] = CreateConVar("sm_spraynomenu_plugin_on", "1.0", "Plugin On/Off.");
	g_arrCVars[MAXDIS] = CreateConVar("sm_spraynomenu_dista", "50.0", "How far away the spray will be traced to.");
	g_arrCVars[REFRESHRATE] = CreateConVar("sm_spraynomenu_refresh", "1.0", "How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_arrCVars[ADMINONLY] = CreateConVar("sm_spraynomenu_adminonly", "1", "Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.");
	g_arrCVars[FULLHUD] = CreateConVar("sm_spray_fullhud", "0", "Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins.");
	g_arrCVars[FULLHUDADMIN] = CreateConVar("sm_spraynomenu_fullhudadmin", "1", "Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins.");
	g_arrCVars[GLOBAL] = CreateConVar("sm_spraynomenu_global", "1", "Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_arrCVars[USEHUD] = CreateConVar("sm_spraynomenu_usehud", "1", "Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");
	g_arrCVars[HUDTIME] = CreateConVar("sm_spraynomenu_hudtime", "1.0", "How long the HUD messages are displayed.");

	g_arrCVars[PLUGIN_ON].AddChangeHook(PluginOnConVarChanged);
	g_arrCVars[MAXDIS].AddChangeHook(ConVarsChanged);
	g_arrCVars[REFRESHRATE].AddChangeHook(TimerChanged);
	g_arrCVars[ADMINONLY].AddChangeHook(ConVarsChanged);
	g_arrCVars[FULLHUD].AddChangeHook(ConVarsChanged);
	g_arrCVars[FULLHUDADMIN].AddChangeHook(ConVarsChanged);
	g_arrCVars[GLOBAL].AddChangeHook(ConVarsChanged);
	g_arrCVars[USEHUD].AddChangeHook(ConVarsChanged);
	g_arrCVars[HUDTIME].AddChangeHook(ConVarsChanged);

	char gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	g_bCanUseHUD = StrEqual(gamename, "tf", false) 
	            || StrEqual(gamename, "hl2mp", false) 
	            || StrEqual(gamename, "sourceforts", false) 
	            || StrEqual(gamename, "obsidian", false) 
	            || StrEqual(gamename, "left4dead", false) 
	            || StrEqual(gamename, "l4d", false) 
	            || StrEqual(gamename, "left4dead2", false) 
	            || StrEqual(gamename, "l4d2", false);

	if(g_bCanUseHUD) g_hHUDMessage = CreateHudSynchronizer();

	AutoExecConfig(true, "plugin.spraytracenomenu");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/

public void OnMapStart() 
{
	for(int i = 1; i <= MaxClients; i++)
	{
		ClearVariables(i);
	}
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/

public void OnClientDisconnect(int client)
{
	if(!bGlobal) ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public void ClearVariables(int client)
{
	g_arrSprayTrace[client][0] = 0.0;
	g_arrSprayTrace[client][1] = 0.0;
	g_arrSprayTrace[client][2] = 0.0;
	strcopy(g_arrSprayName[client], sizeof(g_arrSprayName[]), "");
	strcopy(g_arrSprayID[client], sizeof(g_arrSprayID[]), "");
	strcopy(g_arrMenuSprayID[client], sizeof(g_arrMenuSprayID[]), "");
	g_arrSprayTime[client] = 0;
}

/*
Records the location, name, ID, and time of all sprays
*/

Action PlayerSpray(const char[] szTempEntName, const int[] arrClients, int iClientCount, float flDelay)
{
	int client = TE_ReadNum("m_nPlayer");
	if(IsValidClient(client)) 
	{
		TE_ReadVector("m_vecOrigin", g_arrSprayTrace[client]);
		g_arrSprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, g_arrSprayName[client], 64);
		GetClientAuthId(client, AuthId_Steam2, g_arrSprayID[client], 32);
	}
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void PluginOnConVarChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
{
	GetCvars();
}

/*
Refresh handlers for tracing to HUD or hint message
*/
void TimerChanged(ConVar hConVar, const char[] szOldValue, const char[] szNewValue)
{
	CreateTimers();
}

void IsAllowed()
{
    bool bPluginOn = g_arrCVars[PLUGIN_ON].BoolValue;
    if(bPluginOn && !bHooked)
    {
        bHooked = true;
        GetCvars();
        CreateTimers();
        AddTempEntHook("Player Decal", PlayerSpray);
    }
    else if(!bPluginOn && bHooked)
    {
        bHooked = false;
        RemoveTempEntHook("Player Decal", PlayerSpray);
        if(g_hSprayTimer != null) delete g_hSprayTimer;
        for(int i = 1; i <= MaxClients; i++)
        {
            ClearVariables(i);
        }
    }
}

void GetCvars()
{
    fMaxDis = g_arrCVars[MAXDIS].FloatValue;
    g_iAdminOnly = g_arrCVars[ADMINONLY].IntValue;
    bUseHud = g_arrCVars[USEHUD].BoolValue;
    fHudTime = g_arrCVars[HUDTIME].FloatValue;
    bFullHudAdmin = g_arrCVars[FULLHUDADMIN].BoolValue;
    bFullHud = g_arrCVars[FULLHUD].BoolValue;
    bGlobal = g_arrCVars[GLOBAL].BoolValue;
}

stock void CreateTimers()
{
	if(g_hSprayTimer != null) delete g_hSprayTimer;
	float timer = g_arrCVars[REFRESHRATE].FloatValue;
	if(timer > 0.0) g_hSprayTimer = CreateTimer(timer, CheckAllTraces, 0, TIMER_REPEAT);	
}

/*
Handle tracing sprays to the HUD or hint message
*/

Action CheckAllTraces(Handle hTimer, any useless)
{
	float vecPos[3];
	bool bHasHUDChanged = false;

	//God pray for the processor
	for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
    		if(GetPlayerEye(i, vecPos))
    		{
    			for(int a = 1; a <= MaxClients; a++)
    			{
    				if(GetVectorDistance(vecPos, g_arrSprayTrace[a]) <= fMaxDis)
    				{
    					AdminId admin = GetUserAdmin(i);
    					if(g_iAdminOnly != 1 || admin != INVALID_ADMIN_ID)
    					{
    						if(g_bCanUseHUD && bUseHud)
    						{
    							//Save bandwidth, only send the message if needed.
    							if(!bHasHUDChanged)
    							{
    								bHasHUDChanged = true;
    								SetHudTextParams(0.04, 0.6, fHudTime, 255, 50, 50, 255);
    							}
    
    							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || g_iAdminOnly != 2) 
    							{
    								if((admin != INVALID_ADMIN_ID && bFullHudAdmin) || bFullHud)
    									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed", i, g_arrSprayName[a], g_arrSprayID[a]);
    								else
    									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed Name", i, g_arrSprayName[a]);
    							}
    						}
    						else 
    						{
    							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || g_iAdminOnly != 2)
    							{
    								if((admin != INVALID_ADMIN_ID && bFullHudAdmin) || bFullHud)
    									PrintHintText(i, "%T", "Sprayed", i, g_arrSprayName[a], g_arrSprayID[a]);
    								else
    									PrintHintText(i, "%T", "Sprayed Name", i, g_arrSprayName[a]);
    							}
    						}
    					}
    					break;
    				}
    			}
    		}
		}
	}
	return Plugin_Continue;
}

/*
Helper Methods
*/

stock bool GetPlayerEye(int client, float vecPos[3])
{
	if(IsValidClient(client))
	{
    	float vecAngles[3], vecOrigin[3];

    	GetClientEyePosition(client, vecOrigin);
    	GetClientEyeAngles(client, vecAngles);

    	Handle hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	if(TR_DidHit(hTrace))
    	{
    	 	//This is the first function i ever saw that anything comes before the handle
    		TR_GetEndPosition(vecPos, hTrace);
    		CloseHandle(hTrace);
    		return true;
    	}
    	CloseHandle(hTrace);
	}
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
 	return entity > MaxClients;
}

public bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
