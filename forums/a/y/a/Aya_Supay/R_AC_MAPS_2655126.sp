
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY

/*ConVars*/

ConVar R_Def_Maps;
ConVar hR_ACMDelay;
ConVar hR_ACMHint;

/*bools , float , Handle */
Handle hRACMKvS;
bool R_ACMHint;
bool g_bMap = false;
float R_ACMDelay;

/*char */

char RACMKvS[128];
char R_Next_Maps[64];
char R_Next_Name[64];

public Plugin myinfo =
{
	name = "L4D automatic map change 1.0-by night",
	description = "L4D auto change Maps",
	author = "Ryanx",
	version = "L4D automatic map change 1.0-by night",
	url = ""
};

public void OnPluginStart()
{
	LoadTranslations("R_ACM_MAPS.phrases");
	
	CreateConVar("R_ACM_Version", "L4D auto change Maps", "L4D auto change Maps", CVAR_FLAGS);
	R_Def_Maps = CreateConVar("R_ACM_Def_Map", "l4d_river01_docks", "Maps that are changed by default when not listed.", CVAR_FLAGS);
	hR_ACMHint = CreateConVar("R_ACM_Hint", "1", "Whether to announce when auto-commuting [0=off|1=on]", CVAR_FLAGS);
	hR_ACMDelay = CreateConVar("R_ACM_delay", "30.0", "Automatic change delay for a few seconds (PS: Too long game retires to main menu). Default 5.0 / 300.0", CVAR_FLAGS);

	R_ACMHint = hR_ACMHint.BoolValue;
	R_ACMDelay = hR_ACMDelay.FloatValue;
	
	HookEvent("finale_win", RACMEvent_FinaleWin);
	HookEvent("player_activate", RACMEvent_activate);
	
	hRACMKvS = CreateKeyValues("R_Auto_Change_Maps");
	
//	AutoExecConfig(true, "R_AC_MAPS", "sourcemod");
}

public void OnMapStart()
{
	R_ACMHint = hR_ACMHint.BoolValue;
	R_ACMDelay = hR_ACMDelay.FloatValue;
}

public void RACMEvent_activate(Event event, char[] name, bool dontBroadcast)
{
	g_bMap = IsMap();
	
	if (R_ACMHint)
	{
		int UserId = event.GetInt("userid");
		if (UserId != 0) {
			int client = GetClientOfUserId(UserId);
			if (client != 0 && !IsFakeClient(client)) {
			    if (g_bMap) {
				    RACMLoad();
				    if (strcmp(R_Next_Maps, "none", true)) {
				        CreateTimer(5.0, RACSHints, client);
				    }
				}
			}
		}
	}
}

public Action RACSHints(Handle timer, any client)
{
	//CPrintToChat(client, "{cyan}[ACM] {green}Es el ultimo capitulo");
	CPrintToChat(client, "%t", "change_map_one");
	//CPrintToChat(client, "{cyan}[ACM] {green}La proxima batalla: {orange}%s", R_Next_Name);
	CPrintToChat(client, "%t {orange}%s", "change_map_two", R_Next_Name);
	return Plugin_Continue;
}

public void RACMEvent_FinaleWin(Event event, char[] name, bool dontBroadcast)
{
	RACMLoad();
	if (!strcmp(R_Next_Maps, "none", true))
	{
		GetConVarString(R_Def_Maps, R_Next_Maps, 64);
		GetConVarString(R_Def_Maps, R_Next_Name, 64);
	}
	if (R_ACMHint)
	{
		char ACMHdelayS[12];
		FloatToString(R_ACMDelay, ACMHdelayS, 12);
		int ACMHdelayT = StringToInt(ACMHdelayS, 10);
		//CPrintToChatAll("{cyan}[ACM] {green}Completada esta batalla");
		CPrintToChatAll("%t", "change_map_three");
		//CPrintToChatAll("{cyan}[ACM] {green} cambio automático del mapa en %d segundos.", ACMHdelayT);
		CPrintToChatAll("%t {green}%d sec.", "change_map_four", ACMHdelayT);
	}
	CreateTimer(R_ACMDelay - 3.0, RACMaps);
//	return Plugin_Continue;
}

void CACMKV(Handle kvhandle)
{
	KvRewind(kvhandle);
	if (KvGotoFirstSubKey(kvhandle, true))
	{
		do {
			KvDeleteThis(kvhandle);
			KvRewind(kvhandle);
		} while (KvGotoFirstSubKey(kvhandle, true));
		KvRewind(kvhandle);
	}
}

public Action RACMaps(Handle timer)
{
	if (R_ACMHint)
	{
		//CPrintToChatAll("{cyan}[ACM] {green}La proxima batalla: {orange}%s", R_Next_Name);
		CPrintToChatAll("%t {orange}%s", "change_map_five", R_Next_Name);
		CPrintToChatAll("{orange}%s", R_Next_Maps);
	}
	CreateTimer(3.0, RACMapsN);
	return Plugin_Continue;
}

public Action RACMapsN(Handle timer)
{
	ServerCommand("changelevel %s", R_Next_Maps);
	return Plugin_Continue;
}

void RACMLoad()
{
	CACMKV(hRACMKvS);
	BuildPath(Path_SM, RACMKvS, 128, "data/R_AC_MAPS.txt");
	if (!FileToKeyValues(hRACMKvS, RACMKvS))
	{
		CPrintToChatAll("{cyan}[!Error!] {green}Unable to read [data/R_AC_MAPS.txt]");
	}
	char nrcurrent_map[64];
	GetCurrentMap(nrcurrent_map, 64);
	KvRewind(hRACMKvS);
	if (KvJumpToKey(hRACMKvS, nrcurrent_map, false))
	{
		KvGetString(hRACMKvS, "R_ACM_Next_Maps", R_Next_Maps, 64, "none");
		KvGetString(hRACMKvS, "R_ACM_Next_Name", R_Next_Name, 64, "none");
	}
	KvRewind(hRACMKvS);
}

bool IsMap()
{
	char sMap[100];
	GetCurrentMap(sMap, sizeof(sMap));
	
	if (StrEqual(sMap, "l4d_hospital05_rooftop", false) ||
		StrEqual(sMap, "l4d_garage02_lots", false) ||
		StrEqual(sMap, "l4d_airport05_runway", false) ||
		StrEqual(sMap, "l4d_smalltown05_houseboat", false) ||
		StrEqual(sMap, "l4d_farm05_cornfield", false) ||
		StrEqual(sMap, "l4d_river03_port", false)) {
	
		return true;
	}
	return false;
}

/**
*   @note Used for in-line string translation.
*
*   @param  iClient     Client Index, translation is apllied to.
*   @param  format      String formatting rules. By default, you should pass at least "%t" specifier.
*   @param  ...            Variable number of format parameters.
*   @return char[192]    Resulting string. Note: output buffer is hardly limited.
*/
stock char[] Translate(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    return buffer;
}

/**
*   @note Prints a message to a specific client in the chat area. Supports named colors in translation file.
*
*   @param  iClient     Client Index.
*   @param  format        Formatting rules.
*   @param  ...            Variable number of format parameters.
*   @no return
*/
stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

/**
*   @note Prints a message to all clients in the chat area. Supports named colors in translation file.
*
*   @param  format        Formatting rules.
*   @param  ...            Variable number of format parameters.
*   @no return
*/
stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

/**
*   @note Converts named color to control character. Used internally by string translation functions.
*
*   @param  char[]        Input/Output string for convertion.
*   @param  maxLen        Maximum length of string buffer (includes NULL terminator).
*   @no return
*/
stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}