#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "DB stats",
	author = "mad_hamster",
	description = "Writes server statistics to a database",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};


// We cache the server IP and port for faster access
static String:server_ip[20];
static String:server_port[10];


// Plugin CVars
static Handle:dbstats;
static Handle:dbstats_log_empty;
static Handle:dbstats_cvars;
static Handle:dbstats_gameplay;
static Handle:dbstats_teams;
static Handle:dbstats_network;


// Timers
static Handle:dbstats_gameplay_sample_timer = INVALID_HANDLE;
static Handle:dbstats_teams_sample_timer    = INVALID_HANDLE;
static Handle:dbstats_network_sample_timer  = INVALID_HANDLE;


// Database handles
static Handle:database;


// Monitored CVars
static Handle:monitored_cvars[256];
static num_monitored_cvars = 0;



public OnPluginStart() {
	decl String:error[255];
	database = SQL_Connect("dbstats", true, error, sizeof(error));
	if (database == INVALID_HANDLE) {
		SetFailState("dbstats plugin couldn't connect to database. Error: %s", error);
		return;
	}

	GetConVarString(FindConVar("hostip"),   server_ip,   sizeof(server_ip));
	GetConVarString(FindConVar("hostport"), server_port, sizeof(server_port));

	CreateConVar("dbstats_version", PLUGIN_VERSION, "DBStats version",  FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	dbstats           = CreateConVar("dbstats",           "1",   "Enable/disable DBStats plugin.");
	dbstats_log_empty = CreateConVar("dbstats_log_empty", "0",   "Enable/disable logging when the server has 0 human players (to save space).");
	dbstats_cvars     = CreateConVar("dbstats_cvars",     "hostname, sv_cheats",   "List of CVars to monitor and log whenever their value changes.");
	dbstats_gameplay  = CreateConVar("dbstats_gameplay",  "600", "Enable logging server gameplay data (# of clients, kills, deaths, etc). 0=off, anything else is the number of seconds between samples.");
	dbstats_teams     = CreateConVar("dbstats_teams",     "600", "Enable logging server gameplay data per team (team score, # of clients, # of bots, etc). 0=off, anything else is the number of seconds between samples.");
	dbstats_network   = CreateConVar("dbstats_network",   "600", "Enable logging server network data (avg ping to clients, packet loss, choke, etc). 0=off, anything else is the number of seconds between samples.");

	AutoExecConfig(); // create config file if doesn't exist

	HookConVarChange(dbstats_cvars,    refresh_monitored_cvars);
	HookConVarChange(dbstats_gameplay, refresh_gameplay_sample_timer);
	HookConVarChange(dbstats_teams,    refresh_teams_sample_timer);
	HookConVarChange(dbstats_network,  refresh_network_sample_timer);

	decl String:str[4096];
	GetConVarString(dbstats_cvars, str, sizeof(str));
	refresh_monitored_cvars      (dbstats_cvars,    "", str);
	refresh_gameplay_sample_timer(dbstats_gameplay, "", "");
	refresh_teams_sample_timer   (dbstats_teams,    "", "");
	refresh_network_sample_timer (dbstats_network,  "", "");

	GetGameFolderName(str, sizeof(str));
	write_setting("game_folder", str);
	GetConVarString(FindConVar("hostname"), str, sizeof(str));
	write_setting("hostname", str);
	write_current_map();
}



public refresh_monitored_cvars(Handle:cvar, const String:oldval[], const String:newval[]) {
	for (; num_monitored_cvars > 0; --num_monitored_cvars)
		UnhookConVarChange(monitored_cvars[num_monitored_cvars - 1], monitored_cvar_changed);

	decl String:str[30];
	new pos, size = strlen(newval);
	while (pos < size) {
		new offset = SplitString(newval[pos], ",", str, sizeof(str));
		if (offset == -1) {
			strcopy(str, sizeof(str), newval[pos]);
			pos = size;
		}
		else pos += offset;
		TrimString(str);

		new Handle:monitored_cvar = FindConVar(str);
		if (monitored_cvar == INVALID_HANDLE)
			LogError("Can't monitor non-existent cvar '%s'", str);                                    
		else {
			monitored_cvars[num_monitored_cvars++] = monitored_cvar;
			HookConVarChange(monitored_cvar, monitored_cvar_changed);
			decl String:value[255];
			GetConVarString(monitored_cvar, value, sizeof(value))
			write_setting(str, value);
		}
	}
}



public refresh_gameplay_sample_timer(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (dbstats_gameplay_sample_timer != INVALID_HANDLE) {
		CloseHandle(dbstats_gameplay_sample_timer);
		dbstats_gameplay_sample_timer = INVALID_HANDLE;
	}

	if (GetConVarInt(dbstats_gameplay) > 0)
		dbstats_gameplay_sample_timer = CreateTimer(
			GetConVarFloat(dbstats_gameplay), collect_gameplay_data, _, TIMER_REPEAT);
}



public refresh_teams_sample_timer(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (dbstats_teams_sample_timer != INVALID_HANDLE) {
		CloseHandle(dbstats_teams_sample_timer);
		dbstats_teams_sample_timer = INVALID_HANDLE;
	}

	if (GetConVarInt(dbstats_teams) > 0)
		dbstats_teams_sample_timer = CreateTimer(
			GetConVarFloat(dbstats_teams), collect_teams_data, _, TIMER_REPEAT);
}



public refresh_network_sample_timer(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (dbstats_network_sample_timer != INVALID_HANDLE) {
		CloseHandle(dbstats_network_sample_timer);
		dbstats_network_sample_timer = INVALID_HANDLE;
	}

	if (GetConVarInt(dbstats_network) > 0)
		dbstats_network_sample_timer = CreateTimer(
			GetConVarFloat(dbstats_network), collect_network_data, _, TIMER_REPEAT);
}



public Action:collect_gameplay_data(Handle:timer) {
	static bool:last_record_empty = false;
	if (!GetConVarBool(dbstats))
		return Plugin_Handled;

	new clients, fake_clients, ingame_clients;
	new total_kills, fake_kills, total_deaths, Float:total_conn_time;
	new bool:have_human_client = false;

	for (new client=1; client<=MaxClients; ++client) {
		if (IsClientConnected(client))
			++clients;
		if (IsClientInGame(client)) {
			++ingame_clients;
			if (IsFakeClient(client)) {
				++fake_clients;
				fake_kills += GetClientFrags(client);
			}
			else {
				total_conn_time += GetClientTime(client);
				have_human_client = true;
			}

			total_kills  += GetClientFrags(client);
			total_deaths += GetClientDeaths(client);
		}
	}

	if (have_human_client)
		last_record_empty = false;
	else if (last_record_empty) {
		if (GetConVarBool(dbstats_log_empty) == false)
			return Plugin_Handled;
	}
	else last_record_empty = true;

	decl String:query[255];
	new now = GetTime();
	Format(query, sizeof(query), "INSERT INTO gameplay (ip, port, time, clients, ingame_clients, bots, kills, bot_kills, deaths, connected_mins) VALUES(%s, %s, FROM_UNIXTIME(%d), %d, %d, %d, %d, %d, %d, %f)",
		server_ip, server_port, now, clients, ingame_clients, fake_clients,
		total_kills, fake_kills, total_deaths, total_conn_time / 60.0);
	SQL_TQuery(database, validate_insert_gameplay, query, now);

	return Plugin_Handled;
}



public validate_insert_gameplay(Handle:owner, Handle:hndl, const String:error[], any:query_time) {
	static last_failure = 0;
	if (hndl == INVALID_HANDLE && query_time - last_failure >= 3600) {
		LogError("Insert into gameplay table failed with error: '%s'; subsequent warnings supressed for 1 hour", error);
		last_failure = query_time;
	}
}



public Action:collect_teams_data(Handle:timer) {
	static bool:last_record_empty = false;
	if (!GetConVarBool(dbstats))
		return Plugin_Handled;

	new num_teams = GetTeamCount();
	new ingame_clients[num_teams], fake_clients[num_teams];
	new total_kills[num_teams], fake_kills[num_teams], total_deaths[num_teams];
	new Float:total_conn_time[num_teams];
	new bool:have_human_client = false;

	// add each client's stats to its respective team's stats
	for (new client=1; client<=MaxClients; ++client) {
		if (IsClientInGame(client)) {
			new team = GetClientTeam(client);
			++ingame_clients[team];
			last_record_empty = false;
			if (IsFakeClient(client)) {
				++fake_clients[team];
				fake_kills[team] += GetClientFrags(client);
			}
			else {
				total_conn_time[team] += GetClientTime(client);
				have_human_client = true;
			}

			total_kills[team] += GetClientFrags(client);
			total_deaths[team] += GetClientDeaths(client);
		}
	}

	if (have_human_client)
		last_record_empty = false;
	else if (last_record_empty) {
		if (GetConVarBool(dbstats_log_empty) == false)
			return Plugin_Handled;
	}
	else last_record_empty = true;

	for (new team=0; team<num_teams; ++team) {
		decl String:query[255], String:team_name[15];
		GetTeamName(team, team_name, sizeof(team_name));
		new now = GetTime();
		Format(query, sizeof(query), "INSERT INTO teams (ip, port, time, id, name, score, ingame_clients, bots, kills, bot_kills, deaths, connected_mins) VALUES(%s, %s, FROM_UNIXTIME(%d), %d, '%s', %d, %d, %d, %d, %d, %d, %f)",
			server_ip, server_port, now, team, team_name, GetTeamScore(team),
			ingame_clients[team], fake_clients[team], total_kills[team], fake_kills[team],
			total_deaths[team], total_conn_time[team] / 60.0);
		SQL_TQuery(database, validate_insert_teams, query, now);
	}

	return Plugin_Handled;
}



public validate_insert_teams(Handle:owner, Handle:hndl, const String:error[], any:query_time) {
	static last_failure = 0;
	if (hndl == INVALID_HANDLE && query_time - last_failure >= 3600) {
		LogError("Insert into teams table failed with error: '%s'; subsequent warnings supressed for 1 hour", error);
		last_failure = query_time;
	}
}



addvalues(Float:val, &Float:sum, &Float:squared_sum) {
	sum += val;
	squared_sum += val * val;
}



Float:get_stddev(num_samples, Float:sum_of_samples, Float:sum_of_square_of_samples) {
	return SquareRoot(
		((num_samples * sum_of_square_of_samples) - (sum_of_samples * sum_of_samples))
		/ (num_samples * (num_samples-1)));
}




public Action:collect_network_data(Handle:timer) {
	static bool:last_record_empty = false;
	if (!GetConVarBool(dbstats))
		return Plugin_Handled;

	new ingame_humans;
	new Float:data_in_sum,    Float:data_in_sqr,    Float:data_out_sum,    Float:data_out_sqr;
	new Float:packets_in_sum, Float:packets_in_sqr, Float:packets_out_sum, Float:packets_out_sqr;
	new                                             Float:latency_out_sum, Float:latency_out_sqr;
	new Float:loss_in_sum,    Float:loss_in_sqr,    Float:loss_out_sum,    Float:loss_out_sqr;
	new Float:choke_in_sum,   Float:choke_in_sqr,   Float:choke_out_sum,   Float:choke_out_sqr;

	for (new client=1; client<=MaxClients; ++client) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			++ingame_humans;
			addvalues(GetClientAvgData   (client, NetFlow_Incoming), data_in_sum,     data_in_sqr);
			addvalues(GetClientAvgData   (client, NetFlow_Outgoing), data_out_sum,    data_out_sqr);
			addvalues(GetClientAvgPackets(client, NetFlow_Incoming), packets_in_sum,  packets_in_sqr);
			addvalues(GetClientAvgPackets(client, NetFlow_Outgoing), packets_out_sum, packets_out_sqr);
			addvalues(GetClientAvgLatency(client, NetFlow_Outgoing), latency_out_sum, latency_out_sqr);
			addvalues(GetClientAvgLoss   (client, NetFlow_Incoming), loss_in_sum,     loss_in_sqr);
			addvalues(GetClientAvgLoss   (client, NetFlow_Outgoing), loss_out_sum,    loss_out_sqr);
			addvalues(GetClientAvgChoke  (client, NetFlow_Incoming), choke_in_sum,    choke_in_sqr);
			addvalues(GetClientAvgChoke  (client, NetFlow_Outgoing), choke_out_sum,   choke_out_sqr);
		}
	}

	new Float:server_in, Float:server_out;
	GetServerNetStats(server_in, server_out);
	decl String:query[1024];
	new now = GetTime();

	if (ingame_humans > 0)
		last_record_empty = false;
	else if (last_record_empty) {
		if (GetConVarBool(dbstats_log_empty) == false)
			return Plugin_Handled;
	}
	else {
		last_record_empty = true;
		Format(query, sizeof(query), "INSERT INTO network (ip, port, time, num_clients, s_data_in, s_data_out, c_dataflow_in, c_dataflow_in_sd, c_dataflow_out, c_dataflow_out_sd, c_packets_in, c_packets_in_sd, c_packets_out, c_packets_out_sd, c_latency_out, c_latency_out_sd, c_loss_in, c_loss_in_sd, c_loss_out, c_loss_out_sd, c_choke_in, c_choke_in_sd, c_choke_out, c_choke_out_sd) VALUES(%s, %s, FROM_UNIXTIME(%d), %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)",
			server_ip, server_port, now, ingame_humans, server_in, server_out,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
		SQL_TQuery(database, validate_insert_network, query, now);
		return Plugin_Handled;
	}

	Format(query, sizeof(query), "INSERT INTO network (ip, port, time, num_clients, s_data_in, s_data_out, c_dataflow_in, c_dataflow_in_sd, c_dataflow_out, c_dataflow_out_sd, c_packets_in, c_packets_in_sd, c_packets_out, c_packets_out_sd, c_latency_out, c_latency_out_sd, c_loss_in, c_loss_in_sd, c_loss_out, c_loss_out_sd, c_choke_in, c_choke_in_sd, c_choke_out, c_choke_out_sd) VALUES(%s, %s, FROM_UNIXTIME(%d), %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)",
		server_ip, server_port, now, ingame_humans, server_in, server_out,
		data_in_sum     /ingame_humans, get_stddev(ingame_humans, data_in_sum,     data_in_sqr),
		data_out_sum    /ingame_humans, get_stddev(ingame_humans, data_out_sum,    data_out_sqr),
		packets_in_sum  /ingame_humans, get_stddev(ingame_humans, packets_in_sum,  packets_in_sqr),
		packets_out_sum /ingame_humans, get_stddev(ingame_humans, packets_out_sum, packets_out_sqr),
		latency_out_sum * 1000 /ingame_humans, get_stddev(ingame_humans, latency_out_sum, latency_out_sqr) * 1000,
		loss_in_sum     /ingame_humans, get_stddev(ingame_humans, loss_in_sum,     loss_in_sqr),
		loss_out_sum    /ingame_humans, get_stddev(ingame_humans, loss_out_sum,    loss_out_sqr),
		choke_in_sum    /ingame_humans, get_stddev(ingame_humans, choke_in_sum,    choke_in_sqr),
		choke_out_sum   /ingame_humans, get_stddev(ingame_humans, choke_out_sum,   choke_out_sqr));
	SQL_TQuery(database, validate_insert_network, query, now);

	return Plugin_Handled;
}



