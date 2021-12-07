#pragma semicolon 1

#define PLUGIN_AUTHOR "joac1144 // Zyanthius"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

// ConVars
ConVar g_damage;
ConVar g_freezeMultiplier;
ConVar g_freezetime;
ConVar g_freezetimemax;
ConVar g_showMessage;

public Plugin myinfo = 
{
	name = "Freeze Nades",
	author = PLUGIN_AUTHOR,
	description = "Grenades freeze targets.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/zyanthius/"
};

public void OnPluginStart()
{
	g_damage = CreateConVar("fn_damage", "1", "Whether or not grenades do damage along with freezing. 1 = damage, 0 = no damage");
	g_freezeMultiplier = CreateConVar("fn_freezemultiplier", "0.15", "How much you multiply with the expected damage to find the freeze time. 50 damage * 0.15 = 7.5 seconds of freeze time. 0.0 = fn_freezetime is used instead.");
	g_freezetime = CreateConVar("fn_freezetime", "0.0", "For how long grenades freeze players. 0.0 = fn_freezemultiplier is used instead.");
	g_freezetimemax = CreateConVar("fn_freezetimemax", "10.0", "The maximum amount of time a player can be frozen.");
	g_showMessage = CreateConVar("fn_showmessage", "1", "Whether or not a message will be displayed in chat when you hit or get hit by someone with a grenade. 1 = message, 0 = no message");
	
	AutoExecConfig(true, "freezenades");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		char classname[32];
		GetEdictClassname(inflictor, classname, sizeof(classname));
		
		if(damagetype == DMG_BLAST && StrEqual(classname, "hegrenade_projectile"))
		{	
			// Freeze players
			SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 0.0);
			SetEntityRenderColor(victim, 0, 0, 255, 170);
			
			char victimName[32];
			GetClientName(victim, victimName, sizeof(victimName));
			char attackerName[32];
			GetClientName(attacker, attackerName, sizeof(attackerName));
			
			// Check if a message should be displayed
			char g_showMessageValue[2];
			g_showMessage.GetString(g_showMessageValue, sizeof(g_showMessageValue));
			
			if(g_freezetime.FloatValue == 0.0)
			{
				if(damage * g_freezeMultiplier.FloatValue >= g_freezetimemax.FloatValue)
				{
					CreateTimer(g_freezetimemax.FloatValue, UnfreezeTimer, victim);
					
					if(StrEqual(g_showMessageValue, "1"))
					{
						PrintToChat(attacker, "[FreezeNades] You froze %s for %f seconds!", victimName, g_freezetimemax.FloatValue);
						PrintToChat(victim, "[FreezeNades] You were frozen by %s for %f seconds!", attackerName, g_freezetimemax.FloatValue);
					}
				}
				else
				{
					CreateTimer(damage * g_freezeMultiplier.FloatValue, UnfreezeTimer, victim);
					
					if(StrEqual(g_showMessageValue, "1"))
					{
						PrintToChat(attacker, "[FreezeNades] You froze %s for %f seconds!", victimName, damage * g_freezeMultiplier.FloatValue);
						PrintToChat(victim, "[FreezeNades] You were frozen by %s for %f seconds!", attackerName, g_freezetimemax.FloatValue);
					}
				}
			}
			else
			{
				CreateTimer(g_freezetime.FloatValue, UnfreezeTimer, victim);
				
				if(StrEqual(g_showMessageValue, "1"))
				{
					PrintToChat(attacker, "[FreezeNades] You froze %s for %f seconds!", victimName, g_freezetime.FloatValue);
					PrintToChat(victim, "[FreezeNades] You were frozen by %s for %f seconds!", attackerName, g_freezetimemax.FloatValue);
				}
			}
			
			// Convert ConVar value to usable value
			char g_damageValue[4];
			g_damage.GetString(g_damageValue, sizeof(g_damageValue));
			
			if(StrEqual(g_damageValue, "0"))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}

// Unfreeze client again
public Action UnfreezeTimer(Handle timer, any victim)
{
	if(IsClientInGame(victim))
	{
		SetEntPropFloat(victim, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityRenderColor(victim, 255, 255, 255, 255);
	}
}