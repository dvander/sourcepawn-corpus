
#pragma semicolon true

//     Name: FireAttacks
//   Auhtor: Cookie Monster
// Modified: 2010-05-29

#include <sourcemod>
#include <sdktools>

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define ABILITY_DISABLED	0
#define ABILITY_ENABLED		1

#define INFECTED_BOOMER		2
#define INFECTED_CHARGER	6
#define INFECTED_HUNTER		3
#define INFECTED_JOCKEY		5
#define INFECTED_SMOKER		1
#define INFECTED_SPITTER	4

public GetBaseVelocity(client, Float:baseVelocity[3])
{
	GetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", baseVelocity);
}
public SetBaseVelocity(client, const Float:value[3])
{
	SetEntPropVector(client, Prop_Send, "m_vecBaseVelocity", value);
}

public GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}
public SetHealth(client, value)
{
	SetEntProp(client, Prop_Send, "m_iHealth", value);
}

public GetInfectedClass(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}
public SetInfectedClass(client, type)
{
	SetEntProp(client, Prop_Send, "m_zombieClass", type);
}

public GetOrigin(client, Float:origin[3])
{
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
}
public SetOrigin(client, const Float:value[3])
{
	SetEntPropVector(client, Prop_Send, "m_vecOrigin", value);
}

public GetVelocity(client, Float:velocity[3])
{
	velocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
	velocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
	velocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
}
public SetVelocity(client, const Float:value[3])
{
	SetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]", value[0]);
	SetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]", value[1]);
	SetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]", value[2]);
}

public bool:IsBoomer(client)
{
	return GetInfectedClass(client) == INFECTED_BOOMER;
}
public bool:IsCharger(client)
{
	return GetInfectedClass(client) == INFECTED_CHARGER;
}
public bool:IsHunter(client)
{
	return GetInfectedClass(client) == INFECTED_HUNTER;
}
public bool:IsJockey(client)
{
	return GetInfectedClass(client) == INFECTED_JOCKEY;
}
public bool:IsSmoker(client)
{
	return GetInfectedClass(client) == INFECTED_SMOKER;
}
public bool:IsSpitter(client)
{
	return GetInfectedClass(client) == INFECTED_SPITTER;
}

public bool:IsInfected(client)
{
	return GetClientTeam(client) == 3;
}
public bool:IsGhost(client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost") == 1;
}

public Plugin:myinfo =
{
	name		= "FireAttacks",
	author		= "Cookie Monster",
	description = "Allow charger and hunter to use fire attacks",
	url			= "http://steamcommunity.com/id/Cookie_Monster_",
	version		= "1.0.0"
};

#define STATUS_ACTIVE		1
#define STATUS_DISACTIVE	2
#define STATUS_RELOAD		3

#define IsChargeEnabled() (GetConVarInt(hChargeEnabled) == 1)
#define IsPounceEnabled() (GetConVarInt(hPounceEnabled) == 1)

#define GetChargeInterval() GetConVarFloat(hChargeInterval)
#define GetPounceInterval() GetConVarFloat(hPounceInterval)

#define GetChargeReloadTime() GetConVarFloat(hChargeReloadTime)
#define GetPounceReloadTime() GetConVarFloat(hPounceReloadTime)

#define GetChargeFOV() GetConVarInt(hChargeFOV)
#define GetPounceFOV() GetConVarInt(hPounceFOV)

#define GetChargeImpactDamage() GetConVarInt(hChargeImpactDamage)
#define GetPounceImpactDamage() GetConVarInt(hPounceImpactDamage)

#define GetChargeVelocityScaleX() GetConVarFloat(hChargeVelocityScaleX)
#define GetPounceVelocityScaleX() GetConVarFloat(hPounceVelocityScaleX)

#define GetChargeVelocityScaleY() GetConVarFloat(hChargeVelocityScaleY)
#define GetPounceVelocityScaleY() GetConVarFloat(hPounceVelocityScaleY)

#define GetChargeVelocityScaleZ() GetConVarFloat(hChargeVelocityScaleZ)
#define GetPounceVelocityScaleZ() GetConVarFloat(hPounceVelocityScaleZ)

new Handle:hChargeEnabled = INVALID_HANDLE;
new Handle:hPounceEnabled = INVALID_HANDLE;

new Handle:hChargeInterval = INVALID_HANDLE;
new Handle:hPounceInterval = INVALID_HANDLE;

new Handle:hChargeReloadTime = INVALID_HANDLE;
new Handle:hPounceReloadTime = INVALID_HANDLE;

new Handle:hChargeFOV = INVALID_HANDLE;
new Handle:hPounceFOV = INVALID_HANDLE;

