#define PLUGIN_VERSION 		"1.2"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Private Trigger Log
*	Author	:	SilverShot
*	Descrp	:	Suppresses text said after a slash and displays to admins. Logs all attempted private trigger commands.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=306473
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.2 (10-May-2020)
	- Various changes to tidy up code.
	- Various optimizations and fixes.

1.1 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Replaced AddCommandListener with OnClientSayCommand.

1.0 (01-Apr-2018)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Zephyrus" for "Store by Zephyrus" - Used to read private chat trigger from core.cfg.
	https://forums.alliedmods.net/showthread.php?t=276677
	https://github.com/dvarnai/store-plugin

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define CVAR_FLAGS 0

ConVar g_hAdmFlag, g_hChatBlock, g_hChatFlags, g_hCvarLog;
int SilentChatTriggers[16];

public Plugin myinfo =
{
	name = "[ANY] Private Trigger Log",
	author = "SilverShot",
	description = "Suppresses text said after a slash and displays to admins. Logs attempted private trigger commands.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306473"
}

public void OnPluginStart()
{
	g_hAdmFlag = CreateConVar(	"private_trigger_admin_flag",	"z",	"Admins with these flags will be shown all private triggered commands.", CVAR_FLAGS);
	g_hChatBlock = CreateConVar("private_trigger_chat_block",	"1",	"0=Hide successful commands (Sourcemod default), 1=Hide all messages, 2=Only hide messages from players with below flags).", CVAR_FLAGS);
	g_hChatFlags = CreateConVar("private_trigger_chat_flag",	"abc",	"Players with these flags will have their attempted private commands hidden (root admins always hidden by default).", CVAR_FLAGS);
	g_hCvarLog = CreateConVar(	"private_trigger_log",			"1",	"0=Disables, 1=Enables logging of each private trigger attempt.", CVAR_FLAGS);
	CreateConVar(				"private_trigger_version",		PLUGIN_VERSION,		"Private Trigger Log version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,		"private_trigger");

	// Read core.cfg for chat triggers
	ReadCoreCFG();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	bool pass;
	for( int i = 0; i < sizeof(SilentChatTriggers); i++ )
	{
		if( SilentChatTriggers[i] == 0 )
		{
			break;
		}
		else if( sArgs[0] == SilentChatTriggers[i] )
		{
			pass = true;
			break;
		}
	}

	if( pass )
	{
		if( g_hCvarLog.BoolValue )
		{
			LogAction(client, -1, "\"%L\" used private trigger \"%s\"", client, sArgs);
		}

		PrintToAdmins("\x04[PrivateTrigger] \x05%N\x01 : %s", client, sArgs);

		if( g_hChatBlock.IntValue == 1 )
		{
			return Plugin_Handled;
		} else {
			if( IsValidAdmin(client, g_hChatFlags) )
			{
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

void PrintToAdmins(char[] format, any ...)
{
	char buff[256];
	VFormat(buff, sizeof(buff), format, 2);

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) && IsValidAdmin(i, g_hAdmFlag) )
		{
			PrintToChat(i, buff);
		}
	}
}

bool IsValidClient(int client)
{
	if( client <= 0 || client > MaxClients || !IsClientInGame(client) || (IsFakeClient(client)) )
	{
		return false;
	}
	return true;
}

bool IsValidAdmin(int client, ConVar cvar)
{
	char flags[24];
	cvar.GetString(flags, sizeof(flags));

	int ibFlags = ReadFlagString(flags);
	int iFlags = GetUserFlagBits(client);

	if( iFlags & ibFlags || iFlags & ADMFLAG_ROOT )
	{
		return true;
	}
	return false;
}

public void ReadCoreCFG()
{
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, sizeof(m_szFile), "configs/core.cfg");

	SMCParser parser = new SMCParser();
	char error[128];
	int line = 0;
	int col = 0;

	SMC_SetReaders(parser, Config_NewSection, Config_KeyValue, Config_EndSection);
	parser.OnEnd = Config_End;

	SMCError result = parser.ParseFile(m_szFile, line, col);

	if( result != SMCError_Okay )
	{
		parser.GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, m_szFile);
	}

	delete parser;
}

public SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes)
{
	if( strcmp(section, "Core") == 0 )
		return SMCParse_Continue;
	return SMCParse_Continue;
}

public SMCResult Config_KeyValue(Handle parser, char[] key, char[] value, bool key_quotes, bool value_quotes)
{
	// if( strcmp(key, "PublicChatTrigger", false) == 0 )
		// PublicChatTrigger = value[0];
	if( strcmp(key, "SilentChatTrigger", false) == 0 )
	{
		for( int i = 0; i < strlen(value); i++ )
		{
			SilentChatTriggers[i] = value[i];
		}
	}

	return SMCParse_Continue;
}

public SMCResult Config_EndSection(Handle parser)
{
	return SMCParse_Continue;
}

public void Config_End(Handle parser, bool halted, bool failed)
{
}  