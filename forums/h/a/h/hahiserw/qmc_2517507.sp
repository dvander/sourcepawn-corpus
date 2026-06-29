#include <sourcemod>


// should be more than enough
#define INPUT_LENGTH_MAX 20

// stop searching after that many matches
#define MATCHED_INDEXES_MAX 10

// to not write it twice
#define INFO_VERSION     "1.3.2"
#define INFO_NAME        "Quick map changer"
#define INFO_DESCRIPTION \
	"Type a few letters of a map's name to quickly change the map"


new Handle:g_MapListMapCycle = INVALID_HANDLE;
new Handle:g_MapListAll      = INVALID_HANDLE;
new g_mapFileSerial          = -1;
new g_mapFileSerialAll       = -1;

new g_mapListMatchedIndexes[MATCHED_INDEXES_MAX];


public Plugin:myinfo =
{
	name        = INFO_NAME,
	author      = "hahiserw",
	description = INFO_DESCRIPTION,
	version     = INFO_VERSION,
	url         = "https://github.com/hahiserw/sourcemod-qmc"
};


public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("qmc.phrases");

	CreateConVar("qmc_version", INFO_VERSION, INFO_NAME,
				 FCVAR_NOTIFY | FCVAR_SPONLY);

	new String:description[100];
	Format(description, sizeof(description), "%s  (from mapcycle)", INFO_DESCRIPTION);
	RegAdminCmd("qmc", Command_Qmc, ADMFLAG_CHANGEMAP, description);
	Format(description, sizeof(description), "%s  (all maps)", INFO_DESCRIPTION);
	RegAdminCmd("qmca", Command_Qmc, ADMFLAG_CHANGEMAP, description);

	g_MapListMapCycle = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	g_MapListAll      = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
}


// just as in mapchooser.sp
public OnConfigsExecuted()
{
	if (ReadMapList(g_MapListMapCycle,
					g_mapFileSerial,
					"qmc",
					MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER)
		!= INVALID_HANDLE)
	{
		if (g_mapFileSerial == -1)
		{
			LogError("Unable to create a valid map list.");
		}
	}

	ReadMapList(g_MapListAll,
				g_mapFileSerialAll,
				"qmcall",
				MAPLIST_FLAG_CLEARARRAY | MAPLIST_FLAG_NO_DEFAULT
				| MAPLIST_FLAG_MAPSFOLDER)
}


public Action:Command_Qmc(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: qmc <few_letters_of_mapname> [mode]");
		ReplyToCommand(client, "Usage: qmca <few_letters_of_mapname> [mode]");

		return Plugin_Handled;
	}

	new String:command[INPUT_LENGTH_MAX];
	new String:input[INPUT_LENGTH_MAX];
	new String:mode[INPUT_LENGTH_MAX];

	GetCmdArg(0, command, sizeof(command));
	GetCmdArg(1, input, sizeof(input));
	GetCmdArg(2, mode, sizeof(mode));

	if (StrEqual(input, "!")) {
		OnConfigsExecuted();
		ReplyToCommand(client, "%t", "Map list reloaded", input);

		return Plugin_Handled;
	}

	new Handle:mapList = StrEqual(command, "qmca")? g_MapListAll: g_MapListMapCycle;

	new matches = FindMatchingMaps(mapList, input);

	switch (matches)
	{
	case -1:
		{
			ReplyToCommand(client, "There is some error in getting map list");

			return Plugin_Stop;
		}

	case 0:
		{
			ReplyToCommand(client, "%t", "No mathing maps found for", input);
		}

	case 1:
		{
			ChangeToFirstMatchingMap(mapList, client, mode);
		}

	default:
		{
			if (matches < MATCHED_INDEXES_MAX)
			{
				decl String:map[PLATFORM_MAX_PATH];
				decl String:map_first[PLATFORM_MAX_PATH];

				new bool:first_map_substring = true;
				new map_first_size = sizeof(map_first);

				new index = g_mapListMatchedIndexes[0];
				GetArrayString(mapList, index, map_first, map_first_size);

				// see if first map's name is substring of another ones
				// if it is, user probably wanted to change to it
				// eg. `qmc bhz` could match dm_biohazard and dm_biohazard_cal,
				// but if user wanted the former they would type `qmc bhzc`
				for (new i = 1; i < matches; i++)
				{
					index = g_mapListMatchedIndexes[i];
					GetArrayString(mapList, index, map, sizeof(map));

					if (strncmp(map_first, map[i], map_first_size) == 0)
					{
						first_map_substring = false;
						break;
					}
				}

				if (first_map_substring)
				{
					ChangeToFirstMatchingMap(mapList, client, mode);

					return Plugin_Handled;
				}

				ReplyToCommand(client, "%t", "Found x matching maps:",
							   matches);

				for (new i = 0; i < matches; i++)
				{
					index = g_mapListMatchedIndexes[i];
					GetArrayString(mapList, index, map, sizeof(map));

					ReplyToCommand(client, map);
				}
			}
			else
			{
				ReplyToCommand(client, "%t",
							   "Too many matching maps found for", input);
			}
		}
	}

	return Plugin_Handled;
}


