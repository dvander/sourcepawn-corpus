/**
* Hidden Ranks
*
* Description:
*	Ranks all players depending on
*		1. Who they kill
*		2. How they kill
*		3. What team they kill
*		4. How they die
*		5. Who kills them
*		6. Whether they used a handicap (optional)
*
* Rank file is read as Rank,Points,IRISPoints,HiddenPoints,IRISKills,IRISDeaths,HiddenKills,PhysKills,PigSticks,HiddenDeaths,Suicides,TeamKills,DamageDone,GameTimeMinutes,SteamID,Name
* 
* Commands:
* sm_hiddenranks_version : Prints current version
* sm_hiddenranks_enable (1/0) : Enables/Disables plugin
* sm_hiddenranks_irismult : Determines the points multiplier used for an IRIS kill
* sm_hiddenranks_knifemult : Determines the points multiplier used for a Hidden knife kill
* sm_hiddenranks_pigmult : Determines the points multiplier used for a Hidden pigstick kill
* sm_hiddenranks_physmult : Determines the points multiplier used for a Hidden physics kill
* sm_hiddenranks_ranksuicides : If set to more than 0, the plugin will take the specified amount of points off and add to the deaths stat
* sm_hiddenranks_multbykd : If set to 1, the plugin will give include a k/d ratio multiplier when calculating points
* 							This results in it easier to keep a high rank (high k/d) and harder for lower ranked people (low k/d) to earn points
* sm_hiddenranks_usehandicapplugin : If set to 1, the plugin will include a points multiplier for a handicapped hidden
* sm_hiddenranks_handicapchangetime : The window of opportunity in seconds, that the hidden can handicap himself and have it effect his rank. 
*									  This stops a hidden from handicapping himself and finishing people off for points
* sm_hiddenranks_irisdeathmult : Determines the points reduction multiplier used for an IRIS death
* sm_hiddenranks_hiddendeathmult : Determines the points reduction multiplier used for a Hidden death
* sm_hiddenranks_irismaxpoints : Determines the maximum points an IRIS can accumilate from 1 kill
* sm_hiddenranks_hiddenmaxpoints : Determines the maximum points a Hidden can accumilate from 1 kill
* sm_hiddenranks_iristeamkillpoints : Determines the points you loose from team killing on the iris team
* sm_hiddenranks_hiddenteamkillpoints : Determines the points you loose from team killing on the hidden team
* sm_hiddenranks_countbotkills : Will count bot kills, use this for testing but be aware that listen servers dont report bot deaths properly
*
* Rank (Chat command) : Prints your rank
* IRISRank (Chat command) : Prints your IRIS rank (Taken from the start of the map)
* HiddenRank (Chat command) : Prints your Hidden rank (Taken from the start of the map)
* Top (Chat command) : Creates a menu to display all players who have ranks
* IRISTop (Chat command) : Creates a menu to display all players who have ranks and arranges it by IRIS points (Taken from the start of the map)
* HiddenTop (Chat command) : Creates a menu to display all players who have ranks and arranges it by Hidden points (Taken from the start of the map)
* !ResetRank (Chat command) : Resets your rank
*
*	
*  
* Version History
*	1.0 Release
*	0.75 Various pre release fixes, additions, adjustments, testings
*	0.5 Changed points system, added more functions
* 	0.1 First alpha release
* Contact:
* Ice: Alex_leem@hotmail.com
* Hidden:Source: http://forum.hidden-source.com/
*/

// General includes
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>


//Strings
new String:SteamID[500][64];
new String:Name[500][64];
new String:IRISRankID[500][64];
new String:HiddenRankID[500][64];
new String:IRISRankName[500][64];
new String:HiddenRankName[500][64];

//Integers
new Rank[500];
new IRISRank[500];
new HiddenRank[500];
new Points[500];
new HiddenPoints[500];
new IRISPoints[500];
new IRISKills[500];
new HiddenKills[500];
new IRISDeaths[500];
new HiddenDeaths[500];
new PhysKills[500];
new PigSticks[500];
new DamageDone[500];
new TeamKills[500];
new GameTime[500];
new GameTimeMinutes[500];
new Suicides[500];
new HasAlreadyHandicapped;
new CurrentTime1;
new CurrentTime2;
new PigStickAttack;
new FileLength = 0;
new RankMenu = 0;
new MenuSelect[7];
new HiddenMenu = 0;
new IRISMenu = 0;

//Floats
new Float:ReducedHealthMult;
new Float:ReducedDamageMult;
new Float:DruggedMult;

// Defines
#define HDN_TEAM_IRIS	2
#define HDN_TEAM_HIDDEN 3
#define CD_VERSION "1.0.0"
#define MAX_FILE_LEN 80


//Handles
new Handle:cvarEnable;
new Handle:GrenadeMultiply;
new Handle:IRISDeathMultiply;
new Handle:HiddenDeathMultiply;
new Handle:IRISMaxPoints;
new Handle:HiddenMaxPoints;
new Handle:IRISTeamKillPoints;
new Handle:HiddenTeamKillPoints;
new Handle:IRISMultiply;
new Handle:KnifeMultiply;
new Handle:PigMultiply;
new Handle:PhysicsMultiply;
new Handle:Suicidepoints;
new Handle:TimesByRatio;
new Handle:UseHandicap;
new Handle:HandiCapWindow;
new Handle:ReducedDamage;
new Handle:ReducedHealth;
new Handle:CountBotKills;
new Handle:Drugged;
new Handle:HandiCapEnabled;
new bool:g_isHooked;

