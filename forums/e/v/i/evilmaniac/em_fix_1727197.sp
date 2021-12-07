#pragma semicolon 1
#include <sourcemod>

#define PVersion "0.0.2"

/*
Description:
        Automatically kicks players who attempt the following
                - Ignite fireworks and instantly switch teams
                - Throw a molotov and instantly switch teams

Credit:
        - McFlurry
        - Bugzee
*/

new LastMolly;
new TimeThrown;

public Plugin:myinfo = {
        name = "eM-Fix",
        author = "evilmaniac",
        description = "Bug/Exploit fix compilation for evilmania servers",
        version = PVersion,
        url = "http://www.evilmania.net/"
}

public OnPluginStart(){
        CreateConVar("em_fix_version", PVersion, "eM-FIX version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED);

        HookEvent("player_hurt", Event_PlayerHurt);
        HookEvent("molotov_thrown", Event_MollyThrow);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast){

        new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
        new Attacker = GetEventInt(event, "attackerentid");
        new String:WeaponUsed[32];
        GetEventString(event, "weapon", WeaponUsed, 32);

        if (StrEqual(WeaponUsed, "inferno", false)){
                if(GetClientTeam(Victim) == 2 && GetClientTeam(Attacker) == 3)
                        if(Attacker == LastMolly)
                                if((GetTime() - TimeThrown) <= 15)
                                        KickClient(Attacker, "Exploit detected");
        }
        else if (StrEqual(WeaponUsed, "fire_cracker_blast", false))
                if (GetClientTeam(Victim) == 2 && GetClientTeam(Attacker) == 3)
                        KickClient(Attacker, "Exploit detected");
                else
                        return Plugin_Continue;
        else
                return Plugin_Continue;

        return Plugin_Continue;
}

public Action:Event_MollyThrow(Handle:event, const String:name[], bool:dontBroadcast){
        LastMolly = GetClientOfUserId(GetEventInt(event, "userid"));
        TimeThrown = GetTime();
        return Plugin_Continue;
}