new Handle:hChargeImpactDamage = INVALID_HANDLE;
new Handle:hPounceImpactDamage = INVALID_HANDLE;

new Handle:hChargeVelocityScaleX = INVALID_HANDLE;
new Handle:hPounceVelocityScaleX = INVALID_HANDLE;

new Handle:hChargeVelocityScaleY = INVALID_HANDLE;
new Handle:hPounceVelocityScaleY = INVALID_HANDLE;

new Handle:hChargeVelocityScaleZ = INVALID_HANDLE;
new Handle:hPounceVelocityScaleZ = INVALID_HANDLE;

new mChargeStatus[MAXPLAYERS];
new mPounceStatus[MAXPLAYERS];

new mChargeEffect[MAXPLAYERS];
new mPounceEffect[MAXPLAYERS];

new mHealth[MAXPLAYERS];
new mCharge[MAXPLAYERS];

public Action:ChargeUpdate(Handle:timer, any:client)
{
	if( !IsInfected(client) || !IsCharger(client) )
	{
		mCharge[client] = 0;
		ChargeEnd(INVALID_HANDLE, client);
	}

	if( IsValidEdict(mChargeEffect[client]) && mChargeEffect[client] != 0 )
	{
		decl Float:vector[3];

		GetOrigin(client, vector);
		TeleportEntity(mChargeEffect[client], vector, NULL_VECTOR, NULL_VECTOR);

		SetHealth(client, mHealth[client]);
		if( mCharge[client] == 1 )
		{
			GetVelocity(client, vector);
		
			vector[0] *= GetChargeVelocityScaleX();
			vector[1] *= GetChargeVelocityScaleZ();
			vector[2] *= GetChargeVelocityScaleY();

			SetBaseVelocity(client, vector);
		}

		SetEntProp(client, Prop_Send, "m_iFOV", GetChargeFOV());
		CreateTimer(0.016, ChargeUpdate, client);
	}
}
public Action:PounceUpdate(Handle:timer, any:client)
{
	if( !IsInfected(client) || !IsHunter(client) )
		PounceEnd(INVALID_HANDLE, client);

	if( IsValidEdict(mPounceEffect[client]) && mPounceEffect[client] != 0 )
	{
		decl Float:vector[3];

		GetOrigin(client, vector);
		TeleportEntity(mPounceEffect[client], vector, NULL_VECTOR, NULL_VECTOR);

		SetHealth(client, mHealth[client]);
		GetVelocity(client, vector);
		
		vector[0] *= GetPounceVelocityScaleX();
		vector[1] *= GetPounceVelocityScaleZ();
		vector[2] *= GetPounceVelocityScaleY();

		SetBaseVelocity(client, vector);

		SetEntProp(client, Prop_Send, "m_iFOV", GetPounceFOV());
		CreateTimer(0.016, PounceUpdate, client);
	}
}

public Action:ChargeEnd(Handle:timer, any:client)
{
	if( mChargeEffect[client] == 0 )
		return;

	if( IsValidEdict(mChargeEffect[client]) )
		RemoveEdict(mChargeEffect[client]);

	mChargeEffect[client] = 0;
	mChargeStatus[client] = STATUS_RELOAD;

	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	CreateTimer(GetChargeReloadTime(), ChargeReload, client);
}
public Action:PounceEnd(Handle:timer, any:client)
{
	if( mPounceEffect[client] == 0 )
		return;

	if( IsValidEdict(mPounceEffect[client]) )
		RemoveEdict(mPounceEffect[client]);
	
	mPounceEffect[client] = 0;
	mPounceStatus[client] = STATUS_RELOAD;
	
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	CreateTimer(GetPounceReloadTime(), PounceReload, client);
}

public Action:ChargeReload(Handle:timer, any:client)
{
	mChargeStatus[client] = STATUS_DISACTIVE;
	PrintToChat(client, "[FA] Your fire charge is reloaded");
}
public Action:PounceReload(Handle:timer, any:client)
{
	mPounceStatus[client] = STATUS_DISACTIVE;
	PrintToChat(client, "[FA] Your fire pounce is reloaded");
}

