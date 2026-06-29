#include <sourcemod>
#include <tf2_stocks>
#pragma semicolon 1

#define VERSION "1.0.0"

new Handle:g_Cvar_Enabled;
new Handle:g_Cvar_Song;

new String:g_Song[PLATFORM_MAX_PATH];
new bool:g_bArena;

#define STANDOFF_CHANNEL SNDCHAN_USER_BASE+2

public Plugin:myinfo = {
	name			= "[TF2] Arena Standoff Music",
	author			= "Powerlord",
	description		= "Play music when only two players are left in arena mode",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=227837"
};

public OnPluginStart()
{
	CreateConVar("arena_standoffmusic_version", VERSION, "Arena Standoff Music version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	g_Cvar_Enabled = CreateConVar("arena_standoffmusic_enable", "1", "Enable Arena Standoff Music?", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_Cvar_Song = CreateConVar("arena_standoffmusic_song", "music/mvm_start_last_wave.wav", "Song to play when only one player is left on each team. Relative to sound/ directory.", FCVAR_PLUGIN);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_round_win", Event_RoundEnd);
	
	//AutoExecConfig(true, "arena_standoffmusic");
}

public OnConfigsExecuted()
{
	GetConVarString(g_Cvar_Song, g_Song, sizeof(g_Song));
	new String:cache[PLATFORM_MAX_PATH];
	Format(cache, sizeof(cache), "sound/%s", g_Song);
	AddFileToDownloadsTable(cache);
	
	g_bArena = (FindEntityByClassname(-1, "tf_logic_arena") > -1) ? true : false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bArena || !GetConVarBool(g_Cvar_Enabled) || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;
	
	new playersRED;
	new playersBLU;
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			new TFTeam:team = TFTeam:GetClientTeam(client);
			switch (team)
			{
				case TFTeam_Red:
				{
					playersRED++;
				}
				
				case TFTeam_Blue:
				{
					playersBLU++;
				}
			}
		}
	}
	
	if (playersRED == 1 && playersBLU == 1)
	{
		PrecacheSound(g_Song);
		EmitSoundToAll(g_Song, SOUND_FROM_PLAYER, STANDOFF_CHANNEL);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bArena || !GetConVarBool(g_Cvar_Enabled))
		return;
		
	StopSoundToAll(STANDOFF_CHANNEL, g_Song);
}

stock StopSoundToAll(channel, const String:name[])
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			StopSound(client, channel, name);
	}	
}