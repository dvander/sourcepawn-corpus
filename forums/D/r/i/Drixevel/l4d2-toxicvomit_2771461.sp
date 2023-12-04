#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[L4D2] Toxic Vomit",
	author = "Drixevel",
	description = "Damages players when vomited on.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

ConVar convar_Enabled;
ConVar convar_Damage;

bool g_AllowDamage[MAXPLAYERS + 1];
int g_Attacker[MAXPLAYERS + 1];

public void OnPluginStart()
{
	convar_Enabled = CreateConVar("sm_toxicvomit_enabled", "1", "Should the plugin be enabled or not?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Damage = CreateConVar("sm_toxicvomit_damage", "1.0", "Damage to do per tick to players who have been vomited on.", FCVAR_NOTIFY, true, 0.0);
	AutoExecConfig();
}

public void Event_OnPlayerIt(Event event, const char[] name, bool dontBroadcast)
{
	//Is the plugin enabled?
	if (!convar_Enabled.BoolValue)
		return;
	
	//Client being vomited on.
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	//Validate the client just in case.
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
	
	//Must come from a boomer.
	if (!event.GetBool("by_boomer"))
		return;
	
	//Must be vomit.
	if (!event.GetBool("exploded"))
		return;
	
	//Allow the damage directly.
	g_AllowDamage[client] = true;
	g_Attacker[client] = attacker;
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		//Validate the clients.
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;
		
		//Easy method to make sure explosions don't cause damage.
		if (!g_AllowDamage[i])
			continue;
		
		//Target isn't boomed anymore.
		if (!IsBoomed(i))
		{
			if (g_AllowDamage[i])
				g_AllowDamage[i] = false;
			
			continue;
		}

		//Do the damage.
		SDKHooks_TakeDamage(i, 0, g_Attacker[i], convar_Damage.FloatValue, DMG_ACID);
	}
}

//Found Here: https://github.com/gkistler/SourcemodStuff/blob/master/l4dcompstats.sp#L46
bool IsBoomed(int client)
{
	return (GetEntPropFloat(client, Prop_Send, "m_vomitStart") + 20.1) > GetGameTime();
}

public void OnClientDisconnect_Post(int client)
{
	//Reset variables on disconnect.
	g_AllowDamage[client] = false;
	g_Attacker[client] = 0;
}