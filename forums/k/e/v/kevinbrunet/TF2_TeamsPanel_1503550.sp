/********************************************************************************************
* Plugin	: TF2_TeamsPanel
* Version	: 1.0
* Game		: Team Fortress 2
* Author	: Kevinbrunet
* 
* Purpose	: Shows Panel for Teams on Server
* 
* Version 1.0:
* 		- Initial release
* Version 1.1:
* 		- Fix some bugs
*  
*********************************************************************************************/

#include <sourcemod>
#include <sdktools>


//Define CVARS
#define PLUGIN_VERSION "1.1"

//Handles
new Handle:cc_plpOnConnect = INVALID_HANDLE;
new Handle:cc_plpAutoRefreshPanel = INVALID_HANDLE;
new Handle:cc_plpTimer = INVALID_HANDLE;
new Handle:cc_plpPaShowscores = INVALID_HANDLE;
new Handle:cc_plpAnnounce = INVALID_HANDLE;
new Handle:cc_plpSelectTeam = INVALID_HANDLE;
new Handle:cc_plpHintStatic = INVALID_HANDLE;
new Handle:cc_plpSpectatorSelect = INVALID_HANDLE;
new Handle:cc_plpRedSelect = INVALID_HANDLE;
new Handle:cc_plpBlueSelect = INVALID_HANDLE;

//Strings
new String:hintText[2048];


//CVARS
new plpOnConnect;
new plpAutoRefreshPanel;
new plpTimer;
new plpPaShowscores;
new plpAnnounce;
new plpSelectTeam;
new plpHintStatic;
new plpSpectatorSelect;
new plpRedSelect;
new plpBlueSelect;
new ClientAutoRefreshPanel[33];
new wantedrefresh[33];
new hintstatic[33];


//Plugin Info Block
public Plugin:myinfo =
{
	name = "Playerlist Panel",
	author = "Kevinbrunet",
	description = "Shows Panel for Teams on Server",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};


