/**
* Phys Kill Ranks
*
* Description:
*	Ranks all phys killers into PhysKill_Ranks.txt found in the cfg/ folder
*
* Commands:
* sm_physranks_version : Prints current version
* sm_physranks_enable (1/0) : Enables/Disables plugin
* PhysRank (Chat command) : Prints PhysKill ranks
* PhysTop (Chat command) : Creates a menu to display all players who have PhysKill ranks
*
*	
*  
* Version History
*	1.5 Fixed a case where player ranks wernt sorted correctly
*	1.1 Fixed some physics objects not registering as a phys object kill
* 	1.0 Working version
* Contact:
* Ice: Alex_leem@hotmail.com
* Hidden:Source: http://forum.hidden-source.com/
*/

// General includes
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

new FileLength = 0;
new RankMenu = 0;
new MenuSelect[7];

new String:SteamIDKiller[64];
new String:SteamID[500][64];
new Rank[500];
new Kills[500];
new String:Name[500][64];

// 2 is IRIS's unique team ID so define it
#define HDN_TEAM_IRIS	2
#define CD_VERSION "1.5.0"
#define MAX_FILE_LEN 80

new Handle:cvarEnable;
new bool:g_isHooked;

public Plugin:myinfo = 
{
	name = "PhysKill Ranks",
	author = "Ice",
	description = "Ranks all phys killers",
	version = CD_VERSION,
	url = "http://www.google.com"
};

public OnPluginStart()
{
	CreateConVar("sm_physranks_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_physranks_enable","1","Enable/disable phys kill ranking",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	CreateTimer(3.0, OnPluginStart_Delayed);
	CreateTimer(3.0, OpenPhysRanks_Delayed);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	FileLength = 0;
}

public Action:OnPluginStart_Delayed(Handle:timer){
	if(GetConVarInt(cvarEnable) > 0)
	{
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
		HookEvent("game_round_end",ev_RoundEnd);
		
		// Lets hook the plugin enable so it can be disabled at any time
		HookConVarChange(cvarEnable,PhysRankCvarChange);
		
		LogMessage("[PhysKillRanks] - Loaded");
	}
}

public PhysRankCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
// Okay someone changed the plugin enable cvar lets see if they turned it on or off
	if(GetConVarInt(cvarEnable) <= 0)
	{
		if(g_isHooked)
		{
		g_isHooked = false;
		UnhookEvent("player_death",ev_PlayerDeath);
		UnhookEvent("game_round_start",ev_RoundEnd);
		}
	}
	else if(!g_isHooked)
	{
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
		HookEvent("game_round_start",ev_RoundEnd);
	}
}

bool:IsPlayer(client) {
	if (client >= 1 && client <= MaxClients) {
		if(IsValidEntity(client) && !IsFakeClient(client) && IsClientConnected(client) && IsClientInGame(client)){
			return true;
		}
	}
	return false;
}

