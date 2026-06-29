#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL	0	/**< Allow the client to listen and speak normally. */
#define VOICE_MUTED		1	/**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL	2	/**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL	4	/**< Allow the client to listen to everyone. */
#define VOICE_TEAM		8	/**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM	16	/**< Allow the client to always hear teammates, including dead ones. */

#define TEAM_SPEC 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

new Handle:hAllTalk;


#define PLUGIN_VERSION "2.1.3"
public Plugin:myinfo = 
{
	name = "SpecLister",
	author = "waertf & bear modded by bman",
	description = "Allows spectator listen others team voice for l4d",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=95474"
}


 public OnPluginStart()
{
	HookEvent("player_team",Event_PlayerChangeTeam);
	RegConsoleCmd("hear", Panel_hear);
	
	//Fix for End of round all-talk.
	hAllTalk = FindConVar("sv_alltalk");
	HookConVarChange(hAllTalk, OnAlltalkChange);
	
	//Spectators hear Team_Chat
	RegConsoleCmd("say_team", Command_SayTeam);

}
public PanelHandler1(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		PrintToConsole(param1, "You selected item: %d", param2)
		if(param2==1)
			{
			SetClientListeningFlags(param1, VOICE_LISTENALL);
			PrintToChat(param1,"\x04[Listen Mode]\x03Enabled" );
			}
		else
			{
			SetClientListeningFlags(param1, VOICE_NORMAL);
			PrintToChat(param1,"\x04[Listen Mode]\x03Disabled" );
			}
		
	} else if (action == MenuAction_Cancel) {
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
}


public Action:Panel_hear(client,args)
{
	if(GetClientTeam(client)!=TEAM_SPEC)
		return Plugin_Handled;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Enable listen mode ?");
	DrawPanelItem(panel, "Yes");
	DrawPanelItem(panel, "No");
 
	SendPanelToClient(panel, client, PanelHandler1, 20);
 
	CloseHandle(panel);
 
	return Plugin_Handled;

}

public Action:Command_SayTeam(client, args)
{
	if (client == 0)
		return Plugin_Continue;
		
	new String:buffermsg[256];
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	new senderteam = GetClientTeam(client);
	
	if(FindCharInString(text, '@') == 0)	//Check for admin messages
		return Plugin_Continue;
	
	new startidx = trim_quotes(text);  //Not sure why this function is needed.(bman)
	
	new String:name[32];
	GetClientName(client,name,31);
	
	new String:senderTeamName[10];
	switch (senderteam)
	{
		case 3:
			senderTeamName = "INFECTED"
		case 2:
			senderTeamName = "SURVIVORS"
		case 1:
			senderTeamName = "SPEC"
	}
	
	//Is not console, Sender is not on Spectators, and there are players on the spectator team
	if (client > 0 && senderteam != TEAM_SPEC && GetTeamClientCount(TEAM_SPEC) > 0)
	{
		for (new i = 1; i <= GetMaxClients(); i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == TEAM_SPEC)
			{
				switch (senderteam)	//Format the color different depending on team
				{
					case 3:
						Format(buffermsg, 256, "\x01(%s) \x04%s\x05: %s", senderTeamName, name, text[startidx]);
					case 2:
						Format(buffermsg, 256, "\x01(%s) \x03%s\x05: %s", senderTeamName, name, text[startidx]);
				}
				//Format(buffermsg, 256, "\x01(TEAM-%s) \x03%s\x05: %s", senderTeamName, name, text[startidx]);
				SayText2(i, client, buffermsg);	//Send the message to spectators
			}
		}
	}
	return Plugin_Continue;
}

stock SayText2(client_index, author_index, const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index)
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index)
        BfWriteByte(buffer, true)
        BfWriteString(buffer, message)
        EndMessage()
    }
} 

public trim_quotes(String:text[])
{
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	return startidx
}

public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userID = GetClientOfUserId(GetEventInt(event, "userid"));
	new userTeam = GetEventInt(event, "team");
	if(userID==0)
		return ;

	//PrintToChat(userID,"\x02X02 \x03X03 \x04X04 \x05X05 ");\\ \x02:color:default \x03:lightgreen \x04:orange \x05:darkgreen
	
	if(userTeam==TEAM_SPEC && IsValidClient(userID))
	{
		SetClientListeningFlags(userID, VOICE_LISTENALL);
		//PrintToChat(userID,"\x04[Listen Mode]\x03Enabled" )
		
	}
	else
	{
		SetClientListeningFlags(userID, VOICE_NORMAL);
		//PrintToChat(userID,"\x04[listen]\x03disable" )
	}
}

public OnAlltalkChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == TEAM_SPEC)
			{
				SetClientListeningFlags(i, VOICE_LISTENALL);
				//PrintToChat(i,"Re-Enable Listen Because of All-Talk");
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if (!IsFakeClient(client) && GetClientTeam(client) != 1)	//Make the choose team menu display when someone quits
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == 1)
			{
				ClientCommand(i, "chooseteam");
			}
		}
	}
}

public IsValidClient (client)
{
    if (client == 0)
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    if (IsFakeClient(client))
        return false;
    
    if (!IsClientInGame(client))
        return false;	
		
    return true;
}  