public Plugin:myinfo = 
{
	name = "hiddenranks",
	author = "Ice",
	description = "Ranks players",
	version = CD_VERSION,
	url = "http://forum.hidden-source.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_hiddenranks_version", CD_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	cvarEnable = CreateConVar("sm_hiddenranks_enable","1","Enable/disable phys kill ranking",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	
	IRISMultiply = CreateConVar("sm_hiddenranks_irismult","12.0","Determines the points multiplier used for an IRIS kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	KnifeMultiply = CreateConVar("sm_hiddenranks_knifemult","8.0","Determines the points multiplier used for a Hidden knife kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	PigMultiply = CreateConVar("sm_hiddenranks_pigmult","4.0","Determines the points multiplier used for a Hidden pigstick kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	PhysicsMultiply = CreateConVar("sm_hiddenranks_physmult","12.0","Determines the points multiplier used for a Hidden physics kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	Suicidepoints = CreateConVar("sm_hiddenranks_ranksuicides","0.0","The amount of points lost for commiting suicide by directly hurting yourself, ie a suicide not caused by world damage. If set to 0, no points or kills will be altered except the suicide stat",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	TimesByRatio = CreateConVar("sm_hiddenranks_multbykd","0.0","If set to 1, the plugin will give include a k/d ratio multiplier when calculating points",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	UseHandicap = CreateConVar("sm_hiddenranks_usehandicapplugin","0.0","If set to 1, the plugin will include a points multiplier for a handicapped hidden",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	HandiCapWindow = CreateConVar("sm_hiddenranks_handicapchangetime","15.0","The window of opportunity in seconds, that the hidden can handicap himself and have it effect his rank. This stops a hidden from handicapping himself and finishing people off for points",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	IRISDeathMultiply = CreateConVar("sm_hiddenranks_irisdeathmult","7.0","Determines the points reduction multiplier used for an IRIS death",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	HiddenDeathMultiply = CreateConVar("sm_hiddenranks_hiddendeathmult","5.0","Determines the points reduction multiplier used for a Hidden death",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	IRISMaxPoints = CreateConVar("sm_hiddenranks_irismaxpoints","18.0","Determines the maximum points an IRIS can accumilate from 1 kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	HiddenMaxPoints = CreateConVar("sm_hiddenranks_hiddenmaxpoints","18.0","Determines the maximum points a Hidden can accumilate from 1 kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	IRISTeamKillPoints = CreateConVar("sm_hiddenranks_iristeamkillpoints","20.0","Determines the points you loose from team killing on the iris team",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	HiddenTeamKillPoints = CreateConVar("sm_hiddenranks_hiddenteamkillpoints","40.0","Determines the points you loose from team killing on the hidden team",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	CountBotKills = CreateConVar("sm_hiddenranks_countbotkills","0.0","Will count bot kills, use this for testing but be aware that listen servers dont report bot deaths properly",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	GrenadeMultiply = CreateConVar("sm_hiddenranks_grenademult","5.0","Determines the points multiplier used for a Hidden grenade kill",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,false);
	
	CreateTimer(3.0, OnPluginStart_Delayed);
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
		HookEvent("player_hurt",ev_PlayerHurt);
		HookEvent("game_round_start",ev_RoundStart);
		
		// Lets hook the plugin enable so it can be disabled at any time
		HookConVarChange(cvarEnable,EnableRankCvarChange);
		
		LogMessage("[HiddenRanks] - Loaded");
	}
	if(GetConVarInt(UseHandicap) > 0){
		ReducedDamage = FindConVar("hsm_handicap_damagereduction");
		HookConVarChange(ReducedDamage,ReducedDamageChange);
		ReducedHealth = FindConVar("hsm_handicap_healthreduction");
		HookConVarChange(ReducedHealth,ReducedHealthChange);
		Drugged = FindConVar("hsm_handicap_isdrugged");
		HandiCapEnabled = FindConVar("hsm_handicap_enable");
		HookConVarChange(Drugged,DruggedChange);
	}
	ReducedHealthMult = 1.0;
	ReducedDamageMult = 1.0;
	DruggedMult = 1.0;
}

public EnableRankCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
// Okay someone changed the plugin enable cvar lets see if they turned it on or off
	if(GetConVarInt(cvarEnable) <= 0)
	{
		if(g_isHooked)
		{
		g_isHooked = false;
		UnhookEvent("player_death",ev_PlayerDeath);
		UnhookEvent("game_round_end",ev_RoundEnd);
		UnhookEvent("player_hurt",ev_PlayerHurt);
		UnhookEvent("game_round_start",ev_RoundStart);
		}
	}
	else if(!g_isHooked)
	{
		g_isHooked = true;
		HookEvent("player_death",ev_PlayerDeath);
		HookEvent("game_round_end",ev_RoundEnd);
		HookEvent("player_hurt",ev_PlayerHurt);
		HookEvent("game_round_start",ev_RoundStart);
	}
}

bool:IsPlayer(client) {
	if (client >= 1 && client <= MaxClients) {
		if(GetConVarInt(CountBotKills) < 1 && IsClientConnected(client) && IsClientInGame(client)){
			if(!IsFakeClient(client)){
				return true;
			}
		} else if(GetConVarInt(CountBotKills) > 0 && IsClientInGame(client) && IsClientConnected(client)){
		return true;
		}
	}
	return false;
}

public Action:OpenRanks_Delayed(Handle:timer){
	new String:strPath[256];
	new Handle:HiddenStats = OpenFile("/cfg/hiddenranks_ranks.txt","r");
	
	if(HiddenStats == INVALID_HANDLE)
	{
		SetFailState("Failed to open file: %s", strPath);
		return;
	}
	
	new String:strLine[1024];
	new i;
	i = 0;
	FileLength = 0;
	
	while(!IsEndOfFile(HiddenStats))
	{
		new String:strBreak[16][64];
		
		ReadFileLine(HiddenStats, strLine, sizeof(strLine));
		
		ExplodeString(strLine, ",",strBreak, sizeof(strBreak), sizeof(strBreak[]));
		
		//Handle Split strings
		for(new q = 0; q < sizeof(strBreak[]); q++)
			{
			SteamID[i][q] = strBreak[14][q];
			}
		for(new q = 0; q < sizeof(strBreak[]); q++)
			{
			Name[i][q] = strBreak[15][q];
			}
		
		Rank[i] = StringToInt(strBreak[0][0],10);
		Points[i] = StringToInt(strBreak[1][0],10);
		IRISPoints[i] = StringToInt(strBreak[2][0],10);
		HiddenPoints[i] = StringToInt(strBreak[3][0],10);
		IRISKills[i] = StringToInt(strBreak[4][0],10);
		IRISDeaths[i] = StringToInt(strBreak[5][0],10);
		HiddenKills[i] = StringToInt(strBreak[6][0],10);
		PhysKills[i] = StringToInt(strBreak[7][0],10);
		PigSticks[i] = StringToInt(strBreak[8][0],10);
		HiddenDeaths[i] = StringToInt(strBreak[9][0],10);
		Suicides[i] = StringToInt(strBreak[10][0],10);
		TeamKills[i] = StringToInt(strBreak[11][0],10);
		DamageDone[i] = StringToInt(strBreak[12][0],10);
		GameTime[i] = StringToInt(strBreak[13][0],10);
		GameTimeMinutes[i] = GameTime[i];
		GameTime[i] *= 60;
		
		TrimString(SteamID[i]);
		TrimString(Name[i]);
		
		IRISRank[i] = IRISPoints[i];
		HiddenRank[i] = HiddenPoints[i];
		strcopy(IRISRankID[i],sizeof(SteamID[]),SteamID[i]);
		strcopy(HiddenRankID[i],sizeof(SteamID[]),SteamID[i]);
		strcopy(IRISRankName[i],sizeof(Name[]),Name[i]);
		strcopy(HiddenRankName[i],sizeof(Name[]),Name[i]);
		
		FileLength++;
		i++;
	}
	
	//Take 1 so it starts at 0, and another for the re-read due to writing an empty space
	if(FileLength >= 2){
		FileLength -= 2;
	} else{
		FileLength = 0;
	}
	CloseHandle(HiddenStats);
	
	//God knows why this is necissary! Buggy sourcemod...
	if (Points[0] > 0){
		Rank[0] = 1;
	}
}

public OnMapStart(){
	CreateTimer(1.0, OpenRanks_Delayed);
	CreateTimer(3.0, SortRanks_Delayed);
}


public Action:SortRanks_Delayed(Handle:timer){
	for(new q = 0; q < FileLength; q++)
	{
		if(Points[q] < Points[q + 1] && q != FileLength)
			{
				SortRanks(q);
				if(q >= 2){
					q -= 2;
				}
			}
	}
	SortIrisHiddenPoints();
}

SortIrisHiddenPoints(){
	new que = 0;
	while(que < FileLength)
	{
		if(HiddenRank[que] < HiddenRank[que + 1])
		{
			new HiddenRankTemp2 = HiddenRank[que];
			new String:HiddenRankNameTemp[64];
			new String:HiddenRankTrackerTemp[64];
			strcopy(HiddenRankNameTemp,sizeof(HiddenRankName[]),HiddenRankName[que]);
			strcopy(HiddenRankName[que],sizeof(HiddenRankName[]),HiddenRankName[que + 1]);
			strcopy(HiddenRankName[que + 1],sizeof(HiddenRankNameTemp),HiddenRankNameTemp);
			strcopy(HiddenRankTrackerTemp,sizeof(HiddenRankID[]),HiddenRankID[que]);
			strcopy(HiddenRankID[que],sizeof(HiddenRankID[]),HiddenRankID[que + 1]);
			strcopy(HiddenRankID[que + 1],sizeof(HiddenRankTrackerTemp),HiddenRankTrackerTemp);
			HiddenRank[que] = HiddenRank[que + 1];
			HiddenRank[que + 1] = HiddenRankTemp2;
			if(que >= 1){
				que -= 2;
			}
		}
		que++;
	}
	que = 0;
	while(que < FileLength)
	{
		if(IRISRank[que] < IRISRank[que + 1])
			{
				new IRISRankTemp2 = IRISRank[que];
				new String:IRISRankTrackerTemp[64];
				new String:IRISRankNameTemp[64];
				strcopy(IRISRankNameTemp,sizeof(IRISRankName[]),IRISRankName[que]);
				strcopy(IRISRankName[que],sizeof(IRISRankName[]),IRISRankName[que + 1]);
				strcopy(IRISRankName[que + 1],sizeof(IRISRankNameTemp),IRISRankNameTemp);
				strcopy(IRISRankTrackerTemp,sizeof(IRISRankID[]),IRISRankID[que]);
				strcopy(IRISRankID[que],sizeof(IRISRankID[]),IRISRankID[que + 1]);
				strcopy(IRISRankID[que + 1],sizeof(IRISRankTrackerTemp),IRISRankTrackerTemp);
				IRISRank[que] = IRISRank[que + 1];
				IRISRank[que + 1] = IRISRankTemp2;
				if(que >= 1){
					que -= 2;
				}
			}
		que++;
	}
}

public ev_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CurrentTime1 = RoundFloat(GetGameTime());
	ReducedHealthMult = 1.0;
	ReducedDamageMult = 1.0;
	DruggedMult = 1.0;
	HasAlreadyHandicapped = 0;
	if(GetConVarInt(UseHandicap) > 0 && GetConVarInt(HandiCapEnabled) > 0){
		// Find the ClientID of the hidden
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsPlayer(i) && GetClientTeam(i) == HDN_TEAM_HIDDEN)
			{
				PrintToChat(i,"[HiddenRanks] Handicap yourself within %d seconds for extra points", GetConVarInt(HandiCapWindow));
			}
		}
	}
	
	for(new i = 0; i <= FileLength; i++)
	{
		SortRanks(i);
	}
	SortIrisHiddenPoints();
}

public ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsPlayer(iAttacker)){
		new Float:fDamage = GetEventFloat(event, "damage"); // Get damage done.
		new String:AttackerID[64];
		GetClientAuthString(iAttacker, AttackerID, sizeof(AttackerID));
		new p = 0;
		new LineNumber = 0;
		while(p <= FileLength)
			{
				if(StrEqual(SteamID[p],AttackerID))
				{
					// Add 1 to line number so that if it found line 0 it produces a 1, so that i can check to see if it found nothing
					// REDUCE THIS NUMBER BY 1 LATER!!
					LineNumber = p + 1;
					// Line found and stored, break loop
					p = 500;
				}
				p++;
			}
		if(LineNumber != 0){
			//Only add to ranked individuals
			LineNumber--;
			DamageDone[LineNumber] += RoundFloat(fDamage);
		}
		if (GetClientTeam(iAttacker) != HDN_TEAM_IRIS && fDamage > 900){
			// Must have pigsticked
			PigStickAttack = 1;
		} else {
			PigStickAttack = 0;
		}
	}
}
public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (GetConVarInt(cvarEnable) == 0)
	{
		return;
	}
	

	// Get some info about who killed who
	new String:SteamIDVictim[64];
	new String:SteamIDKiller[64];
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new String:killerName[100];
	new String:victimName[100];
	new String:weapon[64];
	new LineNumberVictim = 0;
	new LineNumber = 0;
	new IsNotRanked = 0;
	new p = 0;
	
	if(IsPlayer(killer) && IsPlayer(victim))
	{
		GetClientAuthString(killer, SteamIDKiller, sizeof(SteamIDKiller));
		GetEventString(event,"weapon",weapon,sizeof(weapon));
		GetClientName(killer,killerName,100);
		GetClientName(victim,victimName,100);
		p = 0;
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
					Rank[0] = 1;
					strcopy(SteamID[0],sizeof(SteamIDKiller),SteamIDKiller);
					strcopy(Name[0],sizeof(killerName),killerName);
					//Its 1 cos we still have to reduce it by 1
					LineNumber = 1;
					Points[0] = 100;
					
				}else
				{
					FileLength++;
					Rank[FileLength] = Rank[FileLength - 1] + 1;
					strcopy(SteamID[FileLength],sizeof(SteamIDKiller),SteamIDKiller);
					strcopy(Name[FileLength],sizeof(killerName),killerName);
					//Its +1 cos we still have to reduce it by 1
					LineNumber = FileLength + 1;
					Points[FileLength] = 100;
					IRISPoints[FileLength] = 0;
					HiddenPoints[FileLength] = 0;
					IRISKills[FileLength] = 0;
					IRISDeaths[FileLength] = 0;
					HiddenKills[FileLength] = 0;
					PhysKills[FileLength] = 0;
					PigSticks[FileLength] = 0;
					HiddenDeaths[FileLength] = 0;
					Suicides[FileLength] = 0;
					TeamKills[FileLength] = 0;
					DamageDone[FileLength] = 0;
					GameTime[FileLength] = 0;
				}
			}
	}
	if(IsPlayer(victim)){
		GetClientAuthString(victim, SteamIDVictim, sizeof(SteamIDVictim));
		p = 0;
		while(p <= FileLength)
		{
			if(StrEqual(SteamID[p],SteamIDVictim))
			{
				// Add 1 to line number so that if it found line 0 it produces a 1, so that i can check to see if it found nothing
				// REDUCE THIS NUMBER BY 1 LATER!!
				LineNumberVictim = p + 1;
				// Line found and stored, break loop
				p = 500;
			}
			p++;
		}
		
		if(LineNumberVictim == 0)
			{
				//Nothing found!
				// Is not ranked, because he has no kills
				IsNotRanked = 1;
			} else {
				IsNotRanked = 0;
			}
	}
	if(IsPlayer(killer) && IsPlayer(victim)){
		LineNumber--;	
		LineNumberVictim--;					
		//Update Name
		strcopy(Name[LineNumber],sizeof(killerName),killerName);
		SortRanks(LineNumber);
			
		//Lets check to see what team and what weapon used then call the correct function
		if(GetClientTeam(victim) == HDN_TEAM_IRIS && GetClientTeam(killer) != HDN_TEAM_IRIS && (StrEqual(weapon,"physics") || StrEqual(weapon,"physics_respawnable") || StrEqual(weapon,"physics_multiplayer")))
		{
				// Okay a hidden has killed an IRIS with physics
				PhysicsKilled(LineNumberVictim,LineNumber,IsNotRanked);
		}
		if(GetClientTeam(victim) == HDN_TEAM_IRIS && GetClientTeam(killer) != HDN_TEAM_IRIS && StrEqual(weapon,"knife") && PigStickAttack == 0)
		{
			// Okay a hidden has killed an IRIS with knife
			KnifeKilled(LineNumberVictim,LineNumber,IsNotRanked);
		}
		if(GetClientTeam(victim) == HDN_TEAM_IRIS && GetClientTeam(killer) != HDN_TEAM_IRIS && StrEqual(weapon,"knife") && PigStickAttack == 1)
		{
			// Okay a hidden has killed an IRIS with PigStick
			PigStickKilled(LineNumberVictim,LineNumber,IsNotRanked);
		}
		if(GetClientTeam(victim) != HDN_TEAM_IRIS && GetClientTeam(killer) == HDN_TEAM_IRIS)
		{
			//Okay A IRIS has killed a hidden
			IRISKilled(LineNumberVictim,LineNumber,IsNotRanked);
		}
		if(GetClientTeam(killer) == GetClientTeam(victim) && killer != victim)
		{
			//It's a team kill
			TeamKill(LineNumber,GetClientTeam(killer));
		}
		if(GetClientTeam(victim) == HDN_TEAM_IRIS && GetClientTeam(killer) != HDN_TEAM_IRIS && StrEqual(weapon,"grenade_projectile"))
		{
			//Hidden killed someone with grenade
			GrenadeKilled(LineNumberVictim,LineNumber,IsNotRanked);
		}
		if(killer == victim)
		{
			//It's a self suicide
			Suicide(LineNumberVictim,GetClientTeam(victim),IsNotRanked);
		}
	}
}

IRISKilled(victim,killer,IsNotRanked) {
	new iPointsV;
	if(IsNotRanked == 1){
		iPointsV = 100;
	} else {
		iPointsV = Points[victim];
		HiddenDeaths[victim]++;
	}
	
	IRISKills[killer]++;
	new iPointsK = Points[killer];
	new Float:fPointsV = float(iPointsV);
	new Float:fPointsK = float(iPointsK);
	new Float:faddpoints;
	if(GetConVarFloat(TimesByRatio) < 1){
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(IRISMultiply);
	} else {
		new TotalKills = HiddenKills[killer] + IRISKills[killer];
		new TotalDeaths = HiddenDeaths[killer] + IRISDeaths[killer];
		if (TotalDeaths < 1){
			//To stop Dividing by 0
			TotalDeaths = 1;
		}
		new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(IRISMultiply) * fKillDeathRatio;
	}
	new iaddpoints = RoundFloat(faddpoints);
	if(iaddpoints > GetConVarInt(IRISMaxPoints)){
		iaddpoints = GetConVarInt(IRISMaxPoints);
	}
	new PointsVictim = RoundFloat(FloatDiv(fPointsV,fPointsK) * GetConVarFloat(HiddenDeathMultiply));
	if(PointsVictim > RoundFloat(GetConVarFloat(HiddenDeathMultiply))){
		PointsVictim = RoundFloat(GetConVarFloat(HiddenDeathMultiply));
	}else if(PointsVictim < 1){
		PointsVictim = 1;
	}
	if(IsNotRanked != 1){
		if(Points[victim] > PointsVictim){
			Points[victim] -= PointsVictim;
		}
		HiddenPoints[victim] -= PointsVictim;
	}
	Points[killer] += iaddpoints;
	IRISPoints[killer] += iaddpoints;
}

TeamKill(Killer,Team){
	TeamKills[Killer]++;
	if(Team == HDN_TEAM_IRIS){
		IRISPoints[Killer] -= GetConVarInt(IRISTeamKillPoints);
		if(Points[Killer] > GetConVarInt(IRISTeamKillPoints)){
			Points[Killer] -= GetConVarInt(IRISTeamKillPoints);
		} else {
			Points[Killer] = 1;
		}
	} else if(Team == HDN_TEAM_HIDDEN) {
		HiddenPoints[Killer] -= GetConVarInt(HiddenTeamKillPoints);
		if(Points[Killer] > GetConVarInt(HiddenTeamKillPoints)){
			Points[Killer] -= GetConVarInt(HiddenTeamKillPoints);
		} else {
			Points[Killer] = 1;
		}
	}
}

Suicide(victim,team,IsNotRanked) {
	if(IsNotRanked != 1){
		Suicides[victim]++;
		if(GetConVarInt(Suicidepoints) > 0){
			if(team == HDN_TEAM_IRIS){
				IRISDeaths[victim]++;
				IRISPoints[victim] -= GetConVarInt(Suicidepoints);
				Points[victim] -= GetConVarInt(Suicidepoints);
			} else if(team != HDN_TEAM_IRIS){
				HiddenDeaths[victim]++;
				HiddenPoints[victim] -= GetConVarInt(Suicidepoints);
				Points[victim] -= GetConVarInt(Suicidepoints);
			}
		}
	}
}
PhysicsKilled(victim,killer,IsNotRanked) {
	new iPointsV;
	if(IsNotRanked == 1){
		iPointsV = 100;
	} else {
		iPointsV = Points[victim];
		IRISDeaths[victim]++;
	}
	PhysKills[killer]++;
	HiddenKills[killer]++;
	new iPointsK = Points[killer];
	new Float:fPointsV = float(iPointsV);
	new Float:fPointsK = float(iPointsK);
	new Float:faddpoints;
	if(GetConVarFloat(TimesByRatio) < 1){
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(PhysicsMultiply) * ReducedHealthMult * ReducedDamageMult * DruggedMult;
	} else {
		new TotalKills = HiddenKills[killer] + IRISKills[killer];
		new TotalDeaths = HiddenDeaths[killer] + IRISDeaths[killer];
		if (TotalDeaths < 1){
			//To stop Dividing by 0
			TotalDeaths = 1;
		}
		new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(PhysicsMultiply) * fKillDeathRatio * ReducedHealthMult * ReducedDamageMult * DruggedMult;
	}
	new iaddpoints = RoundFloat(faddpoints);
	if(iaddpoints > GetConVarInt(HiddenMaxPoints)){
		iaddpoints = GetConVarInt(HiddenMaxPoints);
	}
	new PointsVictim = RoundFloat(FloatDiv(fPointsV,fPointsK) * GetConVarFloat(IRISDeathMultiply));
	if(PointsVictim > RoundFloat(GetConVarFloat(IRISDeathMultiply))){
		PointsVictim = RoundFloat(GetConVarFloat(IRISDeathMultiply));
	}else if(PointsVictim < 1){
		PointsVictim = 1;
	}
	if(IsNotRanked != 1){
		if(Points[victim] > PointsVictim){
			Points[victim] -= PointsVictim;
		}
		IRISPoints[victim] -= PointsVictim;
	}
	Points[killer] += iaddpoints;
	HiddenPoints[killer] += iaddpoints;
}

KnifeKilled(victim,killer,IsNotRanked) {
	new iPointsV;
	if(IsNotRanked == 1){
		iPointsV = 100;
	} else {
		iPointsV = Points[victim];
		IRISDeaths[victim]++;
	}
	HiddenKills[killer]++;
	new iPointsK = Points[killer];
	new Float:fPointsV = float(iPointsV);
	new Float:fPointsK = float(iPointsK);
	new Float:faddpoints;
	if(GetConVarFloat(TimesByRatio) < 1){
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(KnifeMultiply) * ReducedHealthMult * ReducedDamageMult * DruggedMult;
	} else {
		new TotalKills = HiddenKills[killer] + IRISKills[killer];
		new TotalDeaths = HiddenDeaths[killer] + IRISDeaths[killer];
		if (TotalDeaths < 1){
			//To stop Dividing by 0
			TotalDeaths = 1;
		}
		new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(KnifeMultiply) * fKillDeathRatio * ReducedHealthMult * ReducedDamageMult * DruggedMult;
	}
	new iaddpoints = RoundFloat(faddpoints);
	if(iaddpoints > GetConVarInt(HiddenMaxPoints)){
		iaddpoints = GetConVarInt(HiddenMaxPoints);
	}
	new PointsVictim = RoundFloat(FloatDiv(fPointsV,fPointsK) * GetConVarFloat(IRISDeathMultiply));
	if(PointsVictim > RoundFloat(GetConVarFloat(IRISDeathMultiply))){
		PointsVictim = RoundFloat(GetConVarFloat(IRISDeathMultiply));
	}else if(PointsVictim < 1){
		PointsVictim = 1;
	}
	if(IsNotRanked != 1){
		if(Points[victim] > PointsVictim){
			Points[victim] -= PointsVictim;
		}
		IRISPoints[victim] -= PointsVictim;
	}
	Points[killer] += iaddpoints;
	HiddenPoints[killer] += iaddpoints;
}

GrenadeKilled(victim,killer,IsNotRanked) {
	new iPointsV;
	if(IsNotRanked == 1){
		iPointsV = 100;
	} else {
		iPointsV = Points[victim];
		IRISDeaths[victim]++;
	}
	HiddenKills[killer]++;
	new iPointsK = Points[killer];
	new Float:fPointsV = float(iPointsV);
	new Float:fPointsK = float(iPointsK);
	new Float:faddpoints;
	if(GetConVarFloat(TimesByRatio) < 1){
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(GrenadeMultiply) * ReducedDamageMult * DruggedMult;
	} else {
		new TotalKills = HiddenKills[killer] + IRISKills[killer];
		new TotalDeaths = HiddenDeaths[killer] + IRISDeaths[killer];
		if (TotalDeaths < 1){
			//To stop Dividing by 0
			TotalDeaths = 1;
		}
		new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(GrenadeMultiply) * fKillDeathRatio * ReducedDamageMult * DruggedMult;
	}
	new iaddpoints = RoundFloat(faddpoints);
	if(iaddpoints > GetConVarInt(HiddenMaxPoints)){
		iaddpoints = GetConVarInt(HiddenMaxPoints);
	}
	new PointsVictim = RoundFloat(FloatDiv(fPointsV,fPointsK) * GetConVarFloat(IRISDeathMultiply));
	if(PointsVictim > RoundFloat(GetConVarFloat(IRISDeathMultiply))){
		PointsVictim = RoundFloat(GetConVarFloat(IRISDeathMultiply));
	}else if(PointsVictim < 1){
		PointsVictim = 1;
	}
	if(IsNotRanked != 1){
		if(Points[victim] > PointsVictim){
			Points[victim] -= PointsVictim;
		}
		IRISPoints[victim] -= PointsVictim;
	}
	Points[killer] += iaddpoints;
	HiddenPoints[killer] += iaddpoints;
}


PigStickKilled(victim,killer,IsNotRanked) {
	new iPointsV;
	if(IsNotRanked == 1){
		iPointsV = 100;
	} else {
		iPointsV = Points[victim];
		IRISDeaths[victim]++;
	}
	HiddenKills[killer]++;
	PigSticks[killer]++;
	new iPointsK = Points[killer];
	new Float:fPointsV = float(iPointsV);
	new Float:fPointsK = float(iPointsK);
	new Float:faddpoints;
	if(GetConVarFloat(TimesByRatio) < 1){
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(PigMultiply) * DruggedMult;
	} else {
		new TotalKills = HiddenKills[killer] + IRISKills[killer];
		new TotalDeaths = HiddenDeaths[killer] + IRISDeaths[killer];
		if (TotalDeaths < 1){
			//To stop Dividing by 0
			TotalDeaths = 1;
		}
		new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
		faddpoints = FloatDiv(fPointsV,fPointsK) * GetConVarFloat(PigMultiply) * fKillDeathRatio * DruggedMult;
	}
	new iaddpoints = RoundFloat(faddpoints);
	if(iaddpoints > GetConVarInt(HiddenMaxPoints)){
		iaddpoints = GetConVarInt(HiddenMaxPoints);
	}
	new PointsVictim = RoundFloat(FloatDiv(fPointsV,fPointsK) * (GetConVarFloat(IRISDeathMultiply) / 2));
	if(PointsVictim > RoundFloat(GetConVarFloat(IRISDeathMultiply) / 2)){
		PointsVictim = RoundFloat(GetConVarFloat(IRISDeathMultiply) / 2);
	}else if(PointsVictim < 1){
		PointsVictim = 1;
	}
	if(IsNotRanked != 1){
		if(Points[victim] > PointsVictim){
			Points[victim] -= PointsVictim;
		}
		IRISPoints[victim] -= PointsVictim;
	}
	Points[killer] += iaddpoints;
	HiddenPoints[killer] += iaddpoints;
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
	
	new LineNumber = 0;
	new String:SteamIDChat[64];
	new String:ClientName[100];
	
	if (strcmp(Chat[startidx],"Rank", false) == 0)
		{
			new p = 0;
			
			GetClientAuthString(client, SteamIDChat, sizeof(SteamIDChat));
			GetClientName(client,ClientName,sizeof(ClientName));
			
			LineNumber = 0;
			
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
				PrintToChatAll("\x04[HiddenRanks] Player %s is not ranked!",ClientName);
			}
			else
			{
				LineNumber--;
				new TotalPlayers = FileLength + 1;
				new TotalKills = HiddenKills[LineNumber] + IRISKills[LineNumber];
				new TotalDeaths = HiddenDeaths[LineNumber] + IRISDeaths[LineNumber];
				if (TotalDeaths < 1){
					//To stop Dividing by 0
					TotalDeaths = 1;
				}
				new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
				new String:KillDeathRatio[64];
				FloatToCutString(fKillDeathRatio, KillDeathRatio, sizeof(KillDeathRatio), 2);
				PrintToChatAll("[HiddenRanks] %s, ranked: %d/%d points: %d K/D: %s!",ClientName,Rank[LineNumber],TotalPlayers,Points[LineNumber],KillDeathRatio);
			}
			return Plugin_Continue;
		} else if (strcmp(Chat[startidx],"IRISRank", false) == 0)
		{
			new p = 0;
			
			GetClientAuthString(client, SteamIDChat, sizeof(SteamIDChat));
			GetClientName(client,ClientName,sizeof(ClientName));
			
			LineNumber = 0;
			new IRISRankNumber = 0;
			while(p <= FileLength)
			{
				if(StrEqual(IRISRankID[p],SteamIDChat))
				{
					IRISRankNumber = p + 1;
					p = 500;
				}
				p++;
			}
			
			p = 0;
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
				PrintToChatAll("\x04[HiddenRanks] Player %s is not ranked!",ClientName);
			}
			else
			{
				LineNumber--;
				new TotalPlayers = FileLength + 1;
				new IRISKillsTemp = IRISKills[LineNumber];
				new IRISDeathsTemp = IRISDeaths[LineNumber];
				if (IRISDeathsTemp < 1){
					//To stop Dividing by 0
					IRISDeathsTemp = 1;
				}
				new Float:fKillDeathRatio = float(IRISKillsTemp) / float(IRISDeathsTemp);
				new String:KillDeathRatio[64];
				FloatToCutString(fKillDeathRatio, KillDeathRatio, sizeof(KillDeathRatio), 2);
				PrintToChatAll("[HiddenRanks] %s, ranked %d/%d out of IRIS players. IRIS points:%d IRIS K/D:%s!",ClientName,IRISRankNumber,TotalPlayers,IRISPoints[LineNumber],KillDeathRatio);
			}
			return Plugin_Continue;
		} else if (strcmp(Chat[startidx],"HiddenRank", false) == 0)
		{
			new p = 0;
			
			GetClientAuthString(client, SteamIDChat, sizeof(SteamIDChat));
			GetClientName(client,ClientName,sizeof(ClientName));
			
			LineNumber = 0;
			new HiddenRankNumber = 0;
			while(p <= FileLength)
			{
				if(StrEqual(HiddenRankID[p],SteamIDChat))
				{
					HiddenRankNumber = p + 1;
					p = 500;
				}
				p++;
			}
			
			p = 0;
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
				PrintToChatAll("\x04[HiddenRanks] Player %s is not ranked!",ClientName);
			}
			else
			{
				
				LineNumber--;
				new TotalPlayers = FileLength + 1;
				new HiddenKillsTemp = HiddenKills[LineNumber];
				new HiddenDeathsTemp = HiddenDeaths[LineNumber];
				if (HiddenDeathsTemp < 1){
					//To stop Dividing by 0
					HiddenDeathsTemp = 1;
				}
				new Float:fKillDeathRatio = float(HiddenKillsTemp) / float(HiddenDeathsTemp);
				new String:KillDeathRatio[64];
				FloatToCutString(fKillDeathRatio, KillDeathRatio, sizeof(KillDeathRatio), 2);
				PrintToChatAll("[HiddenRanks] %s, ranked: %d/%d out of Hidden players. Hdn points:%d Hdn K/D:%s!",ClientName,HiddenRankNumber,TotalPlayers,HiddenPoints[LineNumber],KillDeathRatio);
			}
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"Top", false) == 0)
		{
			RankMenu = 0;
			HiddenMenu = 0;
			IRISMenu = 0;
			new Player = client;
			PrintTopScoresToClient(Player);
			return Plugin_Continue;
		}  else if(strcmp(Chat[startidx],"IRISTop", false) == 0)
		{
			RankMenu = 0;
			HiddenMenu = 0;
			IRISMenu = 1;
			new Player = client;
			PrintTopScoresToClient(Player);
			return Plugin_Continue;
		}  else if(strcmp(Chat[startidx],"HiddenTop", false) == 0)
		{
			RankMenu = 0;
			HiddenMenu = 1;
			IRISMenu = 0;
			new Player = client;
			PrintTopScoresToClient(Player);
			return Plugin_Continue;
		} else if(strcmp(Chat[startidx],"!ResetRank", false) == 0)
		{
			new l = 0;
			
			GetClientAuthString(client, SteamIDChat, sizeof(SteamIDChat));
			GetClientName(client,ClientName,sizeof(ClientName));
			
			LineNumber = 0;
			
			while(l <= FileLength)
			{
				
				if(StrEqual(SteamID[l],SteamIDChat))
				{
					// Add 1 to line number so that if it found line 0 it produces a 1, so that i can check to see if it found nothing
					// REDUCE THIS NUMBER BY 1 LATER!!
					LineNumber = l + 1;
					// Line found and stored, break loop
					l = 500;
				}
				l++;
			}
			if(LineNumber == 0)
			{
				//Nothing found!
				PrintToChat(client,"[HiddenRanks] You're not ranked yet!");
			}
			else
			{
				LineNumber--;
				Points[LineNumber] = 100;
				IRISPoints[LineNumber] = 0;
				HiddenPoints[LineNumber] = 0;
				IRISKills[LineNumber] = 0;
				IRISDeaths[LineNumber] = 0;
				HiddenKills[LineNumber] = 0;
				PhysKills[LineNumber] = 0;
				PigSticks[LineNumber] = 0;
				HiddenDeaths[LineNumber] = 0;
				Suicides[LineNumber] = 0;
				TeamKills[LineNumber] = 0;
				DamageDone[LineNumber] = 0;
				GameTime[LineNumber] = 0;
				
				for(new loop = LineNumber; loop <= FileLength; loop++){
					SortRanks(loop);
				}
				PrintToChatAll("[HiddenRanks] Player %s has reset his rank!",ClientName);
			}
			return Plugin_Continue;
		}
		else{
		return Plugin_Continue;
		}
}

