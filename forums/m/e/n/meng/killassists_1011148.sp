#include <sourcemod>

#define PLUGIN_VERSION "0.7"

public Plugin:myinfo = 
{
	name = "killassists",
	author = "meng",
	version = PLUGIN_VERSION,
	description = "gives extra kill for a kill assist",
	url = ""
};

new Handle:g_damneed;
new g_damage[MAXPLAYERS+1][MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sm_killassists_version", PLUGIN_VERSION, "killassists version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_damneed = CreateConVar("sm_killassists_damage", "90", "Damage needed to count as a kill assist.");

	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("player_death", EventPlayerDeath);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
		for (new d = 1; d <= MaxClients; d++)
			g_damage[i][d] = 0;
}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	if (attacker && GetClientTeam(attacker) != GetClientTeam(victim))
	{
		new damage = GetEventInt(event,"dmg_health");
		g_damage[attacker][victim] += damage;
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event,"userid"));
	new killer = GetClientOfUserId(GetEventInt(event,"attacker"));
	if (killer)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i != killer && IsClientInGame(i) && g_damage[i][victim] >= GetConVarInt(g_damneed))
			{
				SetEntProp(i, Prop_Data, "m_iFrags", GetClientFrags(i) + 1);
				PrintToChat(i, "\x04[SM] You gained a kill assist! (%i damage to %N)", g_damage[i][victim], victim);
				break;
			}
		}
	}
}