#include <sourcemod>
#include <sdktools>
#include <events>
#tryinclude <colors>
#if !defined _colors_included
	#tryinclude <morecolors>
#endif
#pragma semicolon 1

// global variables tied to cvars
new bool:enabled = true;
new minplayers_mini = 10;
new minplayers_full = 6;
new bool:destroy_mini = true;
new bool:destroy_full = true;
new method = 0;
new bool:chatspam = true;
new bool:announce = true;
new bool:refund = true;
new bool:count_spec = false;
new bool:count_bots = false;

// cvar handles
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_minplayers_mini = INVALID_HANDLE;
new Handle:cvar_minplayers_full = INVALID_HANDLE;
new Handle:cvar_destroy_mini = INVALID_HANDLE;
new Handle:cvar_destroy_full = INVALID_HANDLE;
new Handle:cvar_method = INVALID_HANDLE;
new Handle:cvar_chatspam = INVALID_HANDLE;
new Handle:cvar_announce = INVALID_HANDLE;
new Handle:cvar_refund = INVALID_HANDLE;
new Handle:cvar_count_spec = INVALID_HANDLE;
new Handle:cvar_count_bots = INVALID_HANDLE;

// global variables not tied to cvars
new playercount = 0;
new bool:bot[MAXPLAYERS + 1];
new bool:allowed_mini = false;
new bool:allowed_full = false;

public Plugin:myinfo = {
	name = "Sentry Restrict",
	author = "epicoder",
	description = "Disallow sentries under a certain player count",
	version = "0.4",
	url = "http:// domain.invalid/"
}


KillSentry(sentry, mini, builder, bool:ignorerefund) { // destroy a particular sentry and optionally refund metal to the builder. all arguments except builder guaranteed to be valid
	switch (method) {
		case 0: {
			FakeClientCommand(builder, "destroy 2 0");
		}
		case 1: {
			AcceptEntityInput(sentry, "Kill", builder, builder);
		}
		case 2: {
			SetVariantInt(1000);
			AcceptEntityInput(sentry, "RemoveHealth", builder, builder);
		}
	}
	if (chatspam && IsClientConnected(builder)) {
		if (mini) {
#if defined _colors_included
			if (minplayers_mini == MAXPLAYERS + 1) {
				CPrintToChat(builder, "{green}Mini-sentries {default}are disabled on this server.");
			} else {
				CPrintToChat(builder, "Your {green}mini-sentry {default}was destroyed because there are less than {green}%d {default}active players.", minplayers_mini);
			}
#else
			if (minplayers_mini == MAXPLAYERS + 1) {
				PrintToChat(builder, "Mini-sentries are disabled on this server.");
			} else {
				PrintToChat(builder, "Your mini-sentry was destroyed because there are less than %d active players.", minplayers_mini);
			}
#endif
		} else {
#if defined _colors_included
			if (minplayers_full == MAXPLAYERS + 1) {
				CPrintToChat(builder, "{green}Sentries {default}are disabled on this server.");
			} else {
				CPrintToChat(builder, "Your {green}sentry {default}was destroyed because there are less than {green}%d {default}active players.", minplayers_full);
			}
#else
			if (minplayers_full == MAXPLAYERS + 1) {
				PrintToChat(builder, "Sentries are disabled on this server.");
			} else {
				PrintToChat(builder, "Your sentry was destroyed because there are less than %d active players.", minplayers_full);
			}
#endif
		}
	}
	if (!ignorerefund && refund) {
		if (IsClientConnected(builder) && IsClientInGame(builder) && IsPlayerAlive(builder)) {
			new metal = GetEntProp(builder, Prop_Send, "m_iAmmo", 4, 3); // metal count is the ammo count of an engineer's melee weapon
			if (mini) {
				metal += 100;
			} else {
				metal += 130;
			}
			if (metal > 200) {
				metal = 200;
			}
			SetEntProp(builder, Prop_Send, "m_iAmmo", metal, 4, 3);
		}
	}
}