public ev_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
// Round ended, so lets write new stats
	new String:strPath[256];
	
	
	CurrentTime2 = RoundFloat(GetGameTime());
	new String:SteamIDPerson[64];
	new Float:fGameTimeMinutes;
	new iGameTime;
	
	for(new q = 1; q <= MaxClients; q++){
		if(IsPlayer(q)){
			GetClientAuthString(q, SteamIDPerson, sizeof(SteamIDPerson));
			for(new p = 0; p <= FileLength; p++)
			{
				if(StrEqual(SteamID[p],SteamIDPerson))
				{
					// Player is connected, Line found, so add to their game time
					GameTime[p] += CurrentTime2 - CurrentTime1;
					iGameTime = GameTime[p];
					fGameTimeMinutes = float(iGameTime);
					fGameTimeMinutes /= 60.0;
					GameTimeMinutes[p] = RoundFloat(fGameTimeMinutes);
				}
			}	
		}
	}
	
	if(Points[0] != 0){
	//Must have at least someone ranked
	new Handle:HiddenStats = OpenFile("/cfg/hiddenranks_ranks.txt","w");
	if(HiddenStats == INVALID_HANDLE)
		{
			SetFailState("Failed to open file: %s", strPath);
			return;
		}
		
			
	for(new i = 0; i <= FileLength; i++)
		{
		new String:strLine[1024];
		IRISRank[i] = IRISPoints[i];
		HiddenRank[i] = HiddenPoints[i];
		strcopy(IRISRankID[i],sizeof(SteamID[]),SteamID[i]);
		strcopy(HiddenRankID[i],sizeof(SteamID[]),SteamID[i]);
		strcopy(IRISRankName[i],sizeof(Name[]),Name[i]);
		strcopy(HiddenRankName[i],sizeof(Name[]),Name[i]);
				
		Format(strLine,sizeof(strLine),"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s,%s",Rank[i],Points[i],IRISPoints[i],HiddenPoints[i],IRISKills[i],IRISDeaths[i],HiddenKills[i],PhysKills[i],PigSticks[i],HiddenDeaths[i],Suicides[i],TeamKills[i],DamageDone[i],GameTimeMinutes[i],SteamID[i],Name[i]);
		WriteFileLine(HiddenStats, strLine, sizeof(strLine));
		}
	CloseHandle(HiddenStats);
	}
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
	new Rankmenuadd1 = 0;
	
	// If the first rank is read as 1 then it must be a valid read so lets render!
	if(Rank[0] == 1 && IRISMenu == 1 && HiddenMenu == 0){
		while(RankMenu < RankMenuTotal)
		{
		if(RankMenu < FileLength + 1)
			{
			new String:Text[64];
			Rankmenuadd1 = RankMenu + 1;
			Format(Text,sizeof(Text), "%d. %s",Rankmenuadd1,IRISRankName[RankMenu]);
			DrawPanelItem(TopScores, Text, ITEMDRAW_DEFAULT);
			MenuSelect[a] = RankMenu;
			RankMenu++;
			a++;
			}
			else{
			RankMenu = RankMenuTotal;
			}
		}
	} else if(Rank[0] == 1 && HiddenMenu == 1 && IRISMenu == 0){
		while(RankMenu < RankMenuTotal)
		{
		if(RankMenu < FileLength + 1)
			{
			new String:Text[64];
			Rankmenuadd1 = RankMenu + 1;
			Format(Text,sizeof(Text), "%d. %s",Rankmenuadd1,HiddenRankName[RankMenu]);
			DrawPanelItem(TopScores, Text, ITEMDRAW_DEFAULT);
			MenuSelect[a] = RankMenu;
			RankMenu++;
			a++;
			}
			else{
			RankMenu = RankMenuTotal;
			}
		}
	} else if(Rank[0] == 1 && HiddenMenu == 0 && IRISMenu == 0){
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
	if(IRISMenu == 1 && HiddenMenu == 0){
		SetPanelTitle(TopScores, "Top IRIS Players: \nClick a name to have \ninformation printed to console");
	} else if(HiddenMenu == 1 && IRISMenu == 0){
		SetPanelTitle(TopScores, "Top Hidden Players: \nClick a name to have \ninformation printed to console");
	} else if(Rank[0] == 1 && HiddenMenu == 0 && IRISMenu == 0){
		SetPanelTitle(TopScores, "Top Players: \nClick a name to have \ninformation printed to console");
	}
	
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
		else if (param2==3) //1
		{
			MenuSend(MenuSelect[0],param1);
		}
		else if (param2==4) //2
		{
			MenuSend(MenuSelect[1],param1);
		}
		else if (param2==5) //3
		{
			MenuSend(MenuSelect[2],param1);
		}
		else if (param2==6) //4
		{
			MenuSend(MenuSelect[3],param1);
		}
		else if (param2==7) //5
		{
			MenuSend(MenuSelect[4],param1);
		}
		else if (param2==8) //6
		{
			MenuSend(MenuSelect[5],param1);
		}
	}
} 

