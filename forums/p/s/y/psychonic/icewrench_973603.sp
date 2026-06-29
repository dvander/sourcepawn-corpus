#define FREEZE_DURATION      5

#include <sourcemod>
#include <sdktools>
#include <takedamage>

#pragma semicolon 1

#define PLUGIN_NAME "TF2 Ice Wrench"
#define PLUGIN_VERSION "1.0"

// From funcommands
#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
new Handle:g_FreezeTimers[MAXPLAYERS+1];
new g_FreezeTracker[MAXPLAYERS+1];
new g_GlowSprite;
//

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psychonic",
	description = "Wrench hits cause victim to freeze",
	version = PLUGIN_VERSION,
	url = "http://nicholashastings.com"
};

public OnPluginStart()
{
	CreateConVar("sm_icewrench_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);	
}

// From funcommands
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
//

public Action:OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (inflictor > 0 && inflictor <= MaxClients
		&& IsClientInGame(inflictor) && IsClientInGame(victim)
		&& GetClientHealth(victim) > 0)
	{
		decl String:weapon[64];
		GetClientWeapon(inflictor, weapon, sizeof(weapon));
		if (strncmp(weapon[10], "wrench", 6) == 0)
		{
			FreezeClient(victim, FREEZE_DURATION);
		}
	}
}

// From funcommands to end

FreezeClient(client, time)
{
	if (g_FreezeTimers[client] != INVALID_HANDLE)
	{
		UnfreezeClient(client);
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);
	
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