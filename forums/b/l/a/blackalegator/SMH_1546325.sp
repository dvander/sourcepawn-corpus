#include <sourcemod>
#include <steamtools>
#include <tf2>
#include <sdktools>
#include <colors>

#define SMH_VERSION "1.0"

new bool:roundrestart=false, ibuf;

new Handle:cv_enabled, Handle:cv_restart, Handle:cv_scramble, Handle:cv_restarttime, Handle:cv_resetrounds_enabled, Handle:cv_resetrounds_rounds, Handle:cv_roundrestart_minclients;

public Plugin:myinfo = 
{
	name = "Single Map Handler",
	author = "blackalegator",
	description = "Plugin that helps you on a single map server",
	version = SMH_VERSION,
	url = ""
}

public OnPluginStart()
{
	cv_enabled = CreateConVar("sm_smh_enabled", "1", "Enable/disable UpdateNotifier");
	cv_restart = CreateConVar("sm_smh_restart", "1", "Set restart handling: 0 = No restart caused by the plugin, restart is done by autoupdate on mapchange; 1 = restart server");
	cv_restarttime = CreateConVar("sm_smh_restartdelay", "5.0", "Set the time between the Warning and the restart if minclients is not reached", _, true, 0.1);
	cv_resetrounds_enabled = CreateConVar("sm_smh_resetrounds_enabled", "1", "Should rounds be reset?");
	cv_resetrounds_rounds = CreateConVar("sm_smh_resetrounds_rounds", "5", "After which limit of rounds should they be reset?");
	cv_scramble = CreateConVar("sm_smh_scramble", "1", "Should players be scrambled on round reset?");
	cv_roundrestart_minclients = CreateConVar("sm_smh_restart_minclients", "16", "Minimum ammount of clients, which will block the server update");
	CreateConVar("sm_smh_version", SMH_VERSION, "Shows current plugin version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true);
	
	HookEvent("teamplay_round_win", EndRound, EventHookMode_PostNoCopy);
}

public OnClientDisconnect_Post(client)
{
	if (roundrestart)
		CheckRestart();
}

public Action:Steam_RestartRequested()
{
	if (GetConVarBool(cv_enabled))
	{
		LogMessage("Restart quened");
		PrintToChatAll("%t", "restart_quened");
		
		if (GetConVarInt(cv_restart))
		{
			CreateTimer(GetConVarFloat(cv_restarttime), Timer_Restart);
			roundrestart = true;
		}
	}
	
	return Plugin_Continue;
}

public EndRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	new redscore, bluescore, allscore, roundslimit;
	redscore = GetTeamScore(_:TFTeam_Red);
	bluescore = GetTeamScore(_:TFTeam_Blue);
	allscore = redscore + bluescore;
	
	roundslimit = GetConVarInt(cv_resetrounds_rounds);
	
	if (GetConVarBool(cv_resetrounds_enabled)&&GetConVarBool(cv_enabled)&&redscore!=bluescore&&allscore>=roundslimit)
	{
		if(redscore>bluescore)
			{
				for (ibuf = GetClientCount(true); ibuf>0; ibuf--)
					CPrintToChat(ibuf, "%t", "red_won");
			}
		if(bluescore>redscore)
			{
				for (ibuf = GetClientCount(true); ibuf>0; ibuf--)
					CPrintToChat(ibuf, "%t", "blue_won");
			}

		SetTeamScore(_:TFTeam_Red, 0);
		SetTeamScore(_:TFTeam_Blue, 0);
		CPrintToChatAll("{olive}---===SMH by blackalegator===---");
		LogMessage("Rounds reset due to round limit reached");
		
		if (GetConVarBool(cv_scramble))
		{
			ServerCommand("mp_scrambleteams");
			LogMessage("Scrambled teams due to round end");
		}
		
	}
	
	if (roundrestart)
	{
		new String:buffer[200];
		GetCurrentMap(buffer, sizeof(buffer));
		ForceChangeLevel(buffer, "Server update required");
	}
}

public Action:Timer_Restart(Handle:timer)
{
	CheckRestart();
}

public CheckRestart()
{
	new minclients = GetConVarInt(cv_roundrestart_minclients);
	
	if (GetClientCount(true) < minclients && GetConVarInt(cv_restart) == 1)
	{
		new String:buffer[200];
		GetCurrentMap(buffer, sizeof(buffer));
		ForceChangeLevel(buffer, "Server update required");
	}
}

