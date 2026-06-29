#pragma semicolon 1 // Force strict semicolon mode.

// ====[ INCLUDES ]====================================================
#include <sourcemod>
#include <colors>
#include <sdkhooks>
#include <sdktools> // Slap function

// ====[ CONSTANTS ]===================================================
#define PLUGIN_VERSION "1.0.5"
 
// ====[ VARIABLES ]===================================================
// Global Boolean Variables
new bool:p_enabled,
	bool:p_awp,
	bool:p_g3sg1,
	bool:p_sg550,
	bool:p_slapEnabled,
	bool:p_verboseEnabled,
	bool:p_NotificationEnabled;

// Global CVar Handles
new Handle:g_hEnabled,
	Handle:g_hAwp,
	Handle:g_hG3sg1,
	Handle:g_hSg550,
	Handle:g_hSlapDamage,
	Handle:g_hSlapEnabled,
	Handle:g_hVersion,
	Handle:g_hTextPosition,
	Handle:g_hVerbose,
	Handle:g_hNotification,
	Handle:g_hThreshold;

// Global Variables
new p_slapDamage,
	p_textPosition,
	p_threshold;


// Structure like enum
enum e_playerData
{
	steamid[255],
	ffHits
};

// Initialize array (enum) to NULL for max number of players
new g_playerData[MAXPLAYERS + 1][e_playerData];

// Plugin header/description
public Plugin:myinfo =
{
	name = "Sniper Head Shot",
	author = "Bogomips <bogusmips@gmail.com>",
	description = "Only headshot can kill with the sniper's rifles (AWP, G3SG/1 and SG550). If you cannot aim you should not kill...",
	version = PLUGIN_VERSION,
	url = ""
};

/* OnPluginStart()
 *
 * When the plugin is loaded.
 * Cvars, variables, and console commands are initialized here.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	LoadTranslations("sniperhs.phrases.txt");
	AutoExecConfig(true, "plugin.sniperhs");

	//CreateConVar("cvar name", "value", "Description", Flags default(_), isMin, valueMin, isMax, valueMax)
	g_hVersion = CreateConVar("sm_shs_version", PLUGIN_VERSION, "Sniper Head Shot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// Enforce version number
	decl String:ver[10];
	GetConVarString(g_hVersion, ver, sizeof(ver));
	if (!StrEqual(ver, PLUGIN_VERSION))
	{
		SetConVarString(g_hVersion, PLUGIN_VERSION);
	}

	g_hEnabled = CreateConVar("sm_shs_enabled", "1", "Enable Sniper Head Shot plugin. 0 = Disabled", FCVAR_NONE);
	p_enabled = GetConVarBool(g_hEnabled);

	g_hAwp = CreateConVar("sm_shs_awp", "1", "Enable Head Shot to kill for AWP. 0 = Disabled", FCVAR_NONE);
	p_awp = GetConVarBool(g_hAwp);
	g_hG3sg1 = CreateConVar("sm_shs_g3sg1", "1", "Enable Head Shot to kill for G3SG/1. 0 = Disabled", FCVAR_NONE);
	p_g3sg1 = GetConVarBool(g_hG3sg1);
	g_hSg550 = CreateConVar("sm_shs_sg550", "1", "Enable Head Shot to kill for SG550. 0 = Disabled", FCVAR_NONE);
	p_sg550 = GetConVarBool(g_hSg550);

	g_hSlapEnabled = CreateConVar("sm_shs_slapenabled", "1", "Enable Slap if HS missed. 0 = Disabled", FCVAR_NONE);
	p_slapEnabled = GetConVarBool(g_hSlapEnabled);
	g_hSlapDamage = CreateConVar("sm_shs_slapdamage", "0", "Slap damage amount.", FCVAR_NONE);
	p_slapDamage = GetConVarInt(g_hSlapDamage);

	g_hTextPosition = CreateConVar("sm_shs_textposition", "3", "Defines the area for SHS alert message:\n 1 = in the center of the screen\n 2 = in the hint text area \n 3 = in chat area of screen", FCVAR_NONE, true, 1.0, true, 3.0);
	p_textPosition = GetConVarInt(g_hTextPosition);

	g_hVerbose = CreateConVar("sm_shs_verbose", "0", "Enable verbose mode (log). 0 = Disabled", FCVAR_NONE);
	p_verboseEnabled = GetConVarBool(g_hVerbose);
	g_hNotification = CreateConVar("sm_shs_notification", "1", "Enable player notification of missed shot (at sm_shs_textposition). 0 = Disabled", FCVAR_NONE);
	p_NotificationEnabled = GetConVarBool(g_hNotification);

	g_hThreshold = CreateConVar("sm_shs_threshold", "0", "Number of missed HS before player notification.", FCVAR_NONE);
	p_threshold = GetConVarInt(g_hThreshold);

	HookConVarChange(g_hEnabled, OnSettingsChange);
	HookConVarChange(g_hAwp, OnSettingsChange);
	HookConVarChange(g_hG3sg1, OnSettingsChange);
	HookConVarChange(g_hSg550, OnSettingsChange);
	HookConVarChange(g_hSlapEnabled, OnSettingsChange);
	HookConVarChange(g_hSlapDamage, OnSettingsChange);
	HookConVarChange(g_hTextPosition, OnSettingsChange);
	HookConVarChange(g_hVersion, OnSettingsChange);
	HookConVarChange(g_hVerbose, OnSettingsChange);
	HookConVarChange(g_hThreshold, OnSettingsChange);

	HookEvent("item_pickup", OnItemPickup, EventHookMode_Pre);

	// Reregister all clients already in game when plugin restarted (for exemple when ZBlock warmode is disabled)
	for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_TraceAttack, OnTraceAttack);
        }
    }

    // Only admin can have SHS help in his console
	RegAdminCmd("sm_shs_help", DisplayHelp,	ADMFLAG_KICK, "Display Sniper Head Shot available cvars.");


	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_playerData[i][steamid] = GetClientOfUserId(i);
			g_playerData[i][ffHits] = 0;
		}
	}


	if (p_verboseEnabled)
	{
		PrintToServer("[Sniper Head Shot] Started.");
		LogMessage("--- Started ---");
	}
}

/* OnPluginEnd()
 *
 * When the plugin is unloaded.
 * Mostly used to free timers, etc.
 * -------------------------------------------------------------------------- */
