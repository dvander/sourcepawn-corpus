#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Float:g_ClientVel[MAXPLAYERS+1][3];
new bool:g_bClientShouldBoost[MAXPLAYERS+1];
new bool:g_bClientDoBoost[MAXPLAYERS+1];
new bool:g_bClientEnabled[MAXPLAYERS+1];

new Float:g_ArrVictimVel[MAXPLAYERS+1][128][3];
new g_ClientTicker[MAXPLAYERS+1];

new Handle:g_hEnable			= INVALID_HANDLE;
new Handle:g_hDudXYSpeed			= INVALID_HANDLE;
new Handle:g_hDudZSpeed			= INVALID_HANDLE;
new Handle:g_hDudDelayTicks 	= INVALID_HANDLE;

new bool:g_bEnabled			= true;
new Float:g_fDudXSpeed		= 0.892;
new Float:g_fDudZSpeed		= 1.0;
new g_iDudDelayTicks 		= 1;

new Handle:g_hRemoveTimer[2048];

public Plugin:myinfo = 
{
	name		= "Flashboost Fix",
	author		= "mev, zipcore, m_bNightstalker",
	description	= "Fixes flashboost for trikz & removes flashbangs on hit and before detonate",
	version		= "1.1",
	url			= ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_bug", Cmd_ClientEnabled, "Toggle the flashboost bugfix");
	
	g_hEnable = CreateConVar("flashbooster_enabled", "1", "Sets whether flashboost fix is enabled or not", _, true, 0.0, true, 1.0);
	g_hDudXYSpeed = CreateConVar("flashbooster_xyspeed", "0.892", "Sets boost gained in X axis on a flashboost (Tested by snow - he recommended 0.892 for X & Y axis)");
	g_hDudZSpeed = CreateConVar("flashbooster_zspeed", "1.0", "Sets boost gained in Z axis on a flashboost (Tested by snow - he recommended 1.0 for Z axis)");
	g_hDudDelayTicks = CreateConVar("flashbooster_delayticks", "1", "Picks the speed from X ticks ago and then apply boost to that speed (0 is buggy)");
	
	HookConVarChange(g_hEnable, ConVarChanged_Enable);
	HookConVarChange(g_hDudXYSpeed, ConVarChanged_XSpeed);
	HookConVarChange(g_hDudZSpeed, ConVarChanged_ZSpeed);
	HookConVarChange(g_hDudDelayTicks, ConVarChanged_DelayTicks);
	
	AutoExecConfig(true, "flashboost_fix");
}

public ConVarChanged_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_bEnabled = GetConVarBool(g_hEnable);
public ConVarChanged_XSpeed(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_fDudXSpeed = GetConVarFloat(g_hDudXYSpeed);
public ConVarChanged_ZSpeed(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_fDudZSpeed = GetConVarFloat(g_hDudZSpeed);
public ConVarChanged_DelayTicks(Handle:cvar, const String:oldVal[], const String:newVal[])
	g_iDudDelayTicks = GetConVarInt(g_hDudDelayTicks);

public OnClientPutInServer(iClient)
{
	g_bClientEnabled[iClient] = true;
	SDKHook(iClient, SDKHook_TraceAttack, OnTraceAttack);
}

public OnClientDisconnect(iClient)
{
	g_bClientEnabled[iClient] = false;
	SDKUnhook(iClient, SDKHook_TraceAttack, OnTraceAttack);
}

public Action:Cmd_ClientEnabled(client, args)
{
	if (g_bClientEnabled[client] == true)
	{
		g_bClientEnabled[client] = false;
		PrintToChat(client, "Flashboost fix disabled");
	}
	else if (g_bClientEnabled[client] == false)
	{
		g_bClientEnabled[client] = true;
		PrintToChat(client, "Flashboost fix enabled");
	}
	return Plugin_Handled;
}

/* Boost player */

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		decl Float:vClientVel[3];
		
		if(g_bEnabled)
		{
			if(g_ClientTicker[client] >= 128)
				g_ClientTicker[client] = 0;
			
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vClientVel);
			g_ArrVictimVel[client][g_ClientTicker[client]] = vClientVel;
		}
		
		if(g_bClientShouldBoost[client] && g_bEnabled)
		{
			g_bClientDoBoost[client] = true;
			g_bClientShouldBoost[client] = false;
		}
		else if(g_bClientDoBoost[client] && g_bEnabled)
		{
			if(g_bClientEnabled[client])
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_ClientVel[client]);
			
			g_bClientDoBoost[client] = false;
		}
		g_ClientTicker[client]++;
	}
}

