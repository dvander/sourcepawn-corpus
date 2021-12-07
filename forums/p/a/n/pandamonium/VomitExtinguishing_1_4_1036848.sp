
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.4"

new Handle:hVomit_Range;
new Float:gVomit_Range;
new Handle:hVomit_Duration;
new Float:gVomit_Duration;
new Handle:VomitTimer[MAXPLAYERS+1];
new Handle:hSplash_Enabled;
new Handle:hExtinguishRadius;
new Float:gExtinguishRadius;
new bool:gSplash_Enabled;
new propinfoburn = -1;
new propinfoghost = -1;
public Plugin:myinfo = 

{
	name = "Vomit extinguishing",
	author = "Olj",
	description = "Vomit or boomer explosion can extinguish burning special infected",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
	{
		CreateConVar("l4d2_ve_version", PLUGIN_VERSION, "Version of Vomit Extinguishing plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		hVomit_Duration = FindConVar("z_vomit_duration");
		hVomit_Range = FindConVar("z_vomit_range");
		hSplash_Enabled = CreateConVar("l4d2_ve_splash_enabled", "1", " Enable/Disable boomer explosion to extinguish also ", CVAR_FLAGS);
		hExtinguishRadius = CreateConVar("l4d2_ve_splash_radius", "200", "Extinguish radius of boomer explosion", CVAR_FLAGS);
		gExtinguishRadius = GetConVarFloat(hExtinguishRadius);
		gVomit_Duration = GetConVarFloat(hVomit_Duration);
		gVomit_Range = GetConVarFloat(hVomit_Range);
		gSplash_Enabled = GetConVarBool(hSplash_Enabled);
		HookEvent("ability_use", Vomit_Event);
		HookEvent("player_death", Splash_Event, EventHookMode_Pre);
		HookConVarChange(hVomit_Range, Vomit_RangeChanged);
		HookConVarChange(hVomit_Duration, Vomit_DurationChanged);
		HookConVarChange(hSplash_Enabled, Splash_EnabledChanged);
		HookConVarChange(hExtinguishRadius, ExtinguishRadiusChanged);
		propinfoburn = FindSendPropInfo("CTerrorPlayer", "m_burnPercent");
		propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
		AutoExecConfig(true, "l4d2_vomitextinguishing");
	}

public ExtinguishRadiusChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gExtinguishRadius = GetConVarFloat(hExtinguishRadius);
	}			
	
public Splash_EnabledChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gSplash_Enabled = GetConVarBool(hSplash_Enabled);
	}			
	
public Vomit_RangeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gVomit_Range = GetConVarFloat(hVomit_Range);
	}			

public Vomit_DurationChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		gVomit_Duration = GetConVarFloat(hVomit_Duration);
	}			
	
public Action:Splash_Event(Handle:event, const String:name[], bool:dontBroadcast)
	{
		if (!gSplash_Enabled) return Plugin_Continue;
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if ((victim==0)||(!IsClientConnected(victim))||(!IsClientInGame(victim))) return Plugin_Continue;
		if ((GetClientTeam(victim)!=3)||(IsGhost(victim))) return Plugin_Continue;
		decl String:victim_name[128];
		GetEventString(event, "victimname", victim_name, sizeof(victim));
		if (StrContains(victim_name, "boomer", false)!=-1)
			{
				new Float:Boomer_Position[3];
				GetClientAbsOrigin(victim,Boomer_Position);
				for (new target = 1; target <=MaxClients; target++)
					{
						if ((IsValidClient(target))&&(GetClientTeam(target)==3)&&(IsPlayerBurning(target)))
							{
								new Float:Target_Position[3];
								GetClientAbsOrigin(target, Target_Position);
								new SplashDistance = RoundToNearest(GetVectorDistance(Target_Position, Boomer_Position));
								if (SplashDistance<gExtinguishRadius)
									{
										ExtinguishEntity(target);
									}
							}
					}
			}
		return Plugin_Continue;
	}
	
public Vomit_Event(Handle:event, const String:name[], bool:dontBroadcast)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid")); //we get client
		if ((!IsValidClient(client))||(GetClientTeam(client)!=3)) return; //must be valid infected
		decl String:model[128];
		GetClientModel(client, model, sizeof(model));
		if (StrContains(model, "boomer", false)!=-1)
			{
				VomitTimer[client] = CreateTimer(0.1, VomitTimerFunction, any:client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				CreateTimer(gVomit_Duration,KillingVomitTimer, any:client,TIMER_FLAG_NO_MAPCHANGE);
			}
	}

public Action:VomitTimerFunction(Handle:timer, any:client)
	{
		if ((!IsValidClient(client))||(GetClientTeam(client)!=3))
			{
				VomitTimer[client] = INVALID_HANDLE;
				return Plugin_Stop;
			}
		new target = GetClientAimTarget(client, true);
		if ((target == -1) || (target == -2)) return Plugin_Continue;
		if ((!IsValidClient(target))||(GetClientTeam(target)!=3)) return Plugin_Continue;
		if (!IsPlayerBurning(target)) return Plugin_Continue;
		new Float:boomer_position[3];
		new Float:target_position[3];
		GetClientAbsOrigin(client,boomer_position);
		GetClientAbsOrigin(target,target_position);
		new distance = RoundToNearest(GetVectorDistance(boomer_position, target_position));
		if ((distance<gVomit_Range)&&(IsPlayerBurning(target)))
			{
				ExtinguishEntity(target);
			}
		return Plugin_Continue;
	}

public Action:KillingVomitTimer(Handle:timer, any:client)
	{
		if (VomitTimer[client] != INVALID_HANDLE)
			{
				KillTimer(VomitTimer[client]);	
				VomitTimer[client] = INVALID_HANDLE;
			}
	}


bool:IsPlayerBurning(client)
{
	if (!IsValidClient(client)) return false;
	new Float:isburning = GetEntDataFloat(client, propinfoburn);
	if (isburning>0) return true;
	
	else return false;
}

bool:IsGhost(client)
{
	new isghost = GetEntData(client, propinfoghost, 1);
	
	if (isghost == 1) return true;
	else return false;
}

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}