public OnPluginEnd()
{
	if (p_verboseEnabled)
	{
		PrintToServer("[Sniper Head Shot] Stopped.");
		LogMessage("--- Stopped ---");
	}
	// TODO check if this is useful to free resources or not
	/*for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKUnhook(i, SDKHook_TraceAttack, OnTraceAttack);
		}
	}*/
}

/* OnClientPutInServer()
 *
 * When the client enter the server.
 * Client specific hooks (SDKHooks) are done here.
 * -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);

	for (new i = 1; i <= MaxClients; i++)
	{
		if(g_playerData[i][steamid] == 0)
		{
			g_playerData[i][steamid] = GetClientOfUserId(client);
			g_playerData[i][ffHits] = 0;
		}
	}
}

/* OnClientDisconnect()
 *
 * When the client leave the server.
 * Client specific hooks (SDKHooks) are done here.
 * -------------------------------------------------------------------------- */
public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnTraceAttack);

	for (new i = 1; i <= MaxClients; i++)
	{
		if(g_playerData[i][steamid] == GetClientOfUserId(client))
		{
			g_playerData[i][steamid] = 0;
		}
	}
}

// ====[ CVARS ]====================================================
public OnSettingsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == g_hEnabled)
	{
		if (StringToInt(newVal) == 0)
		{
			p_enabled = false;
			UnhookEvent("item_pickup", OnItemPickup, EventHookMode_Pre);
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Plugin disabled");
		}
		else
		{
			p_enabled = true;
			HookEvent("item_pickup", OnItemPickup, EventHookMode_Pre);
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Plugin enabled");
		}
	}
	else if(cvar == g_hAwp)
	{
		if (StringToInt(newVal) == 0)
		{
			p_awp = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "AWP disabled");
		}
		else
		{
			p_awp = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "AWP enabled");
		}
	}
	else if(cvar == g_hG3sg1)
	{
		if (StringToInt(newVal) == 0)
		{
			p_g3sg1 = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "G3SG/1 disabled");
		}
		else
		{
			p_g3sg1 = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "G3SG/1 enabled");
		}
	}
	else if(cvar == g_hSg550)
	{
		if (StringToInt(newVal) == 0)
		{
			p_sg550 = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "SG550 disabled");
		}
		else
		{
			p_sg550 = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "SG550 enabled");
		}
	}
	else if(cvar == g_hSlapEnabled)
	{
		if (StringToInt(newVal) == 0)
		{
			p_slapEnabled = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Slap disabled");
		}
		else
		{
			p_slapEnabled = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Slap enabled");
		}
	}
	else if(cvar == g_hVerbose)
	{
		if (StringToInt(newVal) == 0)
		{
			p_verboseEnabled = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Verbose disabled");
		}
		else
		{
			p_verboseEnabled = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Verbose enabled");
		}
	}
	else if(cvar == g_hNotification)
	{
		if (StringToInt(newVal) == 0)
		{
			p_NotificationEnabled = false;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Notification disabled");
		}
		else
		{
			p_NotificationEnabled = true;
			CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Notification enabled");
		}
	}
	else if(cvar == g_hSlapDamage)
	{
		p_slapDamage = StringToInt(newVal);
		CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Slap damage", StringToInt(oldVal), p_slapDamage);
	}
	else if(cvar == g_hThreshold)
	{
		p_threshold = StringToInt(newVal);
		CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Notification threshold", StringToInt(oldVal), p_threshold);
	}
	else if(cvar == g_hTextPosition)
	{
		p_textPosition = StringToInt(newVal);
		decl String:position[16];

		switch (p_textPosition)
		{
			case 1:
			{
				position = "position1";
			}
			case 2:
			{
				position = "position2";
			}
			case 3:
			{
				position = "position3";
			}
		}
		CPrintToChatAll("{green}[Sniper Head Shot]{default} %t", "Text position", position);
	}
	else if(cvar == g_hVersion && !StrEqual(newVal, PLUGIN_VERSION))
	{
		// Enforce version number
		SetConVarString(g_hVersion, PLUGIN_VERSION);
	}
}