/* Check for flashboost */

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	new String:sWeapon[32];
	GetEdictClassname(inflictor, sWeapon, 32);
	
	if(StrContains(sWeapon, "flashbang", false) == -1)
		return Plugin_Continue;
	
	if(victim == attacker)
		return Plugin_Continue;
	
	if(!IsValidClient(victim) || !IsValidClient(victim) || !g_bEnabled)
		return Plugin_Continue;
	
	if (damagetype & DMG_FALL)
		return Plugin_Handled;
	
	new iFlashbang = EntRefToEntIndex(inflictor);
	
	if (IsValidEntity(iFlashbang))
		CheckFlashboost(iFlashbang, victim);
	
	return Plugin_Continue;
}

public Action:Timer_KillFlashbang(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE)
		AcceptEntityInput(entity, "Kill");
	
	/* Close the other timer */
	if(g_hRemoveTimer[entity] != INVALID_HANDLE)
	{
		CloseHandle(g_hRemoveTimer[entity]);
		g_hRemoveTimer[entity] = INVALID_HANDLE;
	}
}

/* Remove flashbangs before detonate */

public OnEntityCreated(entity, const String:classname[])
{
    if (StrContains(classname, "flashbang_projectile") != -1)
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

public OnSpawnPost(entity)
{
	g_hRemoveTimer[entity] = CreateTimer(1.45, Timer_KillFlashbang2, entity);
}

public Action:Timer_KillFlashbang2(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE)
		AcceptEntityInput(entity, "Kill");
	
	g_hRemoveTimer[entity] = INVALID_HANDLE;
}

stock CheckFlashboost(flashbang, client)
{
	decl Float:flashOri[3], Float:victimOri[3], Float:victimVel[3];				
	
	GetEntPropVector(flashbang, Prop_Data, "m_vecAbsOrigin", flashOri);
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", victimOri);
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", victimVel);
	
	if(GetEngineVersion() == Engine_CSGO)
		victimOri[2] += 32.0;
	
	if(victimOri[2] >= flashOri[2] && victimVel[2] != 0)
	{
		decl Float:vBoost[3], Float:vVelFlash[3];
		decl iTick;
		
		iTick = g_ClientTicker[client] - g_iDudDelayTicks;
		if(iTick < 0)
			iTick += 128;
		
		GetEntPropVector(flashbang, Prop_Data, "m_vecAbsVelocity", vVelFlash);
		
		vBoost[0] = g_ArrVictimVel[client][iTick][0] - vVelFlash[0] * g_fDudXSpeed;
		vBoost[1] = g_ArrVictimVel[client][iTick][1] - vVelFlash[1] * g_fDudXSpeed;
		vBoost[2] = FloatAbs(vVelFlash[2] * g_fDudZSpeed);
		
		g_bClientShouldBoost[client] = true;
		
		g_ClientVel[client] = vBoost;
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, g_ClientVel[client]);
	}
	
	if(g_bClientEnabled[client])
		CreateTimer(0.0, Timer_KillFlashbang, flashbang);
}

/* Stocks */

stock bool:IsValidClient(iClient)
{
	if (iClient < 1 || iClient > MaxClients || !IsClientConnected(iClient))
		return false;
	
	return true;
}
