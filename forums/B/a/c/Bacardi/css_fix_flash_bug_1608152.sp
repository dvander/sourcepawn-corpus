new Handle:fix_flash = INVALID_HANDLE;
new bool:cvar_enabled;

public Plugin:myinfo =
{
	name = "[CS:S] Fix flashbang flash duration bug",
	author = "Bacardi",
	description = "Fix flashbang flash duration bug",
	version = "0.1"
}

public OnPluginStart()
{
	if(!HookEventEx("player_blind", player_blind))
	{
		SetFailState("Game missing event player_blind");
	}

	fix_flash = CreateConVar("sm_fix_flash", "1", "Enable plugin fix flashbang flash duration", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_enabled = GetConVarBool(fix_flash);
	HookConVarChange(fix_flash, convar_changed);
}

public convar_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	cvar_enabled = GetConVarBool(fix_flash);
}

public player_blind(Handle:event, const String:name[], bool:dontBroadcast)
{
/*
	"player_blind"
	{
		"userid"	"short"
	}
*/
	if(cvar_enabled)
	{
		decl client;
		client = GetClientOfUserId(GetEventInt(event, "userid"));

		if(!IsFakeClient(client) && GetClientTeam(client) >= 2 && IsPlayerAlive(client)) // Not BOT, in team, alive
		{
			decl Float:duration;
			if((duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration")) != 0.0)
			{
				SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", GetRandomFloat(duration + 0.01, duration + 0.1)); // Random duration time little
			}
		}
	}
}