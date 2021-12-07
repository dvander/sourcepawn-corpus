/**
 * sfroundsleft.sp
 * Implements roundsleft (sourceforts only).
 *
 * Version: see Plugin:myinfo
 */
 
#pragma semicolon 1

#include <sourcemod>


new Handle:g_sf_roundlimit;
new Handle:g_info_roundsleft; // for HLSW&co
new g_phaseLeft;
new bool:g_isCombatPhase;
new bool:g_mapRestarted;

public Plugin:myinfo = 
{
	name = "SourceForts Roundsleft",
	author = "kill0r",
	description = "This will show the combatrounds left if someone says roundsleft in chat or in console.",
	version = "0.5.0.5",
	url = ""
};


stock Reset() {
	g_phaseLeft = GetConVarInt(g_sf_roundlimit) + 1;
	g_isCombatPhase = false;
	g_mapRestarted = false;
	
	SetConVarInt(g_info_roundsleft, g_phaseLeft);
	//PrintToChatAndConsoleAll("[SM] DEBUG,SFROUNDSLEFT,Reset(): phaseleft=%d,combatphase=%d",g_phaseLeft,g_isCombatPhase);
}


public OnPluginStart() {
	g_sf_roundlimit = FindConVar("sf_roundlimit");
	if (g_sf_roundlimit == INVALID_HANDLE) {
		PrintToServer("* FATAL ERROR: Failed to find ConVar 'sf_roundlimit'");
		return;
	}
	
	LoadTranslations("plugin.sfroundsleft.cfg");

	g_info_roundsleft = CreateConVar("info_roundsleft", "0", "Rounds left before mapchange.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, false, 0.0);
	// If the convar already exists
	if (g_info_roundsleft==INVALID_HANDLE) {
		g_info_roundsleft = FindConVar("info_roundsleft");
	}
	
	RegConsoleCmd("roundsleft", Command_Roundsleft);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	RegServerCmd("map_restart", Command_MapRestart);
	HookEvent("phase_switch", OnPhaseSwitched, EventHookMode_Post);
	HookConVarChange(g_sf_roundlimit, OnRoundlimitChange);
	Reset();
}

public OnPluginEnd() {
	// maybe another plugin is using this convar, but if not, it has to be 0 to show HLSW that its unknown/disabled, otherwise HLSW would show wrong information.
	SetConVarInt(g_info_roundsleft, 0);
}

/**
 * Reset vars on new map.
 */
public OnMapStart() {
	Reset();
}
/**
 * Reset if map_restart is called with parameter.
 */
public Action:Command_MapRestart(args) {
	//PrintToChatAndConsoleAll("[SM] SFROUNDSLEFT,DEBUG: Command_MapRestart(%d)",args);
	
	if (args) {
		Reset();
		g_mapRestarted = true;
	}
	return Plugin_Continue;
}
/*
 * Refresh phaseLeft-counter on phase-switch.
 *
 * @see:
 *   http://wiki.alliedmods.net/Events_%28SourceMod_Scripting%29
 *   http://wiki.alliedmods.net/Function_Calling_API_%28SourceMod_Scripting%29
 *   sourceforts/resource/modevents.res
 */
public Action:OnPhaseSwitched(Handle:event, const String:name[], bool:dontBroadcast) {
	// by-pass bug in Sourceforts, it's fireing phase_switch with wrong values after map-restart.
	if (g_mapRestarted) {
		g_mapRestarted = false;
		//PrintToChatAndConsoleAll("[SM] SFROUNDSLEFT,DEBUG,OnPhaseSwitched: ignoring phase_switch-values after map_restart!");
		return Plugin_Continue;
	}

	g_phaseLeft = GetEventInt(event, "phase_left") + 1;
	g_isCombatPhase = GetEventBool(event, "newphase");
	
	if (g_isCombatPhase) {
		g_phaseLeft++;
	}
	SetConVarInt(g_info_roundsleft, g_phaseLeft);
	
	//PrintToChatAndConsoleAll("[SM] DEBUG,SFROUNDSLEFT,OnPhaseSwitched(): phaseleft=%d,combatphase=%d",g_phaseLeft,g_isCombatPhase);
	return Plugin_Continue;
}
/*
 * Add the difference of old and new value to phaseLeft-counter on roundlimit-change.
 */
public OnRoundlimitChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_phaseLeft += StringToInt(newValue)-StringToInt(oldValue);
	SetConVarInt(g_info_roundsleft, g_phaseLeft);
}



/**
 * console roundsleft:
 *    Reply only to the client.
 */
public Action:Command_Roundsleft(client, args) {
	if (g_phaseLeft <= 1) {
		if (g_isCombatPhase) {
			PrintToChatAndConsole(client,"%t","This last combatphase before mapchange");
		} else {
			PrintToChatAndConsole(client,"%t","One combatphase before mapchange");
		}
	} else {
		PrintToChatAndConsole(client,"%t","X combatphases before mapchange",g_phaseLeft);
	}
	return Plugin_Handled;
}


