#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Round end slay",
	author = "mad_hamster",
	description = "Forces round to end when round time reaches zero by slaying all players",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};


static Handle:timer = INVALID_HANDLE;
static notification_number;



public OnPluginStart() {
	CreateConVar("round_end_slay_ver", PLUGIN_VERSION, "Round end slay version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_start", on_round_start);
}



public on_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	if (timer != INVALID_HANDLE) // round restarted before end
		CloseHandle(timer);
	new Float:length = GetConVarFloat(FindConVar("mp_roundtime")) * 60.0 - 6.0;
	LogMessage("End round slay in %f seconds", length);
	notification_number = 5;
	timer = CreateTimer(length, on_round_time_end);
}



public OnMapEnd() {
	if (timer != INVALID_HANDLE) {
		CloseHandle(timer);
		timer = INVALID_HANDLE;
	}
}



public Action:on_round_time_end(Handle:timer_) {
	if (notification_number > 0) {
		PrintCenterTextAll("Round ending in %d seconds", notification_number);
		timer = CreateTimer(1.0, on_round_time_end);
		--notification_number;
	}
	else {
		timer = INVALID_HANDLE;
		LogMessage("Time up");
		for (new client=1; client<=MaxClients; ++client) {
			if (IsClientInGame(client) && !IsClientObserver(client) && IsPlayerAlive(client)) {
				new deaths = GetEntProp(client, Prop_Data, "m_iDeaths");
				SetEntProp(client, Prop_Data, "m_iDeaths", deaths-1);
				new kills = GetEntProp(client, Prop_Data, "m_iFrags");
				SetEntProp(client, Prop_Data, "m_iFrags", kills+1);
				ForcePlayerSuicide(client);
			}
		}
	}
}
