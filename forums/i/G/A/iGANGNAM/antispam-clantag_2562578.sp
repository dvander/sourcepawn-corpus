#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.0.1-dev"

//Handle
Handle h_ctsf_kick_mode;
Handle h_ctsf_kick_reason;
Handle h_ctsf_changed_time;
Handle h_ctsf_count_changed;

float	clan_changed_time[MAXPLAYERS+1];
int		clan_count_changed[MAXPLAYERS+1];
char	kick_reason[128];

public Plugin:myinfo = 
{
	name = "ClanTag spam fixed",
	author = "rostov114",
	description = "@TODO",
	version = PLUGIN_VERSION,
	url = "http://rostov114.ru"
}


public OnPluginStart()
{
	h_ctsf_kick_mode     = CreateConVar("ctsf_kick_mode",  "1", "1 - kick on, 0 - kick off");
	h_ctsf_kick_reason   = CreateConVar("ctsf_kick_reason",  "ClanTag spamed", "Kick reason");
	h_ctsf_changed_time  = CreateConVar("ctsf_changed_time", "60.0", "");
	h_ctsf_count_changed = CreateConVar("ctsf_count_changed", "10", "");

	GetConVarString(h_ctsf_kick_reason, kick_reason, sizeof(kick_reason))
}

public void OnClientConnected(int client) 
{ 
    clan_changed_time[client]	= 0.0;
	clan_count_changed[client]	= 0;		
}

public Action OnClientCommandKeyValues(int client, KeyValues kv) 
{
	char cmd[64]; 

	if (kv.GetSectionName(cmd, sizeof(cmd)) && StrEqual(cmd, "ClanTagChanged", false)) 
	{ 
		if (clan_changed_time[client] && GetGameTime() - clan_changed_time[client] <= GetConVarFloat(h_ctsf_changed_time)) 
		{
			if (GetConVarBool(h_ctsf_kick_mode) == true)
			{
				if (clan_count_changed[client] < GetConVarInt(h_ctsf_count_changed))
				{
					clan_count_changed[client]++;
					
					return Plugin_Continue; 
				}
				
				KickClient(client, kick_reason);
			}
					
			return Plugin_Handled;
		}
		
		clan_count_changed[client]	= 0;
		clan_changed_time[client] 	= GetGameTime(); 
	}
	
    return Plugin_Continue; 
}