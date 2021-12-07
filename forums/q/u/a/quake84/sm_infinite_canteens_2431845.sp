#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "quake1337"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

//---Console Variables---//
public ConVar g_cInfiniteCanteensEnabled;
public ConVar g_cInfiniteCanteensVersion;
public ConVar g_cInfiniteCanteensRestrictAdmin;
public ConVar g_cInfiniteCanteensDefaultState;
public ConVar g_cInfiniteCanteensAllowToggling;
public ConVar g_cInfiniteCanteensAdvertise;
//---Plugin Variables---//
public bool g_bInfiniteCanteensEnabled;
public bool g_bInfiniteCanteensRestrictAdmin;
public bool g_bInfiniteCanteensUserState[34];
public bool g_bInfiniteCanteensDefaultState;
public bool g_bInfiniteCanteensAllowToggling;
public float g_flInfiniteCanteensAdvertise;
public Handle RefillTimer;
public Handle AdvertisementTimer;
public Plugin myinfo = 
{
	name = "[TF2] Infinite Canteens",
	author = PLUGIN_AUTHOR,
	description = "Allows players to have infinite canteen charges.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/bartico6"
};

public void OnPluginStart()
{
	RefillTimer = CreateTimer(1.0, Timer_RefillCanteens, _, TIMER_REPEAT);
	RegConsoleCmd("sm_infinitecanteens", Cmd_ToggleIC);
	RegConsoleCmd("sm_ic", Cmd_ToggleIC);
	g_cInfiniteCanteensEnabled = CreateConVar("sm_infinitecanteens_enabled", "1", "Toggles the plugin's functionality.", 0, true, 0.0, true, 1.0);
	g_cInfiniteCanteensVersion = CreateConVar("sm_infinitecanteens_version", PLUGIN_VERSION, "Infinite Canteens version", FCVAR_NOTIFY);
	g_cInfiniteCanteensRestrictAdmin = CreateConVar("sm_infinitecanteens_admin", "0", "Does the plugin require admin priviledges to use?", 0, true, 0.0, true, 1.0);
	g_cInfiniteCanteensAllowToggling = CreateConVar("sm_infinitecanteens_togglable", "1", "Allow the user to disable functionality for themselves?", 0, true, 0.0, true, 1.0);
	g_cInfiniteCanteensDefaultState = CreateConVar("sm_infinitecanteens_default", "1", "Should Infinite Canteens be enabled for new users by default?", 0, true, 0.0, true, 1.0);
	g_cInfiniteCanteensAdvertise = CreateConVar("sm_infinitecanteens_advertise", "120", "Should Infinite Canteens advertise its existence on the server?", 0, true, 0.0, false);
	SetDefaultValues();
	AdvertisementTimer = CreateTimer(g_flInfiniteCanteensAdvertise, Timer_Advertise, _, TIMER_REPEAT);
	HookConVarChange(g_cInfiniteCanteensEnabled, ConVarHook);
	HookConVarChange(g_cInfiniteCanteensVersion, ConVarHook);
	HookConVarChange(g_cInfiniteCanteensRestrictAdmin, ConVarHook);
	HookConVarChange(g_cInfiniteCanteensAllowToggling, ConVarHook);
	HookConVarChange(g_cInfiniteCanteensDefaultState, ConVarHook);
	HookConVarChange(g_cInfiniteCanteensAdvertise, ConVarHook);
}
public void SetDefaultValues()
{
	g_bInfiniteCanteensEnabled = g_cInfiniteCanteensEnabled.BoolValue;
	g_bInfiniteCanteensRestrictAdmin = g_cInfiniteCanteensRestrictAdmin.BoolValue;
	g_bInfiniteCanteensAllowToggling = g_cInfiniteCanteensAllowToggling.BoolValue;
	g_bInfiniteCanteensDefaultState = g_cInfiniteCanteensDefaultState.BoolValue;
	g_flInfiniteCanteensAdvertise = g_cInfiniteCanteensAdvertise.FloatValue;
}
public void ConVarHook(ConVar cvar, char[] oldval, char[] newval)
{
	if(cvar == g_cInfiniteCanteensEnabled)
	{
		g_bInfiniteCanteensEnabled = cvar.BoolValue;
		CPrintToChatAll("{goldenrod}[InfiniteCanteens] {selfmade}The Infinite Canteens plugin is now %s", g_bInfiniteCanteensEnabled ? "{lime}enabled" : "{red}disabled");
		if(g_bInfiniteCanteensEnabled)
			RefillTimer = CreateTimer(1.0, Timer_RefillCanteens, _, TIMER_REPEAT);
		else
			KillTimer(RefillTimer);
	}
	if(cvar == g_cInfiniteCanteensRestrictAdmin)
	{
		g_bInfiniteCanteensRestrictAdmin = cvar.BoolValue;
		CPrintToChatAll("{goldenrod}[InfiniteCanteens] {selfmade}Infinite Canteens %s {selfmade}special priviledges to be used.", g_bInfiniteCanteensRestrictAdmin ? "{red}now require" : "{lime}no longer require");
		ReinitializeClients();
	}
	if(cvar == g_cInfiniteCanteensDefaultState)
	{
		g_bInfiniteCanteensDefaultState = cvar.BoolValue;
		CPrintToChatAll("{goldenrod}[InfiniteCanteens] {selfmade}Infinite Canteens are now %s by default.", g_bInfiniteCanteensDefaultState ? "{lime}enabled" : "{red}disabled");
		ReinitializeClients();
	}
	if(cvar == g_cInfiniteCanteensAllowToggling)
	{
		g_bInfiniteCanteensAllowToggling = cvar.BoolValue;
		CPrintToChatAll("{goldenrod}[InfiniteCanteens] {selfmade}Infinite Canteens' state %s {selfmade}controlled by players.", g_bInfiniteCanteensAllowToggling ? "{lime}can now be" : "{red}can no longer be");
	}
	if(cvar == g_cInfiniteCanteensVersion)
	{
		g_cInfiniteCanteensVersion.SetString(PLUGIN_VERSION);
	}
	if(cvar == g_cInfiniteCanteensAdvertise)
	{
		g_flInfiniteCanteensAdvertise = cvar.FloatValue;
		KillTimer(AdvertisementTimer);
		if(g_flInfiniteCanteensAdvertise > 0.0)
			CreateTimer(g_flInfiniteCanteensAdvertise, Timer_Advertise, _, TIMER_REPEAT);
	}
}
public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int maxlen)
{
	ReinitializeClients();
}
public void ReinitializeClients()
{
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		if(ValidateClientID(i) && (!g_bInfiniteCanteensRestrictAdmin || GetUserAdmin(i) != INVALID_ADMIN_ID))
		{
			UserInit(i);
		}
	}
}
public void OnClientConnected(int client)
{
	UserCleanup(client);
}
public void OnClientDisconnect(int client)
{
	UserCleanup(client);
}
public void OnClientPostAdminCheck(int client)
{
	UserInit(client);
}
public void UserInit(int client)
{
	if(g_bInfiniteCanteensEnabled)
	{
		if(g_bInfiniteCanteensRestrictAdmin)
		{
			if (CheckCommandAccess(client, "sm_infinitecanteens", ADMFLAG_GENERIC))
				g_bInfiniteCanteensUserState[client] = g_bInfiniteCanteensDefaultState;
			else
				g_bInfiniteCanteensUserState[client] = false;
		} else
			g_bInfiniteCanteensUserState[client] = g_bInfiniteCanteensDefaultState;
	}
}
public void UserCleanup(int client)
{
	g_bInfiniteCanteensUserState[client] = false;
}
public Action Cmd_ToggleIC(int client, int args)
{
	if(g_bInfiniteCanteensEnabled)
	{
		if(g_bInfiniteCanteensAllowToggling)
		{
			if(g_bInfiniteCanteensRestrictAdmin && !CheckCommandAccess(client, "sm_infinitecanteens", ADMFLAG_GENERIC, true))
			{
				CReplyToCommand(client, "{goldenrod}[InfiniteCanteens] {crimson}You do not have sufficient access to use this command!");
				return Plugin_Handled;
			} else {
				g_bInfiniteCanteensUserState[client] = !g_bInfiniteCanteensUserState[client];
				CReplyToCommand(client, "{goldenrod}[InfiniteCanteens] {selfmade}Infinite Canteens are now %s", g_bInfiniteCanteensUserState[client] ? "{lime}enabled" : "{red}disabled");
			}
		} else
			CReplyToCommand(client, "{goldenrod}[InfiniteCanteens] {selfmade}Infinite Canteens cannot be toggled per-user due to the server's settings. Please contact the server administrators if you believe that this is an error.");
	} else
		CReplyToCommand(client, "{goldenrod}[InfiniteCanteens] {crimson}The plugin is not enabled. Please contact the server administrators if you believe that this is an error.");
	return Plugin_Handled;
}
public Action Timer_Advertise(Handle hTimer, any data)
{
	for (int i = 1; i <= GetMaxClients(); i++)
		if(ValidateClientID(i))
		{
			CPrintToChat(i, "{selfmade}This server is running {goldenrod}Infinite Canteens{selfmade} version {purple}%s{selfmade}. The plugin is currently %s {selfmade}for you.", PLUGIN_VERSION, g_bInfiniteCanteensUserState[i] ? "{lime}enabled" : "{red}disabled");
			if(g_bInfiniteCanteensAllowToggling)
				CPrintToChat(i, "{selfmade}To %s {selfmade}the plugin for yourself, type {red}/ic{selfmade} or {red}/infinitecanteens.", g_bInfiniteCanteensUserState[i] ? "{red}disable" : "{lime}enable");
		}
}
public Action Timer_RefillCanteens(Handle hTimer, any data)
{
	if(!g_bInfiniteCanteensEnabled)
		return Plugin_Stop;
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		if(ValidateClientID(i) && IsPlayerAlive(i) && g_bInfiniteCanteensUserState[i])
		{
			int canteen = FindUserCanteen(i);
			if(canteen != -1)
			{
				if(GetEntProp(canteen, Prop_Send, "m_usNumCharges") > 0)
					SetEntProp(canteen, Prop_Send, "m_usNumCharges", 5);
			}
		}
	}
	return Plugin_Continue;
}
stock bool ValidateClientID(int id)
{
	return (id > 0 && id <= GetMaxClients() && IsClientInGame(id));
}
stock int FindUserCanteen(int client)
{
	if(ValidateClientID(client) && IsPlayerAlive(client))
	{
		int i = -1;
		while ((i = FindEntityByClassname(i, "tf_powerup_bottle")) != -1)
		{
			if (IsValidEntity(i) && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(i, Prop_Send, "m_bDisguiseWearable"))
			{
				return i;
			}
		}
		return i;
	} else
		return -1;
}
stock int GetOnlinePlayers()
{
	int online = 0;
	for (int i = 1; i <= GetMaxClients(); i++)
	{
		if(ValidateClientID(i))
			online++;
			
	}
	return online;
}