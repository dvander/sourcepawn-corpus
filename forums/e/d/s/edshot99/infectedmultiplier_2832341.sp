/*
 * infectedmultiplier.sp
 * Copyright (c) 2022 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sourcemod>
#include "edlib.sp"

#define DEBUG		0
#define COOLDOWN	3.0

public Handle cvMultiplier;
public bool spawnInProgressBoomer = false;
public bool spawnInProgressSmoker = false;
public bool spawnInProgressHunter = false;
public bool spawnInProgressSpitter = false;
public bool spawnInProgressJockey = false;
public bool spawnInProgressCharger = false;

public Plugin myinfo =
{
	name = "[L4D/L4D2] Special Infected Multiplier",
	author = "EDSHOT",
	version = "0.2"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_Left4Dead && GetEngineVersion() != Engine_Left4Dead2)
	{
		SetFailState("This plugin is only supported by the Left 4 Dead series.");
	}
	cvMultiplier = CreateConVar("sm_infectedmultiplier", "0", "Infected Multiplier", FCVAR_PLUGIN, true, 0.0, false, 0.0);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnPluginEnd()
{
	CloseHandle(cvMultiplier);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		if (GetEngineVersion() == Engine_Left4Dead)
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");
			switch (class)
			{
				// Boomer
				case 1:
				{
					if (!spawnInProgressBoomer)
					{
						spawnInProgressBoomer = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class1 {boomer} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn", "boomer", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressBoomer);
					}
				}
				// Smoker
				case 2:
				{
					if (!spawnInProgressSmoker)
					{
						spawnInProgressSmoker = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class2 {smoker} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn", "smoker", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressSmoker);
					}
				}
				// Hunter
				case 3:
				{
					if (!spawnInProgressHunter)
					{
						spawnInProgressHunter = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class3 {hunter} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn", "hunter", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressHunter);
					}
				}
			}
		}
		if (GetEngineVersion() == Engine_Left4Dead2)
		{
			int class = GetEntProp(client, Prop_Send, "m_zombieClass");
			switch (class)
			{
				// Boomer
				case 1:
				{
					if (!spawnInProgressBoomer)
					{
						spawnInProgressBoomer = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class1 {boomer} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "boomer", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressBoomer);
					}
				}
				// Smoker
				case 2:
				{
					if (!spawnInProgressSmoker)
					{
						spawnInProgressSmoker = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class2 {smoker} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "smoker", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressSmoker);
					}
				}
				// Hunter
				case 3:
				{
					if (!spawnInProgressHunter)
					{
						spawnInProgressHunter = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class3 {hunter} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "hunter", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressHunter);
					}
				}
				// Spitter
				case 4:
				{
					if (!spawnInProgressSpitter)
					{
						spawnInProgressSpitter = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class4 {spitter} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "spitter", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressSpitter);
					}
				}
				// Jockey
				case 5:
				{
					if (!spawnInProgressJockey)
					{
						spawnInProgressJockey = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class5 {jockey} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "jockey", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressJockey);
					}
				}
				// Charger
				case 6:
				{
					if (!spawnInProgressCharger)
					{
						spawnInProgressCharger = true;
						for (int tmp; tmp <= GetConVarInt(cvMultiplier); tmp++)
						{
							#if DEBUG
							PrintToChatAll("[DEBUG] class6 {charger} id:%d spawnnumber:%d", client, tmp);
							#endif
							CheatCommand(client, "z_spawn_old", "charger", "auto", "");
						}
						CreateTimer(COOLDOWN, SpawningCooldown, spawnInProgressCharger);
					}
				}
			}
		}
	}
}

public Action SpawningCooldown(Handle timer, any data)
{
	data = false;
	return Plugin_Handled;
}
