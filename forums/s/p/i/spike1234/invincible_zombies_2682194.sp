
#define PLUGIN_NAME           "Invincible Common Infected"
#define PLUGIN_AUTHOR         "spike1234"
#define PLUGIN_DESCRIPTION    "Make normal zombies invincible."
#define PLUGIN_VERSION        "1.1"
#define PLUGIN_URL            "https://forums.alliedmods.net/showthread.php?t=321215"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1


public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

ConVar g_hEnable;
ConVar g_hDamage;

public void OnPluginStart()
{
	g_hEnable = CreateConVar( "sm_invincibleZombies_enable", "1", "1:Enbable 0:Disable");
	g_hDamage = CreateConVar( "sm_invincibleZombies_dmgPerHit", "-1", "Hurt zombies this amount damage per hit.(If value is 0, only headshot effect. If value is negative, they never dies.)");
	
	AutoExecConfig(true, "invincible_zombies");
	
	HookEvent("infected_hurt", OnInfectedHurt, EventHookMode_Pre);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_hEnable.BoolValue && StrEqual(classname, "infected"))
	
	if(g_hDamage.IntValue < 0)
	{
		SetEntProp(entity, Prop_Data, "m_lifeState", 1);
	}
}

public Action OnInfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_hEnable.BoolValue) return;
	
	int victim = GetEventInt(event, "entityid");
	char classname[16];
	GetEntityClassname(victim, classname, sizeof(classname));
	if(StrEqual(classname, "infected"))
	{
		int damage = GetEventInt(event, "amount");
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		//int hitgroup = GetEventInt(event, "hitgroup");
		
		if(damage > 0)
		{
			if((health - g_hDamage.IntValue) > 0)
			SetEntProp(victim, Prop_Data, "m_iHealth", health + damage - g_hDamage.IntValue);
		}
	}
}
