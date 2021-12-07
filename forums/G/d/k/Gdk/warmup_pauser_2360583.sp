#include <sourcemod>

// Plugin definitions
#define PLUGIN_VERSION "1.6.0"

new Handle:PluginEnabled = INVALID_HANDLE;
new Handle:WarmupTime = INVALID_HANDLE;
new Handle:CountBots = INVALID_HANDLE;
new Handle:PlayerCountStart = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[CS:GO] Warmup Pauser",
	author = "Gdk",
	version = PLUGIN_VERSION,
	description = "Keeps game in warmup untill specified number of players have joined",
	url = "https://TopSecretGaming.net"
};

public OnPluginStart()
{
	PluginEnabled = CreateConVar("sm_warmup_pauser_enabled", "1", "Whether the plugin is enabled");
	WarmupTime = CreateConVar("sm_warmup_pauser_time", "20", "Warmup time after players have connected");
	CountBots = CreateConVar("sm_warmup_pauser_count_bots", "0", "Whether the plugin should count bots in player count");
	PlayerCountStart = CreateConVar("sm_warmup_pauser_players_start", "2", "Number of players to end warmup");
	AutoExecConfig(true, "warmup_pauser");
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(PluginEnabled))
	{
		SetConVarInt(FindConVar("mp_warmuptime"), GetConVarInt(WarmupTime));
		SetConVarInt(FindConVar("mp_do_warmup_period"), 1);

		if(GetConVarBool(CountBots))
		{
			if(GetClientCount(true) < GetConVarInt(PlayerCountStart))
				ServerCommand("mp_warmup_pausetimer 1");
			if(GetClientCount(true) >= GetConVarInt(PlayerCountStart))
				ServerCommand("mp_warmup_pausetimer 0");
		}
		else
		{
			if(GetRealClientCount(true) < GetConVarInt(PlayerCountStart))
				ServerCommand("mp_warmup_pausetimer 1");
			if(GetRealClientCount(true) >= GetConVarInt(PlayerCountStart))
				ServerCommand("mp_warmup_pausetimer 0");
		}
	}
}

stock GetRealClientCount( bool:inGameOnly = true ) 
{
	new clients = 0;
	for( new i = 1; i <= GetMaxClients(); i++ ) 
	{
		if( ( ( inGameOnly ) ? IsClientInGame( i ) : IsClientConnected( i ) ) && !IsFakeClient( i ) ) 
		{
			clients++;
		}
	}
	return clients;
}