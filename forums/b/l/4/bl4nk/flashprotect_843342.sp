#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.0"

new bool:g_bFlashed[MAXPLAYERS+1];

new Handle:g_hCvarEnable;
new Handle:g_hCvarDamage;
new Handle:g_hCvarDuration;
new Handle:g_hCvarMessage;
new Handle:g_hCvarMinHealth;

public Plugin:myinfo =
{
	name = "FlashProtect",
	author = "bl4nk",
	description = "Damage players who flash their own team",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("flashprotect.phrases");

	CreateConVar("sm_flashprotect_version", PLUGIN_VERSION, "FlashProtect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarEnable = CreateConVar("sm_flashprotect_enable", "1", "Enable/Disable the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarDamage = CreateConVar("sm_flashprotect_damage", "3", "Damage to do per second of flash", FCVAR_PLUGIN, true, 0.0, false, _);
	g_hCvarDuration = CreateConVar("sm_flashprotect_duration", "1.5", "Maximum duration that a flash can last for before it's punishable", FCVAR_PLUGIN, true, 0.0, true, 7.0);
	g_hCvarMessage = CreateConVar("sm_flashprotect_message", "1", "Message teammates when a player has flashed someone", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarMinHealth = CreateConVar("sm_flashprotect_minhealth", "20", "Minimum health a player can have without being damaged for team flashing", FCVAR_PLUGIN, true, 0.0, true, 100.0);

	HookEvent("player_blind", Event_PlayerBlind);
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
}

/* Called when a player is blinded by a flashbang */
public Event_PlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Is the plugin enabled? */
	if (!GetConVarBool(g_hCvarEnable))
	{
		return;
	}

	/* The client that was blinded */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	/* Check and see if the flash magnitude is high (255) */
	if (GetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha") == 255)
	{
		/* Get the max limited flash time without punishment */
		new Float:durationLimit = GetConVarFloat(g_hCvarDuration);

		/* If the player was flashed for longer than the allowed time, punish the flasher */
		if (GetEntPropFloat(client, Prop_Send, "m_flFlashDuration") > durationLimit)
		{
			/* Mark the player as being flashed */
			g_bFlashed[client] = true;
		}
	}
}

/* Called when a flashbang has detonated (after the players have already been blinded) */
public Event_FlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Is the plugin enabled? */
	if (!GetConVarBool(g_hCvarEnable))
	{
		return;
	}

	/* The number of flashed players, and the player that threw the flashbang */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new count, damage, dps = GetConVarInt(g_hCvarDamage);

	/* Loop through all flashed players to check if they are on the same team */
	for (new i = 1; i <= MaxClients; i++)
	{
		/* Flash player found */
		if (g_bFlashed[i] == true)
		{
			/* Get the time the player was flashed for */
			new Float:flashTime = GetEntPropFloat(i, Prop_Send, "m_flFlashDuration");

			/* Format the flashed time to be 2 decimal places */
			decl String:sFlash[8];
			Format(sFlash, sizeof(sFlash), "%.2f", flashTime);

			/* Did the player flash themself? */
			if (i == client)
			{
				PrintToChat(client, "[SM] %t", "Self Flash", sFlash);
			}
			/* Did the player flash an alive teammate? */
			else if (GetClientTeam(i) == GetClientTeam(client) && IsPlayerAlive(i))
			{
				count++;

				decl String:flashedName[32], String:flasherName[32];
				GetClientName(i, flashedName, sizeof(flashedName));
				GetClientName(client, flasherName, sizeof(flasherName));

				PrintToChat(i, "[SM] %t", "Flashed By", flasherName, sFlash);
				PrintToChat(client, "[SM] %t", "You Flashed", flashedName, sFlash);

				/* Increment the damage taken depending on how long the player was flashed for */
				damage += RoundFloat(dps * flashTime);
			}

			/* The flashed player has been handled, mark them as not being flashed any longer */
			g_bFlashed[i] = false;
		}
	}

	/* If at least one player was flashed, send a message to teammates */
	if (count > 0 && GetConVarBool(g_hCvarMessage))
	{
		decl String:flasherName[32];
		GetClientName(client, flasherName, sizeof(flasherName));

		/* Print messages to the teammates of the flasher */
		for (new i = 1; i <= MaxClients; i++)
		{
			if (i == client)
			{
				continue;
			}

			if (IsClientInGame(i) && GetClientTeam(i) == GetClientTeam(client))
			{
				PrintToChat(i, "[SM] %t", "Flashed Teammates", flasherName, count);
			}
		}

		/* Punish the flasher for blinding teammates */
		PunishFlasher(client, damage);
	}
}

PunishFlasher(client, damage)
{
	new health = GetPlayerHealth(client);
	new minHealth = GetConVarInt(g_hCvarMinHealth);

	if (minHealth > 0 && health - damage < minHealth)
	{
		SlapPlayer(client, health - minHealth);
	}
	else
	{
		if (damage >= health)
		{
			ForcePlayerSuicide(client);
		}
		else
		{
			SlapPlayer(client, damage);
		}
	}
}

GetPlayerHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}