/*
 * - say roundsleft:
 *      Reply to all, "say roundsleft" will be shown aswell.
 * - say /roundsleft:
 *      Reply only to the client, "say /roundsleft" will not be shown (silent say / like "console roundsleft").
 *
 * @see http://wiki.alliedmods.net/Commands_%28SourceMod_Scripting%29
 */
public Action:Command_Say(client, args) {
	new String:text[30];
	GetCmdArgString(text, sizeof(text));

	new startidx = 0;
	if (text[0] == '"') {
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"') {
			text[len-1] = '\0';
		}
	}

	if (StrEqual(text[startidx], "roundsleft")) {
		// replay to say-roundsleft after it has been displayed in chat.
		CreateTimer(0.1, DelayedBroadcastReplyAll);
		return Plugin_Continue;
	}
	
	// silent say
	if (StrEqual(text[startidx], "/roundsleft")) {
		return Command_Roundsleft(client,args);
	}
	
	return Plugin_Continue;
}
public Action:DelayedBroadcastReplyAll(Handle:timer) {
	if (g_phaseLeft <= 1) {
		if (g_isCombatPhase) {
			PrintToChatAndConsoleAll("%t","This last combatphase before mapchange");
		} else {
			PrintToChatAndConsoleAll("%t","One combatphase before mapchange");
		}
	} else {
		PrintToChatAndConsoleAll("%t","X combatphases before mapchange",g_phaseLeft);
	}
	
	return Plugin_Stop;
}



/*
 * - say_team roundsleft:
 *      Reply to team, "say roundsleft" will be shown aswell.
 * - say_team /roundsleft:
 *      Reply only to the client, "say_team /roundsleft" will not be shown (silent say / like "console roundsleft").
 *
 * @see http://wiki.alliedmods.net/Commands_%28SourceMod_Scripting%29
 */
public Action:Command_SayTeam(client, args) {
	new String:text[30];
	GetCmdArgString(text, sizeof(text));

	new startidx = 0;
	if (text[0] == '"') {
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"') {
			text[len-1] = '\0';
		}
	}

	if (StrEqual(text[startidx], "roundsleft")) {
		if (client) {
			// replay to teamsay-roundsleft after it has been displayed in chat.
			new Handle:pack = CreateDataPack();
			CreateDataTimer(0.1, DelayedBroadcastReplyTeam,pack);
			WritePackCell(pack, GetClientTeam(client));
			return Plugin_Continue;
		} 
		// server console, rcon, etc..
		return Command_Roundsleft(client,args);
	}
	
	// silent teamsay
	if (StrEqual(text[startidx], "/roundsleft")) {
		return Command_Roundsleft(client,args);
	}
	
	return Plugin_Continue;
}
public Action:DelayedBroadcastReplyTeam(Handle:timer, Handle:pack) {
	new team;
	ResetPack(pack);
	team = ReadPackCell(pack);
	
	if (g_phaseLeft <= 1) {
		if (g_isCombatPhase) {
			PrintToChatAndConsoleTeam(team,"%t","This last combatphase before mapchange");
		} else {
			PrintToChatAndConsoleTeam(team,"%t","One combatphase before mapchange");
		}
	} else {
		PrintToChatAndConsoleTeam(team,"%t","X combatphases before mapchange",g_phaseLeft);
	}
	
	return Plugin_Stop;
}



/**
 * Prints a message to the client's chat, and a copy to client's console.
 *
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock PrintToChatAndConsole(client, const String:format[], any:...) {
	decl String:buffer[192];
	VFormat(buffer, sizeof(buffer), format, 3);
	
	PrintToConsole(client,"%s",buffer);
	if (client) // dont print to chat if it was called from server console.
		PrintToChat(client,"%s",buffer);
}
/**
 * Prints a chat-message to all clients and a copy to all their consoles.
 * And one copy to server-console, (important if using hlsw&co)
 *
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock PrintToChatAndConsoleAll(const String:format[], any:...) {
	new maxClients = GetMaxClients();
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToChatAll("%s",buffer);
	PrintToConsole(0,"%s",buffer);
	
	for (new i = 1; i <= maxClients; i++) {
		if (IsClientInGame(i)) {
			PrintToConsole(i, "%s", buffer);
		}
	}
}
/**
 * Prints a chat-message to all clients and a copy to all their consoles.
 * And one copy to server-console, if the server has run "say roundsleft".
 *
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock PrintToChatAndConsoleTeam(team, const String:format[], any:...) {
	new maxClients = GetMaxClients();
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	// dedicated server console, hlsw-rcon, etc.
	// rcon can read teamsay, so he will get a reply too.
	PrintToConsole(0,"%s",buffer);
	
	for (new i = 1; i <= maxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i)==team) {
			PrintToConsole(i, "%s", buffer);
			PrintToChat(i, "%s", buffer);
		}
	}
}