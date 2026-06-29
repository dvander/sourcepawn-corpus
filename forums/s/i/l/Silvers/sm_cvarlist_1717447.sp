/*=======================================================================================
	Plugin Info:

*	Name	:	sm_cvarlist and sm_cmdlist
*	Author	:	SilverShot
*	Descrp	:	Dump cvar/cmd list to sourcemod/logs folder.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=185125

=======================================================================================*/

#pragma semicolon 1
#include <sourcemod>

static Handle:g_hCvarPlugins;

public Plugin:myinfo =
{
	name = "sm_cvarlist and sm_cmdlist",
	author = "SilverShot",
	description = "Dump cvar/cmd list to sourcemod/logs folder.",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=185125"
}

public OnPluginStart()
{
	g_hCvarPlugins = CreateConVar("sm_cvarlist_plugins", "0", "List cvars created by sourcemod plugins?");
	RegAdminCmd("sm_cvarlist", Command_cvars, ADMFLAG_ROOT);
	RegAdminCmd("sm_cmdlist", Command_cmds, ADMFLAG_ROOT);
}

public Action:Command_cvars(client, args)
{
	decl String:name[1024], String:value[1024], String:descp[1024], String:sflags[1024];
	new Handle:cvar, bool:isCommand, flags;

	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags, descp, sizeof(descp));
	if( cvar == INVALID_HANDLE)
	{
		PrintToConsole(client, "Could not load cvar list");
		return Plugin_Handled;
	}

	PrintToConsole(client, "Saving cvar list...");

	new plugins = GetConVarInt(g_hCvarPlugins);

	do {
		if( isCommand == false && (plugins == 1 || plugins == 0 && !(FCVAR_PLUGIN & flags)) )
		{
			GetConVarString(FindConVar(name), value, sizeof(value));
			FlagString(flags, sflags, sizeof(sflags));
			ReplaceString(name, sizeof(name), "\n", " ");
			ReplaceString(descp, sizeof(descp), "\n", " ");
			Pad(name, 50);
			Pad(value, 15);
			Pad(sflags, 20);
			LogCustom(1, "%s : %s : %s : %s", name, value, sflags, descp);
		}
	} while( FindNextConCommand(cvar, name, sizeof(name), isCommand, flags, descp, sizeof(descp)) );

	PrintToConsole(client, "Cvar list saved to 'sourcemod/logs/dump_cvarlist'.");
	return Plugin_Handled;
}

public Action:Command_cmds(client, args)
{
	decl String:name[1024], String:descp[1024], String:sflags[1024];
	new Handle:cvar, bool:isCommand, flags;
	cvar = FindFirstConCommand(name, sizeof(name), isCommand, flags, descp, sizeof(descp));
	if(cvar == INVALID_HANDLE)
	{
		PrintToConsole(client, "Could not load cvar list");
		return Plugin_Handled;
	}

	PrintToConsole(client, "Saving command list...");

	new plugins = GetConVarInt(g_hCvarPlugins);

	do {
		if( isCommand == true && (plugins == 1 || plugins == 0 && !(FCVAR_PLUGIN & flags)) )
		{
			ReplaceString(name, sizeof(name), "\n", " ");
			ReplaceString(descp, sizeof(descp), "\n", " ");
			FlagString(flags, sflags, sizeof(sflags));
			Pad(name, 50);
			Pad(sflags, 20);
			LogCustom(0, "%s : %s : %s", name, sflags, descp);
			SetCommandFlags(name, flags);
		}
	} while( FindNextConCommand(cvar, name, sizeof(name), isCommand, flags, descp, sizeof(descp)) );

	PrintToConsole(client, "Command list saved to 'sourcemod/logs/dump_cmdslist'.");
	return Plugin_Handled;
}

Pad(String:buffer[], size)
{
	new len = strlen(buffer);

	while( len < size )
	{
		buffer[len] = ' ';
		len++;
	}
	
	buffer[len] = '\x0';
}

