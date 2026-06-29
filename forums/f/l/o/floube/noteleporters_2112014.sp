#pragma semicolon 1

#include <sourcemod>

/****************************************************************
			C O N S T A N T S
*****************************************************************/

#define PLUGIN_NAME     "No Teleporters"
#define PLUGIN_AUTHOR   "floube"
#define PLUGIN_DESC     "Prevents engineers from building teleporters"
#define PLUGIN_VERSION  "1.00"
#define PLUGIN_URL      "http://www.styria-games.eu/"

/****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

/****************************************************************
			P L U G I N   V A R S
*****************************************************************/

new Handle:g_hPluginEnabled;
new Handle:g_hMessage;

/****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/

public OnPluginStart() {
	CreateConVar("sm_notele_version", PLUGIN_VERSION, "No Teleporters Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hPluginEnabled = CreateConVar("sm_notele_enabled", "1", "0 = No Teleporters Plugin disabled; 1 = No Teleporters Plugin enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hMessage = CreateConVar("sm_notele_message", "Teleporters are disabled.", "The message to display to the user, leave empty if for no message (max. 128 chars)", FCVAR_PLUGIN, false, _, false, _);

	if (GetConVarBool(g_hPluginEnabled)) {
		AddCommandListener(CommandListener_Build, "build");

		HookConVarChange(g_hMessage, CvarChange_Message);
	}

	HookConVarChange(g_hPluginEnabled, CvarChange_PluginEnabled);
}

/****************************************************************
			C V A R   C H A N G E   F U N C T I O N S
*****************************************************************/

public CvarChange_PluginEnabled(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	if (StringToFloat(sNewValue) == 0) {
		SetConVarBool(g_hPluginEnabled, false);

		PrintToServer("[No Teleporters] Plugin is now disabled.");
		ServerCommand("sm plugins reload noteleporters");
	} else {
		SetConVarBool(g_hPluginEnabled, true);

		PrintToServer("[No Teleporters] Plugin is now enabled.");
		ServerCommand("sm plugins reload noteleporters");
	}
}

public CvarChange_Message(Handle:hCvar, const String:sOldValue[], const String:sNewValue[]) {
	SetConVarString(g_hMessage, sNewValue);

	PrintToServer("[No Teleporters] Changed message from '%s' to '%s'.", sOldValue, sNewValue);
}

/****************************************************************
			H O O K E D   C O M M A N D S
*****************************************************************/

public Action:CommandListener_Build(iClient, const String:sCommand[], iArgs) {
	if (IsClientInGame(iClient) && !IsFakeClient(iClient)) {
		new String:sBuildingIndex[4];
		GetCmdArg(1, sBuildingIndex, sizeof(sBuildingIndex));
		
		if (StringToInt(sBuildingIndex) == 1) {
			new String:sMessage[128];
			GetConVarString(g_hMessage, sMessage, sizeof(sMessage));

			if (!StrEqual(sMessage, "")) {
				PrintToChat(iClient, sMessage);
			}

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}