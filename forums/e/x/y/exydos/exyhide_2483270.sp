
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <regex>

/*
	exydos.com
	2017.01.03 initial
*/

public Plugin:myinfo = {
	name = "eXyHide",
	author = "eXydos",
	description = "Hides People?",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?p=2483270"
};

new Handle:g_Regex = INVALID_HANDLE;
new Handle:g_Menu = INVALID_HANDLE;
new Handle:g_Cookie = INVALID_HANDLE;
new g_Setting[MAXPLAYERS+1] = {0,...};
/*new g_Team[MAXPLAYERS+1] = {0,...};*/

public void OnPluginStart(){
	g_Cookie = RegClientCookie("ExyHide", "ExyHide", CookieAccess_Protected);

	g_Menu = CreateMenu(OnMenu);
	AddMenuItem(g_Menu, "0", "!hide off");
	AddMenuItem(g_Menu, "2", "!hide team");
	AddMenuItem(g_Menu, "4", "!hide enemy");
	AddMenuItem(g_Menu, "9", "!hide all");

	for (new client=1; client<=MaxClients; client++){
		if (IsClientInGame(client)){
			OnClientPutInServer(client);
			if (AreClientCookiesCached(client)){
				OnClientCookiesCached(client);
			}
		}
	}

	g_Regex = CompileRegex("[\"'!@/]+(hide)\\s*([^\"' ]*)" /*"*/, PCRE_CASELESS);
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");

	/*HookEvent("player_team", OnTeamChange, EventHookMode_Post);*/
}

void OnPluginEnd(){
	CloseHandle(g_Cookie);
	CloseHandle(g_Menu);
	CloseHandle(g_Regex);
}

public OnClientPutInServer(client){
	g_Setting[client] = 0;
	/*g_Team[client] = GetClientTeam(client);*/
	SDKHook(client, SDKHook_SetTransmit, OnTransmit);
}

public OnClientCookiesCached(int client){
	char sCookieValue[12];
	GetClientCookie(client, g_Cookie, sCookieValue, sizeof(sCookieValue));
	g_Setting[client] = StringToInt(sCookieValue);
}

public OnMenu(Handle:menu, MenuAction:action, client, param2){
	if (action == MenuAction_Select){
		decl String:sMenuValue[12];
		GetMenuItem(menu, param2, sMenuValue, sizeof(sMenuValue));
		g_Setting[client] = StringToInt(sMenuValue);
	}
}

public Action:OnTransmit(entity, client){
	if (
		entity != client
		&&
		entity > 0
		&&
		entity <= MaxClients
		&&
		g_Setting[client] != 0
	){
		if (g_Setting[client] == 9){
			return Plugin_Handled;
		} else if (g_Setting[client] == 2){
			if (GetClientTeam(client) == GetClientTeam(entity))
			/*if (g_Team[client] == g_Team[entity])*/
				return Plugin_Handled;
		} else if (g_Setting[client] == 4){
			if (GetClientTeam(client) != GetClientTeam(entity))
			/*if (g_Team[client] != g_Team[entity])*/
				return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:OnSay(client, const String:command[], argc){
	if (client > 0 && client <= MaxClients){
		decl String:chatpri[64];
		decl String:chatsec[64];
		if (
			GetCmdArgString(chatpri, sizeof(chatpri))
			&&
			MatchRegex(g_Regex, chatpri) >= 1
			&&
			GetRegexSubString(g_Regex, 2, chatsec, sizeof(chatsec))
		){
			if (0 == strcmp(chatsec, "off")){
				g_Setting[client] = 0;
				SetClientCookie(client, g_Cookie, "0");
			} else if (0 == strcmp(chatsec, "team")){
				g_Setting[client] = 2;
				SetClientCookie(client, g_Cookie, "2");
			} else if (0 == strcmp(chatsec, "enemy")){
				g_Setting[client] = 4;
				SetClientCookie(client, g_Cookie, "4");
			} else if (0 == strcmp(chatsec, "all")){
				g_Setting[client] = 9;
				SetClientCookie(client, g_Cookie, "9");
			} else {
				DisplayMenu(g_Menu, client, 30);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/*public OnTeamChange(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client <= MaxClients){
		g_Team[client] = GetClientTeam(client);
	}
}*/

