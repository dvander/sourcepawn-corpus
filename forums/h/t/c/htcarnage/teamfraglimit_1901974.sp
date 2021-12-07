#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <mapchooser>

#define VER "1.4.1"

new CTPoints, TPoints;
new Handle:FullKillLimit;
new Handle:AnnounceInt;
new Handle:VoteInt = INVALID_HANDLE;
new Handle:AnnounceType;
new Handle:MinPlayers;
new Handle:MinPlayersKillLimit;
new Handle:AutoSelect;
new Handle:BombBonus;
new Handle:DefuseBonus;
new Handle:GameType;
new Handle:RestartGame = INVALID_HANDLE;
new bool:bMapChooser = false;
new bool:HasAnnounced = false;
new bool:VoteStarted = false;
new KillLimit;

public Plugin:myinfo=
{
	name			= "Team Frag Limit",
	author		= "BB",
	description	= "Ends the game when a team gets a set amount of points",
	version		= VER,
	url			= "www.sup-gaming.com",
}

public OnPluginStart()
{
	LoadTranslations("teamfraglimit.phrases");
	
	CreateConVar("sm_tfl_version", VER, "Team Frag Limit Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_tfl_reset", ResetScores, ADMFLAG_GENERIC, "Reset team scores");
	RegAdminCmd("checkbools", BoolsCheck, ADMFLAG_GENERIC);
	FullKillLimit 		= CreateConVar("sm_tfl_limit", "500", "Team Point Limit", FCVAR_NOTIFY);
	AnnounceInt 		= CreateConVar("sm_tfl_announce", "100", "Announce how many points a team has every X points. 0 to disable", FCVAR_NOTIFY);
	AnnounceType		= CreateConVar("sm_tfl_announce_type", "1", "Announce Type: \n1 = Center Text, \n2 = Hint Text, \n3 = Chat Text", FCVAR_NOTIFY);
	VoteInt 			= CreateConVar("sm_tfl_vote", "30", "When to start the map vote based on points remaining. \nRequires mapchooser.smx", FCVAR_NOTIFY);	
	MinPlayers			= CreateConVar("sm_tfl_minplayers", "4", "Minimum players for full points limit.\n0 to disable", FCVAR_NOTIFY);
	MinPlayersKillLimit 	= CreateConVar("sm_tfl_minplayers_points_limit", "50", "Point Limit when players is less than sm_tfl_minplayers", FCVAR_NOTIFY);
	AutoSelect			= CreateConVar("sm_tfl_team_autoselect", "0", "Automatically place players who use the Auto-Join function onto the losing team", FCVAR_NOTIFY);
	BombBonus			= CreateConVar("sm_tfl_bomb_bonus", "3", "Team Points to award for bomb detonation", FCVAR_NOTIFY);
	DefuseBonus		= CreateConVar("sm_tfl_defuse_bonus", "3", "Team Points to award for bomb defusal", FCVAR_NOTIFY);
	GameType			= CreateConVar("sm_tfl_gametype", "1", "Is it deathmatch or normal gameplay \n0 = Normal, \n1 = Deathmatch", FCVAR_NOTIFY);
	KillLimit 			= GetConVarInt(FullKillLimit);
	HookEvent("player_death", Event_Playerdeath);
	HookEvent("round_end", Event_RoundEnd);
	
	RestartGame = FindConVar("mp_restartgame");
	if(RestartGame != INVALID_HANDLE)
		HookConVarChange(RestartGame, ConVarChanged)
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public OnConfigsExecuted()
{
    AutoExecConfig (true, "teamfraglimit");
}

public OnAllPluginsLoaded()
{
	if(LibraryExists("mapchooser"))
	{
		bMapChooser = true;
	}
}

public OnMapStart()
{
	CTPoints	= 0;
	TPoints	= 0;
	VoteStarted = false;
	CreateTimer(60.0, OnMapStartDelayed, TIMER_REPEAT);
}

public Action:OnMapStartDelayed(Handle:Timer)
{
	new PlayerCount = 0;
	new iMinPlayers = GetConVarInt(MinPlayers);
	for (new i = 0; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			PlayerCount++;
		}
	}
	if (iMinPlayers)
	{
		if (PlayerCount < iMinPlayers)
			KillLimit = GetConVarInt(MinPlayersKillLimit);
		if (PlayerCount >= iMinPlayers)
			KillLimit = GetConVarInt(FullKillLimit);
	}
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StrEqual(newVal, "1"))
	{
		CTPoints = 0;
		TPoints = 0;
	}
}

