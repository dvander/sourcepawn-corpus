new Handle:fix_flash = INVALID_HANDLE;
new bool:cvar_enabled;
new Float:old_duration[MAXPLAYERS+1] = {0.0, ...}; // Storage player previous flash duration
new String:path[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "[CS:S] Fix flashbang flash duration bug",
	author = "Bacardi",
	description = "Fix flashbang flash duration bug with log file",
	version = "0.15"
}

public OnPluginStart()
{
	if(!HookEventEx("player_blind", player_blind))
	{
		SetFailState("Game missing event player_blind");
	}

	if(!HookEventEx("player_spawn", player_blind))
	{
		SetFailState("Game missing event player_spawn");
	}

	fix_flash = CreateConVar("sm_fix_flash", "1", "Enable plugin fix flashbang flash duration", FCVAR_NONE, true, 0.0, true, 1.0);
	cvar_enabled = GetConVarBool(fix_flash);
	HookConVarChange(fix_flash, convar_changed);

	new String:file[30];
	Format(file, sizeof(file), "logs/css_fix_flash_bug.log");
	BuildPath(Path_SM, path, sizeof(path), file);
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

		if(IsFakeClient(client)) // bot
		{
			return;
		}

		if(StrEqual(name, "player_spawn"))
		{
			old_duration[client] = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration"); // Storage current flash duration when player spawn
			return;
		}

		if(GetClientTeam(client) >= 2 && IsPlayerAlive(client)) // in team, alive
		{
			decl Float:duration;
			if((duration = GetEntPropFloat(client, Prop_Send, "m_flFlashDuration")) != 0.0)
			{
				if(old_duration[client] == duration) // compare flash duration
				{
					LogToFileEx(path, "Player %L blinded same flash duration %f", client, duration);
					duration = GetRandomFloat(duration + 0.01, duration + 0.1); // Random duration time little
					SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration); // Flash player
				}
			}

			old_duration[client] = duration; // Storage flash duration
		}
	}
}