#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
}
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsValidClient(i) && IsPlayerAlive(i))
        	RemoveExtraKnives(i);	
    }
}
public void RemoveExtraKnives(int client)
{
    int size = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
    bool haveKnife = false;
    
    for (int i = 0; i < size; i++) // run for all the weapons that player have
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
        if (IsValidEdict(weapon) && IsValidEntity(weapon))
        {
            char weaponClass[64];
            if (!GetEdictClassname(weapon, weaponClass, sizeof(weaponClass)))continue; // if invalid entity then continue
            
            if(StrContains(weaponClass, "weapon_knife", false) == 0 || StrContains(weaponClass, "weapon_bayonet", false) == 0) // knife entity
            {
                if(haveKnife) // player already have knife and this is other knife?
                {
                    // delete extra knife because he only need one
                    RemovePlayerItem(client, weapon);
                    AcceptEntityInput(weapon, "Kill");
                }
                haveKnife = true; // set that player have knife
            }
            
        }
    }        
} 

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client);
}	
