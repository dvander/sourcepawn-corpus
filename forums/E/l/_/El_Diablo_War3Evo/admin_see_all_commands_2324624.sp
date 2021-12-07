// admin_see_all_commands.sp

#define PLUGIN_VERSION "1.1"

#include <sourcemod>

#define LoopAuthorizedPlayers(%1) for(new %1=1;%1<=MaxClients;++%1)\
								if(IsClientConnected(%1) && IsClientAuthorized(%1))
#define LoopMaxClients(%1) for(new %1=1;%1<=MaxClients;++%1)

public Plugin:myinfo =
{
	name = "[ANY] Admin See WHO Typed All Commands",
	author = "El Diablo",
	description = "Lets an admin see all typed commands used.",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.info"
};

#define LogStackCommandBuffer 100

new String:sLogStack[LogStackCommandBuffer][192];
new iLogStack=0;

new Handle:g_hSeeAdminCommands;
new Handle:g_hSeeRegCommands;
new Handle:g_hSeePrintCommands;
new Handle:g_hHideFlagCommands;
new Handle:g_hHideAllAdminCommands;
new Handle:g_hShowIP;
new Handle:g_hSeeDebug;
new Handle:g_hSeeUnicodeFiltering;
new Handle:g_hSeeAllCommandsLog;
new Handle:g_hSeeAllCommandsLogSay;


new HideADMINFLAGS=ADMFLAG_ROOT;
new HideAllADMINFLAGS=ADMFLAG_ROOT;

new bool:AdminCanSeeCommands[MAXPLAYERS + 1] = {false, ...};

new bool:g_bSeePrintCommands=true;

new bool:g_bShowIP=false;

new bool:g_bSeeDebug=false;

new bool:g_bSeeUnicodeFiltering=false;

new bool:g_bSeeAllCommandsLog=false;

new bool:g_bSeeAllCommandsLogSay=false;

// commands to ignore
stock const String:IgnoreCommands[][] = {
	//"+",
	//"-",
	"hlx",
	"tp",
	"fp",
	"voicemenu"
};

stock bool:HasIgnoreCommands(const String:CheckCommand[64])
{
	for(new i = 0; i < sizeof(IgnoreCommands); i++)
	{
		if(StrContains(CheckCommand,IgnoreCommands[i])==0)
		{
			return true;
		}
	}
	return false;
}

stock SeeAllCommandsDebug(const String:logMsg[],any:...)
{
	new String:myFormattedString[4096];
	VFormat(myFormattedString, sizeof(myFormattedString), logMsg, 2 );
	PrintToServer("%s",myFormattedString);

	decl String:date[32];
	FormatTime(date, sizeof(date), "%m_%d_%y");

	new String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "logs/SeeAllCommandsDebug_%s.log",date);

	LogToFileEx(path, "%s",myFormattedString);
}

stock LogStackBuffer(const String:logMsg[],any:...)
{
	new String:myFormattedString[4096];
	VFormat(myFormattedString, sizeof(myFormattedString), logMsg, 2 );
	PrintToServer("%s",myFormattedString);

	decl String:date[32];
	FormatTime(date, sizeof(date), "%m_%d_%y");

	new String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "logs/LogStackBuffer_%s.log",date);

	LogToFileEx(path, "%s",myFormattedString);
}

stock LogSeeAllCommandsBuffer(const String:logMsg[],any:...)
{
	new String:myFormattedString[4096];
	VFormat(myFormattedString, sizeof(myFormattedString), logMsg, 2 );
	PrintToServer("%s",myFormattedString);

	decl String:date[32];
	FormatTime(date, sizeof(date), "%m_%d_%y");

	new String:path[1024];
	BuildPath(Path_SM, path, sizeof(path), "logs/LogSeeAllCommands_%s.log",date);

	LogToFileEx(path, "%s",myFormattedString);
}
/*
stock LogSeeAllSayCommandsBuffer(const String:logMsg[],any:...)
{
	new String:myFormattedString[4096];
	VFormat(myFormattedString, sizeof(myFormattedString), logMsg, 2 );
	PrintToServer("%s",myFormattedString);

	decl String:date[32];
	FormatTime(date, sizeof(date), "%m_%d_%y");

	new String:path[1024];
	BuildPath(Path_SM, path, sizeof(path), "logs/LogSeeAllSayCommands_%s.log",date);

	LogToFileEx(path, "%s",myFormattedString);
}*/

