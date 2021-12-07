#include <sourcemod>
#include <sdktools_functions>
#include <geoip>



public Plugin myinfo =
{
	name = "playerinfo",
	author = "91346706501435897134",
	description = "Prints detailed player information to console",
	version = "1.1",
};



public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_playerinfo", cmd_playerinfo, ADMFLAG_GENERIC);
}



public Action cmd_playerinfo(int client, int args)
{
	char target[MAX_NAME_LENGTH];
	
	if (args < 1)
	{
		ReplyToCommand(client, ">> usage: sm_playerinfo <name|#userid>");
		
		return Plugin_Handled;
	}
	
	GetCmdArg(1, target, sizeof(target));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, ">> no matching client was found.");
		return Plugin_Handled;
	}
	
	if (strcmp(target, "@all") == 0)
	{
		PrintToConsole(client, ">> usage of @all is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@!me") == 0)
	{
		PrintToConsole(client, ">> usage of @!me is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@humans") == 0)
	{
		PrintToConsole(client, ">> usage of @humans is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@bots") == 0)
	{
		PrintToConsole(client, ">> usage of @bots is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@alive") == 0)
	{
		PrintToConsole(client, ">> usage of @alive is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@dead") == 0)
	{
		PrintToConsole(client, ">> usage of @dead is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@blue") == 0)
	{
		PrintToConsole(client, ">> usage of @blue is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@red") == 0)
	{
		PrintToConsole(client, ">> usage of @red is disabled");
		
		return Plugin_Handled;
	}
	if (strcmp(target, "@spec") == 0)
	{
		PrintToConsole(client, ">> usage of @spec is disabled");
		
		return Plugin_Handled;
	}
	
	char client_alias[MAX_NAME_LENGTH];
	char client_steamid64[100];
	char client_steamid3[100];
	int client_serial;
	int client_id;
	char client_ip_and_port[100];
	char client_ip[100];
	char client_full_country_name[45];
	float f_client_connection_time;
	char s_client_connection_time[255];
	int i_client_connection_time;
	int client_time_seconds;
	int client_time_minutes;
	int client_time_hours;
	float client_latency;
	float client_avg_latency;
	float client_avg_choke;
	int client_data_rate;
	float client_avg_data;
	float client_avg_packets;
	float client_avg_loss;
	bool client_alive;
	bool client_timing_out;
	float client_pos[3];
	float client_angles[3];
	char client_model[100];
	float client_max_size_vector[3];
	float client_min_size_vector[3];
	char client_weapon[100];
	int client_aim_target;
	char client_aim_target_name[MAX_NAME_LENGTH];
	int client_team_id;
	char client_team_name[100];
	int client_health;
	int kills;
	int deaths;
	float kd_ratio;
	
	for (int i = 0; i < target_count; i++)
	{
		GetClientName(target_list[i], client_alias, MAX_NAME_LENGTH);
		GetClientAuthId(target_list[i], AuthId_SteamID64, client_steamid64, sizeof(client_steamid64), true);
		GetClientAuthId(target_list[i], AuthId_Steam3, client_steamid3, sizeof(client_steamid3), true);
		client_serial = GetClientSerial(target_list[i]);
		client_id = GetClientUserId(target_list[i]);
		GetClientIP(target_list[i], client_ip_and_port, sizeof(client_ip_and_port), false);
		GetClientIP(target_list[i], client_ip, sizeof(client_ip), true);
		GeoipCountry(client_ip, client_full_country_name, sizeof(client_full_country_name));
		f_client_connection_time = GetClientTime(target_list[i]);
		FloatToString(f_client_connection_time, s_client_connection_time, sizeof(s_client_connection_time));
		i_client_connection_time = StringToInt(s_client_connection_time);
		client_time_seconds = i_client_connection_time % 60;
		client_time_minutes = (i_client_connection_time / 60) % 60;
		client_time_hours = (client_time_minutes / 3600) % 3600;
		client_latency = GetClientLatency(target_list[i], NetFlow_Both);
		client_avg_latency = GetClientAvgLatency(target_list[i], NetFlow_Both);
		client_avg_choke = GetClientAvgChoke(target_list[i], NetFlow_Both);
		client_data_rate = GetClientDataRate(target_list[i]);
		client_avg_data = GetClientAvgData(target_list[i], NetFlow_Both);
		client_avg_packets = GetClientAvgPackets(target_list[i], NetFlow_Both);
		client_avg_loss = GetClientAvgLoss(target_list[i], NetFlow_Both);
		client_alive = IsPlayerAlive(target_list[i]);
		client_timing_out = IsClientTimingOut(target_list[i]);
		GetClientAbsOrigin(target_list[i], client_pos);
		GetClientEyeAngles(target_list[i], client_angles);
		GetClientModel(target_list[i], client_model, sizeof(client_model));
		GetClientMaxs(target_list[i], client_max_size_vector);
		GetClientMins(target_list[i], client_min_size_vector);
		GetClientWeapon(target_list[i], client_weapon, sizeof(client_weapon));
		if (strcmp(client_weapon, "") == 0)
		{
			strcopy(client_weapon, sizeof(client_weapon), "< none >");
		}
		client_aim_target = GetClientAimTarget(target_list[i], true);
		if (client_aim_target > 0)
		{
			GetClientName(client_aim_target, client_aim_target_name, sizeof(client_aim_target_name));
		}
		else
		{
			strcopy(client_aim_target_name, sizeof(client_aim_target_name), "< none >");
		}
		client_team_id = GetClientTeam(target_list[i]);
		GetTeamName(client_team_id, client_team_name, sizeof(client_team_name));
		client_health = GetClientHealth(target_list[i]);
		kills = GetClientFrags(target_list[i]);
		deaths = GetClientDeaths(target_list[i]);
		kd_ratio = float(kills) / float(deaths);
		
		PrintToConsole(client, ">>\talias\t\t\t\t%s\n>>\tSteamID64\t\t\t%s\n>>\tSteamID3\t\t\t%s\n>>\tserial\t\t\t\t%d\n>>\tuser id\t\t\t\t%d\n>>\tip + port\t\t\t%s\n>>\tfull country name\t\t%s\n>>\tcurrent connection time\t\t%d:%d:%d\n>>\tlatency\t\t\t\t%f\n>>\tavg latency\t\t\t%f\n>>\tavg choke\t\t\t%f\n>>\tdata rate (bytes/sec)\t\t%d\n>>\tavg data (bytes/sec)\t\t%f\n>>\tavg packets/sec\t\t\t%f\n>>\tavg packet loss\t\t\t%f\n>>\tis client alive\t\t\t%d\n>>\tis client timing out\t\t%d\n>>\tcurrent pos\t\t\t%f %f %f\n>>\tcurrent angle\t\t\t%f %f %f\n>>\tcurrent model\t\t\t%s\n>>\tmax vector\t\t\t%f %f %f\n>>\tmin vector\t\t\t%f %f %f\n>>\tcurrent weapon\t\t\t%s\n>>\tcurrent aim target id\t\t%d\n>>\tcurrent aim target name\t\t%s\n>>\tcurrent team id\t\t\t%d\n>>\tcurrent team name\t\t%s\n>>\tcurrent health\t\t\t%d\n>>\tcurrent frags\t\t\t%d\n>>\tcurrent deaths\t\t\t%d\n>>\tcurrent k/d ratio\t\t%f",
								client_alias,
								client_steamid64,
								client_steamid3,
								client_serial,
								client_id,
								client_ip_and_port,
								client_full_country_name,
								client_time_hours,
								client_time_minutes,
								client_time_seconds,
								client_latency,
								client_avg_latency,
								client_avg_choke,
								client_data_rate,
								client_avg_data,
								client_avg_packets,
								client_avg_loss,
								client_alive,
								client_timing_out,
								client_pos[0],
								client_pos[1],
								client_pos[2],
								client_angles[0],
								client_angles[1],
								client_angles[2],
								client_model,
								client_max_size_vector[0],
								client_max_size_vector[1],
								client_max_size_vector[2],
								client_min_size_vector[0],
								client_min_size_vector[1],
								client_min_size_vector[2],
								client_weapon,
								client_aim_target,
								client_aim_target_name,
								client_team_id,
								client_team_name,
								client_health,
								kills,
								deaths,
								kd_ratio
								);
		
		LogAction(client, target_list[i], ">> \"%L\" used sm_playerinfo on \"%L\"", client, target_list[i]);
	}
	/* don't really know what to do with these...
	if (tn_is_ml)
	{
		
	}
	else
	{
		
	}
	*/
	
	
	
	return Plugin_Handled;
}