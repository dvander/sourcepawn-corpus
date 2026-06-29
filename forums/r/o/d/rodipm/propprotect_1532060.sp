#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	HookEvent("player_spawn", spawn);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));  
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:classname[256];
	decl String:classname1[256];
	GetEdictClassname(inflictor, classname, sizeof(classname));
	GetEdictClassname(attacker, classname1, sizeof(classname1));
	
	if(attacker != 0)
	{
		if(StrEqual(classname, "func_physbox", false) || StrEqual(classname, "prop_physics", false) || StrEqual(classname1, "func_physbox", false) || StrEqual(classname1, "prop_physics", false))
		{
			damage = 0.0;
			PrintToChat(victim, "\x04[Prop Damage Protect \x01By.: RpM\x04]\x03 You were protected from a prop damage!");
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}