#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "[ActivisionGame] Advanced Server Security",
	description = "Block users who hacking the server",
	author = "[A]gha [A]rshia",
	version = "2.1",
	url = "ActivisionGame.ir"
};

new Handle:tv_name;
new String:tvName[100];

public OnPluginStart()
{
	AddCommandListener(CheckCMDString, "sm_cvar");
	AddCommandListener(CheckCMDString, "sm_rcon");
	tv_name = FindConVar("tv_name");
}

public OnConfigsExecuted()
{
	GetConVarString(tv_name, tvName, 100);
}

public OnClientDisconnect(client)
{
	decl String:cName[64];
	GetClientName(client, cName, 64);
	if (StrEqual(cName, tvName, true))
	{
		ServerCommand("sm_msay [Warning] SourceTv Disconnected !");
		PrintHintTextToAll("[Warning] SourceTv Disconnected !");
		PrintCenterTextAll("[Warning] SourceTv Disconnected !");
		PrintToChatAll("[Warning] SourceTv Disconnected !");
	}
}

public Action:CheckCMDString(client, String:command[], argc)
{
	decl String:sCMD[1024];
	GetCmdArgString(sCMD, 1024);
	if (StrContains(sCMD, "hostname", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to change server hostname using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to change server hostname using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "gamedesc_override", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to change server gamedesc using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to change server gamedesc using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "tv_", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to use command (tv_) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to use command (tv_) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "quit", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to restart server (quit) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to restart server (quit) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "quti", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to restart server (quti) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to restart server (quti) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "restart", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to restart server (restart) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to restart server (restart) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "_restart", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to restart server (_restart) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to restart server (_restart) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "exit", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to restart server (exit) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to restart server (exit) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "sm plugins unload", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to use command (sm plugins unload) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to use command (sm plugins unload) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "bot_Prefix", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to use command (bot_Prefix) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to use command (bot_Prefix) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "sm_botnames_prefix", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to use command (sm_botnames_prefix) using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to use command (sm_botnames_prefix) using sm_cvar", client, clientIP);
		}
		ServerCommand("sm_banip %s 0 @ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	if (StrContains(sCMD, "rcon_password", false) != -1)
	{
		new String:clientIP[32];
		GetClientIP(client, clientIP, 32, true);
		decl String:clientName[256];
		GetClientName(client, clientName, 255);
		decl String:file[256];
		BuildPath(Path_SM, file, 256, "logs/ACT_SERVERSECURITY.log");
		GetCmdArg(0, sCMD, 1024);
		if (StrEqual(sCMD, "sm_rcon", false))
		{
			LogToFile(file, "%L [%s] tried to access rcon_password using sm_rcon", client, clientIP);
		}
		else
		{
			LogToFile(file, "%L [%s] tried to access rcon_password using sm_cvar", client, clientIP);
		}
		PrintToConsole(client, "[ACT-ServerSecurity] Your IP [%s] Saved and Logged.", clientIP);
		PrintToChatAll("\x04[ACT-ServerSecurity] \x01Player \x03%s \x01Was Banned From The Server! (\x03Reason : Server Hacking Command\x01)", clientName);
		PrintToConsole(client, "@ActivisionGame_co ServerSecurity : You Were Banned From The Server For Hacking Command!", client);
		return Plugin_Stop ;
	}
	return Plugin_Continue;
}

public OnPluginEnd()
{
	new String:sBuffer[256];
	GetPluginFilename(GetMyHandle(), sBuffer, 256);
	sBuffer[strlen(sBuffer) + -4] = 0;
	InsertServerCommand("sm plugins load %s", sBuffer);
}