public validate_insert_network(Handle:owner, Handle:hndl, const String:error[], any:query_time) {
	static last_failure = 0;
	if (hndl == INVALID_HANDLE && query_time - last_failure >= 3600) {
		LogError("Insert into network table failed with error: '%s'; subsequent warnings supressed for 1 hour", error);
		last_failure = query_time;
	}
}



public monitored_cvar_changed(Handle:cvar, const String:oldval[], const String:newval[]) {
	decl String:name[255];
	GetConVarName(cvar, name, sizeof(name));
	write_setting(name, newval);
}



public OnMapStart() {
	write_current_map();
}



write_current_map() {
	decl String:map_name[30];
	GetCurrentMap(map_name, sizeof(map_name));
	write_setting("current_map", map_name);
}



write_setting(const String:name[], const String:value[]) {
	if (GetConVarBool(dbstats)) {
		decl String:query[512];
		new now = GetTime();
		Format(query, sizeof(query), "INSERT INTO settings (ip, port, time, property, value) VALUES(%s, %s, FROM_UNIXTIME(%d), '%s', '%s')",
			server_ip, server_port, now, name, value);
		SQL_TQuery(database, validate_insert_setting, query, now);
	}
}



public validate_insert_setting(Handle:owner, Handle:hndl, const String:error[], any:query_time) {
	static last_failure = 0;
	if (hndl == INVALID_HANDLE && query_time - last_failure >= 3600) {
		LogError("Insert into settings table failed with error: '%s'; subsequent warnings supressed for 1 hour", error);
		last_failure = query_time;
	}
}
