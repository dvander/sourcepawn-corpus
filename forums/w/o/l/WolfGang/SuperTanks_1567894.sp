#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

#define PARTICLE_SPAWN		"smoker_smokecloud"
#define PARTICLE_FIRE		"aircraft_destroy_fastFireTrail"
#define PARTICLE_WARP		"electrical_arc_01_system"
#define PARTICLE_ICE		"steam_manhole"
#define PARTICLE_SPIT		"spitter_areaofdenial_glow2"
#define PARTICLE_SPITPROJ	"spitter_projectile"
#define PARTICLE_ELEC		"electrical_arc_01_parent"
#define PARTICLE_BLOOD		"boomer_explode_D"
#define PARTICLE_EXPLODE	"boomer_explode"
#define PARTICLE_METEOR		"smoke_medium_01"

/*Arrays*/
new TankDeath[MAXPLAYERS+1];
new TankAbility[MAXPLAYERS+1];
new Rock[MAXPLAYERS+1];
new PlayerSpeed75[MAXPLAYERS+1];

/*
Super Tanks:
1)Spawn
2)Smasher
3)Warp
4)Meteor
5)Spitter
6)Heal
7)Fire
8)Ice
9)Jockey
10)Ghost
11)Shock
12)Witch
13)Shield
14)Cobalt
*/

/*Misc*/
new ad_wave;
new ad_numtanks;
new frame;
new tanktick;

/*Handles*/
new Handle:supertanksoncvar = INVALID_HANDLE;
new Handle:displayhealthcvar = INVALID_HANDLE;
new Handle:wave1cvar = INVALID_HANDLE;
new Handle:wave2cvar = INVALID_HANDLE;
new Handle:wave3cvar = INVALID_HANDLE;
new Handle:finaleonly = INVALID_HANDLE;
new Handle:gamemodecvar = INVALID_HANDLE;

