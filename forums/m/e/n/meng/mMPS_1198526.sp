#include <sourcemod>

#define NAME "mMPS"
#define VERSION "0.7"

new String:g_sLogsPath[PLATFORM_MAX_PATH];
new String:g_sLogFile[PLATFORM_MAX_PATH];
new Handle:g_hAverageArray;
new UserMsg:g_umVGUIMenu;
new g_iClientCount;
new bool:g_bClientPutInServer[MAXPLAYERS+1];
new g_iEarlyDisconnects;
new bool:g_bScoresDisplayed;
new Handle:g_CVarStart;

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	description = "Provides per map population logs",
	version = VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() {

	CreateConVar("sm_mmps", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarStart = CreateConVar("sm_mmps_start", "45", "Seconds after map start to begin log.", _, true, 1.0, true, 120.0);
	BuildPath(Path_SM, g_sLogsPath, sizeof(g_sLogsPath), "logs/mMPS");
	if (!DirExists(g_sLogsPath))
		CreateDirectory(g_sLogsPath, 0x0265);
	g_hAverageArray = CreateArray();
	g_umVGUIMenu = GetUserMessageId("VGUIMenu");
	HookUserMessage(g_umVGUIMenu, VGUIMenuHook);
}

public OnMapStart() {

	GetALogFile();
	ClearArray(g_hAverageArray);
	g_iClientCount = 0;
	g_iEarlyDisconnects = 0;
	g_bScoresDisplayed = false;
	CreateTimer(GetConVarFloat(g_CVarStart), TimerStartLog, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerStartLog(Handle:timer) {

	LogStats(true, false);
	CreateTimer(15.0, TimerTrackAverage, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:TimerTrackAverage(Handle:timer) {

	PushArrayCell(g_hAverageArray, g_iClientCount);
	return Plugin_Continue;
}

public OnClientConnected(client) { // <~ does not fire for bots!?

	if (!IsFakeClient(client))
		g_iClientCount++;
	g_bClientPutInServer[client] = false;
}

public OnClientPutInServer(client) {

	g_bClientPutInServer[client] = true;
}

public OnClientDisconnect(client) {

	if (!IsFakeClient(client))
		g_iClientCount--;
	if (!g_bScoresDisplayed && !g_bClientPutInServer[client])
		g_iEarlyDisconnects++;
}

public OnMapEnd() {

	if (!g_bScoresDisplayed)
		LogStats(false, true);
}

public Action:VGUIMenuHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) {

	if (!g_bScoresDisplayed) {
		decl String:sBuffer[16];
		BfReadString(bf, sBuffer, 16);
		if (StrEqual(sBuffer, "scores") && (BfReadByte(bf) == 1) && (BfReadByte(bf) == 0)) {
			g_bScoresDisplayed = true;
			LogStats(false, false);
		}
	}
	return Plugin_Continue;
}

GetALogFile() {

	decl String:sDate[32];
	FormatTime(sDate, 32, "%m%d%y");
	Format(g_sLogFile, sizeof(g_sLogFile), "%s/mMPSL%s.log", g_sLogsPath, sDate);
	if (!FileExists(g_sLogFile)) {
		new Handle:hLogFile = OpenFile(g_sLogFile, "a");
		if (hLogFile != INVALID_HANDLE) {
			WriteFileLine(hLogFile, " ");
			FormatTime(sDate, 32, "%A %B %d");
			WriteFileLine(hLogFile, "[mMPS] Map Population Stats for %s", sDate);
			WriteFileLine(hLogFile, " ");
			WriteFileLine(hLogFile, "------");
		}
		else
			LogError("Houston, we have a problem.");
		CloseHandle(hLogFile);
	}
}

LogStats(bool:mapstart, bool:earlymapchange) {

	new Handle:hLogFile = OpenFile(g_sLogFile, "a");
	if (hLogFile != INVALID_HANDLE) {
		decl String:sBuffer[64];
		if (mapstart) {
			GetCurrentMap(sBuffer, 64);
			WriteFileLine(hLogFile, " ");
			WriteFileLine(hLogFile, "***** %s *****", sBuffer);
			FormatTime(sBuffer, 64, "%I:%M%p");
			WriteFileLine(hLogFile, "Start = %i [%s]", g_iClientCount, sBuffer);
		}
		else {
			FormatTime(sBuffer, 64, "%I:%M%p");
			if (earlymapchange) {
				new iLastClientCount = GetLastClientCount();
				if (iLastClientCount == -1)
					WriteFileLine(hLogFile, "No stats recorded. *Early map change");
				else
					WriteFileLine(hLogFile, "End = %i [%s] *Early map change", iLastClientCount, sBuffer);
			}
			else
				WriteFileLine(hLogFile, "End = %i [%s]", g_iClientCount, sBuffer);
			WriteFileLine(hLogFile, "Average = %i", GetClientCountAverage());
			WriteFileLine(hLogFile, "Early Disconnects = %i", g_iEarlyDisconnects);
		}
	}
	else
		LogError("Houston, we have a problem.");
	CloseHandle(hLogFile);
}

GetClientCountAverage() {

	new iTotal;
	new iArraySize = GetArraySize(g_hAverageArray);
	for (new i = 0; i < iArraySize; i++)
		iTotal += GetArrayCell(g_hAverageArray, i);
	return RoundToNearest(float(iTotal)/float(iArraySize));
}

GetLastClientCount() {

	new iArraySize = GetArraySize(g_hAverageArray);
	if (iArraySize > 0)
		return GetArrayCell(g_hAverageArray, iArraySize-1);
	return -1;
}