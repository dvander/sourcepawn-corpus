#include <sourcemod>

#define PLUGIN_VERSION "1.0.3"

// You may set these:
#define START_MONEY 500
#define MAX_STEAL 50
#define DBHANDLE "default"
#define TABLENAME "tf2money"

public Plugin:myinfo = 
{
	name = "Money for TF2",
	author = "GachL",
	description = "Money for TF2",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

new Handle:db;
new startmoney = START_MONEY;
new maxsteal = MAX_STEAL;
new String:tablename[64] = TABLENAME;

public OnPluginStart()
{
	CreateConVar("sm_money_version", PLUGIN_VERSION, "Money for TF2 plugin version", FCVAR_PLUGIN | FCVAR_PROTECTED);
	if (SQL_CheckConfig(DBHANDLE))
	{
		new String:error[255];
		db = SQL_Connect(DBHANDLE,true,error, sizeof(error));
		if (db == INVALID_HANDLE)
		{
			PrintToServer("[$$] Failed to connect: %s", error);
			return;
		}
	}
	else
	{
		PrintToServer("[$$] Failed to connect: DB %s not found", DBHANDLE);
		return;
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	CreateTimer(80.0, InfoTimer, _, TIMER_REPEAT);
}

public Action:InfoTimer(Handle:timer)
{
	PrintToChatAll("\x04[\x03$$\x04]\x01 You earn money on this server! Type !money for informations.");
	return Plugin_Continue;
}

public Action:Command_Say(client, args)
{
	/* Credits for this part go to r5053,
	 * I stole it from his N1G TF2 ranking
	 * plugin
	 */
	new String:text[512], String:command[512];
	new startidx = 0;
	GetCmdArgString(text, sizeof(text));
	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}
	if (strcmp(text[startidx], "!money", false) != 0)
	{
		return Plugin_Continue;
	}
	/* End of r5053s part */

	if (client < 1)
	{
		return Plugin_Handled;
	}
	new String:steamId[64];
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:qry[64];
	Format(qry, sizeof(qry), "SELECT money FROM %s WHERE steamid = '%s';", tablename, steamId);
	new Handle:qMoney = SQL_Query(db, qry);
	new iCurrentMoney = startmoney;
	if (SQL_GetRowCount(qMoney) == 1)
	{
		SQL_FetchRow(qMoney);
		iCurrentMoney = SQL_FetchInt(qMoney, 0);
	}
	
	PrintToChat(client, "\x04[\x03$$\x04]\x01 If you kill a player you steal some of his money.");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 You can buy reserved slots with it!");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 Prices:");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 1 month  - $2000");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 3 months - $5400");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 6 months - $8800");
	PrintToChat(client, "\x04[\x03$$\x04]\x01 You currently own \x04$%d\x01.", iCurrentMoney);
	return Plugin_Handled;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new victimId = GetEventInt(event, "userid");
	new attacker = GetClientOfUserId(attackerId);
	new victim = GetClientOfUserId(victimId);
	
	if ((attacker < 1) || (victim < 1))
	{
		return;
	}
	
	if (!IsClientConnected(attacker) || !IsClientConnected(victim))
	{
		return;
	}
	
	if (!IsClientInGame(attacker) || !IsClientInGame(victim))
	{
		return;
	}

	if (victim == attacker)
	{
		return; // suicide :(
	}
	
	new String:steamIdattacker[64];
	new String:steamIdvictim[64];
	GetClientAuthString(attacker, steamIdattacker, sizeof(steamIdattacker));
	GetClientAuthString(victim, steamIdvictim, sizeof(steamIdvictim));
	new String:vname[128];
	GetClientName(victim, vname, sizeof(vname));
	new String:aname[128];
	GetClientName(attacker, aname, sizeof(aname));
	
	if (!CheckUser(attacker) || !CheckUser(victim))
	{
		PrintToServer("[$$] Failed to process user.");
	}
	
	new String:qry1[128];
	new String:qry2[128];
	Format(qry1, sizeof(qry1), "SELECT money FROM %s WHERE steamid = '%s';", tablename, steamIdattacker);
	Format(qry2, sizeof(qry2), "SELECT money FROM %s WHERE steamid = '%s';", tablename, steamIdvictim);

	new Handle:qAttack = SQL_Query(db, qry1);
	SQL_FetchRow(qAttack);
	new iMoneyAttacker = SQL_FetchInt(qAttack, 0);
	
	new Handle:qVict = SQL_Query(db, qry2);
	SQL_FetchRow(qVict);
	new iMoneyVictim = SQL_FetchInt(qVict, 0);
	
	if (iMoneyVictim == 0)
	{
		PrintToChat(attacker, "\x04[\x03$$\x04]\x01 Unfortunately %s had no money.", vname);
		return;
	}
	
	
	new iStoleMoney = 0;
	
	if (iMoneyVictim < maxsteal)
	{
		iStoleMoney = GetRandomInt(1, iMoneyVictim);
	}
	else
	{
		iStoleMoney = GetRandomInt(1, maxsteal);
	}
	
	PrintToChat(attacker,"\x04[\x03$$\x04]\x01 You stole $%d from %s. You have now $%d.", iStoleMoney, vname, (iMoneyAttacker + iStoleMoney));
	PrintToChat(victim,"\x04[\x03$$\x04]\x01 %s stole $%d from you. You have now $%d.", aname, iStoleMoney, (iMoneyVictim - iStoleMoney));
	PrintToServer("[$$] %s stole %s $%d! Now they have $%d and $%d.", aname, vname, iStoleMoney, (iMoneyAttacker + iStoleMoney), (iMoneyVictim - iStoleMoney));
	
	Format(qry1, sizeof(qry1), "UPDATE %s SET money = %d WHERE steamid = '%s';", tablename, (iMoneyAttacker + iStoleMoney), steamIdattacker);
	Format(qry2, sizeof(qry2), "UPDATE %s SET money = %d WHERE steamid = '%s';", tablename, (iMoneyVictim - iStoleMoney), steamIdvictim);
	
	SQL_FastQuery(db, qry1);
	SQL_FastQuery(db, qry2);
}

public CheckUser(user)
{
	new String:steamid[64];
	new String:name[128];
	GetClientAuthString(user, steamid, sizeof(steamid));
	GetClientName(user, name, sizeof(name));
	
	new String:qry[64];
	Format(qry, sizeof(qry), "SELECT * FROM %s WHERE steamid = \"%s\";", tablename, steamid);
	
	new Handle:query = SQL_Query(db, qry);
	if (query == INVALID_HANDLE)
	{
		return false;
	}
	else
	{
		if (SQL_GetRowCount(query) == 0)
		{
			new String:qry2[128];
			Format(qry2, sizeof(qry2), "INSERT INTO %s VALUES (\"%s\", \"%s\", %d);", tablename, steamid, name, startmoney);
			SQL_FastQuery(db, qry2);
		}
	}
	return true;
}