new Handle:tank1 = INVALID_HANDLE;
new Handle:tank2 = INVALID_HANDLE;
new Handle:tank3 = INVALID_HANDLE;
new Handle:tank4 = INVALID_HANDLE;
new Handle:tank5 = INVALID_HANDLE;
new Handle:tank6 = INVALID_HANDLE;
new Handle:tank7 = INVALID_HANDLE;
new Handle:tank8 = INVALID_HANDLE;
new Handle:tank9 = INVALID_HANDLE;
new Handle:tank10 = INVALID_HANDLE;
new Handle:tank11 = INVALID_HANDLE;
new Handle:tank12 = INVALID_HANDLE;
new Handle:tank13 = INVALID_HANDLE;
new Handle:tank14 = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("st_version", PLUGIN_VERSION, "Super Tanks Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	supertanksoncvar = CreateConVar("st_on", "1", "Is Super Tanks enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	displayhealthcvar = CreateConVar("st_display_health", "1", "Display tanks health in crosshair?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	wave1cvar = CreateConVar("st_wave1_tanks", "1", "Default number of tanks in the 1st wave of finale.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	wave2cvar = CreateConVar("st_wave2_tanks", "2", "Default number of tanks in the 2nd wave of finale.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	wave3cvar = CreateConVar("st_wave3_tanks", "3", "Default number of tanks in the finale escape.",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,5.0);
	finaleonly = CreateConVar("st_finale_only", "1", "Create Super Tanks in finale only?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	tank1 = CreateConVar("st_spawn", "1", "Spawn Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank2 = CreateConVar("st_smasher", "1", "Smasher Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank3 = CreateConVar("st_warp", "1", "Warp Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank4 = CreateConVar("st_meteor", "1", "Meteor Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank5 = CreateConVar("st_spitter", "1", "Spitter Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank6 = CreateConVar("st_heal", "1", "Heal Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank7 = CreateConVar("st_fire", "1", "Fire Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank8 = CreateConVar("st_ice", "1", "Ice Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank9 = CreateConVar("st_jockey", "1", "Jockey Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank10 = CreateConVar("st_ghost", "1", "Ghost Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank11 = CreateConVar("st_shock", "1", "Shock Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank12 = CreateConVar("st_witch", "1", "Witch Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank13 = CreateConVar("st_shield", "1", "Shield Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);
	tank14 = CreateConVar("st_cobalt", "1", "Cobalt Tank Enabled?",FCVAR_PLUGIN|FCVAR_NOTIFY,true,0.0,true,1.0);

	HookEvent("ability_use", Ability_Use);
	HookEvent("finale_escape_start", Finale_Escape_Start);
	HookEvent("finale_start", Finale_Start, EventHookMode_Pre);
	HookEvent("finale_vehicle_leaving", Finale_Vehicle_Leaving);
	HookEvent("finale_vehicle_ready", Finale_Vehicle_Ready);
	HookEvent("player_hurt", Player_Hurt);
	HookEvent("player_death", Player_Death);
	HookEvent("tank_spawn", Tank_Spawn);
	HookEvent("round_end", Round_End);
	HookEvent("round_start", Round_Start);

	gamemodecvar = FindConVar("mp_gamemode");
	HookConVarChange(gamemodecvar, GamemodeCvarChanged);
	HookConVarChange(supertanksoncvar, SuperTanksCvarChanged);

	CreateTimer(0.1,TimerUpdate01, _, TIMER_REPEAT);
	CreateTimer(1.0,TimerUpdate1, _, TIMER_REPEAT);

	Init();
	
	/* Config Creation*/
	AutoExecConfig(true,"SuperTanks");
}
//=============================
// StartUp
//=============================
Init()
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		decl String:gamemode[24];
		GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
       		if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
		{
			PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
			PrintToServer("[SuperTanks] Plugin Disabled.");
			SetConVarInt(supertanksoncvar, 0);		
		}
	}
}
//=============================
// Events
//=============================
public GamemodeCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (convar == gamemodecvar)
		{
       			if (StrEqual(oldValue, newValue, false)) return;

       			if (!StrEqual(newValue, "coop", false) && !StrEqual(newValue, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarInt(supertanksoncvar, 0);
			}	
		}
	}
}
public SuperTanksCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == supertanksoncvar)
	{
		new oldval = StringToInt(oldValue);
		new newval = StringToInt(newValue);

		if (newval == oldval) return;

		if (newval == 1)
		{
			decl String:gamemode[24];
			GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
       			if (!StrEqual(gamemode, "coop", false) && !StrEqual(gamemode, "realism", false))
			{
				PrintToServer("[SuperTanks] This plugin is only compatible in Coop or Realism gamemodes.");
				PrintToServer("[SuperTanks] Plugin Disabled.");
				SetConVarInt(supertanksoncvar, 0);		
			}	
		}
	}
}
public OnMapStart()
{
	PrecacheParticle(PARTICLE_SPAWN);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
	PrecacheParticle(PARTICLE_ICE);
	PrecacheParticle(PARTICLE_SPIT);
	PrecacheParticle(PARTICLE_SPITPROJ);
	PrecacheParticle(PARTICLE_ELEC);
	PrecacheParticle(PARTICLE_BLOOD);
	PrecacheParticle(PARTICLE_EXPLODE);
	PrecacheParticle(PARTICLE_METEOR);
	PrecacheModel("models/props_junk/gascan001a.mdl");
	PrecacheModel("models/props_junk/propanecanister001a.mdl");
    	PrecacheModel("models/infected/witch.mdl");
	PrecacheModel("models/infected/witch_bride.mdl");
	PrecacheSound("ambient/ambience/rainscapes/rain/debris_05.wav");
	PrecacheSound("ambient/fire/gascan_ignite1.wav");
	PrecacheSound("player/charger/hit/charger_smash_02.wav");
	PrecacheSound("npc/infected/action/die/male/death_42.wav");
	PrecacheSound("npc/infected/action/die/male/death_43.wav");
	PrecacheSound("ambient/energy/zap1.wav");
	PrecacheSound("ambient/energy/zap5.wav");
	PrecacheSound("ambient/energy/zap7.wav");
	PrecacheSound("player/spitter/voice/warn/spitter_spit_02.wav");
	PrecacheSound("player/tank/voice/growl/tank_climb_01.wav");
	PrecacheSound("player/tank/voice/growl/tank_climb_02.wav");
	PrecacheSound("player/tank/voice/growl/tank_climb_03.wav");
	PrecacheSound("player/tank/voice/growl/tank_climb_04.wav");
}
public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnSurvivorTakeDamage);
	TankDeath[client] = 0;
	TankAbility[client] = 0;
	Rock[client] = 0;
	PlayerSpeed75[client] = 0;
}
public Action:Ability_Use(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				if (IsTank(client))
				{
					new color = GetEntityRenderColor(client);
					switch(color)
					{		
						case 12800: ResetInfectedAbility(client, 6.0); //Fire Tank
						case 303030: ResetInfectedAbility(client, 10.0); //Spawn Tank
						case 0100170: ResetInfectedAbility(client, 6.0); //Ice Tank
						case 0105255: ResetInfectedAbility(client, 999.0); //Cobalt Tank
						case 1002525: ResetInfectedAbility(client, 10.0); //Meteor Tank
						case 2552000: ResetInfectedAbility(client, 7.0); //Jockey Tank
						case 7080100: ResetInfectedAbility(client, 30.0); //Smasher Tank
						case 12115128: ResetInfectedAbility(client, 6.0); //Spitter Tank
						case 100255200: ResetInfectedAbility(client, 15.0); //Heal Tank
						case 100100100: ResetInfectedAbility(client, 15.0); //Ghost Tank
						case 100165255: ResetInfectedAbility(client, 10.0); //Shock Tank
						case 130130255: ResetInfectedAbility(client, 9.0); //Warp Tank
						case 135205255: ResetInfectedAbility(client, 8.0); //Shield Tank
						case 255200255: ResetInfectedAbility(client, 7.0); //Witch Tank
					}
				}
			}
		}
	}
}
public Action:Finale_Escape_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	ad_wave = 3;
}
public Action:Finale_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	ad_wave = 1;
}
public Action:Finale_Vehicle_Leaving(Handle:event, String:event_name[], bool:dontBroadcast)
{
	ad_wave = 4;
}
public Action:Finale_Vehicle_Ready(Handle:event, String:event_name[], bool:dontBroadcast)
{
	ad_wave = 3;
}
public Action:Player_Death(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (client > 0)
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			if (IsClientInGame(client))
			{
				if (GetClientTeam(client) == 3)
				{
					if (IsTank(client))
					{
						TankDeath[client] = 1;
						TankAbility[client] = 0;

						new String:classname[32];
						new entitycount = GetMaxEntities();
						for (new e=1; e<=entitycount; e++)
						{
							if (IsValidEntity(e))
							{
								GetEdictClassname(e, classname, sizeof(classname));
								if (StrEqual(classname, "prop_dynamic"))
								{
           								decl String:model[128];
            								GetEntPropString(e, Prop_Data, "m_ModelName", model, sizeof(model));
									if (StrEqual(model, "models/props_debris/concrete_chunk01a.mdl"))
									{
										new owner = GetEntProp(e, Prop_Send, "m_hOwnerEntity");
										if (owner == client)
										{
											AcceptEntityInput(e, "Kill");
										}
									}
								}
							}
						}
						if (ad_wave == 1)
						{
							CreateTimer(5.0, Timer_Wave2, _, TIMER_FLAG_NO_MAPCHANGE);
						}
						else if (ad_wave == 2)
						{
							CreateTimer(5.0, Timer_Wave3, _, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}		
			}	
		}
	}
}
public Action:Player_Hurt(Handle:event, const String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
    	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new health = GetEventInt(event, "health");
	new dmg = GetEventInt(event, "dmg_health");
	new type = GetEventInt(event, "type");
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (client > 0)
		{
			if (IsClientInGame(client))
			{
				if (IsTank(client))
				{
					//PrintToChatAll("Damage:%i, Type:%i",dmg,type);
					new color = GetEntityRenderColor(client);
					if (color != 255255255 && color != 7080100)
					{
						if (type == 8 || type == 2056 || type == 268435464)
						{
							SetEntProp(client, Prop_Data, "m_iHealth",(health + dmg));
							return;
						}
					}
				}
			}
			if (attacker > 0)
			{
				if (IsClientInGame(attacker) && GetClientTeam(attacker) == 2)
				{
					if (IsTank(client))
					{
						new color = GetEntityRenderColor(client);
						switch(color)
						{
							//Fire Tank
							case 12800:
							{
								if (StrEqual(weapon, "melee"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										SkillFlameGush(client);
									}
								}
							}
							//Meteor Tank
							case 1002525:
							{
								if (StrEqual(weapon, "melee"))
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										if (TankAbility[client] == 0)
										{
											StartMeteorFall(client);
										}
									}
								}
							}
							//Spitter Tank
							case 12115128:
							{
								if (StrEqual(weapon, "melee"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										new x = CreateFakeClient("Spitter");
										if (x > 0)
										{
											new Float:Pos[3];
											GetClientAbsOrigin(client, Pos);
											TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);	
											SDKCallSpitterSpit(x);
											KickClient(x);
										}
									}
								}
							}
							//Ghost Tank
							case 100100100:
							{
								if(StrEqual(weapon, "melee"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										ForceWeaponDrop(attacker);
										EmitSoundToClient(attacker, "npc/infected/action/die/male/death_42.wav", client);
									}
								}
							}
							//Shield Tank
							case 135205255:
							{
								new glow = GetEntProp(client, Prop_Send, "m_iGlowType");
								new glowcolor = GetEntProp(client, Prop_Send, "m_glowColorOverride");
								new tankhealth = GetEntProp(client, Prop_Data, "m_iHealth");
								if (glow > 0 && glowcolor == 075075255255)
								{
									if (type == 134217792 || type == 33554432 || type == 16777280)
									{
										SetEntProp(client, Prop_Send, "m_iGlowType", 0);
										SetEntProp(client, Prop_Send, "m_bFlashing", 0);
										SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
										CreateTimer(8.0, Timer_ActivateShield, client, TIMER_FLAG_NO_MAPCHANGE);
									}
									else
									{
										SetEntProp(client, Prop_Data, "m_iHealth", tankhealth + dmg);
									}
								}
							}
						}
					}
				}
				else if (IsClientInGame(attacker) && GetClientTeam(attacker) == 3)
				{
					if (IsTank(attacker) && GetClientTeam(client) == 2)
					{
						new color = GetEntityRenderColor(attacker);
						switch(color)
						{
							//Fire Tank
							case 12800:
							{
								if (StrEqual(weapon, "tank_claw") || StrEqual(weapon, "tank_rock"))
								{
									SkillFlameClaw(client);
								}
							}
							//Spawn Tank
							case 303030:
							{
								if (StrEqual(weapon, "tank_claw"))
								{
									new random = GetRandomInt(1,4);
									if (random == 1)
									{
										SDKCallVomitOnPlayer(client, attacker);
									}
								}
							}
							//Cobalt Tank
							case 0105255:
							{
								if (StrEqual(weapon, "tank_claw"))
								{
									TankAbility[attacker] = 0;
								}
							}
							//Smasher Tank
							case 7080100:
							{
								if (StrEqual(weapon, "tank_claw") && type == 128)
								{
									new random = GetRandomInt(1,2);
									if (random == 1)
									{
										SkillSmashClawKill(client, attacker);
									}
									else
									{
										SkillSmashClaw(client);
									}
								}
							}
							//Shock Tank
							case 100165255:
							{
								if (StrEqual(weapon, "tank_claw"))
								{
									SkillElecClaw(client, attacker);
								}
							}
							//Warp Tank
							case 130130255:
							{
								if (StrEqual(weapon, "tank_claw") && type == 128)
								{
									new damage = dmg / 2;
									DealDamagePlayer(client, attacker, 2, damage);
								}
							}
						}
					}
				}
			}
		}
	}
}
public Action:Round_End(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && !IsTank(i))
			{
				if (CountInfectedAll() > 16)
				{
					KickClient(i);
				}
			}
		}
	}
}
public Action:Round_Start(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		tanktick = 0;
		ad_wave = 0;
		ad_numtanks = 0;

		new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
		SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
		SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
		SetConVarInt(FindConVar("z_hunter_limit"), 32);
		SetConVarInt(FindConVar("z_jockey_limit"), 32);
		SetConVarInt(FindConVar("z_charger_limit"), 32);
		SetConVarInt(FindConVar("z_hunter_limit"), 32);
		SetConVarInt(FindConVar("z_boomer_limit"), 32);
		SetConVarInt(FindConVar("z_spitter_limit"), 32);

		for (new client=1; client<=MaxClients; client++)
		{
			TankDeath[client] = 0;
			TankAbility[client] = 0;
			Rock[client] = 0;
			PlayerSpeed75[client] = 0;
		}
	}
}
public Action:Tank_Spawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client =  GetClientOfUserId(GetEventInt(event, "userid"));
	if (client<=0)
		return;

	TankDeath[client] = 0;
	TankAbility[client] = 0;
	CountTanks();

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		CreateTimer(0.1, TankSpawnTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		if (GetConVarInt(finaleonly) == 0 || (GetConVarInt(finaleonly) == 1 && ad_wave > 0))
		{
			RandomizeTank(client);
			switch(ad_wave)
			{
				case 1:
				{
					if (ad_numtanks < GetConVarInt(wave1cvar))
					{
						CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (ad_numtanks > GetConVarInt(wave1cvar))
					{
						if (IsFakeClient(client))
						{
							KickClient(client);
						}
					}
				}
				case 2:
				{
					if (ad_numtanks < GetConVarInt(wave2cvar))
					{
						CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (ad_numtanks > GetConVarInt(wave2cvar))
					{
						if (IsFakeClient(client))
						{
							KickClient(client);
						}
					}
				}
				case 3:
				{
					if (ad_numtanks < GetConVarInt(wave3cvar))
					{
						CreateTimer(5.0, SpawnTankTimer, _, TIMER_FLAG_NO_MAPCHANGE);
					}
					else if (ad_numtanks > GetConVarInt(wave3cvar))
					{
						if (IsFakeClient(client))
						{
							KickClient(client);
						}
					}
				}
			}
		}
	}
}
//=============================
// TANK CONTROLLER
//=============================
public TankController()
{
	CountTanks();
	if (ad_numtanks > 0)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsTank(i))
			{
				new color = GetEntityRenderColor(i);
				//Extinquish fire for certain custom tanks
				if (color != 255255255 && color != 7080100)
				{
					if (IsPlayerBurning(i))
					{
						ExtinguishEntity(i);
						SetEntPropFloat(i, Prop_Send, "m_burnPercent", 1.0);
					}
				}
				switch(color)
				{
					//Fire Tank
					case 12800:
					{
						IgniteEntity(i, 1.0);		
					}
					//Spawn Tank
					case 303030:
					{
						tanktick += 1;
						if (tanktick >= 10)
						{
							for (new count=1; count<=10; count++)
							{
								CheatCommand(i, "z_spawn", "zombie area");
							}
							tanktick = 0;
						}
					}
					//Cobalt Tank
					case 0105255:
					{
						if (TankAbility[i] == 0)
						{
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.0);
							new random = GetRandomInt(1,9);
							if (random == 1)
							{
								TankAbility[i] = 1;
								CreateTimer(0.3, BlurEffect, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
							}
						}
						else if (TankAbility[i] == 1)
						{
							SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 2.5);
						}
					}
					//Jockey Tank
					case 2552000:
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 1.33);
					}
					//Smasher Tank
					case 7080100:
					{
						SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", 0.65);		
					}
					//Heal Tank
					case 100255200:
					{
						HealTank(i);
						if (CountTankRange(i) > 0)
						{
							SetEntProp(i, Prop_Send, "m_iGlowType", 3);
							SetEntProp(i, Prop_Send, "m_bFlashing", 1);
							SetEntProp(i, Prop_Send, "m_glowColorOverride", 119911);
						}
						else
						{
							SetEntProp(i, Prop_Send, "m_iGlowType", 0);
							SetEntProp(i, Prop_Send, "m_bFlashing", 0);
							SetEntProp(i, Prop_Send, "m_glowColorOverride", 0);
						}
					}
					//Warp Tank
					case 130130255:
					{
						TeleportTank(i);
					}
					//Ghost Tank
					case 100100100:
					{
						InfectedCloak(i);
						if (CountSurvRange(i) == CountSurvivorsAliveAll())
						{
							SetEntityRenderMode(i, RenderMode:3);
      	 						SetEntityRenderColor(i, 100, 100, 100, 50);
							EmitSoundToAll("npc/infected/action/die/male/death_43.wav", i);
						}
						else
						{
							SetEntityRenderMode(i, RenderMode:3);
      	 						SetEntityRenderColor(i, 100, 100, 100, 150);
							EmitSoundToAll("npc/infected/action/die/male/death_42.wav", i);
						}
					}
					//Witch Tank
					case 255200255:
					{
						SpawnWitch(i);		
					}		
				}		
			}
		}
	}
}
public Action:TankSpawnTimer(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsTank(client))
		{
			SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(FindConVar("z_tank_health")));
			new color = GetEntityRenderColor(client);
			switch(color)
			{
				//Fire Tank
				case 12800:
				{
					ResetInfectedAbility(client, 6.0);
					CreateTimer(0.8, Timer_AttachFIRE,client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Fire Tank");
					}
				}
				//Spawn Tank
				case 303030:
				{
					ResetInfectedAbility(client, 10.0);
					CreateTimer(1.2, Timer_AttachSPAWN, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Spawn Tank");
					}
				}
				//Ice Tank
				case 0100170:
				{
					ResetInfectedAbility(client, 6.0);
					CreateTimer(2.0, Timer_AttachICE, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Ice Tank");
					}
				}
				//Cobalt Tank
				case 0105255:
				{
					ResetInfectedAbility(client, 999.0);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Cobalt Tank");
					}
				}
				//Meteor Tank
				case 1002525:
				{
					ResetInfectedAbility(client, 10.0);
					CreateTimer(0.1, MeteorTankTimer, client, TIMER_FLAG_NO_MAPCHANGE);
					CreateTimer(6.0, Timer_AttachMETEOR, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Meteor Tank");
					}
				}
				//Jockey Tank
				case 2552000:
				{
					ResetInfectedAbility(client, 7.0);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Jockey Tank");
					}
				}
				//Smasher Tank
				case 7080100:
				{
					ResetInfectedAbility(client, 30.0);
					SetEntProp(client, Prop_Send, "m_iGlowType", 3);
					new glowcolor = RGB_TO_INT(50, 50, 50);
					SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Smasher Tank");
					}
				}		
				//Spitter Tank
				case 12115128:
				{
					ResetInfectedAbility(client, 6.0);
					CreateTimer(2.0, Timer_AttachSPIT, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Spitter Tank");
					}
				}
				//Heal Tank
				case 100255200:
				{
					ResetInfectedAbility(client, 15.0);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Heal Tank");
					}
				}				
				//Ghost Tank
				case 100100100:
				{
					ResetInfectedAbility(client, 15.0);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Ghost Tank");
					}
				}
				//Shock Tank
				case 100165255:
				{
					ResetInfectedAbility(client, 10.0);
					CreateTimer(0.8, Timer_AttachELEC, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Shock Tank");
					}
				}
				//Warp Tank
				case 130130255:
				{
					ResetInfectedAbility(client, 9.0);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Warp Tank");
					}
				}
				//Shield Tank
				case 135205255:
				{
					ResetInfectedAbility(client, 8.0);
					SetEntProp(client, Prop_Send, "m_iGlowType", 3);
					SetEntProp(client, Prop_Send, "m_bFlashing", 2);
					SetEntProp(client, Prop_Send, "m_glowColorOverride", 075075255255);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Shield Tank");
					}
				}		
				//Witch Tank
				case 255200255:
				{
					ResetInfectedAbility(client, 7.0);
					CreateTimer(2.0, Timer_AttachBLOOD, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
					if (IsFakeClient(client))
					{
						SetClientInfo(client, "name", "Witch Tank");
					}
				}				
			}
		}
	}
}
//=============================
// Speed on Ground and in Water
//=============================
SpeedRebuild(client)
{
	new Float:value;
	if (PlayerSpeed75[client] > 0)
	{
		value = 0.75;
	}
	else
	{
		value = 1.0;
	}
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", value);
}
//=============================
// SDK CALLS
//=============================
stock SDKCallSpitterSpit(client)
{
    	static Handle:hSpitterSpit=INVALID_HANDLE;
    	if (hSpitterSpit==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("supertanks");
        StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CSpitterProjectile_Detonate");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        hSpitterSpit = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hSpitterSpit == INVALID_HANDLE){
            	SetFailState("Can't initialize CSpitterProjectile_Detonate SDKCall!");
            	return;
        }            
   	}
    	SDKCall(hSpitterSpit,client,true);
}
stock SDKCallVomitOnPlayer(target, client)
{
    	static Handle:hVomitOnPlayer=INVALID_HANDLE;
    	if (hVomitOnPlayer==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("supertanks");
        StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        hVomitOnPlayer = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hVomitOnPlayer == INVALID_HANDLE){
            	SetFailState("Can't initialize CTerrorPlayer_OnVomitedUpon SDKCall!");
            	return;
        }            
    	}
    	SDKCall(hVomitOnPlayer,target,client,true);
}
stock SDKCallWeaponDrop(weapon, client)
{
    	static Handle:hWeaponDrop=INVALID_HANDLE;
    	if (hWeaponDrop==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("supertanks");
        StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "Weapon_Drop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        hWeaponDrop = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hWeaponDrop == INVALID_HANDLE){
            	SetFailState("Can't initialize Weapon_Drop SDKCall!");
            	return;
        }            
    	}
    	SDKCall(hWeaponDrop,client,weapon);
}
//=============================
// FUNCTIONS
//=============================
public OnEntityCreated(entity, const String:classname[])
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (StrEqual(classname, "tank_rock", true))
		{
			CreateTimer(0.1, RockThrowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public OnEntityDestroyed(entity)
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (IsValidEntity(entity) && IsValidEdict(entity))
		{
			new String:classname[32];
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "tank_rock", true))
			{
				new color = GetEntityRenderColor(entity);
				switch(color)
				{
					//Fire
					case 12800:
					{
						new prop = CreateEntityByName("prop_physics");
						if (IsValidEntity(prop))
						{
							new Float:Pos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
							Pos[2] += 10.0;
							DispatchKeyValue(prop, "model", "models/props_junk/gascan001a.mdl");
							DispatchSpawn(prop);
							SetEntData(prop, GetEntSendPropOffs(prop, "m_CollisionGroup"), 1, 1, true);
							TeleportEntity(prop, Pos, NULL_VECTOR, NULL_VECTOR);
							AcceptEntityInput(prop, "break");
						}
					}
					//Spitter
					case 12115128:
					{
						new x = CreateFakeClient("Spitter");
						if (x > 0)
						{
							new Float:Pos[3];
							GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
							TeleportEntity(x, Pos, NULL_VECTOR, NULL_VECTOR);	
							SDKCallSpitterSpit(x);
							KickClient(x);
						}
					}
				}
			}
		}
	}
}
stock Pick()
{
    	new count, clients[MaxClients];
    	for (new i=1; i<= MaxClients; i++)
    	{
        	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
            		clients[count++] = i; 
    	}
    	return clients[GetRandomInt(0,count-1)];
}
stock bool:IsTank(i)
{
	if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsPlayerIncap(i) && TankDeath[i] == 0)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "hulk", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsSmoker(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "smoker", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsBoomer(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "boomer", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsHunter(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "hunter", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsCharger(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "charger", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsJockey(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "jockey", false) != -1)
			return true;
		return false;
	}
	return false;
}
stock bool:IsSpitter(i)
{
	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
	{
		decl String: classname[32];
		GetClientModel(i, classname, sizeof(classname));
		if (StrContains(classname, "spitter", false) != -1)
			return true;
		return false;
	}
	return false;
}
bool:IsWitch(i)
{
	if (IsValidEntity(i))
	{
		decl String: classname[32];
		GetEdictClassname(i, classname, sizeof(classname));
		if (StrEqual(classname, "witch"))
			return true;
		return false;
	}
	return false;
}
stock CountTanks()
{
	ad_numtanks = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTank(i))
		{
			ad_numtanks++;
		}
	}
}
stock CountWitches()
{
	new count;
	decl String: classname[32];
	new entitycount = GetMaxEntities();
	for (new j=1; j<=entitycount; j++)
	{
		if (IsValidEntity(j))
		{
			GetEdictClassname(j, classname, sizeof(classname));
			if (StrEqual(classname, "witch"))
			{
				count++;
			}
		}
	}
	return count;
}
public Action:TankLifeCheck(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		new lifestate = GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_lifeState"));
		if (lifestate == 0)
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				new Float: Origin[3], Float:Angles[3];
				GetClientAbsOrigin(client, Origin);
				GetClientAbsAngles(client, Angles);
				KickClient(client);
				TeleportEntity(bot, Origin, Angles, NULL_VECTOR);
				SpawnInfected(bot, 8, true);
			}
		}	
	}
}
stock RandomizeTank(client)
{
	new count;
	new TempArray[14+1];

	if (GetConVarInt(tank1) == 1)
	{
		TempArray[count+1] = 1;
		count++;	
	}
	if (GetConVarInt(tank2) == 1)
	{
		TempArray[count+1] = 2;
		count++;	
	}
	if (GetConVarInt(tank3) == 1)
	{
		TempArray[count+1] = 3;
		count++;	
	}
	if (GetConVarInt(tank4) == 1)
	{
		TempArray[count+1] = 4;
		count++;	
	}
	if (GetConVarInt(tank5) == 1)
	{
		TempArray[count+1] = 5;
		count++;	
	}
	if (GetConVarInt(tank6) == 1)
	{
		TempArray[count+1] = 6;
		count++;	
	}
	if (GetConVarInt(tank7) == 1)
	{
		TempArray[count+1] = 7;
		count++;	
	}
	if (GetConVarInt(tank8) == 1)
	{
		TempArray[count+1] = 8;
		count++;	
	}
	if (GetConVarInt(tank9) == 1)
	{
		TempArray[count+1] = 9;
		count++;	
	}
	if (GetConVarInt(tank10) == 1)
	{
		TempArray[count+1] = 10;
		count++;	
	}
	if (GetConVarInt(tank11) == 1)
	{
		TempArray[count+1] = 11;
		count++;	
	}
	if (GetConVarInt(tank12) == 1)
	{
		TempArray[count+1] = 12;
		count++;	
	}
	if (GetConVarInt(tank13) == 1)
	{
		TempArray[count+1] = 13;
		count++;	
	}
	if (GetConVarInt(tank14) == 1)
	{
		TempArray[count+1] = 14;
		count++;	
	}

	if (count > 0)
	{
		new random = GetRandomInt(1,count);
		new tankpick = TempArray[random];
		switch(tankpick)
		{
			case 1:
			{
				//Spawn
      	 			SetEntityRenderColor(client, 30, 30, 30, 255);
			}
			case 2:
			{
				//Smasher
      	 			SetEntityRenderColor(client, 70, 80, 100, 255);
			}
			case 3:
			{
				//Warp
      	 			SetEntityRenderColor(client, 130, 130, 255, 255);
			}
			case 4:
			{
				//Meteor
      	 			SetEntityRenderColor(client, 100, 25, 25, 255);
			}
			case 5:
			{
				//Spitter
      	 			SetEntityRenderColor(client, 12, 115, 128, 255);
			}
			case 6:
			{
				//Heal
      	 			SetEntityRenderColor(client, 100, 255, 200, 255);
			}
			case 7:
			{
				//Fire
      	 			SetEntityRenderColor(client, 128, 0, 0, 255);
			}
			case 8:
			{
				//Ice
				SetEntityRenderMode(client, RenderMode:3);
      	 			SetEntityRenderColor(client, 0, 100, 170, 200);
			}
			case 9:
			{
				//Jockey
      	 			SetEntityRenderColor(client, 255, 200, 0, 255);
			}
			case 10:
			{
				//Ghost
				SetEntityRenderMode(client, RenderMode:3);
      	 			SetEntityRenderColor(client, 100, 100, 100, 0);
			}
			case 11:
			{
				//Shock
      	 			SetEntityRenderColor(client, 100, 165, 255, 255);
			}
			case 12:
			{
				//Witch
      	 			SetEntityRenderColor(client, 255, 200, 255, 255);
			}
			case 13:
			{
				//Shield
      	 			SetEntityRenderColor(client, 135, 205, 255, 255);
			}
			case 14:
			{
				//Cobalt
      	 			SetEntityRenderColor(client, 0, 105, 255, 255);
			}
		}
	}
}
stock SpawnInfected(client, Class, bool:bAuto=true)
{
	new bool:resetGhostState[MaxClients+1];
	new bool:resetIsAlive[MaxClients+1];
	new bool:resetLifeState[MaxClients+1];
	ChangeClientTeam(client, 3);
	new String:g_sBossNames[9+1][10]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};
	decl String:options[30];
	if (Class < 1 || Class > 8) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsClientInGame(client)) return false;
	if (IsPlayerAlive(client)) return false;
	
	for (new i=1; i<=MaxClients; i++){ 
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip
		
		if (IsPlayerGhost(i)){
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true; 
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i)){
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	Format(options,sizeof(options),"%s%s",g_sBossNames[Class],(bAuto?" auto":""));
	CheatCommand(client, "z_spawn", options);
	if (IsFakeClient(client)) KickClient(client);
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++){
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}

	return true;
}
stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost){	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
	}else{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
	}
}
stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}
stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}
stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}
stock bool:IsPlayerIncap(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
stock NearestSurvivor(j)
{
    	new target, Float:InfectedPos[3], Float:SurvivorPos[3], Float:nearest = 0.0;
   	for (new i=1; i<=MaxClients; i++)
    	{
        	if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && ChaseTarget[i] == 0)
		{
			GetClientAbsOrigin(j, InfectedPos);
			GetClientAbsOrigin(i, SurvivorPos);
                        new Float:distance = GetVectorDistance(InfectedPos, SurvivorPos);
                        if (nearest == 0.0)
			{
				nearest = distance;
				target = i;
			}
			else if (nearest > distance)
			{
				nearest = distance;
				target = i;
			}
		} 
    	}
    	return target;
}
stock CountSurvivorsAliveAll()
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			count++;
		}
	}
	return count;
}
stock CountInfectedAll()
{
	new count = 0;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			count++;
		}
	}
	return count;
}
bool:IsPlayerBurning(i)
{
	new Float:IsBurning = GetEntPropFloat(i, Prop_Send, "m_burnPercent");
	if (IsBurning > 0) 
		return true;
	return false;
}
public Action:CreateParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0)
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
        		new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    	}
}
public Action:AttachParticle(target, String:particlename[], Float:time, Float:origin)
{
	if (target > 0 && IsValidEntity(target))
	{
   		new particle = CreateEntityByName("info_particle_system");
    		if (IsValidEntity(particle))
    		{
        		new Float:pos[3];
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
			pos[2] += origin;
			TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
			decl String:tName[64];
			Format(tName, sizeof(tName), "Attach%d", target);
			DispatchKeyValue(target, "targetname", tName);
			GetEntPropString(target, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "scale", "");
			DispatchKeyValue(particle, "effect_name", particlename);
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "targetname", "particle");
			DispatchSpawn(particle);
			ActivateEntity(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", particle, particle);
			AcceptEntityInput(particle, "Enable");
			AcceptEntityInput(particle, "start");
			CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		}
    	}
}
public Action:PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.1, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	}  
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
    	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
            		AcceptEntityInput(particle, "Kill");
	}
}
public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
		BfWriteShort(msg, (0x0002 | 0x0008));
	else
		BfWriteShort(msg, (0x0001 | 0x0010));
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}
public ScreenShake(target, Float:intensity)
{
	new Handle:msg;
	msg = StartMessageOne("Shake", target);
	
	BfWriteByte(msg, 0);
 	BfWriteFloat(msg, intensity);
 	BfWriteFloat(msg, 10.0);
 	BfWriteFloat(msg, 3.0);
	EndMessage();
}
public Action:RockThrowTimer(Handle:timer)
{
	decl String:classname[32];
	new entitycount = GetMaxEntities();
	for (new entity=1; entity<=entitycount; entity++)
	{
		if (IsValidEntity(entity))
		{
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "tank_rock"))
			{
				new thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
				if (thrower > 0 && thrower < 33 && IsTank(thrower))
				{
					new color = GetEntityRenderColor(thrower);
					switch(color)
					{
						//Fire Tank
						case 12800:
						{
      	 						SetEntityRenderColor(entity, 128, 0, 0, 255);
							CreateTimer(0.8, Timer_AttachFIRE_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
						//Ice Tank
						case 0100170:
						{
							SetEntityRenderMode(entity, RenderMode:3);
							SetEntityRenderColor(entity, 0, 100, 170, 180);
						}
						//Jockey Tank
						case 2552000:
						{
							Rock[thrower] = entity;
							CreateTimer(0.1, JockeyThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
						//Spitter Tank
						case 12115128:
						{
							SetEntityRenderMode(entity, RenderMode:3);
      	 						SetEntityRenderColor(entity, 121, 151, 28, 30);
							CreateTimer(0.8, Timer_SpitSound, thrower, TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(0.8, Timer_AttachSPIT_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
						//Shock Tank
						case 100165255:
						{
							CreateTimer(0.8, Timer_AttachELEC_Rock, entity, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
						//Shield Tank
						case 135205255:
						{
							Rock[thrower] = entity;
							CreateTimer(0.1, PropaneThrow, thrower, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}
public Action:PropaneThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			new propane = CreateEntityByName("prop_physics");
			if (IsValidEntity(propane))
			{
				DispatchKeyValue(propane, "model", "models/props_junk/propanecanister001a.mdl");
				DispatchSpawn(propane);
				new Float:Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
				AcceptEntityInput(entity, "Kill");
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				TeleportEntity(propane, Pos, NULL_VECTOR, velocity);
			}	
			return Plugin_Stop;
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action:JockeyThrow(Handle:timer, any:client)
{
	new Float:velocity[3];
	new entity = Rock[client];
	if (IsValidEntity(entity))
	{
		new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");	
		GetEntDataVector(entity, g_iVelocity, velocity);
		new Float:v = GetVectorLength(velocity);
		if (v > 500.0)
		{
			new bot = CreateFakeClient("Jockey");
			if (bot > 0)
			{
				SpawnInfected(bot, 5, true);
				new Float:Pos[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);	
				AcceptEntityInput(entity, "Kill");
				NormalizeVector(velocity, velocity);
				new Float:speed = GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				TeleportEntity(bot, Pos, NULL_VECTOR, velocity);
			}	
			return Plugin_Stop;
		}		
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public SkillFlameClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			IgniteEntity(target, 3.0);
			EmitSoundToAll("ambient/fire/gascan_ignite1.wav", target);
			ScreenFade(target, 100, 0, 0, 80, 200, 1);
		}
	}
}

public SkillIceClaw(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			SetEntityRenderMode(target, RenderMode:3);
			SetEntityRenderColor(target, 0, 100, 170, 180);
			SetEntityMoveType(target, MOVETYPE_VPHYSICS);
			CreateTimer(5.0, Timer_UnFreeze, target, TIMER_FLAG_NO_MAPCHANGE);
			EmitSoundToAll("ambient/ambience/rainscapes/rain/debris_05.wav", target);
			ScreenFade(target, 0, 0, 100, 80, 200, 1);
		}
	}
}

public SkillFlameGush(target)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 3)
		{
			decl Float:pos[3];
			GetClientAbsOrigin(target, pos);
			new entity = CreateEntityByName("prop_physics");
			if (IsValidEntity(entity))
			{
				pos[2] += 10.0;
				DispatchKeyValue(entity, "model", "models/props_junk/gascan001a.mdl");
				DispatchSpawn(entity);
				SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(entity, "break");
			}
		}
	}
}
public Action:MeteorTankTimer(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client))
	{
		new color = GetEntityRenderColor(client);
		if (color == 1002525)
		{
			new Float:Origin[3], Float:Angles[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			GetEntPropVector(client, Prop_Send, "m_angRotation", Angles);
			new ent[5];
			for (new count=1; count<=4; count++)
			{
				ent[count] = CreateEntityByName("prop_dynamic_override");
				if (IsValidEntity(ent[count]))
				{
					decl String:tName[64];
					Format(tName, sizeof(tName), "Tank%d", client);
					DispatchKeyValue(client, "targetname", tName);
					GetEntPropString(client, Prop_Data, "m_iName", tName, sizeof(tName));

					DispatchKeyValue(ent[count], "model", "models/props_debris/concrete_chunk01a.mdl");
					DispatchKeyValue(ent[count], "targetname", "RockEntity");
					DispatchKeyValue(ent[count], "parentname", tName);
					DispatchKeyValueVector(ent[count], "origin", Origin);
					DispatchKeyValueVector(ent[count], "angles", Angles);
					DispatchSpawn(ent[count]);
					SetVariantString(tName);
					AcceptEntityInput(ent[count], "SetParent", ent[count], ent[count]);
					switch(count)
					{
						case 1:SetVariantString("relbow");
						case 2:SetVariantString("lelbow");
						case 3:SetVariantString("rshoulder");
						case 4:SetVariantString("lshoulder");
					}
					AcceptEntityInput(ent[count], "SetParentAttachment");
					AcceptEntityInput(ent[count], "Enable");
					AcceptEntityInput(ent[count], "DisableCollision");
					switch(count)
					{
						case 1,2:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.4);
						case 3,4:SetEntPropFloat(ent[count], Prop_Data, "m_flModelScale", 0.5);
					}
					SetEntProp(ent[count], Prop_Send, "m_hOwnerEntity", client);
					Angles[0] = Angles[0] + GetRandomFloat(-90.0, 90.0);
					Angles[1] = Angles[1] + GetRandomFloat(-90.0, 90.0);
					Angles[2] = Angles[2] + GetRandomFloat(-90.0, 90.0);
					TeleportEntity(ent[count], NULL_VECTOR, Angles, NULL_VECTOR);
				}
			}
		}
	}
}
public Action:BlurEffect(Handle:timer, any:client)
{
	if (client > 0 && IsTank(client) && TankAbility[client] == 1)
	{
		new Float:TankPos[3], Float:TankAng[3];
		GetClientAbsOrigin(client, TankPos);
		GetClientAbsAngles(client, TankAng);
		new Anim = GetEntProp(client, Prop_Send, "m_nSequence");
		new entity = CreateEntityByName("prop_dynamic");
		if (IsValidEntity(entity))
		{
			DispatchKeyValue(entity, "model", "models/infected/hulk.mdl");
			DispatchKeyValue(entity, "solid", "6");
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "DisableCollision");
			SetEntityRenderColor(entity, 0, 105, 255, 255);
			SetEntProp(entity, Prop_Send, "m_nSequence", Anim);
			SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 15.0);
			TeleportEntity(entity, TankPos, TankAng, NULL_VECTOR);
			CreateTimer(0.3, RemoveBlurEffect, entity, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}		
	}
	return Plugin_Stop;
}
public Action:RemoveBlurEffect(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "prop_dynamic"))
		{
			decl String:model[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
			if (StrEqual(model, "models/infected/hulk.mdl"))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}	
	}
}
public SkillSmashClaw(target)
{
	new health = GetEntProp(target, Prop_Data, "m_iHealth");
	if (health > 1 && !IsPlayerIncap(target))
	{
		SetEntProp(target, Prop_Data, "m_iHealth", 1);
		SetEntPropFloat(target, Prop_Send, "m_healthBuffer", float(health));
	}
	EmitSoundToAll("player/charger/hit/charger_smash_02.wav", target);
	ScreenFade(target, 100, 50, 50, 80, 200, 1);
	ScreenShake(target, 30.0);
}
public SkillSmashClawKill(client, attacker)
{
	EmitSoundToAll("player/tank/voice/growl/tank_climb_01.wav", attacker);
	AttachParticle(client, PARTICLE_EXPLODE, 0.1, 0.0);
	DealDamagePlayer(client, attacker, 2, 300);
	DealDamagePlayer(client, attacker, 2, 300);
	CreateTimer(0.1, RemoveDeathBody, client, TIMER_FLAG_NO_MAPCHANGE);
}
public Action:RemoveDeathBody(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			decl String:classname[32];
			new entitycount = GetMaxEntities();
			for (new e=1; e<=entitycount; e++)
			{
				if (IsValidEntity(e))
				{
					GetEdictClassname(e, classname, sizeof(classname));
					if (StrEqual(classname, "survivor_death_model"))
					{
						new ownerent = GetEntProp(e, Prop_Send, "m_hOwnerEntity");
						if (client == ownerent)
						{
							AcceptEntityInput(e, "Kill");
						}
					}
				}
			}
		}
	}
}
public SkillElecClaw(target, tank)
{
	if (target > 0)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) == 2)
		{
			PlayerSpeed75[target] += 3;
			new Handle:Pack = CreateDataPack();
			WritePackCell(Pack, target);
			WritePackCell(Pack, tank);
			WritePackCell(Pack, 4);
			CreateTimer(5.0, Timer_Volt, Pack, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			ScreenFade(target, 100, 100, 0, 80, 200, 1);
			ScreenShake(target, 15.0);
			AttachParticle(target, PARTICLE_ELEC, 2.0, 30.0);
			EmitSoundToAll("ambient/energy/zap1.wav", target);
		}
	}
}
public Action:Timer_Volt(Handle:timer, any:Pack)
{
	ResetPack(Pack, false);
	new client = ReadPackCell(Pack);
	new tank = ReadPackCell(Pack);
	new amount = ReadPackCell(Pack);

	if (client > 0 && tank > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2 && PlayerSpeed75[client] == 0 && IsTank(tank))
		{
			if (amount > 0)
			{
				PlayerSpeed75[client] += 2;
				ScreenShake(client, 2.0);
				DealDamagePlayer(client, tank, 2, 12);
				AttachParticle(client, PARTICLE_ELEC, 2.0, 30.0);
				new random = GetRandomInt(1,2);
				if (random == 1) 
				{
					EmitSoundToAll("ambient/energy/zap5.wav", client);
				}
				else
				{
					EmitSoundToAll("ambient/energy/zap7.wav", client);
				}
				ResetPack(Pack, true);
				WritePackCell(Pack, client);
				WritePackCell(Pack, tank);
				WritePackCell(Pack, amount - 1);
				return Plugin_Continue;
			}
		}
	}
	CloseHandle(Pack);
	return Plugin_Stop;
}
StartMeteorFall(client)
{
	TankAbility[client] = 1;
	decl Float:pos[3];
	GetClientEyePosition(client, pos);
	
	new Handle:h=CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h, pos[0]);
	WritePackFloat(h, pos[1]);
	WritePackFloat(h, pos[2]);
	WritePackFloat(h, GetEngineTime());
	
	CreateTimer(0.6, UpdateMeteorFall, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:UpdateMeteorFall(Handle:timer, any:h)
{
	ResetPack(h);
	decl Float:pos[3];
	new client = ReadPackCell(h);
 	
	pos[0] = ReadPackFloat(h);
	pos[1] = ReadPackFloat(h);
	pos[2] = ReadPackFloat(h);

	new Float:time = ReadPackFloat(h);
	if ((GetEngineTime() - time) > 5.0)
	{
		TankAbility[client] = 0;
	}
	new entitycount = GetMaxEntities();
	if (IsTank(client) && TankAbility[client] == 1)
	{
		decl Float:angle[3], Float:velocity[3], Float:hitpos[3];
		angle[0] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[1] = 0.0 + GetRandomFloat(-20.0, 20.0);
		angle[2] = 60.0;
		
		GetVectorAngles(angle, angle);
		GetRayHitPos(pos, angle, hitpos, client, true);
		new Float:dis = GetVectorDistance(pos, hitpos);
		if (GetVectorDistance(pos, hitpos) > 2000.0)
		{
			dis = 1600.0;
		}
		decl Float:t[3];
		MakeVectorFromPoints(pos, hitpos, t);
		NormalizeVector(t,t);
		ScaleVector(t, dis - 40.0);
		AddVectors(pos, t, hitpos);
		
		if (dis > 100.0)
		{
			new ent = CreateEntityByName("tank_rock");
			if (ent > 0)
			{
				DispatchKeyValue(ent, "model", "models/props_debris/concrete_chunk01a.mdl"); 
				DispatchSpawn(ent);  
				decl Float:angle2[3];
				angle2[0] = GetRandomFloat(-180.0, 180.0);
				angle2[1] = GetRandomFloat(-180.0, 180.0);
				angle2[2] = GetRandomFloat(-180.0, 180.0);

				velocity[0] = GetRandomFloat(0.0, 350.0);
				velocity[1] = GetRandomFloat(0.0, 350.0);
				velocity[2] = GetRandomFloat(0.0, 30.0);

				TeleportEntity(ent, hitpos, angle2, velocity);
				ActivateEntity(ent);
	 
				AcceptEntityInput(ent, "Ignite");
				SetEntProp(ent, Prop_Send, "m_hOwnerEntity", client);
			}
		} 
	}
	else if (TankAbility[client] == 0)
	{
		for (new e=1; e<=entitycount; e++)
		{
			if (IsRock(e))
			{
				new ownerent = GetEntProp(e, Prop_Send, "m_hOwnerEntity");
				if (client == ownerent)
				{
					ExplodeMeteor(e, ownerent);
				}
			}
		}
		CloseHandle(h);
		return Plugin_Stop;
	}
	for (new e=1; e<=entitycount; e++)
	{
		if (IsRock(e))
		{
			new ownerent = GetEntProp(e, Prop_Send, "m_hOwnerEntity");
			if (client == ownerent)
			{
				if (OnGroundUnits(e) < 200.0)
				{
					ExplodeMeteor(e, ownerent);
				}
			}
		}
	}
	return Plugin_Continue;	
}
bool:IsRock(entity)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		decl String:classname[20];
		GetEdictClassname(entity, classname, 20);
		if (StrEqual(classname, "tank_rock", true))
		{
			return true;
		}
	}
	return false;
}
public Float:OnGroundUnits(i_Ent)
{
	if (!(GetEntityFlags(i_Ent) & (FL_ONGROUND)))
	{ 
		decl Handle:h_Trace, Float:f_Origin[3], Float:f_Position[3], Float:f_Down[3] = { 90.0, 0.0, 0.0 };
		
		GetEntPropVector(i_Ent, Prop_Send, "m_vecOrigin", f_Origin);
		h_Trace = TR_TraceRayFilterEx(f_Origin, f_Down, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceRayDontHitSelfAndLive, i_Ent);

		if (TR_DidHit(h_Trace))
		{
			decl Float:f_Units;
			TR_GetEndPosition(f_Position, h_Trace);
			
			f_Units = f_Origin[2] - f_Position[2];

			CloseHandle(h_Trace);
			
			return f_Units;
		}
		CloseHandle(h_Trace);
	} 
	
	return 0.0;
}
GetRayHitPos(Float:pos[3], Float:angle[3], Float:hitpos[3], ent=0, bool:useoffset=false)
{
	new Handle:trace;
	new hit=0;
	
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	
	if (useoffset)
	{
		decl Float:v[3];
		MakeVectorFromPoints(hitpos, pos, v);
		NormalizeVector(v, v);
		ScaleVector(v, 15.0);
		AddVectors(hitpos, v, hitpos);
	}
	return hit;
}
ExplodeMeteor(entity, client)
{
	if (IsValidEntity(entity))
	{
		decl String:classname[20];
		GetEdictClassname(entity, classname, 20);
		if (!StrEqual(classname, "tank_rock", true))
		{
			return;
		}

		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);	
		pos[2]+=50.0;
		AcceptEntityInput(entity, "Kill");
	
		new ent = CreateEntityByName("prop_physics"); 		
		DispatchKeyValue(ent, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent); 
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Break");

		new pointHurt = CreateEntityByName("point_hurt");   
		DispatchKeyValue(pointHurt, "Damage", "40");        
		DispatchKeyValue(pointHurt, "DamageType", "2");  
		DispatchKeyValue(pointHurt, "DamageDelay", "0.0");
		DispatchKeyValueFloat(pointHurt, "DamageRadius", 200.0);  
		DispatchSpawn(pointHurt);
		TeleportEntity(pointHurt, pos, NULL_VECTOR, NULL_VECTOR);  
		AcceptEntityInput(pointHurt, "Hurt", client);    
		CreateTimer(0.1, DeletePointHurt, pointHurt, TIMER_FLAG_NO_MAPCHANGE); 
		
		new push = CreateEntityByName("point_push");         
  		DispatchKeyValueFloat (push, "magnitude", 600.0);                     
		DispatchKeyValueFloat (push, "radius", 200.0*1.0);                     
  		SetVariantString("spawnflags 24");                     
		AcceptEntityInput(push, "AddOutput");
 		DispatchSpawn(push);   
		TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 		AcceptEntityInput(push, "Enable", -1, -1);
		CreateTimer(0.5, DeletePushForce, push, TIMER_FLAG_NO_MAPCHANGE);
	}
} 
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
	 	decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_push", false))
		{
			AcceptEntityInput(ent, "Kill"); 
		}
	 }
}
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		decl String:classname[64];
		GetEdictClassname(ent, classname, sizeof(classname));
		if (StrEqual(classname, "point_hurt", false))
		{
			AcceptEntityInput(ent, "Kill"); 
		}
	 }
}
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if (entity == data) 
	{
		return false; 
	}
	else if (entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}
