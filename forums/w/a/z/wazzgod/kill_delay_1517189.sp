/* 1.0 	-- July_23_2011 Official release
 * 1.1 	-- July_23_2011 Touched up code
 * */

 // chat green = 		/x04
// 		lightgreen = 	/x03
//		white =			/x01
 
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

// cvars
new Handle:g_pluginEnabled= INVALID_HANDLE;
new Handle:g_killdelay_time= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Kill Delay",
	author = "Jon - Ehh",
	description = "When a player types kill in console it will delay x then suicide them",
	version = PLUGIN_VERSION,
	url = "http://wazzgame.com/"
};


public OnPluginStart()
{
	RegConsoleCmd("kill", command_kill);
	CreateConVar("sm_killdelay_version", PLUGIN_VERSION, "Kill Delay Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_pluginEnabled= CreateConVar("sm_killdelay_enabled", "1", "Is Kill Delay Enabled? 1/0");
	g_killdelay_time= CreateConVar("sm_killdelay_time", "5", "How many seconds to wait before suicide the client");
}


 
public Action:command_kill(client, args)
{
	if (GetConVarBool(g_pluginEnabled) && IsPlayerAlive(client) && IsClientInGame(client))
	{
		CreateTimer(GetConVarFloat(g_killdelay_time), Suicide_Player, client)
	}
	return Plugin_Handled;
}
 
public Action:Suicide_Player(Handle:timer, any:client)
{
	PrintToConsole(client, "You have suicided!")
	PrintCenterText(client,"You have suicided!")
	PrintToChat(client, "\x04[Kill Delay] : \x03You have suicided!");
	ForcePlayerSuicide(client);
}


