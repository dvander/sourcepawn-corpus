#define PLUGIN_VERSION "1.0"
#define READY_LIST_PANEL_LIFETIME 10

#include <sourcemod>
#include <sdktools>



new readyStatus[33] = {0, ...};

new Handle:roundislive = INVALID_HANDLE
new Handle:war_cfg = INVALID_HANDLE
new Handle:min_players = INVALID_HANDLE

new Handle:menuPanel = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "DoD:S Pug",
	author = "Puopjik",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://baronettes.verygames.net/"
};

 public OnPluginStart()
{

	CreateConVar("sm_dodspug_version", PLUGIN_VERSION , "Pug Mode Plugin for DOD:S version number", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	

	HookEvent("player_connect", Event_PlayerConnect)
	HookEvent("player_disconnect", Event_PlayerConnect)
	HookEvent("player_team", Event_PlayerTeam)

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegConsoleCmd("sm_drawready", readyDraw);



	roundislive = CreateConVar("pug_live", "0", "1 if the round is live, 0 otherwise.", FCVAR_DONTRECORD|FCVAR_PLUGIN)
	war_cfg = CreateConVar("pug_cfg", "pug.cfg", "Filename of the pug config", FCVAR_PLUGIN);
	min_players = CreateConVar("pug_minplayers", "12.0", "Number of player needed to start the plugin.", FCVAR_PLUGIN);





   	AutoExecConfig(true, "pug_plugin", "sourcemod")

}

public OnMapStart()
{
    for(new i =0; i<GetMaxClients()+1 ;i++) readyStatus[i] = 0;
    SetConVarBool(roundislive, false)
}


public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new user = GetClientOfUserId(userid);
	
	readyStatus[user] = 0;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new user = GetClientOfUserId(userid);
	
	new team = GetEventInt(event, "team");

	if(team < 2)
		readyStatus[user] = 0;
}



public Action:readyDraw(client, args)
{
	DrawReadyPanelList();
}

public Action:Command_Say(client, args)
{
	if (!GetConVarBool(roundislive))
	{
		decl String:text[192];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);

		if(strcmp("!ready",text)==0)
		{
			Ready(client, true)
		}
		
		if(strcmp("!unready",text)==0)
		{
			Ready(client, false)
		}
	}
	return Plugin_Continue;
}

DrawReadyPanelList()
{

	decl String:readyPlayers[1024];
	decl String:name[MAX_NAME_LENGTH];

	readyPlayers[0] = 0;

	new numPlayers = 0;
	new numPlayers2 = 0;

	new ready, unready;

	new i;
	for(i = 1; i < GetMaxClients()+1; i++)
	{
		if(IsClientInGame(i))
		{
			if(!IsClientObserver(i))
			{

				if(readyStatus[i])
	   			{

					ready++;
				}
				else
				{

					unready++;
				}
			}
		}
	}



	new Handle:panel = CreatePanel();

	if(ready)
	{
		DrawPanelText(panel, "READY");

		//->%d. %s makes the text yellow
		// otherwise the text is white

		for(i = 1; i < GetMaxClients()+1; i++)
		{
			if(IsClientInGame(i))
			{
                if(!IsClientObserver(i))
				{
					GetClientName(i, name, sizeof(name));

					if(readyStatus[i])
					{

						numPlayers++;
						Format(readyPlayers, 1024, "->%d. %s", numPlayers, name);
						DrawPanelText(panel, readyPlayers);

					}
				}
			}
		}
	}

	if(unready)
	{
		DrawPanelText(panel, "NOT READY");

		for(i = 1; i < GetMaxClients()+1; i++)
		{
			if(IsClientInGame(i))
			{
                if(!IsClientObserver(i))
				{

					GetClientName(i, name, sizeof(name));

					if(!readyStatus[i])
					{

						numPlayers2++;
						Format(readyPlayers, 1024, "->%d. %s", numPlayers2, name);
						DrawPanelText(panel, readyPlayers);

					}
				}
			}
		}
	}

	for (i = 1; i < GetMaxClients()+1; i++)
	{
		if(IsClientInGame(i))
		{
			SendPanelToClient(panel, i, Menu_ReadyPanel, READY_LIST_PANEL_LIFETIME);

			/*
			//some other menu was open during this time?
			if(menuInterrupted[i])
			{
				//if the menu is still up, dont refresh
				if(GetClientMenu(i))
				{
					DebugPrintToAll("MENU: Will not draw to %N, has menu open (and its not ours)", i);
					continue;
				}
				else
				{
					menuInterrupted[i] = false;
				}
			}
			//send to client if he doesnt have menu already
			//this menu will be refreshed automatically from timeout callback
			if(!GetClientMenu(i))
				SendPanelToClient(panel, i, Menu_ReadyPanel, READY_LIST_PANEL_LIFETIME);
			else
				DebugPrintToAll("MENU: Will not draw to %N, has menu open (and it could be ours)", i);
			*/

			/*
			#if READY_DEBUG
			PrintToChat(i, "[DEBUG] You have been sent the Panel.");
			#endif
			*/

		}
	}

	if(menuPanel != INVALID_HANDLE)
	{
		CloseHandle(menuPanel);
	}
	menuPanel = panel;
}

public Menu_ReadyPanel(Handle:menu, MenuAction:action, param1, param2)
{
}



Ready(client, bool:yes = true)
{

	if(yes)
	{
		readyStatus[client] = 1;
	}
	else
	{
		readyStatus[client] = 0;
	}

	new i, count =0;
	for(i = 1; i< GetMaxClients()+1; i++)
	{
        if(IsClientInGame(i))
		{
			if(!IsClientObserver(i))
			{

				count += 1;
			}
		}
	}

	DrawReadyPanelList();
	
	if(count >= GetConVarInt(min_players))
	{
		CheckReady();
	}
}

CheckReady()
{
	new allready = 1;
	for(new i = 1; i<GetMaxClients()+1; i++)
	{
		if(IsClientInGame(i))
		{

			if(!IsClientObserver(i))
			{
				allready *= readyStatus[i];
			}
		}
	}

	if(allready)
	    StartPug()
}

StartPug()
{
	PrintToChatAll("\x05 All players ready\n War is starting.")
	new String:cfg[128];
	GetConVarString(war_cfg, cfg, sizeof(cfg))
	ServerCommand("exec %s", cfg)
	
	SetConVarBool(roundislive, true)
}

