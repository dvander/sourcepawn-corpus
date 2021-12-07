#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Network Monitor",
	author = "James \"sslice\" Gray",
	description = "Provides informative commands regarding the network status of the game server, and monitors players network connections and kicks players that have latency, loss, or choke that exceeds the other players by a certain amount.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new g_iMaxClients;
new g_iClientCount;

// ConVars
new Handle:sm_ping_threshold;
new Handle:sm_loss_threshold;
new Handle:sm_choke_threshold;

new g_iCurrentPlayer = 1;
new g_iSamplePos[64];

// The first 9 slots per player are for samples.. the last two are for total and average, for quick averaging
new Float:g_flNumSamples[64];
new Float:g_flPingSamples[64][11];
new Float:g_flLossSamples[64][11];
new Float:g_flChokeSamples[64][11];
new Float:g_flPingTotal;
new Float:g_flLossTotal;
new Float:g_flChokeTotal;

public OnPluginStart()
{
	g_iMaxClients = GetMaxClients();
	
	CreateConVar("netmon_version",  PLUGIN_VERSION, "Network Monitor", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	sm_ping_threshold = CreateConVar("sm_ping_threshold", "150", "Maximum difference in ping from other players before being kicked", FCVAR_PLUGIN, true, 20.0, false, 0.0);
	sm_loss_threshold = CreateConVar("sm_loss_threshold", "30", "Maximum difference in loss from other players before being kicked", FCVAR_PLUGIN, true, 3.0, false, 0.0);
	sm_choke_threshold = CreateConVar("sm_choke_threshold", "50", "Maximum difference in choke from other players before being kicked", FCVAR_PLUGIN, true, 5.0, false, 0.0);
	
	RegServerCmd("netstats", Cmd_NetStats, "Network statistics", FCVAR_PLUGIN);
	
	// Take sample of each player--spread over a 10 second interval.
	// In this plugin, we have a 90 second wide sample spectrum.
	new Float:timer_interval = 10.0 / g_iMaxClients;
	CreateTimer(timer_interval, Timer_TakeSample, 0, TIMER_REPEAT);
	
	CalcClientCount();
}

public OnMapStart()
{
	g_flPingTotal = 0.0;
	g_flLossTotal = 0.0;
	g_flChokeTotal = 0.0;
}

public OnClientPutInServer(client)
{
	CalcClientCount();
}

public OnClientDisconnect(client)
{
	g_flPingTotal -= g_flPingSamples[client][10];
	g_flLossTotal -= g_flLossSamples[client][10];
	g_flChokeTotal -= g_flChokeSamples[client][10];

	g_iSamplePos[client] = 0;
	g_flNumSamples[client] = 0.0;
	for (new i; i < 11; ++i)
	{
		g_flPingSamples[client][i] = 0.0;
		g_flLossSamples[client][i] = 0.0;
		g_flChokeSamples[client][i] = 0.0;
	}
	g_iClientCount -= 1;
}


public CalcClientCount()
{
	new count;
	for (new i = 1; i <= g_iMaxClients; ++i)
	{
		if (IsClientInGame(i))
			++count;
	}
	g_iClientCount = count;
}

public Action:Cmd_NetStats(argc)
{
	if (g_iClientCount == 0)
	{
		PrintToServer("%10s %10s %10s\n%6.2f  %6.2f  %6.2f", "Avg Ping", "Avg Loss", "Avg Choke", 0.0, 0.0, 0.0);
	}
	else
	{
		new Float:num_clients = float(g_iClientCount);
		
		new Float:total_avg_ping = g_flPingTotal / num_clients;
		new Float:total_avg_loss = g_flLossTotal / num_clients;
		new Float:total_avg_choke = g_flChokeTotal / num_clients;

		PrintToServer("%10s %10s %10s\n%6.2f  %6.2f  %6.2f", "Avg Ping", "Avg Loss", "Avg Choke", total_avg_ping, total_avg_loss, total_avg_choke);
	}
}

public Action:Timer_TakeSample(Handle:timer)
{
	new client = g_iCurrentPlayer;
	if (IsClientInGame(client) && g_iClientCount > 1)
	{
		new pos = g_iSamplePos[client];
		new next_pos = g_iSamplePos[client] + 1;
		if (next_pos >= 9)
			next_pos = 0;
			
		g_flNumSamples[client] += 1.0;
		if (g_flNumSamples[client] > 9.0)
			g_flNumSamples[client] = 9.0;
		
		// Sample the data
		new Float:ping = GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0; // milliseconds
		new Float:loss = GetClientAvgLoss(client, NetFlow_Outgoing) * 100.0;
		new Float:choke = GetClientAvgChoke(client, NetFlow_Outgoing) * 100.0;

		// Copy the data to global vars
		g_flPingSamples[client][pos] = ping;
		g_flLossSamples[client][pos] = loss;
		g_flChokeSamples[client][pos] = choke;

		// Adjust the totals
		g_flPingSamples[client][9] += ping;
		g_flPingSamples[client][9] -= g_flPingSamples[client][next_pos];
		g_flLossSamples[client][9] += loss;
		g_flLossSamples[client][9] -= g_flLossSamples[client][next_pos];
		g_flChokeSamples[client][9] += choke;
		g_flChokeSamples[client][9] -= g_flChokeSamples[client][next_pos];

		// Calculate averages
		new Float:avg_ping = g_flPingSamples[client][9] / g_flNumSamples[client]; // total / 9
		new Float:avg_loss = g_flLossSamples[client][9] / g_flNumSamples[client];
		new Float:avg_choke = g_flChokeSamples[client][9] / g_flNumSamples[client];
		
		// Total of all clients' averages, excluding self (current player)
		g_flPingTotal -= g_flPingSamples[client][10];
		g_flLossTotal -= g_flLossSamples[client][10];
		g_flChokeTotal -= g_flChokeSamples[client][10];
		
		// Copy our client's averages to global vars
		g_flPingSamples[client][10] = avg_ping;
		g_flLossSamples[client][10] = avg_loss;
		g_flChokeSamples[client][10] = avg_choke;
		
		// Overall average ping, loss, and choke (excluding self)
		new Float:num_clients = float(g_iClientCount - 1);
		new Float:total_avg_ping = g_flPingTotal / num_clients;
		new Float:total_avg_loss = g_flLossTotal / num_clients;
		new Float:total_avg_choke = g_flChokeTotal / num_clients;
		
		new Float:ping_threshold = GetConVarFloat(sm_ping_threshold);
		new Float:loss_threshold = GetConVarFloat(sm_loss_threshold);
		new Float:choke_threshold = GetConVarFloat(sm_choke_threshold);
		
		// Compare averages
		if (g_flNumSamples[client] == 9.0)
		{
			if (avg_ping - total_avg_ping > ping_threshold)
			{
				ServerCommand("kickid %d \"Your ping exceeded the average ping by over %d\"\n", GetClientUserId(client), RoundToFloor(ping_threshold));
			}
			else if (avg_loss - total_avg_loss > loss_threshold)
			{
				ServerCommand("kickid %d \"Your packet loss exceeded the average loss by over %d\"\n", GetClientUserId(client), RoundToFloor(loss_threshold));
			}
			else if (avg_choke - total_avg_choke > choke_threshold)
			{
				ServerCommand("kickid %d \"Your packet choke exceeded the average choke by over %d\"\n", GetClientUserId(client), RoundToFloor(choke_threshold));
			}
		}
		
		// Add our averages back in to totals
		g_flPingTotal += avg_ping;
		g_flLossTotal += avg_loss;
		g_flChokeTotal += avg_choke;

		++pos;
		if (pos >= 9)
			pos = 0;
		g_iSamplePos[client] = pos;
	}
	
	++client;
	if (client > g_iMaxClients)
	{
		client = 1;
	}
	g_iCurrentPlayer = client;
}
