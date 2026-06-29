#include <sourcemod>
#include <clientprefs>

new Handle:LogChat;
new Handle:g_hCookieTag;

public Plugin:myinfo =
{
	name = "Custom Admin Prefixes",
	author = "Marcus",
	description = "A plugin that addes special prefixes to your name if you are admin.",
	version = "1.0.8",
	url = "http://snbx.info"
};
enum AdminLevel{
	AL_None=0,
	AL_Root,
	AL_LeadAdmin,
	AL_Admin
}; 
public OnPluginStart()
{
	RegAdminCmd("sm_admintag", Command_ATag, ADMFLAG_GENERIC);
	AddCommandListener(HookPlayerChat, "say");
	
	LogChat = CreateConVar("sm_log_chat", "1", "Enables or disables chat logging for admins with a prefix", FCVAR_NOTIFY);
	g_hCookieTag = RegClientCookie("prefix_toggle", "Toggles the chat prefix on or off.", CookieAccess_Public);
}
public Action:Command_ATag(client, args)
{
	decl String:TagToggle[8];
	GetClientCookie(client, g_hCookieTag, TagToggle, sizeof(TagToggle));
	if (StringToInt(TagToggle) != 1)
	{
		SetClientCookie(client, g_hCookieTag, "1");
		ReplyToCommand(client, "\x04[Notice]\x01 You have enabled your admin tag.");
	} else
	{
		SetClientCookie(client, g_hCookieTag, "0");
		ReplyToCommand(client, "\x04[Notice]\x01 You have disabled your admin tag.");
	}
	return Plugin_Handled;
}
public AdminLevel:GetAdmin(client)
{
	if(IsValidClient(client))
	{
		if(!GetUserFlagBits(client))
			return AL_None;
		else if(GetUserFlagBits(client)&ADMFLAG_ROOT > 0)
			return AL_Root;
		else if(GetUserFlagBits(client)&ADMFLAG_RCON > 0)
			return AL_LeadAdmin;
		else if(GetUserFlagBits(client)&ADMFLAG_GENERIC > 0)
			return AL_Admin;
		else
			return AL_None;
	}
	return AL_None;
}
stock bool:IsValidClient( client ) 
{
    if((1<=client<= MaxClients ) && IsClientInGame(client)) 
        return true; 
     
    return false; 
}
public Action:HookPlayerChat(client, const String:command[], args)
{
	new bool:TagEnabled = false;
	decl String:szText[256], String:TagToggle[8], String:szAuthId[32];
	szText[0] = '\0';
	GetCmdArg(1, szText, sizeof(szText));
	GetClientCookie(client, g_hCookieTag, TagToggle, sizeof(TagToggle));
	GetClientAuthString(client, szAuthId, sizeof(szAuthId));
	if (!StrEqual(TagToggle, ""))
	{
		if (StringToInt(TagToggle) == 1)
		TagEnabled = true;
	} else if (client != 0 && TagEnabled)
	{
		if (szText[0] != '/' && szText[0] != '!')
		{
			if (GetAdmin(client) == AL_Root)
			{
				PrintToChatAll2("\x07DC6900[Owner]\x01 %N: \x070069DC%s\x01",client, szText);
				PrintToServer("[Owner] %N: %s",client, szText);
			}
			if (GetAdmin(client) == AL_LeadAdmin)
			{
				PrintToChatAll2("\x07DC6900[Lead Admin]\x01 %N: \x070069DC%s\x01",client, szText);
				PrintToServer("[Lead Admin] %N: %s",client, szText);
			}
			if (GetAdmin(client) == AL_Admin)
			{
				PrintToChatAll2("\x07DC6900[Admin]\x01 %N: \x070069DC%s\x01",client, szText);
				PrintToServer("[Admin] %N: %s",client, szText);
			}
			if (GetConVarBool(LogChat)) 
			{
				LogCustom("%N: %s", client, szText);
			}
		}
	} else if (!IsPlayerAlive(client) && !TagEnabled)
	{
		PrintToChatAll2("\x05*DEAD*\x01 %N: %s", client, szText);
		PrintToServer("*DEAD* %N: %s",client, szText);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
LogCustom(const String:format[], any:...)
{
	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	new Handle:file;
	decl String:FileName[256], String:sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/chat_prefix_logs.txt");
	file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y %H:%M:%S");
	WriteFileLine(file, "%s  %s", sTime, buffer);
	FlushFile(file);
	CloseHandle(file);
}
public PrintToChat2(client, const String:format[], any:...)
{
	decl String:buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	new Handle:bf = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}
public PrintToChatAll2(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	new Handle:bf = StartMessageAll("SayText2", USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	BfWriteByte(bf, -1);
	BfWriteByte(bf, true);
	BfWriteString(bf, buffer);
	EndMessage();
}