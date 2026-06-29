#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "Money balance",
	author = "mad_hamster",
	description = "Gives extra money to a certain team on certain maps",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};


// Plugin CVars
static Handle:moneybalance;
static Handle:moneybalance_maxcash;
static Handle:moneybalance_settings;


// Settings (parsed from moneybalance_settings)
static String:maps[256][20];
static team_ids[256];
static extra_money[256];
static num_settings = 0;

new g_iAccount = -1;


public OnPluginStart() {
	CreateConVar("moneybalance_version", PLUGIN_VERSION, "moneybalance version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	moneybalance          = CreateConVar("moneybalance",           "1",   "Enable/disable moneybalance plugin.");
	moneybalance_maxcash  = CreateConVar("moneybalance_maxcash",   "16000", "Do not increase player cash above this threshold");
	moneybalance_settings = CreateConVar("moneybalance_settings",  "",   "Define extra money on certain maps, e.g. \"de_aztec:2:2000, de_cbble:2:2000\" will give 2000$ extra on aztec and cbble maps to team #2 (Terrorists in CSS)");

	AutoExecConfig(); // create config file if doesn't exist
	HookConVarChange(moneybalance_settings,  refresh_settings);
	decl String:str[4096];
	GetConVarString(moneybalance_settings, str, sizeof(str));
	refresh_settings(moneybalance_settings, "", str);
	HookEvent("round_start", on_round_start)
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
		SetFailState("Can't find money props offset");
}



public refresh_settings(Handle:cvar, const String:oldval[], const String:newval[]) {
	num_settings = 0;
	decl String:setting[30];
	new pos, size = strlen(newval);
	while (pos < size) {
		new offset = SplitString(newval[pos], ",", setting, sizeof(setting));
		if (offset == -1) {
			strcopy(setting, sizeof(setting), newval[pos]);
			pos = size;
		}
		else pos += offset;
		TrimString(setting);
		
		decl String:strings[32][20];
		new parts = ExplodeString(setting, ":", strings, sizeof(strings), sizeof(strings[]));
		if (   parts != 3
		    || StringToIntEx(strings[1], team_ids[num_settings]) == 0
		    || StringToIntEx(strings[2], extra_money[num_settings]) == 0)
		{
			LogError("Can't parse '%s'; ignoring (format needs to be 'map_name:team_id:extra_money')", setting);
		}
		else maps[num_settings++] = strings[0];
	}
}



public on_round_start(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(moneybalance))
		return;
	new max_cash = GetConVarInt(moneybalance_maxcash);
		
	decl String:current_map[30];
	GetCurrentMap(current_map, sizeof(current_map));
	
	for (new i=0; i<num_settings; ++i) {
		if (strcmp(current_map, maps[i]) == 0 && team_ids[i] < GetTeamCount()) {
			decl String:team_name[20];
			GetTeamName(team_ids[i], team_name, sizeof(team_name));
			PrintToChatAll("\x03Money balancer: team %s awarded extra \x01%d$", team_name, extra_money[i]);
			
			for (new client=1; client<=MaxClients; ++client) {
				if (IsClientInGame(client) && GetClientTeam(client) == team_ids[i]) {
					new cash = GetEntData(client, g_iAccount);
					SetEntData(client, g_iAccount, cash + (cash >= max_cash ? 0 :
						(max_cash - cash > extra_money[i] ? extra_money[i] : (max_cash - cash))));
				}
			}
		}
	}
}
