#include <sourcemod>
#include <sdktools>


//Define CVARS
#define MAX_SURVIVORS GetConVarInt(FindConVar("survivor_limit"))
#define MAX_INFECTED GetConVarInt(FindConVar("z_max_player_zombies"))
#define PLUGIN_VERSION "1.4"


//Handles
new Handle:cc_plpOnConnect = INVALID_HANDLE;
new Handle:cc_plpTimer = INVALID_HANDLE;
new Handle:cc_plpAutoRefreshPanel = INVALID_HANDLE;
new Handle:cc_plpPaSTimer = INVALID_HANDLE;
new Handle:cc_plpPaShowscores = INVALID_HANDLE;

//CVARS
new plpOnConnect=1;
new plpTimer=20;
new plpPaSTimer=5;
new plpAutoRefreshPanel=1;
new plpPaShowscores=0;
new ClientAutoRefreshPanel[33];
new wantedrefresh[33];
new newjoin[64];


//Plugin Info Block
public Plugin:myinfo =
{
	name = "Playerlist Panel",
	author = "OtterNas3",
	description = "Shows Panel for Teams on Server",
	version = PLUGIN_VERSION,
	url = "n/A"
};


//Plugin start
public OnPluginStart()
{
	//Reg Commands
	RegConsoleCmd("sm_teams", PrintTeamsToClient);

	//Reg Cvars
	CreateConVar("l4d_plp_version", PLUGIN_VERSION, "Playerlist Panel Display Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cc_plpOnConnect = CreateConVar("l4d_plp_onconnect", "1", "Show Playerlist Panel on Connect?", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	cc_plpTimer = CreateConVar("l4d_plp_timer", "20", "How many seconds should the Playerlist Panel been displayed? 0 = static", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,999.0);
	cc_plpAutoRefreshPanel = CreateConVar("l4d_plp_autorefreshpanel", "1", "Should the Panel be static & refresh itself every second?", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	cc_plpPaShowscores = CreateConVar("l4d_plp_pashowscores", "0", "How many seconds should the Playerlist Panel stay after Showscores?", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,1.0);
	cc_plpPaSTimer = CreateConVar("l4d_plp_pastimer", "5", "How many seconds should the Playerlist Panel stay after Showscores? 0 = static", FCVAR_REPLICATED|FCVAR_GAMEDLL|FCVAR_NOTIFY,true,0.0,true,999.0);

	//Execute the config file
	AutoExecConfig(true, "l4d_teamspanel");

	//Hook Cvars
	HookConVarChange(cc_plpOnConnect, ConVarChanged);
	HookConVarChange(cc_plpTimer, ConVarChanged);
	HookConVarChange(cc_plpAutoRefreshPanel, ConVarChanged);
	HookConVarChange(cc_plpPaSTimer, ConVarChanged);
	HookConVarChange(cc_plpPaShowscores, ConVarChanged);
}


//Search for running L4DToolz and/or L4Downtown (or none of them) to get correct Max Clients
maxclToolzDowntownCheck()
{
	new Handle:invalid = INVALID_HANDLE;
	new Handle:downtownrun = FindConVar("l4d_maxplayers");
	new Handle:toolzrun = FindConVar("sv_maxplayers");
	new maxcl;
	
	//Downtown is running!
	if (downtownrun != (invalid))
	{
		//Is Downtown used for slot patching? if yes use it for Max Players
		new downtown = (GetConVarInt(FindConVar("l4d_maxplayers")));
		if (downtown >= 1)
		{
			maxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
		}
	}

	//L4DToolz is running!
	if (toolzrun != (invalid))
	{
		//Is L4DToolz used for slot patching? if yes use it for Max Players
		new toolz = (GetConVarInt(FindConVar("sv_maxplayers")));
		if (toolz >= 1)
		{
			maxcl = (GetConVarInt(FindConVar("sv_maxplayers")));
		}
	}

	//No Downtown or L4DToolz running using fallback (possible x/32)
	if (downtownrun == (invalid) && toolzrun == (invalid))
	{
		maxcl = (MaxClients);
	}
	return maxcl;
}


//Prepare & Print Playerlist Panel
public BuildPrintPanel(client)
{
	//Get correct Max Clients
	new maxcl = maxclToolzDowntownCheck();
	new i, j = (MaxClients);
	new botcounts[4];
	new playerteams[MaxClients+1];
	new teamcounts[4];
	new tempteam;

	//Counting teams
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			tempteam = GetClientTeam(i) - 1;
			if (tempteam == 0 || tempteam == 1 || tempteam == 2)
			{
				playerteams[i-1] = tempteam;
				teamcounts[tempteam]++;
			
				//Botcount
				if (IsFakeClient(i))
				{
					botcounts[tempteam]++;
				}
			}
		}
		//just to be sure
		else playerteams[i-1] = -1;
	}
	
	//Build panel
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "Playerlist Panel");
	DrawPanelText(TeamPanel, " \n");
	new count;
	new sum;
	new String:text[64];

	//How many Clients ingame?
	for (i = 0; i < 3; i++) sum += teamcounts[i];

	//Draw Spectators count line
	Format(text, sizeof(text), "Spectators (%d of %d)\n", teamcounts[0], (sum - botcounts[1] - botcounts[2]));
	DrawPanelText(TeamPanel, text);

	//Get & Draw Spectator Player Names
	count = 1;
	for (j = 0; j < MaxClients; j++)
	{
		if (playerteams[j] != 0) continue;
		Format(text, sizeof(text), "%d. %N", count, (j + 1));
		DrawPanelText(TeamPanel, text);
		count++;
	}
	DrawPanelText(TeamPanel, " \n");
	
	//Draw Survivors count line
	Format(text, sizeof(text), "Survivors (%d of %d)\n", (teamcounts[1] - botcounts[1]), MAX_SURVIVORS);
	DrawPanelText(TeamPanel, text);

	//Get & Draw Survivor Player Names
	count = 1;
	for (j = 0; j < MaxClients; j++)
	{
		if (playerteams[j] != 1) continue;
		Format(text, sizeof(text), "%d. %N", count, (j + 1));
		DrawPanelText(TeamPanel, text);
		count++;
	}
	DrawPanelText(TeamPanel, " \n");

	//Draw Infected part depending on gamemode
	//
	//Gamemode is Versus
	if (GameModeCheck() == 2)
	{
		//Draw Infected count line
		Format(text, sizeof(text), "Infected (%d of %d)\n", (teamcounts[2] - botcounts[2]), MAX_INFECTED);

		//Get & Draw Infected Player Names
		DrawPanelText(TeamPanel, text);
		count = 1;
		for (j = 0; j < MaxClients; j++)
		{
			if (playerteams[j] != 2) continue;
			Format(text, sizeof(text), "%d. %N", count, (j + 1));
			DrawPanelText(TeamPanel, text);
			count++;
		}

		//Draw Total connected Players & Draw Final
		DrawPanelText(TeamPanel, " \n");
		Format(text, sizeof(text), "Connected: %d/%d", (sum - botcounts[1] -botcounts[2]), maxcl);
		DrawPanelText(TeamPanel, text);
	}

	//Gamemode is Coop
	if (GameModeCheck() == 1)
	{
		//Draw Total connected Players & Draw Final
		Format(text, sizeof(text), "Connected: %d/%d", (teamcounts[1] - botcounts[1]), maxcl);
		DrawPanelText(TeamPanel, text);
	}

	//Send Panel to client
	SendPanelToClient(TeamPanel, client, TeamPanelHandler, plpTimer);
}


