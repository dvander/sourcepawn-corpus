#include <sourcemod>
#include <cstrike>

#define NAME "CSS: Buy relive"
#define VERSION "2.0 beta"

//Cvars Handlers
new Handle:sm_buy_relive_enabled;
new Handle:sm_buy_relive_cost;
new Handle:sm_buy_relive_message;
new Handle:sm_buy_relive_buytime;
new Handle:mp_buytime;
//Times Handlers
new Handle:PlayerBuyTimer[MAXPLAYERS+1] = INVALID_HANDLE; // Individual buytimers
new Handle:BuyTimer = INVALID_HANDLE; // Global buytimer
//
new bool:RoundEnd = false; // Status of Round end event
new bool:buy_relive_enabled = true; // Status of plugin (enabled / disabled)
new bool:buy_relive_message = true; // Status of plugin message (enabled / disabled)
new buy_relive_cost; // Value of cvar sm_buy_relive_cost
new Float:buy_relive_buytime; // Value of cvar sm_buy_relive_buytime
new Float:buytime; // Value of cvar mp_buytime;

public Plugin:myinfo = {
	name = NAME,
	author = "Devzirom",
	description = "Allows players to buy relive(respawn)",
	version = VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart() {
	sm_buy_relive_enabled = CreateConVar("sm_buy_relive_enabled", "1", "\"1\" = \"Buy relive\" plugin is enabled, \"0\" = \"Buy relive\" plugin is disabled");
	sm_buy_relive_cost = CreateConVar("sm_buy_relive_cost", "5000.0", "Set the price for the relive(respawn)", FCVAR_NOTIFY, true, 0.0, true, 16000.0);
	sm_buy_relive_message = CreateConVar("sm_buy_relive_message", "1", "\"1\" = \"Buy relive\" message is enabled, \"0\" = \"Buy relive\" message is disabled");
	sm_buy_relive_buytime = CreateConVar("sm_buy_relive_buytime", "0", "Time in seconds in which flow players can buy items again", FCVAR_NOTIFY);
	mp_buytime = FindConVar("mp_buytime");
	
	CreateConVar("sm_buy_relive_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	HookEvent("round_freeze_end", EventFreezeEnd, EventHookMode_Post);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);

	HookConVarChange(sm_buy_relive_enabled, ConVarChanged);
	HookConVarChange(sm_buy_relive_buytime, ConVarChanged);
	HookConVarChange(sm_buy_relive_message, ConVarChanged);
	HookConVarChange(sm_buy_relive_cost, ConVarChanged);
	HookConVarChange(mp_buytime, ConVarChanged);
	
	// Backup of cvar mp_buytime
	buytime = GetConVarFloat(mp_buytime);
}

public OnPluginEnd() {
	RoundEnd = false;
	
	// Remove all timers
	StopBuyTimer(BuyTimer, 0);
	
	for(new i=1; i<MAXPLAYERS+1; i++) {
		StopBuyTimer(PlayerBuyTimer[i], i);
	}
	
	// Set cvar mp_buytime
	SetConVarFloat(mp_buytime, buytime, true);
}

public OnMapStart() {
	buy_relive_enabled = (GetConVarInt(sm_buy_relive_enabled) == 1);
	buy_relive_message = (GetConVarInt(sm_buy_relive_message) == 1);
	buy_relive_cost = RoundToCeil(GetConVarFloat(sm_buy_relive_cost));
	buy_relive_buytime = GetConVarFloat(sm_buy_relive_buytime);
	
	if(buy_relive_enabled)
		SetConVarFloat(mp_buytime, 1440.0, true);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(convar == sm_buy_relive_enabled) {
		buy_relive_enabled = (GetConVarInt(sm_buy_relive_enabled) == 1);
		
		if(buy_relive_enabled)
			OnMapStart();
		else
			OnPluginEnd();
	} else if(convar == mp_buytime)
		buytime = GetConVarFloat(mp_buytime);
	else 
		OnMapStart();
}

public OnClientPutInServer(client) {
	if(buy_relive_enabled && buy_relive_message) {
		PrintToChat(client, "[SM] To relive, write to the chat: relive/respawn/buyrelive/buyrespawn");
		PrintToChat(client, "[SM] The price for the relive: %d$", buy_relive_cost);
	}
}

public OnGameFrame() {
	if(!buy_relive_enabled)
		return;
	
	if(RoundEnd || BuyTimer != INVALID_HANDLE)
		return;
	
	for(new i=1; i<=MaxClients; i++) {
		if(!IsClientInGame(i))
			continue;
			
		if(!IsPlayerAlive(i) || PlayerBuyTimer[i] != INVALID_HANDLE)
			continue;
			
		SetEntProp(i, Prop_Send, "m_bInBuyZone", 0);
	}
}

public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!buy_relive_enabled)
		return Plugin_Continue;
	
	StopBuyTimer(BuyTimer, 0);
	
	RoundEnd = true;
	
	return Plugin_Continue;
}

public Action:EventFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if(!buy_relive_enabled)
		return Plugin_Continue;
	
	StopBuyTimer(BuyTimer, 0);
	BuyTimer = CreateTimer(buytime * 60.0, StopBuyTimer, 0);
	
	for(new i=1; i<MAXPLAYERS+1; i++) {
		if(PlayerBuyTimer[i] != INVALID_HANDLE) {
			KillTimer(PlayerBuyTimer[i]);
			PlayerBuyTimer[i] = INVALID_HANDLE;
		}
	}
	
	RoundEnd = false;
	
	return Plugin_Continue;
}

public Action:StopBuyTimer(Handle:timer, any:client) {
	if(!client) {
		if(BuyTimer != INVALID_HANDLE) {
			KillTimer(BuyTimer);
			BuyTimer = INVALID_HANDLE;
		}
	} else {
		if(PlayerBuyTimer[client] != INVALID_HANDLE) {
			KillTimer(PlayerBuyTimer[client]);
			PlayerBuyTimer[client] = INVALID_HANDLE;
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args) {
	if(client == 0 && !IsDedicatedServer())
		client = 1;
	
	if(client < 1 || !buy_relive_enabled || RoundEnd)
		return Plugin_Continue;
		
	decl String:command[32], String:value[32];
	
	GetCmdArg(0, command, sizeof(command));
	GetCmdArg(1, value, sizeof(value));
	
	if(StrEqual(value, "relive") || StrEqual(value, "respawn")
	|| StrEqual(value, "buyrespawn") || StrEqual(value, "buyrelive")) {
		new team = GetClientTeam(client);
		
		if(team != CS_TEAM_CT && team != CS_TEAM_T) {
			PrintToChat(client, "[SM] This command is not available to spectators");
			return Plugin_Handled;
		}
		
		if(IsPlayerAlive(client)) {
			PrintToChat(client, "[SM] Life is short, try later");
			return Plugin_Handled;
		}
		
		new money = GetEntProp(client, Prop_Send, "m_iAccount");
		
		if(money < buy_relive_cost) {
			PrintToChat(client, "[SM] You have insufficient funds. The price for the relive: %d$", buy_relive_cost);
			return Plugin_Handled;
		}
		
		if(PlayerBuyTimer[client] != INVALID_HANDLE) {
			KillTimer(PlayerBuyTimer[client]);
			PlayerBuyTimer[client] = INVALID_HANDLE;
		}
		
		PlayerBuyTimer[client] = CreateTimer(buy_relive_buytime, StopBuyTimer, client);
		SetEntProp(client, Prop_Send, "m_iAccount", money - buy_relive_cost);
		CS_RespawnPlayer(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}