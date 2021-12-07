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

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "v5.8b"
#define MAXDIS 0
#define REFRESHRATE 1
#define ADMINONLY 2
#define FULLHUD 3
#define FULLHUDADMIN 4
#define GLOBAL 5
#define USEHUD 6
#define HUDTIME 7
#define NUMCVARS 8

//Nican: I am doing all this global for those "happy" people who spray something and quit the server
new Float:g_arrSprayTrace[MAXPLAYERS + 1][3];
new String:g_arrSprayName[MAXPLAYERS + 1][64];
new String:g_arrSprayID[MAXPLAYERS + 1][32];
new String:g_arrMenuSprayID[MAXPLAYERS + 1][32];
new g_arrSprayTime[MAXPLAYERS + 1];

// Misc. globals
new Handle:g_arrCVars[NUMCVARS];
new Handle:g_hSprayTimer = INVALID_HANDLE;
new Handle:g_hHUDMessage;
new bool:g_bCanUseHUD;

public Plugin:myinfo = 
{
	name = "Spray Tracer No Menu",
	author = "Nican132, CptMoore, Lebson506th",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	LoadTranslations("spraytracenomenu.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_spraynomenu_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_arrCVars[MAXDIS] = CreateConVar("sm_spraynomenu_dista","50.0","How far away the spray will be traced to.");
	g_arrCVars[REFRESHRATE] = CreateConVar("sm_spraynomenu_refresh","1.0","How often the program will trace to see player's spray to the HUD. 0 to disable.");
	g_arrCVars[ADMINONLY] = CreateConVar("sm_spraynomenu_adminonly","0","Changes showing the trace messages on HUD. 0 - Only admin can trace sprays 1 - All players can trace all sprays 2 - All players can trace all non-admin sprays.");
	g_arrCVars[FULLHUD] = CreateConVar("sm_spray_fullhud","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to non-admins.");
	g_arrCVars[FULLHUDADMIN] = CreateConVar("sm_spraynomenu_fullhudadmin","0","Toggles showing sprayer's name and Steam ID(1) or just sprayer's name(0) on the HUD to admins.");
	g_arrCVars[GLOBAL] = CreateConVar("sm_spraynomenu_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");
	g_arrCVars[USEHUD] = CreateConVar("sm_spraynomenu_usehud","1","Enables or disables using the HUD for spray tracking. Works on supported games. If this is off, hint will be used.");
	g_arrCVars[HUDTIME] = CreateConVar("sm_spraynomenu_hudtime","1.0","How long the HUD messages are displayed.");

	HookConVarChange(g_arrCVars[REFRESHRATE], TimerChanged);

	AddTempEntHook("Player Decal",PlayerSpray);

	CreateTimers();

	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	g_bCanUseHUD = StrEqual(gamename,"tf",false) || StrEqual(gamename,"hl2mp",false) || StrEqual(gamename,"sourceforts",false) || StrEqual(gamename,"obsidian",false) || StrEqual(gamename,"left4dead",false) || StrEqual(gamename,"l4d",false);
	if(g_bCanUseHUD)
		g_hHUDMessage = CreateHudSynchronizer();

	AutoExecConfig(true, "plugin.spraytracenomenu");
}

/*
	Clears all stored sprays when the map changes.
	Also prechaches the model.
*/

public OnMapStart() {
	for(new i = 1; i <= MaxClients; i++)
		ClearVariables(i);
}

/*
	Clears all stored sprays for a disconnecting
	client if global spray tracing is disabled.
*/

public OnClientDisconnect(client) {
	if(!GetConVarBool(g_arrCVars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public ClearVariables(client) {
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

public Action:PlayerSpray(const String:szTempEntName[], const arrClients[], iClientCount, Float:flDelay) {
	new client = TE_ReadNum("m_nPlayer");

	if(IsValidClient(client)) {
		TE_ReadVector("m_vecOrigin", g_arrSprayTrace[client]);

		g_arrSprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, g_arrSprayName[client], 64);
		GetClientAuthString(client, g_arrSprayID[client], 32);
	}
}

/*
Refresh handlers for tracing to HUD or hint message
*/

public TimerChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[]) {
	CreateTimers();
}

stock CreateTimers() {
	if(g_hSprayTimer != INVALID_HANDLE) {
		KillTimer( g_hSprayTimer );
		g_hSprayTimer = INVALID_HANDLE;
	}

	new Float:timer = GetConVarFloat( g_arrCVars[REFRESHRATE] );

	if( timer > 0.0 )
		g_hSprayTimer = CreateTimer( timer, CheckAllTraces, 0, TIMER_REPEAT);	
}

/*
Handle tracing sprays to the HUD or hint message
*/

public Action:CheckAllTraces(Handle:hTimer, any:useless) {
	new Float:vecPos[3];
	new bool:bHasHUDChanged = false;

	//God pray for the processor
	for(new i = 1; i <= MaxClients; i++) {
		if(!IsValidClient(i) || IsFakeClient(i))
			continue;

		if(GetPlayerEye(i, vecPos)) {
			for(new a = 1; a <= MaxClients; a++) {
				if(GetVectorDistance(vecPos, g_arrSprayTrace[a]) <= GetConVarFloat(g_arrCVars[MAXDIS])) {
					new AdminId:admin = GetUserAdmin(i);

					if(!(GetConVarInt(g_arrCVars[ADMINONLY]) == 1) || (admin != INVALID_ADMIN_ID)) {
						if(g_bCanUseHUD && GetConVarBool(g_arrCVars[USEHUD])) {
							//Save bandwidth, only send the message if needed.
							if(!bHasHUDChanged) {
								bHasHUDChanged = true;
								SetHudTextParams(0.04, 0.6, GetConVarFloat(g_arrCVars[HUDTIME]), 255, 50, 50, 255);
							}

							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_arrCVars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_arrCVars[FULLHUDADMIN])) || GetConVarBool(g_arrCVars[FULLHUD]))
									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed", i, g_arrSprayName[a], g_arrSprayID[a]);
								else
									ShowSyncHudText(i, g_hHUDMessage, "%T", "Sprayed Name", i, g_arrSprayName[a]);
							}
						}
						else {
							if((admin != INVALID_ADMIN_ID) || (IsClientInGame(a) && (GetUserAdmin(a) == INVALID_ADMIN_ID)) || (GetConVarInt(g_arrCVars[ADMINONLY]) != 2)) {
								if((admin != INVALID_ADMIN_ID && GetConVarBool(g_arrCVars[FULLHUDADMIN])) || GetConVarBool(g_arrCVars[FULLHUD]))
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

/*
Helper Methods
*/

stock bool:GetPlayerEye(client, Float:vecPos[3]) {
	if(!IsValidClient(client))
		return false;

	new Float:vecAngles[3], Float:vecOrigin[3];

	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client, vecAngles);

	new Handle:hTrace = TR_TraceRayFilterEx(vecOrigin, vecAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(hTrace)) {
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(vecPos, hTrace);
		CloseHandle(hTrace);
		return true;
	}

	CloseHandle(hTrace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity > MaxClients;
}

public bool:IsValidClient(client) {
	if(client <= 0)
		return false;
	if(client > MaxClients)
		return false;

	return IsClientInGame(client);
}