/**
 * Prints Message to server and all chat
 * For debugging prints
 */
stock DDebugPrint(const String:szMessage[], any:...)
{
	decl String:szBuffer[1000];

	VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);
	PrintToServer("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);
	PrintToChatAll("[DebugP %d] %s",RoundFloat(GetGameTime())%100, szBuffer);

}

public ConVarChanged_ConVars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar      == g_hHideFlagCommands)
	{
		HideADMINFLAGS = ReadFlagString(newValue);
	}
	else if (convar == g_hHideAllAdminCommands)
	{
		HideAllADMINFLAGS = ReadFlagString(newValue);
	}
	else if (convar == g_hSeePrintCommands)
		g_bSeePrintCommands = bool:StringToInt(newValue);
	else if (convar == g_hShowIP)
		g_bShowIP = bool:StringToInt(newValue);
	else if (convar == g_hSeeDebug)
		g_bSeeDebug = bool:StringToInt(newValue);
	else if (convar == g_hSeeUnicodeFiltering)
		g_bSeeUnicodeFiltering = bool:StringToInt(newValue);
	else if (convar == g_hSeeAllCommandsLog)
		g_bSeeAllCommandsLog = bool:StringToInt(newValue);
	else if (convar == g_hSeeAllCommandsLogSay)
		g_bSeeAllCommandsLogSay = bool:StringToInt(newValue);
}

public OnPluginStart()
{
	CreateConVar("sm_admin_see_all_commands", PLUGIN_VERSION, "Admin See All Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hHideFlagCommands=CreateConVar("sm_hide_flag_commands","z","these flags are checked against the command's default flag");
	g_hHideAllAdminCommands=CreateConVar("sm_hide_all_admin_commands","z","these flags are checked against the user's flags");

	g_hSeeUnicodeFiltering=CreateConVar("sm_see_unicode_filtering","0","1 - enable 0 - disable\nIf enabled, Filters unicode from command buffer and client name.");

	g_hSeeDebug=CreateConVar("sm_see_debug_messages","0","if you want a log of all commands while this plugin is starting,\nmust be set in server.cfg before server starts with plugin.\nalso enables other debug messages.");

	g_hShowIP=CreateConVar("sm_see_show_ip","0","allows admins whom can use sm_seecommands to be able to see players ip addresses too.");

	g_hSeeAdminCommands=CreateConVar("sm_see_admin_commands","1","must be set in server.cfg before the server starts.");
	g_hSeeRegCommands=CreateConVar("sm_see_reg_commands","1","must be set in server.cfg before the server starts.");

	g_hSeePrintCommands=CreateConVar("sm_see_print_commands","1", "0 - print to console\n1 - print to chat");

	g_hSeeAllCommandsLog=CreateConVar("sm_see_log_commands_to_file","0", "0 - disabled\n1 - enabled");

	g_hSeeAllCommandsLogSay=CreateConVar("sm_see_log_say_to_file","0", "0 - disabled\n1 - enabled");

	RegAdminCmd("sm_logit", Command_logit, ADMFLAG_BAN, "sm_logit logs all commands in log stack buffer to a log file.");

	RegAdminCmd("sm_seecommands", Command_seecommands, ADMFLAG_BAN, "sm_seecommands\nAllows an admin to see who typed all commands.");

	// Hook convar changes
	HookConVarChange(g_hSeeUnicodeFiltering,         ConVarChanged_ConVars);
	HookConVarChange(g_hHideFlagCommands,         ConVarChanged_ConVars);
	HookConVarChange(g_hHideAllAdminCommands,         ConVarChanged_ConVars);
	HookConVarChange(g_hSeePrintCommands,         ConVarChanged_ConVars);
	HookConVarChange(g_hShowIP,         ConVarChanged_ConVars);
	HookConVarChange(g_hSeeDebug,         ConVarChanged_ConVars);

	AddCommandListener(See_Say_Commands, "say");
	AddCommandListener(See_Say_Commands, "say_team");
}

public OnMapStart()
{
	LoopMaxClients(i)
	{
		AdminCanSeeCommands[i]=false;
	}
	g_bSeeAllCommandsLog = GetConVarBool(g_hSeeAllCommandsLog);

	g_bSeeAllCommandsLogSay = GetConVarBool(g_hSeeAllCommandsLogSay);
}

public OnConfigsExecuted()
{
	g_bSeeAllCommandsLog = GetConVarBool(g_hSeeAllCommandsLog);

	g_bSeeAllCommandsLogSay = GetConVarBool(g_hSeeAllCommandsLogSay);
}

public OnClientDisconnect(client)
{
	AdminCanSeeCommands[client]=false;
}

public Action:Command_seecommands(client, args)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		AdminCanSeeCommands[client]=AdminCanSeeCommands[client]?false:true;
		PrintToChat(client,"%s",AdminCanSeeCommands[client]?"You can now see all commands.":"Seeing all commands turned off.");
	}
	return Plugin_Handled;
}