Destroy(client, mini) { // destroy the (mini) sentries belonging to client, -1 meaning all clients
	new sentry = -1, prev = 0, builder;
	while ((sentry = FindEntityByClassname(sentry, "obj_sentrygun")) != INVALID_ENT_REFERENCE) {
		if (prev) {
			builder = GetEntPropEnt(prev, Prop_Send, "m_hBuilder");
			if (client == -1 || builder == client) {
				if (GetEntProp(prev, Prop_Send, "m_bMiniBuilding") == mini) {
					KillSentry(prev, mini, builder, client == -1); // never refund for late destructions
				}
			}
		}
		prev = sentry;
	}
	if (prev) {
		builder = GetEntPropEnt(prev, Prop_Send, "m_hBuilder");
		if (client == -1 || builder == client) {
			if (GetEntProp(prev, Prop_Send, "m_bMiniBuilding") == mini) {
				KillSentry(prev, mini, builder, client == -1);
			}
		}
	}
}

CountPlayers() { // count the number of players according to current critera and take action as necessary
	if (enabled) {
		playercount = 0;
		// This loop does nothing during OnPluginStart, which is fine since it gets run again as soon as someone joins anyway
		for (new client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client)) {
				new team = GetClientTeam(client);
				if (count_bots || !bot[client]) {
					if (count_spec || (team == 2 || team == 3)) { // 2 = RED, 3 = BLU
						playercount++;
					}
				}
			}
		}
		if (playercount < minplayers_mini) {
			if (allowed_mini) {
				if (announce) {
#if defined _colors_included
					CPrintToChatAll("{green}Mini-sentries {default}are no longer allowed.");
#else
					PrintToChatAll("Mini-sentries are no longer allowed.");
#endif
				}
				if (destroy_mini) {
					Destroy(-1, 1);
				}
				allowed_mini = false;
			}
		} else {
			if (!allowed_mini) {
				if (announce) {
#if defined _colors_included
					CPrintToChatAll("{green}Mini-sentries {default}are now allowed.");
#else
					PrintToChatAll("Mini-sentries are now allowed.");
#endif
				}
				allowed_mini = true;
			}
		}
		if (playercount < minplayers_full) {
			if (allowed_full) {
				if (announce) {
#if defined _colors_included
					CPrintToChatAll("{green}Sentries {default}are no longer allowed.");
#else
					PrintToChatAll("Sentries are no longer allowed.");
#endif
				}
				if (destroy_full) {
					Destroy(-1, 0);
				}
				allowed_full = false;
			}
		} else {
			if (!allowed_full) {
				if (announce) {
#if defined _colors_included
					CPrintToChatAll("{green}Sentries {default}are now allowed.");
#else
					PrintToChatAll("Sentries are now allowed.");
#endif
				}
				allowed_full = true;
			}
		}
	}
}

// timers
public Action:timer_CountPlayers(Handle:timer) {
	CountPlayers();
	return Plugin_Continue;
}

// cvar hooks
public cvhook_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	enabled = !!StringToInt(newValue); // coerce to boolean
	allowed_full = true; // these assignments make sure that freshly disallowed sentries are destroyed
	allowed_mini = true;
	CountPlayers();
}
public cvhook_minplayers_mini(Handle:convar, const String:oldValue[], const String:newValue[]) {
	minplayers_mini = StringToInt(newValue);
	if (minplayers_mini == 0) {
		minplayers_mini = MAXPLAYERS + 1;
	}
	CountPlayers();
}
public cvhook_minplayers_full(Handle:convar, const String:oldValue[], const String:newValue[]) {
	minplayers_full = StringToInt(newValue);
	if (minplayers_full == 0) {
		minplayers_full = MAXPLAYERS + 1;
	}
	CountPlayers();
}
public cvhook_destroy_mini(Handle:convar, const String:oldValue[], const String:newValue[]) {
	destroy_mini = !!StringToInt(newValue);
}
public cvhook_destroy_full(Handle:convar, const String:oldValue[], const String:newValue[]) {
	destroy_full = !!StringToInt(newValue);
}
public cvhook_method(Handle:convar, const String:oldValue[], const String:newValue[]) {
	method = StringToInt(newValue);
}
public cvhook_chatspam(Handle:convar, const String:oldValue[], const String:newValue[]) {
	chatspam = !!StringToInt(newValue);
}
public cvhook_announce(Handle:convar, const String:oldValue[], const String:newValue[]) {
	announce = !!StringToInt(newValue);
}
public cvhook_refund(Handle:convar, const String:oldValue[], const String:newValue[]) {
	refund = !!StringToInt(newValue);
}
public cvhook_count_bots(Handle:convar, const String:oldValue[], const String:newValue[]) {
	count_bots = !!StringToInt(newValue);
	CountPlayers();
}
public cvhook_count_spec(Handle:convar, const String:oldValue[], const String:newValue[]) {
	count_spec = !!StringToInt(newValue);
	CountPlayers();
}

