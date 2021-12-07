#include <sourcemod>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo =
{
	name = "Admin RegAdminCmd Logging",
	author = "El Diablo",
	description = "Logs all admin commands by hooking RegAdminCmd",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.info"
};


// commands to ignore
stock const String:IgnoreCommands[][] = {
	"+",
	"-",
	"hlx",
	"jointeam",
	"voicemenu",
	"tp",
	"fp"
};

// commands to include
stock const String:IncludeCommands[][] = {
	"war3"
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

stock bool:HasIncludeCommands(const String:CheckCommand[64])
{
	for(new i = 0; i < sizeof(IncludeCommands); i++)
	{
		if(StrContains(CheckCommand,IncludeCommands[i])==0)
		{
			return true;
		}
	}
	return false;
}

public OnPluginStart()
{
	CreateConVar("sm_regadmincmd_logging", PLUGIN_VERSION, "Admin RegAdminCmd Logging Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnAllPluginsLoaded()
{
	decl String:Name[64];
	decl String:Desc[255];
	new Flags;
	new Handle:CmdIter = GetCommandIterator();

	new i;
	while(ReadCommandIterator(CmdIter, Name, sizeof(Name), Flags, Desc, sizeof(Desc)))
	{
		// comment out any flags you dont want to check and remove || from first one

		if (
			(Flags & ADMFLAG_RESERVATION)
		||	(Flags & ADMFLAG_GENERIC)
		||	(Flags & ADMFLAG_KICK)
		||	(Flags & ADMFLAG_BAN)
		||	(Flags & ADMFLAG_UNBAN)
		||	(Flags & ADMFLAG_SLAY)
		||	(Flags & ADMFLAG_CHANGEMAP)
		||	(Flags & ADMFLAG_CONVARS)
		||	(Flags & ADMFLAG_CONFIG)
		||	(Flags & ADMFLAG_CHAT)
		||	(Flags & ADMFLAG_VOTE)
		||	(Flags & ADMFLAG_PASSWORD)
		||	(Flags & ADMFLAG_RCON)
		||	(Flags & ADMFLAG_CHEATS)
		||	(Flags & ADMFLAG_CUSTOM1)
		||	(Flags & ADMFLAG_CUSTOM2)
		||	(Flags & ADMFLAG_CUSTOM3)
		||	(Flags & ADMFLAG_CUSTOM4)
		||	(Flags & ADMFLAG_CUSTOM5)
		||	(Flags & ADMFLAG_CUSTOM6)
			)
		{
			if(AddCommandListener(Log_Admin_Command, Name))
			{
				i++;
				//LogMessage("Hooked %s Flags %d",Name,Flags);
			}
		}
		else if (
			(Flags & ADMFLAG_ROOT)
			)
		{
			if (!HasIgnoreCommands(Name))
			{
				if(AddCommandListener(Log_Admin_Command, Name))
				{
					i++;
					//LogMessage("ADMFLAG_ROOT %s Flags %d",Name,Flags);
				}
			}
		}
		else if (HasIncludeCommands(Name))
		{
			if(AddCommandListener(Log_Admin_Command, Name))
			{
				i++;
				//LogMessage("ADMFLAG_ROOT %s Flags %d",Name,Flags);
			}
		}
	}
	CloseHandle(CmdIter);
	LogMessage("Hooked %d RegAdminCmd commands",i);
}

public Action:Log_Admin_Command(client, const String:command[], args)
{
	if(client>0 && client<=MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		// Just in case the AddCommandListener added some command it wasn't suppose to via ADMFLAG_ROOT
		// for some reason commands that are registered via RegConsoleCmd without any flags specificed it will
		// assume it is ADMFLAG_ROOT???
		new Flags = GetCommandFlags(command);
		if (CheckCommandAccess(client, command, Flags))
		{
			// whole command string
			decl String:CmdBuffer[255];
			GetCmdArgString(CmdBuffer, sizeof(CmdBuffer));

			// filter out any unicode
			FilterSentence(CmdBuffer,false,false);

			decl String:steamid[32];
			GetClientAuthString(client, steamid, sizeof(steamid));
			ReplaceString(steamid, sizeof(steamid), ":", "-");
			ReplaceString(steamid, sizeof(steamid), "[", "");
			ReplaceString(steamid, sizeof(steamid), "]", "");

			/* Prefix our file with the word 'admin_' */
			decl String:file[PLATFORM_MAX_PATH], String:ClientName[MAX_NAME_LENGTH];

			if(GetClientName(client, ClientName, sizeof(ClientName)))
			{
				// forces name to be alpha-numeric only
				FilterSentence(ClientName,true,true);
				if(strlen(ClientName)>2)
				{
					BuildPath(Path_SM, file, sizeof(file), "logs/admin_%s_%s.log", steamid, ClientName);
				}
				else
				{
					BuildPath(Path_SM, file, sizeof(file), "logs/admin_%s.log", steamid);
				}
			}
			else
			{
				BuildPath(Path_SM, file, sizeof(file), "logs/admin_%s.log", steamid);
			}

			/* Finally, write to the log file with the log tag we deduced. */
			LogToFileEx(file, "[%s] %s", command, CmdBuffer);
		}
	}

	return Plugin_Continue;
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
