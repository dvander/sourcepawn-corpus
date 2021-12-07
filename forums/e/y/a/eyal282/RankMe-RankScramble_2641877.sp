#include <sourcemod>
#include <cstrike>
#include <sdktools>

native RankMe_GetPoints(client);

new const String:PLUGIN_VERSION[] = "1.1";

public Plugin:myinfo = 
{
	name = "sm_rankscramble",
	author = "Eyal282",
	description = "Scramble teams teams by the rank of the players.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2641877#post2641877"
}

#define HUD_PRINTCENTER        4 

// ATB = Auto Team Balance
new Handle:hcv_ATB = INVALID_HANDLE;
new Handle:hcv_PluginATB = INVALID_HANDLE;
new Handle:hcv_PluginATBMethod = INVALID_HANDLE;

public OnPluginStart()
{
	RegAdminCmd("sm_rankshuffle", RankScramble, ADMFLAG_KICK);
	RegAdminCmd("sm_rankscramble", RankScramble, ADMFLAG_KICK);		
	
	HookEvent("round_prestart", Event_RoundPreStart, EventHookMode_Post); // This happens before players spawn so we don't need to spawn them on the team balance.
	
	hcv_PluginATB = CreateConVar("rankme_autoteambalance", "2", "Automatically balance teams before a round starts if player count difference in teams is greater or equal to this value. Set to 0 to disable.");
	hcv_PluginATBMethod = CreateConVar("rankme_autoteambalance_method", "1", "0 - Move the player who will make the point difference between all teams the smallest. 1 - Complete team scramble");
	
	hcv_ATB = FindConVar("mp_autoteambalance");
	
	HookConVarChange(hcv_ATB, hcvChange_AutoTeamBalance);
	HookConVarChange(hcv_PluginATB, hcvChange_PluginAutoTeamBalance);

	new String:Value[64];
	GetConVarString(hcv_PluginATB, Value, sizeof(Value));
	
	hcvChange_PluginAutoTeamBalance(hcv_PluginATB, Value, Value);
	
	GetConVarString(hcv_ATB, Value, sizeof(Value));
	
	hcvChange_AutoTeamBalance(hcv_ATB, Value, Value);
}

public hcvChange_AutoTeamBalance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(hcv_PluginATB) != 0 && StringToInt(newValue) != 0)
		SetConVarInt(hcv_ATB, 0);
}

public hcvChange_PluginAutoTeamBalance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToInt(newValue) != 0)
		SetConVarInt(hcv_ATB, 0);
}

public Action:Event_RoundPreStart(Handle:hEvent, const String:Name[], bool:dontBroadcast)
{
	if(GetConVarInt(hcv_PluginATB) == 0)
		return;
	
	new CTCount, TCount;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		switch(GetClientTeam(i))
		{
			case CS_TEAM_T: TCount++;
			case CS_TEAM_CT: CTCount++;
		}
	}
	
	if(Abs(CTCount - TCount) >= GetConVarInt(hcv_PluginATB))
	{
		if(GetConVarBool(hcv_PluginATBMethod))
			ScrambleTeams(false);

		else
			BalanceTeams(false, TCount, CTCount);
		
		UC_PrintCenterTextAll("#Teams_Balanced");
		PrintToChatAll(" \x01Server \x02 automatically\x03 scrambled the teams\x01 based on\x03 rank.");

	}
}

public Action:RankScramble(client, args)
{
	ScrambleTeams(true);
	
	PrintToChatAll(" \x01Admin\x04 %N\x03 scrambled the teams\x01 based on\x03 rank", client);
}

stock ScrambleTeams(bool:Respawn = true)
{
	new players[MAXPLAYERS], num = 0;
	
	for(new i=0;i <= MaxClients;i++)
	{
		players[i] = 0;
	}
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		else if(IsFakeClient(i))
			continue;
			
		else if(GetClientTeam(i) != CS_TEAM_CT && GetClientTeam(i) != CS_TEAM_T)
			continue;
			
		players[num] = i;
		num++;
		ChangeClientTeam(i, 1);
	}
	
	SortCustom1D(players, MAXPLAYERS, SortByPPM);
	
	new bool:Terror = false;
	for(new i=0;i < MAXPLAYERS;i++)
	{
		new target = players[i];
		if(target == 0)
			continue;
			
		if(Terror)
			CS_SwitchTeam(target, CS_TEAM_T);
		
		else
			CS_SwitchTeam(target, CS_TEAM_CT);
		
		if(Respawn)
			CS_RespawnPlayer(target);
		
		Terror = !Terror;
	}
}


