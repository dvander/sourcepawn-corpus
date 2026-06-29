#include <sourcemod>
#include <sdkhooks>

new Handle:g_hMaxRange;

public OnPluginStart()
{
	g_hMaxRange = CreateConVar("sm_rifle_maxrange", "8192.0", "Maximum range of the sniper rifle");
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	decl String:strWeapon[32];
	GetEdictClassname(inflictor, strWeapon, sizeof(strWeapon));
	
	if(strcmp(strWeapon, "tf_weapon_sniperrifle") == 0)
	{
		if(victim && attacker && IsClientInGame(victim) && IsClientInGame(attacker))
		{
			decl Float:flPos1[3];
			GetClientAbsOrigin(victim, flPos1);
			decl Float:flPos2[3];
			GetClientAbsOrigin(attacker, flPos2);
			
			if(GetVectorDistance(flPos1, flPos2) >= GetConVarFloat(g_hMaxRange))
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	return Plugin_Continue;
}
