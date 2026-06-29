#pragma semicolon 1
#define DEBUG
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>  
#include <halflife>



#pragma newdecls required

public Plugin myinfo = 
{
	name = "1v1 plugin [Mostly for Surf Combat]",
	author = "awyx",
	description = "Choose teams with 2 simple menus and fight!",
	version = "1.1",
	url = "https://steamcommunity.com/id/sleepiest/"
};

// idk tbh
int player1;
int player2;

// used for score
int roundsWon_p1 = 0;
int roundsWon_p2 = 0;

// used for chat
int p1, p2;

// rounds that will be played
int rounds;

bool match = false;

public void OnPluginStart()
{
	RegAdminCmd("sm_1v1", Main, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cancel1v1", Cancel1v1, ADMFLAG_GENERIC);
	
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);	
}


// current map
char mapname[128];
public void OnMapStart() 
{ 
    GetCurrentMap(mapname, sizeof(mapname));
}

// round start
public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{ 
	if (match)
	{
		info1v1();
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (match)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		int victimId = event.GetInt("userid");
		int victim = GetClientOfUserId(victimId);
	
		int teamVictim = GetClientTeam(victim);

		if (teamVictim == CS_TEAM_T) 
		{
			roundsWon_p1++;
		}
		else if (teamVictim == CS_TEAM_CT)
		{
			roundsWon_p2++;
		}

		
		if ((roundsWon_p1 == rounds) || (roundsWon_p2 == rounds))
		{
			RemoveCommandListener(ChangeTeam, "jointeam");
			PrintToChatAll("\x01 \x03---------- END ----------");
			SetHudTextParams(-1.0, 0.1, 10.1, 255, 255, 0, 2, 0);
			if (roundsWon_p1 == rounds)
			{
				for (int x = 0; x < 3; x++){
					PrintToChatAll("\x01 \x0B%N \x01has beaten \x07%N \x01( \x0B%d \x01- \x07%d\x01 ) ", p1, p2, roundsWon_p1, roundsWon_p2);
				}
				ShowHudText(client, 2, "%N has won!", p1);
			}
			if (roundsWon_p2 == rounds)
			{
				for (int y = 0; y < 3; y++){ 
					PrintToChatAll("\x01 \x07%N \x01has beaten \x0B%N \x01( \x07%d \x01- \x0B%d\x01 ) ", p2, p1, roundsWon_p2, roundsWon_p1);
				}
				ShowHudText(client, 2, "%N has won!", p2);
			}
			player1 = -1;
			player2 = -1;
			roundsWon_p1 = 0;
			roundsWon_p2 = 0;
			p1 = -1;
			p2 = -1;
			rounds = 0;
			match = false;
		}
	}
}

// cancel the plugin 
public Action Cancel1v1(int client, int args)
{
	PrintToChat(client, "\x01 \x07Match canceled!");
	player1 = -1;
	player2 = -1;
	roundsWon_p1 = 0;
	roundsWon_p2 = 0;
	p1 = -1;
	p2 = -1;
	rounds = 0;
	match = false;
	RemoveCommandListener(ChangeTeam, "jointeam");
	return Plugin_Stop; 
}

// first menu (Choose players)
public Action Main(int client, int args)
{
	if (match)
	{
		PrintToChat(client, "\x01 \x07There is already a match running.");
		return Plugin_Stop; 
	}
	else
	match = true;
	PrintToChat(client, "\x01 \x07If you want to cancel the 1v1 match do \x04!cancel1v1");
	Menu menu = new Menu(MenuMain_Callback);
	menu.SetTitle("First to ?");
	menu.AddItem("1", "1");
	menu.AddItem("2", "3");
	menu.AddItem("3", "5");
	menu.Display(client, 30);
	return Plugin_Handled;
}

public int MenuMain_Callback(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action) 
	{
		case MenuAction_Select:
		{
			char item[32];
			menu.GetItem(param2, item, sizeof(item));
			
			if (StrEqual(item, "1")){
				rounds = 1;
				menu1(param1);
			}
			if (StrEqual(item, "2")){
				rounds = 3;
				menu1(param1);
			}
			if (StrEqual(item, "3")){
				rounds = 5;
				menu1(param1);
			}
		}
		case MenuAction_End: { delete menu; } 
	}
}


