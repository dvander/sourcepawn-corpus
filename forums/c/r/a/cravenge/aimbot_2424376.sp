#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <glow>

new bool:aimbot[MAXPLAYERS+1];
new bool:wallhack[MAXPLAYERS+1];

#define DATA "1.2"

#define WALLHACK_MODEL "models/props/cs_militia/silo_01.mdl"

new wLaserMaterial;
new wHaloMaterial;

public Plugin:myinfo =
{
	name = "Aimbot (With ESP Box and Wall Hack)",
	author = "Franc1sco franug, cravenge",
	description = "Provides Legit Auto-Aim And Wallhack.",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	CreateConVar("aimbot_version", DATA, "Aimbot (With ESP Box and Wall Hack) Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("weapon_reload", OnWeaponReload);
	HookEvent("revive_begin", OnReviveBegin);
	HookEvent("player_death", OnPlayerDeath);
	
	HookEvent("player_ledge_grab", OnAimbotAutoDisable);
	HookEvent("revive_success", OnAimbotAutoEnable);
	
	HookEvent("lunge_pounce", OnAAD);
	HookEvent("jockey_ride", OnAAD);
	HookEvent("tongue_grab", OnAAD);
	HookEvent("charger_carry_start", OnAAD);
	HookEvent("player_now_it", OnAAD);
	HookEvent("pounce_end", OnAAE);
	HookEvent("jockey_ride_end", OnAAE);
	HookEvent("tongue_release", OnAAE);
	HookEvent("charger_pummel_end", OnAAE);
	HookEvent("player_no_longer_it", OnAAE);
	
	RegAdminCmd("sm_aimbot", aimbotcmd, ADMFLAG_ROOT);
	
	for (new client = 1; client <= MaxClients; client++) 
    {
		if (IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public OnClientPutInServer(client)
{
	aimbot[client] = false;
	wallhack[client] = false;
	
	SDKHook(client, SDKHook_PreThink, OnClientThink);
	SDKHook(client, SDKHook_PreThinkPost, OnClientThink);
	SDKHook(client, SDKHook_PostThink, OnClientThink);
	SDKHook(client, SDKHook_PostThinkPost, OnClientThink);
}

public OnMapStart()
{
	wLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	wHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheModel(WALLHACK_MODEL, true);
}

public Action:aimbotcmd(client, args)
{
	if(args < 1)
	{
		if(!aimbot[client] && !wallhack[client])
		{
			aimbot[client] = true;
			wallhack[client] = true;
			SetupESPs(client);
		}
		else
		{
			aimbot[client] = false;
			wallhack[client] = false;
		}
		
		ReplyToCommand(client, "Auto-Aim %s!", aimbot[client] ? "Enabled" : "Disabled");
	}
	else
	{
		decl String:strTarget[32]; GetCmdArg(1, strTarget, sizeof(strTarget));
		
		decl String:strTargetName[MAX_TARGET_LENGTH]; 
		decl TargetList[MAXPLAYERS], TargetCount; 
		decl bool:TargetTranslate;
		
		if ((TargetCount = ProcessTargetString(strTarget, 0, TargetList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, strTargetName, sizeof(strTargetName), TargetTranslate)) <= 0) 
		{
			ReplyToCommand(client, "Missing Target!");
			return Plugin_Handled; 
		}
		
		for (new i = 0; i < TargetCount; i++) 
		{ 
			new iClient = TargetList[i]; 
			if (IsClientInGame(iClient)) 
			{ 
				if(!aimbot[iClient] && !wallhack[iClient])
				{
					aimbot[iClient] = true;
					wallhack[iClient] = true;
					SetupESPs(iClient);
				}
				else
				{
					aimbot[iClient] = false;
					wallhack[iClient] = false;
				}
				
				ReplyToCommand(client, "%N's Auto-Aim %s!", iClient, aimbot[iClient] ? "Enabled" : "Disabled");
			} 
		}   
	}
	return Plugin_Handled;
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!aimbot[client] || !wallhack[client])
	{
		return;
	}
	
	new objetivo = GetClosestClient(client);
	if(objetivo > 0)
	{
		LookAtClient(client, objetivo);
	}
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new changer = GetClientOfUserId(GetEventInt(event, "userid"));
	if(changer <= 0 || !IsClientInGame(changer) || IsFakeClient(changer) || !wallhack[changer])
	{
		return;
	}
	
	new cOT = GetEventInt(event, "oldteam");
	new cNT = GetEventInt(event, "team");
	if(cOT == 2 && (cNT == 1 || cNT == 3))
	{
		aimbot[changer] = false;
	}
}

public Action:OnWeaponReload(Handle:event, const String:name[], bool:dontBroadcast)
{
	new reloader = GetClientOfUserId(GetEventInt(event, "userid"));
	if(reloader <= 0 || !IsClientInGame(reloader) || GetClientTeam(reloader) != 2 || IsFakeClient(reloader) || !wallhack[reloader])
	{
		return;
	}
	
	aimbot[reloader] = false;
	CreateTimer(3.5, ReEnable, reloader);
}

public Action:ReEnable(Handle:timer, any:client)
{
	aimbot[client] = true;
	return Plugin_Stop;
}

public Action:OnReviveBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new savior = GetClientOfUserId(GetEventInt(event, "userid"));
	if(savior <= 0 || !IsClientInGame(savior) || GetClientTeam(savior) != 2 || IsFakeClient(savior) || !wallhack[savior])
	{
		return;
	}
	
	aimbot[savior] = false;
	CreateTimer(GetConVarFloat(FindConVar("survivor_revive_duration")), ReEnable, savior);
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if (victim <= 0 || !IsClientInGame(victim))
	{
		return;
	}
	
	if (GetClientTeam(victim) == 2 && !IsFakeClient(victim))
	{
		if(aimbot[victim] || wallhack[victim])
		{
			aimbot[victim] = false;
			wallhack[victim] = false;
		}
	}
	else if (GetClientTeam(victim) == 3)
	{
		L4D2_SetEntGlow(victim, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
	}
}

public Action:OnAimbotAutoDisable(Handle:event, const String:name[], bool:dontBroadcast)
{
	new hanger = GetClientOfUserId(GetEventInt(event, "userid"));
	if(hanger <= 0 || !IsClientInGame(hanger) || GetClientTeam(hanger) != 2 || IsFakeClient(hanger) || !wallhack[hanger])
	{
		return;
	}
	
	aimbot[hanger] = false;
}

public Action:OnAimbotAutoEnable(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetEventBool(event, "ledge_hang"))
	{
		return;
	}
	
	new hanger = GetClientOfUserId(GetEventInt(event, "subject"));
	if(hanger <= 0 || !IsClientInGame(hanger) || GetClientTeam(hanger) != 2 || IsFakeClient(hanger) || aimbot[hanger] || !wallhack[hanger])
	{
		return;
	}
	
	aimbot[hanger] = true;
}

public Action:OnAAD(Handle:event, const String:name[], bool:dontBroadcast)
{
	new capped = GetClientOfUserId(GetEventInt(event, "victim"));
	if(capped <= 0 || !IsClientInGame(capped) || GetClientTeam(capped) != 2 || IsFakeClient(capped) || !wallhack[capped])
	{
		return;
	}
	
	aimbot[capped] = false;
}

public Action:OnAAE(Handle:event, const String:name[], bool:dontBroadcast)
{
	new capped = GetClientOfUserId(GetEventInt(event, "victim"));
	if(capped <= 0 || !IsClientInGame(capped) || GetClientTeam(capped) != 2 || IsFakeClient(capped) || !IsPlayerAlive(capped) || !wallhack[capped])
	{
		return;
	}
	
	aimbot[capped] = true;
}

public OnClientThink(client)
{
	if(!aimbot[client] || !wallhack[client])
	{
		return;
	}
	
	new Float:NoRecoil[3];
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", NoRecoil);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", NoRecoil);
}

SetupESPs(client)
{
	CreateTimer(0.1, Timer_ESPBoxes, client, TIMER_REPEAT);
	CreateTimer(0.1, Timer_ESPColors, client, TIMER_REPEAT);
}

public Action:Timer_ESPBoxes(Handle:timer, any:client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2 || !wallhack[client])
	{
		return Plugin_Stop;
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			decl Float:wMaxs[3], Float:wMins[3], Float:wPos[3];
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", wPos);
			GetEntPropVector(i, Prop_Send, "m_vecMaxs", wMaxs);
			GetEntPropVector(i, Prop_Send, "m_vecMins", wMins);
			
			AddVectors(wPos, wMaxs, wMaxs);
			AddVectors(wPos, wMins, wMins);
			
			decl Float:wPos1[3], Float:wPos2[3], Float:wPos3[3], Float:wPos4[3], Float:wPos5[3], Float:wPos6[3];
			
			wPos1 = wMaxs;
			wPos1[0] = wMins[0];
			
			wPos2 = wMaxs;
			wPos2[1] = wMins[1];
			
			wPos3 = wMaxs;
			wPos3[2] = wMins[2];
			
			wPos4 = wMins;
			wPos4[0] = wMaxs[0];
			
			wPos5 = wMins;
			wPos5[1] = wMaxs[1];
			
			wPos6 = wMins;
			wPos6[2] = wMaxs[2];
			
			new iHealth = GetClientHealth(i);
			new iMaxHealth = GetEntProp(i, Prop_Send, "m_iMaxHealth");
			if(iHealth >= iMaxHealth * 0.75)
			{
				TE_SetupBeamPoints(wMaxs, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
				TE_SendToClient(client);
			}
			else if(iHealth >= iMaxHealth * 0.25 && iHealth < iMaxHealth * 0.75)
			{
				TE_SetupBeamPoints(wMaxs, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client);
			}
			else if(iHealth < iMaxHealth * 0.25)
			{
				TE_SetupBeamPoints(wMaxs, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wMaxs, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos6, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wMins, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos1, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos5, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos3, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
				
				TE_SetupBeamPoints(wPos4, wPos2, wLaserMaterial, wHaloMaterial, 0, 0, 0.2, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_ESPColors(Handle:timer, any:client)
{
	if (client <= 0 || !IsClientInGame(client) || GetClientTeam(client) != 2)
	{
		return Plugin_Stop;
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			if(wallhack[client])
			{
				new hp = GetClientHealth(i);
				new maxhp = GetEntProp(i, Prop_Send, "m_iMaxHealth");
				if(hp >= maxhp * 0.75)
				{
					L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {0, 255, 0}, false);
				}
				else if(hp >= maxhp * 0.25 && hp < maxhp * 0.75)
				{
					L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {255, 255, 0}, false);
				}
				else if(hp < maxhp * 0.25)
				{
					L4D2_SetEntGlow(i, L4D2Glow_Constant, 100000, 0, {255, 0, 0}, false);
				}
			}
			else
			{
				L4D2_SetEntGlow(i, L4D2Glow_None, 0, 0, {0, 0, 0}, false);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3])
{
	if(!IsClientInGame(client) || !aimbot[client] || !IsPlayerAlive(client))
	{
		return;
	}
	
	if(buttons & IN_ATTACK)
	{
		new objetivo = GetClosestClient(client);
		if(objetivo > 0)
		{
			LookAtClient(client, objetivo);
		}
	}
}

stock LookAtClient(client, target)
{
	new Float:TargetPos[3], Float:TargetAngles[3], Float:ClientPos[3], Float:Result[3], Float:Final[3];
	
	GetClientEyePosition(client, ClientPos);
	GetClientEyePosition(target, TargetPos);
	
	GetClientEyeAngles(target, TargetAngles);
	
	decl Float:vecFinal[3];
	AddInFrontOf(TargetPos, TargetAngles, 8.0, vecFinal);
	
	MakeVectorFromPoints(ClientPos, vecFinal, Result);
	GetVectorAngles(Result, Result);
    
	Final[0] = Result[0];
	Final[1] = Result[1];
	Final[2] = Result[2];
    
	TeleportEntity(client, NULL_VECTOR, Final, NULL_VECTOR);
}

AddInFrontOf(Float:vecOrigin[3], Float:vecAngle[3], Float:units, Float:output[3])
{
    new Float:vecView[3];
    GetViewVector(vecAngle, vecView);
	
    output[0] = vecView[0] * units + vecOrigin[0];
    output[1] = vecView[1] * units + vecOrigin[1];
    output[2] = vecView[2] * units + vecOrigin[2];
}
 
GetViewVector(Float:vecAngle[3], Float:output[3])
{
    output[0] = Cosine(vecAngle[1] / (180 / FLOAT_PI));
    output[1] = Sine(vecAngle[1] / (180 / FLOAT_PI));
    output[2] = -Sine(vecAngle[0] / (180 / FLOAT_PI));
}

stock GetClosestClient(iClient)
{
	decl Float:fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);
	decl Float:fEntityOrigin[3];
	
	new clientteam = GetClientTeam(iClient);
	new iClosestEntity = -1;
	new Float:fClosestDistance = -1.0;
	new Float:fEntityDistance;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) != clientteam && IsPlayerAlive(i) && i != iClient)
		{
			GetClientAbsOrigin(i, fEntityOrigin);
			fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0)
			{
				if(PuedeVerAlOtro(iClient, i))
				{
					fClosestDistance = fEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	
	return iClosestEntity;
}

stock bool:PuedeVerAlOtro(visionario, es_visto, Float:distancia = 0.0, Float:altura_visionario = 50.0)
{
	new Float:vMonsterPosition[3], Float:vTargetPosition[3];
	
	GetEntPropVector(visionario, Prop_Send, "m_vecOrigin", vMonsterPosition);
	vMonsterPosition[2] += altura_visionario;
	
	GetClientEyePosition(es_visto, vTargetPosition);
	
	if (distancia == 0.0 || GetVectorDistance(vMonsterPosition, vTargetPosition, false) < distancia)
	{
		new Handle:trace = TR_TraceRayFilterEx(vMonsterPosition, vTargetPosition, MASK_SOLID_BRUSHONLY, RayType_EndPoint, Base_TraceFilter);
		if(TR_DidHit(trace))
		{
			CloseHandle(trace);
			return false;
		}
		
		CloseHandle(trace);
		return true;
	}
	return false;
}

public bool:Base_TraceFilter(entity, contentsMask, any:data)
{
	if(entity != data)
	{
		return false;
	}
	
	return true;
}

