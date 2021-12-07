#pragma semicolon 1
#pragma newdecls required

static const char
	CMD_DUMP[]	= "addons/sourcemod/! cmdlist_%Y.%m.%d-%H.%M.%S.cfg",
	CVAR_DUMP[]	= "addons/sourcemod/! cvarlist_%Y.%m.%d-%H.%M.%S.cfg",
	FLAGS[][][]	=
{	// old flags			new flags
	{"UNREGISTERED",	"UNREGISTERED"},
	{"LAUNCHER",		"DEVELOPMENTONLY"},			//new
	{"GAMEDLL",			"GAMEDLL"},
	{"CLIENTDLL",		"CLIENTDLL"},
	{"MATERIAL_SYSTEM",	"MATERIAL_SYSTEM"},
	{"PROTECTED",		"PROTECTED"},
	{"SPONLY",			"SPONLY"},
	{"ARCHIVE",			"ARCHIVE"},
	{"NOTIFY",			"NOTIFY"},
	{"USERINFO",		"USERINFO"},
	{"PRINTABLEONLY",	"PRINTABLEONLY"},
	{"UNLOGGED",		"UNLOGGED"},
	{"NEVER_AS_STRING",	"NEVER_AS_STRING"},
	{"REPLICATED",		"REPLICATED"},
	{"CHEAT",			"CHEAT"},
	{"STUDIORENDER",	"SS"},						//new
	{"DEMO",			"DEMO"},
	{"DONTRECORD",		"DONTRECORD"},
	{"PLUGIN",			"SS_ADDED"},				//new
	{"DATACACHE",		"RELEASE"},					//new
	{"TOOLSYSTEM",		"RELOAD_MATERIALS"},		//new
	{"FILESYSTEM",		"FILESYSTEM"},
	{"NOT_CONNECTED",	"NOT_CONNECTED"},
	{"SOUNDSYSTEM",		"MATERIAL_SYSTEM_THREAD"},	//new
	{"ARCHIVE_XBOX",	"ARCHIVE_XBOX"},
	{"INPUTSYSTEM",		"ACCESSIBLE_FROM_THREADS"},	//new
	{"NETWORKSYSTEM",	"NETWORKSYSTEM"},
	{"VPHYSICS",		"VPHYSICS"},
	{"",				"SERVER_CAN_EXECUTE"},		//new
	{"",				"SERVER_CANNOT_QUERY"},		//new
	{"",				"CLIENTCMD_CAN_EXECUTE"}	//new
};

bool bNew;

public Plugin myinfo =
{
	name		= "[TOOLS] Cvarlist & Cmdlist",
	author		= "MCPAN(mcpan@foxmail.com) (rewritten by Grey83)",
	description	= "List all cvar/cmd value, flags and description.",
	version		= "1.2.0",
	url			= "https://forums.alliedmods.net/showthread.php?t=201768"
}

public void OnPluginStart()
{
	bNew = GetEngineVersion() > Engine_SourceSDK2006;
	RegServerCmd("tools_cvarlist", tools_cvarlist);
}

