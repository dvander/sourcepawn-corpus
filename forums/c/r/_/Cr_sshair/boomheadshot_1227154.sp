#include sourcemod
#include sdktools


#define Boom  		"boomheadshot.mp3"

public Plugin:myinfo = 
{
	name = "Boom Headshot!",
	author = "ThatGuy, psychonic(DoDS fix), Cr(+)sshair(fix with CS:S support)",
	description = "Plays a sound to snipers when they get headshots & victims of headshots",
	version = "1.3pc",
	url = "http://www.iam-clan.com"
}

public OnPluginStart() {
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("player_hurt", Event_PlayerHurt)
	CreateConVar("BoomHSVersion", "1.2c", "Boom Headshot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
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
		if (IsPlayerAlive(attacker))
		continue;
		if (!IsPlayerAlive(victim))
		continue;
		
		
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	if (GetEventInt(event, "customkill")) 
		{
        if (StrContains(weapon,"sniperrifle") != -1) 
        { 
				
        EmitSoundToClient(attacker, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
        EmitSoundToClient(victim, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
		}
	else 
		{
		new String:weaponcs[64]
	GetEdictClassname(attacker, weaponcs, sizeof(weaponcs))
	if ( ( StrContains(weaponcs, "weapon_awp") != -1)
			{
	 EmitSoundToClient(attacker, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
	 EmitSoundToClient(victim, Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
			}
		}
    
	return Plugin_Continue
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "hitgroup") == 1 && GetEventInt(event, "health" <= 0))
	{
		EmitSoundToClient(GetClientOfUserId(GetEventInt(event, "attacker")), Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
		EmitSoundToClient(GetClientOfUserId(GetEventInt(event, "userid")), Boom, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL)
    }
	return Plugin_Continue
}