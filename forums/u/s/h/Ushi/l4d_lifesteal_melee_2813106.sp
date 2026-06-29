#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

enum LifestealEvents
{
	EVENT_INFECTED_DEATH
};

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// Plugin information
public Plugin myinfo =
{
	name = "Lifesteal Melee",
	author = "arclightarchery",
	description = "Killing common infected with melee will heal you",
	version = PLUGIN_VERSION,
	url = ""
};

Handle:cvarLifestealAmount;

public void OnPluginStart()
{
	CreateConVar("l4d_lifesteal_melee_version", PLUGIN_VERSION, "Lifesteal Melee Version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	cvarLifestealAmount = CreateConVar("l4d_lifesteal_melee_amount", "5", "How much would you heal when you kill a common infected with melee.", FCVAR_NOTIFY, true, 0.0);

	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);

	AutoExecConfig(true, "l4d_lifesteal_melee");
}

/* ==================================================================================================
										EVENTS
================================================================================================== */

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int infected_id = GetEventInt(event, "infected_id");
	int weapon_id = GetEventInt(event, "weapon_id");

	if (infected_id == 0 && weapon_id == 19) // Assuming weapon_id 19 represents melee attacks
	{
		int maxHealth = GetEntProp(attacker, Prop_Send, "m_iMaxHealth");
		int currentHealth = GetEntProp(attacker, Prop_Send, "m_iHealth");
		int healthAmount = GetConVarInt(cvarLifestealAmount);

		if ((currentHealth + healthAmount) < maxHealth)
		{
			currentHealth += healthAmount;
			SetEntProp(attacker, Prop_Send, "m_iHealth", currentHealth);
		}
		else
		{
			SetEntProp(attacker, Prop_Send, "m_iHealth", maxHealth);
		}
	}
}