//Plugin start
public OnPluginStart()
{
	//Load Translation file
	LoadTranslations("tf2_teamspanel.phrases");

	//Reg Commands
	RegConsoleCmd("sm_players", PrintTeamsToClient);

	//Reg Cvars
	CreateConVar("tf2_plp_version", PLUGIN_VERSION, "Playerlist Panel Display Version", FCVAR_REPLICATED|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cc_plpOnConnect = CreateConVar("tf2_plp_onconnect", "1", "Show Playerlist Panel on connect?");
	cc_plpTimer = CreateConVar("tf2_plp_timer", "10", "How long, in seconds, the Playerlist Panel stay before it close automatic");
	cc_plpAutoRefreshPanel = CreateConVar("tf2_plp_autorefreshpanel", "0", "Should the Panel be static & refresh itself every second?");
	cc_plpPaShowscores = CreateConVar("tf2_plp_pashowscores", "0", "Show Playerlist Panel after Showscores? NO REFRESH!");
	cc_plpAnnounce = CreateConVar("tf2_plp_announce", "0", "Show Hint-Message about the command to players on Spectator?");
	cc_plpSelectTeam = CreateConVar ("tf2_plp_select_team", "0", "Should the user be able to select a team on Playerlist Panel?");
	cc_plpHintStatic = CreateConVar ("tf2_plp_hint_static", "0", "Should the Hint for Panel options be Static?");
	cc_plpSpectatorSelect = CreateConVar ("tf2_plp_select_team_spectator", "0", "If l4d_plp_select_team = 1 \nShould the Spectator selection be functional?");
	cc_plpRedSelect = CreateConVar ("tf2_plp_select_team_red", "0", "If l4d_plp_select_team = 1 \nShould the Red selection be functional?");
	cc_plpBlueSelect = CreateConVar ("tf2_plp_select_team_blue", "0", "If l4d_plp_select_team = 1 \nShould the Blue selection be functional?");
	
	//Execute the config file
	AutoExecConfig(true, "tf2_teamspanel");

	//Hook Cvars
	HookConVarChange(cc_plpOnConnect, ConVarChanged);
	HookConVarChange(cc_plpTimer, ConVarChanged);
	HookConVarChange(cc_plpAutoRefreshPanel, ConVarChanged);
	HookConVarChange(cc_plpPaShowscores, ConVarChanged);
	HookConVarChange(cc_plpAnnounce, ConVarChanged);
	HookConVarChange(cc_plpSelectTeam, ConVarChanged);
	HookConVarChange(cc_plpHintStatic, ConVarChanged);
	HookConVarChange(cc_plpSpectatorSelect, ConVarChanged);
	HookConVarChange(cc_plpRedSelect, ConVarChanged);
	HookConVarChange(cc_plpBlueSelect, ConVarChanged);
	
	//Build Hint Text depending on cvars
	HintText();
	
	//Re read CVARS
	ReadCvars();
}


//Prepare & Print Playerlist Panel
public BuildPrintPanel(client)
{

	//Build panel
	new Handle:TeamPanel = CreatePanel();
	SetPanelTitle(TeamPanel, "\x04Playerlist Panel");
	DrawPanelText(TeamPanel, " \n");
	new count;
	new i, sumall, sumspec, sumsurv, suminf;
	new String:text[64];

	//Counting
	sumall = CountAllHumanPlayers();
	sumspec = CountPlayersTeam(1);
	sumsurv = CountPlayersTeam(2);
	suminf = CountPlayersTeam(3)
	
	
	//Draw Spectators count line
	Format(text, sizeof(text), "\x04Spectators \x03(%d of %d) \x01\n", sumspec, sumall);
	
	//Slectable Spectators or not
	if (plpSelectTeam == 1)
	{
		DrawPanelItem(TeamPanel, text);
	}
	if (plpSelectTeam == 0)
	{
		DrawPanelText(TeamPanel, text);
	}

	//Get & Draw Spectator Player Names
	count = 1;
	for (i=1;i<=MaxClients;i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 1)
		{
			Format(text, sizeof(text), "%d. %N", count, i);
			DrawPanelText(TeamPanel, text);
			count++;
		}
	}
	DrawPanelText(TeamPanel, " \n");
	
	//Draw Red Team count line
	Format(text, sizeof(text), "\x04Red Team \x03(%d of %d) \x01\n", sumsurv, MaxClients/2);

	//Selectable Survivors or not
	if (plpSelectTeam == 1)
	{
		DrawPanelItem(TeamPanel, text);
	}
	if (plpSelectTeam == 0)
	{
		DrawPanelText(TeamPanel, text);
	}

	//Get & Draw Red Player Names
	count = 1;
	for (i=1;i<=MaxClients;i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 2)
		{
			Format(text, sizeof(text), "%d. %N", count, i);
			DrawPanelText(TeamPanel, text);
			count++;
		}
	}
	DrawPanelText(TeamPanel, " \n");

	//Draw Blue Team count line
	Format(text, sizeof(text), "\x04Blue Team \x03(%d of %d) \x01\n", suminf, MaxClients/2);

	//Get & Draw Blue Team Player Names
	if (plpSelectTeam == 1)
	{
		DrawPanelItem(TeamPanel, text);
	}
	if (plpSelectTeam == 0)
	{
		DrawPanelText(TeamPanel, text);
	}
	count = 1;
	for (i=1;i<=MaxClients;i++)
	{
		if (IsValidPlayer(i) && GetClientTeam(i) == 3)
		{
			Format(text, sizeof(text), "%d. %N", count, i);
			DrawPanelText(TeamPanel, text);
			count++;
		}
	}
	//Draw Total connected Players & Draw Final
	DrawPanelText(TeamPanel, " \n");
	Format(text, sizeof(text), "\x04Connected: %d/%d", sumall, MaxClients);
	DrawPanelText(TeamPanel, text);
	
	//Send Panel to client
	if (plpSelectTeam == 1)
	{
		SendPanelToClient(TeamPanel, client, TeamPanelHandlerB, plpTimer);
		CloseHandle(TeamPanel);
	}
	if (plpSelectTeam == 0)
	{
		SendPanelToClient(TeamPanel, client, TeamPanelHandler, plpTimer);
		CloseHandle(TeamPanel);
	}
}


