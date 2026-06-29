#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "2.5"

#define SOLID_NONE 0
#define FSOLID_NOT_SOLID 0x0004

new Handle:hDamage;
new Handle:hRadius;
new Handle:hSpeed;
new Handle:hType;
new Handle:hEnable;
new Handle:hReplace;
new Handle:hTeam;
new Handle:hArc;
new Handle:hAmmo;
new Handle:hPrice;
new Handle:hBuyZone;
new Handle:hBuyTime;

new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
new Float:MaxNadeHull[3] = {2.5, 2.5, 2.5};
new Float:MaxWorldLength;
new Float:SpinVel[3] = {0.0, 0.0, 200.0};
new Float:SmokeOrigin[3] = {-30.0,0.0,0.0};
new Float:SmokeAngle[3] = {0.0,-180.0,0.0};

new NadeDamage;
new NadeRadius;
new Float:NadeSpeed;
new NadeType;
new Float:NadeArc;
new String:ReplaceNade[50];
new NadeAllowTeam;
new IsEnabled;
new ArcEnabled;
new NadeAmmo;
new NadePrice;
new BuyZone;
new Float:BuyTime;
new Float:BuyTimer;

new MissilesLeft[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Homing Missiles",
	author = "Blodia",
	description = "Turns projectile weapons into homing missiles",
	version = "2.5",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("missile_version", PLUGIN_VERSION, "Homing missile version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hDamage = CreateConVar("missile_damage", "100", "Sets the maximum amount of damage the missiles can do", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
	hRadius = CreateConVar("missile_radius", "350", "Sets the explosive radius of the missiles", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 1.0);
	hSpeed = CreateConVar("missile_speed", "500.0", "Sets the speed of the missiles", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 300.0 ,true, 3000.0);
	hType = CreateConVar("missile_type", "1", "Type of missile to use, 0 = dumb missiles, 1 = homing missiles, 2 = crosshair guided", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hEnable = CreateConVar("missile_enable", "1", "1 enables plugin, 0 disables plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hReplace = CreateConVar("missile_replace", "0", "replace this weapon with missiles, 0 = grenade, 1 = flashbang, 2 = smoke", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hTeam = CreateConVar("missile_team", "0", "Which team can use missiles, 0 = any, 1 = only terrorists, 2 = only counter terrorists", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 2.0);
	hArc = CreateConVar("missile_arc", "1", "1 enables the turning arc of missiles, 0 makes turning instant for missiles", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hAmmo = CreateConVar("missile_ammo", "0", "Number of projectiles that turn into missiles per player spawn, 0 is infinite", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0);
	hPrice = CreateConVar("missile_price", "0", "Price to buy a missile, 0 turns picked up projectiles into missiles", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 16000.0);
	hBuyZone = CreateConVar("missile_buyzone", "0", "1 players can only buy while in buyzone, 0 players can buy anywhere", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 1.0);
	hBuyTime = CreateConVar("missile_buytime", "0.0", "Sets the amount of time after round start players can buy missiles, 0.0 is infinite buy time", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0);
	
	NadeDamage = GetConVarInt(hDamage);
	NadeRadius = GetConVarInt(hRadius);
	NadeSpeed = GetConVarFloat(hSpeed);
	NadeType = GetConVarInt(hType);
	NadeAllowTeam = GetConVarInt(hTeam) + 1;
	NadeArc = NadeSpeed / 1000.0;
	ArcEnabled = GetConVarInt(hArc);
	NadeAmmo = GetConVarInt(hAmmo);
	IsEnabled = GetConVarInt(hEnable);
	NadePrice = GetConVarInt(hPrice);
	BuyZone = GetConVarInt(hBuyZone);
	BuyTime = GetConVarFloat(hBuyTime);
	
	switch (GetConVarInt(hReplace))
	{
		case 0:
		{
			ReplaceNade = "hegrenade_projectile";
		}
		case 1:
		{
			ReplaceNade = "flashbang_projectile";
		}
		case 2:
		{
			ReplaceNade = "smokegrenade_projectile";
		}
	}
	
	HookConVarChange(hDamage, ConVarChange);
	HookConVarChange(hRadius, ConVarChange);
	HookConVarChange(hSpeed, ConVarChange);
	HookConVarChange(hType, ConVarChange);
	HookConVarChange(hEnable, ConVarChange);
	HookConVarChange(hReplace, ConVarChange);
	HookConVarChange(hTeam, ConVarChange);
	HookConVarChange(hArc, ConVarChange);
	HookConVarChange(hAmmo, ConVarChange);
	HookConVarChange(hPrice, ConVarChange);
	HookConVarChange(hBuyZone, ConVarChange);
	HookConVarChange(hBuyTime, ConVarChange);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end",Event_RoundFreezeEnd);
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
}

public OnMapStart()
{
	new Float:WorldMinHull[3], Float:WorldMaxHull[3];
	GetEntPropVector(0, Prop_Send, "m_WorldMins", WorldMinHull);
	GetEntPropVector(0, Prop_Send, "m_WorldMaxs", WorldMaxHull);
	MaxWorldLength = GetVectorDistance(WorldMinHull, WorldMaxHull);
	
	AddFileToDownloadsTable("sound/weapons/rpg/rocket1.wav");
	
	AddFileToDownloadsTable("materials/models/weapons/w_missile/missile side.vmt");
	
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx80.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.dx90.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.mdl");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.phy");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.sw.vtx");
	AddFileToDownloadsTable("models/weapons/W_missile_closed.vvd");
	
	PrecacheModel("models/weapons/w_missile_closed.mdl");
	
	PrecacheSound("weapons/rpg/rocket1.wav");
	PrecacheSound("weapons/hegrenade/explode5.wav");
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hDamage)
	{
		NadeDamage = StringToInt(newVal);
	}
	
	else if (cvar == hRadius)
	{
		NadeRadius = StringToInt(newVal);
	}
	
	else if (cvar == hSpeed)
	{
		NadeSpeed = StringToFloat(newVal);
		NadeArc = NadeSpeed / 1000.0;
	}
	
	else if (cvar == hType)
	{
		NadeType = StringToInt(newVal);
	}
	
	else if (cvar == hEnable)
	{
		IsEnabled = StringToInt(newVal);
	}
	
	else if (cvar == hReplace)
	{
		switch (StringToInt(newVal))
		{
			case 0:
			{
				ReplaceNade = "hegrenade_projectile";
			}
			case 1:
			{
				ReplaceNade = "flashbang_projectile";
			}
			case 2:
			{
				ReplaceNade = "smokegrenade_projectile";
			}
		}
	}
	
	else if (cvar == hTeam)
	{
		NadeAllowTeam = GetConVarInt(hTeam) + 1;
	}
	
	else if (cvar == hArc)
	{
		ArcEnabled = StringToInt(newVal);
	}
	
	else if (cvar == hAmmo)
	{
		NadeAmmo = StringToInt(newVal);
	}
	
	else if (cvar == hPrice)
	{
		NadePrice = StringToInt(newVal);
	}
	
	else if (cvar == hBuyZone)
	{
		BuyZone = StringToInt(newVal);
	}
	
	else if (cvar == hBuyTime)
	{
		BuyTime = StringToFloat(newVal);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(UserId);
	
	if (client == 0)
	{
		return;
	}
	
	new ClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
	if ((NadeAllowTeam != 1) && (NadeAllowTeam != ClientTeam))
	{
		return;
	}
	
	if (IsEnabled)
	{
		if (!NadePrice)
		{
			MissilesLeft[client] = NadeAmmo;
			
			if (NadeAmmo)
			{
				PrintToChat(client, "\x04[Homing Missiles]\x05 Missiles left = %i", MissilesLeft[client]);
			}
		}
		else
		{
			MissilesLeft[client] = 0;
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (NadePrice && IsEnabled)
	{
		PrintToChatAll("\x04[Homing Missiles]\x05 Type !buymissile in chat to buy a missile for $%i.", NadePrice);
	}
	
	BuyTimer = GetGameTime() + BuyTime;
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	BuyTimer = GetGameTime() + BuyTime;
}

public Action:Command_Say(client, const String:command[], argc)
{
	new String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	if (!IsEnabled)
	{
		return Plugin_Continue;
	}
 
	if (StrEqual(text, "!buymissile", false))
	{
		if (!NadePrice)
		{
			return Plugin_Handled;
		}
			
		if ((!GetEntProp(client, Prop_Send, "m_bInBuyZone")) && (BuyZone))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 You aren't in a buyzone");
			return Plugin_Handled;
		}
		
		if ((GetGameTime() > BuyTimer) && (BuyTime != 0.0))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 Buy time is up");
			return Plugin_Handled;
		}
		
		new ClientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");
		if ((NadeAllowTeam != 1) && (NadeAllowTeam != ClientTeam))
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 Your team can't buy missiles.");
			
			return Plugin_Handled;
		}
		
		if ((MissilesLeft[client] == NadeAmmo) && NadeAmmo)
		{
			PrintToChat(client, "\x04[Homing Missiles]\x05 You can't buy anymore, you have maximum ammo");
		}
		else
		{
			new Cash = GetEntProp(client, Prop_Send, "m_iAccount");
			
			if (Cash < NadePrice)
			{
				PrintToChat(client, "\x04[Homing Missiles]\x05 You don't have $%i to buy a missile", NadePrice);
			}
			else
			{
				Cash -= NadePrice;
				SetEntProp(client, Prop_Send, "m_iAccount", Cash);
				MissilesLeft[client]++;
				PrintToChat(client, "\x04[Homing Missiles]\x05 You bought a missile");
				
				new AmmoReserve;
				if (StrEqual("hegrenade_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 11);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, "weapon_hegrenade");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 11);
					}
				}
				else if (StrEqual("flashbang_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 12);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, "weapon_flashbang");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 12);
					}
				}
				else if (StrEqual("smokegrenade_projectile", ReplaceNade, false))
				{
					AmmoReserve = GetEntProp(client, Prop_Send, "m_iAmmo", 4, 13);
					
					if (!AmmoReserve)
					{
						GivePlayerItem(client, "weapon_smokegrenade");
					}
					
					if (AmmoReserve)
					{
						SetEntProp(client, Prop_Send, "m_iAmmo", MissilesLeft[client], 4, 13);
					}
				}
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, ReplaceNade, false))
	{
		if (!IsEnabled)
		{
			return;
		}
		
		HookSingleEntityOutput(entity, "OnUser2", InitMissile, true);
		
		new String:OutputString[50] = "OnUser1 !self:FireUser2::0.0:1";
		SetVariantString(OutputString);
		AcceptEntityInput(entity, "AddOutput");
		
		AcceptEntityInput(entity, "FireUser1");
	}
}

public InitMissile(const String:output[], caller, activator, Float:delay)
{
	new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
	
	// assume other plugins don't set this on any projectiles they create, this avoids conflicts.
	if (NadeOwner == -1)
	{
		return;
	}
	
	//ignore the projectile if this team can't use missiles.
	new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	if ((NadeAllowTeam != 1) && (NadeAllowTeam != NadeTeam))
	{
		return;
	}
	
	if (!MissilesLeft[NadeOwner] && NadeAmmo)
	{
		return;
	}
	else
	{
		MissilesLeft[NadeOwner]--;
		PrintToChat(NadeOwner, "\x04[Homing Missiles]\x05 Missiles left = %i", MissilesLeft[NadeOwner]);
	}
	
	// stop the projectile thinking so it doesn't detonate.
	SetEntProp(caller, Prop_Data, "m_nNextThinkTick", -1);
	SetEntityMoveType(caller, MOVETYPE_FLY);
	SetEntityModel(caller, "models/weapons/w_missile_closed.mdl");
	// make it spin correctly.
	SetEntPropVector(caller, Prop_Data, "m_vecAngVelocity", SpinVel);
	// stop it bouncing when it hits something
	SetEntPropFloat(caller, Prop_Send, "m_flElasticity", 0.0);
	SetEntPropVector(caller, Prop_Send, "m_vecMins", MinNadeHull);
	SetEntPropVector(caller, Prop_Send, "m_vecMaxs", MaxNadeHull);
	
	switch (NadeTeam)
	{
		case 2:
		{
			SetEntityRenderColor(caller, 255, 0, 0, 255);
		}
		case 3:
		{
			SetEntityRenderColor(caller, 0, 0, 255, 255);
		}
	}
	
	new SmokeIndex = CreateEntityByName("env_rockettrail");
	if (SmokeIndex != -1)
	{
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_Opacity", 0.5);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRate", 100.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_ParticleLifetime", 0.5);
		new Float:SmokeRed[3] = {0.5, 0.25, 0.25};
		new Float:SmokeBlue[3] = {0.25, 0.25, 0.5};
		switch (NadeTeam)
		{
			case 2:
			{
				SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeRed);
			}
			case 3:
			{
				SetEntPropVector(SmokeIndex, Prop_Send, "m_StartColor", SmokeBlue);
			}
		}
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_StartSize", 5.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_EndSize", 30.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_SpawnRadius", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MinSpeed", 0.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_MaxSpeed", 10.0);
		SetEntPropFloat(SmokeIndex, Prop_Send, "m_flFlareScale", 1.0);
		
		DispatchSpawn(SmokeIndex);
		ActivateEntity(SmokeIndex);
		
		new String:NadeName[20];
		Format(NadeName, sizeof(NadeName), "Nade_%i", caller);
		DispatchKeyValue(caller, "targetname", NadeName);
		SetVariantString(NadeName);
		AcceptEntityInput(SmokeIndex, "SetParent");
		TeleportEntity(SmokeIndex, SmokeOrigin, SmokeAngle, NULL_VECTOR);
	}
	
	// make the missile go towards the coordinates the player is looking at.
	new Float:NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	new Float:OwnerAng[3];
	GetClientEyeAngles(NadeOwner, OwnerAng);
	new Float:OwnerPos[3];
	GetClientEyePosition(NadeOwner, OwnerPos);
	TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
	new Float:InitialPos[3];
	TR_GetEndPosition(InitialPos);
	new Float:InitialVec[3];
	MakeVectorFromPoints(NadePos, InitialPos, InitialVec);
	NormalizeVector(InitialVec, InitialVec);
	ScaleVector(InitialVec, NadeSpeed);
	new Float:InitialAng[3];
	GetVectorAngles(InitialVec, InitialAng);
	TeleportEntity(caller, NULL_VECTOR, InitialAng, InitialVec);
	
	EmitSoundToAll("weapons/rpg/rocket1.wav", caller, 1, 90);
	
	HookSingleEntityOutput(caller, "OnUser2", MissileThink);
	
	new String:OutputString[50] = "OnUser1 !self:FireUser2::0.1:-1";
	SetVariantString(OutputString);
	AcceptEntityInput(caller, "AddOutput");
	
	AcceptEntityInput(caller, "FireUser1");
	
	SDKHook(caller, SDKHook_StartTouch, OnStartTouch);
}

public MissileThink(const String:output[], caller, activator, Float:delay)
{
	// detonate any missiles that stopped for any reason but didn't detonate.
	decl Float:CheckVec[3];
	GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CheckVec);
	if ((CheckVec[0] == 0.0) && (CheckVec[1] == 0.0) && (CheckVec[2] == 0.0))
	{
		StopSound(caller, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(caller);
		return;
	}
	
	decl Float:NadePos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", NadePos);
	
	new NadeTeam = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	
	if (NadeType > 0)
	{
		new Float:ClosestDistance = MaxWorldLength;
		decl Float:TargetVec[3];
		
		// find closest enemy in line of sight.
		if (NadeType == 1)
		{
			new ClosestEnemy;
			new Float:EnemyDistance;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) != NadeTeam))
				{
					decl Float:EnemyPos[3];
					GetClientEyePosition(i, EnemyPos);
					TR_TraceHullFilter(NadePos, EnemyPos, MinNadeHull, MaxNadeHull, MASK_SOLID, DontHitOwnerOrNade, caller);
					if (TR_GetEntityIndex() == i)
					{
						EnemyDistance = GetVectorDistance(NadePos, EnemyPos);
						if (EnemyDistance < ClosestDistance)
						{
							ClosestEnemy = i;
							ClosestDistance = EnemyDistance;
						}
					}
				}
			}
			// no target found, continue along current trajectory.
			if (!ClosestEnemy)
			{
				AcceptEntityInput(caller, "FireUser1");
				return;
			}
			else
			{
				decl Float:EnemyPos[3];
				GetClientEyePosition(ClosestEnemy, EnemyPos);
				MakeVectorFromPoints(NadePos, EnemyPos, TargetVec);
			}
		}
		
		// make the missile go towards the coordinates the player is looking at.
		else if (NadeType == 2)
		{
			new NadeOwner = GetEntPropEnt(caller, Prop_Send, "m_hThrower");
			decl Float:OwnerAng[3];
			GetClientEyeAngles(NadeOwner, OwnerAng);
			decl Float:OwnerPos[3];
			GetClientEyePosition(NadeOwner, OwnerPos);
			TR_TraceRayFilter(OwnerPos, OwnerAng, MASK_SOLID, RayType_Infinite, DontHitOwnerOrNade, caller);
			decl Float:TargetPos[3];
			TR_GetEndPosition(TargetPos);
			ClosestDistance = GetVectorDistance(NadePos, TargetPos);
			MakeVectorFromPoints(NadePos, TargetPos, TargetVec);
		}
		
		decl Float:CurrentVec[3];
		GetEntPropVector(caller, Prop_Send, "m_vecVelocity", CurrentVec);
		decl Float:FinalVec[3];
		if (ArcEnabled && (ClosestDistance > 100.0))
		{
			NormalizeVector(TargetVec, TargetVec);
			NormalizeVector(CurrentVec, CurrentVec);
			ScaleVector(TargetVec, NadeArc);
			AddVectors(TargetVec, CurrentVec, FinalVec);
		}
		// ignore turning arc if the missile is close to the enemy to avoid it circling them.
		else
		{
			FinalVec = TargetVec;
		}
		
		NormalizeVector(FinalVec, FinalVec);
		ScaleVector(FinalVec, NadeSpeed);
		decl Float:FinalAng[3];
		GetVectorAngles(FinalVec, FinalAng);
		TeleportEntity(caller, NULL_VECTOR, FinalAng, FinalVec);
	}
	
	AcceptEntityInput(caller, "FireUser1");
}

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data)
{
	new NadeOwner = GetEntPropEnt(data, Prop_Send, "m_hThrower");
	return ((entity != data) && (entity != NadeOwner));
}

