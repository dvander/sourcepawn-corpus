#pragma semicolon 1

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define PLUGIN_VERSION "1.0"

new g_PlayerStrikes[MAXPLAYERS+1];
new bool:g_PlayerBanned[MAXPLAYERS+1];

new String:g_LoggingPath[] = "CheatLogs";
new Handle:g_hMaxStrikes = INVALID_HANDLE;
new Handle:g_hLogCommands = INVALID_HANDLE;
new Handle:g_hBannedEntities = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "svcheat",
	author = "Blake",
	description = "",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart() {
	CreateConVar("sv_cheat_logger_version", PLUGIN_VERSION, "Plugin Cheat (FCVAR Commands) Logger current version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hMaxStrikes = CreateConVar("sv_cheat_logger_maxstrikes", "1", "Max strikes until banned", FCVAR_PLUGIN, true, 1.0, false, 0.0);
	
	RegAdminCmd("sm_banentity", Command_EntityBanned, ADMFLAG_CHEATS, "Bans entity from use");
	RegAdminCmd("sm_unbanentity", Command_EntityUnbanned, ADMFLAG_CHEATS, "Unbans entity from use");
	RegAdminCmd("sm_logcommand", Command_LogCommand, ADMFLAG_CHEATS, "Adds command to logging hook");
	RegAdminCmd("sm_unlogcommand", Command_UnlogCommand, ADMFLAG_CHEATS, "Removes command to logging hook");

	AutoExecConfig(true, "cheatmod.settings");
	
	if(!DirExists(g_LoggingPath)) {
		CreateDirectory(g_LoggingPath, 511);
	}
	
	g_hBannedEntities = CreateArray(256,0);
	g_hLogCommands = CreateArray(256,0);
	
}

public Action:Command_LogCommand(client, args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_logcommand <Command>");
		return Plugin_Handled;
	}
	
	new String:arg1[128], index;
	GetCmdArg(1, arg1, sizeof(arg1));
	index = FindStringInArray(g_hLogCommands, arg1);
	if(index == -1)
	{
		PushArrayString(g_hLogCommands, arg1);
		AddCommandListener(OnCheatCommand, arg1);
		ReplyToCommand(client, "[SM] Logging command %s.", arg1);
	}
	else
	if(index != -1)
	{
		ReplyToCommand(client, "[SM] Already logging command %s.", arg1);
	}
	
	return Plugin_Handled;
}

public Action:Command_UnlogCommand(client, args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unlogcommand <Command>");
		return Plugin_Handled;
	}
	
	new String:arg1[128], index;
	GetCmdArg(1, arg1, sizeof(arg1));
	index = FindStringInArray(g_hLogCommands, arg1);
	if(index == -1)
	{
		ReplyToCommand(client, "[SM] Command %s is not being loogged.", arg1);
	}
	else
	if(index != -1)
	{
		RemoveFromArray(g_hLogCommands, index);
		RemoveCommandListener(OnCheatCommand, arg1);
		ReplyToCommand(client, "[SM] Unlogging command %s.", arg1);
	}
	
	return Plugin_Handled;
}

public Action:Command_EntityBanned(client, args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_banentity <Entity>");
		return Plugin_Handled;
	}
	
	new String:arg1[128], index;
	GetCmdArg(1, arg1, sizeof(arg1));
	index = FindStringInArray(g_hBannedEntities, arg1);
	if(index == -1)
	{
		PushArrayString(g_hBannedEntities, arg1);
		ReplyToCommand(client, "[SM] Banned Entity %s.", arg1);
	}
	else
	if(index != -1)
	{
		ReplyToCommand(client, "[SM] Entity %s already banned.", arg1);
	}
	
	return Plugin_Handled;
}

public Action:Command_EntityUnbanned(client, args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unbanentity <Entity>");
		return Plugin_Handled;
	}
	
	new String:arg1[128], index;
	GetCmdArg(1, arg1, sizeof(arg1));
	index = FindStringInArray(g_hBannedEntities, arg1);
	if(index == -1)
	{
		ReplyToCommand(client, "[SM] Entity %s is not banned.", arg1);
	}
	else
	if(index != -1)
	{
		RemoveFromArray(g_hBannedEntities, index);
		ReplyToCommand(client, "[SM] Unbanned Entity %s.", arg1);
	}
	
	return Plugin_Handled;
}

stock LogToCustomFile(const String:FileName[], const String:format[]) {
	new Handle:MyFile = OpenFile(FileName, "a");
	if(MyFile == INVALID_HANDLE) return;
	WriteFileLine(MyFile, "%s", format);
	FlushFile(MyFile);
	CloseHandle(MyFile);
}

public OnClientPostAdminCheck(client) {
	g_PlayerStrikes[client] = 0;
	g_PlayerBanned[client] = false;
	ServerCommand("mp_disable_autokick %d", GetClientUserId(client));
	decl String:steamid[32], String:newPath[128];
	GetClientAuthString(client, steamid, sizeof(steamid));
	ReplaceString(steamid, sizeof(steamid), ":", "-");
	Format(newPath, sizeof(newPath), "%s\\%s", g_LoggingPath, steamid);
	if(!DirExists(newPath)) {
		CreateDirectory(newPath, 511);
	}
}

public Action:OnCheatCommand(client, const String:command[], argc)
{
	if(client != 0)
	{
		decl String:Temp[256],String:cmd[256],String:cmdArgStr[256],String:steamid[32],String:TimeString[256],String:PersonLogDir[256];
		GetCmdArg(0, cmd, sizeof(cmd));
		GetCmdArgString(cmdArgStr, sizeof(cmdArgStr));	
		GetClientAuthString(client, steamid, sizeof(steamid));
		ReplaceString(steamid, sizeof(steamid), ":", "-");
		FormatTime(TimeString, sizeof(TimeString), "%y-%m-%d");
		Format(PersonLogDir, sizeof(PersonLogDir), "%s\\%s\\%s.txt", g_LoggingPath, steamid, TimeString);
		Format(Temp, sizeof(Temp), "Player %L used command %s %s", client, cmd, cmdArgStr);
		LogToCustomFile(PersonLogDir, Temp);
		for(new i = 0;i<GetArraySize(g_hBannedEntities);i++)
		{
			new String:entity[128];
			GetArrayString(g_hBannedEntities, i, entity, sizeof(entity));
			if(StrContains(cmd, entity, true) != -1 || StrContains(cmdArgStr, entity, true) != -1)
			{
				g_PlayerStrikes[client]++;
				
				new String:reason[512];
				Format(reason, sizeof(reason), "Using banned entity: %s", entity);
				
				if(g_PlayerStrikes[client] >= GetConVarInt(g_hMaxStrikes) && !g_PlayerBanned[client])
				{
					g_PlayerBanned[client] = true;
					BanClient(client, 0, BANFLAG_AUTO, reason, reason, "sm_ban", 0);
				}
				if(g_PlayerStrikes[client] == 1)
				{
					NotifyAdmins(client, entity);
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	for(new i = 0;i<GetArraySize(g_hBannedEntities);i++)
	{
		new String:entityname[128];
		GetArrayString(g_hBannedEntities, i, entityname, sizeof(entityname));
		if(StrEqual(classname, entityname, false))
		{
			AcceptEntityInput(entity , "kill");
		}
	}
}

NotifyAdmins(client, const String:entity[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (CheckCommandAccess(i, "sm_chat", ADMFLAG_CHAT)))
		{
			PrintToChat(i, "%N has attempted to use a banned entity %s.", client, entity);
		}	
	}
}