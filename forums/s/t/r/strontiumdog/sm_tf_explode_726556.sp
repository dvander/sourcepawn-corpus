#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.102"

new Handle:Cvar_Explode = INVALID_HANDLE

new g_Explode[MAXPLAYERS+1]

// Functions
public Plugin:myinfo =
{
	name = "Explode",
	author = "<eVa>Dog",
	description = "Allow players to gib again!",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_tf_explode_version", PLUGIN_VERSION, " Explode Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_Explode = CreateConVar("sm_explode_enabled", "1", " Allow players to suicide with gibs", FCVAR_PLUGIN)
	
	RegConsoleCmd("explode", Command_Explode, " restoring VALVe's suicide function")
	
	HookEvent("player_death", PlayerDeath)
}

public OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeath)
}


public Action:Command_Explode(client, args)
{
	if (GetConVarInt(Cvar_Explode))
	{
		if (client > 0)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				g_Explode[client] = 1
				ForcePlayerSuicide(client)
			}
		}
	}
	return Plugin_Handled
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (g_Explode[client])
	{
		CreateTimer(0.1, DeleteRagdoll, client)
		
		decl Ent
		decl Float:ClientOrigin[3]

		//Initialize:
		Ent = CreateEntityByName("tf_ragdoll")
		GetClientAbsOrigin(client, ClientOrigin)

		//Write:
		SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", ClientOrigin)
		SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client)
		SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR)
		SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR)
		SetEntProp(Ent, Prop_Send, "m_bGib", 1)

		//Send:
		DispatchSpawn(Ent)
		
		CreateTimer(8.0, DeleteGibs, Ent)
		
		g_Explode[client] = 0
	}
}

public Action:DeleteRagdoll(Handle:timer, any:client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll")
	
	if (IsValidEdict(ragdoll))
    {
        RemoveEdict(ragdoll)
    }
}

public Action:DeleteGibs(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
    {
        new String:classname[256]
        GetEdictClassname(ent, classname, sizeof(classname))
        if (StrEqual(classname, "tf_ragdoll", false))
        {
            RemoveEdict(ent)
        }
    }
}
