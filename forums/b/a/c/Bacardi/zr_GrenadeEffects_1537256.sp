#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#include <zombiereloaded>

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

//new maxents;

new Handle:Enable;
new Handle:Version;
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
	name = "Grenade Effects",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Adds Grenade Special Effects.",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru"
}

public OnPluginStart()
{
	Enable = CreateConVar("zr_greneffect_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	Version = CreateConVar("zr_greneffect_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Trails = CreateConVar("zr_greneffect_trails", "1", "Enables/Disables Grenade Trails", 0, true, 0.0, true, 1.0);
	SmokeFreeze = CreateConVar("zr_greneffect_smoke_freeze", "1", "Enables/Disables a smoke grenade to be a freeze grenade", 0, true, 0.0, true, 1.0);
	SmokeFreezeDistance = CreateConVar("zr_greneffect_smoke_freeze_distance", "600.0", "Freeze grenade distance", 0, true, 100.0);
	SmokeFreezeDuration = CreateConVar("zr_greneffect_smoke_freeze_duration", "4.0", "Freeze grenade duration in seconds", 0, true, 1.0);
	FlashLight = CreateConVar("zr_greneffect_flash_light", "1", "Enables/Disables a flashbang to be a light", 0, true, 0.0, true, 1.0);
	FlashLightDistance = CreateConVar("zr_greneffect_flash_light_distance", "1000.0", "Light distance", 0, true, 100.0);
	FlashLightDuration = CreateConVar("zr_greneffect_flash_light_duration", "15.0", "Light duration in seconds", 0, true, 1.0);
	
	HookConVarChange(Enable, CvarChanges);
	HookConVarChange(Trails, CvarChanges);
	HookConVarChange(SmokeFreeze, CvarChanges);
	HookConVarChange(SmokeFreezeDistance, CvarChanges);
	HookConVarChange(SmokeFreezeDuration, CvarChanges);
	HookConVarChange(FlashLight, CvarChanges);
	HookConVarChange(FlashLightDistance, CvarChanges);
	HookConVarChange(FlashLightDuration, CvarChanges);
	HookConVarChange(Version, CvarChanges);
	
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

public OnConfigsExecuted()
{
	enabled = GetConVarBool(Enable);
	trails = GetConVarBool(Trails);
	freezegren = GetConVarBool(SmokeFreeze);
	flashlightgren = GetConVarBool(FlashLight);

	freezedistance = GetConVarFloat(SmokeFreezeDistance);
	freezeduration = GetConVarFloat(SmokeFreezeDuration);
	flashlightdistance = GetConVarFloat(FlashLightDistance);
	flashlightduration = GetConVarFloat(FlashLightDuration);
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
		return;
		
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
}

public Action:SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (!enabled || !freezegren)
		return;
	
	//decl String:EdictName[64];
	new ent; //, client = GetClientOfUserId(GetEventInt(event, "userid"));

	while((ent = FindEntityByClassname(ent, "env_particlesmokegrenade")) != -1)
	{
		AcceptEntityInput(ent, "Kill");
	}
/*	
	maxents = GetMaxEntities();
	
	for (new edict = MaxClients; edict <= maxents; edict++)
	{
		if (IsValidEdict(edict))
		{
			GetEdictClassname(edict, EdictName, sizeof(EdictName));
			if (!strcmp(EdictName, "smokegrenade_projectile", false))
				if (GetEntPropEnt(edict, Prop_Send, "m_hThrower") == client)
					AcceptEntityInput(edict, "Kill");
		}
	}
*/
	new Float:DetonateOrigin[3];
	DetonateOrigin[0] = GetEventFloat(event, "x"); 
	DetonateOrigin[1] = GetEventFloat(event, "y"); 
	DetonateOrigin[2] = GetEventFloat(event, "z");
	
	DetonateOrigin[2] += 30.0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			new Float:targetOrigin[3];
			GetClientAbsOrigin(i, targetOrigin);
			
			if (GetVectorDistance(DetonateOrigin, targetOrigin) <= freezedistance)
			{
				new Handle:trace = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
			
				if (TR_DidHit(trace))
				{
					if (TR_GetEntityIndex(trace) == i)
						Freeze(i, freezeduration);
				}
				else
				{
					GetClientEyePosition(i, targetOrigin);
					targetOrigin[2] -= 1.0;
			
					if (GetVectorDistance(DetonateOrigin, targetOrigin) <= freezedistance)
					{
						new Handle:trace2 = TR_TraceRayFilterEx(DetonateOrigin, targetOrigin, MASK_SHOT, RayType_EndPoint, FilterTarget, i);
				
						if (TR_DidHit(trace2))
						{
							if (TR_GetEntityIndex(trace2) == i)
								Freeze(i, freezeduration);
						}
						CloseHandle(trace2);
					}
				}
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(DetonateOrigin, 10.0, freezedistance, g_beamsprite, g_halosprite, 1, 10, 1.0, 5.0, 1.0, FreezeColor, 0, 0);
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
	
	if(StrEqual(Classname, "hegrenade_projectile"))
		BeamFollowCreate(Entity, FragColor);
		
	else if(StrEqual(Classname, "flashbang_projectile"))
	{
		if (flashlightgren)
			CreateTimer(1.3, FlashingLight, Entity, TIMER_FLAG_NO_MAPCHANGE);
		BeamFollowCreate(Entity, FlashColor);
	}
	else if(StrEqual(Classname, "smokegrenade_projectile"))
	{
		if (freezegren)
		{
			BeamFollowCreate(Entity, FreezeColor);
			CreateTimer(2.0, SmokeCreateEvent, Entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
			BeamFollowCreate(Entity, SmokeColor);
	}
	else if(freezegren && StrEqual(Classname, "env_particlesmokegrenade") && freezegren)
		AcceptEntityInput(Entity, "Kill");
}

public Action:SmokeCreateEvent(Handle:timer, any:entity)
{
	if (IsValidEdict(entity) && IsValidEntity(entity))
	{
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
	}
}
		
BeamFollowCreate(Entity, Color[4])
{
	if (trails)
	{
		TE_SetupBeamFollow(Entity, BeamSprite,	0, Float:1.0, Float:10.0, Float:10.0, 5, Color);
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
	if(IsValidEdict(entity))
		AcceptEntityInput(entity, "kill");
}

public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(freezegren && StrEqual(sample, "^weapons/smokegrenade/sg_explode.wav"))
		return Plugin_Handled;
	return Plugin_Continue;
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == Enable)
		enabled = GetConVarBool(convar); else
	if (convar == Trails)
		trails = GetConVarBool(convar); else
	if (convar == SmokeFreeze)
		freezegren = GetConVarBool(convar); else
	if (convar == FlashLight)
		flashlightgren = GetConVarBool(convar); else
	if (convar == SmokeFreezeDistance)
		freezedistance = StringToFloat(newValue); else
	if (convar == SmokeFreezeDuration)
		freezeduration = StringToFloat(newValue); else
	if (convar == FlashLightDistance)
		flashlightdistance = StringToFloat(newValue); else
	if (convar == FlashLightDuration)
		flashlightduration = StringToFloat(newValue); else
	if (convar == Version)
		if (!StrEqual(newValue, PLUGIN_VERSION))
			SetConVarString(Version, PLUGIN_VERSION);
}