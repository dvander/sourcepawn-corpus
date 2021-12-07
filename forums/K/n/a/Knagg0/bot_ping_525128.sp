#include <sourcemod>
#include <sdktools>

new g_iMaxClients		= 0;

new Float:g_fTimer		= 0.0;

new String:g_szPlayerManager[50] = "";

// Entities
new g_iPlayerManager	= -1;

// Offsets
new g_iPing				= -1;

// ConVars
new Handle:g_hMinPing 	= INVALID_HANDLE;
new Handle:g_hMaxPing	= INVALID_HANDLE;
new Handle:g_hInterval	= INVALID_HANDLE;

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Bot Ping",
	author = "Knagg0",
	description = "Changes the ping of a BOT on the scoreboard",
	version = PLUGIN_VERSION,
	url = "http://www.mfzb.de"
};

public OnPluginStart()
{
	CreateConVar("bp_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);

	g_hMinPing	= CreateConVar("bp_minping", "50");
	g_hMaxPing	= CreateConVar("bp_maxping", "75");
	g_hInterval	= CreateConVar("bp_interval", "3");
	
	g_iPing	= FindSendPropOffs("CPlayerResource", "m_iPing");

	new String:szBuffer[100];
	GetGameFolderName(szBuffer, sizeof(szBuffer));

	if(StrEqual("cstrike", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "cs_player_manager");
	else if(StrEqual("dod", szBuffer))
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "dod_player_manager");
	else
		strcopy(g_szPlayerManager, sizeof(g_szPlayerManager), "player_manager");
}

public OnMapStart()
{
	g_iMaxClients		= GetMaxClients();
	g_iPlayerManager	= FindEntityByClassname(g_iMaxClients + 1, g_szPlayerManager);
	g_fTimer			= 0.0;
}

public OnGameFrame()
{
	if(g_fTimer < GetGameTime() - GetConVarInt(g_hInterval))
	{
		g_fTimer = GetGameTime();
		
		if(g_iPlayerManager == -1 || g_iPing == -1)
			return;

		for(new i = 1; i <= g_iMaxClients; i++)
		{
			if(!IsValidEdict(i) || !IsClientInGame(i) || !IsFakeClient(i))
				continue;

			SetEntData(g_iPlayerManager, g_iPing + (i * 4), GetRandomInt(GetConVarInt(g_hMinPing), GetConVarInt(g_hMaxPing)));
		}
	}
}
