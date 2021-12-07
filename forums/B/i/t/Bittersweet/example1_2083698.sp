#include <sourcemod>
#include <updater>
#include <autoexecconfig>
#include <copycfg>

#define UPDATE_URL "http://bbgcss.servegame.com/updater/example.txt"

new const String:PLUGIN_NAME[]= "example"
new const String:PLUGIN_AUTHOR[]= "Bittersweet"
new const String:PLUGIN_DESCRIPTION[]= "An example/test plugin using copycfg concept.  To use Copycfg, you must include copycfg.inc and use Copycfg with the correct opcode to handle creating/loading .cfg files and cvars."
new const String:PLUGIN_VERSION[]= "1.0.0"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}
public OnPluginStart()
{
	PrintToServer("[%s %s] Loaded", PLUGIN_NAME, PLUGIN_VERSION)
	CreateConVar("example_version", PLUGIN_VERSION, "example plugin used for testing copycfg plugin", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	//Always call copycfg with opcode 0 before calling any other opcodes, or you get no backup file for the previous version
	Copycfg(0, "/cfg/sourcemod/example.cfg")
	Copycfg(1, "/cfg/sourcemod/example.cfg", 0, "example_cvar1", "0", "Boolean test cvar.")
	Copycfg(1, "/cfg/sourcemod/example.cfg", 1, "example_cvar2", "25", "Integer test cvar.", FCVAR_PLUGIN, true, 0.0, true, 100.0)
	Copycfg(1, "/cfg/sourcemod/example.cfg", 2, "example_cvar3", "2.0", "Float test cvar.", FCVAR_PLUGIN, true, 0.0, true, 10.0)
	//Copycfg(1, "/cfg/sourcemod/example.cfg", 3, "example_cvar4", "test", "String test cvar.", FCVAR_PLUGIN)
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL)
	}
}
public OnConfigsExecuted()
{
	//Forcing an update would be optional
	new UpdateTriggered = Updater_ForceUpdate()
	if (UpdateTriggered)
	{
		PrintToServer("[%s %s] - Checking for update(s)...", PLUGIN_NAME, PLUGIN_VERSION)
	}
	else
	{
		PrintToServer("[%s %s] - Updater DID NOT trigger an update...", PLUGIN_NAME, PLUGIN_VERSION)
	}
}
public Action:Updater_OnPluginChecking()
{
	PrintToServer("[%s %s] - Contacting update server...", PLUGIN_NAME, PLUGIN_VERSION)
	return Plugin_Continue
}
public Action:Updater_OnPluginDownloading()
{
	PrintToServer("[%s %s] - Downloading update(s)...", PLUGIN_NAME, PLUGIN_VERSION)
	return Plugin_Continue
}
public Updater_OnPluginUpdated()
{
	//Only reload the plugin if: the user has blocked restarting the server, or a restart was already scheduled
	if (Copycfg(2) == GetMyHandle()) ReloadPlugin(INVALID_HANDLE)
}
public OnMapStart()
{
	PrintToServer("[%s %s] - Map start", PLUGIN_NAME, PLUGIN_VERSION)
	if (GetConVarBool(FindConVar("copycfg_restart_scheduled")))
	{
		PrintToServer("[%s %s] - Server should restart", PLUGIN_NAME, PLUGIN_VERSION)
		ServerCommand("_restart")
	}
	else
	{
		PrintToServer("[%s %s] - No restart scheduled", PLUGIN_NAME, PLUGIN_VERSION)
	}
}
//End of code