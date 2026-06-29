// ====[ INCLUDES ]==========================================================
#include <clientprefs>
#include <morecolors> 

// ====[ CONSTANTS ]=========================================================
#define PLUGIN_NAME      "DoD:S Damage Report"
#define PLUGIN_VERSION   "1.7"

#define DOD_MAXPLAYERS   33
#define DOD_MAXHITGROUPS 7

// ====[ VARIABLES ]=========================================================
new	Handle:damagereport_enable, // ConVars
	Handle:damagereport_mdest,
	Handle:dmg_chatprefs, // Clientprefs
	Handle:dmg_panelprefs,
	Handle:dmg_endroundprefs,
	bool:cookie_chatmode[DOD_MAXPLAYERS + 1]    = {false, ...}, // Cookies
	bool:cookie_deathpanel[DOD_MAXPLAYERS + 1]  = {false, ...},
	bool:cookie_resultpanel[DOD_MAXPLAYERS + 1] = {true,  ...},
	bool:roundend = false, // Round end stats
	kills[DOD_MAXPLAYERS + 1],
	deaths[DOD_MAXPLAYERS + 1],
	headshots[DOD_MAXPLAYERS + 1],
	captures[DOD_MAXPLAYERS + 1],
	damage_temp[DOD_MAXPLAYERS + 1], // Damage (given, taken and summary)
	damage_summ[DOD_MAXPLAYERS + 1],
	damage_given[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1],
	damage_taken[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1],
	hits[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1], // Hits data
	hurts[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1],
	String:yourstatus[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1], // Player status (killed or injured)
	String:killerstatus[DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1][DOD_MAXPLAYERS + 1];

// ====[ PLUGIN ]============================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root, playboycyberclub",
	description = "Shows damage stats, round stats and most destructive player",
	version     = PLUGIN_VERSION,
	url         = "http://dodsplugins.com/"
}


/**
 * --------------------------------------------------------------------------
 *     ____           ______                  __  _
 *    / __ \____     / ____/__  ______  _____/ /_(_)____  ____  _____
 *   / / / / __ \   / /_   / / / / __ \/ ___/ __/ // __ \/ __ \/ ___/
 *  / /_/ / / / /  / __/  / /_/ / / / / /__/ /_/ // /_/ / / / (__  )
 *  \____/_/ /_/  /_/     \__,_/_/ /_/\___/\__/_/ \____/_/ /_/____/
 *
 * --------------------------------------------------------------------------
*/

/* OnPluginStart()
 *
 * When the plugin starts up.
 * -------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("dod_damagestats_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	damagereport_enable = CreateConVar("dod_damage_report",       "1", "Whether or not enable Damage Report plugin");
	damagereport_mdest  = CreateConVar("dod_damage_report_mdest", "2", "Determines where to show most destructive player stats:\n1 = In hint\n2 = In chat");

	// Hook main ConVar change
	HookConVarChange(damagereport_enable, OnConVarChange);
	OnConVarChange(damagereport_enable, "0", "1");

	// Create / register damage report command
	RegConsoleCmd("dmg", DamageReportMenu);

	// Load translations
	LoadTranslations("dod_damage_report.phrases");

	// Creates a new clientprefs cookies
	dmg_chatprefs     = RegClientCookie("Chat preferences",     "Damage Report", CookieAccess_Private);
	dmg_panelprefs    = RegClientCookie("Panel preferences",    "Damage Report", CookieAccess_Private);
	dmg_endroundprefs = RegClientCookie("RoundEnd preferences", "Damage Report", CookieAccess_Private);

	// Show "Damge Report" item in cookie settings menu
	decl String:title[64]; Format(title, sizeof(title), "%t", "damagemenu");

	// Add clientprefs item called "Damage Report"
	if (LibraryExists("clientprefs")) SetCookieMenuItem(DamageReportSelect, MENU_TIME_FOREVER, title);
}

/* OnConVarChange()
 *
 * Called when a convar's value is changed.
 * -------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Convert a string to an integer
	switch (StringToInt(newValue))
	{
		// Unhook all needed events on disabling
		case false:
		{
			UnhookEvent("dod_stats_player_damage", Event_Player_Damage);
			UnhookEvent("dod_point_captured",      Event_Point_Captured);
			UnhookEvent("dod_round_start",         Event_Round_Start, EventHookMode_PostNoCopy);
			UnhookEvent("dod_round_win",           Event_Round_End,   EventHookMode_PostNoCopy);
			UnhookEvent("dod_game_over",           Event_Round_End,   EventHookMode_PostNoCopy);
		}
		case true:
		{
			HookEvent("dod_stats_player_damage", Event_Player_Damage);
			HookEvent("dod_point_captured",      Event_Point_Captured);
			HookEvent("dod_round_start",         Event_Round_Start, EventHookMode_PostNoCopy);
			HookEvent("dod_round_win",           Event_Round_End,   EventHookMode_PostNoCopy);
			HookEvent("dod_game_over",           Event_Round_End,   EventHookMode_PostNoCopy);
		}
	}
}

/* OnClientPutInServer()
 *
 * Called when a client is entering the game.
 * -------------------------------------------------------------------------- */