SortRanks(i){
	if(Points[i] < Points[i+1] && i != FileLength)
	{
		//Someone is ranked less than the next guy and hasnt been corrected, lets correct it
		new PointsTemp = Points[i];
		new String:SteamTemp[64];
		new String:NameTemp[64];
		new IRISPointsTemp = IRISPoints[i];
		new HiddenPointsTemp = HiddenPoints[i];
		new IRISKillsTemp = IRISKills[i];
		new HiddenKillsTemp = HiddenKills[i];
		new PhysKillsTemp = PhysKills[i];
		new IRISDeathsTemp = IRISDeaths[i];
		new HiddenDeathsTemp = HiddenDeaths[i];
		new PigSticksTemp = PigSticks[i];
		new DamageDoneTemp = DamageDone[i];
		new GameTimeTemp = GameTime[i];
		new SuicidesTemp = Suicides[i];
		new TeamKillsTemp = TeamKills[i];
						
		strcopy(SteamTemp,sizeof(SteamID[]),SteamID[i]);
		strcopy(NameTemp,sizeof(Name[]),Name[i]);
				
		Points[i] = Points[i + 1];
		IRISPoints[i] = IRISPoints[i + 1];
		HiddenPoints[i] = HiddenPoints[i + 1];
		IRISKills[i] = IRISKills[i + 1];
		HiddenKills[i] = HiddenKills[i + 1];
		PhysKills[i] = PhysKills[i + 1];
		IRISDeaths[i] = IRISDeaths[i + 1];
		HiddenDeaths[i] = HiddenDeaths[i + 1];
		PigSticks[i] = PigSticks[i + 1];
		DamageDone[i] = DamageDone[i + 1];
		GameTime[i] = GameTime[i + 1];
		Suicides[i] = Suicides[i + 1];
		TeamKills[i] = TeamKills[i + 1];
							
		strcopy(SteamID[i],sizeof(SteamID[]),SteamID[i + 1]);
		strcopy(Name[i],sizeof(Name[]),Name[i + 1]);
			
		Points[i + 1] = PointsTemp;
		IRISPoints[i + 1] = IRISPointsTemp;
		HiddenPoints[i + 1] = HiddenPointsTemp;
		IRISKills[i + 1] = IRISKillsTemp;
		HiddenKills[i + 1] = HiddenKillsTemp;
		PhysKills[i + 1] = PhysKillsTemp;
		IRISDeaths[i + 1] = IRISDeathsTemp;
		HiddenDeaths[i + 1] = HiddenDeathsTemp;
		PigSticks[i + 1] = PigSticksTemp;
		DamageDone[i + 1] = DamageDoneTemp;
		GameTime[i + 1] = GameTimeTemp;
		Suicides[i + 1] = SuicidesTemp;
		TeamKills[i + 1] = TeamKillsTemp;
		strcopy(SteamID[i + 1],sizeof(SteamTemp),SteamTemp);
		strcopy(Name[i + 1],sizeof(NameTemp),NameTemp);
		if(Points[i] < 1){
			Points[i] = 1;
		}
	}
}