public Action:Timer_Wave2(Handle:timer)
{
	CountTanks();
	if (ad_numtanks == 0)
	{
		ad_wave = 2;
	}
}
public Action:Timer_Wave3(Handle:timer)
{
	CountTanks();
	if (ad_numtanks == 0)
	{
		ad_wave = 3;
	}
}
public Action:SpawnTankTimer(Handle:timer)
{
	if (ad_wave == 1)
	{
		if (ad_numtanks < GetConVarInt(wave1cvar))
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (ad_wave == 2)
	{
		if (ad_numtanks < GetConVarInt(wave2cvar))
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
	else if (ad_wave == 3)
	{
		if (ad_numtanks < GetConVarInt(wave3cvar))
		{
			new bot = CreateFakeClient("Tank");
			if (bot > 0)
			{
				SpawnInfected(bot, 8, true);
			}
		}
	}
}
public Action:Timer_UnFreeze(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			SetEntityRenderMode(client, RenderMode:3);
			SetEntityRenderColor(client, 255, 255, 255, 255);
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
	}
}
public Action:Timer_ActivateShield(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsTank(client))
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 3);
			SetEntProp(client, Prop_Send, "m_bFlashing", 2);
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 075075255255);
		}
	}
}
public Action:Timer_ResetGravity(Handle:timer, any:client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			SetEntityGravity(client, 1.0);
		}
	}
}
public Action:Timer_AttachSPAWN(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 303030)
	{
		AttachParticle(client, PARTICLE_SPAWN, 1.2, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachFIRE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12800)
	{
		AttachParticle(client, PARTICLE_FIRE, 0.8, 0.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachFIRE_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			IgniteEntity(entity, 100.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachICE(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 0100170)
	{
		AttachParticle(client, PARTICLE_ICE, 2.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_SpitSound(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		EmitSoundToAll("player/spitter/voice/warn/spitter_spit_02.wav", client);
	}
}
public Action:Timer_AttachSPIT(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 12115128)
	{
		AttachParticle(client, PARTICLE_SPIT, 2.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachSPIT_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			AttachParticle(entity, PARTICLE_SPITPROJ, 0.8, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 100165255)
	{
		AttachParticle(client, PARTICLE_ELEC, 0.8, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachELEC_Rock(Handle:timer, any:entity)
{
	if (IsValidEntity(entity))
	{
		decl String: classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "tank_rock"))
		{
			AttachParticle(entity, PARTICLE_ELEC, 0.8, 0.0);
			return Plugin_Continue;
		}
	}
	return Plugin_Stop;
}
public Action:Timer_AttachBLOOD(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 255200255)
	{
		AttachParticle(client, PARTICLE_BLOOD, 0.8, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
public Action:Timer_AttachMETEOR(Handle:timer, any:client)
{
	if (IsTank(client) && GetEntityRenderColor(client) == 1002525)
	{
		AttachParticle(client, PARTICLE_METEOR, 6.0, 30.0);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}
stock TeleportTank(client)
{
	new random = GetRandomInt(1,20);
	if (random == 20)
	{
		new target = Pick();
		if (target)
		{
			new Float:Origin[3], Float:Angles[3];
			GetClientAbsOrigin(target, Origin);
                        GetClientAbsAngles(target, Angles);
			CreateParticle(client, PARTICLE_WARP, 1.0, 0.0);
			TeleportEntity(client, Origin, Angles, NULL_VECTOR);
		}
	}
}
stock SpawnWitch(client)
{
	new count;
	decl String: classname[32];
	new entitycount = GetMaxEntities();
	for (new j=1; j<=entitycount; j++)
	{
		if (IsValidEdict(j) && IsValidEntity(j) && count < 4)
		{
			GetEdictClassname(j, classname, sizeof(classname));
			if (StrEqual(classname, "infected"))
			{
				decl Float:TankPos[3], Float:InfectedPos[3], Float:InfectedAng[3];
                        	GetClientAbsOrigin(client, TankPos);
				GetEntPropVector(j, Prop_Send, "m_vecOrigin", InfectedPos);
				GetEntPropVector(j, Prop_Send, "m_angRotation", InfectedAng);
				new Float:distance = GetVectorDistance(InfectedPos, TankPos);
                        	if (distance < 100.0)
				{
					AcceptEntityInput(j, "Kill");
					new witch = CreateEntityByName("witch");
					DispatchSpawn(witch);
					ActivateEntity(witch);
					TeleportEntity(witch, InfectedPos, InfectedAng, NULL_VECTOR);
					SetEntProp(witch, Prop_Send, "m_glowColorOverride", 1);
					count++;
				}
			}
		}
	}					
}
stock CountTankRange(client)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsTank(i) && i != client)
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				count++;
			}
		}
	}
	return count;
}
stock HealTank(client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsTank(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				new health = GetClientHealth(client);
				if (health <= (GetConVarInt(FindConVar("z_tank_health")) - 200) && health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", health + 100);
				}
			}
		}
		else if (IsTank(i) && i != client)
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				new health = GetClientHealth(client);
				if (health <= (GetConVarInt(FindConVar("z_tank_health")) - 2000) && health > 500)
				{
					SetEntProp(client, Prop_Data, "m_iHealth", health + 1000);
				}
			}
		}
	}
	decl String: classname[32];
	new entitycount = GetMaxEntities();
	for (new entity=1; entity<=entitycount; entity++)
	{
		if (IsValidEdict(entity))
		{
			GetEdictClassname(entity, classname, sizeof(classname));
			if (StrEqual(classname, "infected"))
			{
				decl Float:TankPos[3], Float:InfectedPos[3];
               	 		GetClientAbsOrigin(client, TankPos);
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", InfectedPos);
				new Float:distance = GetVectorDistance(InfectedPos, TankPos);
                		if (distance < 500)
				{
					new health = GetClientHealth(client);
					if (health <= (GetConVarInt(FindConVar("z_tank_health")) - 50) && health > 500)
					{
						SetEntProp(client, Prop_Data, "m_iHealth", health + 10);
					}
				}
			}
		}
	}
}
stock InfectedCloak(client)
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3 && !IsTank(i))
		{
			decl Float:TankPos[3], Float:InfectedPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, InfectedPos);
                       	new Float:distance = GetVectorDistance(TankPos, InfectedPos);
                        if (distance < 500)
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 50);
			}
			else
			{
				SetEntityRenderMode(i, RenderMode:3);
      	 			SetEntityRenderColor(i, 255, 255, 255, 255);
			}
		}
	}
}
stock CountSurvRange(client)
{
	new count = 0;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			decl Float:TankPos[3], Float:PlayerPos[3];
                        GetClientAbsOrigin(client, TankPos);
                        GetClientAbsOrigin(i, PlayerPos);
                       	new Float:distance = GetVectorDistance(TankPos, PlayerPos);
                        if (distance > 120)
			{
				count++;
			}
		}
	}
	return count;
}
stock GetEntityRenderColor(entity)
{
	if (entity > 0)
	{
		new offset = GetEntSendPropOffs(entity, "m_clrRender");
		new r = GetEntData(entity, offset, 1);
		new g = GetEntData(entity, offset+1, 1);
		new b = GetEntData(entity, offset+2, 1);
		decl String:rgb[10];
		Format(rgb, sizeof(rgb), "%d%d%d", r, g, b);
		new color = StringToInt(rgb);
		return color;
	}
	return 0;	
}
stock RGB_TO_INT(red, green, blue) 
{
	return (blue * 65536) + (green * 256) + red;
}
public Action:OnSurvivorTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetConVarInt(supertanksoncvar) == 1)
	{
		if (damage > 0.0 && victim > 0 && victim < 33 && IsClientInGame(victim) && GetClientTeam(victim) == 2)
		{
			if (IsWitch(attacker))
			{
				if (GetEntProp(attacker, Prop_Send, "m_glowColorOverride") == 1)
				{
					damage = 16.0;
				}
			}
			else if (attacker > 0 && attacker < 33 && IsTank(attacker) && damagetype != 2)
			{
				new color = GetEntityRenderColor(attacker);
				//Ice Tank
				if (color == 0100170)
				{
					new flags = GetEntityFlags(victim);
					if (flags & FL_ONGROUND)
					{
						new random = GetRandomInt(1,3);
						if (random == 1)
						{
							SkillIceClaw(victim);
						}
					}
				}
			}
		}
	}
	return Plugin_Changed;
}
stock DealDamagePlayer(target, attacker, dmgtype, dmg)
{
	if (target > 0 && target < 33)
	{
		if (IsClientInGame(target) && IsPlayerAlive(target))
		{
   	 		decl String:damage[16];
    			IntToString(dmg, damage, 16);
   	 		decl String:type[16];
    			IntToString(dmgtype, type, 16);
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", attacker);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}
stock DealDamageEntity(target, attacker, dmgtype, dmg)
{
	if (target > 32)
	{
		if (IsValidEntity(target))
		{
   	 		decl String:damage[16];
    			IntToString(dmg, damage, 16);
   	 		decl String:type[16];
    			IntToString(dmgtype, type, 16);
			new pointHurt = CreateEntityByName("point_hurt");
			if (pointHurt)
			{
				DispatchKeyValue(target, "targetname", "hurtme");
				DispatchKeyValue(pointHurt, "Damage", damage);
				DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");
				DispatchKeyValue(pointHurt, "DamageType", type);
				DispatchSpawn(pointHurt);
				AcceptEntityInput(pointHurt, "Hurt", attacker);
				AcceptEntityInput(pointHurt, "Kill");
				DispatchKeyValue(target, "targetname", "donthurtme");
			}
		}
	}
}
stock ForceWeaponDrop(client)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	new String:weapon[32];
	GetClientWeapon(client, weapon, 32);

	if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_hunting_rifle") || StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5") || StrEqual(weapon, "weapon_shotgun_spas") || StrEqual(weapon, "weapon_shotgun_chrome") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47") || StrEqual(weapon, "weapon_grenade_launcher") || StrEqual(weapon, "weapon_rifle_m60"))
		DropSlot(client, 0);
	else if (StrEqual(weapon, "weapon_pistol") || StrEqual(weapon, "weapon_pistol_magnum") || StrEqual(weapon, "weapon_chainsaw") || StrEqual(weapon, "weapon_melee"))
		DropSlot(client, 1);
	else if (StrEqual(weapon, "weapon_pipe_bomb") || StrEqual(weapon, "weapon_molotov") || StrEqual(weapon, "weapon_vomitjar"))
		DropSlot(client, 2);
	else if (StrEqual(weapon, "weapon_first_aid_kit") || StrEqual(weapon, "weapon_defibrillator") || StrEqual(weapon, "weapon_upgradepack_explosive") || StrEqual(weapon, "weapon_upgradepack_incendiary"))
		DropSlot(client, 3);
	else if (StrEqual(weapon, "weapon_pain_pills") || StrEqual(weapon, "weapon_adrenaline"))
		DropSlot(client, 4);
}
public DropSlot(client, slot)
{
	if (GetPlayerWeaponSlot(client, slot) > 0)
	{
		new weapon = GetPlayerWeaponSlot(client, slot);
		SDKCallWeaponDrop(weapon, client);
	}
}
stock ResetInfectedAbility(client, Float:time)
{
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
		{
			new ability = GetEntPropEnt(client, Prop_Send, "m_customAbility");
			if (ability > 0)
			{
				SetEntPropFloat(ability, Prop_Send, "m_duration", time);
				SetEntPropFloat(ability, Prop_Send, "m_timestamp", GetGameTime() + time);
			}
		}
	}
}
stock GetNearestSurvivorDist(client)
{
    	new Float:PlayerPos[3], Float:TargetPos[3], Float:nearest = 0.0, Float:distance = 0.0;
	if (client > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetClientAbsOrigin(client, PlayerPos);
   			for (new i=1; i<=MaxClients; i++)
    			{
        			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					GetClientAbsOrigin(i, TargetPos);
                        		distance = GetVectorDistance(PlayerPos, TargetPos);
                        		if (nearest == 0.0)
					{
						nearest = distance;
					}
					else if (nearest > distance)
					{
						nearest = distance;
					}
				}
			}
		} 
    	}
    	return RoundFloat(distance);
}
//=============================
// COMMANDS
//=============================
stock CheatCommand(client, const String:command[], const String:arguments[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments );
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
stock DirectorCommand(client, String:command[])
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", command);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}
//=============================
// GAMEFRAME
//=============================
public OnGameFrame()
{
	if (!IsServerProcessing()) return;

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		frame++;
		if (frame >= 3)
		{
			for (new i=1; i<=MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
				{
					SpeedRebuild(i);
				}
			}
			frame = 0;
		}
	}
}
//=============================
// TIMER 0.1
//=============================
public Action:TimerUpdate01(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (GetConVarInt(supertanksoncvar) == 1 && GetConVarInt(displayhealthcvar) == 1)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				if (!IsFakeClient(i))
				{
					new entity = GetClientAimTarget(i, false);
					if (IsValidEntity(entity))
					{
						new String:classname[32];
						GetEdictClassname(entity, classname, sizeof(classname));
						if (StrEqual(classname, "player", false))
						{
							if (entity > 0)
							{
								if (IsTank(entity))
								{
									new health = GetClientHealth(entity);
									PrintHintText(i, "%N (%d HP)", entity, health);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}
//=============================
// TIMER 1.0
//=============================
public Action:TimerUpdate1(Handle:timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;

	if (GetConVarInt(supertanksoncvar) == 1)
	{
		TankController();
		SetConVarInt(FindConVar("z_max_player_zombies"), 32);
		for (new i=1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == 2)
				{
					if (PlayerSpeed75[i] > 0)
					{
						PlayerSpeed75[i] -= 1;
					}
				}
				else if (GetClientTeam(i) == 3)
				{
					if (IsFakeClient(i))
					{
						new zombie = GetEntData(i, FindSendPropInfo("CTerrorPlayer", "m_zombieClass"));
						if (zombie == 8)
						{
							CreateTimer(3.0, TankLifeCheck, i, TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}