#pragma semicolon 1

/*
 *	SM Bank
 *	by MaTTe (mateo10)
 */

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "SM Bank",
	author = "MaTTe",
	description = "Player is allowed to put money in his bank, and take them out when he needs them",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

new g_iBank[MAXPLAYERS + 1];
new g_iAccount = -1;

public OnPluginStart()
{
	CreateConVar("smbank_version", VERSION, "SM Bank Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	LoadTranslations("plugin.smbank");

	RegConsoleCmd("deposit", Deposit);
	RegConsoleCmd("withdraw", WithDraw);
	RegConsoleCmd("bankstatus", BankStatus);

	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	HookEvent("round_start", EventRoundStart);
}

public OnClientPutInServer(client)
{
	g_iBank[client] = 0;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("%t", "Available commands", "\x04", "\x01");
}

public Action:Deposit(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "%t", "Deposit usage", "\x04", "\x01");
		return Plugin_Handled;
	}

	new String:szCmd[12];
	GetCmdArg(1, szCmd, sizeof(szCmd));

	if(StrEqual(szCmd, "all"))
	{
		g_iBank[client] += GetMoney(client);
		PrintToChat(client, "%t", "Deposit successfully", GetMoney(client), "\x04", "\x01");
		SetMoney(client, 0);
	}
	else
	{
		new iMoney = StringToInt(szCmd);

		if(GetMoney(client) < iMoney)
		{
			PrintToChat(client, "%t", "Deposit not enough money", "\x04", "\x01");
		}
		else
		{
			g_iBank[client] += iMoney;
			SetMoney(client, GetMoney(client) - iMoney);
			PrintToChat(client, "%t", "Deposit successfully", iMoney, "\x04", "\x01");
		}
	}

	return Plugin_Handled;
}

public Action:WithDraw(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "%t", "Withdraw usage", "\x04", "\x01");
	}

	new String:szCmd[12];
	GetCmdArg(1, szCmd, sizeof(szCmd));

	if(StrEqual(szCmd, "all"))
	{
		new iBalance = 16000 - GetMoney(client);

		if(g_iBank[client] < iBalance)
		{
			SetMoney(client, GetMoney(client) + g_iBank[client]);
			PrintToChat(client, "%t", "Withdraw successfully", g_iBank[client], "\x04", "\x01");
			g_iBank[client] = 0;
		}
		else
		{
			SetMoney(client, 16000);
			PrintToChat(client, "%t", "Withdraw successfully", iBalance, "\x04", "\x01");
			g_iBank[client] -= iBalance;
		}
	}
	else
	{
		new iMoney = StringToInt(szCmd);

		if(g_iBank[client] < iMoney)
		{
			PrintToChat(client, "%t", "Withdraw not enough money", "\x04", "\x01");
			return Plugin_Handled;
		}

		if(GetMoney(client) + iMoney <= 16000)
		{
			SetMoney(client, GetMoney(client) + iMoney);
			PrintToChat(client, "%t", "Withdraw successfully", iMoney, "\x04", "\x01");
			g_iBank[client] -= iMoney;
		}
		else
		{
			PrintToChat(client, "%t", "Withdraw max error", "\x04", "\x01");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public Action:BankStatus(client, args)
{
	PrintToChat(client, "%t", "Bankstatus", g_iBank[client], "\x04", "\x01");
	return Plugin_Handled;
}

public SetMoney(client, amount)
{
	if(g_iAccount != -1)
	{
		SetEntData(client, g_iAccount, amount);
	}
}

public GetMoney(client)
{
	if(g_iAccount != -1)
	{
		return GetEntData(client, g_iAccount);
	}

	return 0;
}