#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION			"1.01"
#define PLUGIN_NAME				"Soldier VS Demoman"
#define PLUGIN_AUTHOR			"Mecha the Slag"
#define PLUGIN_DESCRIPTION		"Shows how each team (Demo / Soldier) is doing compared to the other in this dreadful WAR (also plays ding!)"
#define PLUGIN_URL				"www.mechaware.net"

new Soldier = 0;
new Demoman = 0;

public OnPluginStart()
{    

    // Create cvars
    CreateConVar("svd_version", PLUGIN_VERSION, "Current version of this plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    // Hook blocks
    HookEvent		("player_death", player_death);
}

public player_death(Handle:argEvent, const String:name[], bool:noBroadcast) {
    new g_attackerid = GetEventInt(argEvent, "attacker");
    new g_victimid = GetEventInt(argEvent, "userid");
    
    new g_attacker = GetClientOfUserId(g_attackerid);
    new g_victim = GetClientOfUserId(g_victimid);
    
    if ((TF2_GetPlayerClass(g_attacker) == TFClass_Soldier) && (TF2_GetPlayerClass(g_victim) == TFClass_DemoMan)) {
        Soldier = Soldier + 1
        onPlayerKill()
    }
    
    if ((TF2_GetPlayerClass(g_attacker) == TFClass_DemoMan) && (TF2_GetPlayerClass(g_victim) == TFClass_Soldier)) {
        Demoman = Demoman + 1
        onPlayerKill()
    }
}

onPlayerKill() {
    for (new i=1;i<=MaxClients;i++) {
        if (IsClientInGame(i) && !IsFakeClient(i))	{
            ClientCommand(i, "playgamesound \"ui/scored.wav\"");
        }
    }
    
    new String:text[512];
    
    if (Soldier > Demoman) Format(text, sizeof(text),"1) Soldier: %d\n2) Demoman: %d", Soldier, Demoman);
    if (Soldier < Demoman) Format(text, sizeof(text),"1) Demoman: %d\n2) Soldier: %d", Demoman, Soldier);
    if (Soldier == Demoman) Format(text, sizeof(text),"Soldier and Demoman: %d", Soldier);
    PrintToChatAll(text)

}
