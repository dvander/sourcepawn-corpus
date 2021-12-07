/**
 * sm_bhop_health plugin by sniperfodder
 * Based off of bl4nk's HPRegeneration plugin.
 * Logic and errors corrected by Antithasys
 *
 * Description:
 *   Sets the health of a player to X ammount of health, and resets it to that ammount anytime they take dammage.
 *
 * Commands and Examples:
 *   sm_bhop_health_enable - Enables the Bhop Health plugin.
 *     - 0 = off
 *     - 1 = on (default)
 *   sm_bhop_health_hp - Health to set to.
 *     - 500 = Set health to 500 (default)
 *     - 1000 = Set health to 1000
 *   sm_bhop_health_delay - Time to delay health regening.
 *     - 0.0 = Instantly (default)
 *     - 0.5 = Half a second after being hurt
 *     - 10.0 = Ten seconds after being hurt
 *   sm_bhop_health_bots - Enables bots regenerating their life.
 *     - 0 = Bots do not get health boost. (default)
 *     - 1 = Bots do get health boost.
 *   sm_bhop_health_spawn_only - Disables health regening after spawn.
 *     - 0 = Regen works like normal. (default)
 *     - 1 = Health is only set at spawn, and not when the player is hurt.
 *
 */

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.3.1"

new bool:isEnabled;
new bool:includeBot;
new bool:spawnOnly;

new iHealth = 0;
new Float:fDelay = 0.0;


new Handle:cvarEnable;
new Handle:cvarHealth;
new Handle:cvarDelay;
new Handle:cvarBot;
new Handle:cvarSpawnOnly;

new Handle:clientTimers[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Bhop Health",
	author = "SniperFodder; bl4nk",
	description = "Sets player health after respawn and any damage to specified ammount.",
	version = PLUGIN_VERSION,
	url = "http://silicateillusion.org"
};


public OnPluginStart()
{
	CreateConVar("sm_bhop_health_version", PLUGIN_VERSION, "Bhop Health Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarEnable = CreateConVar("sm_bhop_health_enable", "1", "Enables the Bhop Health plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	cvarHealth = CreateConVar("sm_bhop_health_hp", "500", "The ammount of health to set (Def 500)", FCVAR_PLUGIN, true, 0.0, false, _);
	
	cvarDelay = CreateConVar("sm_bhop_health_delay", "0.0", "The ammount of time to delay giving the health back (Def 0.0 - Instantly; seconds)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarBot = CreateConVar("sm_bhop_health_bots", "0", "Enables health for bots. (Def 0/off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvarSpawnOnly = CreateConVar("sm_bhop_health_spawn_only", "0", "Disables health regen after spawn. (Def 0/off)", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	AutoExecConfig(true, "plugin.bhop_health");

	HookConVarChange(cvarEnable, CvarChange);

	HookConVarChange(cvarHealth, CvarChange);
	
	HookConVarChange(cvarDelay, CvarChange);

	HookConVarChange(cvarBot, CvarChange);
	
	HookConVarChange(cvarSpawnOnly, CvarChange);

	HookEvent("player_hurt", event_PlayerHurt);

	HookEvent("player_spawn", event_PlayerSpawn);
}

/**
 * Inform the rest of the plugin if we are enabled or disabled.
 */
public OnConfigsExecuted()
{
	isEnabled = GetConVarBool(cvarEnable);

	includeBot = GetConVarBool(cvarBot);
	
	spawnOnly = GetConVarBool(cvarSpawnOnly);

	iHealth = GetConVarInt(cvarHealth);
	
	fDelay = GetConVarFloat(cvarDelay);
}

/**
 * A change occured to one of the cvars, check the change and inform the rest of the plugin.
 */
public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarEnable)
	{
		if (StringToInt(newValue) == 1)
		{
			isEnabled = true;
		}
		else
		{
			isEnabled = false;
		}
	}
	else if (convar == cvarBot)
	{
		if (StringToInt(newValue) == 1)
		{
			includeBot = true;
		}
		else
		{
			includeBot = false;
		}
	}
	else if (convar == cvarSpawnOnly)
	{
		if (StringToInt(newValue) == 1)
		{
			spawnOnly = true;
		}
		else
		{
			spawnOnly = false;
		}
	}
	else if (convar == cvarHealth)
	{
		iHealth = StringToInt(newValue);
	}
	else if (convar == cvarDelay)
	{
		fDelay = StringToFloat(newValue);
	}
}

/**
 * Ensure timer does not continue to run after a client has disconnected.
 */
public OnClientDisconnect_Post(client)
{
	clientTimers[client] = INVALID_HANDLE;
}

/**
 * Check to see if a player has recieved dammage, and return their health to the constant.
 */
public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ensure the plugin is running before we continue and not just spawn.
	if (isEnabled && !spawnOnly)
	{
		// Transform the userid into a client int.
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// Check to see if healing is instant.
		if (fDelay == 0.0)
		{
			// Ensure our client isn't a bot if we are not setting bot health.
			if ((IsFakeClient(client) && !includeBot) || !IsPlayerAlive(client))
			{
				return;
			}
			else
			{
				SetEntityHealth(client, iHealth);
			}
		}
		// If healing is delayed, create a timer as long as one doesn't exist already.
		else if (clientTimers[client] == INVALID_HANDLE)
		{
			clientTimers[client] = CreateTimer(fDelay, HealPlayer, client, TIMER_DATA_HNDL_CLOSE);
		}
		
	}
}

/**
 * Change a player's health to the constant on spawn.
 */
public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Ensure the plugin is enabled.
	if (isEnabled)
	{
		// Transform the userid into a client int.
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		// Ensure our client isn't a bot if we are not setting bot health.
		if (IsFakeClient(client) && !includeBot)
		{
			return;
		}
		else
		{
			SetEntityHealth(client, iHealth);
		}
	}
}

/**
 * Heal the player after the timer finishes.
 */
public Action:HealPlayer(Handle:timer, any:client)
{
	
	// Ensure our client isn't a bot if we are not setting bot health.
	if ((IsFakeClient(client) && !includeBot) || !IsPlayerAlive(client))
	{
		return;
	}
	else
	{
		// Heal the player.
		SetEntityHealth(client, iHealth);
		
		// Disable the timer.
		clientTimers[client] = INVALID_HANDLE;
	}
}