public Action:ChargeBegin(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( IsChargeEnabled() && client && IsClientInGame(client) && (mChargeStatus[client] == STATUS_ACTIVE) )
	{
		mCharge[client] = 1;
		if( mChargeEffect[client] == 0 )
		{
			new entity = CreateEntityByName("info_particle_system");

			if( IsValidEdict(entity) )
			{
				decl Float:origin[3];

				GetOrigin(client, origin);
				SetOrigin(entity, origin);

				DispatchKeyValue(entity, "effect_name", "env_fire_large");

				DispatchSpawn(entity);
				ActivateEntity(entity);

				AcceptEntityInput(entity, "start");
			}
			else entity = -1;
		
			SetEntProp(client, Prop_Send, "m_iFOV", GetChargeFOV());

			mHealth[client] = GetHealth(client);
			mChargeEffect[client] = entity;

			CreateTimer(0.01, ChargeUpdate, client);

			if( GetChargeInterval() > 0.0 )
				CreateTimer(GetChargeInterval(), ChargeEnd, client);
		}
	}
}
public Action:PounceBegin(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( IsPounceEnabled() && client && IsClientInGame(client) && (mPounceStatus[client] == STATUS_ACTIVE) && (mPounceEffect[client] == 0) )
	{
		new entity = CreateEntityByName("info_particle_system");

		if( IsValidEdict(entity) )
		{
			decl Float:origin[3];

			GetOrigin(client, origin);
			SetOrigin(entity, origin);

			DispatchKeyValue(entity, "effect_name", "env_fire_large");

			DispatchSpawn(entity);
			ActivateEntity(entity);

			AcceptEntityInput(entity, "start");
		}
		else entity = -1;
		
		SetEntProp(client, Prop_Send, "m_iFOV", GetPounceFOV());
		
		mHealth[client] = GetHealth(client);
		mPounceEffect[client] = entity;

		CreateTimer(0.01, PounceUpdate, client);

		if( GetPounceInterval() > 0.0 )
			CreateTimer(GetPounceInterval(), PounceEnd, client);
		else if( GetPounceInterval() == 0.0 )
			CreateTimer(2.0, PounceEnd, client);
	}
}

public Action:Cmd_ToggleFireAttack(client, args)
{
	if( IsInfected(client) && !IsGhost(client) )
	{
		if( IsChargeEnabled() && IsCharger(client) )
		{
			switch( mChargeStatus[client] )
			{
			case STATUS_ACTIVE:
				if( (mChargeEffect[client] == 0) )
				{
					mChargeStatus[client] = STATUS_DISACTIVE;
					PrintToChat(client, "[FA] You have disactivated the fire charge");
				}
				else
					PrintToChat(client, "[FA] The fire charge is already running");

			case STATUS_DISACTIVE:
				{
					mChargeStatus[client] = STATUS_ACTIVE;
					PrintToChat(client, "[FA] You have activated the fire charge\n - Start your charge to begin");
				}
			case STATUS_RELOAD:
				{
					PrintToChat(client, "[FA] The fire charge is reloading");
				}
			}
		}
		else if( IsPounceEnabled() && IsHunter(client) )
		{
			switch( mPounceStatus[client] )
			{
			case STATUS_ACTIVE:
				if( (mPounceEffect[client] == 0) )
				{
					mPounceStatus[client] = STATUS_DISACTIVE;
					PrintToChat(client, "[FA] You have disactivated the fire pounce");
				}
				else
					PrintToChat(client, "[FA] The fire pounce is already running");

			case STATUS_DISACTIVE:
				{
					mPounceStatus[client] = STATUS_ACTIVE;
					PrintToChat(client, "[FA] You have activated the fire pounce\n - Start your pounce to begin");
				}
			case STATUS_RELOAD:
				{
					PrintToChat(client, "[FA] The fire pounce is reloading");
				}
			}
		}
	}
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client && IsClientInGame(client) && IsInfected(client) )
	{
		if( IsCharger(client) && IsChargeEnabled() && mChargeStatus[client] == STATUS_ACTIVE && mChargeEffect[client] != 0 )
		{
			ChargeEnd(INVALID_HANDLE, client);
		}
		else if( IsHunter(client) && IsPounceEnabled() && mPounceStatus[client] == STATUS_ACTIVE && mPounceEffect[client] != 0 )
		{
			PounceEnd(INVALID_HANDLE, client);
		}
	}
}
public Action:Event_PounceVictim(Handle:event, const String:name[], bool:dontBroadCast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client && IsClientInGame(client) && mPounceStatus[client] == STATUS_ACTIVE && mPounceEffect[client] != 0 )
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		
		new health = GetHealth(victim) - GetPounceImpactDamage();

		if( health < 1 )
			health = 1;
		else if( health > 100 )
			health = 100;

		SetHealth(victim, health);

		if( GetPounceInterval() < 0.0 )
			PounceEnd(INVALID_HANDLE, client);
	}
}
public Action:Event_ChargeImpact(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client && IsClientInGame(client) && mChargeStatus[client] == STATUS_ACTIVE && mChargeEffect[client] != 0 )
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		
		new health = GetHealth(victim) - GetChargeImpactDamage();

		if( health < 1 )
			health = 1;
		else if( health > 100 )
			health = 100;

		SetHealth(victim, health);

		decl Float:velocity[3];
		GetVelocity(victim, velocity);
		
		velocity[0] *= 0.05;
		velocity[1] *= 0.05; 
		velocity[2] *= 0.075;

		SetBaseVelocity(victim, velocity);
	}
}
public Action:Event_ChargeStopped(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client && IsClientInGame(client) && mChargeStatus[client] == STATUS_ACTIVE && mChargeEffect[client] != 0 )
	{
		mCharge[client] = 0;

		if( GetChargeInterval() == 0.0 )
			ChargeEnd(INVALID_HANDLE, client);
	}
}
public Action:Event_ChargeCarry(Handle:event, const String:name[], bool:dontBroadCast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if( client && IsClientInGame(client) && mChargeStatus[client] == STATUS_ACTIVE && mChargeEffect[client] != 0 )
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		
		new health = GetHealth(victim) - GetChargeImpactDamage();

		if( health < 1 )
			health = 1;
		else if( health > 100 )
			health = 100;

		SetHealth(victim, health);

		if( GetChargeInterval() < 0.0 )
			ChargeEnd(INVALID_HANDLE, client);
	}
}

