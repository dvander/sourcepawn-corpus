//Includes:
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "1.2"
#define MAX_FILE_LEN 80
#define DF_CRITS        1048576    //crits = DAMAGE_ACID

new Handle:bt_enable;
new Handle:bt_crits;
new Handle:bt_knife;
new Handle:bt_melee;
new Handle:bt_timescale;
new Handle:bt_trans;
new Handle:bt_fsound;

new slowdown = 0;
new cheatstatus = 0;
new focussound = 2;
new transition = false;
new Float:timescale = 0.50;
new String:sound_slowdown[MAX_FILE_LEN] = "imgay/nmh_slash_low.mp3";
new String:sound_kill[MAX_FILE_LEN] = "imgay/nmh_kill.mp3";
static const String:Weapons[][]={"taunt_demoman", "taunt_soldier", "pickaxe", "unique_pickaxe", "sword", "bat", "tf_projectile_arrow", "club", "wrench", "bottle", "ubersaw", "axtinguisher", "fists", "sandman", "gloves", "bonesaw", "shovel", "fireaxe", "taunt_sniper", "bat_wood", "taunt_heavy", "deflect_rocket", "taunt_pyro", "deflect_arrow", "deflect_promode", "compound_bow", "deflect_sticky", "tf_projectile_arrow_fire"};    
static const String:CritWeapons[][]={"sniperrifle", "tf_projectile_pipe", "tf_projectile_rocket", "rocketlauncher_directhit", "tf_projectile_pipe_remote", "sticky_resistance", "flaregun", "tf_projectile_arrow"};    


public Plugin:myinfo = 

{
    name = "Bullet Time",
    author = "Mecha the Slag",
    description = "Creates a slow-motion effect on events in bullet time / matrix style",
    version = PLUGIN_VERSION,
    url = "http://mechaware.net/"
};

public OnPluginStart() {
    // G A M E  C H E C K //
    decl String:game[32];
    GetGameFolderName(game, sizeof(game));
    if(!(StrEqual(game, "tf")))
    {
        SetFailState("This plugin is only for TF2, not %s", game);
    }

    CreateConVar("mw_id_bt", PLUGIN_VERSION, "Bullet Time", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
    CreateConVar("bt_version", PLUGIN_VERSION, "Bullet Time Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
    bt_enable = CreateConVar("bt_enable", "1", "Enables/Disables Bullet Time.", FCVAR_PLUGIN);
    bt_knife = CreateConVar("bt_knife", "1", "Enables bullet time after backstab.", FCVAR_PLUGIN);
    bt_crits = CreateConVar("bt_crits", "2", "if 1, starts bullet time on all crit kills. If 2, starts bullet time on special crit kills (sniper rifle, rockets, stickies, etc.).", FCVAR_PLUGIN);
    bt_melee = CreateConVar("bt_melee", "1", "Starts Bullet Time on melee and taunt kills.", FCVAR_PLUGIN);
    bt_trans = CreateConVar("bt_transition", "1", "Transitions the timescales if on. If not, timescales are set directly.", FCVAR_PLUGIN);
    bt_timescale = CreateConVar("bt_timescale", "0.50", "Slowdown timescale.", FCVAR_PLUGIN);
    bt_fsound = CreateConVar("bt_fsound", "2", "Plays a sound for the focus of bullet time. If 2 it replaces the default sound rather than playing simultaneously.", FCVAR_PLUGIN);
    RegAdminCmd("bt_go", Command_slow, ADMFLAG_GENERIC, "Forces bullet time.");
    HookEvent("player_death", EventPlayerDeath);
    HookConVarChange(bt_trans, OnConVarChanged_Trans);
    timescale = GetConVarFloat(bt_timescale);
    transition = GetConVarBool(bt_trans);
    focussound = GetConVarBool(bt_fsound);
    
    UpdateClientCheatValue();
}

public OnConfigsExecuted() {
    precacheSound(sound_slowdown);
    precacheSound(sound_kill);
    AddFileToDownloadsTable("materials/imgay/slowdown1.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vmt");
    AddFileToDownloadsTable("materials/imgay/slowdown1.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown2.vtf");
    AddFileToDownloadsTable("materials/imgay/slowdown3.vtf");
}

precacheSound(String:var[]) {
    new String:buffer[MAX_FILE_LEN];
    PrecacheSound(var, true);
    Format(buffer, sizeof(buffer), "sound/%s", var);
    AddFileToDownloadsTable(buffer);
}

public Action:Command_slow(client, args) {
    ActivateSlow(-1);
    return Plugin_Handled;
}  

ActivateSlow(activator) {
    if (slowdown > 0 || !GetConVarBool(bt_enable))
        return;
    cheatstatus = 1;
    UpdateClientCheatValue();
    slowdown = 55;
    for(new i = 1; i <= MaxClients; i++) {
        if(IsValidClient(i) && !IsFakeClient(i)) {
            ClientCommand(i,"r_screenoverlay imgay/slowdown1");
            if (i != activator) EmitSoundToClient(i, sound_slowdown);
        }
    }
    timescale = GetConVarFloat(bt_timescale);
    ServerCommand("host_timescale %f", timescale);
}

public OnGameFrame() {
    if (transition && slowdown <= 10 && slowdown > 1) {
        timescale = GetConVarFloat(bt_timescale);
        new Float:difscale = 1.0 - timescale;
        new Float:tempscale = 1.0 - difscale * slowdown *0.1;
        ServerCommand("host_timescale %f", tempscale);
    }

    if (slowdown == 5) {
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && (!(IsFakeClient(i)))) {
                ClientCommand(i,"r_screenoverlay imgay/slowdown2");
            }
        }   
    }
    
    if (slowdown == 3) {
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && (!(IsFakeClient(i)))) {
                ClientCommand(i,"r_screenoverlay imgay/slowdown3");
            }
        }   
    }

    if (slowdown == 1) {
        slowdown = slowdown - 1;
        ServerCommand("host_timescale 1.0")
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && (!(IsFakeClient(i)))) {
                ClientCommand(i,"r_screenoverlay \"\"")
            }
        }
        cheatstatus = 0;
        UpdateClientCheatValue();
    }
    if (slowdown > 1) {
        slowdown = slowdown - 1;
    }

}

