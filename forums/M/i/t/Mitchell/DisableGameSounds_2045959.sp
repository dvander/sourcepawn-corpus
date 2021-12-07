#pragma semicolon 1
public Plugin:myinfo =
{
	name = "Disable Game Sounds",
	author = "Mitch",
	description = "Fix to the annoying round sounds, and death sounds",
	version = "1.3.1",
	url = "https://forums.alliedmods.net/showthread.php?t=???"
};
public OnPluginStart()
{
	CreateConVar("sm_disablegamesounds_version", "1.3.0", "DisableGameSounds Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	HookEvent("round_poststart", Event_Standard);
	HookEvent("round_start", Event_Standard);
	HookEvent("round_end", Event_Standard);
	HookEvent("round_freeze_end", Event_Standard);
	HookEvent("teamplay_round_start", Event_Standard);
	HookEvent("player_death", Event_Player);
	HookEvent("player_spawn", Event_Player);
}
public Action:Event_Player(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = (GetClientOfUserId(GetEventInt(event, "userid")));
	
	ClientCommand(client, "playgamesound Music.StopAllMusic");
}
public Action:Event_Standard(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			ClientCommand(i, "playgamesound Music.StopAllMusic");
}