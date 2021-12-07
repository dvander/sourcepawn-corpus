#pragma semicolon 1
#define PLUGIN_VERSION  "1.0"

public Plugin:myinfo = {
	name = "Nav Cycler",
	author = "MasterOfTheXP",
	description = "Cycles through all maps that don't have a .nav mesh, and generates one for each.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new Handle:aMaps, Handle:hLog;
new numMaps, bool:Cycling, bool:NowGenerating;
new StartTime, MapStartTime;

new Handle:cvarShutDown;
new Handle:cvarKickPlayers;

public OnPluginStart()
{
	RegAdminCmd("nav_generate_all", Command_Cyclenavs, ADMFLAG_ROOT);
	
	CreateConVar("sm_navcycler_version", PLUGIN_VERSION, "Don'ttouchthis.mp3", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarShutDown = CreateConVar("sm_navcycler_shutdownonfinish", "1", "Close/restart srcds.exe when done creating all nav files", _, true, 0.0, true, 1.0);
	cvarKickPlayers = CreateConVar("sm_navcycler_kickplayers", "Generating nav files. Be back soon!", "Kick all players while creating nav meshes? If non-blank, kick players with <value> kick reason.", _, true, 0.0, true, 1.0);
}

public Action:Command_Cyclenavs(client, args)
{
	if (aMaps != INVALID_HANDLE) CloseHandle(aMaps);
	aMaps = CreateArray(PLATFORM_MAX_PATH);
	new Handle:dirMaps = OpenDirectory("./maps"), String:name[PLATFORM_MAX_PATH], FileType:type;
	while (ReadDirEntry(dirMaps, name, sizeof(name), type))
	{
		if (type != FileType_File) continue;
		if (StrContains(name, ".bsp", false) == -1) continue;
		if (StrContains(name, ".ztmp", false) != -1) continue;
		if (StrContains(name, ".bsp.bz2", false) != -1) continue;
		ReplaceString(name, sizeof(name), ".bsp", "", false);
		new String:checkNav[PLATFORM_MAX_PATH];
		Format(checkNav, sizeof(checkNav), "./maps/%s.nav", name);
		if (FileExists(checkNav, true)) continue;
		PushArrayString(aMaps, name);
		numMaps++;
	}
	if (!numMaps)
	{
		ReplyToCommand(client, "All of your maps already have a .nav!");
		return Plugin_Handled;
	}
	new String:kick[192];
	GetConVarString(cvarKickPlayers, kick, sizeof(kick));
	if (strlen(kick))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (!IsClientConnected(i)) continue;
			if (IsClientSourceTV(i)) continue; // Probably unsafe to kick these...
			if (IsClientReplay(i)) continue;
			KickClient(i, kick);
		}
	}
	if (hLog != INVALID_HANDLE) CloseHandle(hLog);
	new String:time[96], String:logPath[PLATFORM_MAX_PATH];
	FormatTime(time, sizeof(time), "Y-%m-%d_%H-%M-%S");
	BuildPath(Path_SM, logPath, sizeof(logPath), "logs/navcycler-%s.txt", time);
	hLog = OpenFile(logPath, "at+");
	Log("Preparing to generate nav files for %i map%s...", numMaps, numMaps != 1 ? "s" : "");
	Cycling = true;
	NowGenerating = true;
	StartTime = GetTime();
	
	SetCommandFlags("nav_generate", GetCommandFlags("nav_generate") & ~FCVAR_CHEAT);
	
	new String:mapName[PLATFORM_MAX_PATH];
	GetArrayString(aMaps, 0, mapName, sizeof(mapName));
	ServerCommand("changelevel %s", mapName);
	return Plugin_Handled;
}

public OnMapStart()
{
	if (!Cycling) return;
	new String:Map[PLATFORM_MAX_PATH];
	GetCurrentMap(Map, sizeof(Map));
	if (!NowGenerating)
	{
		if (GetArraySize(aMaps) == 1)
		{
			Log("Done (took %i seconds)! All maps should now have a nav file!", GetTime()-StartTime);
			CloseHandle(aMaps), CloseHandle(hLog);
			Cycling = false;
			if (GetConVarBool(cvarShutDown))
			{
				Log("Shutting down server...");
				ServerCommand("quit");
			}
			else SetCommandFlags("nav_generate", GetCommandFlags("nav_generate") | FCVAR_CHEAT);
			return;
		}
		RemoveFromArray(aMaps, 0);
		new String:mapName[PLATFORM_MAX_PATH];
		GetArrayString(aMaps, 0, mapName, sizeof(mapName));
		NowGenerating = true;
		ServerCommand("changelevel %s", mapName);
		Log("Nav for %s done (took %i seconds). Changing the map to %s...", Map, GetTime()-MapStartTime, mapName);
		return;
	}
	ServerCommand("nav_generate");
	Log("Generating a nav for %s...", Map);
	NowGenerating = false;
	MapStartTime = GetTime();
}

stock Log(const String:fmt[], any:...)
{
	if (hLog == INVALID_HANDLE) return;
	new String:time[96], String:msg[192];
	FormatTime(time, sizeof(time), "%Y-%m-%d @ %H:%M:%S");
	VFormat(msg, sizeof(msg), fmt, 2);
	PrintToServer(msg);
	WriteFileLine(hLog, "[%s] %s", time, msg);
	FlushFile(hLog);
}