public OnClientPutInServer(client)
{
	// Make sure client is valid
	if (IsValidClient(client))
	{
		// Are clients cookies have been loaded from the database?
		if (AreClientCookiesCached(client))
		{
			LoadPreferences(client);
		}

		// Show welcome message after 30 seconds of connection
		CreateTimer(30.0, Timer_WelcomePlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

/* OnClientCookiesCached()
 *
 * Called once a client's saved cookies have been loaded from the database.
 * -------------------------------------------------------------------------- */
public OnClientCookiesCached(client)
{
	// If cookies was not ready until connection, wait until OnClientCookiesCached()
	if (IsValidClient(client))
	{
		LoadPreferences(client);
	}
}

/* OnClientDisconnect()
 *
 * When a client disconnects from the server.
 * -------------------------------------------------------------------------- */
public OnClientDisconnect_Post(client)
{
	resetall(client);
}


/**
 * --------------------------------------------------------------------------
 *      ______                  __
 *     / ____/_   _____  ____  / /______
 *    / __/  | | / / _ \/ __ \/ __/ ___/
 *   / /___  | |/ /  __/ / / / /_(__  )
 *  /_____/  |___/\___/_/ /_/\__/____/
 *
 * --------------------------------------------------------------------------
*/

/* Event_Player_Damage()
 *
 * Called when a player taking damage and dying.
 * -------------------------------------------------------------------------- */
public Event_Player_Damage(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (roundend == false)
	{
		// Get event keys
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event, "victim"));
		new damage   = GetEventInt(event, "damage");
		new hitgroup = GetEventInt(event, "hitgroup");

		// Make sure attacker and victim is okay
		if (attacker && victim && GetClientTeam(attacker) != GetClientTeam(victim))
		{
			// 7 hitboxes is avaliable
			decl String:Hitbox[DOD_MAXHITGROUPS + 1][32], String:data[32], String:color[10];

			// I'd like to use all features of 'morecolors' since its having team colors for DoD:S
			FormatEx(color, sizeof(color), "%s", GetClientTeam(victim) == 2 ? "{allies}" : "{axis}");

			// Hitgroup definitions
			Format(data, sizeof(data), "%t", "hitbox0", victim); Hitbox[0] = data; // Generic
			Format(data, sizeof(data), "%t", "hitbox1", victim); Hitbox[1] = data; // Head
			Format(data, sizeof(data), "%t", "hitbox2", victim); Hitbox[2] = data; // Upper chest
			Format(data, sizeof(data), "%t", "hitbox3", victim); Hitbox[3] = data; // Lower Chest
			Format(data, sizeof(data), "%t", "hitbox4", victim); Hitbox[4] = data; // Left arm
			Format(data, sizeof(data), "%t", "hitbox5", victim); Hitbox[5] = data; // Right arm
			Format(data, sizeof(data), "%t", "hitbox6", victim); Hitbox[6] = data; // Left leg
			Format(data, sizeof(data), "%t", "hitbox7", victim); Hitbox[7] = data; // Right Leg

			// Times hit/injured
			hits[victim][attacker]++;
			hurts[attacker][victim]++;

			// Saves summary damage done to all victims
			damage_temp[attacker] += damage;

			// Summary damage (most destructive)
			damage_summ[attacker] += damage;

			// Save damage data of every injured victim
			damage_given[attacker][victim] += damage;

			// And for every attacker
			damage_taken[victim][attacker] += damage;

			// GetEventInt(event, "health") is not working here. So I'd better do GetClientHealth
			if (GetClientHealth(victim) > 0)
			{
				// If player was not killed - show status
				Format(data, sizeof(data), "%t", "injured", victim);
				yourstatus[attacker][victim] = data;

				// Dont show 'injured you' phrase
				FormatEx(data, sizeof(data), NULL_STRING, victim);
				killerstatus[victim][attacker] = data;

				// Show chat notifications if client wants
				if (cookie_chatmode[attacker])
				{
					CPrintToChat(attacker, "%t", "chat", color, victim, yourstatus[attacker][victim], Hitbox[hitgroup], damage);
				}
			}
			else
			{
				decl String:buffer[32], String:given[32], String:taken[32];

				// Add kills & deaths for endround stats
				kills[attacker]++;
				deaths[victim]++;

				// NULL_STRING fix issue with unknown characters in a panel
				Format(given,    sizeof(given), "%T", "given", victim, damage_temp[victim]);
				Format(taken,    sizeof(taken), "%T", "taken", victim);
				FormatEx(buffer, sizeof(buffer), NULL_STRING,  victim);

				// Check client's preferences
				if (cookie_deathpanel[victim])
				{
					new Handle:panel = CreatePanel(), i;

					// Show panel if player do any damage
					if (damage_temp[victim]) DrawPanelItem(panel, given);

					for (i = 1; i <= MaxClients; i++)
					{
						// Check for all damaged victims, otherwise not involved enemies will be shown
						if (IsClientInGame(i) && damage_given[victim][i])
						{
							// Show names of all victims
							decl String:victims[72], String:victimname[MAX_NAME_LENGTH];
							GetClientName(i, victimname, sizeof(victimname));

							Format(victims, sizeof(victims), "%T", "yourstats", victim, victimname, damage_given[victim][i], hurts[victim][i], yourstatus[victim][i]);
							DrawPanelText(panel, victims);
						}
					}

					// Panel with attackers
					DrawPanelItem(panel, taken);
					for (i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && damage_taken[victim][i])
						{
							decl String:attackers[72], String:attackername[MAX_NAME_LENGTH];
							GetClientName(i, attackername, sizeof(attackername));

							// Getting attackers data
							Format(attackers, sizeof(attackers), "%T", "enemystats", victim, attackername, damage_taken[victim][i], hits[victim][i], killerstatus[victim][i]);
							DrawPanelText(panel, attackers);
						}
					}

					// Draw panel wit' all results for 8 seconds
					DrawPanelText(panel, buffer);
					SendPanelToClient(panel, victim, Handler_DoNothing, 8);
					CloseHandle(panel);
				}

				// Show killed victims
				Format(data, sizeof(data), "%t", "killed", victim);
				yourstatus[attacker][victim] = data;

				// And killer's info
				Format(data, sizeof(data), "%t", "killer", victim);
				killerstatus[victim][attacker] = data;

				// Headshot
				if (hitgroup == 1) headshots[attacker]++;

				if (cookie_chatmode[attacker])
				{
					CPrintToChat(attacker, "%t", "chat", color, victim, yourstatus[attacker][victim], Hitbox[hitgroup], damage);
				}

				// Reset all damage to zero, otherwise panel with all results be always shown
				resethits(victim);
			}
		}
	}
}

