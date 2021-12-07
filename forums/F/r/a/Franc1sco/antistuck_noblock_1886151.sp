#include <sourcemod>
#include <sdktools>

#define VERSION "1.1"

public Plugin:myinfo = 
{
	name = "SM Anti-Stuck NoBlock",
	author = "Franc1sco steam: franug",
	description = "give to all players a simple Anti-Stuck NoBlock",
	version = VERSION,
	url = "http://servers-cfg.foroactivo.com/"
};

new Handle:sm_noblock;

new bool:enable;

#define COLLISION_GROUP_PUSHAWAY            17
#define COLLISION_GROUP_PLAYER              5 

public OnPluginStart()
{
	HookEvent("player_spawn", OnSpawn);

	sm_noblock = CreateConVar("sm_antistucknoblock", "1", "Removes player vs. player stuck. 1 = enable, 0 = disable");
	CreateConVar("sm_antistucknoblock_version", VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookConVarChange(sm_noblock, OnCVarChange);
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

public OnConfigsExecuted()
{
	GetCVars();
}

public OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!enable)
		return;

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY); 
}


// Get new values of cvars if they has being changed
public GetCVars()
{
	enable = GetConVarBool(sm_noblock);
	if(enable)
		EnableBlock();


	else
		DisableBlock();
}

DisableBlock()
{
  		for (new i = 1; i < GetMaxClients(); i++)
			if (IsClientInGame(i) && IsPlayerAlive(i))
				SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
}

EnableBlock()
{
  		for (new i = 1; i < GetMaxClients(); i++)
			if (IsClientInGame(i) && IsPlayerAlive(i))
				SetEntProp(i, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
}
