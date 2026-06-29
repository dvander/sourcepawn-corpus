#include <sourcemod>
#include <sdkhooks>
#include <weaponsystem>

#define PLUGIN_VERSION "0.0.5"

new Handle:g_imode, Handle:g_iknife;

public Plugin:myinfo = 
{
	name = "Head Shot Modes",
	author = "SavSin",
	description = "Choose different head shot modes.",
	version = PLUGIN_VERSION,
	url = "www.xvgaming.com"
}

public OnPluginStart()
{
	CreateConVar("HsMode_Version", PLUGIN_VERSION, "Version of Head Shot Modes", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_imode = CreateConVar("hs_mode", "1", "Changes the head shot mode", 0, true, 0.0, true, 3.0);
	g_iknife = CreateConVar("hs_knife", "1", "Ignores Knife attacks");
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, HookTraceAttack);
}

public Action:HookTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, HitGroup)
{
	if (!attacker || attacker > MaxClients)  // attacker is 0
		return Plugin_Continue;
		
	decl String:szWeapon[32];
	GetClientWeapon(attacker, szWeapon, sizeof(szWeapon));
	
	switch(GetConVarInt(g_imode))
	{
		case 1:
		{
			if(IsFakeClient(attacker) && HitGroup == 1)
			{
				if(GetConVarInt(g_iknife))
				{
					if(GetWeaponID(szWeapon) != WEAPON_KNIFE)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
				else
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
		case 2:
		{
			if(GetConVarInt(g_iknife))
			{
				if(GetWeaponID(szWeapon) != WEAPON_KNIFE)
				{
					if(HitGroup == 1)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
			}
			else
			{
				if(HitGroup == 1)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
			
		}
		case 3:
		{
			if(GetConVarInt(g_iknife))
			{
				if(StrContains("weapon_knife", szWeapon) == -1)
				{
					if(HitGroup != 1)
					{
						damage = 0.0;
						return Plugin_Changed;
					}
				}
			}
			else
			{
				if(HitGroup != 1)
				{
					damage = 0.0;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}