//TeamPanelHandler
public TeamPanelHandler(Handle:TeamPanel, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		if (wantedrefresh[param1] == 0)
		{
			ClientAutoRefreshPanel[param1] = 0;
			hintstatic[param1] = 0;
		}
	}
	else if (action == MenuAction_Select)
	{
		if (param2 >= 1)
		{
			ClientAutoRefreshPanel[param1] = 0;
			hintstatic[param1] = 0;
		}
	}
}


//TeamPanelHandlerB
public TeamPanelHandlerB(Handle:TeamPanel, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			if (plpSpectatorSelect == 1)
			{
				PerformSwitch(param1, 1);
			}
			ClientAutoRefreshPanel[param1] = 0;
			hintstatic[param1] = 0;
		}
		else if (param2 == 2)
		{
			if (plpRedSelect == 1)
			{
				PerformSwitch(param1, 2);
			}
			ClientAutoRefreshPanel[param1] = 0;
			hintstatic[param1] = 0;
		}
		else if (param2 == 3)
		{
			if (plpBlueSelect == 1)
			{
				PerformSwitch(param1, 3);
			}
			ClientAutoRefreshPanel[param1] = 0;
			hintstatic[param1] = 0;
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ClientAutoRefreshPanel[param1] = 0;
		hintstatic[param1] = 0;
	}
}


//Send the Panel to the Client
public Action:PrintTeamsToClient(client, args)
{
	if (plpAutoRefreshPanel == 1 && plpSelectTeam == 0)
	{
		wantedrefresh[client] = 1;
		ClientAutoRefreshPanel[client] = 1;
		if (plpHintStatic == 1)
		{
			hintstatic[client] = 1;
			CreateTimer(3.0, HintStaticTimer, client, TIMER_REPEAT);
		}
		CreateTimer(3.0, RefreshPanel, client, TIMER_REPEAT);
	}
	if (plpAutoRefreshPanel == 0)	
	{
		plpTimer = GetConVarInt(cc_plpTimer);
		wantedrefresh[client] = 0;
		if (plpSelectTeam == 1)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "%s", hintText);
		}
		if (plpSelectTeam == 0)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "Press '0' \nTo close the Panel!");
		}
		BuildPrintPanel(client);
	}
	if (plpAutoRefreshPanel == 1 && plpSelectTeam == 1)
	{
		wantedrefresh[client] = 0;
		plpTimer = GetConVarInt(cc_plpTimer);
		if (plpSelectTeam == 1)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "%s", hintText);
		}
		if (plpSelectTeam == 0)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "Press '0' \nTo close the Panel!");
		}
		BuildPrintPanel(client);
	}
	
}


