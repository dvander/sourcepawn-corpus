/**
 * smcash.sp
 * Implements sm_cash command
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "Sm_Cash",
	author = "ferret",
	description = "Basic Chat Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new g_iAccount = -1;

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	if (g_iAccount == -1)
	{
		PrintToServer("[smcash] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}

	LoadTranslations("common.phrases");
	LoadTranslations("plugin.smcash");

	CreateConVar("sm_smcash_version", PLUGIN_VERSION, "SmCash Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_cash", Command_SmCash, ADMFLAG_BAN, "sm_cash <name or #userid or all/t/ct> <amount> - Set target's cash to amount.");
}

public Action:Command_SmCash(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cash <name or #userid or all/t/ct> <amount>");
		return Plugin_Handled;	
	}
	
	new String:szArg[65];
	GetCmdArg(1, szArg, sizeof(szArg));

	new iAmount;
	decl String:szAmount[64];
	GetCmdArg(2, szAmount, 64);
	iAmount = StringToInt(szAmount);
	
	if(iAmount == 0 && szAmount[0] != '0')
	{
		ReplyToCommand(client, "[SM] %t", "Invalid Amount");
		return Plugin_Handled;
	}
	
	if(strcmp(szArg, "all", false) == 0)
	{
		new iMaxClients = GetMaxClients();
		
		for (new i = 1; i <= iMaxClients; i++)
		{
				if (IsClientInGame(i))
					SetMoney(i, iAmount);
		}
		
		ShowActivity(client, "%T", "Set All Cash", LANG_SERVER, iAmount);		
	}
	else if(strcmp(szArg, "t", false) == 0 || strcmp(szArg, "ct", false) == 0)
	{
		new iMaxClients = GetMaxClients();
		
		for (new i = 1; i <= iMaxClients; i++)
		{
				if (IsClientInGame(i))
				{
					if(GetClientTeam(i) == (strcmp(szArg, "t", false) == 0 ? 2 : 3))
						SetMoney(i, iAmount);
				}
		}
		
		ShowActivity(client, "%T", "Set Team Cash", LANG_SERVER, (strcmp(szArg, "t", false) == 0 ? "Terrorist" : "Counter-Terrorist"), iAmount);				
	}
	else
	{
		new iClients[2];
		new iNumClients = SearchForClients(szArg, iClients, 2);
	
		if (iNumClients == 0)
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
			return Plugin_Handled;
		}
		else if (iNumClients > 1)
		{
			ReplyToCommand(client, "[SM] %t", "More than one client matches", szArg);
			return Plugin_Handled;
		}
		else if (!CanUserTarget(client, iClients[0]))
		{
			ReplyToCommand(client, "[SM] %t", "Unable to target");
			return Plugin_Handled;
		}
		
		decl String:szName[64];
		GetClientName(iClients[0], szName, 64);
		
		SetMoney(iClients[0], iAmount);
		
		ShowActivity(client, "%T", "Set Player Cash", LANG_SERVER, szName, iAmount);
	}
		
	return Plugin_Handled;
}

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
		SetEntData(client, g_iAccount, amount);
}

public GetMoney(client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount);

	return 0;
}