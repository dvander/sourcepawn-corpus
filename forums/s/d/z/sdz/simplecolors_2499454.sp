#include <sourcemod>
#include <morecolors>
#include <basecomm>

new Handle:g_hCVAR_NameColor = INVALID_HANDLE;
new Handle:g_hCVAR_ChatColor = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Chat Color", 
	author = "Realization Software (Sidezz)", 
	description = "Enable the coloring of chat", 
	version = "1.0",
	url = "www.coldcommunity.com"
}

public OnPluginStart()
{
	g_hCVAR_NameColor = CreateConVar("sm_namecolor", "cyan", "The HTML-Safe Color Name you'd like to use for names in chat", FCVAR_NOTIFY);
	g_hCVAR_ChatColor = CreateConVar("sm_chatcolor", "green", "The HTML-Safe Color Name you'd like to use for text in chat", FCVAR_NOTIFY);

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

	AutoExecConfig();
}

public Action Listener_Say(client, const String:command[], argc)
{
	decl String:chat[256], String:clientName[MAX_NAME_LENGTH];
	decl String:cvar_NameColor[32], String:cvar_TextColor[32];

	GetCmdArgString(chat, sizeof(chat));
	GetClientName(client, clientName, sizeof(clientName));

	GetConVarString(g_hCVAR_ChatColor, cvar_TextColor, sizeof(cvar_TextColor));
	GetConVarString(g_hCVAR_NameColor, cvar_NameColor, sizeof(cvar_NameColor));

	TrimString(chat);
	StripQuotes(chat);

	//If Server Console:
	if(client == 0) return Plugin_Continue;

	//If Chat Command:
	if(StrContains(chat, "/", false) == 0) return Plugin_Handled;


	if(!BaseComm_IsClientGagged(client))
	{
		//All chat
		if(StrEqual(command, "say", false))
		{
			CPrintToChatAll("{%s}%s {default}:  {%s}%s", cvar_NameColor, clientName, cvar_TextColor, chat);
			return Plugin_Handled;
		}

		//Team chat
		if(StrEqual(command, "say_team", false))
		{
			int team = GetClientTeam(client);
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					if(GetClientTeam(i) == team)
					{
						CPrintToChat(i, "(TEAM) {%s}%s {default}:  {%s}%s", cvar_NameColor, clientName, cvar_TextColor, chat);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	else return Plugin_Handled;
	return Plugin_Continue;
}