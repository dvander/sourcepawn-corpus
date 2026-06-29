#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.alpha"

public Plugin:myinfo = 
{
	name = "multibomb_remover",
	author = "Franc1sco",
	description = "clear away the not planted bombs",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	HookEvent( "bomb_planted", Event_BombPlanted );
}

public Action:Event_BombPlanted( Handle:event, const String:name[], bool:dontBroadcast )
{
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (StrContains(weapon, "weapon_c4") != -1)
					RemoveEdict(i);
		}
	}
}