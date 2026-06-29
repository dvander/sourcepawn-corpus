#include <sourcemod>

#define VERSION "1.0"

new userFlood[64];
new String:serverLangName[4];
new String:langCode[4];

public Plugin:myinfo =
{
	name = "Rules Menu",
	author = "graczu_-",
	description = "Showing rules to player on /say rules or on admin request (sm_rules)",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};


public OnPluginStart()
{
	LoadTranslations("rules.phrases");

	CreateConVar("menu_rules_version", VERSION, "Menu Rules Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_rules", adminRules, ADMFLAG_KICK, "sm_rules <#userid|name> - Showing Rules to a player");
	RegConsoleCmd("say", Command_Say);
	initLangMe();
}

public initLangMe(){
	new serverLang = GetServerLanguage();
	GetLanguageInfo(serverLang, langCode, sizeof(langCode), serverLangName, sizeof(serverLangName));
}

public onClientPutInServer(client)
{
	userFlood[client]=0;
}

public Action:Command_Say(client, args){

	decl String:text[192], String:command[64];

	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)

	startidx += 4;
	if(StrEqual(langCode, "pl")){
		if (strcmp(text[startidx], "/zasady", false) == 0)	{
			if(userFlood[client] != 1){
				showRules(client);
				userFlood[client]=1;
				CreateTimer(10.0, removeFlood, client);
			} else {
				PrintToChat(client,"%t", "[RULES] Dont Flood!");
			}
		}
	} else 
	if(StrEqual(langCode, "en")){
		if (strcmp(text[startidx], "/rules", false) == 0)
		{		
			if(userFlood[client] != 1){
				showRules(client);
				userFlood[client]=1;
				CreateTimer(10.0, removeFlood, client);
			} else {
				PrintToChat(client,"%t", "[RULES] Dont Flood!");
			}
		}
	}
	return Plugin_Continue;
}

public Action:removeFlood(Handle:timer, any:client){
	userFlood[client]=0;
}


public Action:adminRules(client, args){
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rules <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[64];
	GetCmdArg(1, arg, sizeof(arg));

	new target = FindTarget(client, arg);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	GetClientName(target, arg, sizeof(arg));

	PrintToChatAll("%t", "[RULES] Rules Action", arg);
	if ( !IsFakeClient(target) )
	{
		if(IsClientInGame(target)){
			showRules(target);
		}
	}
	return Plugin_Handled;
}


public showRules(any:client){

	new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	new String:text[128];
	Format(text,127, "%t", "Server Rules Menu Title");
	SetPanelTitle(Panel,text);



	new Handle:hFile = OpenFile("addons/sourcemod/configs/rules_data.ini", "rt");
	new String:szReadData[128];
	if(hFile == INVALID_HANDLE)
	{
		return;
	}
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		DrawPanelText(Panel, szReadData);
	}

	DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

	Format(text,59, "%t", "Exit Rules Menu")
	DrawPanelItem(Panel, text)
		
	SendPanelToClient(Panel, client, RlzMenu, 20);

	CloseHandle(Panel);

}

public RlzMenu(Handle:menu, MenuAction:action, param1, param2)
{
}
