#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Teleport Position",
	author = "The Count",
	description = "Allows admins (or regular players if set) to teleport to an X Z Y location.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new bool:allowAll = false;
new String:KvPath[PLATFORM_MAX_PATH];

public OnPluginStart(){
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_tpos", TPos, "Teleport to X Z Y.");
	RegAdminCmd("sm_toggle", Toggle, ADMFLAG_SLAY, "Allows an admin to toggle teleport position allowability.");
	
	CreateDirectory("addons/sourcemod/data/TeleportPosition", 3);
	BuildPath(Path_SM, KvPath, sizeof(KvPath), "data/TeleportPosition/config.cfg");
	new Handle:DB = CreateKeyValues("Data Configurable");
	FileToKeyValues(DB, KvPath);
	if(KvJumpToKey(DB, "Data", true)){
		new String:temp[10];
		KvGetString(DB, "Allow All", temp, sizeof(temp), "false");
		KvSetString(DB, "Allow All", temp);
		if(strcmp(temp, "true", false) == 0){
			allowAll = true;
		}
	}
	KvRewind(DB);
	KeyValuesToFile(DB, KvPath);
	CloseHandle(DB);
}

public Action:Toggle(client, args){
	if(allowAll == false){
		allowAll = true;
		new Handle:DB = CreateKeyValues("Data Configurable");
		FileToKeyValues(DB, KvPath);
		if(KvJumpToKey(DB, "Data", true)){
			KvSetString(DB, "Allow All", "true");
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KvPath);
		CloseHandle(DB);
		PrintToChatAll("\x01 [SM]\x04 Teleport Position enabled for everyone.");
	}else{
		allowAll = false;
		new Handle:DB = CreateKeyValues("Data Configurable");
		FileToKeyValues(DB, KvPath);
		if(KvJumpToKey(DB, "Data", true)){
			KvSetString(DB, "Allow All", "false");
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KvPath);
		CloseHandle(DB);
		PrintToChatAll("\x01 [SM]\x04 Teleport Position disabled for non-admins.");
	}
	return Plugin_Handled;
}

public Action:TPos (client, args){
	if(args < 3 || args > 4){
		ReplyToCommand(client, "[SM] Usage: sm_tpos <Client/Optional> <X Value> <Z Value> <Y Value>");
		return Plugin_Handled;
	}
	new String:arg[32], Float:pos[3];
	for(new i=1;i<=3;i++){
		if(args == 4){
			GetCmdArg(i + 1, arg, sizeof(arg));
		}else{
			GetCmdArg(i, arg, sizeof(arg));
		}
		pos[i - 1] = StringToFloat(arg);
	}
	new targ = client;
	if(args == 4){
		if(GetUserAdmin(client) != INVALID_ADMIN_ID){
			GetCmdArg(1, arg, sizeof(arg));
			targ = FindTarget(client, arg, false, false);
		}else{
			ReplyToCommand(client, "[SM] Only admins are allowed to teleport specific targets.");
			return Plugin_Handled;
		}
	}
	if(allowAll == true || GetUserAdmin(client) != INVALID_ADMIN_ID){
		TeleportEntity(targ, pos, NULL_VECTOR, NULL_VECTOR);
		ClientCommand(targ, "playgamesound buttons/button18.wav");
		PrintToChat(client, "\x01 [SM]\x04 Teleported to\x04 %d, %d, %d.", RoundFloat(pos[0]), RoundFloat(pos[1]), RoundFloat(pos[2]));
	}else{
		ClientCommand(client, "playgamesound buttons/button16.wav");
		PrintToChat(client, "\x01 [SM] You are not allowed to use that command.");
	}
	return Plugin_Handled;
}