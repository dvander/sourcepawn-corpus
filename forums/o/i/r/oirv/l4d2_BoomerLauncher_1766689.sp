#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION 	"1.0"
#define	TEAM_SURVIVORS	2
#define	TEAM_INFECTED	3
#define SMOKE_DURATION 	10.0
#define BOOMER_MODEL 	"models/infected/boomer.mdl"
#define BOOMETTE_MODEL 	"models/infected/boomette.mdl"
#define BOOMER_SOUND	"player/boomer/voice/warn/male_boomer_warning_12.wav"
#define BOOMETTE_SOUND 	"player/boomer/voice/warn/female_boomer_warning_12.wav"
#define CVAR_FLAGS 		 FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY


new Handle:sdkVomitSurvivor = INVALID_HANDLE;
new Handle:sdkVomitInfected = INVALID_HANDLE;
new Handle:l4d2_boomer_laucher_enable = INVALID_HANDLE;
new Handle:l4d2_boomer_laucher_type = INVALID_HANDLE;
new Handle:l4d2_boomer_laucher_radius_survivor = INVALID_HANDLE;
new Handle:l4d2_boomer_laucher_radius_infected = INVALID_HANDLE;
//new Handle:l4d2_boomer_laucher_smoke_duration = INVALID_HANDLE;

new bool:init_plugin = false;
new launcher_type = 1;

