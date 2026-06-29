#include <sourcemod>
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "Why the fuck they do this? WHY?"

public Plugin:myinfo =
{
	name = "＃Lua Resupply Delay System ._.",
	author = "D.Freddo",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "http://steam.lua.kr"
}

new Handle:c_Version;
new Handle:c_Enabled;
new Handle:c_DelayINS;
new Handle:c_DelaySEC;
new bool:g_Enabled = true;
new Float:g_DelayINS = 10.0;
new Float:g_DelaySEC = 10.0;
new Float:ResupplyCheck[MAXPLAYERS+1];

public OnPluginStart()
{
	c_Version = CreateConVar("Lua_Resupply_Delay_System", PLUGIN_VERSION, PLUGIN_DESCRIPTION, FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	c_Enabled = CreateConVar("sm_resupply_enabled", "1", "Enable da plugin ._.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	c_DelayINS = CreateConVar("sm_resupply_delay_ins", "10.0", "Delay time of resupply for Insurgent Team", FCVAR_PLUGIN, true, 0.0);
	c_DelaySEC = CreateConVar("sm_resupply_delay_sec", "10.0", "Delay time of resupply for Security Team", FCVAR_PLUGIN, true, 0.0);
	AutoExecConfig();

	SetConVarString(c_Version, PLUGIN_VERSION, false, false);
	HookConVarChange(c_Version, OnConvarChange);
	HookConVarChange(c_Enabled, OnConvarChange);
	HookConVarChange(c_DelayINS, OnConvarChange);
	HookConVarChange(c_DelaySEC, OnConvarChange);
	RegConsoleCmd("inventory_resupply", PlayerResupplyCheck);
}

public OnConvarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == c_Enabled)
		g_Enabled = bool:StringToInt(newvalue);
	else if(cvar == c_DelayINS)
		g_DelayINS = StringToFloat(newvalue);
	else if(cvar == c_DelaySEC)
		g_DelaySEC = StringToFloat(newvalue);
	else if(cvar == c_Version)
		SetConVarString(c_Version, PLUGIN_VERSION, false, false);
}

public OnClientPutInServer(client){
	ResupplyCheck[client] = 0.0;
}

public Action:PlayerResupplyCheck(client, args)
{
	if (!g_Enabled || client <= 0 || IsFakeClient(client) || GetClientTeam(client) <= 1 || !IsPlayerAlive(client)) return Plugin_Continue;
	new Float:Time = GetGameTime();
	new Team = GetClientTeam(client);
	new Float:Delay = (Team == 2 ? g_DelaySEC : g_DelayINS);
	if (Time-ResupplyCheck[client] < Delay){
		PrintToChat(client, "\x03You cannot resupply now, try again in \x01%0.1f\x03sec ._.", Delay-(Time-ResupplyCheck[client]));
		return Plugin_Handled;
	}
	ResupplyCheck[client] = Time;
	return Plugin_Continue;
}