public Action:Command_logit(client, args)
{
	LogStackBuffer("-----------------------------------------------------------------------------");
	decl String:steamid[32];
	GetClientAuthId(client,AuthId_Steam2,steamid,sizeof(steamid),true);
	decl String:sClientName[32];
	GetClientName(client,sClientName,sizeof(sClientName));
	LogStackBuffer("Client whom logged it: %s %s",sClientName,steamid);
	LogStackBuffer("-----------------------------------------------------------------------------");
	for(new i=0;i<=LogStackCommandBuffer-1;++i)
	{
		if(StrEqual(sLogStack[i],"")) continue;
		LogStackBuffer(sLogStack[i]);
	}
	PrintToChat(client,"You logged command stack to log file.");
	return Plugin_Handled;
}

public OnAllPluginsLoaded()
{
	decl String:Name[64];
	decl String:Desc[255];
	new Flags;
	new Handle:CmdIter = GetCommandIterator();

	new AdminCmdCount;
	new RegCmdCount;
	while(ReadCommandIterator(CmdIter, Name, sizeof(Name), Flags, Desc, sizeof(Desc)))
	{
		if ( (Flags & ADMFLAG_RESERVATION)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_RESERVATION, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_RESERVATION %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_GENERIC)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_GENERIC, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_GENERIC %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_KICK)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_KICK, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_KICK %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_BAN)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_BAN, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_BAN %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_UNBAN)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_UNBAN, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_UNBAN %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_SLAY)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_SLAY, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_SLAY %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CHANGEMAP)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CHANGEMAP, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CHANGEMAP %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CONVARS)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CONVARS, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CONVARS %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CONFIG)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CONFIG, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CONFIG %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CHAT)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CHAT, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CHAT %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_VOTE)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_VOTE, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_VOTE %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_PASSWORD)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_PASSWORD, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_PASSWORD %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_RCON)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_RCON, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_RCON %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CHEATS)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CHEATS, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CHEATS %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM1)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM1, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM1 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM2)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM2, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM2 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM3)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM3, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM3 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM4)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM4, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM4 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM5)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM5, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM5 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_CUSTOM6)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_CUSTOM6, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_CUSTOM6 %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if ( (Flags & ADMFLAG_ROOT)
			&& GetConVarBool(g_hSeeAdminCommands))
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_ADMFLAG_ROOT, Name))
				{
					AdminCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked ADMFLAG_ROOT %s Flags %d",Name,Flags);
					}
				}
			}
		}
		else if (
			(Flags == 0)
			&& GetConVarBool(g_hSeeRegCommands)
		)
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(See_Reg_Command, Name))
				{
					RegCmdCount++;
					if(g_bSeeDebug)
					{
						SeeAllCommandsDebug("Hooked RegCommands %s Flags %d",Name,Flags);
					}
				}
			}
		}
	}
	CloseHandle(CmdIter);
	new iTotal = RegCmdCount + AdminCmdCount;
	SeeAllCommandsDebug("Hooked [%d Admin] [%d Reg commands] [%d Total]",AdminCmdCount,RegCmdCount,iTotal);
}

