#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name = "AddCond",
	author = "The Count",
	description = "Add any TF2 condition to yourself.",
	version = "1",
	url = "http://steamcommunity.com/profiles/76561197983205071"
}

new Handle:timeCvar = INVALID_HANDLE;

public OnPluginStart(){
	RegConsoleCmd("sm_addcond", Cmd_AddCond, "Add a condition to yourself.");
	timeCvar = CreateConVar("sm_addcond_duration", "0.0");
}

public Action:Cmd_AddCond(client, args){
	if(!IsPlayerAlive(client)){
		ReplyToCommand(client, "[SM] Must be alive to add a condition.");
		return Plugin_Handled;
	}
	if(args != 1){
		ReplyToCommand(client, "[SM] Usage: !addcond [NUMBER]");
		return Plugin_Handled;
	}
	new String:arg1[MAX_NAME_LENGTH], Float:time = GetConVarFloat(timeCvar);
	GetCmdArg(1, arg1, sizeof(arg1));
	if(StringToInt(arg1) <= 0){
		ReplyToCommand(client, "[SM] Invalid integer.");
		return Plugin_Handled;
	}
	if(time <= 0.0){//If time not specified or applicable.
		time = TFCondDuration_Infinite;
	}
	TF2_AddCondition(client, StringToInt(arg1), time);//Tag mismatch here because it expects an enum instead of number, but they can both be used.
	PrintToChat(client, "\x04Condition added.");
	return Plugin_Handled;
}