//TeamPanelHandler
public TeamPanelHandler(Handle:TeamPanel, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		if (wantedrefresh[param1] == 1)
		{
			ClientAutoRefreshPanel[param1] = 1;
			//PrintToChat(param1, "Menu End - wanted refresh 1 - ClientAutoRefreshPanel = %d", ClientAutoRefreshPanel[param1]);
		}
		else if (wantedrefresh[param1] == 0)
		{
			ClientAutoRefreshPanel[param1] = 0;
			//PrintToChat(param1, "Menu End - wanted refresh 0 - ClientAutoRefreshPanel = %d", ClientAutoRefreshPanel[param1]);
		}
	}
	else if (action == MenuAction_Select)
	{
		ClientAutoRefreshPanel[param1] = 0;
		//PrintToChat(param1, "Menu Select - ClientAutoRefreshPanel = %d", ClientAutoRefreshPanel[param1]);
	}
}


//Send the Panel to the Client
public Action:PrintTeamsToClient(client, args)
{
	if (plpAutoRefreshPanel == 1)
	{
		wantedrefresh[client] = 1;
		ClientAutoRefreshPanel[client] = 1;
		CreateTimer(1.0, RefreshPanel, client, TIMER_REPEAT);
	}
	if (plpAutoRefreshPanel == 0)	
	{
		wantedrefresh[client] = 0;
		plpTimer = GetConVarInt(cc_plpTimer);
		BuildPrintPanel(client);
	}
}


