// rage_freeze:		arg0 - slot (def.0)
//						arg1 - freeze duration

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"

new BossTeam=_:TFTeam_Blue;
new Handle:g_FreezeTimers[MAXPLAYERS+1];
new g_FreezeTracker[MAXPLAYERS+1];
new g_GlowSprite;

public Plugin:myinfo = {
	name = "Freak Fortress 2: rage_freeze",
	author = "Jery0987",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.3,Timer_GetBossTeam);
	return Plugin_Continue;
}

public Action:Timer_GetBossTeam(Handle:hTimer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_freeze"))
		Rage_Freeze(index,ability_name);
	return Plugin_Continue;
}

Rage_Freeze(index,const String:ability_name[])
{
	decl i;
	for(i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			FreezeClient(i,FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,5.0));
		}
}

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

public Action:Timer_Freeze(Handle:timer, any:client)
{
	if (!IsClientInGame(client))
	{
		KillFreezeTimer(client);

		return Plugin_Continue;
	}
	
	if (!IsPlayerAlive(client))
	{
		UnfreezeClient(client);
		
		return Plugin_Continue;
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

	return Plugin_Continue;
}