stock BalanceTeams(bool:Respawn = true, TCount, CTCount)
{
	new TPoints = GetTeamPoints(CS_TEAM_T);
	new CTPoints = GetTeamPoints(CS_TEAM_CT);
	
	if(TCount > CTCount)
	{
		do
		{
			TCount--;
			CTCount++;
			
			new BestCandidate = 0, BestCandidateDiff; // BestCandidateDiff is the difference in points the teams will have if the best candidate moves to the other team.
			
			for(new i=1;i <= MaxClients;i++)
			{
				if(!IsClientInGame(i))
					continue;
				
				else if(GetClientTeam(i) != CS_TEAM_T)
					continue;
					
				new points = RankMe_GetPoints(i);
				
				new Diff = Abs( (TPoints - points) - (CTPoints + points) );
				
				if(BestCandidate == 0)
				{
					BestCandidate = i;
					BestCandidateDiff = Diff;
					
					continue;
				}
				
				else if(BestCandidateDiff > Diff)
				{
					BestCandidate = i;
					BestCandidateDiff = Diff;
				}
			}
			
			if(BestCandidate == 0) // No players found.
				return;
				
			CS_SwitchTeam(BestCandidate, CS_TEAM_CT);
		}
		while(TCount - CTCount >= 2)
	}
	else if(CTCount > TCount)
	{
		do
		{
			CTCount--;
			TCount++;
			
			new BestCandidate = 0, BestCandidateDiff; // BestCandidateDiff is the difference in points the teams will have if the best candidate moves to the other team.
			
			for(new i=1;i <= MaxClients;i++)
			{
				if(!IsClientInGame(i))
					continue;
				
				else if(GetClientTeam(i) != CS_TEAM_CT)
					continue;
					
				new points = RankMe_GetPoints(i);
				
				new Diff = Abs( (CTPoints - points) - (TPoints + points) );
				
				if(BestCandidate == 0)
				{
					BestCandidate = i;
					BestCandidateDiff = Diff;
					
					continue;
				}
				
				else if(BestCandidateDiff > Diff)
				{
					BestCandidate = i;
					BestCandidateDiff = Diff;
				}
			}
			
			if(BestCandidate == 0) // No players found.
				return;
				
			CS_SwitchTeam(BestCandidate, CS_TEAM_T);
		}
		while(CTCount - TCount >= 2)
	}
}


public SortByPPM(player1, player2, Array[], Handle:hndl)
{		
	if(player1 == -1 && player2 == -1) 
		return 0;
	
	else if(player1 == -1 && player2 != -1)
		return 1;
	
	else if(player1 != -1 && player2 == -1)
		return -1;
		
	if(RankMe_GetPoints(player1) > RankMe_GetPoints(player2))
		return -1;
	
	else if(RankMe_GetPoints(player1) < RankMe_GetPoints(player2))
		return 1;
		
	return 0;
}


// https://forums.alliedmods.net/showpost.php?p=2325048&postcount=8
// Print a Valve translation phrase to a group of players 
// Adapted from util.h's UTIL_PrintToClientFilter 
stock UC_PrintCenterTextAll(const String:msg_name[], const String:param1[]="", const String:param2[]="", const String:param3[]="", const String:param4[]="")
{ 
	new UserMessageType:MessageType = GetUserMessageType();
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		
		SetGlobalTransTarget(i);
		
		new Handle:bf = StartMessageOne("TextMsg", i, USERMSG_RELIABLE); 
		 
		if (MessageType == UM_Protobuf) 
		{ 
			PbSetInt(bf, "msg_dst", HUD_PRINTCENTER); 
			PbAddString(bf, "params", msg_name); 
				
			PbAddString(bf, "params", param1); 
			PbAddString(bf, "params", param2); 
			PbAddString(bf, "params", param3); 
			PbAddString(bf, "params", param4); 
		} 
		else 
		{ 
			BfWriteByte(bf, HUD_PRINTCENTER); 
			BfWriteString(bf, msg_name); 
			
			BfWriteString(bf, param1); 
			BfWriteString(bf, param2); 
			BfWriteString(bf, param3); 
			BfWriteString(bf, param4); 
		}
		 
		EndMessage(); 
	}
}  

stock Abs(value)
{
	if(value < 0)
		return -value;
		
	return value;
}

stock GetTeamPoints(Team)
{
	new PointsCount = 0;
	
	for(new i=1;i <= MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
			
		PointsCount += RankMe_GetPoints(i);
	}
	
	return PointsCount;
}