//Dow we Show Panel On Connect? (on by default)
public Action:OnConnect(Handle:timer, any:client)
{
	if (plpOnConnect == 1 && ClientAutoRefreshPanel[client] == 1)
	{
		CreateTimer(2.0, RefreshPanel, client, TIMER_REPEAT);
	}
	else if (plpOnConnect == 1 && ClientAutoRefreshPanel[client] == 0)
	{
		plpTimer = GetConVarInt(cc_plpTimer);
		BuildPrintPanel(client);
	}
}


//Refreshing Panel Timer
public Action:RefreshPanel(Handle:Timer, any:client)
{
	if (ClientAutoRefreshPanel[client] == 1)
	{
		plpTimer = 0;
		BuildPrintPanel(client);
		PrintHintText(client, "Press '0' to close the Panel!");
		return Plugin_Continue;
	}
	return Plugin_Stop;
}


//Check if Player fresh connected
public OnClientPostAdminCheck(client)
{
	newjoin[client] = 1;
	if (!IsFakeClient(client) && plpAutoRefreshPanel == 1)
	{
		ClientAutoRefreshPanel[client] = 1;
		wantedrefresh[client] = 1;
	}
	else if (!IsFakeClient(client) && plpAutoRefreshPanel == 0)
	{
		ClientAutoRefreshPanel[client] = 0;
		wantedrefresh[client] = 0;
	}
	//Only show Playerlist Panel to "new" connected Players
	if (!IsFakeClient(client) && (GetClientTime(client) <= 120))
	CreateTimer(5.0, OnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
}


//Client Disconnects
public OnClientDisconnect(client)
{
	ClientAutoRefreshPanel[client] = 0;
	wantedrefresh[client] = 0;
}

//Gamemode Check
GameModeCheck()
{
	new GameMode = 0;
	new String:gamemodecvar[16];
	GetConVarString(FindConVar("mp_gamemode"), gamemodecvar, sizeof(gamemodecvar));
	if (StrContains(gamemodecvar, "versus", false) != -1)
	{
		GameMode = 2;
		return GameMode;
	}
	if (StrContains(gamemodecvar, "coop", false) != -1)
	{
		GameMode = 1;
		return GameMode;
	}
	return GameMode;
}


//Cvar changed check
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ReadCvars();
}


//Re-Read Cvars
public ReadCvars()
{
	plpOnConnect=GetConVarInt(cc_plpOnConnect);
	plpTimer=GetConVarInt(cc_plpTimer);
	plpAutoRefreshPanel=GetConVarInt(cc_plpAutoRefreshPanel);
	plpPaShowscores=GetConVarInt(cc_plpPaShowscores);
	plpPaSTimer=GetConVarInt(cc_plpPaSTimer);
}


//Show Playerlist Panel after Scoreboard
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	//Check if its a valid player
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client)) return;
	if (plpPaShowscores == 1)
	{
		if (buttons & IN_SCORE)
		{
			wantedrefresh[client] = 0;
			ClientAutoRefreshPanel[client] = 0;
			plpTimer = plpPaSTimer;
			BuildPrintPanel(client);
		}
	}  
}  


//End of Plugin