public Action:See_ADMFLAG_RESERVATION(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_RESERVATION )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_RESERVATION: sm_hide_flag_commands a",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_RESERVATION: sm_hide_flag_commands a",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_GENERIC(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_GENERIC )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_GENERIC: sm_hide_flag_commands b",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_GENERIC: sm_hide_flag_commands b",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_KICK(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_KICK )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_KICK: sm_hide_flag_commands c",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_KICK: sm_hide_flag_commands c",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_BAN(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_BAN )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_BAN: sm_hide_flag_commands d",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_BAN: sm_hide_flag_commands d",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_UNBAN(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_UNBAN )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_UNBAN: sm_hide_flag_commands e",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_UNBAN: sm_hide_flag_commands e",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_SLAY(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_SLAY )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_SLAY: sm_hide_flag_commands f",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_SLAY: sm_hide_flag_commands f",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CHANGEMAP(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CHANGEMAP )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CHANGEMAP: sm_hide_flag_commands g",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CHANGEMAP: sm_hide_flag_commands g",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CONVARS(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CONVARS )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CONVARS: sm_hide_flag_commands h",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CONVARS: sm_hide_flag_commands h",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CONFIG(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CONFIG )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CONFIG: sm_hide_flag_commands i",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CONFIG: sm_hide_flag_commands i",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CHAT(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CHAT )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CHAT: sm_hide_flag_commands j",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CHAT: sm_hide_flag_commands j",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_VOTE(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_VOTE )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_VOTE: sm_hide_flag_commands k",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_VOTE: sm_hide_flag_commands k",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_PASSWORD(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_PASSWORD )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_PASSWORD: sm_hide_flag_commands l",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_PASSWORD: sm_hide_flag_commands l",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_RCON(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_RCON )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_RCON: sm_hide_flag_commands m",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_RCON: sm_hide_flag_commands m",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CHEATS(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CHEATS )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CHEATS: sm_hide_flag_commands n",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CHEATS: sm_hide_flag_commands n",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM1(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM1 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM1: sm_hide_flag_commands o",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM1: sm_hide_flag_commands o",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM2(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM2 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM2: sm_hide_flag_commands p",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM2: sm_hide_flag_commands p",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM3(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM3 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM3: sm_hide_flag_commands q",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM3: sm_hide_flag_commands q",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM4(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM4 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM4: sm_hide_flag_commands r",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM4: sm_hide_flag_commands r",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM5(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM5 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM5: sm_hide_flag_commands s",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM5: sm_hide_flag_commands s",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_CUSTOM6(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_CUSTOM6 )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_CUSTOM6: sm_hide_flag_commands t",command);
		}
		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_CUSTOM6: sm_hide_flag_commands t",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}
public Action:See_ADMFLAG_ROOT(client, const String:command[], args)
{
	if ( HideADMINFLAGS & ADMFLAG_ROOT )
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("[HIDDEN] [%s] ADMFLAG_ROOT: sm_hide_flag_commands z",command);
		}

		return Plugin_Continue;
	}
	if(g_bSeeDebug)
	{
		DDebugPrint("[SHOW] [%s] ADMFLAG_ROOT: sm_hide_flag_commands z",command);
	}

	CheckCommands(client,command);

	return Plugin_Continue;
}


public Action:See_Reg_Command(client, const String:command[], args)
{
	CheckCommands(client,command);

	return Plugin_Continue;
}

public Action:See_Say_Commands(client, const String:command[], args)
{
	if(!g_bSeeAllCommandsLogSay) return Plugin_Continue;

	CheckCommands(client,command,true);

	return Plugin_Continue;
}

stock CheckCommands(client, const String:command[], bool:IsSayCommand=false)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		// whole command string
		decl String:CmdBuffer[255];
		GetCmdArgString(CmdBuffer, sizeof(CmdBuffer));

		if(g_bSeeUnicodeFiltering)
		{
			// filter out any unicode
			FilterSentence(CmdBuffer,false,false);
		}

		decl String:steamid[32];
		GetClientAuthId(client,AuthId_Steam2,steamid,sizeof(steamid),true);

		decl String:sFornatToChat[192], String:sClientName[MAX_NAME_LENGTH];

		GetClientName(client, sClientName, sizeof(sClientName));
		if(g_bSeeUnicodeFiltering)
		{
			FilterSentence(sClientName,true,true);
		}

		decl String:sIP[17];
		GetClientIP(client, sIP, sizeof(sIP));

		// Was thinking of recording account id too, but not sure yet.
		//new accountid = GetSteamAccountID(client);

		Format(sFornatToChat,sizeof(sFornatToChat), "[%s] #%d %s %s %s %s", command, GetClientUserId(client), sClientName, steamid, sIP, CmdBuffer);

		strcopy(sLogStack[iLogStack],191,sFornatToChat);
		iLogStack++;
		if(iLogStack>=LogStackCommandBuffer) iLogStack=0;

		if(g_bSeeAllCommandsLog)
		{
			LogSeeAllCommandsBuffer(sFornatToChat);
		}

		if(!IsSayCommand) return;

		if(GetAdminFlags(GetUserAdmin(client), Access_Effective) & HideAllADMINFLAGS)
		{
			if(g_bSeeDebug)
			{
				DDebugPrint("See_Reg_Command GetUserAdmin HideAllADMINFLAGS");
			}
			return;
		}

		if(!g_bShowIP)
		{
			Format(sFornatToChat,sizeof(sFornatToChat), "[%s] #%d %s %s %s", command, GetClientUserId(client), sClientName, steamid, CmdBuffer);
		}

		LoopAuthorizedPlayers(AuthUser)
		{
			if (AdminCanSeeCommands[AuthUser] && CheckCommandAccess(AuthUser, "sm_seecmds_override", ADMFLAG_BAN))
			{
				if(g_bSeePrintCommands)
				{
					PrintToChat(AuthUser,sFornatToChat);
				}
				else
				{
					PrintToConsole(AuthUser,sFornatToChat);
				}
			}
		}
	}
	else if(client==0)
	{
		if(g_bSeeDebug)
		{
			DDebugPrint("CheckCommand client == SERVER");
		}
	}
}

