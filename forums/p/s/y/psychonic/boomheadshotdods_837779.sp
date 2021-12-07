#include sourcemod
#include sdktools

#pragma semicolon 1

#define Boom  		"boomheadshot.mp3"

public Plugin:myinfo = 
{
	name = "Boom Headshot!",
	author = "ThatGuy",
	description = "Plays a sound to snipers when they get headshots & victims of headshots",
	version = "1.1-DODS-psychonic",
	url = "http://www.iam-clan.com"
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	CreateConVar("BoomHSVersion", "1.1-psychonic", "Boom Headshot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart() 
{
	PrecacheSound(Boom);
	decl String:file[64];
	Format(file, 63, "sound/%s", Boom);
	AddFileToDownloadsTable(file);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "hitgroup") == 1 && GetEventInt(event, "health" <= 0))
	{
		EmitSoundToClient(GetClientOfUserId(GetEventInt(event, "attacker")), Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		EmitSoundToClient(GetClientOfUserId(GetEventInt(event, "userid")), Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
    }
	return Plugin_Continue;
}
