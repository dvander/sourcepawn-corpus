#include <sourcemod>
#include <sdktools>
#include <mapchooser>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1 by Franug"

new ganado_ct = 0;
new ganado_t = 0;

new Handle:t_cvar;
new Handle:ct_cvar;

public Plugin:myinfo = {
	name = "SM consecutive wins",
	author = "Franc1sco steam: franug",
	description = "Exec configs by consecutive wins.",
	version = PLUGIN_VERSION,
	url = "http://www.servers-cfg.foroactivo.com"
};

public OnPluginStart() 
{
	CreateConVar("sm_consecutivewins_version", PLUGIN_VERSION, "version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("round_end", EventRoundEnd);

        t_cvar = CreateConVar("sm_consecutive_wins_ct", "10", "consecutive round by t for exec config");
        ct_cvar = CreateConVar("sm_consecutive_wins_t", "10", "consecutive round by ct for exec config");

}



public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
		new ev_winner = GetEventInt(event, "winner");
		if(ev_winner == 2) 
		{
			++ganado_t;
			ganado_ct = 0;
			if(GetConVarInt(t_cvar) == ganado_t)
			{
				ServerCommand("exec changelevel.cfg");
				Votaciones();
			}

		}
		else if(ev_winner == 3) 
		{
			++ganado_ct;
			ganado_t = 0;
			if(GetConVarInt(ct_cvar) == ganado_ct)
			{
				ServerCommand("exec changelevel.cfg");
				Votaciones();
			}

		}
		else {
			ganado_ct = 0;
			ganado_t = 0;
		}
}

Votaciones()
{
        new MapChange:when = MapChange:0;
        InitiateMapChooserVote(when);
}