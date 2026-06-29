#include sourcemod
#include sdktools


#define Boom  		"boomheadshot.mp3"

public Plugin:myinfo = 
{
	name = "Boom Headshot!",
	author = "ThatGuy",
	description = "Plays a sound to snipers when they get headshots & victims of headshots",
	version = "1.1",
	url = "http://www.iam-clan.com"
}

public OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath)
	CreateConVar("BoomHSVersion", "1.1", "Boom Headshot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

public OnMapStart() 
{
	PrecacheSound(Boom)
	decl String:file[64]
	Format(file, 63, "sound/%s", Boom);
	AddFileToDownloadsTable(file)
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
        new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
        new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	if (GetEventInt(event, "customkill")) {
        if (StrContains(weapon,"sniperrifle") != -1) 
        { 
				
        EmitSoundToClient(attacker, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
        EmitSoundToClient(victim, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
	}
    }
	return Plugin_Continue
}