/* Event_Point_Captured()
 *
 * When a flag/point is captured.
 * -------------------------------------------------------------------------- */
public Event_Point_Captured(Handle:event, const String:name[], bool:dontBroadcast)
{
	// There may be more than 1 capper
	decl String:cappers[256];
	GetEventString(event, "cappers", cappers, sizeof(cappers));
	for (new i; i < strlen(cappers); i++)
	{
		captures[cappers[i]]++;
	}
}

/* Event_Round_Start()
 *
 * Called when the round starts.
 * -------------------------------------------------------------------------- */
public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Round started
	roundend = false;

	// Reset everything
	for (new client = 1; client <= MaxClients; client++)
	{
		OnClientDisconnect_Post(client);
	}
}

/* Event_Round_End()
 *
 * Called when a round ends.
 * -------------------------------------------------------------------------- */
public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Init
	new client, mdest;
	roundend = true;

	for (client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			// Getting most kills & damage from all players to define most destructive
			if (kills[client] > kills[mdest]) mdest = client;
			else if (kills[client] == kills[mdest] && damage_summ[client] > damage_summ[mdest]) mdest = client;

			// Are client wants to see roundend panel?
			if (cookie_resultpanel[client])
			{
				decl String:menutitle[64],
				     String:overallkills[64],
				     String:overalldeaths[64],
				     String:overallheadshots[64],
				     String:overallcaptures[64],
				     String:overalldamage[64];

				// Dont show panel if client dont do any action below
				if (kills[client] || deaths[client] || headshots[client] || captures[client])
				{
					new Handle:panel = CreatePanel();

					// Draw panel as item, so clients will able to close it easily
					Format(menutitle, sizeof(menutitle), "%T:", "roundend", client);
					DrawPanelItem(panel, menutitle);

					// If player is killed at least 1 player - add kill stats
					if (kills[client])
					{
						Format(overallkills, sizeof(overallkills), "%T", "kills", client, kills[client]);
						DrawPanelText(panel, overallkills);
					}
					if (deaths[client])
					{
						// Format a string for translations
						Format(overalldeaths, sizeof(overalldeaths), "%T", "deaths", client, deaths[client]);
						DrawPanelText(panel, overalldeaths);
					}
					if (headshots[client])
					{
						Format(overallheadshots, sizeof(overallheadshots), "%T", "headshots", client, headshots[client]);

						// And draws a raw line of text on a panel
						DrawPanelText(panel, overallheadshots);
					}
					if (damage_summ[client])
					{
						Format(overalldamage, sizeof(overalldamage), "%T", "alldamage", client, damage_summ[client]);
						DrawPanelText(panel, overalldamage);
					}
					if (captures[client])
					{
						Format(overallcaptures, sizeof(overallcaptures), "%T", "captured", client, captures[client]);
						DrawPanelText(panel, overallcaptures);
					}

					// Draw panel till bonusround
					SendPanelToClient(panel, client, Handler_DoNothing, 14);
					CloseHandle(panel);
				}
			}
		}
	}

	// Show most destructive player if this function is enabled
	if (GetConVarInt(damagereport_mdest))
	{
		// Most destructive player stats
		if (damage_summ[mdest])
		{
			decl String:color[10];

			// Lets colorize chat message depends on most destructive player team
			FormatEx(color, sizeof(color), "%s", GetClientTeam(mdest) == 2 ? "{allies}" : "{axis}");

			// Draw mdest stats (kills, headshots & dmg) depends on value
			switch (GetConVarInt(damagereport_mdest))
			{
				case 1: PrintHintTextToAll("%t", "mdest", mdest, kills[mdest], headshots[mdest], damage_summ[mdest]);
				case 2: CPrintToChatAll("%s%t",  color, "mdest",  mdest, kills[mdest], headshots[mdest], damage_summ[mdest]);
			}
		}
	}
}