FlagString(flags, String:sflags[], size)
{
	Format(sflags, size, "");

	if( flags & FCVAR_UNREGISTERED )
		StrCat(sflags, size, "UNREGISTERED|");
	if( flags & FCVAR_LAUNCHER )
		StrCat(sflags, size, "LAUNCHER|");
	if( flags & FCVAR_GAMEDLL )
		StrCat(sflags, size, "GAMEDLL|");
	if( flags & FCVAR_CLIENTDLL )
		StrCat(sflags, size, "CLIENTDLL|");
	if( flags & FCVAR_MATERIAL_SYSTEM )
		StrCat(sflags, size, "MATERIAL_SYSTEM|");
	if( flags & FCVAR_PROTECTED )
		StrCat(sflags, size, "PROTECTED|");
	if( flags & FCVAR_SPONLY )
		StrCat(sflags, size, "SPONLY|");
	if( flags & FCVAR_ARCHIVE )
		StrCat(sflags, size, "ARCHIVE|");
	if( flags & FCVAR_NOTIFY )
		StrCat(sflags, size, "NOTIFY|");
	if( flags & FCVAR_USERINFO )
		StrCat(sflags, size, "USERINFO|");
	if( flags & FCVAR_PRINTABLEONLY )
		StrCat(sflags, size, "PRINTABLEONLY|");
	if( flags & FCVAR_UNLOGGED )
		StrCat(sflags, size, "UNLOGGED|");
	if( flags & FCVAR_NEVER_AS_STRING )
		StrCat(sflags, size, "NEVER_AS_STRING|");
	if( flags & FCVAR_REPLICATED )
		StrCat(sflags, size, "REPLICATED|");
	if( flags & FCVAR_CHEAT )
		StrCat(sflags, size, "CHEAT|");
	if( flags & FCVAR_STUDIORENDER )
		StrCat(sflags, size, "STUDIORENDER|");
	if( flags & FCVAR_DEMO )
		StrCat(sflags, size, "DEMO|");
	if( flags & FCVAR_DONTRECORD )
		StrCat(sflags, size, "DONTRECORD|");
	if( flags & FCVAR_PLUGIN )
		StrCat(sflags, size, "PLUGIN|");
	if( flags & FCVAR_USERINFO )
		StrCat(sflags, size, "USERINFO|");
	if( flags & FCVAR_DATACACHE )
		StrCat(sflags, size, "DATACACHE|");
	if( flags & FCVAR_TOOLSYSTEM )
		StrCat(sflags, size, "TOOLSYSTEM|");
	if( flags & FCVAR_FILESYSTEM )
		StrCat(sflags, size, "FILESYSTEM|");
	if( flags & FCVAR_NOT_CONNECTED )
		StrCat(sflags, size, "NOT_CONNECTED|");
	if( flags & FCVAR_SOUNDSYSTEM )
		StrCat(sflags, size, "SOUNDSYSTEM|");
	if( flags & FCVAR_ARCHIVE_XBOX )
		StrCat(sflags, size, "ARCHIVE_XBOX|");
	if( flags & FCVAR_INPUTSYSTEM )
		StrCat(sflags, size, "INPUTSYSTEM|");
	if( flags & FCVAR_NETWORKSYSTEM )
		StrCat(sflags, size, "NETWORKSYSTEM|");
	if( flags & FCVAR_VPHYSICS )
		StrCat(sflags, size, "VPHYSICS|");

	new len = strlen(sflags) -1;
	if( len > 1 )
		sflags[len] = '\x0';
}

LogCustom(type, const String:format[], any:...)
{
	decl String:buffer[512];
	VFormat(buffer, sizeof(buffer), format, 3);

	new Handle:file;
	decl String:FileName[256];
	if( type )
		BuildPath(Path_SM, FileName, sizeof(FileName), "logs/dump_cvarlist.txt");
	else
		BuildPath(Path_SM, FileName, sizeof(FileName), "logs/dump_cmdlist.txt");
	file = OpenFile(FileName, "a+");
	WriteFileLine(file, "%s", buffer);
	FlushFile(file);
	CloseHandle(file);
}