#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:SOUND_PISTOL[] 		= "weapons/pistol/gunfire/pistol_fire.wav";

public Plugin:myinfo = 
{
    name = "L4DAutoPistolSoundFix",
    author = "Armonic",
    description = "Fixes the sound bug when you use Timocops l4dautopistols",
    version = "1.0",
    url = ""
}

public OnPluginStart()
{
    HookEvent("weapon_fire", Event_WeaponFire);
}

public OnMapStart()
{
    
    PrefetchSound(SOUND_PISTOL);
    PrecacheSound(SOUND_PISTOL, true);
    
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
    new String:weapon[64];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client < 0 || client > MAXPLAYERS || !IsPlayerAlive(client) || GetClientTeam(client) != 2) 
        return Plugin_Handled;
    
    
    if (StrEqual(weapon, "pistol"))
    {
        EmitSoundToAll(SOUND_PISTOL, client, SNDCHAN_WEAPON);
    }
    return Plugin_Continue;
}  