#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

ConVar		g_cvDefMapcycleFile = null,
			g_cvRecentMaps = null;

int			ga_iCooldown[MAXPLAYERS + 1] = {0, ...},
			g_iRecentMaps;

char		g_sDefMapcycleFile[PLATFORM_MAX_PATH],
			g_sTempMapcycleFile[PLATFORM_MAX_PATH];

bool		g_bHooked = false,
			g_bLoadArrayFromFile = true;

ArrayList	ga_hExcludedMaps;

public Plugin myinfo = {
	name		= "lastmaps",
	author		= "Nullifidian",
	description	= "Creates & sets the server to a new custom mapcyclefile without recently played maps.",
	version		= "1.8",
	url			= ""
};

public void OnPluginStart() {
	if (!(g_cvDefMapcycleFile = FindConVar("mapcyclefile"))) {
		SetFailState("Fatal Error [0]: Unable to FindConVar \"mapcyclefile\" !");
	}

	ga_hExcludedMaps = CreateArray(32);

	g_cvRecentMaps = CreateConVar("sm_lastmaps", "7", "Number of recent maps to exclude", _, true, 1.0);
	g_iRecentMaps = g_cvRecentMaps.IntValue;
	g_cvRecentMaps.AddChangeHook(OnConVarChanged);

	char sBuffer[PLATFORM_MAX_PATH];
	GetPluginFilename(INVALID_HANDLE, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), ".smx", "", false);
	AutoExecConfig(true, sBuffer);

	RegConsoleCmd("lastmaps", cmd_lastmaps, "Recently played maps that will be excluded from the map vote.");

	//because plugin reloads faster than "ServerCommand" in "OnPluginEnd"
	CreateTimer(0.1, Timer_Setup);
}