//Show Announcement for !teams Command
public Action:AnnounceCommand(Handle:timer)
{
	if (plpAnnounce >0)
	{
		for(new i=1; i<=32; i++)
		{
			if (IsValidPlayer(i) && GetClientTeam(i) == 1)
			{
				PrintHintText(i, "Say !teams to see a list of Players \nThen 2 for Red Team \nOr 3 for Blue Team");
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

//Dow we Show Panel On Connect? (on by default)
public Action:OnConnect(Handle:timer, any:client)
{
	if (plpOnConnect == 1 && ClientAutoRefreshPanel[client] == 1)
	{
		if (plpSelectTeam == 1)
		{
			hintstatic[client] = 0;
			plpTimer = GetConVarInt(cc_plpTimer);
		}
		else plpTimer=0;
		CreateTimer(3.0, RefreshPanel, client, TIMER_REPEAT);
		if (plpSelectTeam == 0 && plpHintStatic == 1)
		{
			hintstatic[client] = 1;
			CreateTimer(4.0, HintStaticTimer, client, TIMER_REPEAT);
		}
		if (plpHintStatic == 0)
		{
			hintstatic[client] = 0;
			CreateTimer(4.0, HintStaticTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	if (plpOnConnect == 1 && ClientAutoRefreshPanel[client] == 0)
	{
		hintstatic[client] = 0;
		wantedrefresh[client] = 0;
		plpTimer = GetConVarInt(cc_plpTimer);
		if (plpSelectTeam == 1)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "%s", hintText);
		}
		if (plpSelectTeam == 0)
		{
			if (IsValidPlayer(client)) PrintHintText(client, "Press '0' \nTo close the Panel!");
		}
		BuildPrintPanel(client);
	}
}


//HintStatic Timer
public Action:HintStaticTimer(Handle:Timer, any:client)
{
	if (hintstatic[client] == 1)
	{
		if (IsValidPlayer(client)) PrintHintText(client, "Press '0' \nTo close the Panel!");
	}
	return Plugin_Stop;
}

//Refreshing Panel Timer
public Action:RefreshPanel(Handle:Timer, any:client)
{
	if (ClientAutoRefreshPanel[client] == 1)
	{
		if (plpSelectTeam == 1)	plpTimer = GetConVarInt(cc_plpTimer);
		else plpTimer = 0;
		BuildPrintPanel(client);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}


//Check if Player fresh connected
public OnClientPostAdminCheck(client)
{
	if (IsValidPlayer(client) && plpAutoRefreshPanel == 1)
	{
		ClientAutoRefreshPanel[client] = 1;
		wantedrefresh[client] = 1;
	}
	if (IsValidPlayer(client) && plpAutoRefreshPanel == 0)
	{
		ClientAutoRefreshPanel[client] = 0;
		wantedrefresh[client] = 0;
	}
	//Only show Playerlist Panel to "new" connected Players
	if (IsValidPlayer(client) && GetClientTime(client) <= 120)
	{
		CreateTimer(5.0, OnConnect, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}


//Client Disconnects
public OnClientDisconnect(client)
{
	if (IsValidPlayer(client))
	{
		ClientAutoRefreshPanel[client] = 0;
		wantedrefresh[client] = 0;
		hintstatic[client] = 0;
	}
}


//Cvar changed check
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ReadCvars();
}


//Re-Read Cvars
public ReadCvars()
{
	plpAutoRefreshPanel=GetConVarInt(cc_plpAutoRefreshPanel);
	plpHintStatic=GetConVarInt(cc_plpHintStatic);
	plpSelectTeam=GetConVarInt(cc_plpSelectTeam);
	plpSpectatorSelect=GetConVarInt(cc_plpSpectatorSelect);
	plpRedSelect=GetConVarInt(cc_plpRedSelect);
	plpBlueSelect=GetConVarInt(cc_plpBlueSelect);
	plpOnConnect=GetConVarInt(cc_plpOnConnect);
	plpAnnounce=GetConVarInt(cc_plpAnnounce);
	plpTimer=GetConVarInt(cc_plpTimer);
	plpPaShowscores=GetConVarInt(cc_plpPaShowscores);
	HintText();
}


//Show Playerlist Panel after Scoreboard
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	//Check if its a valid player
	if (!IsValidPlayer(client)) return;
	if (plpPaShowscores == 1)
	{
		if (buttons & IN_SCORE)
		{
			wantedrefresh[client] = 0;
			ClientAutoRefreshPanel[client] = 0;
			if (plpSelectTeam == 1)
			{
				if (IsValidPlayer(client)) PrintHintText(client, "%s", hintText);
			}
			if (plpSelectTeam == 0)
			{
				if (IsValidPlayer(client)) PrintHintText(client, "Press '0' \nTo close the Panel!");
			}
			if (IsValidPlayer(client))
			{
				BuildPrintPanel(client);
			}
		}
	}  
}  

bool:IsTeamFull (team)
{
	// Spectator's team is never full :P
	if (team == 1) return false;
	
	new count=0;
	new i;
	
	// we count the players in the Red team
	if (team == 2){
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==2))
				count++;
	}
	else if (team == 3) { // we count the players in the Blue team
		for (i=1;i<GetMaxClients();i++)
			if ((IsClientConnected(i))&&(!IsFakeClient(i))&&(GetClientTeam(i)==3))
				count++;
	}
	
	// If full ...
	if (2*count >= MaxClients)
		return true;
	else
	return false;
}

PerformSwitch (client, team)
{
	if ((!IsClientConnected(client)) || (!IsClientInGame(client))) return;
	
	// If teams are the same ...
	if (GetClientTeam(client) == team)
	{
		PrintToChat(client, "Open your eyes, you are already on that team!");
		return;
	}
	
	
	// We check if target team is full...
	if (IsTeamFull(team))
	{
		if (team == 2) PrintToChat(client, "The \x03Red\x01 team is already full.");
		else if (team == 3) PrintToChat(client, "The \x03Blue\x01 team is already full.");
		return;
	}
	
	ChangeClientTeam(client, team);
}

//Hint Text
public HintText()
{
	//Define text parts
	new String:specTextOn[] = "1 to join Spectator";
	new String:specTextOff[] = "Spec = !spectate";
	new String:redTextOn[] = "2 to join Red Team";
	new String:redTextOff[] = "Red = !jointeam2";
	new String:blueTextOn[] = "3 to join Blue Team";
	new String:blueTextOff[] = "Blue = !jointeam3";
	new String:secondLine[] = "\nPress '0' to just close the Panel!"
	
	//Check selectable switches and format text
	if (plpSpectatorSelect == 1 && plpRedSelect == 1 && plpBlueSelect == 1)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOn, redTextOn, blueTextOn, secondLine);
	}
	if (plpSpectatorSelect == 1 && plpRedSelect == 0 && plpBlueSelect == 0)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOn, redTextOff, blueTextOff, secondLine);
	}
	if (plpSpectatorSelect == 1 && plpRedSelect == 1 && plpBlueSelect == 0)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOn, redTextOn, blueTextOff, secondLine);
	}
	if (plpSpectatorSelect == 1 && plpRedSelect == 0 && plpBlueSelect == 1)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOn, redTextOff, blueTextOn, secondLine);
	}
	if (plpSpectatorSelect == 0 && plpRedSelect == 1 && plpBlueSelect == 1)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOff, redTextOn, blueTextOn, secondLine);
	}
	if (plpSpectatorSelect == 0 && plpRedSelect == 1 && plpBlueSelect == 0)
	{
		Format(hintText, 255, "%s | %s | %s%s", specTextOff, redTextOn, blueTextOff, secondLine);
	}
	if (plpSpectatorSelect == 0 && plpRedSelect == 0 && plpBlueSelect == 1)
	{
		Format(hintText, sizeof(hintText), "%s | %s | %s %s", specTextOff, redTextOff, blueTextOn, secondLine);
	}
}


//Event Map Start
public OnMapStart()
{
	if (plpAnnounce >= 1)
	{
		CreateTimer(15.0, AnnounceCommand, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}


//Is Valid Player
public IsValidPlayer(client)
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


//Count all Players
public CountAllHumanPlayers()
{
	new Count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			Count++;
		}
	}
	return Count;
}


//Count Players Team
public CountPlayersTeam(team)
{
	new Count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
		{
			Count++;
		}
	}
	return Count;
}


//End of Plugin