public Action:OpenPhysRanks_Delayed(Handle:timer){
	new String:strPath[256];
	new Handle:PhysStats = OpenFile("/cfg/physkill_ranks.txt","r");
	
	if(PhysStats == INVALID_HANDLE)
	{
		SetFailState("Failed to open file: %s", strPath);
		return;
	}
	
	new String:strLine[500];
	new i = 0;
	
	while(!IsEndOfFile(PhysStats))
	{
		new String:strBreak[4][64];
		
		ReadFileLine(PhysStats, strLine, sizeof(strLine));
		
		ExplodeString(strLine, ",",strBreak, sizeof(strBreak), sizeof(strBreak[]));
		
		//Handle Split strings
		for(new q = 0; q < sizeof(strBreak[]); q++)
			{
			SteamID[i][q] = strBreak[2][q];
			}
		for(new q = 0; q < sizeof(strBreak[]); q++)
			{
			Name[i][q] = strBreak[3][q];
			}
		
		Rank[i] = StringToInt(strBreak[0][0],10);
		Kills[i] = StringToInt(strBreak[1][0],10);
		TrimString(SteamID[i]);
		TrimString(Name[i]);
		
		FileLength++;
		i++;
	}
	
	//Take 1 so it starts at 0, and another for the re-read due to writing a empty space
	FileLength -= 2;
	CloseHandle(PhysStats);
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}

	// Get some info about who killed who
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	GetClientAuthString(killer, SteamIDKiller, sizeof(SteamIDKiller));
	
	new String:killerName[100];
	new String:victimName[100];
	new String:weapon[64];
	
	GetEventString(event,"weapon",weapon,sizeof(weapon));
	if(IsPlayer(victim) && IsPlayer(killer) && (killer != victim) && (GetClientTeam(victim) == HDN_TEAM_IRIS) && (GetClientTeam(killer) != HDN_TEAM_IRIS))
	{
		if(StrEqual(weapon,"physics") || StrEqual(weapon,"physics_respawnable") || StrEqual(weapon,"physics_multiplayer"))
		{
		// Okay a hidden has killed an IRIS with physics
		GetClientName(killer,killerName,100);
		GetClientName(victim,victimName,100);
		new LineNumber = 0;
		new p = 0;
		while(p <= FileLength)
		{
			if(StrEqual(SteamID[p],SteamIDKiller))
			{
				// Add 1 to line number so that if it found line 0 it produces a 1, so that i can check to see if it found nothing
				// REDUCE THIS NUMBER BY 1 LATER!!
				LineNumber = p + 1;
				// Line found and stored, break loop
				p = 500;
			}
			p++;
		}
		if(LineNumber == 0)
			{
				//Nothing found!
				// New Player
				if (Rank[0] != 1)
				{
					//Must be a blank file! Start the first rank
					FileLength++;
					Rank[0] = 1;
					Kills[0] = 1;
					strcopy(SteamID[0],sizeof(SteamIDKiller),SteamIDKiller);
					strcopy(Name[0],sizeof(killerName),killerName);
				}else
				{
					FileLength++;
					Rank[FileLength] = Rank[FileLength - 1] + 1;
					Kills[FileLength] = 1;
					strcopy(SteamID[FileLength],sizeof(SteamIDKiller),SteamIDKiller);
					strcopy(Name[FileLength],sizeof(killerName),killerName);
				}
			}
			else
			{
				LineNumber--;
				Kills[LineNumber]++;
				
				//Update Name
				strcopy(Name[LineNumber],sizeof(killerName),killerName);
			
				if(Kills[LineNumber] > Kills[LineNumber-1])
				{
					//Someone has beaten the previous guys rank, lets swap places
					new KillsTemp;
					new String:SteamTemp[64];
					new String:NameTemp[64];
				
					KillsTemp = Kills[LineNumber];
					strcopy(SteamTemp,sizeof(SteamID[]),SteamID[LineNumber]);
					strcopy(NameTemp,sizeof(Name[]),Name[LineNumber]);
									
					Kills[LineNumber] = Kills[LineNumber-1];
					strcopy(SteamID[LineNumber],sizeof(SteamID[]),SteamID[LineNumber - 1]);
					strcopy(Name[LineNumber],sizeof(Name[]),Name[LineNumber - 1]);

		
					Kills[LineNumber-1] = KillsTemp;
					strcopy(SteamID[LineNumber - 1],sizeof(SteamTemp),SteamTemp);
					strcopy(Name[LineNumber - 1],sizeof(NameTemp),NameTemp);
				}
			}
		}
	}
}

public Action:Command_Say(client, args)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return Plugin_Continue;
	}

	// Get as little info as possible here
	new String:Chat[64];
	GetCmdArgString(Chat, sizeof(Chat));
	
	new startidx;
	if (Chat[strlen(Chat)-1] == '"')
	{
		Chat[strlen(Chat)-1] = '\0';
		startidx = 1;
	}
	
	if (strcmp(Chat[startidx],"PhysRank", false) == 0)
		{
			new p = 0;
			new String:SteamIDChat[64];
			new String:ClientName[100];
			
			GetClientAuthString(client, SteamIDChat, sizeof(SteamIDChat));
			GetClientName(client,ClientName,sizeof(ClientName));
			
			new LineNumber = 0;
			
			while(p <= FileLength)
			{
				if(StrEqual(SteamID[p],SteamIDChat))
				{
					// Add 1 to line number so that if it found line 0 it produces a 1, so that i can check to see if it found nothing
					// REDUCE THIS NUMBER BY 1 LATER!!
					LineNumber = p + 1;
					// Line found and stored, break loop
					p = 500;
				}
				p++;
			}
			if(LineNumber == 0)
			{
				//Nothing found!
				PrintToChatAll("\x04[PhysRanks] Player %s has no Phys Kills yet!",ClientName);
			}
			else
			{
				new TotalPlayers = FileLength + 1;
				PrintToChatAll("\x04[PhysRanks] Player %s is ranked %d/%d with %d PhysKills!",ClientName,LineNumber,TotalPlayers,Kills[LineNumber-1]);
			}
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"PhysTop", false) == 0)
		{
			RankMenu = 0;
			new Player = client;
			PrintTopScoresToClient(Player);
			return Plugin_Continue;
		}
		else{
		return Plugin_Continue;
		}
}

public ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
// Round started, so lets write new stats
	new String:strPath[256];
	
	new Handle:PhysStats = OpenFile("/cfg/physkill_ranks.txt","w");
	if(PhysStats == INVALID_HANDLE)
		{
			SetFailState("Failed to open file: %s", strPath);
			return;
		}
	
	for(new i = 0; i <= FileLength; i++)
	{
		if(i != FileLength)
		{
			if(Kills[i] < Kills[i+1])
			{
				//Someone is ranked less than the next guy and hasnt been corrected, lets correct it
				new KillsTemp;
				new String:SteamTemp[64];
				new String:NameTemp[64];
					
				KillsTemp = Kills[i];
				strcopy(SteamTemp,sizeof(SteamID[]),SteamID[i]);
				strcopy(NameTemp,sizeof(Name[]),Name[i]);
								
				Kills[i] = Kills[i + 1];
				strcopy(SteamID[i],sizeof(SteamID[]),SteamID[i + 1]);
				strcopy(Name[i],sizeof(Name[]),Name[i + 1]);

			
				Kills[i + 1] = KillsTemp;
				strcopy(SteamID[i + 1],sizeof(SteamTemp),SteamTemp);
				strcopy(Name[i + 1],sizeof(NameTemp),NameTemp);
			}
		}
		new String:strLine[500];
		
		Format(strLine,sizeof(strLine),"%d,%d,%s,%s",Rank[i],Kills[i],SteamID[i],Name[i]);
		WriteFileLine(PhysStats, strLine, sizeof(strLine));
	}
	CloseHandle(PhysStats);
}

PrintTopScoresToClient(client)
{
	//2. build panel
	new Handle:TopScores = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	
	new RankMenuTotal = RankMenu + 7;
	
	new String:Previous[32];
	new String:Next[32];
	Format(Previous,sizeof(Previous),"Previous");
	Format(Next,sizeof(Next),"Next");
	DrawPanelItem(TopScores, Previous,ITEMDRAW_DEFAULT);
	DrawPanelItem(TopScores, Next,ITEMDRAW_DEFAULT);
	new a = 0;
	
	// If the first rank is read as 1 then it must be a valid read so lets render!
	if(Rank[0] == 1)
	{
		while(RankMenu < RankMenuTotal)
		{
		if(RankMenu < FileLength + 1)
			{
			new String:Text[64];
			Format(Text,sizeof(Text), "%d. %s",Rank[RankMenu],Name[RankMenu]);
			DrawPanelItem(TopScores, Text, ITEMDRAW_DEFAULT);
			MenuSelect[a] = RankMenu;
			RankMenu++;
			a++;
			}
			else{
			RankMenu = RankMenuTotal;
			}
		}
	}
	
	//3. print panel
	SetPanelTitle(TopScores, "Top PhysKillers: \nClick a name to have \ninformation printed to console");
	
	SendPanelToClient(TopScores, client, TopScoresHandler, 30);
	
	CloseHandle(TopScores);
}

public TopScoresHandler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
	{
		if (param2==1) //Previous
		{
			if(RankMenu <= 7)
			{
			RankMenu = 0;
			PrintTopScoresToClient(param1);
			}
			else{
			RankMenu -= 13;
			PrintTopScoresToClient(param1);
			}
			
		} else if (param2==2) //Next
		{
			if(RankMenu - 2 < FileLength)
			{
			RankMenu--;
			PrintTopScoresToClient(param1);
			}
			else{
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
			}
		}
		else if (param2==3) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[0]], SteamID[MenuSelect[0]], Rank[MenuSelect[0]], Kills[MenuSelect[0]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
		else if (param2==4) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[1]], SteamID[MenuSelect[1]], Rank[MenuSelect[1]], Kills[MenuSelect[1]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
		else if (param2==5) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[2]], SteamID[MenuSelect[2]], Rank[MenuSelect[2]], Kills[MenuSelect[2]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
		else if (param2==6) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[3]], SteamID[MenuSelect[3]], Rank[MenuSelect[3]], Kills[MenuSelect[3]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
		else if (param2==7) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[4]], SteamID[MenuSelect[4]], Rank[MenuSelect[4]], Kills[MenuSelect[4]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
		else if (param2==8) //Next
		{
			PrintToConsole(param1, "%s (%s) is ranked %d with %d phys kills", Name[MenuSelect[5]], SteamID[MenuSelect[5]], Rank[MenuSelect[5]], Kills[MenuSelect[5]]);
			RankMenu = MenuSelect[0];
			PrintTopScoresToClient(param1);
		}
	}
} 