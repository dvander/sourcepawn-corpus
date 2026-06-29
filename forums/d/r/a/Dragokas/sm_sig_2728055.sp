#define PLUGIN_VERSION		"1.4.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Gamedata Sig Tester
*	Author	:	SilverShot
*	Descrp	:	Test gamedata signature bytes via command.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=316990
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4.1 (08-Dec-2020)
	- allow providing escaped bytes in sm_sig (\x)

1.4 (10-May-2020)
	- Various changes to tidy up code.

1.3 (26-June-2019)
	- Added convar "sm_sig_library" to determine which library to search.

1.2 (21-June-2019)
	- Added command sm_sig_hex.
	- Fixed quoted strings not working.

1.1 (20-June-2019)
	- Fixed memory leak.

1.0 (20-June-2019)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>


ConVar gCvarLibrary;



public Plugin myinfo =
{
	name = "[ANY] Gamedata Sig Tester",
	author = "SilverShot",
	description = "Test gamedata signature bytes via command.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=316990"
}

public void OnPluginStart()
{
	gCvarLibrary =	CreateConVar("sm_sig_library", "1", "Which library to search. 0=Engine, 1=Server.", 0);
	CreateConVar("sm_sig_version", PLUGIN_VERSION, "Gamedata Sig Tester plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegAdminCmd("sm_sig",		CmdSig,		ADMFLAG_ROOT,	"Usage: sm_sig <bytes>");
	RegAdminCmd("sm_sig_hex",	CmdSigHex,	ADMFLAG_ROOT,	"Usage: sm_sig_hex <bytes>. Converts hex escaped bytes to non-escaped.");
}

public Action CmdSigHex(int client, int args)
{
	char buffer[2048];
	GetCmdArgString(buffer, sizeof(buffer));
	StripQuotes(buffer);
	ReplaceString(buffer, sizeof(buffer), "\\x", " ");
	ReplaceString(buffer, sizeof(buffer), "2A", "?");
	ReplyToCommand(client, "[SIG]: %s", buffer);
	return Plugin_Handled;
}

public Action CmdSig(int client, int args)
{
	// Validate
	if( args < 1 )
	{
		ReplyToCommand(client, "[SIG] Add more bytes!");
		return Plugin_Handled;
	}

	// Vars
	char byte[2];
	char buff[1024][3];
	char buffer[2048];
	char buffer2[2048];

	// Bytes wildcard
	GetCmdArgString(buffer, sizeof(buffer));
	ReplaceString(buffer, sizeof(buffer), "?", "2A");
	ReplaceString(buffer, sizeof(buffer), "\\x", " ");

	// Strip quotes
	StripQuotes(buffer);
	
	// Remove leading whitespace
	TrimString(buffer);

	// Explode
	int count = ExplodeString(buffer, " ", buff, sizeof(buff), sizeof(buff[]), false);
	ReplaceString(buffer, sizeof(buffer), " ", "\\x");
	strcopy(buffer2, sizeof(buffer2), buffer);

	// Convert bytes to char
	for( int i = 0; i < count; i++ )
	{
		Format(byte, sizeof(byte), "%s", HexToDec(buff[i]));
		buffer[i] = byte[0];
	}

	// Prep
	StartPrepSDKCall(SDKCall_Raw);

	// Test
	if( PrepSDKCall_SetSignature(gCvarLibrary.IntValue ? SDKLibrary_Server : SDKLibrary_Engine, buffer, count) )
	{
		ReplyToCommand(client, "[SIG]: \\x%s", buffer2);
		ReplyToCommand(client, "[SIG] Signature found!");
	} else {
		ReplyToCommand(client, "[SIG] Failed to find signature.");
	}

	// Cleanup
	delete EndPrepSDKCall();

	return Plugin_Handled;
}

int HexToDec(char[] bytes)
{
	int len = strlen(bytes);
	int base = 1;
	int value = 0;

	for( int i = len - 1; i >= 0; i-- )
	{
		if( bytes[i] >= '0' && bytes[i] <= '9' )
		{
			value += (bytes[i] - 48) * base;
			base = base * 16;
		}

		else if( bytes[i] >= 'A' && bytes[i] <= 'F' )
		{
			value += (bytes[i] - 55) * base;
			base = base * 16;
		}
	}

	return value;
}