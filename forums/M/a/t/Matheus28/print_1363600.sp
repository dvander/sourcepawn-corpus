#include <sourcemod>
#include <colors>
public Plugin:myinfo = 
{
	name = "Print",
	author = "Matheus28",
	description = "",
	version = "1.1",
	url = ""
}

public OnPluginStart(){
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_print", Cmd_Print, ADMFLAG_CHAT, "Prints something with formatting");
	RegAdminCmd("sm_print_c", Cmd_PrintC, ADMFLAG_CHAT, "Prints something to a client with formatting");
}

public Action:Cmd_Print(client, args){
	if(args<1){
		ReplyToCommand(client, "[SM] Usage: sm_print <text>");
		return Plugin_Handled;
	}
	decl String:str[512];
	GetCmdArgString(str, sizeof(str));
	CPrintToChatAll(str);
	return Plugin_Handled;
}

public Action:Cmd_PrintC(client, args){
	if(args<2){
		ReplyToCommand(client, "[SM] Usage: sm_print_c <target> <text>");
		return Plugin_Handled;
	}
	
	decl String:tName[MAX_NAME_LENGTH];
	GetCmdArg(1, tName, sizeof(tName));
	new target=FindTarget(client, tName, false, false);
	
	if(target==-1) return Plugin_Handled;
	if(IsFakeClient(target)) return Plugin_Handled
	
	decl String:str[512];
	decl String:tmp[512];
	
	GetCmdArg(2, str, sizeof(str));
	for(new i=3;i<=args;++i){
		GetCmdArg(i, tmp, sizeof(tmp));
		Format(str, sizeof(str), "%s %s", str, tmp);
	}
	CPrintToChat(target, str);
	return Plugin_Handled;
}