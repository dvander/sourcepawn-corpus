#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define PLUGIN_NAME "TF2 Fire Jarate"
#define PLUGIN_VERSION "3.1"

#define MDL_JAR "models/props_gameplay/bottle001.mdl"
// From funcommands
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define FREEZE_DURATION      7

new Handle:g_FreezeTimers[MAXPLAYERS+1];
new g_FreezeTracker[MAXPLAYERS+1];
new g_GlowSprite;
new Handle:cvModel = INVALID_HANDLE;
new String:model[512];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psychonic, TheSpyHunter, L.Duke",
	description = "Jarate cause victim to catch on fire",
	version = PLUGIN_VERSION,
	url = "http://www.ultimatefragforce.co.uk"
};

public OnPluginStart()
{
	CreateConVar("sm_firejarate_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvModel = CreateConVar("sm_jar_model", MDL_JAR, "model for jarate bomb");
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);	
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnConfigsExecuted()
{
	GetConVarString(cvModel, model, sizeof(model));
	PrecacheModel(model, true);
}

public OnMapStart()
{
	if (!IsSoundPrecached(SOUND_FREEZE))
	{
		PrecacheSound(SOUND_FREEZE, true);
	}
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	
}

public OnMapEnd()
{
	KillAllFreezes();
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
	KillAllFreezes();
	return Plugin_Handled;
}

public Action:Event_PlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && (TF2_GetPlayerClass(client) != TFClass_Sniper)) return;
	new iWeapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(iWeapon))
	{
		if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{
			SetHudTextParams(0.2, -1.0, 5.0, 255, 50, 50, 255);
			ShowHudText(client, -1, "[JARATE] Flames Enemys or Freezes Pyros!");
		}
	}
}


public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (inflictor > 0 && inflictor <= MaxClients
	&& IsClientInGame(inflictor) && IsClientInGame(victim) 
	&& GetClientHealth(victim) > 0)
	{
		if ((GetUserFlagBits(victim) & ADMFLAG_KICK) && GetEntData(victim, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & (1 << 22))
		{
			PrintCenterText(victim, "IMMNUITY FROM THE EVIL JARATE!");
			PrintCenterText(attacker, "[FIRE JARATE] PLAYER HAS EVIL JARATE IMMUNITY!");
		} else
		{	
			if (IsClientInGame(victim) && (TF2_GetPlayerClass(victim) == TFClass_Pyro) && GetEntData(victim, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & (1 << 22))
			{
				FreezeClient(victim, FREEZE_DURATION);
				PrintCenterText(victim, "ICE COOL PISS! CHILL FOR A FEW SECONDS!");
				PrintCenterText(attacker, "[ICE JARATE] YOU SPARKED THE ICE REACTION!");
			} else {
				if (IsClientInGame(victim) && GetEntData(victim, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & (1 << 22))
				{
					TF2_IgnitePlayer(victim, attacker);
					PrintCenterText(victim, "MEDIC! SOMEONE IGNITED THE SNIPERS FLAMABLE PISS!");
					PrintCenterText(attacker, "[FIRE JARATE] YOU IGNITED THAT POOR PLAYER!");
				} 
			}
		}
	}
}

public OnEntityCreated(entity)
{
	SDKHook(entity, SDKHook_Spawn, EntSpawn);
}

public Action:EntSpawn(entity)
{
	new String:g_sClassName[64];
	GetEntityClassname(entity, g_sClassName, sizeof(g_sClassName));
	
	if (StrEqual(g_sClassName, "tf_projectile_jar"))
	{
		SetEntityModel(entity, model);
	}
	return;
}

// From funcommands to end

FreezeClient(client, time)
{
	if (g_FreezeTimers[client] != INVALID_HANDLE)
	{
		UnfreezeClient(client);
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 222);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	g_FreezeTimers[client] = CreateTimer(1.0, Timer_Freeze, client, TIMER_REPEAT);
	g_FreezeTracker[client] = time;
}

UnfreezeClient(client)
{
	KillFreezeTimer(client);
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;	
	
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetEntityRenderColor(client, 255, 255, 255, 255);	
}

KillFreezeTimer(client)
{
	KillTimer(g_FreezeTimers[client]);
	g_FreezeTimers[client] = INVALID_HANDLE;
}

KillAllFreezes()
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++)
	{
		if (g_FreezeTimers[i] != INVALID_HANDLE)
		{
			if(IsClientInGame(i))
			{
				UnfreezeClient(i);
			}
			else
			{
				KillFreezeTimer(i);
			}			
		}
	}
}

public Action:Timer_Freeze(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillFreezeTimer(client);
		
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		UnfreezeClient(client);
		
		return Plugin_Handled;
	}		
	
	g_FreezeTracker[client]--;
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 135);
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	TE_SetupGlowSprite(vec, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();	
	
	if (g_FreezeTracker[client] == 0)
	{
		UnfreezeClient(client);
	}
	
	return Plugin_Handled;
}

stock bool:IsValidClient(client)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}