bool:FloatToCutString(Float:value, String:Target[], TargetSize, DecPlaces)
{
	if(DecPlaces < 1){
		return false;
	}
	new Float:fBuffer = value;
	new String:Buffer[255];
	new String:Buffer2[255];
	new Ganz = RoundToFloor(fBuffer); //strip integer from decimal places
	fBuffer = FloatFraction(fBuffer); //strip decimal places from integer
	FloatToString(fBuffer, Buffer, (3+DecPlaces)); //cut decimal places to desired (2 places = 5 characters (0,xx\n)
	strcopy(Buffer2, sizeof(Buffer2), Buffer[2]); //strip decimal places string from '0,'-prefix
	Format(Buffer, sizeof(Buffer), "%d.%s",Ganz,Buffer2);
	strcopy(Target, TargetSize, Buffer);
	return true;
}

MenuSend(client,param1){
	new p = 0;
	if(IRISMenu == 1 && HiddenMenu == 0){
		while(p <= FileLength)
			{
				if(StrEqual(SteamID[p],IRISRankID[client]))
				{
					client = p;
					// Line found and stored, break loop
					p = 500;
				}
				p++;
			}
	} else if(HiddenMenu == 1 && IRISMenu == 0){
		while(p <= FileLength)
			{
				if(StrEqual(SteamID[p],HiddenRankID[client]))
				{
					client = p;
					// Line found and stored, break loop
					p = 500;
				}
				p++;
			}
	}
	new TotalKills = HiddenKills[client] + IRISKills[client];
	new iIRISKills = IRISKills[client];
	new iIRISDeaths = IRISDeaths[client];
	new iHiddenKills = HiddenKills[client];
	new iHiddenDeaths = HiddenDeaths[client];
	if (iIRISDeaths < 1){
		//To stop Dividing by 0
		iIRISDeaths = 1;
	}
	if (iHiddenDeaths < 1){
		//To stop Dividing by 0
		iHiddenDeaths = 1;
	}
	new iGameTime = GameTime[client];
	new Float:fGameTimeMinutes = float(iGameTime);
	fGameTimeMinutes /= 60.0;
	GameTimeMinutes[client] = RoundFloat(fGameTimeMinutes);
	new TotalDeaths = HiddenDeaths[client] + IRISDeaths[client];
	if (TotalDeaths < 1){
		//To stop Dividing by 0
		TotalDeaths = 1;
	}
	new Float:fKillDeathRatio = float(TotalKills) / float(TotalDeaths);
	new Float:fIRISKillDeathRatio = float(iIRISKills) / float(iIRISDeaths);
	new Float:fHiddenKillDeathRatio = float(iHiddenKills) / float(iHiddenDeaths);
	new String:KillDeathRatio[64];
	new String:HiddenKillDeathRatio[64];
	new String:IRISKillDeathRatio[64];
	FloatToCutString(fKillDeathRatio, KillDeathRatio, sizeof(KillDeathRatio), 2);
	FloatToCutString(fIRISKillDeathRatio, IRISKillDeathRatio, sizeof(IRISKillDeathRatio), 2);
	FloatToCutString(fHiddenKillDeathRatio, HiddenKillDeathRatio, sizeof(HiddenKillDeathRatio), 2);
	PrintToConsole(param1, "////////////////////////////////////////////////");
	PrintToConsole(param1, "///// Name:  %s",Name[client]);
	PrintToConsole(param1, "////  Total Points %d",Points[client]);
	PrintToConsole(param1, "////  Total K/D Ratio: %s",KillDeathRatio);
	PrintToConsole(param1, "////  IRIS Points: %d  Hidden Points: %d",IRISPoints[client],HiddenPoints[client]);
	PrintToConsole(param1, "////  IRIS Kills: %d    IRIS Deaths: %d",IRISKills[client],IRISDeaths[client]);
	PrintToConsole(param1, "////  IRIS K/D Ratio: %s",IRISKillDeathRatio);
	PrintToConsole(param1, "////  Hidden Kills: %d   Hidden Deaths: %d",HiddenKills[client],HiddenDeaths[client]);
	PrintToConsole(param1, "////  Hidden K/D Ratio: %s",HiddenKillDeathRatio);
	PrintToConsole(param1, "////  PhysKills: %d    PigSticks: %d",PhysKills[client],PigSticks[client]);
	PrintToConsole(param1, "////  Suicides: %d    TeamKills: %d",Suicides[client],TeamKills[client]);
	PrintToConsole(param1, "////  Damage Done: %d Game Time (m): %d",DamageDone[client],GameTimeMinutes[client]);
	PrintToConsole(param1, "////////////////////////////////////////////////");
	RankMenu = MenuSelect[0];
	PrintTopScoresToClient(param1);
}

public ReducedDamageChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(UseHandicap) > 0 && GetConVarInt(HandiCapEnabled) > 0){
		if(GetConVarInt(ReducedDamage) == 0 || HasAlreadyHandicapped == 1){
			//The hidden set to normal or something else, to avoid exploiting let's set to 1.0
			ReducedDamageMult = 1.0;
		}
		new TheTime = RoundFloat(GetGameTime());
		if((TheTime - CurrentTime1) < GetConVarInt(HandiCapWindow) && HasAlreadyHandicapped == 0){
			HasAlreadyHandicapped = 1;
			if(GetConVarInt(ReducedDamage) == 10){
				ReducedDamageMult = 1.2;
			} else if(GetConVarInt(ReducedDamage) == 25){
				ReducedDamageMult = 1.25;
			} else if(GetConVarInt(ReducedDamage) == 50){
				ReducedDamageMult = 1.5;
			} else if(GetConVarInt(ReducedDamage) == 75){
				ReducedDamageMult = 2.0;
			} else if(GetConVarInt(ReducedDamage) == 90){
				ReducedDamageMult = 3.0;
			}
		}
	}
}

public ReducedHealthChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(UseHandicap) > 0 && GetConVarInt(HandiCapEnabled) > 0){
		new TheTime = RoundFloat(GetGameTime());
		if((TheTime - CurrentTime1) < GetConVarInt(HandiCapWindow)){
			if(GetConVarInt(ReducedHealth) == 25){
				ReducedHealthMult = 1.5;
			} else if(GetConVarInt(ReducedHealth) == 50){
				ReducedHealthMult = 2.0;
			} else if(GetConVarInt(ReducedHealth) == 75){
				ReducedHealthMult = 3.0;
			}
		}
	}
}

public DruggedChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(UseHandicap) > 0 && GetConVarInt(HandiCapEnabled) > 0){
		if(GetConVarInt(Drugged) == 0){
			//The hidden set to normal
			DruggedMult = 1.0;
		}
		new TheTime = RoundFloat(GetGameTime());
		if((TheTime - CurrentTime1) < GetConVarInt(HandiCapWindow)){
			if(GetConVarInt(Drugged) == 1){
				DruggedMult = 1.25;
			}
		}
	}
}