#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define L4D CRITICAL

ConVar cvarCritChance;
ConVar cvarCritDamageMin;
ConVar cvarCritDamageMax;
ConVar cvarCritForce;
ConVar cvarCritPrint;

int damagechance;
int damage;
int damagebonus;
int damageshow;
int health;

public Plugin myinfo = 
{
    name = "[L4D] Critical Shot",
    author = "[E]c, TK",
    description = "Damage done to special infected will have chance to become critical",
    version = "1.1",
    url = ""
}

public void OnPluginStart()
{
	HookEvent("player_hurt", SHurtDamage, EventHookMode_Post);

	cvarCritChance = CreateConVar("sm_critical_chance", "3", "Шанс критического урона в процентах (По умолчанию 5)", FCVAR_NONE, true, 0.0, false, _);
	cvarCritDamageMin = CreateConVar("sm_critical_min", "2", "Во сколько минимум раз увеличивается урон, когда крит (По умолчанию 2)", FCVAR_NONE, true, 0.0, false, _);
	cvarCritDamageMax = CreateConVar("sm_critical_max", "10", "Во сколько максимум раз увеличивается урон, когда крит (По умолчанию 10)", FCVAR_NONE, true, 0.0, false, _);
	cvarCritForce = CreateConVar("sm_critical_force", "100", "Отбросить жертву критического попадания (По умолчанию 100)", FCVAR_NONE, true, 0.0, false, _);
	cvarCritPrint = CreateConVar("sm_critical_print", "1", "Показывать критический урон в чат", FCVAR_NONE, true, 0.0, false, _);
	AutoExecConfig(true, "l4d_crit");
}

public Action SHurtDamage(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim || !attacker) return Plugin_Continue;
	if (GetClientTeam(victim) == 3 && GetClientTeam(attacker) != 3)
	{
		if (IsClientInGame(attacker))
		{
			int TempChance = GetRandomInt(0, 100);
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

public Action apply(Handle timer, any victim)
{
	if (health - damagebonus <= 0) KillVictim();
	else SetEntityHealth(victim, health - damagebonus);
}

void Knockback(int client, int target, float power, float powHor, float powVec)
{
	/* Smash target */
	float HeadingVector[3], AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);

	float resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

void KillVictim()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		
		if (!IsClientInGame(i)) continue;
		
		if (GetClientTeam(i) == 3)
			ForcePlayerSuicide(i);
	}
}