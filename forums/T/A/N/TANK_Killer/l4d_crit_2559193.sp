#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define L4D CRITICAL

new Handle:cvarCritChance;
new Handle:cvarCritDamageMin;
new Handle:cvarCritDamageMax;
new Handle:cvarCritForce;
new Handle:cvarCritPrint;

new damagechance;
new damage;
new damagebonus;
new damageshow;
new health;


public Plugin:myinfo = 
{
    name = "[L4D] Critical Shot",
    author = "[E]c, TK",
    description = "Damage done to special infected will have chance to become critical",
    version = "1.1",
    url = ""
}

public OnPluginStart()
{
	HookEvent("player_hurt", SHurtDamage, EventHookMode_Post);

	cvarCritChance = CreateConVar("sm_critical_chance", "3", "Шанс критического урона в процентах (По умолчанию 5)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritDamageMin = CreateConVar("sm_critical_min", "2", "Во сколько минимум раз увеличивается урон, когда крит (По умолчанию 2)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritDamageMax = CreateConVar("sm_critical_max", "10", "Во сколько максимум раз увеличивается урон, когда крит (По умолчанию 10)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritForce = CreateConVar("sm_critical_force", "100", "Отбросить жертву критического попадания (По умолчанию 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarCritPrint = CreateConVar("sm_critical_print", "1", "Показывать критический урон в чат", FCVAR_PLUGIN, true, 0.0, false, _);
	AutoExecConfig(true, "l4d_crit");
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
				damagechance = GetRandomInt(GetConVarInt(cvarCritDamageMin), GetConVarInt(cvarCritDamageMax));
				health = GetClientHealth(victim);
				damage = GetEventInt(event, "dmg_health");
				damagebonus = damage * damagechance;
				damageshow = damage + damagebonus;
				if (GetConVarInt(cvarCritPrint))
				{
				PrintToChat(attacker, "\x01 Крит!\x03 %i\x01 урона", damageshow);
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
	if (health - damagebonus <= 0) KillVictim();
	else SetEntityHealth(victim, health - damagebonus);
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

KillVictim()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		
		if (!IsClientInGame(i)) continue;
		
		if (GetClientTeam(i)==3)
			ForcePlayerSuicide(i);
	}
}