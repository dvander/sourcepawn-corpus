#include <sourcemod>
#define L4D_MAXCLIENTS_PLUS1 19

new Handle:voteDuration;
new String:voteNames[2][3][MAX_NAME_LENGTH];
new voteNameIndex[2];
/*
There are 4 teams.
idx: 0, name: Unassigned
idx: 1, name: Spectator
idx: 2, name: Survivor
idx: 3, name: Infected
* Ignore all but 2 and 3 by subtracting 2 from each team event argument
*/
public Plugin:myinfo = 
{
	name = "Votekick Autoban",
	author = "n0limit",
	description = "Automatically bans any player for sm_autoban_duration minutes who was votekicked via the in-game menu",
	version = "1.3",
	url = "https://forums.alliedmods.net/showthread.php?t=93482"
}

public OnPluginStart()
{
	voteDuration = CreateConVar("sm_autoban_duration","5","autoban time in minutes. Use 0 for permanent", FCVAR_NOTIFY);
	
	for(new i=0; i < sizeof(voteNameIndex);i++)
		voteNameIndex[i] = 0;
	
	HookEvent("vote_passed",Event_VotePassed);
	HookEvent("vote_failed",Event_VoteFailed);
	HookEvent("vote_cast_yes",Event_VoteCastYes);
}

public Event_VotePassed(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:details[64];
	decl String:param1[64]; //param1 will be the user who was kicked
	decl String:playerName[MAX_NAME_LENGTH];
	decl String:kickReason[MAX_NAME_LENGTH * 4]; //3 player names + extra
	new team;
	new i; //player iterator
	
	GetEventString(event,"details",details,sizeof(details));
	GetEventString(event,"param1",param1,sizeof(param1));
	team = GetEventInt(event,"team");
	team = team - 2; //decrease by 2 to ignore unassigned and spectator teams
	
	if(StrEqual(details,"#L4D_vote_passed_kick_player",false))
	{
		for (i = 1; i < L4D_MAXCLIENTS_PLUS1; i++)
		{
			if( IsClientInGame(i) && !IsFakeClient(i))
			{ //real player
				GetClientName(i,playerName,sizeof(playerName));
				if(StrEqual(playerName,param1))
				{ //player being kicked
					//See if we have a record of the players who voted yes
					switch(voteNameIndex[team])
					{ //1 has no majority
						//case 2:
						//{
						//	Format(kickReason,sizeof(kickReason),"AutoBan: Votekicked by %s and %s.",voteNames[team][0], voteNames[team][1]);
						//}
						//case 3:
						//{
						//	Format(kickReason,sizeof(kickReason),"AutoBan: Votekicked by %s, %s and %s.",voteNames[team][0], voteNames[team][1], voteNames[team][2]);
						//}
						default:
						{
							Format(kickReason,sizeof(kickReason), "AutoBan: banned for being votekicked");
						}
					}
					ServerCommand("sm_ban #%d %d \"%s\"",GetClientUserId(i),GetConVarInt(voteDuration),kickReason);
				}
			}
		}
	}
	//reset voteNameIndex to 0
	if(team >= 0)
		voteNameIndex[team] = 0;
}

public Event_VoteFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event,"team");
	team = team - 2; //decrease by 2 to ignore unassigned and spectator teams
	//reset name list
	if(team >= 0)
		voteNameIndex[team] = 0;
}

public Event_VoteCastYes(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event,"team");
	new entity = GetEventInt(event, "entityid");

	team = team - 2; //decrease by 2 to ignore unassigned and spectator teams

	if(IsValidEntity(entity) && team >= 0)
	{ //valid player and team slot, save his name
		//GetClientName(entity,voteNames[team][voteNameIndex[team]++], MAX_NAME_LENGTH);
	}
}
