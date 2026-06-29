#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define L4D CRITICAL
#define PLUGIN_VERSION "1.1"

new Handle:cvarCritChance;
new Handle:cvarCritDamage;
new Handle:cvarCritForce;
new Handle:cvarCritPrint;

new damage;
new damagebonus;
new damageshow;
new health;


public Plugin:myinfo = 
{
    name = "[L4D] Critical Shot",
    author = "[E]c",
    description = "Damage done to special infected will have chance to become critical",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	HookEvent("player_hurt", SHurtDamage, EventHookMode_Post);
	HookEvent("infected_hurt", IHurtDamage);
	
	CreateConVar("sm_critical", PLUGIN_VERSION, "Critical Shot Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	cvarCritChance = CreateConVar("sm_critical_chance", "5", "Chance to crit(Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritDamage = CreateConVar("sm_critical_damages", "2", "Damages bonus multiple when crit (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritForce = CreateConVar("sm_critical_force", "100", "Knockback apply to victim when crit (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritPrint = CreateConVar("sm_critical_print", "1", "Show damage done", FCVAR_PLUGIN, true, 0.0, false, _);
	AutoExecConfig(true, "critical");

	LogMessage("[Critical Shot] - Loaded");
}

public Action:SHurtDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim || !attacker) return Plugin_Continue;
	if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
	{
		if (IsClientInGame(attacker))
		{
			new TempChance = GetRandomInt(0, 100);
			if (TempChance < GetConVarInt(cvarCritChance))
			{
				health = GetClientHealth(victim);
				damage = GetEventInt(event, "dmg_health");
				damagebonus = RoundToNearest(damage * GetConVarFloat(cvarCritDamage));
				damageshow = damage + damagebonus;
				if (GetConVarInt(cvarCritPrint))
				{
				PrintToChat(attacker, "Crit! %i damage", damageshow);
				}
				Knockback(attacker, victim, GetConVarFloat(cvarCritForce), 1.5, 2.0);
				CreateTimer(0.01, apply, victim);
			}
		}
	}
	return Plugin_Continue;
}

public Action:apply(Handle:timer, any:victim)
{
	if (health - damagebonus < 0) SetEntityHealth(victim, 0);
	else SetEntityHealth(victim, health - damagebonus);
}




public Action:IHurtDamage(Handle:event, const String:name[], bool:dontBroadcast)
{	
	// new damagetype = GetEventInt(event, "type");
	new TempChance = GetRandomInt(0, 100);
	if (TempChance < GetConVarInt(cvarCritChance))
		{
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			if (GetClientTeam(attacker) == 2)
			{
				new infected = GetEventInt(event, "entityid");
				decl String:class[20];
				GetEntityNetClass(infected, class, 20);
				new compare;
				compare = strcmp(class, "Witch");
				if(compare == 0)
				{
					return Plugin_Continue;
				}
				else
				{
					IgniteEntity(infected, 100.0, false);
				}
			}
		}
	return Plugin_Continue;
}

Knockback(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Smash target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}