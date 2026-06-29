#include <sourcemod>
#include "versioningCvar.sp"

/* Make the admin menu plugin optional */
#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#define VERSION	"1.1.2"
#define UPDATE_URL    "http://gaming.comhix.de/sm/updater.php/sm/info.txt"

/* CVars */
#define VERSION_CVAR	"sm_mvmsm_version"
#define ENABLE			"sm_mvmsm_enabled"

/* Configs */
#define EMPTY_CFG		"tf_mvm_servermode_empty.cfg"
#define JOINED_CFG		"tf_mvm_servermode_joined.cfg"

new Handle:plugin_enabled = INVALID_HANDLE;
new bool:lobbyMode=true;
new bool:mapStarted=false;

/**
 * Plugin public information.
 */
public Plugin:myinfo =
{
	name = "[TF2] MvM Servermode AutoToggler",
	author = "NoZomIBK",
	description = "Just toggles tf_mm_servermode automatically",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1870458"
};

public OnPluginStart()
{
	initVersion(VERSION,VERSION_CVAR);
	initCvars();

	OnMapStart();

	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryAdded(const String:name[])
{

	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}

initCvars() {
	plugin_enabled = CreateConVar( ENABLE, "1", "Enables plugin", 0, true, 0.0, true, 1.0 );
}
public Updater_OnPluginUpdated() {
	ReloadPlugin();
}

public OnClientPutInServer(client) {
	LogMessage("Connected");
	setServerModeTo(false);
}

public OnClientDisconnect_Post(client) {
	LogMessage("Disconnected");
	setServerModeTo(true);
}

public OnMapStart() {
	lobbyMode=GetClientCount() == 0;
	mapStarted=true;
	setServerMode();
}

public OnMapEnd() {
	mapStarted=false;
}

setServerModeTo(bool:nowLobby) {
	if(GetConVarBool(plugin_enabled)) {
		if(nowLobby != lobbyMode) {
			setServerMode();
		}
	}
	else{
		LogMessage("(Dis)connect ignored, plugin disabled");
	}
}

setServerMode(){
	if(!mapStarted){
		LogMessage("(Dis)connect ignored, map not started");
		return;
	}
	new bool:isEmpty = GetClientCount() == 0;
	LogMessage("isEmpty: %b lobbyMode: %b",isEmpty,lobbyMode);
	if(isEmpty && !lobbyMode) {
//		ServerCommand("sm_cvar tf_mm_servermode %d",2);
		LogMessage("exec %s",EMPTY_CFG);
		ServerCommand("exec %s",EMPTY_CFG);
		lobbyMode = true;
	}
	else if (!isEmpty && lobbyMode) {
//		ServerCommand("sm_cvar tf_mm_servermode %d",1);
		LogMessage("exec %s",JOINED_CFG);
		ServerCommand("exec %s",JOINED_CFG);
		lobbyMode = false;
	}
}
