#include <sourcemod>
#include <sdktools>
#include <tf2>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo = {
	name        = "[Any] Who's Free?",
	author      = "DarthNinja",
	description = "List Free2Play players",
	version     = PLUGIN_VERSION,
	url         = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_whosfree_version", PLUGIN_VERSION, "Who's free?", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_whosfree", WhosFree, "List Free2Play and Premium players with totals");
	RegConsoleCmd("whosfree", WhosFree, "List Free2Play and Premium players with totals");
	
	RegConsoleCmd("listfree", ShowFree, "List Free2Play players");
	RegConsoleCmd("showfree", ShowFree, "List Free2Play players");
	RegConsoleCmd("listprem", ShowPremium, "List Premium players");
	RegConsoleCmd("showprem", ShowPremium, "List Premium players");
	LoadTranslations("common.phrases");
}


public Action:ShowFree(client, args)
{
	new iPlayers = 0;
	decl String:TeamName[25];
	ReplyToCommand(client, "Free Players:\n-----------------------");
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}			
		if (Steam_CheckClientSubscription(i, 0) && !Steam_CheckClientDLC(i, 459))
		{
			new iTeam = GetClientTeam(i);
			if (iTeam == 0)
				iTeam ++;  //Roll unassigned and spec players into one group
				
			GetTeamName(iTeam, TeamName, sizeof(TeamName));
			ReplyToCommand(client, "   %N - Free2Play - Team %s", i, TeamName);
			iPlayers++;
		}
	}
	ReplyToCommand(client, "-----------------------\n%i Free Players Total.\n-----------------------", iPlayers);
	return Plugin_Handled;
}

public Action:ShowPremium(client, args)
{
	new iPlayers = 0;
	decl String:TeamName[25];
	ReplyToCommand(client, "Premium Players:\n-----------------------");
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}			
		if (!(Steam_CheckClientSubscription(i, 0) && !Steam_CheckClientDLC(i, 459)))
		{
			new iTeam = GetClientTeam(i);
			if (iTeam == 0)
				iTeam ++;  //Roll unassigned and spec players into one group
			
			GetTeamName(iTeam, TeamName, sizeof(TeamName));
			ReplyToCommand(client, "   %N - Premium - Team %s", i, TeamName);
			iPlayers++;
		}
	}
	ReplyToCommand(client, "-----------------------\n%i Premium Players Total.\n-----------------------", iPlayers);
	return Plugin_Handled;
}


public Action:WhosFree(client, args)
{
	if (args != 1)
	{
		//Stats
		new iFreeTeam[5] = 0;
		new iPremTeam[5] = 0;
		new iPrem = 0;
		new iFree = 0;

		decl String:TeamName[25];

		ReplyToCommand(client, "Players:\n-----------------------");
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientAuthorized(i) || !IsClientInGame(i) || IsFakeClient(i))
			{
				continue;
			}
			
			new iTeam = GetClientTeam(i);
			if (iTeam == 0)
				iTeam ++;  //Roll unassigned and spec players into one group
			
			GetTeamName(iTeam, TeamName, sizeof(TeamName));
			
			if (Steam_CheckClientSubscription(i, 0) && !Steam_CheckClientDLC(i, 459))
			{
				ReplyToCommand(client, "   %N - Free2Play - Team %s", i, TeamName);
				iFree++;
				iFreeTeam[iTeam] ++;
			}
			else
			{
				ReplyToCommand(client, "   %N - Premium - Team %s", i, TeamName);
				iPrem++;
				iPremTeam[iTeam] ++;
			}
		}
		ReplyToCommand(client, "-----------------------\nTotals:\n   Free: %i\n   Premium: %i", iFree, iPrem);
		ReplyToCommand(client, "Teams:\n   Red:\n      Free: %i\n      Prem: %i", iFreeTeam[TFTeam_Red], iPremTeam[TFTeam_Red]);
		ReplyToCommand(client,"   Blue:\n      Free: %i\n      Prem: %i", iFreeTeam[TFTeam_Blue], iPremTeam[TFTeam_Blue]);
		ReplyToCommand(client,"   Spectator:\n      Free: %i\n      Prem: %i\n-----------------------", iFreeTeam[TFTeam_Spectator], iPremTeam[TFTeam_Spectator]);
	}
	else
	{
		decl String:buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer))
		new i = FindTarget(client, buffer, true, false);
		if (!IsClientAuthorized(i) || i == -1)
		{
			ReplyToCommand(client, "Player cannot be found!");
			return Plugin_Handled;
		}
		if (Steam_CheckClientSubscription(i, 0) && !Steam_CheckClientDLC(i, 459))
		{
			ReplyToCommand(client, "%N is Free2Play", i);
		}
		else
		{
			ReplyToCommand(client, "%N is Premium", i);
		}
	}
	return Plugin_Handled;
}