// event hooks
public evhook_builtobject(Handle:event, const String:name[], bool:dontBroadcast) {
	if (enabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!allowed_full) {
			Destroy(client, 0);
		}
		if (!allowed_mini) {
			Destroy(client, 1);
		}
	}
}
public evhook_team(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.1, timer_CountPlayers, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
}

// forwards
public OnClientAuthorized(client, const String:auth[]) {
	bot[client] = StrEqual(auth, "BOT");
}

public OnClientPutInServer(client) {
	CountPlayers();
}

public OnPluginStart() {
	cvar_enabled = CreateConVar("sm_sentryrestrict_enabled", "1", " Set to 0 to disable Sentry Restrict (always allow sentries)", FCVAR_PLUGIN);
	cvar_minplayers_mini = CreateConVar("sm_sentryrestrict_minplayers_mini", "10", " Minimum players to allow mini-sentries. 0 = never allow", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_minplayers_full = CreateConVar("sm_sentryrestrict_minplayers_full", "6", " Minimum players to allow standard sentries. 0 = never allow", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_destroy_mini = CreateConVar("sm_sentryrestrict_destroy_mini", "1", " Set to 1 to destroy existing mini-sentries when the player count falls below the threshold", FCVAR_PLUGIN);
	cvar_destroy_full = CreateConVar("sm_sentryrestrict_destroy_full", "1", " Set to 1 to destroy existing standard sentries when the player count falls below the threshold", FCVAR_PLUGIN);
	cvar_method = CreateConVar("sm_sentryrestrict_method", "0", " Method of destroying sentries\n    0: Force the client to execute destroy 2 0\n    1: Remove the sentry from the game world\n    2: Destroy the sentry with damage from the builder", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_chatspam = CreateConVar("sm_sentryrestrict_chatspam", "1", " Set to 1 to tell clients when their sentries are destroyed", FCVAR_PLUGIN);
	cvar_announce = CreateConVar("sm_sentryrestrict_announce", "1", " Set to 1 to announce when sentries are allowed or disallowed", FCVAR_PLUGIN);
	cvar_refund = CreateConVar("sm_sentryrestrict_refund", "1", " Set to 1 to refund the builder's metal when their sentry is destroyed", FCVAR_PLUGIN);
	cvar_count_bots = CreateConVar("sm_sentryrestrict_count_bots", "0", " Set to 1 to count bots when deciding to allow/disallow sentries", FCVAR_PLUGIN);
	cvar_count_spec = CreateConVar("sm_sentryrestrict_count_spec", "0", " Set to 1 to count spectators and unassigned players when deciding to allow/disallow sentries", FCVAR_PLUGIN);
	HookConVarChange(cvar_enabled, cvhook_enabled);
	HookConVarChange(cvar_minplayers_mini, cvhook_minplayers_mini);
	HookConVarChange(cvar_minplayers_full, cvhook_minplayers_full);
	HookConVarChange(cvar_destroy_mini, cvhook_destroy_mini);
	HookConVarChange(cvar_destroy_full, cvhook_destroy_full);
	HookConVarChange(cvar_method, cvhook_method);
	HookConVarChange(cvar_chatspam, cvhook_chatspam);
	HookConVarChange(cvar_announce, cvhook_announce);
	HookConVarChange(cvar_refund, cvhook_refund);
	HookConVarChange(cvar_count_bots, cvhook_count_bots);
	HookConVarChange(cvar_count_spec, cvhook_count_spec);
	HookEvent("player_builtobject", evhook_builtobject);
	HookEvent("player_team", evhook_team);
	CountPlayers();
}