public Action tools_cvarlist(int argc)
{
	bool isCommand;
	int flags;
	Handle cvarIter, cvarTrieDesc = CreateTrie(), cvarTrieFlags = CreateTrie(), cvarArray = CreateArray(ByteCountToCells(256)), cmdTrieDesc = CreateTrie(), cmdTrieFlags = CreateTrie(),
cmdArray = CreateArray(ByteCountToCells(256));
	char buffer[256], desc[1024];

	do
	{
		if(!cvarIter) cvarIter = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc));

		if(isCommand)
		{
			PushArrayString(cmdArray, buffer);
			SetTrieString(cmdTrieDesc, buffer, desc);
			SetTrieValue(cmdTrieFlags, buffer, flags);
			continue;
		}

		PushArrayString(cvarArray, buffer);
		SetTrieString(cvarTrieDesc, buffer, desc);
		SetTrieValue(cvarTrieFlags, buffer, flags);
	}
	while(FindNextConCommand(cvarIter, buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc)));
	CloseHandle(cvarIter);

	Handle file;
	int size;
	char game[32], version[32], appid[16], map[64], path[256], flagsStr[1024], value[256];
	GetCurrentMap(map, sizeof(map));
	GetGameInformation(version, game, appid);

	FormatTime(path, sizeof(path), CMD_DUMP);
	file = OpenFile(path, "a+");
	size = GetArraySize(cmdArray);
	SortADTArray(cmdArray, Sort_Ascending, Sort_String);
	WriteFileLine(file, "// game=%s, version=%s, appid=%s, map=%s, totalcmd=%d\n", game, version, appid, map, size);

	for(int i; i < size; i++)
	{
		GetArrayString(cmdArray, i, buffer, sizeof(buffer));
		if(GetTrieString(cmdTrieDesc, buffer, desc, sizeof(desc)) && desc[0])
		{
			ReplaceString(desc, sizeof(desc), "\n", "\n// ");
			WriteFileLine(file, "// %s", desc);
		}

		if(GetTrieValue(cmdTrieFlags, buffer, flags) && flags)
		{
			ConVarFlagsToString(flags, flagsStr, sizeof(flagsStr));
			WriteFileLine(file, "// Flags: %s", flagsStr);
		}

		WriteFileLine(file, "%s\n", buffer);
	}
	CloseHandle(file);
	CloseHandle(cmdArray);
	CloseHandle(cmdTrieDesc);
	CloseHandle(cmdTrieFlags);
	PrintToServer("Command dump finished. \"%s\"", path);

	FormatTime(path, sizeof(path), CVAR_DUMP);
	file = OpenFile(path, "a+");
	size = GetArraySize(cvarArray);
	SortADTArray(cvarArray, Sort_Ascending, Sort_String);
	WriteFileLine(file, "// game=%s, version=%s, appid=%s, map=%s, totalcvar=%d\n", game, version, appid, map, size);

	Handle hndl;
	float valueMin, valueMax;
	for(int i; i < size; i++)
	{
		GetArrayString(cvarArray, i, buffer, sizeof(buffer));
		if(GetTrieString(cvarTrieDesc, buffer, desc, sizeof(desc)) && desc[0])
		{
			ReplaceString(desc, sizeof(desc), "\n", "\n// ");
			WriteFileLine(file, "// %s", desc);
		}

		if(GetTrieValue(cvarTrieFlags, buffer, flags) && flags)
		{
			ConVarFlagsToString(flags, flagsStr, sizeof(flagsStr));
			WriteFileLine(file, "// Flags: %s", flagsStr);
		}

		flagsStr[0] = 0;
		if(GetConVarBounds((hndl = FindConVar(buffer)), ConVarBound_Lower, valueMin))
		{
			FloatToStringEx(valueMin, game, sizeof(game));
			FormatEx(flagsStr, sizeof(flagsStr), " Min: \"%s\"", game);
		}

		if(GetConVarBounds(hndl, ConVarBound_Upper, valueMax))
		{
			FloatToStringEx(valueMax, game, sizeof(game));
			Format(flagsStr, sizeof(flagsStr), "%s%s Max: \"%s\"", flagsStr, flagsStr[0] ? "" : "//", game);
		}

		GetConVarDefault(hndl, value, sizeof(value));
		WriteFileLine(file, "//%s Def.: \"%s\"", flagsStr, value);

		GetConVarString(hndl, value, sizeof(value));
		WriteFileLine(file, "%s \"%s\"\n", buffer, value);
	}
	CloseHandle(file);
	CloseHandle(cvarTrieDesc);
	CloseHandle(cvarTrieFlags);
	CloseHandle(cvarArray);
	PrintToServer("ConVar dump finished. \"%s\"", path);
	return Plugin_Handled;
}

stock void ConVarFlagsToString(int flags, char[] flagsStr, int length)
{
	flagsStr[0] = 0;
	for(int i; i < sizeof(FLAGS); i++) if(flags & (1 << i))
		Format(flagsStr, length, "%s%sFCVAR_%s", flagsStr, flagsStr[0] ? "|" : "", FLAGS[i][view_as<int>(bNew)]);
}

stock void GetGameInformation(char[] PatchVersion, char[] ProductName, char[] appID)
{
	Handle file;
	if(!(file = OpenFile("steam.inf", "r")))
		return;

	char buffer[64];
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if(!StrContains(buffer, "PatchVersion="))		strcopy(PatchVersion, strlen(buffer) - 13, buffer[13]);
		else if(!StrContains(buffer, "ProductName="))	strcopy(ProductName, strlen(buffer) - 12, buffer[12]);
		else if(!StrContains(buffer, "appID="))			strcopy(appID, strlen(buffer) - 6, buffer[6]);
	}
	CloseHandle(file);
}

stock int FloatToStringEx(float num, char[] str, int maxlength)
{
	int len = FloatToString(num, str, maxlength);
	for(int i = len - 1, idx; i >= 0; i--) if(str[i] != '0')
	{
		idx = str[i] == '.' ? 1 : 0;
		len = i - idx + 1;
		str[len] = 0;
		break;
	}
	return len;
}