public Action:Event_Playerdeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl victimTeam, attackerTeam;
	attackerTeam = GetClientTeam(GetClientOfUserId(GetEventInt(event, "attacker")));
	victimTeam = GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid")));
	new iAnnounce = GetConVarInt(AnnounceInt);
	new iAnnounceType = GetConVarInt(AnnounceType);
	if (victimTeam != attackerTeam)
	{
		if (attackerTeam == 2)
		{
			TPoints++;
			if(GetConVarInt(GameType))
				SetTeamScore(2, TPoints);
		}
		else if (attackerTeam == 3)
		{
			CTPoints++;
			if(GetConVarInt(GameType))
				SetTeamScore(3, CTPoints);
		}
	}

	if(GetConVarInt(GameType))
	{
		if (TPoints >= KillLimit)
			TWin();
		else if (CTPoints >= KillLimit)
			CTWin();
	}

	if(iAnnounce >= 0)
	{
		if ((TPoints % iAnnounce == 0) && (TPoints > CTPoints) && !HasAnnounced && (TPoints < KillLimit))
			{
				new TRem = (KillLimit - TPoints);
				switch(iAnnounceType)
				{
				case 1:
					{
						PrintCenterTextAll("%t", "T_Frags_Remaining", TRem);
					}
				case 2:
					{
						PrintHintTextToAll("%t", "T_Frags_Remaining", TRem);
					}
				case 3:
					{
						PrintToChatAll("%t", "T_Frags_Remaining", TRem);
					}
				default:
					{
						PrintCenterTextAll("%t", "T_Frags_Remaining", TRem);
					}
				}
				HasAnnounced = true;
			}
		else if ((CTPoints % iAnnounce == 0) && (CTPoints > TPoints) && !HasAnnounced && (CTPoints < KillLimit))
			{
				new CTRem = (KillLimit - CTPoints);
				switch(iAnnounceType)
				{
				case 1:
					{
						PrintCenterTextAll("%t", "CT_Frags_Remaining", CTRem);
					}
				case 2:
					{
						PrintHintTextToAll("%t", "CT_Frags_Remaining", CTRem);
					}
				case 3:
					{
						PrintToChatAll("%t", "CT_Frags_Remaining", CTRem);
					}
				default:
					{
						PrintCenterTextAll("%t", "CT_Frags_Remaining", CTRem);
					}
				}
				HasAnnounced = true;
			}
		if ((CTPoints >= TPoints && CTPoints % iAnnounce != 0) || (TPoints >= CTPoints && TPoints % iAnnounce != 0))
		{
			HasAnnounced = false;
		}
	}
	
	if (bMapChooser && !VoteStarted && GetConVarInt(GameType))
	{
		new iVote = GetConVarInt(VoteInt);
		if (iVote > 0)
		{
			if ((TPoints >= KillLimit - iVote) || (CTPoints >= KillLimit - iVote))
			{
				StartMapVote();
			}
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Winner = GetEventInt(event, "winner");
	new Reason = GetEventInt(event, "reason");
	if(Winner == 2)
	{
		if(Reason == 0)
		{
			TPoints += GetConVarInt(BombBonus);
			CreateTimer(0.5, SetScores, Winner);
		}
	}
	else if(Winner == 3)
	{
		if(Reason == 6)
		{
			CTPoints += GetConVarInt(DefuseBonus);
			CreateTimer(0.5, SetScores, Winner);
		}
	}

	if(!GetConVarInt(GameType))
	{
		SetTeamScore(2, TPoints);
		SetTeamScore(3, CTPoints);
		if (TPoints >= KillLimit)
			TWin();
		else if (CTPoints >= KillLimit)
			CTWin();
	}

	if (bMapChooser && !VoteStarted && !GetConVarInt(GameType))
	{
		new iVote = GetConVarInt(VoteInt);
		if (iVote > 0)
		{
			if ((TPoints >= KillLimit - iVote) || (CTPoints >= KillLimit - iVote))
			{
				StartMapVote();
			}
		}
	}
}

public Action:SetScores(Handle:timer, any:Winner)
{
	SetTeamScore(2, TPoints);
	SetTeamScore(3, CTPoints);
	if (TPoints >= KillLimit)
		TWin();
	else if (CTPoints >= KillLimit)
		CTWin();
}

public Action:BoolsCheck(client, args)
{
	PrintToChat(client, "bMapChooser : %i", bMapChooser);
	PrintToChat(client, "GameType : %i", GetConVarInt(GameType));
	PrintToChat(client, "VoteStarted: %i", VoteStarted);
	return Plugin_Handled;
}

public Action:ResetScores(client, args)
{
	CTPoints = 0;
	TPoints = 0;
	SetTeamScore(2, (TPoints));
	SetTeamScore(3, (CTPoints));
	ReplyToCommand(client, "%t", "Admin_Scores_Reset");
	new iAnnounceType = GetConVarInt(AnnounceType);
	switch (iAnnounceType)
	{
		case 1:
		{
			PrintCenterTextAll("%t", "Scores_Reset");
		}
		case 2:
		{
			PrintHintTextToAll("%t", "Scores_Reset");
		}
		case 3:
		{
			PrintToChatAll("%t", "Scores_Reset");
		}
		default:
		{
			PrintCenterTextAll("%t", "Scores_Reset");
		}
	}
	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	new bool:bAutoSelect = GetConVarBool(AutoSelect);
	new Handle:lt = FindConVar("mp_limitteams");
	new ctcount = GetTeamClientCount(3);
	new tcount = GetTeamClientCount(2);
	if((ctcount - tcount < (GetConVarInt(lt))) && (tcount - ctcount < GetConVarInt(lt)))
	{
		decl String:arg[5];
		GetCmdArg(1, arg, sizeof(arg));
		if (StringToInt(arg) == 0)
		{
			if(bAutoSelect)
			{
				if(CTPoints != TPoints)
				{
					if(CTPoints < TPoints)
					{
						ChangeClientTeam(client, 3);
						return Plugin_Handled;
					}
					if(TPoints < CTPoints)
					{
						ChangeClientTeam(client, 2);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:EndGame()
{
	new iGameEnd  = FindEntityByClassname(-1, "game_end");
	if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) 
	{     
		LogError("Unable to create entity \"game_end\"!");
	} 
	else 
	{     
		AcceptEntityInput(iGameEnd, "EndGame");
	}
}

TWin()
{
	PrintCenterTextAll("%t", "T_Win");
	EndGame();
}

CTWin()
{
	PrintCenterTextAll("%t", "CT_Win");
	EndGame();
}

StartMapVote()
{
	InitiateMapChooserVote(MapChange:2)
	VoteStarted = true;
}

stock bool:IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	else
		return false;
} 
