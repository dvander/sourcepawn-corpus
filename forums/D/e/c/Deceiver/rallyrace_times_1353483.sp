
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <rallyrace>

#define  RALLYRACE_TIMES_VERSION			"1.7"

public Plugin:myinfo = 
{
	name = "CSS Rally Race Times Addon",
	author = "TigerOx",
	description = "CSS Rally Race Times Addon",
	version = RALLYRACE_TIMES_VERSION,
};


//TigerOx
//Added !times command - stores fastes map time and keeps race times on maps.
// - Player names are updated in times data on connect.
//Added Timeout x number of seconds after first player finishes.
//  	- ConVar rallyrace_timetofinish to control timeout seconds.s
//Added auto times popup on race finish
//Added player win and fell out of race announcement
//Added Top 10 times stored for each map.
//Old V1.0 data will be moved to top10
//Added ConVar rallyrace_timespopup to enable/disable end of race times popup
//Optimized times saving

#define		MAX_TIME		100000.0
#define		MENU_TIME		20
#define		MAX_RACE_TIMES	10
#define		TEAM_CT			3
#define		TOP_TEN			10
/* Contains the race time data */
new String:TimesDataFile[PLATFORM_MAX_PATH];
new String:ClientsDataFile[PLATFORM_MAX_PATH];
new Handle:KvTime = INVALID_HANDLE;
new Handle:KvClients = INVALID_HANDLE;
new bool:TimeOpen;
new bool:ClientsOpen;

//Finish timeout var
new Handle:h_rallyrace_timetofinish;
new Handle:h_rallyrace_timespopup;

//Top 10 map time vars
new Float:g_TopTime[TOP_TEN+1] = {MAX_TIME, ...};
new String:g_TopPlayerAuthid[TOP_TEN+1][64]; 
new String:g_TopPlayerName[TOP_TEN+1][64];
new String:g_CurrentMapName[64];

