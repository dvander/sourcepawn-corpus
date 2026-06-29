// Force strict semicolon mode
#pragma semicolon 1
#include <sourcemod>
#include <halflife>
#include <string>
#include <sdktools_functions>

#define PLUGIN_VERSION	"1.0"

int thirdparty_count = 0;
Handle g_hTimer_CheckEmpty;

public Plugin myinfo =
{
	name = "[L4D2] Server Watchdog",
	author = "Rikka0w0",
	description = "Switch the map to offical maps when the server has no active player but running 3rd party map",
	version = PLUGIN_VERSION,
	url = "..."
}

Timer_CheckEmpty_Kill() {
	if (g_hTimer_CheckEmpty != INVALID_HANDLE) {
		KillTimer(g_hTimer_CheckEmpty);
		g_hTimer_CheckEmpty = INVALID_HANDLE;
	}
}

public OnMapStart() {
	Timer_CheckEmpty_Kill();
	g_hTimer_CheckEmpty = CreateTimer(5.0, Timer_OnFeedDog, INVALID_HANDLE, TIMER_REPEAT);
}

public OnMapEnd() {
	Timer_CheckEmpty_Kill();
}

public Action Timer_OnFeedDog(Handle timer, any param) 
{
	bool isOfficialMap = true;
	char mapName[256];
	GetCurrentMap(mapName, 256);
	if (mapName[0] != 'c')
		isOfficialMap = false;
	if (!IsCharNumeric(mapName[1]))
		isOfficialMap = false;


	bool hasHumanPlayer = false;
	for (new i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i))
			continue;

		if (!IsFakeClient(i))
			hasHumanPlayer = true;
	}

	if (!hasHumanPlayer && !isOfficialMap) {
		thirdparty_count++;
		if (thirdparty_count > 12) {
			thirdparty_count = 0;
			
			Timer_CheckEmpty_Kill();
			ForceChangeLevel("c1m1_hotel", "Server idle + running third-party map, ready to switch to official maps");
			LogMessage("Server idle + running third-party map, ready to switch to official maps");
			return Plugin_Stop;
		}
	} else {
		thirdparty_count = 0;
	}
	
	return Plugin_Handled;
}