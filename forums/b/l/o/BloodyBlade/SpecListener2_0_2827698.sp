#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.1.3"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY
#define NORMAL		0	/**< Allow the client to listen and speak normally. */
#define MUTED		1	/**< Mutes the client from speaking to everyone. */
#define SPEAKALL	2	/**< Allow the client to speak to everyone. */
#define LISTENALL	4	/**< Allow the client to listen to everyone. */
#define TEAM		8	/**< Allow the client to always speak to team, even when dead. */
#define LISTENTEAM	16	/**< Allow the client to always hear teammates, including dead ones. */
#define TEAMSPEC	1

ConVar hSpecListerEnable, hAllTalk;
bool bHooked = false;

public Plugin myinfo = 
{
	name = "Spec Lister",
	author = "waertf & bear modded by bman",
	description = "Allows spectator listen others team voice for l4d",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=95474"
}

public void OnPluginStart()
{
	CreateConVar("spec_lister_version", PLUGIN_VERSION, "Spec Lister plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hSpecListerEnable = CreateConVar("spec_lister_enable", "1", "Enables this plugin.", CVAR_FLAGS, true, 0.0, true, 1.0);

	AutoExecConfig(true, "spec_lister");

	hSpecListerEnable.AddChangeHook(OnEnableChange);
	hAllTalk = FindConVar("sv_alltalk");
	hAllTalk.AddChangeHook(OnAlltalkChange);

	RegConsoleCmd("hear", Panel_hear);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnEnableChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void OnAlltalkChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StringToInt(newValue) == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSpectator(i))
			{
				SetClientListeningFlags(i, LISTENALL);
			}
		}
	}
}

void IsAllowed()
{
	bool bPluginOn = hSpecListerEnable.BoolValue;
	if(!bHooked && bPluginOn)
	{
		bHooked = true;
		AddCommandListener(Command_SayTeam, "say_team");
		HookEvent("player_team", Event_PlayerChangeTeam);
	}
	else if(bHooked && !bPluginOn)
	{
		bHooked = false;
		RemoveCommandListener(Command_SayTeam, "say_team");
		UnhookEvent("player_team", Event_PlayerChangeTeam);
	}
}

Action Panel_hear(int client, int args)
{
	if(bHooked && IsValidClient(client) && GetClientTeam(client) == TEAMSPEC)
	{
		Panel panel = new Panel();
		panel.SetTitle("Enable listen mode ?");
		panel.DrawItem("Yes");
		panel.DrawItem("No");

		panel.Send(client, PanelHandler1, 20);
		panel.Close();
	}
	return Plugin_Handled;
}

int PanelHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		PrintToConsole(param1, "You selected item: %d", param2);
		if(param2 == 1)
		{
			SetClientListeningFlags(param1, LISTENALL);
			PrintToChat(param1, "\x04[Listen Mode]\x03Enabled");
		}
		else
		{
			SetClientListeningFlags(param1, NORMAL);
			PrintToChat(param1,"\x04[Listen Mode]\x03Disabled");
		}
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	return 0;
}

Action Command_SayTeam(int client, const char[] command, int args)
{
	if (client > 0)
	{
		char buffermsg[256], text[192];
		GetCmdArgString(text, sizeof(text));
		int senderteam = GetClientTeam(client);

		if(FindCharInString(text, '@'))	//Check for admin messages
		{
			int startidx = trim_quotes(text);  //Not sure why this function is needed.(bman)

			char name[32];
			GetClientName(client, name, 31);
			
			char senderTeamName[10];
			switch (senderteam)
			{
				case 1: senderTeamName = "SPEC";
				case 2: senderTeamName = "SURVIVORS";
				case 3: senderTeamName = "INFECTED";
			}
			
			//Is not console, Sender is not on Spectators, and there are players on the spectator team
			if (client > 0 && senderteam != 1 && GetTeamClientCount(1) > 0)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && GetClientTeam(i) == TEAMSPEC)
					{
						switch (senderteam)	//Format the color different depending on team
						{
							case 3: Format(buffermsg, 256, "\x01(%s) \x04%s\x05: %s", senderTeamName, name, text[startidx]);
							case 2: Format(buffermsg, 256, "\x01(%s) \x03%s\x05: %s", senderTeamName, name, text[startidx]);
						}
						//Format(buffermsg, 256, "\x01(TEAM-%s) \x03%s\x05: %s", senderTeamName, name, text[startidx]);
						SayText2(i, client, buffermsg);	//Send the message to spectators
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void Event_PlayerChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userID = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(userID))
	{
		//PrintToChat(userID,"\x02X02 \x03X03 \x04X04 \x05X05 ");\\ \x02:color:default \x03:lightgreen \x04:orange \x05:darkgreen
		if(event.GetInt("team") == 1)
		{
			SetClientListeningFlags(userID, LISTENALL);
			//PrintToChat(userID,"\x04[Listen Mode]\x03Enabled");
			
		}
		else
		{
			SetClientListeningFlags(userID, NORMAL);
			//PrintToChat(userID,"\x04[listen]\x03disable");
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (bHooked && client > 0 && !IsFakeClient(client) && GetClientTeam(client) != TEAMSPEC)	//Make the choose team menu display when someone quits
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidSpectator(i))
			{
				ClientCommand(i, "chooseteam");
			}
		}
	}
}

stock void SayText2(int client_index, int author_index, const char[] message) 
{
    Handle buffer = StartMessageOne("SayText2", client_index);
    if (buffer != null) 
	{
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
} 

stock int trim_quotes(char[] text)
{
	int startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		int len = strlen(text);
		if (text[len - 1] == '"')
		{
			text[len - 1] = '\0';
		}
	}
	return startidx;
}

stock bool IsValidClient(int client)
{
    return client > 0 && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client);
}

stock bool IsValidSpectator(int client)
{
    return IsValidClient(client) && GetClientTeam(client) == TEAMSPEC;
}