public void OnMapStart() {
	CreateTimer(0.2, Timer_MapStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

void MakeTempMapcyle() {
	if (ga_hExcludedMaps.Length < 1) {
		if (g_bHooked) {
			g_cvDefMapcycleFile.RemoveChangeHook(OnConVarChanged);
			ServerCommand("mapcyclefile %s", g_sDefMapcycleFile);
			g_bHooked = false;
		}

		PrintToServer("Fatal Error [1]: array \"ga_hExcludedMaps\" is empty!");
		SetFailState("Fatal Error [1]: array \"ga_hExcludedMaps\" is empty!");
	}

	Handle hRead = OpenFile(g_sDefMapcycleFile, "rt", false);
	if (!hRead) {
		if (g_bHooked) {
			g_cvDefMapcycleFile.RemoveChangeHook(OnConVarChanged);
			ServerCommand("mapcyclefile %s", g_sDefMapcycleFile);
			g_bHooked = false;
		}

		PrintToServer("Fatal Error [2]: can't open \"%s\" !", g_sDefMapcycleFile);
		SetFailState("Fatal Error [2]: can't open \"%s\" !", g_sDefMapcycleFile);
	}

	Handle hWrite = OpenFile(g_sTempMapcycleFile, "wt", false);
	if (!hWrite) {
		if (g_bHooked) {
			g_cvDefMapcycleFile.RemoveChangeHook(OnConVarChanged);
			ServerCommand("mapcyclefile %s", g_sDefMapcycleFile);
			g_bHooked = false;
		}

		PrintToServer("Fatal Error [3]: can't open \"%s\" !", g_sTempMapcycleFile);
		SetFailState("Fatal Error [3]: can't open \"%s\" !", g_sTempMapcycleFile);
	}

	bool	bSkip = false;

	char	sBuffer[128],
			sArrayBuffer[32];

	int		iLines = 0;

	while (!IsEndOfFile(hRead)) {
		if (!ReadFileLine(hRead, sBuffer, sizeof(sBuffer))) {
			continue;
		}

		TrimString(sBuffer);

		if (strlen(sBuffer) < 3) {
			continue;
		}

		if (StrContains(sBuffer, "//", false) == 0) {
			continue;
		}

		for (int i = 0; i < ga_hExcludedMaps.Length; i++) {
			ga_hExcludedMaps.GetString(i, sArrayBuffer, sizeof(sArrayBuffer));
			if (StrContains(sBuffer, sArrayBuffer, false) == 0) {
				bSkip = true;
				break;
			}
		}

		if (bSkip) {
			bSkip = false;
			continue;
		}

		iLines++;
		WriteFileLine(hWrite, sBuffer);
	}

	if (iLines < 3) {
		if (g_bHooked) {
			g_cvDefMapcycleFile.RemoveChangeHook(OnConVarChanged);
			ServerCommand("mapcyclefile %s", g_sDefMapcycleFile);
			g_bHooked = false;
		}

		PrintToServer("Fatal Error [4]: failed to make \"%s\" due to \"%s\" not having enough maps! Try lowering \"sm_lastmaps\"", g_sTempMapcycleFile, g_sDefMapcycleFile);
		SetFailState("Fatal Error [4]: failed to make \"%s\" due to \"%s\" not having enough maps! Try lowering \"sm_lastmaps\"", g_sTempMapcycleFile, g_sDefMapcycleFile);
	}

	delete hWrite;
	delete hRead;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (convar == g_cvDefMapcycleFile && strcmp(newValue, g_sTempMapcycleFile, false) != 0) {
		//strcopy(g_sDefMapcycleFile, sizeof(g_sDefMapcycleFile), g_sTempMapcycleFile);
		ServerCommand("mapcyclefile %s", g_sTempMapcycleFile);
	}
	else if (convar == g_cvRecentMaps) {
		g_iRecentMaps = g_cvRecentMaps.IntValue;
		RemoveMapFromArray();
	}
}

public Action cmd_lastmaps(int client, int args) {
	if (client > 0) {
		int iTime = GetTime();
		if (iTime < ga_iCooldown[client]) {
			ga_iCooldown[client] += 2;
			ReplyToCommand(client, "You must wait %d seconds before using this command again!", (ga_iCooldown[client] - iTime));
			return Plugin_Handled;
		}
		ga_iCooldown[client] = iTime + 3;
	}

	char tempBuffer[192], sArrayBuffer[32];
	tempBuffer[0] = '\0'; // Initialize tempBuffer as an empty string
	int currentLength = 0;

	for (int i = 0; i < ga_hExcludedMaps.Length; i++) {
		ga_hExcludedMaps.GetString(i, sArrayBuffer, sizeof(sArrayBuffer));

		// Add separator if not the first element
		if (i != 0) {
			StrCat(tempBuffer, sizeof(tempBuffer), " ");
			currentLength++;
		}

		// Check if adding the next map will exceed the limit
		if (currentLength + strlen(sArrayBuffer) >= sizeof(tempBuffer)) {
			// Send the current buffer and reset it if limit is reached
			PrintToConsole(client, "%s", tempBuffer);
			tempBuffer[0] = '\0'; // Clear buffer
			currentLength = 0;
		}

		// Concatenate the map name
		StrCat(tempBuffer, sizeof(tempBuffer), sArrayBuffer);
		currentLength += strlen(sArrayBuffer);
	}

	// Output any remaining maps in the buffer
	if (currentLength > 0) {
		PrintToConsole(client, "%s", tempBuffer);
	}

	// Check if the command was sent from chat or console
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT) {
		ReplyToCommand(client, "Output has been printed to the console.");
	}

	return Plugin_Handled;
}

Action Timer_Setup(Handle timer) {
	GetConVarString(g_cvDefMapcycleFile, g_sDefMapcycleFile, sizeof(g_sDefMapcycleFile));
	char sBuffer[PLATFORM_MAX_PATH];
	
	GetPluginFilename(INVALID_HANDLE, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), ".smx", "", false);
	BuildPath(Path_SM, g_sTempMapcycleFile, sizeof(g_sTempMapcycleFile), "data/%s.txt", sBuffer);

	FormatEx(sBuffer, sizeof(sBuffer), "%s", g_sDefMapcycleFile);
	if (!FileExists(sBuffer, false)) {
		PrintToServer("Fatal Error [6]: mapcyclefile \"%s\" doesn't exist!", sBuffer);
		SetFailState("Fatal Error [6]: mapcyclefile \"%s\" doesn't exist!", sBuffer);
	}
	return Plugin_Stop;
}

