#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.3"

public Plugin:myinfo =
{
	name = "L4D Vote Restrict",
	author = "devicenull, lep",
	description = "Enforce access levels for L4D voting",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:cLobbyAccess;
new Handle:cDifficultyAccess;
new Handle:cLevelAccess;
new Handle:cRestartAccess;
new Handle:cKickAccess;
new Handle:cKickImmunity;
new Handle:cSendToLog;

#define CVAR_FLAGS FCVAR_PLUGIN
#define TEAM_SPECTATOR 1

#define CHECK_ACCESS(%1,%2) if (!CheckVoteAccess(client,%2)) { LogClient(client,"was prevented from starting a %s vote",%1); PrintToChat(client,"You do not have access to start a %s vote",%1); return Plugin_Handled; }

public OnPluginStart()
{
	RegConsoleCmd("callvote",Callvote_Handler);
	cLobbyAccess = CreateConVar("l4d_vote_lobby_access","","Access level needed to start a return to lobby vote",CVAR_FLAGS);
	cDifficultyAccess = CreateConVar("l4d_vote_difficulty_access","","Access level needed to start a change difficulty vote",CVAR_FLAGS);
	cLevelAccess = CreateConVar("l4d_vote_level_access","","Access level needed to start a change level vote",CVAR_FLAGS);
	cRestartAccess = CreateConVar("l4d_vote_restart_access","","Access level needed to start a restart level vote",CVAR_FLAGS);
	cKickAccess = CreateConVar("l4d_vote_kick_access","","Access level needed to start a kick vote",CVAR_FLAGS);
	cKickImmunity = CreateConVar("l4d_vote_kick_immunity","0","Make votekick respect admin immunity",CVAR_FLAGS,true,0.0,true,1.0);
	cSendToLog = CreateConVar("l4d_vote_log", "0", "Log voting data",CVAR_FLAGS,true,0.0,true,1.0);
	CreateConVar("l4d_vote_manager",PLUGIN_VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
}
	
public Action:Callvote_Handler(client, args)
{
	new log = GetConVarBool(cSendToLog);
	new String:votetype[32];
	decl String:sInitiator[32];
	GetClientName(client, sInitiator, sizeof(sInitiator));
	GetCmdArg(1,votetype,32);
	PrintToChatAll("\x04[SM] \x01%s initiated a %s vote", sInitiator, votetype);
	if (log)
		LogMessage("%s initiated a %s vote", sInitiator, votetype);
		
	if (strcmp(votetype,"ReturnToLobby",false) == 0)
	{
		CHECK_ACCESS("ReturnToLobby",cLobbyAccess)
	}
	else if (strcmp(votetype,"ChangeDifficulty",false) == 0)
	{
		CHECK_ACCESS("ChangeDifficulty",cDifficultyAccess)
	}
	else if (strcmp(votetype,"ChangeMission",false) == 0)
	{
		CHECK_ACCESS("ChangeMission",cLevelAccess)
	}
	else if (strcmp(votetype,"RestartGame",false) == 0)
	{
		CHECK_ACCESS("RestartGame",cRestartAccess)
	}
	else if (strcmp(votetype,"Kick",false) == 0)
	{
		// Forbid Spectator team from kicking
		new clientTeam = GetClientTeam(client);
		if (clientTeam == TEAM_SPECTATOR)
		{
			PrintToChatAll("\x04[SM] \x01Spectators cannot initiate kick votes");
			if (log)
				LogMessage("Spectators cannot initiate kick votes");
			return Plugin_Handled;
		}

		// Check if the "cKickAccess" flag prevents the client from kicking entirely
		CHECK_ACCESS("Kick",cKickAccess)

		// 'arg2' is the second argument to Callvote_Handler, which is the UserId of the target
		// 'target' is the targeted client
		// 'sTarget' is the name of the user being targeted
		decl String:arg2[12];
		GetCmdArg(2, arg2, sizeof(arg2));
		new target = GetClientOfUserId(StringToInt(arg2));
		decl String:sTarget[32];
		GetClientName(target, sTarget, sizeof(sTarget));
		
		// Printing and logging notification
		PrintToChatAll("\x04[SM] \x01Votekick target is %s", sTarget);
		if (log)
			LogMessage("Votekick target is %s", sTarget);

		// If the "cKickImmunity" flag is set, we have to check admin rights of the client and target
		if (GetConVarBool(cKickImmunity))
		{
			// If the target is an admin, the client must be able to 'admin' the target
			new AdminId:clientAdminId = GetUserAdmin(client);
			new AdminId:targetAdminId = GetUserAdmin(target);
			if (!CanAdminTarget(clientAdminId, targetAdminId))
			{
				// Tell client they can't kick the admin
				PrintToChat(client, "\x04[SM] \x01You do not have access to votekick that user");
				// Tell admin who was trying to kick them
				PrintToChat(target, "\x04[SM] \x01%s has made an attempt to kick you from the server!", sInitiator);

				if (log)
					LogMessage("%s does not have rights to admin %s", sInitiator, sTarget);
				
				return Plugin_Handled;
			}
			else
			{
				if (log)
					LogMessage("%s has rights to admin %s", sInitiator, sTarget);
			}
		}
	}
	return Plugin_Continue;
}

public CheckVoteAccess(client,Handle:accvar)
{
	new String:acclvl[16];
	GetConVarString(accvar,acclvl,16);
	if (strlen(acclvl) == 0) return true;
	new access = ReadFlagString(acclvl);
	
	if (GetUserFlagBits(client)&access > 0) return true;
	
	return false;
	
}

public LogClient(client,String:format[], any:...)
{
	new String:buffer[512];
	VFormat(buffer,512,format,3);
	new String:name[128];
	new String:steamid[64];
	new String:ip[32];
	
	GetClientName(client,name,128);
	GetClientAuthString(client,steamid,64);
	GetClientIP(client,ip,32);
	
	LogAction(client,-1,"<%s><%s><%s> %s",name,steamid,ip,buffer);
}