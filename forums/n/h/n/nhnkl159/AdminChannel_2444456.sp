#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "nhnkl159"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <colors>

public Plugin myinfo = 
{
	name = "[CS:GO] AdminChannel",
	author = PLUGIN_AUTHOR,
	description = "none",
	version = PLUGIN_VERSION,
	url = "none"
};

bool IsInChannel[MAXPLAYERS + 1] =  { false, ... };

public void OnPluginStart()
{
	RegAdminCmd("sm_adminchannel", Cmd_AdminChannel, ADMFLAG_BAN);
	RegAdminCmd("sm_ac", Cmd_AdminChannel, ADMFLAG_BAN);
}

public void OnMapStart()
{
	for(int i = 0; i < MaxClients; i++)
	{
		if(IsFuckingValidClient(i))
		{
			IsInChannel[i] = false;
		}
	}
}

public Action Cmd_AdminChannel(int client, int args)
{
	if(!IsFuckingValidClient(client))
	{
		return Plugin_Handled;
	}
	
	ShowMenu(client);
	
	return Plugin_Handled;
}

void ShowMenu(int client)
{
	char ChannelFormat[258];
	Format(ChannelFormat, sizeof(ChannelFormat), "Admin Channel : [%s]", IsInChannel[client] ? "X":"");
	Menu menu = new Menu(AdminMenuHandler);
	menu.SetTitle("Admin channel status :");
	menu.AddItem("", ChannelFormat);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int AdminMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select)
	{
		if(IsInChannel[client] == true)
		{
			SetClientVoice(client, false);
			CPrintToChat(client, "\x05[AdminChannel]\x01 You \x07quit\x01 the admin channel , you can now hear all the players !");
			IsInChannel[client] = false;
		}
		else
		{
			SetClientVoice(client, true);
			CPrintToChat(client, "\x05[AdminChannel]\x01 You \x07entered\x01 the admin channel , you can now hear all the admins who is in the channel !");
			IsInChannel[client] = true;
		}
		ShowMenu(client);
	}
	if(action == MenuAction_Cancel)
	{
		delete menu;
	}
}

stock int SetClientVoice(int client, bool boolean)
{
	if(boolean)
	{
		for(int i = 0; i < MaxClients; i++)
		{
			if(IsInChannel[i] == true && IsFuckingValidClient(i))
			{
				SetListenOverride(i, client, Listen_Yes);
				SetListenOverride(client, i, Listen_Yes);
			}
		}
		
		for(int i = 0; i < MaxClients; i++)
		{
			if(IsInChannel[i] != true && IsFuckingValidClient(i))
			{
				SetListenOverride(i, client, Listen_No);
				SetListenOverride(client, i, Listen_No);
			}
		}
	}
	else
	{
		for(int i = 0; i < MaxClients; i++)
		{
			if(IsInChannel[i] == true && IsFuckingValidClient(i))
			{
				SetListenOverride(i, client, Listen_No);
				SetListenOverride(client, i, Listen_No);
			}
		}
		
		for(int i = 0; i < MaxClients; i++)
		{
			if(IsInChannel[i] != true && IsFuckingValidClient(i))
			{
				SetListenOverride(i, client, Listen_Yes);
				SetListenOverride(client, i, Listen_Yes);
			}
		}
	}
}


stock bool IsFuckingValidClient(int client, bool alive = false, bool bots = false)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)))
	{
		return true;
	}
	return false;
}