/*

Description:

Adds a !teamspeak command that allows players to join the teamspeak server or admins to force players into the teamspeak server
Adds a !ventrilo command that allows players to join the ventrilo server or admins to force players into the ventrilo server

Commands:

sm_teamspeak [<target>] - When a player executes it, it just opens the players teamspeak, connects him to the server and joins the specified channel in the config.
When an admin executes it he can also specify a target which player to join the teamspeak.
example: !ts @all would force all players to connect to the teamspeak server

sm_ventrilo [<target>] - When a player executes it, it just opens the players ventrilo, connects him to the server and joins the specified channel in the config.
When an admin executes it he can also specify a target which player to join the ventrilo server.
example: !vent @all would force all players to connect to the teamspeak server


sm_ts - Alias of sm_teamspeak
sm_vent - Alias of sm_ventrilo


Config

configs/teamspeak.cfg
configs/ventrilo.cfg


Changelog

Date: 26.08.2008
Version: 1.0

    * Initial release

Notes

Many thanks to berni for writing the initial Teamspeak join plugin on which this is based

*/





// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Voice server join command",
	author = "reverend",
	description = "Allows players to join teamspeak or ventrilo servers",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
new Handle:vs_version;

new String:address[256];
new String:password[64];
new String:channel[128];
new String:Vaddress[256];
new String:Vservername[128];
new String:Vpassword[64];
new String:Vchannel[128];
new String:DisAllowedClientNameChars[128];


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	// ConVars
	vs_version = CreateConVar("vs_version", PLUGIN_VERSION, "Voice Server plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(vs_version, PLUGIN_VERSION);

	RegConsoleCmd("sm_ts", Command_Teamspeak, "Allows users to join the teamspeak server");
	RegConsoleCmd("sm_teamspeak", Command_Teamspeak, "Allows users to join the teamspeak server");
	RegConsoleCmd("sm_vent", Command_Ventrilo, "Allows users to join the ventrilo server");
	RegConsoleCmd("sm_ventrilo", Command_Ventrilo, "Allows users to join the ventrilo server");
}

public OnConfigsExecuted() {
	ReadConfig();
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_Teamspeak(client, args) {
	decl target_list[MAXPLAYERS];
	new target_count;

	if (args == 0) {
		target_count = 1;
		target_list[0] = client;
	}
	else {
	
		new AdminId:aid = GetUserAdmin(client);
		
		if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
			decl String:target[MAX_TARGET_LENGTH];
			GetCmdArg(1, target, sizeof(target));

			decl String:target_name[MAX_TARGET_LENGTH];
			decl bool:tn_is_ml;

			target_count = ProcessTargetString(
					target,
					client,
					target_list,
					sizeof(target_list),
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml
			);
			
			ReplyToCommand(client, "\x04[SM] Command executed on target %s...", target);
		}
		else {
			ReplyToCommand(client, "\x04[SM] Access denied");
			return Plugin_Handled;
		}
	}
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
		return Plugin_Handled;
	}
	
	decl String:URL[256];
	decl String:nickName[64];

	for (new i=0; i<target_count; ++i) {
		GenerateValidTeamspeakNickName(target_list[i], nickName, sizeof(nickName));
		
		PrintToChatAll("Debug: name: %s", nickName);
		
		Format(URL, sizeof(URL), "teamspeak://%s/nickname=%s?password=%s?channel=%s", address, nickName, password, channel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Teamspeak server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
	}
	
	return Plugin_Handled;
}

public Action:Command_Ventrilo(client, args) {
	decl target_list[MAXPLAYERS];
	new target_count;

	if (args == 0) {
		target_count = 1;
		target_list[0] = client;
	}
	else {
	
		new AdminId:aid = GetUserAdmin(client);
		
		if (aid != INVALID_ADMIN_ID && GetAdminFlag(aid, Admin_Custom4)) {
			decl String:target[MAX_TARGET_LENGTH];
			GetCmdArg(1, target, sizeof(target));

			decl String:target_name[MAX_TARGET_LENGTH];
			decl bool:tn_is_ml;

			target_count = ProcessTargetString(
					target,
					client,
					target_list,
					sizeof(target_list),
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml
			);
			
			ReplyToCommand(client, "\x04[SM] Command executed on target %s...", target);
		}
		else {
			ReplyToCommand(client, "\x04[SM] Access denied");
			return Plugin_Handled;
		}
	}
	
	if (target_count <= 0) {
		ReplyToCommand(client, "\x04[SM] Error: no valid targets found");
		return Plugin_Handled;
	}
	
	decl String:URL[256];

	for (new i=0; i<target_count; ++i) {
				
		PrintToChatAll("Debug: name: %s", Vservername);
		
		Format(URL, sizeof(URL), "ventrilo://%s/servername=%s&serverpassword=%s&channelname=%s", Vaddress, Vservername, Vpassword, Vchannel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Ventrilo server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
	}
	
	return Plugin_Handled;
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/

GenerateValidTeamspeakNickName(client, String:buffer[], size) {
	if (size == 0) {
		return;
	}

	decl String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName));
	
	new n=0;
	new buf_pos = 0;
	while (clientName[n] != '\0') {
		new x = 0;
		new invalid = false;
		while (DisAllowedClientNameChars[x] != '\0') {
			if (clientName[n] == DisAllowedClientNameChars[x]) {
				invalid = true;
				break;
			}
			
			++x;
		}
		
		if (!invalid) {
			buffer[buf_pos] = clientName[n];
			buf_pos++;
			
			if (buf_pos == size) {
				break;
			}
		}
		
		++n;
	}
	
	buffer[buf_pos] = '\0';
}


ReadConfig() {
	decl String:path[PLATFORM_MAX_PATH];

	new Handle:kv = CreateKeyValues("Teamspeakserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/teamspeak.cfg");
	FileToKeyValues(kv, path);

	KvGetString(kv, "address", address, sizeof(address));
	KvGetString(kv, "password", password, sizeof(password));
	KvGetString(kv, "channel", channel, sizeof(channel));
	KvGetString(kv, "DisAllowedClientNameChars", DisAllowedClientNameChars, sizeof(DisAllowedClientNameChars));
	
	CloseHandle(kv);
	
	new Handle:kv2 = CreateKeyValues("Ventriloserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/ventrilo.cfg");
	FileToKeyValues(kv2, path);

	KvGetString(kv2, "Vaddress", Vaddress, sizeof(Vaddress));
	KvGetString(kv2, "Vpassword", Vpassword, sizeof(Vpassword));
	KvGetString(kv2, "Vservername", Vservername, sizeof(Vservername));
	KvGetString(kv2, "Vchannel", Vchannel, sizeof(Vchannel));
	
	CloseHandle(kv2);

	return true;

}
