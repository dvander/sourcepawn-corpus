#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

#define VERSION 	"2.3.3"
new Handle:v_Enable = INVALID_HANDLE;
new Handle:v_TTL = INVALID_HANDLE;
new g_LastSandvich[MAXPLAYERS+1] = -1;

public Plugin:myinfo =
{
	name 	= "[TF2] Olde Sandvich",
	author = "DarthNinja",
	description = "Sandvich work as before the 2/14/2012 update (ie; they heal when dropped)",
	version = VERSION,
};

public OnPluginStart()
{
	CreateConVar("sm_olde_sandvich_version", VERSION, "Plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	v_Enable = CreateConVar("sm_olde_sandvich_enable", "1", "Enable/Disable the plugin.", 0, true, 0.0, true, 1.0);
	v_TTL = CreateConVar("sm_olde_sandvich_ttl", "30", "How many seconds dropped sandviches last.", 0, true, 5.0);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(GetConVarBool(v_Enable) && StrEqual(classname, "item_healthkit_medium"))
	{
		SDKHook(entity, SDKHook_StartTouch, TouchinSandvich);
		SDKHook(entity, SDKHook_SpawnPost, OnFoodSpawned);
	}
}

public OnFoodSpawned(iSandvich)
{
	// Owner of the new sandvich
	new iOwner = GetEntPropEnt(iSandvich, Prop_Data, "m_hOwnerEntity");
	//Todo: add model check here at some point
	if (iOwner != -1 && iOwner <= MAXPLAYERS && g_LastSandvich[iOwner] != -1 && IsValidEntity(g_LastSandvich[iOwner]))
	{
		// Looks like this player already has a sandvich deployed
		// Lets make sure that it's an item_healthkit_medium and not something else that we wouldnt want to kill
		new String:classname[256];
		GetEntityClassname(g_LastSandvich[iOwner], classname, sizeof(classname))
		if (StrEqual(classname, "item_healthkit_medium"))
		{
			// Yep, they already have one out there.  They should only have one at a time, so lets kill it.
			AcceptEntityInput(g_LastSandvich[iOwner], "Kill");
			g_LastSandvich[iOwner] = -1;
		}	
	}
}


public TouchinSandvich(iHookedEnt, iTouchingEnt)
{
	new iOwner = GetEntPropEnt(iHookedEnt, Prop_Data, "m_hOwnerEntity");
	if(iOwner > 0 && iOwner <= MaxClients && IsClientInGame(iOwner) && TF2_GetPlayerClass(iOwner) == TFClass_Heavy && iOwner == iTouchingEnt)
	{
		//Owner is a valid client, so it's not some map spawn.  Now is it a dropped sandvich?
		// I'd much rather validate this by model, but since that doesnt seem to work for shit (the model returns as the medpack model)
		// Soooo we'll just see if the client is a heavy
		// We'll also check if the owner is the player touching it - if it's another player, we dont need to do shit.
		new newSandvich = CreateEntityByName("item_healthkit_medium");

		if(IsValidEntity(newSandvich))
		{
			SetEntProp(iHookedEnt, Prop_Data, "m_bDisabled", 1);	// disable it so it cant get picked up before we kill it

			new Float:pos[3];
			GetEntPropVector(iHookedEnt, Prop_Send, "m_vecOrigin", pos);	//Grab the location
			AcceptEntityInput(iHookedEnt, "Kill");	// Kill the old one
			//new owner = GetEntPropEnt(oldSandvich, Prop_Data, "m_hOwnerEntity");	//Owner
			//SetEntPropEnt(newSandvich, Prop_Data, "m_hOwnerEntity", owner);	//Set the owner	//if we set the owner as the heavy, TF2 does the ammo action crap

			DispatchKeyValue(newSandvich, "powerup_model", "models/items/plate.mdl");	// Set the correct model
			DispatchSpawn(newSandvich);	// Spawn the new one

			TeleportEntity(newSandvich, pos, NULL_VECTOR, NULL_VECTOR);	// teleport to old one's location
			CreateTimer(GetConVarFloat(v_TTL), KillSandvich, newSandvich);
			g_LastSandvich[iOwner] = newSandvich;
		}
	}
}

public Action:KillSandvich(Handle:hTimer, any:iSandvich)
{
	if(IsValidEntity(iSandvich))
		AcceptEntityInput(iSandvich, "Kill");
	return Plugin_Continue;
}  
