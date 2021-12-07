#include <tf2_stocks>
#define PLUGIN_VERSION "1.0.0"

new monorockets[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
	name = "[TF2] Soldier Eyerockets!",
	author = "Oshizu",
	description = "Changes Soldier Rockets into Eyerockets",
	version = PLUGIN_VERSION,
	url = "None"
}

public OnPluginStart()
{
	RegAdminCmd("sm_eyerockets", mono_rockets, ADMFLAG_GENERIC);
	HookEvent("player_death", player_dead, EventHookMode_Pre);
	HookEvent("object_destroyed", object_destroyed, EventHookMode_Pre);
}

public Action:player_dead( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new attacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if(monorockets[attacker])
	{
	//	if(TF2_GetPlayerClass(attacker) == TFClass_Soldier)
	//	{
			if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_ROCKETLAUNCHER)
			{
				if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_DIRECTHIT)
				{
					return Plugin_Continue;
				}
			}
		
			SetEventString( hEvent, "weapon", "eyeball_rocket" );
			SetEventInt( hEvent, "weaponid", 0 );
			SetEventInt( hEvent, "customkill", TF_CUSTOM_EYEBALL_ROCKET );
			
			return Plugin_Continue;
	//	}
	}
	return Plugin_Continue;
}

public Action:object_destroyed( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new attacker = GetClientOfUserId( GetEventInt( hEvent, "attacker" ) );
	if(monorockets[attacker])
	{
	//	if(TF2_GetPlayerClass(attacker) == TFClass_Soldier)
	//	{
			if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_ROCKETLAUNCHER)
			{
				if(GetEventInt(hEvent, "weaponid")!=TF_WEAPON_DIRECTHIT) //
				{
					return Plugin_Continue;
				}
			}
		
			SetEventString( hEvent, "weapon", "eyeball_rocket" );
			SetEventInt( hEvent, "weaponid", 0 );
		
			return Plugin_Continue;
	//	}
	}
	return Plugin_Continue;
}

public Action:mono_rockets(client, args)
{
	if(monorockets[client])
	{
		monorockets[client] = false;
		PrintToChat(client, "Eyerockets Disabled")
	}
	else if(!monorockets[client])
	{
		monorockets[client] = true;
		PrintToChat(client, "Eyerockets Enabled")
	}
}

public OnMapStart()
{
	PrecacheModel("models/props_halloween/eyeball_projectile.mdl");	
}

public OnGameFrame()
{
	new entity = -1; 
	while ((entity=FindEntityByClassname(entity, "tf_projectile_rocket"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(client))
			{
				if(monorockets[client])
				{
					SetEntityModel(entity, "models/props_halloween/eyeball_projectile.mdl"); 
				}
			}
		}
	}
}

/// Stocks
stock bool:IsValidClient(iClient, bool:bReplay = true) 
{ 
    if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient)) 
        return false; 
    if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient))) 
        return false; 
    return true; 
}