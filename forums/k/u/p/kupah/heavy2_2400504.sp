#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

char model[256] = "models/player/custom_player/legacy/tm_phoenix_heavy.mdl";

public Plugin myinfo = {
	name = "CS:GO Player armor skin",
	author = "kupah",
	description = "Give player armor and skin",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=280015"
};

public void OnPluginStart() { 
    RegAdminCmd("sm_heavy", cmd_heavy, ADMFLAG_RESERVATION);
} 

public void OnMapStart() {
	PrecacheModel(model, true);
}

public Action cmd_heavy(int client, int args) {
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_heavy <target>");
		return Plugin_Handled;
	}
	char arg[MAX_NAME_LENGTH];
	char target_name[MAX_TARGET_LENGTH];
	int target[MAXPLAYERS];
	bool tn_is_ml;
	
	GetCmdArg(1, arg, sizeof(arg));
	int get_target = ProcessTargetString(arg, client, target, sizeof(target), COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml); 
	
	if(get_target <= 0) { 
		ReplyToTargetError(client, get_target); 
		return Plugin_Handled;
	}
	for(int i = 0; i < get_target; i++) {
		SetEntityModel(target[i], model);
		GivePlayerItem(target[i], "item_assaultsuit");
		
		PrintToChat(client, "You have give armor to %N", target[i]);
		PrintToChat(client, "%N give you armor", client);
	}
	return Plugin_Handled;
}