#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

// Thanks to Ferret for original inspiration
public Plugin:myinfo = 
{
	name = "SM Cash",
	author = "brizad",
	description = "Cash Give/Take",
	version = PLUGIN_VERSION,
	url = "http://www.doopalliance.com/"
};

new g_iAccount = -1;
new Handle:g_hnCashAdminFlags = INVALID_HANDLE;
new Handle:g_hnCashRound = INVALID_HANDLE;

public OnPluginStart()
{
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

	if (g_iAccount == -1)
	{
		PrintToServer("[DA Cash] - Unable to start, used for Counter Stike Source Only!");
		return;
	}

	LoadTranslations("common.phrases");
	LoadTranslations("sm_cash.phrases");

	CreateConVar("sm_cash_version", PLUGIN_VERSION, "SM Cash Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hnCashRound = CreateConVar("sm_cash_round","","Sets Money Given/Taken at Spawn. <[+/-]amount>");
	g_hnCashAdminFlags = CreateConVar("sm_cash_adminflags", "o", "Admin Flag(s) to allow changing cash. o=CustomFlag_1(default) p=CustomFlag_2 z=root etc.");

	new String:szAdminFlags[37];
	new iFlagBits;

	GetConVarString(g_hnCashAdminFlags, szAdminFlags, sizeof(szAdminFlags));

	// Double Check flag and set to CustomFlag_1 if need be
	if (strlen(szAdminFlags) == 0)
		szAdminFlags[0] = 'o';

	iFlagBits = ReadFlagString(szAdminFlags);

	RegAdminCmd("sm_cash", commandCash, iFlagBits, "sm_cash <name or #userid @all/@t/@ct> <[+/-]amount> - Set target's cash to amount.");
	HookEvent("player_spawn" , eventSpawn);
}

public Action:commandCash(p_iClient, p_iArgs)
{
	if (p_iArgs < 2)
	{
		ReplyToCommand(p_iClient, "[SM] %t", "Usage");
		return Plugin_Handled;	
	}

	new String:szTarget[65];
	new iAmount;
	new cMod = ' ';
	decl String:szAmount[8];

	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, szAmount, sizeof(szAmount));

	if (GetMoneyFromString(szAmount, iAmount, cMod) != 0)
	{
		ReplyToCommand(p_iClient, "[SM] %t", "Invalid Amount2");
		return Plugin_Handled;
	}

	iAmount = StringToInt(szAmount);

	if(iAmount == 0 && szAmount[0] != '0')
	{
		ReplyToCommand(p_iClient, "[SM] %t", "Invalid Amount");
		return Plugin_Handled;
	}


	decl String:szTargetName[MAX_TARGET_LENGTH];
	decl iTargetList[MAXPLAYERS];
	decl iTargetCount;
	decl bool:bML;
	
	if ((iTargetCount = ProcessTargetString(szTarget, p_iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, szTargetName, sizeof(szTargetName), bML)) <= 0)
	{
		ReplyToTargetError(p_iClient, iTargetCount);
		return Plugin_Handled;
	}

	for (new i = 0; i < iTargetCount; i++)
	{
		SetMoney(iTargetList[i], iAmount, cMod);
	}

	if (bML)
		ShowActivity2(p_iClient, "[SM] ", "%t", "Set cash on target", szTargetName);
	else
		ShowActivity2(p_iClient, "[SM] ", "%t", "Set cash on target", "_s", szTargetName);

	return Plugin_Handled;
}

public eventSpawn(Handle:p_hnEvent , const String:p_szName[] , bool:p_bDontBroadcast)
{
	new String:szRound[8];
	new iAmount;
	new cMod = ' ';

	new iClientId = GetEventInt(p_hnEvent,"userid");
	new iClient = GetClientOfUserId(iClientId);

	GetConVarString(g_hnCashRound, szRound, sizeof(szRound));
	GetMoneyFromString(szRound, iAmount, cMod);

	SetMoney(iClient, iAmount, cMod);
}

public GetMoneyFromString(const String:p_szAmount[], & r_iAmount, & r_cModifier)
{
	new cAmtChar = p_szAmount[0];
	new String:szAmount[8] = "";

	if(cAmtChar == '+' || cAmtChar == '-')
	{
		if(strlen(p_szAmount) == 1)
		{
			return 2;
		}

		strcopy(szAmount, sizeof(szAmount), p_szAmount[1]);
	}
	else {
		cAmtChar = ' ';
		strcopy(szAmount, sizeof(szAmount), p_szAmount);
	}

	r_cModifier = cAmtChar;
	r_iAmount = StringToInt(szAmount);
	return 0;
}

public SetMoney(p_iClient, amount, modifier)
{
	if (modifier == '+')
		amount = GetMoney(p_iClient) + amount;

	if (modifier == '-')
		amount = GetMoney(p_iClient) - amount;

	if (amount > 16000)
		amount = 16000;

	if (amount < 0)
		amount = 0;

	if (g_iAccount != -1)
		SetEntData(p_iClient, g_iAccount, amount);
}

public GetMoney(p_iClient)
{
	if (g_iAccount != -1)
		return GetEntData(p_iClient, g_iAccount);

	return 0;
}
