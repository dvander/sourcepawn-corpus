#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo = {
    name = "RoboSapper fun version (2)",
    author = "Michal [TF2BWR R]",
    description = "Allows to use sapper on robot players",
    version = "1.3",
    url = "http://steamcommunity.com/profiles/76561198069217835/"
};

new bool:IsMvM;

new bool:SapperCooldown[MAXPLAYERS] = false;
new bool:bSapped[MAXPLAYERS];
new bool:bPlayedSND[MAXPLAYERS];

new bool:IsRobot[MAXPLAYERS];

#define SOUND_SAPPER_REMOVED    "weapons/sapper_removed.wav"
#define SOUND_SAPPER_NOISE      "weapons/sapper_timer.wav"
#define SOUND_SAPPER_PLANT      "weapons/sapper_plant.wav"

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent( "player_death", OnPlayerDeath );
	RegConsoleCmd("sm_robot", Command_rb);
}
public OnMapStart()
{
	ServerCommand("sv_tags Robo-Sapper");
	PrecacheSound(SOUND_SAPPER_REMOVED, true);
	PrecacheSound(SOUND_SAPPER_NOISE, true);
	PrecacheSound(SOUND_SAPPER_PLANT, true);
	decl String:map[32];
	GetCurrentMap(map,sizeof(map));
	if(StrContains(map, "mvm_", false) != -1)
	{
		IsMvM = true;
	}
	else
		IsMvM = false;
	for( new i = 0; i < MAXPLAYERS; i++ )
	{
		if( IsValidClient( i ) )
			SDKHook( i, SDKHook_OnTakeDamage, OnTakeDamage );
	}
}
public OnClientPutInServer( client )
{
	if( IsValidClient( client ) )
		SDKHook( client, SDKHook_OnTakeDamage, OnTakeDamage );
}
public OnClientConnected(client)
{
	IsRobot[client] = false;
}
stock bool:IsValidClient( iClient )
{
	if (iClient <= 0 || iClient > 32) return false;
	if (!IsClientInGame(iClient)) return false;
	if( !IsClientConnected(iClient) ) return false;
	if (GetEntProp(iClient, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}
public Action:OnPlayerSpawn( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	
	CreateTimer(0.3, Timer_CheckClient4Robot, client);
}
public Action:Timer_CheckClient4Robot(Handle:timer, any:client)
{
	new String:modelname[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, 128);
	if(StrContains(modelname, "bots") != -1 || StrContains(modelname, "sentry_buster") != -1)
		IsRobot[client] = true;
	else
		IsRobot[client] = false;
}

public Action:Command_rb(client, args) 
{
	for( new i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) )
		{
			new String:modelname[128];
			GetEntPropString(i, Prop_Data, "m_ModelName", modelname, 128);
			if(StrContains(modelname, "bots") != -1 || StrContains(modelname, "sentry_buster") != -1)
				IsRobot[i] = true;
			else
				IsRobot[i] = false;
		}
	}
	return Plugin_Handled;
}
	