public Plugin:myinfo =
{
	name = "L4D2 Boomer Launcher",
	author = "OIRV",
	description = "Grenade Lauchers throws boomers",
	version = PLUGIN_VERSION,
	url = " "
};
public OnPluginStart()
{ 
	CreateConVar("l4d2_boomer_launcher_version", PLUGIN_VERSION, "L4D2 Boomer Launcher Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d2_boomer_laucher_enable = CreateConVar("l4d2_boomer_laucher_enable","1", "Enable/Disable the plugin", CVAR_FLAGS);
	l4d2_boomer_laucher_type = CreateConVar("l4d2_boomer_laucher_type","1", "Grenade Type, 0 random, 1 boomer, 2 boomette", CVAR_FLAGS);
	l4d2_boomer_laucher_radius_survivor = CreateConVar("l4d2_boomer_laucher_radius_survivor","100", "Sets boomer explosion radius for survivors", CVAR_FLAGS);
	l4d2_boomer_laucher_radius_infected = CreateConVar("l4d2_boomer_laucher_radius_infected","400", "Sets boomer explosion radius for infected", CVAR_FLAGS);
	//l4d2_boomer_laucher_smoke_duration = CreateConVar("l4d2_boomer_laucher_smoke_duration","10.0", "Sets boomer launcher smoke duration", CVAR_FLAGS);
	
	HookEvent("weapon_fire", WeaponFire, EventHookMode_Pre);
	HookConVarChange(l4d2_boomer_laucher_type, OnBoomerLauncherType);
	
	new Handle:ConfigFile = LoadGameConfigFile("l4d2_boomerlauncher");	
 	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnHitByVomitJar");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitInfected = EndPrepSDKCall();
	
	if(sdkVomitInfected == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnHitByVomitJar' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	
	if(sdkVomitSurvivor == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_OnVomitedUpon' signature, check the file version!");
	}
	
	CloseHandle(ConfigFile);
}
public OnBoomerLauncherType(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(GetConVarInt(l4d2_boomer_laucher_type) < 0 || GetConVarInt(l4d2_boomer_laucher_type)>2)
	{
		SetConVarInt(l4d2_boomer_laucher_type,1,true,true);
	}
	
	if(GetConVarInt(l4d2_boomer_laucher_type)==0)
	{
		launcher_type = GetRandomInt(1,2);
	}
	else
	{
		launcher_type = GetConVarInt(l4d2_boomer_laucher_type);
	}
}
public OnMapStart()
{	
	PrecacheModel(BOOMER_MODEL, true);
	PrecacheModel(BOOMETTE_MODEL, true);
	PrecacheSound(BOOMER_SOUND,true);
	PrecacheSound(BOOMETTE_SOUND,true);
	
	if(GetConVarInt(l4d2_boomer_laucher_type)==0)
	{
		launcher_type = GetRandomInt(1,2);
	}
	else
	{
		launcher_type = GetConVarInt(l4d2_boomer_laucher_type);
	}
}
public OnClientPutInServer(client)
{
	init_plugin = true;
}
public OnEntityCreated(entity)
{
	if( !init_plugin || entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity) || GetConVarInt(l4d2_boomer_laucher_enable) != 1)
		return;
	
	decl String:EntityName[128];
	
	GetEdictClassname(entity, EntityName, sizeof(EntityName)); 
	
	if(StrEqual(EntityName, "grenade_launcher_projectile", false))
	{	
		CreateBoomer(entity, launcher_type);		
 	} 
 
}
public OnEntityDestroyed(entity)
{
	if( !init_plugin || entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity) || GetConVarInt(l4d2_boomer_laucher_enable) != 1)
		return;
		
	decl String:EntityName[128];	
	GetEdictClassname(entity, EntityName, sizeof(EntityName));
	
	if(StrEqual(EntityName, "grenade_launcher_projectile", false))
	{	
		decl Float:explosion[3],Float:target[3];		
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", explosion);
		
		for (new client = 1; client <= MaxClients; client++)
		{ 
			if( IsValidEntity(client) && IsValidEdict(client) && IsPlayerAlive(client) )
			{			
						
				GetEntPropVector(client, Prop_Data,"m_vecOrigin", target);
				VomitJar(explosion,SMOKE_DURATION);
				
				if(GetVectorDistance(explosion,target) < GetConVarFloat(l4d2_boomer_laucher_radius_infected) && GetClientTeam(client) == TEAM_INFECTED)
				{
					SDKCall(sdkVomitInfected, client, 1, true);
				}
				else
				if(GetVectorDistance(explosion,target) < GetConVarFloat(l4d2_boomer_laucher_radius_survivor) && GetClientTeam(client) == TEAM_SURVIVORS)
				{
					SDKCall(sdkVomitSurvivor, client, 1, true);
				}
			}
		}
		
		VomitWitch(explosion,SMOKE_DURATION * 2.0,GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity"));		
	}
} 
public WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[64];
	GetEventString(event,"weapon",weapon,sizeof(weapon));
	
	if(StrEqual(weapon, "grenade_launcher", false))
	{		
		if(launcher_type==1)
		{
			ClientCommand(GetClientOfUserId(GetEventInt(event,"userid")),"play player/boomer/voice/warn/male_boomer_warning_12.wav");
		}
		else
		if(launcher_type==2)
		{
			ClientCommand(GetClientOfUserId(GetEventInt(event,"userid")),"play player/boomer/voice/warn/female_boomer_warning_12.wav");
		}
	}
	 
}
public CreateBoomer(parent, model)
{
	decl Float:origin[3],Float:ang[3], String:tname[60];

	GetEntPropVector(parent, Prop_Data, "m_vecOrigin", origin);		
	GetEntPropVector(parent, Prop_Data, "m_angRotation", ang);	
	
	new boomer = CreateEntityByName("prop_dynamic_override");	
		
	if(model==1)
	{
		DispatchKeyValue(boomer,"model",BOOMER_MODEL);
		ang[0]=90.0;
		origin[2]-=30;	
		origin[0]+=5;		
	}
	else
	{
		DispatchKeyValue(boomer,"model",BOOMETTE_MODEL);
		origin[2]-=30;		
		origin[0]+=5;
	}
	
	SetEntityMoveType(boomer, MOVETYPE_NOCLIP);	
	DispatchSpawn(boomer);	
	
	TeleportEntity(boomer, origin, ang, NULL_VECTOR);
	
	Format(tname, sizeof(tname), "target%d", parent);
	DispatchKeyValue(parent, "targetname", tname); 		
	DispatchKeyValue(boomer, "parentname", tname);		
	SetVariantString(tname);
	AcceptEntityInput(boomer, "SetParent", boomer, boomer, 0); 	
		
}
public VomitWitch(Float:explosion[3], Float:duration, attacker)
{
	decl Float:origin[3], String:tname[60], witch;
	witch=-1;
	
	while((witch = FindEntityByClassname(witch, "witch")) != -1)
	{
		GetEntPropVector(witch, Prop_Data, "m_vecOrigin", origin);
	
		if(GetVectorDistance(explosion,origin) < GetConVarFloat(l4d2_boomer_laucher_radius_infected))
		{			
			SetEntProp(witch, Prop_Send, "m_iGlowType", 3);
			SetEntProp(witch, Prop_Send, "m_glowColorOverride", -4713783);
			
			new vomit = CreateEntityByName("info_goal_infected_chase");
			DispatchKeyValueVector(vomit, "origin", origin);
			DispatchSpawn(vomit);			
			AcceptEntityInput(vomit, "Enable");
			
			Format(tname, sizeof(tname), "target%d", witch);
			DispatchKeyValue(witch, "targetname", tname); 		
			DispatchKeyValue(vomit, "parentname", tname);		
			SetVariantString(tname);
			AcceptEntityInput(vomit, "SetParent",vomit, vomit, 0);
			
			SDKHooks_TakeDamage(witch, attacker, attacker, 1.0);
			CreateTimer(duration, RemoveEntity, vomit);
			CreateTimer(duration, RemoveGlow, witch);
		}
	}
}
public VomitJar(Float:origin[3], Float:duration)
{
	decl vomit, particle;	
	particle = CreateEntityByName("info_particle_system");	
	
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, origin, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", "vomit_jar");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		CreateTimer(duration, RemoveEntity, particle);				
	}

	vomit = CreateEntityByName("info_goal_infected_chase");
	DispatchKeyValueVector(vomit, "origin", origin);
	DispatchSpawn(vomit);
	AcceptEntityInput(vomit, "Enable");
	CreateTimer(duration, RemoveEntity, vomit);
	
}
public Action:RemoveGlow(Handle:timer, any:witch)
{
	if (IsValidEntity(witch) && IsValidEdict(witch))
	{
 		SetEntProp(witch, Prop_Send, "m_iGlowType", 0);
	}
}
public Action:RemoveEntity(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
 		RemoveEdict(entity);
	}
}