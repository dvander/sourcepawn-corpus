#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hSwitchScout = INVALID_HANDLE;
new Handle:g_hSwitchAwp = INVALID_HANDLE;

new bool:g_bEnabled, bool:g_bSwitchScout, bool:g_bSwitchAwp;
new String:g_sWeapon[MAXPLAYERS + 1][32];

public Plugin:myinfo =
{
	name = "CSS Quick Fire",
	author = "Twisted|Panda",
	description = "Provides an automatic \"quick switch\" feature, allowing weapons to continue firing.",
	version = PLUGIN_VERSION,
	url = "http://ominousgaming.com/"
}

public OnPluginStart()
{
	CreateConVar("css_quickswitch_version", PLUGIN_VERSION, "CSS Quick Switch: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("css_quickswitch_enabled", "1", "Enables/disables all functionality of the plugin. (0 = Disabled, 1 = Enabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnSettingsChange);
	g_hSwitchScout = CreateConVar("css_quickswitch_scout", "1", "Enables/disable auto quick switching for the scout.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSwitchScout, OnSettingsChange);
	g_hSwitchAwp = CreateConVar("css_quickswitch_awp", "1", "Enables/disable auto quick switching for the awp.", FCVAR_NONE, true, 0.0, true, 1.0);
	HookConVarChange(g_hSwitchAwp, OnSettingsChange);

	HookEvent("weapon_fire", Event_OnWeaponFire, EventHookMode_Post);
}

public OnMapStart()
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	if(g_bEnabled)
	{		
		g_bSwitchScout = GetConVarBool(g_hSwitchScout);
		g_bSwitchAwp = GetConVarBool(g_hSwitchAwp);
	}
}

public OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar == g_hEnabled)
		g_bEnabled = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSwitchScout)
		g_bSwitchScout = StringToInt(newvalue) ? true : false;
	else if(cvar == g_hSwitchAwp)
		g_bSwitchAwp = StringToInt(newvalue) ? true : false;
}

public Action:Event_OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		if(!client || !IsClientInGame(client))
			return Plugin_Continue;

		GetEventString(event, "weapon", g_sWeapon[client], sizeof(g_sWeapon[]));
		if((g_bSwitchScout && StrEqual(g_sWeapon[client], "scout")) || (g_bSwitchAwp && StrEqual(g_sWeapon[client], "awp")))
			CreateTimer(0.1, Timer_Switch, userid);
	}
	
	return Plugin_Continue;
}

public Action:Timer_Switch(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(client && IsClientInGame(client))
	{
		FakeClientCommandEx(client, "use weapon_knife");
		FakeClientCommandEx(client, "use weapon_%s", g_sWeapon[client]);
	}
}