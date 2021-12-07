#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix"
#define PLUGIN_VERSION "1.00"
#define Prefix	"\x3 \x4[POKE] \x1"

#include <sourcemod>

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "CS:GO Poke",
	author = PLUGIN_AUTHOR,
	description = "Poke other players",
	version = PLUGIN_VERSION,
	url = "http://www.google.com"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	RegAdminCmd("sm_poke", CMD_Poke, ADMFLAG_BAN);
}


public Action CMD_Poke(int client, int args) {
	
	if(args < 2) {
		PrintToChat(client, "%s!poke [username] [message]", Prefix);
		return Plugin_Handled;
	}
	
	//Getting username to poke
	char user[MAX_NAME_LENGTH];
	GetCmdArg(1, user, sizeof(user));
	
	//Find users
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS]; 
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			user,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		PrintToChat(client, "%sPlayer not found!", Prefix);
		return Plugin_Handled;
	}
	
	char Message[512];
	GetCmdArgString(Message, sizeof(Message));
	
	char username[MAX_NAME_LENGTH];
	GetClientName(client, username, sizeof(username));
	
	ReplaceString(Message, sizeof(Message), user, "");
	
	char MessageStart[512];
	Format(MessageStart, sizeof(MessageStart), "<b>%s:</b> ", username);
	StrCat(MessageStart, sizeof(MessageStart), Message);
	
	for (new i = 0; i < target_count; i++)
	{

		if(IsClientInGame(target_list[i]) && !IsFakeClient(target_list[i])) {
			char url[512];
			Format(url, sizeof(url), "http://csgo.lol/csgo/poke/redirect.php?url=http://csgo.lol/csgo/poke/index.php?t=%s", MessageStart);
			ShowMOTDPanel(target_list[i], "", url, MOTDPANEL_TYPE_URL);
		}

	}
	
	PrintToChat(client, "%s%s successfully poked", Prefix, username);

	return Plugin_Handled;

}