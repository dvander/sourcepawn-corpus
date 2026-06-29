#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_VERSION "1"
public Plugin:myinfo = {
    name = "[L4D] Tank Burner",
    author = "Adam Nowack <nowak@xpam.de>",
    description = "Continuously damage the Tank when on fire",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:cvar_director_no_human_zombies;
new Handle:cvar_l4d_tank_burner_dps_vs;
new Handle:cvar_l4d_tank_burner_dps_coop;

public OnPluginStart() {
    CreateConVar("l4d_tank_burner_version", PLUGIN_VERSION, "Tank Burner plugin version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    
    cvar_director_no_human_zombies = FindConVar("director_no_human_zombies");
    cvar_l4d_tank_burner_dps_vs = CreateConVar("l4d_tank_burner_dps_vs", "150.0", "Damage per second to a burning tank, versus only.");
    cvar_l4d_tank_burner_dps_coop = CreateConVar("l4d_tank_burner_dps_coop", "150.0", "Damage per second to a burning tank, coop only.");
    HookEvent("tank_spawn", eventTankSpawn);
}

public eventTankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new Handle:args;
    CreateDataTimer(0.1, BurnTick, args, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    WritePackCell(args, GetEventInt(event, "tankid"));
    if (GetConVarInt(cvar_director_no_human_zombies) == 0) {
	WritePackFloat(args, GetConVarFloat(cvar_l4d_tank_burner_dps_vs));
    } else {
	WritePackFloat(args, GetConVarFloat(cvar_l4d_tank_burner_dps_coop));
    }
    WritePackFloat(args, -1.0);
    WritePackFloat(args, 0.0);
}

public Action:BurnTick(Handle:timer, Handle:args) {
    ResetPack(args);
    new ent = ReadPackCell(args);
    new Float:dps = ReadPackFloat(args);
    new Float:lastTime = ReadPackFloat(args);
    new Float:curTime = GetGameTime();
    new Float:damage = ReadPackFloat(args);
    
    if (IsValidEntity(ent)) {
        new m_fFlags = GetEntProp(ent, Prop_Data, "m_fFlags");
	if (m_fFlags & FL_TRANSRAGDOLL) {
	    KillTimer(timer);
	} else if (m_fFlags & FL_ONFIRE) {
	    if (lastTime < 0) lastTime = curTime - GetTickInterval();
	    new Float:dTime = curTime - lastTime;
	    if (dTime > 0) {
		new health = GetEntProp(ent, Prop_Data, "m_iHealth");
		damage += dps * dTime;
		new iDamage = RoundToFloor(damage);
		damage -= iDamage;
		if (health <= iDamage) {
		    SetEntProp(ent, Prop_Data, "m_iHealth", 0);
		    KillTimer(timer);
		} else {
		    SetEntProp(ent, Prop_Data, "m_iHealth", health - iDamage);
	            ResetPack(args, true);
		    WritePackCell(args, ent);
		    WritePackFloat(args, dps);
	            WritePackFloat(args, curTime);
		    WritePackFloat(args, damage);
		}
	    }
	}
    } else {
        KillTimer(timer);
    }
}
