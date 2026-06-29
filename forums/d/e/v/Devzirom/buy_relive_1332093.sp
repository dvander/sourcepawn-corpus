#include <sourcemod>
#include <cstrike>

#define NAME "CSS: Buy relive"
#define VERSION "1.0"

new Handle:sm_buy_relive_enabled;
new Handle:sm_buy_relive_cost;
new Handle:sm_buy_relive_message;

public Plugin:myinfo = {
	name = NAME,
	author = "Devzirom",
	description = "Allows players to buy relive(respawn)",
	version = VERSION,
	url = "www.sourcemod.com"
}

public OnPluginStart() {
	sm_buy_relive_enabled = CreateConVar("sm_buy_relive_enabled", "1", "\"1\" = \"Buy relive\" plugin is enabled, \"0\" = \"Buy relive\" plugin is disabled");
	sm_buy_relive_cost = CreateConVar("sm_buy_relive_cost", "5000.0", "Set the price for the relive(respawn)", FCVAR_REPLICATED, true, 0.0, true, 16000.0);
	sm_buy_relive_message = CreateConVar("sm_buy_relive_message", "1", "\"1\" = \"Buy relive\" message is enabled, \"0\" = \"Buy relive\" message is disabled");
	
	CreateConVar("sm_buy_relive_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public OnClientPutInServer(client) {
	if(GetConVarInt(sm_buy_relive_message) == 1 && GetConVarInt(sm_buy_relive_enabled) == 1) {
		PrintToChat(client, "[SM] To relive, write to the chat: relive/respawn/buyrelive/buyrespawn");
		PrintToChat(client, "[SM] The price for the relive: %d$", RoundToCeil(GetConVarFloat(sm_buy_relive_cost)));
	}
}

public Action:Command_Say(client, args) {
	if(client == 0 && !IsDedicatedServer())
		client = 1;
	
	if(client < 1 || GetConVarInt(sm_buy_relive_enabled) != 1)
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
		
		new cost = RoundToCeil(GetConVarFloat(sm_buy_relive_cost));
		new money = GetEntProp(client, Prop_Send, "m_iAccount");
		
		if(money < cost) {
			PrintToChat(client, "[SM] You have insufficient funds. The price for the relive: %d$", cost);
			return Plugin_Handled;
		}
		
		SetEntProp(client, Prop_Send, "m_iAccount", money - cost);
		CS_RespawnPlayer(client);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}