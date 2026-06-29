#include <sourcemod>
#include <money>

new money[MAXPLAYERS]

new String:path[64]

new Handle:g_cvHSBonus
new Handle:g_cvMoney
new Handle:g_cvSuicide

public Plugin myinfo =
{
	name = "Money System",
	author = "Vaggelis",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_money", CmdMoney)
	RegAdminCmd("sm_setmoney", CmdSetMoney, ADMFLAG_ROOT, "sm_setmoney <name> <amount>")
	
	HookEvent("player_death",  EventPlayer_Death)
	
	g_cvHSBonus = CreateConVar("money_hs_bonus", "20", "How much extra money with a headshot kill", _, true, 0.0)
	g_cvMoney = CreateConVar("money_kill", "100", "How much money for killing 1 player", _, true, 0.0)
	g_cvSuicide = CreateConVar("money_lose_suicide", "50", "How much money lose on suicide", _, true, 0.0)
	
	BuildPath(Path_SM, path, 64, "data/money.txt")
	
	LoadTranslations("common.phrases.txt")
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SetMoney", Native_SetMoney)
	CreateNative("GetMoney", Native_GetMoney)

	RegPluginLibrary("money")
	return APLRes_Success
}

public Native_SetMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new amount = GetNativeCell(2)
	
	money[client] = amount
}

public Native_GetMoney(Handle:plugin, numParams)
{
	new client = GetNativeCell(1)
	new amount = money[client]
	
	return amount
}

public Action:CmdMoney(client, args)
{
	PrintToChat(client, "You have: %d", GetMoney(client))
	return Plugin_Handled
}

public Action:CmdSetMoney(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmoney <name> <amount>")
		return Plugin_Handled
	}
	
	new String:arg1[32]
	GetCmdArg(1, arg1, sizeof(arg1))
	
	new target = FindTarget(client, arg1)
	
	if(target == -1)
	{
		return Plugin_Handled
	}
	
	new String:arg2[32]
	GetCmdArg(2, arg2, sizeof(arg2))
	new amount = StringToInt(arg2)
	
	SetMoney(target, amount)
	return Plugin_Handled
}

public Action:EventPlayer_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new bool:headshot = GetEventBool(event, "headshot")
	
	if(attacker == victim)
	{
		SetMoney(victim, GetMoney(victim) - GetConVarInt(g_cvSuicide))
		return Plugin_Handled
	}
	
	if(headshot)
	{
		SetMoney(attacker, GetMoney(attacker) + GetConVarInt(g_cvHSBonus))
	}
	
	SetMoney(attacker, GetMoney(attacker) + GetConVarInt(g_cvMoney))
	return Plugin_Handled
}

public LoadMoney(client)
{
	new Handle:kv
	
	kv = CreateKeyValues("Money")
	
	FileToKeyValues(kv, path)
	
	new String:SteamID[35]
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID))
	
	if(KvJumpToKey(kv, SteamID))
	{
		new temp = KvGetNum(kv, "Current Money")
		SetMoney(client, temp)
		
		KvRewind(kv)
	}
	
	CloseHandle(kv)
}

public SaveMoney(client)
{
	new Handle:kv
	
	kv = CreateKeyValues("Money")
	
	FileToKeyValues(kv, path)
	
	new String:SteamID[35]
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID))
	
	KvJumpToKey(kv, SteamID, true)
	KvSetNum(kv, "Current Money", GetMoney(client))
	KvRewind(kv)
	
	KeyValuesToFile(kv, path)
	
	CloseHandle(kv)
}

public OnClientAuthorized(client, const String:auth[])
{
	LoadMoney(client)
}

public OnClientDisconnect(client)
{
	SaveMoney(client)
}