/**
 * --------------------------------------------------------------------------
 *     ______                                          __
 *    / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
 *   / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
 *  / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  )
 *  \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/
 *
 * --------------------------------------------------------------------------
*/

/* DamageReportMenu()
 *
 * When client called 'dmgmenu' command.
 * -------------------------------------------------------------------------- */
public Action:DamageReportMenu(client, args)
{
	// Shows Damage Report settings on command
	ShowMenu(client);

	// Prevents 'unknown command' reply in client console
	return Plugin_Handled;
}

/* DamageReportSelect()
 *
 * Dont closes menu when option selected.
 * -------------------------------------------------------------------------- */
public DamageReportSelect(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	// Menu should not disappear on selection
	if (action == CookieMenuAction_SelectOption)
	{
		ShowMenu(client);
	}
}


/**
 * --------------------------------------------------------------------------
 *     ______            __   _
 *    / ____/___  ____  / /__(_)__   ____
 *   / /   / __ \/ __ \/ //_/ / _ \/____/
 *  / /___/ /_/ / /_/ / ,< / /  __/(__ )
 *  \____/\____/\____/_/|_/_/\___/____/
 *
 * --------------------------------------------------------------------------
*/

/* Handler_MenuDmg()
 *
 * Cookie's main menu.
 * -------------------------------------------------------------------------- */
