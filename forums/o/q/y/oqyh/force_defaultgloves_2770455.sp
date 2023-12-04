#include <sourcemod> 
#include <sdktools>

// define default gloves
#define CTARMS "models/weapons/ct_arms.mdl" 
#define TTARMS "models/weapons/t_arms.mdl" 


public Plugin myinfo = 
{
	name = "SM Force Default Gloves", 
	author = "Franc1sco franug", 
	description = "", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart() 
{
	HookEvent("player_spawn", PlayerSpawn); 
}

public void OnMapStart() 
{ 
	// precache default gloves
	PrecacheModel(CTARMS, true); 
	PrecacheModel(TTARMS, true); 
} 

public Action PlayerSpawn(Handle event, const char[] name, bool dbc) 
{ 
	int client = GetClientOfUserId(GetEventInt(event, "userid")); 
     
	if(client) 
	{
		// kill custom gloves if he have it
		int ent = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
		if(ent != -1)
		{
			AcceptEntityInput(ent, "KillHierarchy");
		}
		
		// set default gloves to prevent "no arms" bug
		switch(GetClientTeam(client)) 
		{ 
			case 2: SetEntPropString(client, Prop_Send, "m_szArmsModel", TTARMS); 
			case 3: SetEntPropString(client, Prop_Send, "m_szArmsModel", CTARMS); 
		} 
	} 
}  