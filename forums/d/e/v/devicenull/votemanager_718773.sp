#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "0.2"
public Plugin:myinfo =
{
	name = "L4D Vote Restrict",
	author = "devicenull",
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

#define CVAR_FLAGS FCVAR_PLUGIN

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
	CreateConVar("l4d_vote_manager",PLUGIN_VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
}
	
public Action:Callvote_Handler(client, args)
{
	new String:votetype[32], String:arg2[128];
	GetCmdArg(1,votetype,32);
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
		CHECK_ACCESS("Kick",cKickAccess)
		
		if (GetConVarBool(cKickImmunity))
		{
			new AdminId:source = GetUserAdmin(client);
			GetCmdArg(2,arg2,128);
			new curclient=-1, String:curname[128];
			for (new i=1;i<GetMaxClients();i++)
			{
				if (IsClientInGame(i))
				{
					GetClientName(i,curname,128);
					if (strcmp(curname,arg2,false) == 0)
					{
						curclient = i;
						break;
					}
				}
			}
			
			if (curclient != -1)
			{
				new AdminId:target = GetUserAdmin(curclient);
				if (!CanAdminTarget(source,target))
				{
					LogAction(client,curclient,"was prevented from starting a kick vote against");
					PrintToChat(client,"You do not have access to votekick that user");
					return Plugin_Handled;
				}
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