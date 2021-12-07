#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2_stocks>
#include <tf2>

#pragma semicolon 1
#pragma tabsize 0

public Plugin myinfo = {
	name        = "[TF2] Chat Management",
	author      = "TheUnderTaker",
	description = "Admins can control chats, they can turn it, and off it(Dead, Red, Blue, Spectator).",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/theundertaker007/"
};

bool:Chat = true;
bool:SpecChat = true;
bool:DeadChat = true;
bool:RedChat = true;
bool:BlueChat = true;

public OnPluginStart()
{
	/* Root */
	RegAdminCmd("sm_pchat", PublicChat, ADMFLAG_ROOT);
	
	/* Generic Admins + */
	RegAdminCmd("sm_specchat", SpectatorsChat, ADMFLAG_GENERIC);
	RegAdminCmd("sm_deadchat", DeadsChat, ADMFLAG_GENERIC);
	RegAdminCmd("sm_redchat", RedsChat, ADMFLAG_GENERIC);
	RegAdminCmd("sm_bluechat", BluesChat, ADMFLAG_GENERIC);
	
	/* Command Listeners */
	AddCommandListener(OnSay, "say_team");
	AddCommandListener(OnSay, "say");
}

public OnMapStart()
{
	Chat = true;
	SpecChat = true;
	DeadChat = true;
	RedChat = true;
	BlueChat = true;
}

public Action:PublicChat(client, args)
{
	if(!Chat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Public chat ON.");
	return Plugin_Handled;
	}
	else if(Chat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Public chat OFF!", client);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			CPrintToChat(i, "{valve}%N{default}: Your chat now blocked.", client);
		}
	}
	Chat = false;
	}
	
	return Plugin_Handled;
}

public Action:SpectatorsChat(client, args)
{
	if(!SpecChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Spectator's chat ON.");
	return Plugin_Handled;
	}
	else if(SpecChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Spectator's chat OFF!", client);
	for(int n = 1; n <= MaxClients; n++)
	{
		if(IsClientInGame(n) && TF2_GetClientTeam(n) == TFTeam_Spectator)
		{
			CPrintToChat(n, "{valve}%N{default}: You can see now only Spectator's messages, Players that aren't Spectator won't Spectator's messages.", client);
		}
	}
	SpecChat = false;
	}
	
	return Plugin_Handled;
}

public Action:DeadsChat(client, args)
{
	if(!DeadChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Dead's chat ON.");
	return Plugin_Handled;
	}
	else if(DeadChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Dead's chat OFF!", client);
	for(int d = 1; d <= MaxClients; d++)
	{
		if(IsClientInGame(d) && !IsPlayerAlive(d))
		{
			CPrintToChat(d, "{valve}%N{default}: You can see now only Dead's messages, Players that aren't Dead won't Dead's messages.", client);
		}
	}
	DeadChat = false;
	}
	
	return Plugin_Handled;
}

public Action:RedsChat(client, args)
{
	if(!RedChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Red's chat ON.");
	return Plugin_Handled;
	}
	else if(RedChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Red's chat OFF!", client);
	for(int r = 1; r <= MaxClients; r++)
	{
		if(IsClientInGame(r) && TF2_GetClientTeam(r) == TFTeam_Red)
		{
			CPrintToChat(r, "{valve}%N{default}: You can see now only Red's messages, Players that aren't Red won't Red's messages.", client);
		}
	}
	RedChat = false;
	}
	
	return Plugin_Handled;
}

public Action:BluesChat(client, args)
{
	if(!BlueChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Blue's chat ON.");
	return Plugin_Handled;
	}
	else if(BlueChat)
	{
	CPrintToChatAll("{valve}%N{default}: Turned Blue's chat OFF!", client);
	for(int b = 1; b <= MaxClients; b++)
	{
		if(IsClientInGame(b) && TF2_GetClientTeam(b) == TFTeam_Red)
		{
			CPrintToChat(b, "{valve}%N{default}: You can see now only Blue's messages, Players that aren't Blue won't Blue's messages.", client);
		}
	}
	RedChat = false;
	}
	
	return Plugin_Handled;
}

public Action:OnSay(client, const String:command[], args)
{
	if(!Chat)
	{
	return Plugin_Handled;
	}
	if(!SpecChat)
	{
	for(int s = 1; s <= MaxClients; s++)
	{
	if(IsClientInGame(s) && TF2_GetClientTeam(s) == TFTeam_Spectator)
	{
			char text[512];
			GetCmdArgString(text, sizeof(text));
			StripQuotes(text);
			CPrintToChatEx(s, client, "{teamcolor}%N{default} : %s", client, text);
	}
	}
	}
	if(!DeadChat)
	{
	for(int d = 1; d <= MaxClients; d++)
	{
	if(IsClientInGame(d) && !IsPlayerAlive(d))
	{
			char text[512];
			GetCmdArgString(text, sizeof(text));
			StripQuotes(text);
			CPrintToChatEx(d, client, "{teamcolor}%N{default} : %s", client, text);
	}
	}
	}
	if(!RedChat)
	{
	for(int r = 1; r <= MaxClients; r++)
	{
	if(IsClientInGame(r) && TF2_GetClientTeam(r) == TFTeam_Red)
	{
			char text[512];
			GetCmdArgString(text, sizeof(text));
			StripQuotes(text);
			CPrintToChatEx(r, client, "{teamcolor}%N{default} : %s", client, text);
	}
	}
	}
	if(!BlueChat)
	{
	for(int b = 1; b <= MaxClients; b++)
	{
	if(IsClientInGame(b) && TF2_GetClientTeam(b) == TFTeam_Blue)
	{
			char text[512];
			GetCmdArgString(text, sizeof(text));
			StripQuotes(text);
			CPrintToChatEx(b, client, "{teamcolor}%N{default} : %s", client, text);
	}
	}
	}
	
	return Plugin_Continue;
}