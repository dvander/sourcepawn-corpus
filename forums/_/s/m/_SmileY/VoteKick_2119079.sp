#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name 		= "Vote Kick",
	author 		= "SmileY",
	description 	= "Vote Kick System for SourceMod",
	version 	= "0.0.2",
	url 		= "MaxiGames.com.br"
};

new g_iVotedPlayers[MAXPLAYERS];
new g_iVotes[MAXPLAYERS];

new g_iPlayers[MAXPLAYERS];

new Handle:g_hPercent = INVALID_HANDLE;
new Handle:g_hMinPlayers = INVALID_HANDLE;

public OnPluginStart()
{
	g_hPercent 	= CreateConVar("votekick_percentage","70.0","Minimum of votes to Kick an Player",FCVAR_NOTIFY);
	g_hMinPlayers 	= CreateConVar("votekick_minplayers","3","Minimum of Players in server",FCVAR_NOTIFY);

	RegConsoleCmd("sm_votekick_rtv",PugCmdVoteKick,"Vote to Kick an Player.");
	RegConsoleCmd("say .votekick",PugCmdVoteKick,"Vote to Kick an Player.");
}

public OnClientDisconnect(iClient)
{
	if(g_iVotedPlayers[iClient])
	{
		GetPlayers(g_iPlayers);
		
		for(new i = 1;i <= MaxClients;i++)
		{
			g_iPlayers[i]++;
			
			if(g_iVotedPlayers[iClient] & (1 << g_iPlayers[i]))
			{
				g_iVotes[g_iPlayers[i]]--;
			}
		}
		
		g_iVotedPlayers[iClient] = 0;
	}
}

public Action:PugCmdVoteKick(iClient,iArgs)
{
	if(iClient)
	{
		GetPlayers(g_iPlayers);
		new iClientCount = GetClientCount();
		
		if(iClientCount < GetConVarInt(g_hMinPlayers))
		{
			PrintCenterText(iClient,"We need more than 3 players.");
		}
		else
		{
			new String:sName[40],String:sNum[3];
			new Handle:hMenu = CreateMenu(MenuPlayersHandler);
			SetMenuTitle(hMenu,"Vote Kick: \n ");
			
			for(new i = 1;i <= MaxClients;i++)
			{
				if(IsClientInGame(i) && !IsClientSourceTV(i) && (i != iClient) && (GetUserAdmin(i) == INVALID_ADMIN_ID))
				{
					GetClientName(i,sName,sizeof(sName));
					Format(sName,sizeof(sName),"%s (%i%%)",sName,GetPercent(g_iVotes[i],iClientCount));
					
					IntToString(i,sNum,sizeof(sNum));
					AddMenuItem(hMenu,sNum,sName);
				}
			}
			
			DisplayMenu(hMenu,iClient,5);
		}
	}
}

public MenuPlayersHandler(Handle:hMenu,MenuAction:iAction,iClient,iKey)
{
	if(iAction == MenuAction_Select)
	{
		new String:sInfo[3];
		GetMenuItem(hMenu,iKey,sInfo,sizeof(sInfo));
		
		new iPlayer = StringToInt(sInfo);
		
		if(IsClientInGame(iPlayer))
		{
			new String:sName[MAX_NAME_LENGTH];
			GetClientName(iPlayer,sName,sizeof(sName));
			
			if(g_iVotedPlayers[iClient] & (1 << iPlayer))
			{
				PrintCenterText(iClient,"You have already voted against this player!");
			}
			else
			{
				g_iVotes[iPlayer]++;
				g_iVotedPlayers[iClient] |= (1 << iPlayer);
				
				GetPlayers(g_iPlayers);
				
				new String:sClientName[MAX_NAME_LENGTH];
				GetClientName(iClient,sClientName,sizeof(sClientName));
				
				PrintToChatAll
				(
					"%s voted to kick %s [%i of %i]",
					sClientName,
					sName,
					GetPercent(g_iVotes[iPlayer],GetClientCount()),
					GetConVarInt(g_hPercent)
				);
				
				CheckVotes(iClient,iPlayer);
			}
		}
		else PrintCenterText(iClient,"This player left the server!");
	}
}

public CheckVotes(iClient,iPlayer)
{
	GetPlayers(g_iPlayers);
	
	if(GetPercent(g_iVotes[iPlayer],GetClientCount()) >= GetConVarInt(g_hPercent))
	{
		g_iVotes[iPlayer] = 0;

		if(IsClientInGame(iPlayer))
		{
			new String:sName[MAX_NAME_LENGTH];
			GetClientName(iPlayer,sName,sizeof(sName));
	
			PrintToChatAll
			(
				"%s Was Kicked by Vote Kick.",
				sName
			);
			
			KickClient(iClient,"Kicked duo the Vote Kick");
		}
	}
}

public GetPlayers(iPlayers[MAXPLAYERS])
{
	for(new i = 1;i < MAXPLAYERS;i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i))
		{
			iPlayers[i] = i;
		}
	}
}

stock GetPercent(iValue,tValue)
{
	new iTest = RoundFloat(FloatMul((float(iValue) / float(tValue)),100.0));
	
	return iTest;
}