#include <sourcemod>
#include <sdkhooks>
#include <swarmtools>

#define PLUGIN_VERSION		"1.1"

new Handle:h_FriendlyFire, bool:b_enabled,
	bool:b_late;

public Plugin:myinfo = 
{
	name = "[ASW] Friendlyfire disabler",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Friendlyfire disabler",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	b_late = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("asw_ffdisabler_version", PLUGIN_VERSION, "The plugin's version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	h_FriendlyFire = FindConVar("mp_friendlyfire");
	
	b_enabled = GetConVarBool(h_FriendlyFire);
	HookConVarChange(h_FriendlyFire, OnCvarChange);
	
	HookEvent("marine_selected", OnMarineSelected);
	
	if (b_late)
	{
		new marine;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				marine = Swarm_GetMarine(i);
				if (IsValidMarine(marine))
					SDKHook(marine, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public OnMarineSelected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new new_marine = GetEventInt(event, "new_marine");
	new old_marine = GetEventInt(event, "old_marine");
	
	if (new_marine > 0)
		SDKHook(new_marine, SDKHook_OnTakeDamage, OnTakeDamage);
	if (old_marine > 0)
		SDKUnhook(old_marine, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	b_enabled = bool:StringToInt(newValue);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (b_enabled)
		return Plugin_Continue;
	
	if (IsValidMarine(attacker))
		return Plugin_Handled;
		
	return Plugin_Continue;
}

bool:IsValidMarine(marine)
{
	if (!IsValidEdict(marine))
		return false;
	
	decl String:classname[64];
	GetEdictClassname(marine, classname, sizeof(classname));
	
	return !(strcmp(classname, "asw_marine"));
}