public Handler_MenuDmg(Handle:menu, MenuAction:action, client, param)
{
	switch (action)
	{
		// When client is pressed a button
		case MenuAction_Select:
		{
			// Get param
			switch (param)
			{
				case 0: /* First - chat preferences */
				{
					/* If enabled - be disabled and vice versa */
					cookie_chatmode[client] = !cookie_chatmode[client];
				}
				case 1: /* Second - damage report panel */
				{
					cookie_deathpanel[client] = !cookie_deathpanel[client];
				}
				case 2: /* Third - results panel prefs */
				{
					cookie_resultpanel[client] = !cookie_resultpanel[client];
				}
			}

			// Buffer needed to store cookie
			decl String:buffer[2];

			// Save chat settings
			IntToString(cookie_chatmode[client], buffer, sizeof(buffer));

			// Set the value of a Client preference cookie
			SetClientCookie(client, dmg_chatprefs, buffer);

			// Save death panel settings
			IntToString(cookie_deathpanel[client], buffer, sizeof(buffer));
			SetClientCookie(client, dmg_panelprefs, buffer);

			IntToString(cookie_resultpanel[client], buffer, sizeof(buffer));
			SetClientCookie(client, dmg_endroundprefs, buffer);

			// Call a damage report menu
			DamageReportMenu(client, MENU_TIME_FOREVER);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack) ShowCookieMenu(client);
		}

		// End
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

/* LoadPreferences()
 *
 * Loads client's preferences on connect.
 * -------------------------------------------------------------------------- */
LoadPreferences(client)
{
	decl String:buffer[2];

	// Retrieve the value of a Client preference cookie (for chat preferences)
	GetClientCookie(client, dmg_chatprefs, buffer, sizeof(buffer));
	if (buffer[0]) cookie_chatmode[client] = bool:StringToInt(buffer);

	// for death panel
	GetClientCookie(client, dmg_panelprefs, buffer, sizeof(buffer));
	if (buffer[0]) cookie_deathpanel[client] = bool:StringToInt(buffer);

	GetClientCookie(client, dmg_endroundprefs, buffer, sizeof(buffer));

	// Any buffer should exists in player cookie. If not, use default value
	if (buffer[0]) cookie_resultpanel[client] = bool:StringToInt(buffer);
}

/* ShowMenu()
 *
 * Damage Report menu.
 * -------------------------------------------------------------------------- */
ShowMenu(client)
{
	// Creates a new, empty menu using the default style
	new Handle:menu = CreateMenu(Handler_MenuDmg);

	decl String:buffer[128];
	Format(buffer, sizeof(buffer), "%t:", "damagemenu", client);

	// Sets the menu's default title/instruction message
	SetMenuTitle(menu, buffer);

	Format(buffer, sizeof(buffer), "%t", cookie_chatmode[client] ? "disable text" : "enable text", client);

	// Something must be added on 'AddMenuItem', otherwise Damage Report menu items will not be shown
	AddMenuItem(menu, NULL_STRING, buffer);

	Format(buffer, sizeof(buffer), "%t", cookie_deathpanel[client] ? "disable panel" : "enable panel", client);

	// For every param
	AddMenuItem(menu, NULL_STRING, buffer);

	Format(buffer, sizeof(buffer), "%t", cookie_resultpanel[client] ? "disable results" : "enable results", client);
	AddMenuItem(menu, NULL_STRING, buffer);

	// Add 'ExitBack' and 'Exit' buttons to clientprefs menu
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu,     true);

	// Displays cookies menu until client close it
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}


/**
 * --------------------------------------------------------------------------
 *      __  ____
 *     /  |/  (_)__________
 *    / /|_/ / // ___/ ___/
 *   / /  / / /(__  ) /__
 *  /_/  /_/_//____/\___/
 *
 * --------------------------------------------------------------------------
*/

/* resetall()
 *
 * Reset all player's damage & other stats.
 * -------------------------------------------------------------------------- */
resetall(client)
{
	kills[client] =
	deaths[client] =
	headshots[client] =
	captures[client] =
	damage_temp[client] =
	damage_summ[client] = 0;

	// Loop through all clients
	for (new i = 1; i <= MaxClients; i++)
	{
		damage_given[client][i] =
		damage_taken[client][i] =
		hits[client][i]         =
		hurts[client][i]        = 0;
	}
}

/* resethits()
 *
 * Reset stats of damage & hits.
 * -------------------------------------------------------------------------- */
resethits(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		// Becaue all damage/hits is actually have done on by everyone
		damage_temp[client]     =
		damage_given[client][i] =
		damage_taken[client][i] =
		hits[client][i]         =
		hurts[client][i]        = 0;
	}
}

/* Timer_WelcomePlayer()
 *
 * Shows welcome message to a client.
 * -------------------------------------------------------------------------- */
public Action:Timer_WelcomePlayer(Handle:timer, any:client)
{
	// Get the client id
	if ((client = GetClientOfUserId(client)))
	{
		CPrintToChat(client, "%t", "welcome");
	}
}

/* Handler_DoNothing()
 *
 * Empty menu handler.
 * -------------------------------------------------------------------------- */
public Handler_DoNothing(Handle:menu, MenuAction:action, client, param){}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * -------------------------------------------------------------------------- */
bool:IsValidClient(client) return (1 <= client <= MaxClients && !IsFakeClient(client)) ? true : false;