Action Timer_MapStart(Handle timer) {
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));

	if (!g_bLoadArrayFromFile) {
		ga_hExcludedMaps.PushString(sMap);
		RemoveMapFromArray();
		ArrayToFile();
		MakeTempMapcyle();
	} else {
		ArrayFromFile(sMap);
		g_bLoadArrayFromFile = false;
		RemoveMapFromArray();
	}

	if (ga_hExcludedMaps.Length > 0) {
		ServerCommand("mapcyclefile %s", g_sTempMapcycleFile);
	}

	if (!g_bHooked) {
		g_bHooked = true;
		g_cvDefMapcycleFile.AddChangeHook(OnConVarChanged);
	}
	return Plugin_Stop;
}

void RemoveMapFromArray() {
	if (ga_hExcludedMaps.Length == (g_iRecentMaps + 1)) {
		ga_hExcludedMaps.Erase(0);
	}
	else if (ga_hExcludedMaps.Length > (g_iRecentMaps + 1)) {
		for (int i = 0; i <= (ga_hExcludedMaps.Length - g_iRecentMaps); i++) {
			ga_hExcludedMaps.Erase(0);
		}
	}
}

void ArrayToFile() {
	if (ga_hExcludedMaps.Length < 1) {
		return;
	}

	char sBuffer[PLATFORM_MAX_PATH];

	Format(sBuffer, sizeof(sBuffer), "%s_array.txt", g_sTempMapcycleFile);
	ReplaceStringEx(sBuffer, sizeof(sBuffer), ".txt", "");

	Handle hWrite = OpenFile(sBuffer, "wt", false);
	if (!hWrite) {
		PrintToServer("Error [7]: can't open \"%s\" !", sBuffer);
		return;
	}

	for (int i = 0; i < ga_hExcludedMaps.Length; i++) {
		if (i > g_iRecentMaps) {
			break;
		}
		ga_hExcludedMaps.GetString(i, sBuffer, sizeof(sBuffer));
		TrimString(sBuffer);
		WriteFileLine(hWrite, sBuffer);
	}

	delete hWrite;
}

void ArrayFromFile(const char[] sMap) {
	char sBuffer[PLATFORM_MAX_PATH];

	FormatEx(sBuffer, sizeof(sBuffer), "%s_array.txt", g_sTempMapcycleFile);
	ReplaceStringEx(sBuffer, sizeof(sBuffer), ".txt", "");

	Handle hRead = OpenFile(sBuffer, "rt", false);
	if (hRead) {
		char sBreak[PLATFORM_MAX_PATH];

		while (!IsEndOfFile(hRead)) {
			if (!ReadFileLine(hRead, sBuffer, sizeof(sBuffer))) {
				continue;
			}

			TrimString(sBuffer);

			if (strlen(sBuffer) < 3) {
				continue;
			}

			BreakString(sBuffer, sBreak, sizeof(sBreak));

			if (strcmp(sBreak, sMap, false) == 0) {
				continue;
			}

			ga_hExcludedMaps.PushString(sBuffer);

			if ((ga_hExcludedMaps.Length - 1) >= g_iRecentMaps && g_iRecentMaps > 0) {
				ga_hExcludedMaps.Erase(0);
			}
		}
		delete hRead;
	}

	ga_hExcludedMaps.PushString(sMap);

	if ((ga_hExcludedMaps.Length - 1) >= g_iRecentMaps && g_iRecentMaps > 0) {
		ga_hExcludedMaps.Erase(0);
	}

	ArrayToFile();
	MakeTempMapcyle();
}

public void OnPluginEnd() {
	ServerCommand("mapcyclefile %s", g_sDefMapcycleFile);
}