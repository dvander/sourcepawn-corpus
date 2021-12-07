#include <sourcemod> 
#include <tf2> 
#define PLUGIN_VERSION "1.5" 

new bool:ToggleTags = true; 
public Plugin:myinfo =  
{ 
	name = "Instant Respawn", 
	author = "ChauffeR", 
	version = PLUGIN_VERSION, 
	url = "" 
} 

public OnPluginStart() 
{ 
	CreateConVar("sm_tf2_instantrespawn", PLUGIN_VERSION, "Plugin Version of [TF2] Instant Respawn", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD); 
	HookEvent("player_death", OnPlayerDeath); 
	
	if(TagsContain("norespawntime")) 
	{ 
		ToggleTags = false; 
	} 
	TagsCheck("norespawntime"); 
} 

public OnPluginEnd() 
{ 
	if(ToggleTags == true) 
	{ 
		TagsCheck("norespawntime", true); 
	} 
} 

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	RequestFrame(Respawn, GetClientSerial(client)); 
} 

public Respawn(any:serial) 
{ 
	new client = GetClientFromSerial(serial); 
	if(client != 0) 
	{ 
		new team = GetClientTeam(client); 
		if(!IsPlayerAlive(client) && team != 1 && CheckCommandAccess(client, "sm_tag", ADMFLAG_CUSTOM6))
		{ 
			TF2_RespawnPlayer(client); 
		}
		if(!IsPlayerAlive(client) && team != 1 && IsFakeClient(client))
		{ 
			TF2_RespawnPlayer(client); 
		}
	} 
} 

public bool:TagsContain(const String:tag[]) 
{ 
	new Handle:hTags = FindConVar("sv_tags"); 
	decl String:tags[255]; 
	GetConVarString(hTags, tags, sizeof(tags)); 
	if(StrContains(tags, tag) > -1) 
	{ 
		return true; 
	} 
	else 
	{ 
		return false; 
	} 
} 

/* 
Stock from WoZeR's code 
*/ 

stock TagsCheck(const String:tag[], bool:remove = false) 
{ 
	new Handle:hTags = FindConVar("sv_tags"); 
	decl String:tags[255]; 
	GetConVarString(hTags, tags, sizeof(tags)); 

	if (StrContains(tags, tag, false) == -1 && !remove) 
	{ 
		decl String:newTags[255]; 
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag); 
		ReplaceString(newTags, sizeof(newTags), ",,", ",", false); 
		SetConVarString(hTags, newTags); 
		GetConVarString(hTags, tags, sizeof(tags)); 
	} 
	else if (StrContains(tags, tag, false) > -1 && remove) 
	{ 
		ReplaceString(tags, sizeof(tags), tag, "", false); 
		ReplaceString(tags, sizeof(tags), ",,", ",", false); 
		SetConVarString(hTags, tags); 
	} 
}