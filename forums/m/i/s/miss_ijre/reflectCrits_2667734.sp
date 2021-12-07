#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#define pAuthor "ijre"
#define pName    "Reflect Crits"
#define pDesc    "Reflects all crit damage back onto the attacker."
#define pVersion    "1.0.0"
#define pURL        "https://github.com/ijre/Reflect-Crits"

public Plugin:myinfo = {name = pName, author = pAuthor, description = pDesc, version = pVersion, url = pURL};

new Handle:enabled;
static bool initDone;

public OnPluginStart()
{
	enabled = CreateConVar("rc_enabled", "1", "Enable or disable the Reflect Crits plugin.", FCVAR_PLUGIN);
	
	HookConVarChange(enabled, activated);
	
	AutoExecConfig(true, "reflectCrits");
}
public OnConfigsExecuted()
{
	if(GetConVarBool(enabled))
	{
		SetConVarBool(enabled, false);
		SetConVarBool(enabled, true);
	}
	initDone = true;
	
	// before anyone quotes this and says "????????", i did this because i couldn't figure out how to call the enabled cvar's function otherwise
	// since they only care when changed and enabled is the only one with a default of 1, when you start the plugin it wouldn't work because it didn't trigger HookConVarChange since it was already 1
}
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, playerTookDamage);
}
public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, playerTookDamage);
}

/*
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool& result)
{
	result = true;
	return Plugin_Changed;
}
*/

void activated(ConVar activated, const char[] oldValue, const char[] newValue)
{	
	if(activated.BoolValue == true)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsClientReplay(i) || IsClientSourceTV(i))
				continue;
			
			SDKHook(i, SDKHook_OnTakeDamage, playerTookDamage);
		}
		if(initDone)
			PrintToChatAll("[SM] Reflect Crits has been activated.");
	}
	else 
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientConnected(i) || IsClientReplay(i) || IsClientSourceTV(i))
				continue;
			
			SDKUnhook(i, SDKHook_OnTakeDamage, playerTookDamage);
		}
		if(initDone)
			PrintToChatAll("[SM] Reflect Crits has been deactivated.");
	}
}

Action playerTookDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	if(GetConVarBool(enabled) && damagetype & DMG_ACID)
	{
		new String:weaponName[32];
		GetClientWeapon(attacker, weaponName, sizeof(weaponName));
		
		if(TF2_IsPlayerInCondition(attacker, (TFCond_Kritzkrieged | TFCond_HalloweenCritCandy | TFCond_CritCanteen | TFCond_CritDemoCharge
		| TFCond_CritOnFirstBlood | TFCond_CritOnWin | TFCond_CritOnFlagCapture | TFCond_CritOnKill | TFCond_CritMmmph | TFCond_CritOnDamage)))
			return Plugin_Continue;
			
		else if(
		(TF2_GetPlayerClass(attacker) == TFClass_Sniper && GetEntPropEnt(attacker, Prop_Send, "m_hMyWeapons", 0) == GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon"))
		|| 
		(TF2_GetPlayerClass(attacker) == TFClass_Spy && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 4) == 61) || GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 4) == 1006))
			return Plugin_Continue;
		// if sniper and your equipped weapon is your primary
		// or if spy and your equipped weapon is the ambassador (or festive ambassador)
			
		SDKHooks_TakeDamage(attacker, victim, victim, damage, damagetype, weapon, damageForce, damagePosition);
		return Plugin_Stop;
	}
	else return Plugin_Continue;
}