// menu player 1
public Action menu1(int client)
{
	Menu menuT1 = new Menu(MenuT1_Cb);
	menuT1.SetTitle("Player 1:");
	for(int id = 1; id < MAXPLAYERS; id++) 
	{
 		if(IsClientInGame(id))
 		{
     		char info[10], name[32];
     		IntToString(id, info, sizeof(info));
     		GetClientName(id, name, sizeof(name));
    		menuT1.AddItem(info, name);
 		}
 	}
 	menuT1.Display(client, MENU_TIME_FOREVER);
}

public int MenuT1_Cb(Menu menuT1, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32], name[MAX_NAME_LENGTH];
			menuT1.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			int client = StringToInt(info);
			p1 = client;
			if(IsClientInGame(client))
			{
					player1 = client;
					CS_SwitchTeam(client, CS_TEAM_CT);
					PrintToChat(param1, "\x01 Player %N has been moved to \x0BCT", client);  
			}
			menu2(param1);
		}
		case MenuAction_End:{delete menuT1;}
	}
}


// menu player 2
public Action menu2(int client)
{
	Menu menuT2 = new Menu(MenuT2_Cb);
	menuT2.SetTitle("Player 2:");
	for(int id = 1; id < MAXPLAYERS; id++) 
	{
 		if(IsClientInGame(id))
 		{
     		char info[32], name[32];
     		IntToString(id, info, sizeof(info));
     		GetClientName(id, name, sizeof(name));
     		
     		bool verificarid = false;
     		for (int x = 0; x < MAXPLAYERS; x++){
				if(id == player1){
					verificarid = true;
					break;
				}
     		}
     		if(!verificarid){
				menuT2.AddItem(info, name);
			}
    	}
 	}
 	menuT2.Display(client, 0);
}

public int MenuT2_Cb(Menu menuT2, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[32], name[MAX_NAME_LENGTH];	
			menuT2.GetItem(param2, info, sizeof(info), _, name, sizeof(name));
			int client = StringToInt(info);
			p2 = client;
			if (IsClientInGame(client))
			{
				player2 = client;
				CS_SwitchTeam(client, CS_TEAM_T);
				PrintToChat(param1, "\x01 Player %N has been moved to \x07T", client);  
			}
			SpecOut();
		}
		case MenuAction_End:{delete menuT2;}		
	}	
}

// restart the round // spec the other players 
void SpecOut()
{
	if (match)
	{
		commands();
		AddCommandListener(ChangeTeam, "jointeam"); // blocks joining team 
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && i != player1 && i != player2)
			{
				ChangeClientTeam(i, CS_TEAM_SPECTATOR);
			}
		}
	}
	//HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
	//HookEvent("player_death", Event_PlayerDeath);
}

// chat stuff (players, score and current map)
public void info1v1()
{
	if (match)
	{
		PrintToChatAll("\x01 \x04******************************");
		PrintToChatAll("\x01 \x0B%N \x01vs \x07%N", p1, p2); 
		PrintToChatAll("\x01 Score: %d - %d (first to \x05%d\x01)", roundsWon_p1, roundsWon_p2, rounds); 
		PrintToChatAll("\x01 Map: \x08%s", mapname);
		PrintToChatAll("\x01 \x04******************************");
	}
}

// avoid changing team
public Action ChangeTeam(int client, const char[] command, int args) 
{ 
   	return Plugin_Stop;
}  

// sum shit idk restart the round
void commands()
{
	if (match)
	{
		ServerCommand("mp_restartgame 1");
		ServerCommand("mp_limitteams 0");
		ServerCommand("mp_autoteambalance 0");
	}
}

public Action end()
{
	player1 = -1;
	player2 = -1;
	roundsWon_p1 = 0;
	roundsWon_p2 = 0;
	p1 = -1;
	p2 = -1;
	rounds = 0;
	match = false;
}