public OnClientPostAdminCheck(client) {
    UpdateClientCheatValue();
}

public OnConVarChanged_Trans(Handle:convar, const String:oldValue[], const String:newValue[]) {
    transition = GetConVarBool(bt_trans);
}

UpdateClientCheatValue() {
        decl String:Value[10];
        Format(Value, sizeof(Value), "%s", cheatstatus);
        for(new i = 1; i <= MaxClients; i++) {
            if(IsValidClient(i) && (!(IsFakeClient(i)))) {
                SendConVarValue(i, FindConVar("sv_cheats"), Value);
            }
        }
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    if (!GetConVarBool(bt_enable))
        return;
    new String:weapon[512];
    GetEventString(event, "weapon", weapon, sizeof(weapon));
    new g_damagebits = GetEventInt(event, "damagebits");
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    
    new bool:go = false;
    new activator = -1;
    for (new i = 0; i < sizeof(Weapons); i++) {
        if (StrEqual(weapon,Weapons[i],false) && GetConVarBool(bt_melee)) go = true;
    }
    for (new i = 0; i < sizeof(CritWeapons); i++) {
        if ((g_damagebits & DF_CRITS) && StrEqual(weapon,CritWeapons[i],false) && GetConVarInt(bt_crits) == 2) go = true;
    }
    
    if ((g_damagebits & DF_CRITS) && GetConVarInt(bt_crits) == 1) go = true;
    if ((g_damagebits & DF_CRITS) && StrEqual(weapon, "knife") && GetConVarBool(bt_knife)) go = true;
    
    focussound = GetConVarBool(bt_fsound);
    if (go == true && focussound >= 1) {
        if(IsValidClient(attacker) && (!(IsFakeClient(attacker)))) {
            EmitSoundToClient(attacker, sound_kill);
            if (focussound >= 2) activator = attacker;
        }
        ActivateSlow(activator);
    }
}

stock bool:IsValidClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}
