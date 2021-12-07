// enforce semicolons after each code statement
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.2"


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/

public Plugin:myinfo = {
	name = "Mumble Joiner",
	author = "Nightbox",
	description = "Allows players to join mumble server",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=858659"
}



/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/

// Mumble
new String:mumble_address[256];
new String:mumble_password[64];
new String:mumble_channel[128];




/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/

public OnPluginStart() {
	
	// ConVars
	mumble_version = CreateConVar("mumble_version", PLUGIN_VERSION, "Mumble join plugin version", FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated...
	SetConVarString(mumble_version, PLUGIN_VERSION);
	

	RegConsoleCmd("sm_mumble", Command_Teamspeak, "Allows users to join the mumble server");

}

public OnConfigsExecuted() {
	ReadConfig_mumble();
}



/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/

public Action:Command_Mumble(client, args) {
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
		
		Format(URL, sizeof(URL), "mumble://%s/%s:%s@%s", mumble_address, nickName, mumble_password, mumble_channel);
		
		ReplyToCommand(target_list[i], "\x04[SM] Trying to join Teamspeak server...");
		ShowMOTDPanel(target_list[i], "", URL, MOTDPANEL_TYPE_URL);
		ShowVGUIPanel(target_list[i], "info", INVALID_HANDLE, false);
		
		if (GetConVarBool(ts_printjoins)) {
			PrintToChatAll("\x04[SM] Player %N is joining the mumble server !", target_list[i]);
		}
	}
	
	return Plugin_Handled;
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/



ReadConfig_Mumble() {
	decl String:path[PLATFORM_MAX_PATH];

	new Handle:kv = CreateKeyValues("mumbleserver");
	
	BuildPath(Path_SM, path, sizeof(path), "configs/voiceserver/mumble.cfg");
	FileToKeyValues(kv, path);

	KvGetString(kv, "address", mumble_address, sizeof(teamspeak_address));
	KvGetString(kv, "password", mumble_password, sizeof(teamspeak_password));
	KvGetString(kv, "channel", mumble_channel, sizeof(teamspeak_channel));
	
	CloseHandle(kv);

	return true;

}