public ChangeToFirstMatchingMap(Handle:mapList, client, const String:mode[])
{
	decl String:map[PLATFORM_MAX_PATH];

	new index = g_mapListMatchedIndexes[0];
	GetArrayString(mapList, index, map, sizeof(map));

	if (!strlen(mode)) {
		ShowActivity(client, "%t", "Changing map", map);
		LogAction(client, -1, "\"%L\" changed map to \"%s\"", client, map);

		new Handle:dp;
		CreateDataTimer(3.0, Timer_ChangeMap, dp);
		WritePackString(dp, map);
		return;
	}

	// dry run
	if (strcmp(mode, "?", false) == 0)
	{
		ReplyToCommand(client, map);
		return;
	}

	new command_length = INPUT_LENGTH_MAX + 3;
	decl String:command[command_length];

	// read aliases from a configuration file?
	if (strcmp(mode, "vm", false) == 0)
	{
		strcopy(command, command_length, "sm_votemap");
	}
	else if (strcmp(mode, "nm", false) == 0)
	{
		strcopy(command, command_length, "sm_nextmap");
	}


	// first check if mode is a cvar since every cvar is also a command?

	// cvar
	strcopy(command, command_length, mode);

	new Handle:mode_convar = FindConVar(command);

	if (!mode_convar)
	{
		strcopy(command, command_length, "sm_");
		StrCat(command, command_length, mode);

		mode_convar = FindConVar(command);
	}

	if (mode_convar)
	{
		LogAction(client, -1, "\"%L\" set console variable \"%s\" to \" %s\"", client, mode, map);
		SetConVarString(mode_convar, map);
		return;
	}


	// command
	strcopy(command, command_length, mode);

	bool run_command = false;

	if (CommandExists(command))
	{
		run_command = true;
	}
	else
	{
		strcopy(command, command_length, "sm_");
		StrCat(command, command_length, mode);

		if (CommandExists(command))
		{
			run_command = true;
		}
	}

	if (run_command)
	{
		LogAction(client, -1, "\"%L\" called \"%s %s\"", client, command, map);
		ServerCommand("%s %s", command, map);
		return;
	}


	ReplyToCommand(client, "%t", "No such cvar nor command:", command);
}


public FindMatchingMaps(Handle:mapList, const String:input[])
{
	new map_count = GetArraySize(mapList);

	if (!map_count)
	{
		return -1;
	}

	new matches = 0;
	decl String:map[PLATFORM_MAX_PATH];

	for (new i = 0; i < map_count; i++)
	{
		GetArrayString(mapList, i, map, sizeof(map));

		if (FuzzyCompare(input, map))
		{
			g_mapListMatchedIndexes[matches] = i;
			matches++;

			if (matches >= MATCHED_INDEXES_MAX)
			{
				break;
			}
		}
	}

	return matches;
}


// just as in basecommands/map.sp
public Action:Timer_ChangeMap(Handle:hTimer, Handle:dp)
{
	decl String:map[PLATFORM_MAX_PATH];

	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));

	ForceChangeLevel(map, INFO_NAME);

	return Plugin_Stop;
}


// shamelessly ripped off of https://github.com/bevacqua/fuzzysearch
public FuzzyCompare(const String:needle[], const String:haystack[])
{
	new hlen = strlen(haystack);
	new nlen = strlen(needle);

	if (nlen > hlen)
	{
		return false;
	}

	if (nlen == hlen)
	{
		return strcmp(needle, haystack) == 0;
	}

	new n = 0;
	new h = 0;
	new p = 0;

	for (; n < nlen; n++)
	{
		new nch = needle[n];

		while (h < hlen)
		{
			if (nch == haystack[h])
			{
				h++;
				p++;
				break;
			}

			h++;
		}
	}

	return p == nlen;
}


// vim: ft=sourcepawn