stock AttachParticle(entity, String:particleType[], Float:offset[]={0.0,0.0,0.0}, bool:attach=true)
{
	if(!IsValidSapper(entity) || !IsValidEntity(entity) ) return;
	new particle=CreateEntityByName("info_particle_system");

	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[0]+=offset[0];
	position[1]+=offset[1];
	position[2]+=offset[2];
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	AcceptEntityInput(particle, "start");
	ActivateEntity(particle);
	CreateTimer(3.0, DeleteParticle, particle);
}
stock AttachParticle2(entity, String:particleType[], Float:offset[]={0.0,0.0,0.0})
{
	new particle=CreateEntityByName("info_particle_system");

	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[0]+=offset[0];
	position[1]+=offset[1];
	position[2]+=offset[2];

	DispatchKeyValue(particle, "effect_name", particleType);
	SetVariantString("!activator");
	AcceptEntityInput(particle, "SetParent", entity, particle, 0);
	SetVariantString("head");
	AcceptEntityInput(particle, "SetParentAttachment", particle , particle, 0);
	DispatchSpawn(particle);

	AcceptEntityInput(particle, "start");
	ActivateEntity(particle);
	CreateTimer(3.0, DeleteParticle, particle);
	return particle;
}
public Action:DeleteParticle(Handle:timer, any:Ent)
{
	if (!IsValidEntity(Ent)) return;
	new String:cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) 
		AcceptEntityInput(Ent, "Kill");
	return;
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!SapperCooldown[client])
	{
		new TFClassType:iClass = TF2_GetPlayerClass( client );
		new ActiveWep = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
		new SapperSlot = GetPlayerWeaponSlot( client, 1 );
		if(buttons & IN_ATTACK && iClass == TFClass_Spy && ActiveWep == SapperSlot && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Dazed) && !TF2_IsPlayerInCondition(client, TFCond_Sapped))
		{
			new Float:flPos1[3];
			GetClientAbsOrigin(client, flPos1);
			new SappedRobot = GetClientAimTarget(client, true);
			new Float:flPos2SR[3];
			if(!IsValidClient(SappedRobot))
				return Plugin_Stop;
			if(IsMvM && GetClientTeam(client) == _:TFTeam_Blue)
				return Plugin_Stop;
			GetClientAbsOrigin(SappedRobot, flPos2SR);
			new Float:flDistanceSR = GetVectorDistance(flPos1, flPos2SR);

			if(IsClientInGame(SappedRobot) && SappedRobot != client && IsRobot[SappedRobot] && GetClientTeam(SappedRobot) != GetClientTeam(client) && IsPlayerAlive(SappedRobot) && flDistanceSR < 130) //
			{
				if(!TF2_IsPlayerInCondition(SappedRobot, TFCond_Ubercharged) && !TF2_IsPlayerInCondition(SappedRobot, TFCond_UberchargedHidden) && !TF2_IsPlayerInCondition(SappedRobot, TFCond_Sapped) && !TF2_IsPlayerInCondition(SappedRobot, TFCond_Bonked) && !TF2_IsPlayerInCondition(SappedRobot, TFCond_UberchargedCanteen) && !TF2_IsPlayerInCondition(SappedRobot, TFCond_UberchargedOnTakeDamage))
				{																																																																																																						
					AttachSapper(SappedRobot);
					
					CreateTimer(4.9, Timer_KillSapper, SappedRobot);
					EmitSoundToAll(SOUND_SAPPER_NOISE, SappedRobot, _, _, _, 0.6);
					EmitSoundToAll(SOUND_SAPPER_PLANT, SappedRobot, _, _, _, 0.7);
					TF2_AddCondition(SappedRobot, TFCond_Sapped, 5.0);
					CreateTimer(1.0, Timer_CooldownHud, client);
					CreateTimer(4.9, Timer_SapEnd, SappedRobot);
					SapperCooldown[client] = true;
					if(bool:GetEntProp(SappedRobot, Prop_Send, "m_bIsMiniBoss") == false)
						TF2_StunPlayer(SappedRobot, 4.9, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
					if(bool:GetEntProp(SappedRobot, Prop_Send, "m_bIsMiniBoss") == true)
					{
						new Float:flSpeed = GetEntPropFloat(SappedRobot, Prop_Send, "m_flMaxspeed");
						SetEntPropFloat(SappedRobot, Prop_Send, "m_flMaxspeed", 0.35 * flSpeed);
						TF2_StunPlayer(SappedRobot, 5.0, 0.75, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, client);
					}
					if(IsMvM)
					{
						for (new i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i))
							{
								new Float:flPos2[3];
								GetClientAbsOrigin(i, flPos2);
								new Float:flDistance = GetVectorDistance(flPos2SR, flPos2);
								if(!TF2_IsPlayerInCondition(i, TFCond_Ubercharged) && !TF2_IsPlayerInCondition(i, TFCond_UberchargedHidden) && !TF2_IsPlayerInCondition(i, TFCond_Sapped) && !TF2_IsPlayerInCondition(i, TFCond_Bonked) && !TF2_IsPlayerInCondition(i, TFCond_UberchargedCanteen) && !TF2_IsPlayerInCondition(i, TFCond_UberchargedOnTakeDamage))
								{
									if(GetClientTeam(i) == _:TFTeam_Blue && i != client && i != SappedRobot)
									{
										if(flDistance < 240 && bool:GetEntProp(i, Prop_Send, "m_bIsMiniBoss") == false && IsPlayerAlive(i))
										{
											TF2_StunPlayer(i, 4.9, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
											TF2_AddCondition(i, TFCond_Sapped, 5.0);
											CreateTimer(1.0, Timer_CooldownHud, client);
											CreateTimer(4.9, Timer_SapEnd, i);
										}
										if(flDistance < 240 && bool:GetEntProp(i, Prop_Send, "m_bIsMiniBoss") == true && IsPlayerAlive(i))
										{
											new Float:flSpeed = GetEntPropFloat(i, Prop_Send, "m_flMaxspeed");
											SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 0.35 * flSpeed);
											TF2_AddCondition(i, TFCond_Sapped, 5.0);
											TF2_StunPlayer(i, 5.0, 0.75, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT, client);
											CreateTimer(4.9, Timer_SapEnd, i);
										}
									}
								}
							}
						}
					}
				}
			}
			
		} 
	}
	if(!TF2_IsPlayerInCondition(client, TFCond_Sapped))
	{
		new Float:flPos12[3];
		GetClientAbsOrigin(client, flPos12);
		new SappedRobot = GetClientAimTarget(client, true);
		new Float:flPos23SR[3];
		if(!IsValidClient(SappedRobot) || !TF2_IsPlayerInCondition(SappedRobot, TFCond_Sapped) || !bSapped[SappedRobot])
			return Plugin_Stop;
		GetClientAbsOrigin(SappedRobot, flPos23SR);
		new Float:flDistanceSR2 = GetVectorDistance(flPos12, flPos23SR);
		
		new TFClassType:iClass = TF2_GetPlayerClass( client );
		new ActiveWep = GetEntPropEnt( client, Prop_Send, "m_hActiveWeapon" );
		new MeleeSlot = GetPlayerWeaponSlot( client, 2 );
		if(iClass == TFClass_Engineer || iClass == TFClass_Pyro && bSapped[SappedRobot])
			if(buttons & IN_ATTACK && ActiveWep == MeleeSlot && bSapped[SappedRobot] && GetClientTeam(SappedRobot) == GetClientTeam(client))
				if(IsClientInGame(SappedRobot) && SappedRobot != client && IsPlayerAlive(SappedRobot) && flDistanceSR2 < 130 && TF2_IsPlayerInCondition(SappedRobot, TFCond_Sapped) && bSapped[SappedRobot])//can remove sapper
				{
					if(!bSapped[SappedRobot])
						return Plugin_Stop;
					bSapped[SappedRobot] = false;
					CreateTimer(1.2, Timer_SapEnd, SappedRobot);
					CreateTimer(1.2, Timer_KillSapper, SappedRobot);
					CreateTimer(1.2, Timer_KillSapperMDLWrench, SappedRobot);
				}
	}
	return Plugin_Continue;
}
stock AttachSapper(client)
{
		bPlayedSND[client] = false;
		bSapped[client] = true;
		new sapper = CreateEntityByName("prop_dynamic");
		DispatchKeyValue(sapper, "targetname", "RobSap");
		DispatchKeyValue(sapper, "solid", "0");
		DispatchKeyValue(sapper, "model", "models/buildables/sapper_sentry1.mdl");
		SetVariantString("!activator");
		AcceptEntityInput(sapper, "SetParent", client, sapper, 0);
		SetVariantString("head");
		AcceptEntityInput(sapper, "SetParentAttachment", sapper , sapper, 0);
	//	CreateTimer(5.0, Timer_KillSapperMDL, sapper);
		DispatchSpawn(sapper);
		CreateTimer(5.0, Timer_KillSapperMDL, sapper);
		SetEntProp( sapper, Prop_Send, "m_hOwnerEntity", client );
		AttachParticle2(client, "Explosion_ShockWave_01");
}
public Action:OnTakeDamage( iVictim, &iAttacker, &iInflictor, &Float:flDamage, &iDamageBits, &iWeapon, Float:flDamageForce[3], Float:flDamagePosition[3], iDamageCustom )
{
	if(!IsValidClient(iVictim) || !IsValidClient(iAttacker))
		return Plugin_Continue;
	decl String:strWeaponClass[32];
	if(iWeapon > 0 && IsValidEntity(iWeapon))
	{
		GetEntityClassname( iWeapon, strWeaponClass, sizeof(strWeaponClass) );
		if( strcmp( strWeaponClass, "tf_weapon_knife", false ) == 0 && !TF2_IsPlayerInCondition( iAttacker, TFCond_Taunting ) && TF2_IsPlayerInCondition( iVictim, TFCond_Sapped ) && TF2_GetPlayerClass(iAttacker) == TFClass_Spy && bool:GetEntProp(iVictim, Prop_Send, "m_bIsMiniBoss") == false && !IsMvM)
		{
			new Thp = GetClientHealth( iVictim );
			iDamageBits = DMG_CRIT;
			iDamageCustom = TF_CUSTOM_BACKSTAB;
			flDamage = float(Thp) *8;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:Timer_KillSapperMDL(Handle:timer, any:sapper)
{
	if(IsValidEntity(sapper))
	{
		AttachParticle(sapper, "ExplosionCore_sapperdestroyed");
		AcceptEntityInput(sapper, "kill")
	}  
}
public Action:Timer_KillSapperMDLWrench(Handle:timer, any:client)
{
	new iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "prop_dynamic") ) != -1 )
	{
		decl String:strName[50];
		GetEntPropString(iEnt, Prop_Data, "m_iName", strName, sizeof(strName));
		if( GetEntProp( iEnt, Prop_Send, "m_hOwnerEntity" ) == client && strcmp(strName, "RobSap") == 0 )
			AcceptEntityInput(iEnt,"Kill");
	}
}
public Action:Timer_KillSapper(Handle:timer, any:SappedRobot)
{
	if(IsValidClient(SappedRobot))
	{
		if(IsPlayerAlive(SappedRobot) && !bPlayedSND[SappedRobot])
		{
			bPlayedSND[SappedRobot] = true;
			EmitSoundToAll(SOUND_SAPPER_REMOVED, SappedRobot, _, _, _, 0.6);
		}
		StopSound(SappedRobot, 0, SOUND_SAPPER_NOISE);
	}
}
public Action:Timer_CooldownHud(Handle:timer, any:client)
{
	if(!SapperCooldown[client]) return Plugin_Stop;
	CreateTimer(1.2, Timer_CooldownHudS1, client);
	CreateTimer(2.0, Timer_CooldownHudS2, client);
	CreateTimer(3.0, Timer_CooldownHudS3, client);
	CreateTimer(4.0, Timer_CooldownHudS4, client);
	CreateTimer(5.0, Timer_CooldownHudS5, client);
	CreateTimer(6.0, Timer_CooldownHudS6, client);
	CreateTimer(7.0, Timer_CooldownHudS7, client);
	CreateTimer(8.0, Timer_CooldownHudS8, client);
	CreateTimer(9.0, Timer_CooldownHudS9, client);
	CreateTimer(10.0, Timer_CooldownHudS10, client);
	CreateTimer(11.0, Timer_CooldownHudS11, client);
	CreateTimer(12.0, Timer_CooldownHudS12, client);
	CreateTimer(13.0, Timer_CooldownHudS13, client);
	CreateTimer(14.0, Timer_CooldownHudS14, client);
	return Plugin_Continue;
}
public Action:Timer_CooldownHudS1(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 13%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS2(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 20%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS3(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 26%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS4(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 33%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS5(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 40%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS6(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 46%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS7(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 53%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS8(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 60%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;

}

public Action:Timer_CooldownHudS9(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 66%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS10(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 73%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS11(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 80%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS12(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 86%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS13(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.7, 0.8, 1.1, 255, 0, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge 93%");
		CloseHandle(hHudTextCharge);
		return Plugin_Continue;
}

public Action:Timer_CooldownHudS14(Handle:timer, any:client)
{
		if(!SapperCooldown[client]) return Plugin_Stop;
		new Handle:hHudTextCharge = CreateHudSynchronizer();
		SetHudTextParams(-0.6, 0.8, 4.0, 0, 255, 0, 255);
		ShowSyncHudText(client, hHudTextCharge, "Sapper Recharge Done");
		CloseHandle(hHudTextCharge);
		SapperCooldown[client] = false;
		return Plugin_Continue;
}

public Action:Timer_SapEnd(Handle:timer, any:i)
{
	bSapped[i] = false;
	TF2_RemoveCondition(i, TFCond_Dazed);
	TF2_RemoveCondition(i, TFCond_Sapped);
	if(bool:GetEntProp(i, Prop_Send, "m_bIsMiniBoss") == true && IsPlayerAlive(i))
		TF2_StunPlayer(i, 0.0, 0.0, TF_STUNFLAG_SLOWDOWN|TF_STUNFLAG_NOSOUNDOREFFECT);
}
stock SwitchToOtherWeapon(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
}
public OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new client = GetClientOfUserId( GetEventInt( hEvent, "userid" ) );
	StopSound(client, 0, SOUND_SAPPER_NOISE);
	SapperCooldown[client] = false;
	new iEnt = -1;
	while( ( iEnt = FindEntityByClassname( iEnt, "prop_dynamic") ) != -1 )
	{
		decl String:strName[50];
		GetEntPropString(iEnt, Prop_Data, "m_iName", strName, sizeof(strName));
		if( GetEntProp( iEnt, Prop_Send, "m_hOwnerEntity" ) == client && strcmp(strName, "RobSap") == 0 )
			AcceptEntityInput(iEnt,"Kill");
	}

}
public OnGameFrame()
{
	new i = -1;
	for( i = 1; i <= MaxClients; i++ )
		if( IsValidClient(i) )
			if(SapperCooldown[i])
			{
				new KnifeSlot = GetPlayerWeaponSlot( i, 2 );
				new ActiveWep = GetEntPropEnt( i, Prop_Send, "m_hActiveWeapon" );
				new SapperSlot = GetPlayerWeaponSlot( i, 1 );
				if(ActiveWep == SapperSlot)
				{
					SwitchToOtherWeapon(i);
					if (IsValidEntity(KnifeSlot)) 
						SetEntPropFloat(KnifeSlot, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 1.1);
				}
			}
}

bool:IsValidSapper(Sapper)
{
	decl String:strName[50];
	GetEntPropString(Sapper, Prop_Data, "m_iName", strName, sizeof(strName));
	if(strcmp(strName, "RobSap") != 0)
		return false;
	return true;
}