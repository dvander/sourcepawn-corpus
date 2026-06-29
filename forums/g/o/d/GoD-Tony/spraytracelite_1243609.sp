/*
*	Spray Trace Lite
*
*	Spray Trace originally by Nican
*	Lite version by Lebson506th
*
*	Description
*	-----------
*
*	This is a handy plugin for servers to trace a player's spray on any surface
*
*	Usage
*	-----
*
*	sm_spraylite_dista (default: 50.0) - maximum distance the plugin will trace the spray
*	sm_spraylite_global (default: 1) - Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.
*
*	Commands
*	--------
*
*	sm_spray - Detect a spray that the client is looking at and display the details in chat.
*
*	To Do
*	----------
*	- Get translated into more languages
*
*	Change Log
*	----------
*	5/7/2010 - v1.0
*	- Initial release.
*/

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.0"
#define MAXDIS 0
#define GLOBAL 1
#define NUMCVARS 2

//Nican: I am doing all this global for those "happy" people who spray something and quit the server
new Float:SprayTrace[MAXPLAYERS + 1][3];
new String:SprayName[MAXPLAYERS + 1][64];
new String:SprayID[MAXPLAYERS + 1][32];
new String:MenuSprayID[MAXPLAYERS + 1][32];
new SprayTime[MAXPLAYERS + 1];

// Misc. globals
new Handle:g_cvars[NUMCVARS];

public Plugin:myinfo = 
{
	name = "Spray Tracer Lite",
	author = "Nican132, CptMoore, Lebson506th",
	description = "Traces sprays on the wall",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	LoadTranslations("spraytracelite.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("sm_spraylite_version", PLUGIN_VERSION, "Spray tracer plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("sm_spray", Command_Spray);
	
	g_cvars[MAXDIS] = CreateConVar("sm_spraylite_dista","50.0","How far away the spray will be traced to.");
	g_cvars[GLOBAL] = CreateConVar("sm_spraylite_global","1","Enables or disables global spray tracking. If this is on, sprays can still be tracked when a player leaves the server.");

	AddTempEntHook("Player Decal",PlayerSpray);

	new String:gamename[32];
	GetGameFolderName(gamename, sizeof(gamename));

	AutoExecConfig(true, "plugin.spraytracelite");
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
	if(!GetConVarBool(g_cvars[GLOBAL]))
		ClearVariables(client);
}

/*
	Clears the stored sprays for the given client.
*/

public ClearVariables(client) {
	SprayTrace[ client ][0] = 0.0;
	SprayTrace[ client ][1] = 0.0;
	SprayTrace[ client ][2] = 0.0;
	strcopy(SprayName[ client ], sizeof(SprayName[]), "");
	strcopy(SprayID[ client ], sizeof(SprayID[]), "");
	strcopy(MenuSprayID[ client ], sizeof(MenuSprayID[]), "");
	SprayTime[ client ] = 0;
}

/*
Records the location, name, ID, and time of all sprays
*/

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay) {
	new client = TE_ReadNum("m_nPlayer");

	if(client && IsClientInGame(client)) {
		TE_ReadVector("m_vecOrigin",SprayTrace[client]);

		SprayTime[client] = RoundFloat(GetGameTime());
		GetClientName(client, SprayName[client], 64);
		GetClientAuthString(client, SprayID[client], 32);
	}
}

/*
Print spray details to the player that executed Command_Spray.
*/

public Action:Command_Spray(client, args) {
	new Float:pos[3];

	if(GetPlayerEye(client, pos)) {
		for(new i=1; i<=MaxClients;i++) {
		
			// If we find a spray to trace, display the details and break out of the loop.
			if(GetVectorDistance(pos, SprayTrace[i]) <= GetConVarFloat(g_cvars[MAXDIS])) {
				ReplyToCommand(client, "%t", "Sprayed", SprayName[i], SprayID[i]);
				break;
			}
			
			// We couldn't find a spray to trace.
			if(i == MaxClients)
				ReplyToCommand(client, "No spray detected.");
		}
	}
}

/*
Helper Methods
*/

public GetClientFromAuthID(const String:authid[]) {
	new String:tmpAuthID[32];
	for ( new i = 1; i <= GetMaxClients(); i++ ) {
		if (IsClientInGame(i) && !IsFakeClient(i) ) {
			GetClientAuthString(i, tmpAuthID, 32);

			if ( strcmp(tmpAuthID, authid) == 0 )
				return i;
		}
	}
	return 0;
}

stock bool:GetPlayerEye(client, Float:pos[3]) {
	new Float:vAngles[3], Float:vOrigin[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}

	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
 	return entity > MaxClients;
}