/* OnTraceAttack()
 *
 * Callback function called when client is hurt by anything.
 * Weapon and damage management are done here.
 * -------------------------------------------------------------------------- */
public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(p_enabled)
	{
		//PrintToChatAll("Appel Callback.");
		decl String:weapon[64];

		// to prevent error log invalid index
		if (0 < inflictor <= MaxClients)
		{
			GetClientWeapon(inflictor, weapon, sizeof(weapon));
		}

		/*if (p_verboseEnabled)
		{
			PrintToServer("[Sniper Head Shot] weapon: %s", weapon);
		}*/

		if ((p_awp && StrEqual(weapon, "weapon_awp", false))
		||	(p_g3sg1 && StrEqual(weapon, "weapon_g3sg1", false))
		||	(p_sg550 && StrEqual(weapon, "weapon_sg550", false)))
		{
			//PrintToChatAll("Callback filtre sniper.");

			if (GetClientTeam(victim) != GetClientTeam(attacker))
			{
				//PrintToChatAll("Callback victim != attacker");

				if (hitgroup != 1)
				{
					//PrintToChatAll("Callback hitgroup != 1. Damage: %f", damage);
					decl String:victimName[MAX_NAME_LENGTH], String:attackerName[MAX_NAME_LENGTH];
					GetClientName(victim, victimName, sizeof(victimName));
					GetClientName(attacker, attackerName, sizeof(attackerName));

					if (p_slapEnabled)
					{
						SlapPlayer(attacker, p_slapDamage);

						if (p_NotificationEnabled)
						{
							for (new i = 1; i <= MaxClients; i++)
							{
								if(g_playerData[i][steamid] == GetClientOfUserId(attacker))
								{
									if(g_playerData[i][ffHits] >= p_threshold)
									{
										switch (p_textPosition)
										{
											case 1:
											{
												PrintCenterText(attacker, "[Sniper Head Shot] %t", "Slapped no colors", p_slapDamage, weapon);
											}

											case 2:
											{
												PrintHintText(attacker, "[Sniper Head Shot] %t", "Slapped no colors", p_slapDamage, weapon);
											}

											case 3:
											{
												CPrintToChat(attacker, "{green}[Sniper Head Shot]{default} %t", "Slapped", p_slapDamage, weapon);
											}

											default:
											{
												PrintToChat(attacker, "[Sniper Head Shot] %t", "Slapped no colors", p_slapDamage, weapon);
											}
										}

										g_playerData[i][ffHits] = 0;
									}
									else
									{
										g_playerData[i][ffHits]++;
									}
								}
							}

						}

						if (p_verboseEnabled)
						{
							PrintToServer("[Sniper Head Shot] \"%s\" slapped with %dhp damage for missing \"%s\"'s head with \"%s\".", attackerName, p_slapDamage, victimName, weapon);
							LogMessage("\"%s\" slapped with %dhp damage for missing \"%s\"'s head with \"%s\".", attackerName, p_slapDamage, victimName, weapon);
						}
					}
					else
					{
						if (p_NotificationEnabled)
						{
							switch (p_textPosition)
							{
								case 1:
								{
									PrintCenterText(attacker, "[Sniper Head Shot] %t", "Warning no colors", weapon);
								}

								case 2:
								{
									PrintHintText(attacker, "[Sniper Head Shot] %t", "Warning no colors", weapon);
								}

								case 3:
								{
									CPrintToChat(attacker, "{green}[Sniper Head Shot]{default} %t", "Warning", weapon);
								}

								default:
								{
									PrintToChat(attacker, "[Sniper Head Shot] %t", "Warning no colors", weapon);
								}
							}
						}

						if (p_verboseEnabled)
						{
							PrintToServer("[Sniper Head Shot] %s missed %s's head with %s.", attackerName, victimName, weapon);
							LogMessage("\"%s\" missed \"%s\"'s head with \"%s\".", attackerName, victimName, weapon);
						}
					}

					return Plugin_Handled;
				}
			}
		}
	}

	return Plugin_Continue;
}

