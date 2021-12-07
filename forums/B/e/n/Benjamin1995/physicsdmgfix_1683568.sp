//Includes:
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define VERSION "1.9"

//DMG Fix
new bool:hooksloaded;


public OnPluginStart()
{
	hooksloaded = (GetExtensionFileStatus("sdkhooks.ext") == 1);	
	if (hooksloaded) 
	{
		
		for(new X = 1; X <= MAXPLAYERS; X++) 
		{
			if(IsClientInGame(X) && IsClientConnected(X))
			{				
				SDKHook(X, SDKHook_OnTakeDamage, OnTakeDamage);		
			}
		}		
	}	
	CreateConVar("benni_physics_damage_fix", VERSION, "Physics Damage Blcok",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED);
}

public OnClientPutInServer(Client) 
{	
	if (hooksloaded) 
	{	
		if(IsClientConnected(Client) && IsClientInGame(Client))
		{		
			SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType) 
{
	if(IsValidEdict(attacker))
	{
		new String:EntName[64];
		GetEdictClassname(attacker, EntName, sizeof(EntName));	
		if(damageType == DMG_CRUSH || StrContains(EntName, "func_physbox", false) != -1)
		{
			damage = 0.0;
			return Plugin_Changed;		
		}
	}
	return Plugin_Continue;
}

public Plugin:myinfo = 
{
	name = "Phys Damage Block",
	author = "Benni aka benjamin1995",
	description = "Blocks Physics Damage",
	version = VERSION,
	url = "http://www.source-minecraft.net"
}
