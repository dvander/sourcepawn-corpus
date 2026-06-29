#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
	name = "Hug",
	author = "The Count",
	description = "",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071/"
}

new info[MAXPLAYERS + 1][2];// [0] = Hug Allow, [1] = Last Hugged Player

public OnPluginStart(){
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_hug", Command_Hug, "Hug a player.");
}

public Action:Command_Hug (client, args){
	if(args != 1){
		ReplyToCommand(client, "[SM] Usage: sm_hug [PLAYER]");
		return Plugin_Handled;
	}
	new String:user[MAX_NAME_LENGTH];
	GetCmdArg(1, user, sizeof(user));
	new targ = FindTarget(client, user, false, false);
	if(targ == -1){
		return Plugin_Handled;
	}
	if(targ == client){
		ReplyToCommand(client, "[SM] You can't hug yourself, silly.");
		return Plugin_Handled;
	}
	if(info[client][0] == 1){
		ReplyToCommand(client, "[SM] You can only hug 1 person every 10 seconds.");
		return Plugin_Handled;
	}
	new String:username[MAX_NAME_LENGTH], String:username2[MAX_NAME_LENGTH];
	GetClientName(client, username, sizeof(username));
	GetClientName(targ, username2, sizeof(username2));
	if(info[targ][1] == client){
		PrintToChatAll("\x07FF69B4%s hugged %s back.", username, username2);
	}else{
		PrintToChatAll("\x07FF69B4%s hugged %s.", username, username2);
	}
	info[client][1] = targ;
	info[client][0] = 1;
	CreateTimer(35.0, Timer_HugBack, client);
	CreateTimer(10.0, Timer_Hug, client);
	return Plugin_Handled;
}

public Action:Timer_HugBack(Handle:timer, any:client){
	info[client][1] = 0;
	return Plugin_Stop;
}

public Action:Timer_Hug(Handle:timer, any:client){
	info[client][0] = 0;
	return Plugin_Stop;
}