public Action:OnStartTouch(entity, other) 
{
	if (other == 0)
	{
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	}
	// detonate if the missile hits something solid.
	else if((GetEntProp(other, Prop_Data, "m_nSolidType") != SOLID_NONE) && (!(GetEntProp(other, Prop_Data, "m_usSolidFlags") & FSOLID_NOT_SOLID)))
	{
		StopSound(entity, 1, "weapons/rpg/rocket1.wav");
		CreateExplosion(entity);
	}
	return Plugin_Continue;
}

CreateExplosion(entity)
{
	UnhookSingleEntityOutput(entity, "OnUser2", MissileThink);
	
	new Float:MissilePos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", MissilePos);
	new MissileOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	new MissileOwnerTeam = GetEntProp(entity, Prop_Send, "m_iTeamNum");
	
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		DispatchKeyValue(ExplosionIndex,"classname",ReplaceNade);
		
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 6146);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", NadeDamage);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", NadeRadius);
		
		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		TeleportEntity(ExplosionIndex, MissilePos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", MissileOwner);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", MissileOwnerTeam);
		
		EmitSoundToAll("weapons/hegrenade/explode5.wav", ExplosionIndex, 1, 90);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		
		DispatchKeyValue(ExplosionIndex,"classname","env_explosion");
		
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
	
	AcceptEntityInput(entity, "Kill");
}