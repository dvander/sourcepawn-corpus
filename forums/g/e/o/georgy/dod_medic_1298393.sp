#pragma semicolon 1

#include <sourcemod>

#define PL_VERSION "1.2"

new g_iCount[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_hAmount;
new Handle:g_hCount;
new Handle:g_hMaximum;

public Plugin:myinfo = {
	name        = "DoD Medic",
	author      = "Tsunami",
	description = "Gives players health when they call for a medic",
	version     = PL_VERSION,
	url         = "http://www.charliemaurice.com/plugins/"
};

public OnPluginStart() {
	CreateConVar("dod_medic_version", PL_VERSION, "Gives players health when they call for a medic", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_dodmedic_enabled", "1",  "Enable/disable being able to use !medic.",           FCVAR_PLUGIN);
	g_hAmount   = CreateConVar("sm_dodmedic_amount",  "40", "Amount of health to give when !medic is used.",      FCVAR_PLUGIN);
	g_hCount    = CreateConVar("sm_dodmedic_count",   "1",  "Amount of times per life to be able to use !medic.", FCVAR_PLUGIN);
	g_hMaximum  = CreateConVar("sm_dodmedic_maximum", "30", "Maximum health left to be able to use !medic.",      FCVAR_PLUGIN);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("say",         Command_Say);
	RegConsoleCmd("say_team",    Command_Say);
	RegConsoleCmd("voice_medic", Command_Medic);
	
	LoadTranslations("dodmedic.phrases");
	AutoExecConfig(true, "dod_medic");
	
}

public Action:Command_Medic(client, args) {
	if (GetConVarBool(g_hEnabled)) {
		CreateTimer(0.1, Timer_Medic, client);
	}
	
	return Plugin_Continue;
}

public Action:Command_Say(client, args) {
	new iStart = 0, String:sCommand[64];
	GetCmdArgString(sCommand, sizeof(sCommand));
	
	if (sCommand[strlen(sCommand) - 1] == '"') {
		iStart++;
		sCommand[strlen(sCommand) - 1] = '\0';
	}
	
	if(GetConVarBool(g_hEnabled) && StrEqual(sCommand[iStart], "!medic")) {
		ClientCommand(client, "voice_medic");
		
		return Plugin_Handled;
	} else {
		return Plugin_Continue;
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	g_iCount[GetClientOfUserId(GetEventInt(event, "userid"))] = 0;
}

public Action:Timer_Medic(Handle:timer, any:client) {
	if (IsPlayerAlive(client)) {
		new iCount = GetConVarInt(g_hCount), iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
		if (iHealth <= GetConVarInt(g_hMaximum)) {
			if (g_iCount[client] < iCount) {
				g_iCount[client]++;
				SetEntProp(client, Prop_Send, "m_iHealth", iHealth + GetConVarInt(g_hAmount));
				PrintToChat(client, "[DoD Medic] %t", "Roger");
				PrintToChat(client, "[DoD Medic] %t", "UsedHealthKits", g_iCount[client], iCount); //You've used %d out of %d health kits!", g_iCount[client], iCount);
			} else {
				PrintToChat(client, "[DoD Medic] %t", "NoHealthKits"); //You've used up all your health kits!");
			}
		} else {
			PrintToChat(client, "[DoD Medic] %t", "QueryHealth");  //That's merely a flesh wound!");
		}
	} else {
		PrintToChat(client, "[DoD Medic] %t", "NoHealthKits"); //Medics can't raise the dead you know!");
	}
	
	return Plugin_Handled;
}