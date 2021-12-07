#include <sourcemod>
#include <sdktools>
#include <regex>

new Handle:g_CEnabled = INVALID_HANDLE;
new Handle:g_NEnabled = INVALID_HANDLE;
new Handle:g_WhiteList = INVALID_HANDLE;
new Handle:g_Flags = INVALID_HANDLE;
new Handle:g_Msg = INVALID_HANDLE;

new Handle:g_IpRegex = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Remove Ads",
	author = "Zephyrus",
	description = "Removes ads from chat and player names.",
	version = "1.3",
	url = ""
};

public OnPluginStart()
{
	g_CEnabled = CreateConVar("sm_ads_chat", "1");
	g_NEnabled = CreateConVar("sm_ads_names", "1");
	g_WhiteList = CreateConVar("sm_ads_whitelist", "");
	g_Flags = CreateConVar("sm_ads_immunity", "b");
	g_Msg = CreateConVar("sm_ads_chat_censoredmsg", "");

	RegServerCmd("say", Command_Say);
	RegServerCmd("sm_say", Command_Say);
	RegServerCmd("ma_say", Command_Say);
	
	AddCommandListener(Command_CSay, "say");
	AddCommandListener(Command_CSay, "say_team");
	
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	
	g_IpRegex = CompileRegex("((?:[0-9]+){1,3}.(?:[0-9]+){1,3}.(?:[0-9]+){1,3}.(?:[0-9]+){1,3}(?::[0-9]+|)|(?:[a-z.-]+):(?:[0-9]+))");
}

public OnClientPutInServer(client)
{
	if(!GetConVarBool(g_NEnabled))
		return;

	new String:name[64];
	GetClientName(client, name, sizeof(name));
	NameChange(client, name);
}

public NameChange(client, String:name[])
{
	if(!IsValidEdict(client))
		return;
	if(!IsClientInGame(client))
		return;
	
	if(MatchRegex(g_IpRegex, name) > 0)
	{
		new String:newname[64];
		strcopy(newname, sizeof(newname), name);
		new String:ip[25];
		GetRegexSubString(g_IpRegex, 0, ip, sizeof(ip));
		ReplaceString(newname, sizeof(newname), ip, "");
		SetClientInfo(client, "name", newname);
		SetEntPropString(client, Prop_Data, "m_szNetname", newname);
	}
}

public OnClientSettingsChanged(client)
{
	if(!GetConVarBool(g_NEnabled))
		return;
		
	if(IsClientImmune(client))
		return;
		
	new String:name[64];
	GetClientName(client, name, sizeof(name));
		
	if(MatchIp(name))
	{
		NameChange(client, name);
	}
}

public Action:Command_Say(args)
{
	if(!GetConVarBool(g_CEnabled))
		return Plugin_Continue;

	new String:buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	
	if(MatchIp(buffer))
	{
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Command_CSay(client, String:command[], args)
{
	if(!GetConVarBool(g_CEnabled))
		return Plugin_Continue;
	
	if(client == 0)
		return Plugin_Stop;
	
	if(IsClientImmune(client))
		return Plugin_Continue;

	new String:buffer[256];
	GetCmdArgString(buffer, sizeof(buffer));
	
	if(MatchIp(buffer))
	{
		new String:censoredmsg[256];
		GetConVarString(g_Msg, censoredmsg, sizeof(censoredmsg));
		if(strcmp(censoredmsg, "")!=0)
		{
			new String:ip[25];
			GetRegexSubString(g_IpRegex, 0, ip, sizeof(ip));
			ReplaceString(command, 256, ip, censoredmsg);
			return Plugin_Changed;
		}
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_NEnabled))
		return Plugin_Continue;

	new String:sName[64];
	GetEventString(event, "name", sName, 64);
	if(MatchIp(sName))
	{
		new String:ip[25];
		GetRegexSubString(g_IpRegex, 0, ip, sizeof(ip));
		ReplaceString(sName, 64, ip, "");
		SetEventString(event, "name", sName);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public bool:MatchIp(String:text[])
{
	if(MatchRegex(g_IpRegex, text) > 0)
	{
		new String:ip[25];
		GetRegexSubString(g_IpRegex, 0, ip, sizeof(ip));
	
		new String:whitelist[4096];
		GetConVarString(g_WhiteList, whitelist, sizeof(whitelist));
		
		if(StrContains(whitelist, ip) != -1)
		{
			return false;
		}
		
		return true;
	}
	return false;
}

public bool:IsClientImmune(client)
{
	if(client == 0 || client > MaxClients+1)
		return false;

	new String:flags[45];
	GetConVarString(g_Flags, flags, sizeof(flags));

	if(GetUserFlagBits(client) & ReadFlagString(flags))
	{
		return true;
	}
	
	return false;
}
