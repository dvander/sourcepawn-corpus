#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new Handle:forward_connectmethodFavorites = INVALID_HANDLE;
new Handle:hEnable = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Favorite Connections",
  	author = "Nanochip & Wolvan",
	version = PLUGIN_VERSION,
  	description = "Detect when a player connects to the server via favorites.",
	url = "http://thecubeserver.org/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta") && !StrEqual(Game, "dod") && !StrEqual(Game, "hl2mp") && !StrEqual(Game, "css")) {
		Format(error, err_max, "This plugin only works for TF2, TF2Beta, DoD:S, CS:S and HL2:DM.");
		return APLRes_Failure;
	}
	
	RegPluginLibrary("favorite_connections");
	
	return APLRes_Success;
}

public OnPluginStart()
{
	forward_connectmethodFavorites = CreateGlobalForward("ClientConnectedViaFavorites", ET_Event, Param_Cell);
	CreateConVar("favoriteconnections_version", PLUGIN_VERSION, "Favorite Connections Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnable = CreateConVar("favoriteconnections_enable", "1", "Enable the plugin? 1 = Enable, 0 = Disable", FCVAR_NOTIFY);
	
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) 
		{
			doCheck(i);
		}
	}
}

public OnClientPostAdminCheck(client)
{
  	if (!GetConVarBool(hEnable)) 
	{
		return;
	}
	
	doCheck(client);
}

doCheck(client)
{
	new String:connectmethod[32];
	if (GetClientInfo(client, "cl_connectmethod", connectmethod, sizeof(connectmethod)))
	{
		if (StrEqual(connectmethod, "serverbrowser_favorites"))
		{
			new Action:result = Plugin_Continue;
			Call_StartForward(forward_connectmethodFavorites);
			Call_PushCell(client);
			Call_Finish(result);
		}
	}
}