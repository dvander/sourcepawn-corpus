#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zriot>

#define PLUGIN_VERSION "1.7"

#define FLASH 0
#define SMOKE 1

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

#define FragColor 	{255,75,75,255}
#define FlashColor 	{255,255,255,255}
#define SmokeColor	{75,255,75,255}
#define FreezeColor	{75,75,255,255}

new BeamSprite, GlowSprite, g_beamsprite, g_halosprite;

new Handle:Enable;
new Handle:Trails;
new Handle:SmokeFreeze;
new Handle:SmokeFreezeDistance;
new Handle:SmokeFreezeDuration;
new Handle:FlashLight;
new Handle:FlashLightDistance;
new Handle:FlashLightDuration;
new Handle:FreezeTimer[MAXPLAYERS+1];

new bool:IsFreezed[MAXPLAYERS+1];
new bool:enabled, bool:trails, bool:freezegren, bool:flashlightgren;

new Float:freezedistance, Float:freezeduration, Float:flashlightdistance, Float:flashlightduration;

public Plugin:myinfo = 
{
	name = "[ZR] Grenade Effects",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Adds Grenades Special Effects.",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru"
}

public OnPluginStart()
{
	CreateConVar("zr_greneffect_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	Enable = CreateConVar("zr_greneffect_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	Trails = CreateConVar("zr_greneffect_trails", "1", "Enables/Disables Grenade Trails", 0, true, 0.0, true, 1.0);
	SmokeFreeze = CreateConVar("zr_greneffect_smoke_freeze", "1", "Enables/Disables a smoke grenade to be a freeze grenade", 0, true, 0.0, true, 1.0);
	SmokeFreezeDistance = CreateConVar("zr_greneffect_smoke_freeze_distance", "600.0", "Freeze grenade distance", 0, true, 100.0);
	SmokeFreezeDuration = CreateConVar("zr_greneffect_smoke_freeze_duration", "4.0", "Freeze grenade duration in seconds", 0, true, 1.0);
	FlashLight = CreateConVar("zr_greneffect_flash_light", "1", "Enables/Disables a flashbang to be a light", 0, true, 0.0, true, 1.0);
	FlashLightDistance = CreateConVar("zr_greneffect_flash_light_distance", "1000.0", "Light distance", 0, true, 100.0);
	FlashLightDuration = CreateConVar("zr_greneffect_flash_light_duration", "15.0", "Light duration in seconds", 0, true, 1.0);
	
	enabled = GetConVarBool(Enable);
	trails = GetConVarBool(Trails);
	freezegren = GetConVarBool(SmokeFreeze);
	flashlightgren = GetConVarBool(FlashLight);

	freezedistance = GetConVarFloat(SmokeFreezeDistance);
	freezeduration = GetConVarFloat(SmokeFreezeDuration);
	flashlightdistance = GetConVarFloat(FlashLightDistance);
	flashlightduration = GetConVarFloat(FlashLightDuration);
	
	HookConVarChange(Enable, CvarChanges);
	HookConVarChange(Trails, CvarChanges);
	HookConVarChange(SmokeFreeze, CvarChanges);
	HookConVarChange(SmokeFreezeDistance, CvarChanges);
	HookConVarChange(SmokeFreezeDuration, CvarChanges);
	HookConVarChange(FlashLight, CvarChanges);
	HookConVarChange(FlashLightDistance, CvarChanges);
	HookConVarChange(FlashLightDuration, CvarChanges);
	
	AutoExecConfig(true, "zombiereloaded/GrenadeEffects");
	
	HookEvent("smokegrenade_detonate", SmokeDetonate);
	AddNormalSoundHook(NormalSHook);
}

public OnMapStart() 
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
}

public OnClientDisconnect_Post(client)
{
	IsFreezed[client] = false;
	if (FreezeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FreezeTimer[client]);
		FreezeTimer[client] = INVALID_HANDLE;
	}
}

public Action:FlashingLight(Handle:timer, any:Entity)
{
	if (!IsValidEdict(Entity))
		return Plugin_Stop;
		
	decl String:EdictClassname[64];
	GetEdictClassname(Entity, EdictClassname, sizeof(EdictClassname));
	if (!strcmp(EdictClassname, "flashbang_projectile", false))
	{
		new Float:EntOrigin[3];
		GetEntPropVector(Entity, Prop_Send, "m_vecOrigin", EntOrigin);
		EntOrigin[2]+=50.0;
		LightCreate(FLASH, EntOrigin);
		AcceptEntityInput(Entity, "kill");
	}
	
	return Plugin_Stop;
}

public SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!enabled || !freezegren)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new index = MaxClients+1;
	
	while ((index = FindEntityByClassname(index, "smokegrenade_projectile")) != -1)
	{
		if (GetEntPropEnt(index, Prop_Send, "m_hThrower") == client)
			AcceptEntityInput(index, "Kill");
	}
	
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z");
	
	DetonateOrigin[2] += 10.0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!(IsClientInGame(i) && IsPlayerAlive(i) && ZRiot_IsClientZombie(i)))
			continue;
		
		new Float:targetOrigin[3];
		GetClientAbsOrigin(i, targetOrigin);
		
		if (GetVectorDistance(DetonateOrigin, targetOrigin) <= freezedistance)
		{
			new Handle:trace = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
		
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(DetonateOrigin, targetOrigin) <= 100.0))
				Freeze(i, freezeduration);
				
			else
			{
				GetClientEyePosition(i, targetOrigin);
				targetOrigin[2] -= 1.0;
		
				new Handle:trace2 = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, CONTENTS_SOLID, RayType_EndPoint, FilterTarget, i);
			
				if ((TR_DidHit(trace2) && TR_GetEntityIndex(trace2) == i) || (GetVectorDistance(DetonateOrigin, targetOrigin) <= 100.0))
					Freeze(i, freezeduration);
				
				CloseHandle(trace2);
			}
			CloseHandle(trace);
		}
	}
	
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, freezedistance, g_beamsprite, g_halosprite, 10, 100, 1.0, 5.0, 1.0, FreezeColor, 0, 0);
	TE_SendToAll();
	LightCreate(SMOKE, DetonateOrigin);
}

public bool:FilterTarget(entity, contentsMask, any:data)
{
	return (data == entity);
} 

Freeze(client, Float:time)
{
	if (FreezeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FreezeTimer[client]);
		FreezeTimer[client] = INVALID_HANDLE;
	}
		
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	TE_SetupGlowSprite(vec, GlowSprite, time, 1.5, 50);
	TE_SendToAll();
	IsFreezed[client] = true;
	FreezeTimer[client] = CreateTimer(time, Unfreeze, client);
}

public Action:Unfreeze(Handle:timer, any:client)
{
	if (IsFreezed[client])
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		IsFreezed[client] = false;
		FreezeTimer[client] = INVALID_HANDLE;
	}
}

public OnEntityCreated(Entity, const String:Classname[])
{
	if (!enabled)
		return;
	
	if (!strcmp(Classname, "hegrenade_projectile"))
		BeamFollowCreate(Entity, FragColor);
		
	else if (!strcmp(Classname, "flashbang_projectile"))
	{
		if (flashlightgren)
			CreateTimer(1.3, FlashingLight, Entity, TIMER_FLAG_NO_MAPCHANGE);
		BeamFollowCreate(Entity, FlashColor);
	}
	else if (!strcmp(Classname, "smokegrenade_projectile"))
	{
		if (freezegren)
		{
			BeamFollowCreate(Entity, FreezeColor);
			CreateTimer(2.0, SmokeCreateEvent, Entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			BeamFollowCreate(Entity, SmokeColor);
	}
	else if (freezegren && !strcmp(Classname, "env_particlesmokegrenade"))
		AcceptEntityInput(Entity, "Kill");
}

public Action:SmokeCreateEvent(Handle:timer, any:entity)
{
	if (!IsValidEdict(entity))
		return Plugin_Stop;
	
	decl String:clsname[64];
	GetEdictClassname(entity, clsname, sizeof(clsname));
	if (!strcmp(clsname, "smokegrenade_projectile", false))
	{
		new Float:SmokeOrigin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", SmokeOrigin);
		new client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		new userid = GetClientUserId(client);
	
		new Handle:event = CreateEvent("smokegrenade_detonate");
		
		SetEventInt(event, "userid", userid);
		SetEventFloat(event, "x", SmokeOrigin[0]);
		SetEventFloat(event, "y", SmokeOrigin[1]);
		SetEventFloat(event, "z", SmokeOrigin[2]);
		FireEvent(event);
	}
	
	return Plugin_Stop;
}
		
BeamFollowCreate(Entity, Color[4])
{
	if (trails)
	{
		TE_SetupBeamFollow(Entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, Color);
		TE_SendToAll();	
	}
}

LightCreate(Gren, Float:Pos[3])   
{  
	new iEntity = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	switch(Gren)
	{
		case FLASH : {
				DispatchKeyValue(iEntity, "_light", "255 255 255 255");
				DispatchKeyValueFloat(iEntity, "distance", flashlightdistance);
				EmitSoundToAll("items/nvg_on.wav", iEntity, SNDCHAN_WEAPON);
				CreateTimer(flashlightduration, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
			}
		case SMOKE : {
				DispatchKeyValue(iEntity, "_light", "75 75 255 255");
				DispatchKeyValueFloat(iEntity, "distance", freezedistance);
				EmitSoundToAll(SOUND_FREEZE_EXPLODE, iEntity, SNDCHAN_WEAPON);
				CreateTimer(1.0, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
			}
	}
	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, Pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action:Delete(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (freezegren && !strcmp(sample, "^weapons/smokegrenade/sg_explode.wav"))
		return Plugin_Handled;
	return Plugin_Continue;
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == Enable)
		enabled = bool:StringToInt(newValue); else
	if (convar == Trails)
		trails = bool:StringToInt(newValue); else
	if (convar == SmokeFreeze)
		freezegren = bool:StringToInt(newValue); else
	if (convar == FlashLight)
		flashlightgren = bool:StringToInt(newValue); else
	if (convar == SmokeFreezeDistance)
		freezedistance = StringToFloat(newValue); else
	if (convar == SmokeFreezeDuration)
		freezeduration = StringToFloat(newValue); else
	if (convar == FlashLightDistance)
		flashlightdistance = StringToFloat(newValue); else
	if (convar == FlashLightDuration)
		flashlightduration = StringToFloat(newValue);
}