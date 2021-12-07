#include <sourcemod>

#define ADMIN_REDIRECT		ADMFLAG_RCON

public Plugin:myinfo = {
	name = "Server Migration",
	author = "[suRF-h] Rogue/Tobi / NIGathan",
	description = "Extract of redirect from HLstatsX, modified to auto prompt for redirect.",
	version = "1.1a niggy's revision a",
	url = "http://sandvich.justca.me/"
};

new Handle:hEnabled = INVALID_HANDLE;
new Handle:hNewServer = INVALID_HANDLE;
new Handle:hAutoTime = INVALID_HANDLE;
new Handle:hReason = INVALID_HANDLE;

new bool:enabled = true;
new String:newServer[22] = "";
new Float:autoTime = 25.0;
new String:treason[256] = "";

public OnPluginStart() 
{
	new String: game_description[64];
	GetGameDescription(game_description, 64, true);

	RegAdminCmd("sm_redirect", sm_redirect,ADMIN_REDIRECT);

	CreateConVar("sm_autoredirect_version", "1.1a niggy's revision a", "Server Migration", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	hEnabled = CreateConVar("sm_autoredirect", "1", "Force a redirect upon player join.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hNewServer = CreateConVar("sm_autoredirect_addr", "", "Server address to auto redirect players to. Example: 127.0.0.1:27015", FCVAR_PLUGIN);
	hAutoTime = CreateConVar("sm_autoredirect_time", "25.0", "Time to allow player to accept the redirect.", FCVAR_PLUGIN, true, 0.0);
	hReason = CreateConVar("sm_autoredirect_reason", "Please accept the server redirect prompt!", "Redirect reason, also used as the kick message.", FCVAR_PLUGIN);
	
	HookConVarChange(hEnabled, cvarUpdate);
	HookConVarChange(hNewServer, cvarUpdate);
	HookConVarChange(hAutoTime, cvarUpdate);
	HookConVarChange(hReason, cvarUpdate);

}

public cvarUpdate(Handle:convar, const String:oldValue[], const String:newValue[])
{
	enabled = GetConVarBool(hEnabled);
	GetConVarString(hNewServer, newServer, 22);
	autoTime = GetConVarFloat(hAutoTime);
	GetConVarString(hReason, treason, 256);
}

public OnClientPostAdminCheck(client)
{
	if (enabled)
	{
		ServerCommand("sm_redirect %f %i \"%s\" \"%s\"", autoTime, GetClientUserId(client), newServer, treason);
		CreateTimer(autoTime, getOut, client);
	}
}

public Action:getOut(Handle:Timer, any:client)
{
	if (IsClientInGame(client)) KickClient(client,treason);
	return Plugin_Handled;
}

public Action:sm_redirect(client,args)
{
	if (args < 3) {
		PrintToServer("Usage: sm_redirect <time> <userid> <address> <reason> - asks player to be redirected to specified gameserver");
		return Plugin_Handled;
	}

	new String:display_time[16];
	GetCmdArg(1, display_time, 16);

	new String:client_id[32];
	GetCmdArg(2, client_id, 32);

	new String:server_address[192];
	new argument_count = GetCmdArgs();
	new break_address = argument_count;

	for(new i = 2; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if (strcmp(temp_argument, ":") == 0) {
			break_address = i + 1;
		} else if (i == 3) {
			break_address = i - 1;
		}
		if (i <= break_address) {
			if ((192 - strlen(server_address)) > strlen(temp_argument)) {
				strcopy(server_address[strlen(server_address)], 192, temp_argument);
			}
		}
	}	

	new String:redirect_reason[192];
	for(new i = break_address + 1; i < argument_count; i++) {
		new String:temp_argument[192];
		GetCmdArg(i+1, temp_argument, 192);
		if ((192 - strlen(redirect_reason)) > strlen(temp_argument)) {
			redirect_reason[strlen(redirect_reason)] = 32;		
			strcopy(redirect_reason[strlen(redirect_reason)], 192, temp_argument);
		}
	}	


	new target = StringToInt(client_id);
	if ((target > 0) && (strcmp(server_address, "") != 0)) {
		new player_index = GetClientOfUserId(target);
		if ((player_index > 0) && (!IsFakeClient(player_index)) && (IsClientConnected(player_index))) {

			new Handle:top_values = CreateKeyValues("msg");
			KvSetString(top_values, "title", redirect_reason);
			KvSetNum(top_values, "level", 1); 
			KvSetString(top_values, "time", display_time); 
			CreateDialog(player_index, top_values, DialogType_Msg);
			CloseHandle(top_values);

			new Handle:values = CreateKeyValues("msg");
			KvSetString(values, "time", display_time); 
			KvSetString(values, "title", server_address); 
			CreateDialog(player_index, values, DialogType_AskConnect);
			CloseHandle(values);

		}	
	}		
	ReplyToCommand(client,"[SM] Redirect Request sent to player.")
		
	return Plugin_Handled;
}

