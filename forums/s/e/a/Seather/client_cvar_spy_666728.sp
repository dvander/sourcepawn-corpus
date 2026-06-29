#pragma semicolon 1
#include <sourcemod>

/*



credit: snipplets copied, Kigen's Anti-Cheat http://forums.alliedmods.net/showthread.php?p=635173

example server.cfg:

sm_cvarspy_clear

sm_cvarspy_add "cl_logofile"
sm_cvarspy_add "cl_soundfile"

sm_cvarspy_add "cl_downloadfilter"
sm_cvarspy_add "cl_allowdownload"
sm_cvarspy_add "cl_allowupload"
sm_cvarspy_add "cl_forcepreload"

sm_cvarspy_add "con_enable"
sm_cvarspy_add "mp_decals"
sm_cvarspy_add "r_gamma"
sm_cvarspy_add "sensitivity"
sm_cvarspy_add "crosshair"
sm_cvarspy_add "voice_enable"
sm_cvarspy_add "cl_showpluginmessages"

sm_cvarspy_add "sv_client_cmdrate_difference"
sm_cvarspy_add "sv_maxcmdrate"
sm_cvarspy_add "sv_maxupdaterate"
sm_cvarspy_add "sv_maxrate"
sm_cvarspy_add "sv_mincmdrate"
sm_cvarspy_add "sv_minupdaterate"
sm_cvarspy_add "sv_minrate"
sm_cvarspy_add "cl_cmdrate"
sm_cvarspy_add "cl_updaterate"
sm_cvarspy_add "rate"

*/
public Plugin:myinfo =
{
	name = "Client Cvar Spy",
	author = "Seather",
	description = "Allows an admin to check the client side cvar values of a specified client",
	version = "0.0.1",
	url = "http://www.sourcemod.net"
};

#define MAX_CVARS 150
#define MAX_CVAR_LEN 50

new String:CvarArray[MAX_CVARS][MAX_CVAR_LEN];
new g_CvarCount = 0;

public OnPluginStart()
{
	RegServerCmd("sm_cvarspy_add",Command_add);
	RegServerCmd("sm_cvarspy_clear",Command_clear);
	
	RegAdminCmd("sm_cvarspy_scan", Command_scan, ADMFLAG_RCON, "sm_cvarspy_scan <#userid|name> [optional cvar name]");
}

public Action:Command_add(args) {
	if(g_CvarCount == MAX_CVARS) {
		LogError("Max number of cvar entries reached");
		return;
	}
	
	decl String:arg[MAX_CVAR_LEN];
	GetCmdArg(1, arg, sizeof(arg));
	
	strcopy(CvarArray[g_CvarCount], MAX_CVAR_LEN, arg);
		
	g_CvarCount++;
}

public Action:Command_clear(args) {
	g_CvarCount = 0;
}

public Action:Command_scan(client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cvarspy_scan <#userid|name> [option cvar name]");
		return Plugin_Handled;
	}
	
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target = FindTarget(client, arg, true);
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	decl String:PlayerName[64];
	GetClientName(target, PlayerName, sizeof(PlayerName));
	
	decl String:authString[64];
	if ( !GetClientAuthString(target, authString, sizeof(authString)) )
		strcopy(authString, sizeof(authString), "STEAM_ID_PENDING");

	PrintToConsole(client, "[SM] Cvar Listing for <%s><%s>", authString,PlayerName);
	if(args == 1) {
		new i;
		for(i = 0; i < g_CvarCount; i++) {
		
			QueryClientConVar(target,CvarArray[i],ClientCVarCallback,client);
		}
	}
	if(args == 2) {
		decl String:arg2[65];
		GetCmdArg(2, arg2, sizeof(arg2));
		
		QueryClientConVar(target,arg2,ClientCVarCallback,client);
	}
	return Plugin_Handled;
}
public ClientCVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:admin2) {
	new admin = admin2;
	if ( !client || !IsClientConnected(client) || IsFakeClient(client) )
		return;
	
	if(admin != 0 && !IsClientConnected(admin))
		return;

	decl String:filtered_cvarValue[500];
	
	if(result == ConVarQuery_Okay)
		strcopy(filtered_cvarValue, sizeof(filtered_cvarValue), cvarValue);
	if(result == ConVarQuery_NotFound)
		strcopy(filtered_cvarValue, sizeof(filtered_cvarValue), "ConVarQuery_NotFound - Client convar was not found.");
	if(result == ConVarQuery_NotValid)
		strcopy(filtered_cvarValue, sizeof(filtered_cvarValue), "ConVarQuery_NotValid - A console command with the same name was found, but there is no convar.");
	if(result == ConVarQuery_Protected)
		strcopy(filtered_cvarValue, sizeof(filtered_cvarValue), "ConVarQuery_Protected - Client convar was found, but it is protected. The server cannot retrieve its value.");
	
	PrintToConsole(admin, "-- %s %s",cvarName,filtered_cvarValue);
}
