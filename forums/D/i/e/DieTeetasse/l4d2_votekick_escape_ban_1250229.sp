#include <sourcemod>
#pragma semicolon 1

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.2"

/**
 * Plugin history:
 * ---------------------------
 *
 * v1.2:
 * - blocking new votes if old one is still active
 * - trying to kick the banned one again after 15 seconds
 *
 * v1.1:
 * - added version cvar
 * - output will display cvar sv_vote_kick_ban_duration 
 * - the check timer is now using the value of sv_vote_timer_duration
 *
 */

public Plugin:myinfo =
{
	name = "Votekick Escape Ban",
	author = "Die Teetasse",
	description = "This plugins will ban a player who disconnects before the votekick ended.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1250229"
};

new bool:isVictimAlreadyBanned = false;
new bool:isVoteKickActive = false;
new Handle:hCvarBanTime;
new String:voteVictimName[MAX_NAME_LENGTH];
new String:voteVictimSteamid[32];
new votesNo = 0;
new votesYes = 0;

public OnPluginStart()
{
	CreateConVar("l4d2_votekickban_version", PLUGIN_VERSION, "Votekick Escape Ban - Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hCvarBanTime = CreateConVar("l4d2_votekickban_bantime", "15", "Votekick Escape Ban - Ban time for excapers in minutes. (0 = permanent)", CVAR_FLAGS);

	RegConsoleCmd("callvote", Cmd_CallVote);
	HookEvent("vote_cast_yes", Event_VoteYes);
	HookEvent("vote_cast_no", Event_VoteNo);
	HookEvent("server_addban", Event_BanAdded);
}

public Action:Cmd_CallVote(client, args)
{
	decl String:voteCommand[32];
	GetCmdArg(1, voteCommand, sizeof(voteCommand));
	
	//too prevent a new vote try messing the old one
	if (isVoteKickActive) return Plugin_Continue;
	
	isVoteKickActive = false;
	if (!StrEqual(voteCommand, "Kick", false)) return Plugin_Continue;
	
	decl String:tempUserId[MAX_NAME_LENGTH];
	GetCmdArg(2, tempUserId, sizeof(tempUserId));
	
	new victimId = GetClientOfUserId(StringToInt(tempUserId));
	
	if (victimId == 0) return Plugin_Continue;
	if (!IsClientInGame(victimId)) return Plugin_Continue;
	if (IsFakeClient(victimId)) return Plugin_Continue;
	
	GetClientName(victimId, voteVictimName, sizeof(voteVictimName));	
	GetClientAuthString(victimId, voteVictimSteamid, sizeof(voteVictimSteamid));
	
	votesNo = 0;
	votesYes = 0;
	isVoteKickActive = true;
	isVictimAlreadyBanned = false;
		
	PrintToChatAll("Votekick open for %s. Disconnecting will not help.", voteVictimName);
		
	CreateTimer(float(GetConVarInt(FindConVar("sv_vote_timer_duration")) + 5), Timer_CallEnd, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Event_VoteYes(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isVoteKickActive) votesYes++;
	return Plugin_Continue;
}

public Action:Event_VoteNo(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isVoteKickActive) votesNo++;
	return Plugin_Continue;
}

public Action:Event_BanAdded(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:banSteamID[64];
	GetEventString(event, "networkid", banSteamID, sizeof(banSteamID));
	
	if (StrEqual(banSteamID, voteVictimSteamid, false)) isVictimAlreadyBanned = true;
	return Plugin_Continue;
}

public Action:Timer_CallEnd(Handle:timer)
{
	if (votesYes <= votesNo)
	{
		PrintToChatAll("Votekick against %s failed (%d Yes, %d No).", voteVictimName, votesYes, votesNo);
		return Plugin_Continue;
	}
	
	if (isVictimAlreadyBanned)
	{
		PrintToChatAll("Votekick against %s [%s] succeeded (%d Yes, %d No). Standard %d min ban.", voteVictimName, voteVictimSteamid, votesYes, votesNo, GetConVarInt(FindConVar("sv_vote_kick_ban_duration")));
	}
	else 
	{
		//disconnected before. add x min ban.
		new banTime = GetConVarInt(hCvarBanTime);
		BanIdentity(voteVictimSteamid, banTime, BANFLAG_AUTHID, "You got banned by vote!");
		PrintToChatAll("Votekick against %s [%s] succeeded (%d Yes, %d No). Trying to escape, %d min ban.", voteVictimName, voteVictimSteamid, votesYes, votesNo, banTime);
		
		//kick if he maybe rejoined in time
		if (!KickClientBySteamId(voteVictimSteamid))
		{
			//try another kick in 15 seconds (slowloader -.-)
			new Handle:tempSteamIdStack = CreateStack();
			PushStackString(tempSteamIdStack, voteVictimSteamid);
		
			CreateTimer(15.0, Timer_TryKickAgain, tempSteamIdStack);
		}
	}
	
	return Plugin_Continue;
}
		
public Action:Timer_TryKickAgain(Handle:timer, any:tempSteamIdStack)
{
	decl String:steamId[64];
	PopStackString(tempSteamIdStack, steamId, sizeof(steamId));
	CloseHandle(tempSteamIdStack);
	
	KickClientBySteamId(steamId);
}
		
//true if kick, false if not
bool:KickClientBySteamId(const String:steamId[])
{
	decl String:tempId[64];
	
	for (new i = 1; i < (MaxClients+1); i++) 
	{
		if (!IsClientInGame(i)) continue;
		if (IsFakeClient(i)) continue;
		
		GetClientAuthString(i, tempId, sizeof(tempId));
		
		if (StrEqual(steamId, tempId, false))
		{
			KickClient(i, "You got banned by vote!");
			return true;
		}
	}
	
	return false;
}			