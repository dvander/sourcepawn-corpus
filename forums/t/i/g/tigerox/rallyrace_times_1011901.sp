
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <rallyrace>

#define  RALLYRACE_TIMES_VERSION			"1.0"

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
//  	- ConVar rallyrace_timetofinish to control timeout seconds.
//Added auto times popup on race finish
//Added player win and fell out of race announcement

#define		MAX_TIME		100000.0
#define		MENU_TIME		20
#define		MAX_RACE_TIMES	10
#define		TEAM_CT			3

/* Contains the race time data */
new String:TimeFile[PLATFORM_MAX_PATH];
new Handle:KvTime = INVALID_HANDLE;
new bool:TimeOpen;

//Finish timeout var
new Handle:h_rallyrace_timetofinish;

//Top map time vars
new Float:g_TopTime;
new String:g_TopPlayerAuthid[64]; 
new String:g_TopPlayerName[64];
new String:g_CurrentMapName[64];

//Times menu
new Handle:TopTimePanel[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Float:g_Player_Times[MAXPLAYERS+1][MAX_RACE_TIMES];

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
	
	RegConsoleCmd("times", TimeCommand);
	
	HookEvent("player_death",OnPlayerDeath);
	
	OnCreateKeyValues();
	
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
	//Get top time map info
	GetCurrentMap(g_CurrentMapName, sizeof(g_CurrentMapName));
	if(!LoadTopTime())
		g_TopTime = MAX_TIME;
	
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
			
			//Add to top time list
			if(finish_time < g_TopTime)
			{
				PrintToChatAll("%s - set a new fastest time!", playername);
				g_TopTime = finish_time;
				GetClientName(client, g_TopPlayerName, sizeof(g_TopPlayerName));
				GetClientAuthString(client,g_TopPlayerAuthid, sizeof(g_TopPlayerAuthid));
				AddTopTime();
			}
		}
		
		//Update number of racers
		g_Racer_Count--;
		
		//Show times panel to client
		if(g_Racer_Count > 0)
			CreateTimer(1.0, AutoPopup, client);
		else
		{
			if(g_Finish_Timer != INVALID_HANDLE)
			{
				KillTimer(g_Finish_Timer);
				g_Finish_Timer = INVALID_HANDLE;
			}
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
	
	if(TimeOpen)
	{
		GetClientAuthString(client, Auth, sizeof(Auth));
		GetClientName(client,Name,sizeof(Name));
		
		KvRewind(KvTime);
		
		if(!KvGotoFirstSubKey(KvTime))
			return;
		
		while(TimeOpen)
		{	
			KvGetString(KvTime, "authid", buffer, sizeof(buffer));
			if(StrEqual(buffer, Auth))
			{
				KvGetString(KvTime, "name", buffer, sizeof(buffer));
				if(!StrEqual(buffer, Name))
				{	
					KvSetString(KvTime, "name", Name);
					changed = true;
				}
			}
			
			if(!KvGotoNextKey(KvTime))
				break;
		}
		KvRewind(KvTime);
		
		if(changed)
		{
			KeyValuesToFile(KvTime, TimeFile);
			//Rebuild top time list
			LoadTopTime();
		}
	}
}

//Show top time menu to client
public Action:TimeCommand(client, args)
{
	ShowClientTimes(client);
	return Plugin_Handled;
}

public Action:AutoPopup(Handle:timer, any:client)
{
	ShowClientTimes(client);
	return Plugin_Stop;
}

//Send times panel to client
ShowClientTimes(client)
{
	if(TopTimePanel[client] != INVALID_HANDLE)
		CloseHandle(TopTimePanel[client]);
	
	TopTimePanel[client] = CreateTopTimePanel(client);
	
	if(TopTimePanel[client] != INVALID_HANDLE)
		SendPanelToClient(TopTimePanel[client], client, EmptyHandler, MENU_TIME);
}

//Race Time Menu
Handle:CreateTopTimePanel(client)
{
	decl String:Key[74];
	new Handle:TopTime = CreatePanel();

	FormatEx(Key, sizeof(Key), "%s", g_CurrentMapName);
	SetPanelTitle(TopTime, "Race times -");
	DrawPanelText(TopTime, Key);
	DrawPanelText(TopTime, " ");
	if(g_TopTime == MAX_TIME)
	{
		DrawPanelText(TopTime, "No time for this map yet!");
	} 
	else 
	{
		DrawPanelText(TopTime, "Fastest:");
		new minutes = RoundToZero(g_TopTime/60);
		new Float:seconds = g_TopTime - (minutes * 60);
		if(seconds < 10)
			FormatEx(Key, sizeof(Key), "%s - %d:0%.2f", g_TopPlayerName, minutes, seconds);
		else
			FormatEx(Key, sizeof(Key), "%s - %d:%.2f", g_TopPlayerName, minutes, seconds);
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
	return TopTime;
}

public EmptyHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* Don't care what they pressed. */
}


//***Map race time keyvalues!***//
OnCreateKeyValues()
{
	KvTime = CreateKeyValues("race_top", _, _);
	BuildPath(Path_SM, TimeFile, sizeof(TimeFile), "data/rallyracetop.txt");
	TimeOpen = FileToKeyValues(KvTime, TimeFile);
}

bool:LoadTopTime()
{
	new bool:gotTime = false;
	
	/* Load top race time data, if file is found */
	if(TimeOpen)
	{
		KvRewind(KvTime);

		// Go to first SubKey
		if(!KvGotoFirstSubKey(KvTime))
			return false;

		new String:MapName[64];

		while(TimeOpen)
		{
			if(!KvGetSectionName(KvTime, MapName, sizeof(MapName)))
			{
				break;
			}
			
			if(StrEqual(MapName, g_CurrentMapName))
			{
				//Get top map time player info
				KvGetString(KvTime, "authid", g_TopPlayerAuthid, sizeof(g_TopPlayerAuthid));
				KvGetString(KvTime, "name", g_TopPlayerName, sizeof(g_TopPlayerName));
				g_TopTime = KvGetFloat(KvTime, "time");
				gotTime = true;
				break;
			}

			if(!KvGotoNextKey(KvTime))
			{
				break;
			}
		}

		KvRewind(KvTime);
	}
	return gotTime;
}

AddTopTime()
{
	/* Set at top of file */
	KvRewind(KvTime);
	
	if(KvJumpToKey(KvTime, g_CurrentMapName, true))
	{
		KvSetString(KvTime, "authid", g_TopPlayerAuthid);
		KvSetString(KvTime, "name", g_TopPlayerName);
		KvSetFloat(KvTime, "time", g_TopTime);
	}
	/* Need to be at the top of the file to before writing */
	KvRewind(KvTime);
	KeyValuesToFile(KvTime, TimeFile);
}