stock FilterSentence(String:message[],bool:extremefilter=false,bool:RemoveWhiteSpace=false)
{
	new charMax = strlen(message);
	new charIndex;
	new copyPos = 0;

	new String:strippedString[192];

	for (charIndex = 0; charIndex < charMax; charIndex++)
	{
		// Reach end of string. Break.
		if (message[copyPos] == 0) {
			strippedString[copyPos] = 0;
			break;
		}

		if (GetCharBytes(message[charIndex])>1)
		{
			continue;
		}

		if(RemoveWhiteSpace && IsCharSpace(message[charIndex]))
		{
			continue;
		}

		if(extremefilter && IsAlphaNumeric(message[charIndex]))
		{
			strippedString[copyPos] = message[charIndex];
			copyPos++;
			continue;
		}

		// Found a normal character. Copy.
		if (!extremefilter && IsNormalCharacter(message[charIndex])) {
			strippedString[copyPos] = message[charIndex];
			copyPos++;
			continue;
		}
	}

	// Copy back to passing parameter.
	strcopy(message, 192, strippedString);
}

stock bool:IsAlphaNumeric(characterNum) {
	return ((characterNum >= 48 && characterNum <=57)
		||  (characterNum >= 65 && characterNum <=90)
		||  (characterNum >= 97 && characterNum <=122));
}

stock bool:IsNormalCharacter(characterNum) {
	return (characterNum > 31 && characterNum < 127);
}