/* OnItemPickup()
 *
 * Callback function called when items are picked up or bought by client.
 * Warning messages of modified gun's behavior are done here.
 * -------------------------------------------------------------------------- */
public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(p_enabled)
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));

		decl String:item[64];
		GetEventString(event, "item", item, sizeof(item));

		if ((p_awp && StrEqual(item, "awp"))
		||	(p_g3sg1 && StrEqual(item, "g3sg1"))
		||	(p_sg550 && StrEqual(item, "sg550")))
		{
			switch (p_textPosition)
			{
				case 1:
				{
					PrintCenterText(attacker, "[Sniper Head Shot] %t", "Warning no colors", item);
				}

				case 2:
				{
					PrintHintText(attacker, "[Sniper Head Shot] %t", "Warning no colors", item);
				}

				case 3:
				{
					CPrintToChat(attacker, "{green}[Sniper Head Shot]{default} %t", "Warning", item);
				}

				default:
				{
					PrintToChat(attacker, "[Sniper Head Shot] %t", "Warning no colors", item);
				}
			}
		}
	}

	return Plugin_Continue;
}

/* DisplayHelp()
 *
 * Callback function called when admin type sm_shs_help command.
 * Help messages are done here.
 * -------------------------------------------------------------------------- */
public Action:DisplayHelp(client, args)
{
	PrintToConsole(client, "---------- [Sniper Head Shot] ----------\nCommands and server cvars available:\n - sm_shs_help\n - sm_shs_version\n - sm_shs_enabled\n - sm_shs_verbose\n - sm_shs_awp\n - sm_shs_g3sg1\n - sm_shs_sg550\n - sm_shs_slapenabled\n - sm_shs_slapdamage\n - sm_shs_textposition\n - sm_shs_verbose\n - sm_shs_notification\n - sm_shs_threshold\n----------------------------------------");

	return Plugin_Continue;
}