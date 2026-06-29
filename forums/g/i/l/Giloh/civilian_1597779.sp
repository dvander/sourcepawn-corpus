#include <TF2_stocks>
#define VERSION "1.0"

public Plugin:myinfo = {
	name = "Civilian forcer",
	author = "Giloh",
	description = "Forces targetted player to become a civilian",
	version = VERSION,
	url = "null"
};

public OnPluginStart(){
	LoadTranslations("common.phrases");
	CreateConVar("sm_fakeitem_version", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_civilian", Command_Civilian, "Usage: sm_civilian <target>");
}

public Action:Command_Civilian(client, args){
	if(args > 1){
		PrintToChat(client, "\x04[SM] \x01Usage: sm_civilian <target>");
	} else if(args == 0){
		TF2_RemoveAllWeapons(client);
		ShowActivity2(client, "\x04[SM] ", "\x01\"%N\" made themself a civilian", client);
	} else {
		new String:target[MAX_TARGET_LENGTH]; GetCmdArg(1, target, MAX_TARGET_LENGTH);
		new String:targetName[MAX_TARGET_LENGTH], targetList[MAXPLAYERS] = 0;
		new bool:tn_is_ml;
		new targetCount = ProcessTargetString(target, client, targetList, MAXPLAYERS, COMMAND_FILTER_ALIVE, targetName, sizeof(targetName), tn_is_ml);
		if(targetCount <= 0){
			ReplyToTargetError(client, targetCount);
			return Plugin_Handled;
		}
	
		for(new i = 0; i < targetCount; i++){
			TF2_RemoveAllWeapons(targetList[i]);
			ShowActivity2(client, "\x04[SM] ", "\x01\"%N\" made \"%N\" a civilian", client, targetList[i]);
		}
	}
	
	return Plugin_Handled;
}