public ResetSettings(client)
{
	if(client == -1)
	{
		for(new i = 0; i < MAXPLAYERS; ++i)
		{
			mChargeStatus[i] = mPounceStatus[i] = 2;
			mChargeEffect[i] = mPounceEffect[i] = 0;
		}
	}
	else
	{
		mChargeStatus[client] = mPounceStatus[client] = 2;
		mChargeEffect[client] = mPounceEffect[client] = 0;
	}
}

public OnPluginStart()
{
	hChargeEnabled = CreateConVar("fire_charge_enabled", "0", "\n - 0 to disable\n - 1 to enable", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceEnabled = CreateConVar("fire_pounce_enabled", "0", "\n - 0 to disable\n - 1 to enable", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeInterval = CreateConVar("fire_charge_interval", "0", "\n - -1 to make the fire charge disappear after charger take it's victim.\n - 0 to make the fire charge disappear after charger end it's charge\n - > 0 to make fire charge disappear after specified time", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceInterval = CreateConVar("fire_pounce_interval", "-1", "\n - -1 to make the fire pounce disappear after hunter take it's victim.\n - 0 to make the fire pounce disappear after hunter end it's pounce(What is not really true, but I didn't find any event that allow me to end the fire pounce after hunter fail it's pounce)\n - > 0 to make fire pounce disappear after specified time", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeReloadTime = CreateConVar("fire_charge_reload_time", "30.0", "", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceReloadTime = CreateConVar("fire_pounce_reload_time", "30.0", "", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeFOV = CreateConVar("fire_charge_fov", "130", "Warning: Do not set values smaller then 1 or higher then 180!", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceFOV = CreateConVar("fire_pounce_fov", "130", "Warning: Do not set values smaller then 1 or higher then 180!", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeImpactDamage = CreateConVar("fire_charge_impact_damage", "30", "Warning: Higher values then 99 wont work",  FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceImpactDamage = CreateConVar("fire_pounce_impact_damage", "30", "Warning: Higher values then 99 wont work",  FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeVelocityScaleX = CreateConVar("fire_charge_velocity_scale_x", "0.075", "Warning: Even smaller change can cause big difference in charger's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceVelocityScaleX = CreateConVar("fire_pounce_velocity_scale_x", "0.05", "Warning: Even smaller change can cause big difference in hunter's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeVelocityScaleY = CreateConVar("fire_charge_velocity_scale_y", "0.0", "Warning: Even smaller change can cause big difference in charger's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceVelocityScaleY = CreateConVar("fire_pounce_velocity_scale_y", "0.075", "Warning: Even smaller change can cause big difference in hunter's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);

	hChargeVelocityScaleZ = CreateConVar("fire_charge_velocity_scale_z", "0.075", "Warning: Even smaller change can cause big difference in charger's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);
	hPounceVelocityScaleZ = CreateConVar("fire_pounce_velocity_scale_z", "0.05", "Warning: Even smaller change can cause big difference in hunter's velocity", FCVAR_NOTIFY | FCVAR_REPLICATED);

	RegConsoleCmd("fa", Cmd_ToggleFireAttack);
	RegConsoleCmd("fireattack", Cmd_ToggleFireAttack);

	ResetSettings(-1);

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("charger_charge_start", ChargeBegin);
	HookEvent("charger_impact", Event_ChargeImpact);
	HookEvent("charger_charge_end", Event_ChargeStopped);
	HookEvent("charger_pummel_start", Event_ChargeCarry);
	HookEvent("pounce_end", PounceBegin);
	HookEvent("lunge_pounce", Event_PounceVictim);
	
	AutoExecConfig();
}