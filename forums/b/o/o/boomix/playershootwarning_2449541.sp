#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "boomix && Grey83"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdkhooks>

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1))

public Plugin myinfo = 
{
	name = "Warning: shooting others",
	author = PLUGIN_AUTHOR,
	description = "Warns in chat, that player is shooting others",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public void OnPluginStart()
{
	LoopAllPlayers(i)
		SDKHook(i, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{
	
    if(damagetype & DMG_BULLET || damagetype & DMG_BUCKSHOT)
    {
    	damage = 0.0;
    	PrintToChatAll("\x1 \x2 Warning:\x1 Player\x3 %N\x1 is shooting others!", attacker);
    	return Plugin_Handled; 
    }
    
    return Plugin_Continue;
}  