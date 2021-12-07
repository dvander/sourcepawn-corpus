#include <sourcemod>

new g_iMaxBanTime[6] = {-1,...};

public Plugin:myinfo = 
{
	name = "Ban Time Limit",
	author = "Peace-Maker",
	description = "Limits admins to only ban for x minutes",
	version = "1.0",
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	RegAdminCmd("sm_reloadbanlimit", Cmd_ReloadBanLimit, ADMFLAG_CONFIG, "Reloads the ban time limit config file.");
	ParseBanLimitConfig();
	AddCommandListener(Cmd_Ban, "sm_ban");
}

public OnMapStart()
{
	ParseBanLimitConfig();
}

public Action:Cmd_ReloadBanLimit(client, args)
{
	ParseBanLimitConfig();
	ReplyToCommand(client, "Ban Time Limit: Config reloaded.");
	return Plugin_Handled;
}

public Action:Cmd_Ban(client, const String:command[], argc)
{
	if(argc < 2 || !client)
		return Plugin_Continue;
	
	decl String:sTime[16];
	GetCmdArg(2, sTime, sizeof(sTime));
	new iLimit = -1;
	if(!IsAllowedToBanThatLong(client, StringToInt(sTime), iLimit))
	{
		ReplyToCommand(client, "Ban Time Limit: You're limited to %d minute bans.", iLimit);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source)
{
	new iLimit = -1;
	if(0 < source && source <= MaxClients && IsClientInGame(source) && !IsAllowedToBanThatLong(source, time, iLimit))
	{
		PrintToChat(source, "Ban Time Limit: You're limited to %d minute bans. Your ban has been shortened.", iLimit);
		// reban with shorter time.
		BanClient(client, iLimit, flags, reason, kick_message, command, source);
		// Block this too long ban. Player will still be kicked.
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

bool:IsAllowedToBanThatLong(client, time, &iLimit)
{
	iLimit = -1;
	new iFlagBits = GetUserFlagBits(client);
	
	// Don't check root admins.
	if((iFlagBits & ADMFLAG_ROOT) > 0)
		return true;
	
	// Get the limit of the banning admin
	for(new i=0;i<6;i++)
	{
		if((iFlagBits & (ADMFLAG_CUSTOM1<<i)) > 0 && iLimit < g_iMaxBanTime[i])
			iLimit = g_iMaxBanTime[i];
	}
	
	// Admin isn't allowed to ban for that long.
	if(iLimit >= 0 && (time > iLimit || time == 0))
	{
		return false;
	}
	return true;
}

ParseBanLimitConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/bantimelimit.cfg");
	if(!FileExists(sPath))
	{
		SetFailState("Can't find config file in %s", sPath);
		return;
	}
	
	new Handle:hKV = CreateKeyValues("bantimelimit");
	FileToKeyValues(hKV, sPath);
	
	if(!KvGotoFirstSubKey(hKV))
		return;
	
	g_iMaxBanTime[0] = KvGetNum(hKV, "custom1", -1);
	g_iMaxBanTime[1] = KvGetNum(hKV, "custom2", -1);
	g_iMaxBanTime[2] = KvGetNum(hKV, "custom3", -1);
	g_iMaxBanTime[3] = KvGetNum(hKV, "custom4", -1);
	g_iMaxBanTime[4] = KvGetNum(hKV, "custom5", -1);
	g_iMaxBanTime[5] = KvGetNum(hKV, "custom6", -1);
	
	CloseHandle(hKV);
}