//Times menu
new Handle:Top10Panel = INVALID_HANDLE;
new Handle:TopTimePanel[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Float:g_Player_Times[MAXPLAYERS+1][MAX_RACE_TIMES];
new g_saveTimes = false;

//InRace stuff
new bool:g_Player_Racing;
new bool:g_Player_InRace[MAXPLAYERS+1] = {false, ...};
new bool:g_Race_Started;
new g_Racer_Count;
new Handle:g_Finish_Timer = INVALID_HANDLE;


public OnPluginStart()
{
		
	CreateConVar("rallyrace_times_version",RALLYRACE_TIMES_VERSION,"Rally Race Times version",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	h_rallyrace_timetofinish= CreateConVar("rallyrace_timetofinish","35","Race will end this many seconds after the first player finishes (0 = disable)",0,true,0.0);
	h_rallyrace_timespopup= CreateConVar("rallyrace_timespopup","1","The race times menu will be displayed when you finish the race (0 = disable)",0,true,0.0);
	
	RegConsoleCmd("times", TimeCommand);
	RegConsoleCmd("top10times", Time10Command);
	RegConsoleCmd("top10", Time10Command);
	RegConsoleCmd("toptimes", Time10Command);
	
	HookEvent("player_death",OnPlayerDeath);
	
	OnCreateKeyValues();
	UpdateData();
	
	//Start the race status polling - please export number of racers
	CreateTimer(1.0, RaceCheck,_,TIMER_REPEAT);
	
}

public Action:RaceCheck(Handle:timer)
{
	if(!g_Player_Racing)
	{
		if(GetTeamClientCount(TEAM_CT) > 0)
		{
			for(new i=1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetClientTeam(i) == TEAM_CT)
				{ 
					g_Racer_Count++; 
					g_Player_InRace[i] = true; 
				}
			}
			g_Player_Racing = true;
			g_Race_Started = true;
		}
		
	}
	else
	{
		//Check racer count incase last player is switched before top time check
		if(GetTeamClientCount(TEAM_CT) == 0 && g_Racer_Count == 0)
		{
			if(g_saveTimes)
			{
				AddTopTimes();
				g_saveTimes = false;
			}
			g_Race_Started = false;
			g_Player_Racing = false;
			if(g_Finish_Timer != INVALID_HANDLE)
			{
				KillTimer(g_Finish_Timer);
				g_Finish_Timer = INVALID_HANDLE;
			}
		}
	}
	
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	//Clear their last times
	for(new i = 0; i<MAX_RACE_TIMES; i++)
	{
		g_Player_Times[client][i] = 0.0;
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(g_Player_InRace[client])
	{
		g_Player_InRace[client] = false;
		g_Racer_Count--;
	}
}

public OnClientDisconnect(client)
{
	if(g_Player_InRace[client])
	{
		g_Player_InRace[client] = false;
		g_Racer_Count--;
	}
	
	if(TopTimePanel[client] != INVALID_HANDLE)
	{
		CloseHandle(TopTimePanel[client]);
		TopTimePanel[client] = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	//if we missed a save
	if(g_saveTimes)
	{ 
		AddTopTimes();
		g_saveTimes = false;
	}
	
	//Get top time map info
	GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
	
	//Clear times and names
	for(new i=1; i<=TOP_TEN; i++)
	{
		g_TopTime[i] = MAX_TIME;
		g_TopPlayerName[i] = "";
	}
	
	LoadTopTimes();
	
	//Create top 10 panel
	if(Top10Panel != INVALID_HANDLE)
		CloseHandle(Top10Panel);
	Top10Panel = CreateTop10TimePanel();
	
	//First player finish reset
	g_Player_Racing = false;
	g_Race_Started = false;
	g_Racer_Count = 0;
	
}

public Action:EndRace(Handle:timer)
{
	if(g_Racer_Count > 0)
	{
		for(new i=1; i <= MaxClients; i++)
		{
			if(g_Player_InRace[i])
			{
				ForcePlayerSuicide(i);
				g_Player_InRace[i] = false;
			}
			if(IsClientInGame(i)) PrintToChat(i, "\x04[-]\x03 Timeout!");
		}	
	}
	g_Racer_Count = 0;
	g_Finish_Timer = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public OnPlayerFinishRace(client, bool:isfinish, minutes, Float:seconds)
{
	new String:playername[64];
	GetClientName(client, playername, sizeof(playername));
	new Float:finish_time = minutes*60 + seconds;
	
	//Check if finished or did not finish
	if(isfinish)
	{
		g_Player_InRace[client] = false;
		
		new clientCount = GetTeamClientCount(TEAM_CT);
		
		//Add race time to last times list
		for(new i = 0; i < MAX_RACE_TIMES; i++)
		{
			if(g_Player_Times[client][i] == 0.0)
			{
				g_Player_Times[client][i] = finish_time;
				break;
			}
		}
		
		//Check for first to finsih
		if(g_Race_Started) //Do not display winner or start time limit with only 1 racer
		{
			g_Race_Started = false;
			
			PrintCenterTextAll("%s won the race!", playername);
			
			new Float:timeleft = GetConVarFloat(h_rallyrace_timetofinish);
			if(clientCount > 0 && timeleft != 0)
			{
				g_Finish_Timer = CreateTimer(timeleft,EndRace,_);
				for (new i=1; i<=MaxClients; i++)
					if(g_Player_InRace[i])
						PrintToChat(i,"%.0f seconds left in the race!", timeleft);
			}
		}
			
		//Add to top time list
		if(finish_time < g_TopTime[TOP_TEN])
		{
			new place = TOP_TEN;
			if(finish_time < g_TopTime[1])
			{
				PrintToChatAll("%s - set a new fastest time!", playername);
				place = 1;
			}
			else
			{
				PrintToChat(client, "You set a new top 10 time!");
				while(place > 1)
				{
					if(finish_time < g_TopTime[place-1])
						place--;
					else break;
				}
			}
			
			//make space if needed
			if(g_TopTime[place] != MAX_TIME && place < TOP_TEN)
				PutTimeInPlace(place);
			
			g_TopTime[place] = finish_time;
			GetClientName(client, g_TopPlayerName[place], sizeof(g_TopPlayerName[]));
			GetClientAuthString(client,g_TopPlayerAuthid[place], sizeof(g_TopPlayerAuthid[]));
			g_saveTimes = true;
			
			//Recreate top 10 panel
			if(Top10Panel != INVALID_HANDLE)
				CloseHandle(Top10Panel);
			Top10Panel = CreateTop10TimePanel();
		}
		
		//Update number of racers
		g_Racer_Count--;
		
		//Show times panel to client
		if(GetConVarInt(h_rallyrace_timespopup) == 1)
			CreateTimer(1.0, AutoPopup, client);
		
		if(g_Racer_Count == 0 && g_Finish_Timer != INVALID_HANDLE)
		{
				KillTimer(g_Finish_Timer);
				g_Finish_Timer = INVALID_HANDLE;
		}
	}
	else
	{
		//Update number of racers
		if(g_Player_InRace[client])
		{
			g_Player_InRace[client] = false;
			g_Racer_Count--;
		}
		PrintToChatAll("%s is out of the race!", playername);
	
	}
}


//Update Player name if top time
public OnClientAuthorized(client)
{
	decl String:Name[64], String:Auth[64], String:buffer[64];
	new bool:changed = false;
	
	if(ClientsOpen)
	{
		GetClientAuthString(client, Auth, sizeof(Auth));
		GetClientName(client,Name,sizeof(Name));
		
		KvRewind(KvClients);
	
		if(KvJumpToKey(KvClients, Auth, true))	
		{
			KvGetString(KvClients, "name", buffer, sizeof(buffer));
			if(!StrEqual(buffer, Name))
			{	
				KvSetString(KvClients, "name", Name);
				changed = true;
			}
			KvRewind(KvClients);
		}		
		if(changed)
		{
			KeyValuesToFile(KvClients, ClientsDataFile);
			//Rebuild top time if player in it
			for(new i = 1; i<=TOP_TEN; i++)
				if(StrEqual(Auth,g_TopPlayerAuthid[i]))
				{
					g_TopPlayerName[i] = Name;
					//Create top 10 panel
					if(Top10Panel != INVALID_HANDLE)
						CloseHandle(Top10Panel);
					Top10Panel = CreateTop10TimePanel();
				}
		}
	}
}

//Show top time menu to client
public Action:TimeCommand(client, args)
{
	ShowClientTimes(client);
	return Plugin_Handled;
}

//Show top 10 time menu to client
public Action:Time10Command(client, args)
{
	if(Top10Panel != INVALID_HANDLE)
		SendPanelToClient(Top10Panel, client, EmptyHandler, MENU_TIME);
	
	return Plugin_Handled;
}


public Action:AutoPopup(Handle:timer, any:client)
{
	new MenuSource:tempmenu = GetClientMenu(client,INVALID_HANDLE);
	//Do not popup if there is another menu present
	if(tempmenu == MenuSource_None)
		ShowClientTimes(client);
	
	return Plugin_Stop;
}

//Send times panel to client
ShowClientTimes(client)
{
	if(TopTimePanel[client] != INVALID_HANDLE)
		CloseHandle(TopTimePanel[client]);
	
	TopTimePanel[client] = CreateTimePanel(client);
	
	if(TopTimePanel[client] != INVALID_HANDLE)
		SendPanelToClient(TopTimePanel[client], client, EmptyHandler, MENU_TIME);
}

//Race Time Menu
Handle:CreateTimePanel(client)
{
	decl String:Key[74];
	new Handle:TopTime = CreatePanel();

	FormatEx(Key, sizeof(Key), "%s", g_CurrentMapName);
	SetPanelTitle(TopTime, "Race times -");
	DrawPanelText(TopTime, Key);
	DrawPanelText(TopTime, " ");
	if(g_TopTime[1] == MAX_TIME)
	{
		DrawPanelText(TopTime, "No fastest time on record!");
	} 
	else 
	{
		DrawPanelText(TopTime, "Fastest:");
		new minutes = RoundToZero(g_TopTime[1]/60);
		new Float:seconds = g_TopTime[1] - (minutes * 60);
		if(seconds < 10)
			FormatEx(Key, sizeof(Key), "%s - %d:0%.2f", g_TopPlayerName[1], minutes, seconds);
		else
			FormatEx(Key, sizeof(Key), "%s - %d:%.2f", g_TopPlayerName[1], minutes, seconds);
		DrawPanelText(TopTime, Key);
	}
	DrawPanelText(TopTime, " ");
	
	//Add recent times
	new Float:timex = g_Player_Times[client][0];
	DrawPanelText(TopTime, "Last race times:");
	if(timex == 0.0)
		DrawPanelText(TopTime,"Finish the race to record a time.");
	
	for(new i = 0; i<MAX_RACE_TIMES; i++)
	{
		timex = g_Player_Times[client][i];
		if(timex != 0.0)
		{
			new minutes = RoundToZero(timex/60);
			new Float:seconds = timex - (minutes * 60);
			if(seconds < 10)
				FormatEx(Key, sizeof(Key), "%d. %d:0%.2f", i+1, minutes, seconds);
			else
				FormatEx(Key, sizeof(Key), "%d. %d:%.2f", i+1, minutes, seconds);
			DrawPanelText(TopTime, Key);
		}
	}
	DrawPanelText(TopTime, " ");
	DrawPanelItem(TopTime, "Exit", ITEMDRAW_CONTROL);
	DrawPanelItem(TopTime, "Top 10 times", ITEMDRAW_CONTROL);
	return TopTime;
}


//Race top 10 times panel
Handle:CreateTop10TimePanel()
{
	decl String:Key[74];
	new Handle:Top10Time = CreatePanel();

	FormatEx(Key, sizeof(Key), "%s", g_CurrentMapName);
	SetPanelTitle(Top10Time, "Top 10 times -");
	DrawPanelText(Top10Time, Key);
	DrawPanelText(Top10Time, " ");
	if(g_TopTime[1] == MAX_TIME)
	{
		DrawPanelText(Top10Time, "No times on record!");
	} 
	else 
	{
		for(new i = 1; i<=TOP_TEN; i++)
		{
			//if at end of list stop
			if(g_TopTime[i] == MAX_TIME) break;
			
			new minutes = RoundToZero(g_TopTime[i]/60);
			new Float:seconds = g_TopTime[i] - (minutes * 60);
			if(seconds < 10)
				FormatEx(Key, sizeof(Key), "%d. %d:0%.2f - %s", i, minutes, seconds, g_TopPlayerName[i]);
			else
				FormatEx(Key, sizeof(Key), "%d. %d:%.2f - %s", i, minutes, seconds, g_TopPlayerName[i]);
			DrawPanelText(Top10Time, Key);
		}
	}
	DrawPanelText(Top10Time, " ");
	DrawPanelItem(Top10Time, "Exit", ITEMDRAW_CONTROL);
	return Top10Time;
}


public EmptyHandler(Handle:menu, MenuAction:action, param1, param2)
{
	//If top10 selected
	if(param2 == 2 && Top10Panel != INVALID_HANDLE)
		SendPanelToClient(Top10Panel, param1, EmptyHandler, MENU_TIME);
}

//***Map race time keyvalues!***//
OnCreateKeyValues()
{
	if(KvTime != INVALID_HANDLE)
		CloseHandle(KvTime);
	if(KvClients != INVALID_HANDLE)
		CloseHandle(KvClients);
	
	KvTime = CreateKeyValues("race_times", _, _);
	KvClients = CreateKeyValues("race_clients",_,_);
	
	BuildPath(Path_SM, TimesDataFile, sizeof(TimesDataFile), "data/rallyracetimes.txt");
	BuildPath(Path_SM, ClientsDataFile, sizeof(ClientsDataFile), "data/rallyraceclients.txt");
	
	TimeOpen = FileToKeyValues(KvTime, TimesDataFile);
	ClientsOpen = FileToKeyValues(KvClients, ClientsDataFile);
}


LoadTopTimes()
{
	/* Load top race time data, if file is found */
	if(TimeOpen)
	{
		KvRewind(KvTime);

		if(KvJumpToKey(KvTime,g_CurrentMapName,false))
		{
			new String:Key[20];
			new i = 1;
			//Get top map times data
			while(TimeOpen && i <= TOP_TEN)
			{
				FormatEx(Key, sizeof(Key), "authid_%d", i);
				KvGetString(KvTime, Key, g_TopPlayerAuthid[i], sizeof(g_TopPlayerAuthid[]));
				
				if(StrEqual(g_TopPlayerAuthid[i],NULL_STRING,false)) break;
				
				//Gen client name and time
				FormatEx(Key, sizeof(Key), "time_%d", i);
				g_TopTime[i] = KvGetFloat(KvTime, Key);
				LoadClientName(i);
				
				i++;
			}
		}
		KvRewind(KvTime);
	}
	return;
}

LoadClientName(timePlace)
{
	if(ClientsOpen)
	{
		KvRewind(KvClients);

		if(KvJumpToKey(KvClients,g_TopPlayerAuthid[timePlace],false))
			KvGetString(KvClients, "name", g_TopPlayerName[timePlace], sizeof(g_TopPlayerName[]));
		KvRewind(KvClients);
	}
}

PutTimeInPlace(timePlace)
{
	new i = TOP_TEN;
	
	while(g_TopTime[i] == MAX_TIME && i > 1) i--;
		
	//Check if overwrite needed
	if(i < TOP_TEN) i++;
	
	for(;i > timePlace; i--)
	{
		g_TopPlayerAuthid[i] = g_TopPlayerAuthid[i-1];
		g_TopPlayerName[i] = g_TopPlayerName[i-1];
		g_TopTime[i] = g_TopTime[i-1];
	}
}


AddTopTimes()
{
	/* Set at top of file */
	KvRewind(KvTime);
	
	if(KvJumpToKey(KvTime, g_CurrentMapName, true))
	{
		new String:Key[20];
		for(new timePlace=1; timePlace<=TOP_TEN; timePlace++)
		{	
			if(g_TopTime[timePlace] == MAX_TIME) break;
			
			FormatEx(Key, sizeof(Key), "authid_%d", timePlace);
			KvSetString(KvTime, Key, g_TopPlayerAuthid[timePlace]);
			
			FormatEx(Key, sizeof(Key), "time_%d", timePlace);
			KvSetFloat(KvTime, Key, g_TopTime[timePlace]);
			
			AddClient(timePlace);
		}
	}
	/* Need to be at the top of the file to before writing */
	KvRewind(KvTime);
	KeyValuesToFile(KvTime, TimesDataFile);
}

AddClient(timePlace)
{
	KvRewind(KvClients);
	
	if(KvJumpToKey(KvClients, g_TopPlayerAuthid[timePlace], true))	
		KvSetString(KvClients, "name", g_TopPlayerName[timePlace]);
	
	/* Need to be at the top of the file to before writing */
	KvRewind(KvClients);
	KeyValuesToFile(KvClients, ClientsDataFile);
	
}

//Update from old data 'rallyracetop.txt' version 1.0
UpdateData()
{
	//Check if update needed
	if(ClientsOpen)
	{
		KvRewind(KvClients);
		if(KvGotoFirstSubKey(KvClients))
		{
			KvRewind(KvClients);
			return;
		}
	}
	
	new String:OldDataFile[PLATFORM_MAX_PATH];
	new Handle:KvOld = CreateKeyValues("race_top", _, _);
	BuildPath(Path_SM, OldDataFile, sizeof(OldDataFile), "data/rallyracetop.txt");
	new bool:OldOpen = FileToKeyValues(KvOld, OldDataFile);
	
	if(OldOpen)
	{
		KvRewind(KvOld);

		// Go to first SubKey
		if(!KvGotoFirstSubKey(KvOld))
			return;

		while(OldOpen)
		{
			if(!KvGetSectionName(KvOld, g_CurrentMapName, sizeof(g_CurrentMapName)))
			{
				break;
			}
			//Get top map time player info
			KvGetString(KvOld, "authid", g_TopPlayerAuthid[1], sizeof(g_TopPlayerAuthid[]));
			KvGetString(KvOld, "name", g_TopPlayerName[1], sizeof(g_TopPlayerName[]));
			g_TopTime[1] = KvGetFloat(KvOld, "time");
			
			AddTopTimes();

			if(!KvGotoNextKey(KvOld))
				break;
		}
		KvRewind(KvOld);
		CloseHandle(KvOld);
		
		//Reopen keyvales
		OnCreateKeyValues();
	}
}


/*
PruneClients()
{

To be completed. Removes clients no longer in any top 10 record.
	
}
*/
 /* TODO V2.0
 -Prune clients no longer in any top10 record
 -Translations file
 -Update player name in times list on 'name change'
 * Save on round end/map end
 -Add on-screen finish countdown
 -Add real time updating for top10 if menu open
 * */ 
 