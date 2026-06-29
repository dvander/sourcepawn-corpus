/*
Initial planning:
Simple weapon upgrade
Sequence: charge spray rifle sniper melee
Upgrading experience acquisition or number of killing sensations
Optional: attack to cure self

Optional Advancement: Automatic Weapons (?
Maybe database (?
Limited ability, many function I can't achieve just by myself
*/

/**************
		SUMMARY
	This plugin want to achieve some functions.
	first, weapon upgrade, the more you kill, the better weapon you will take.
	And, we need definite level to upgrade our weapon, before that we just could gain some special ability(such as attack to cure self, critical, strick faster etc...
	this plugin is potential, we maybe can make it connect to the database and more functions.
	automatic_machine also in my consideration.......
	
	this plugin's idea come from some Single_play CS version and I the weapon_upgrade_mode in it.
	I want achieve it in L4D2 ( maybe better in CSGO XD...
**************/
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name="weapon upgrade mode",
	author="NiceT",
	description="weapon upgrade mode",
	version="PLUGIN_VERSION",
	url=""
};

const WEP_SLOT_PRIMARY = 0;
const WEP_SLOT_MELEE = 1;

#define TEAM_SPECTATORS 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define CLASS_TANK		8
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD
#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)	(1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1))
	
new Lv[MAXPLAYERS+1];
#define Lv_limit 428;	// 25 kinds weapon per weapon upgrade 20 times to change next weapon  if level more than 15*20=300 (melee) upgrade 16 times to change weapon total 428 level
new WeaponLv[MAXPLAYERS+1] = 0;
new EXP[MAXPLAYERS+1];
new CRT[MAXPLAYERS+1];	//Critical chance
new Handle:CRTDmg;
//#define CRT_limit 40;		//	increase 2 per level
new FireSpeedLv[MAXPLAYERS+1];	//increase fire speed
new WRQ[MAXPLAYERS+1];
new WRQL;
new Float:Multi[MAXPLAYERS+1];
#define FireSpeedEffect[%1]	0.9*FireSpeedLv[%1]
//#define FireSpeedLv_limit 20	// increase 1 per level
new MeleeSpeedLv[MAXPLAYERS+1];	//increase melee fire speed
//#define MeleeSpeedLv_limit 16

new String:WeaponClass[25][32] = {"weapon_smg", "weapon_smg_silenced", "weapon_smg_mp5", 
								"weapon_pumpshotgun", "weapon_shotgun_chrome", "weapon_shotgun_spas", "weapon_autoshotgun",
								"weapon_rifle", "weapon_refle_desert", "weapon_rifle_ak47", "weapon_rifle_sg552",
								"weapon_hunting_rifle", "weapon_sniper_scout", "weapon_sniper_military", "weapon_sniper_awp",
								"weapon_grenade_launcher",
								"frying_pan", "baseball_bat", "cricket_bat", "tonfa", "crowbar", "electric_guitar", "katana", "fireaxe", "machete"}

new Handle:JockeyKilledExp;
new Handle:HunterKilledExp;
new Handle:ChargerKilledExp;
new Handle:SmokerKilledExp;
new Handle:SpitterKilledExp;
new Handle:BoomerKilledExp;
new Handle:TankKilledExp;
new Handle:WitchKilledExp;

new Handle:LvUpExpRate;
new Handle:TimerUpgrade[MAXPLAYERS+1]				=	{	INVALID_HANDLE, ...};
new Handle:CheckExpTimer[MAXPLAYERS+1]				= {	INVALID_HANDLE, ...};

public OnPluginStart()
{
	decl String:ModName[64];
	GetGameFolderName(ModName, sizeof(ModName));
	
	if(!StrEqual(ModName, "left4dead2", false)) 
	{ 
		SetFailState("Use this in Left 4 Dead (2) only.");
	}
	
	CreateConVar("Weapon_Upgrade_Version", PLUGIN_VERSION, "plugin_version", CVAR_FLAGS);
	
	RegisterCvars();
	//RegisterCmds();
	HookEvents();
}

RegisterCvars()
{
	CRTDmg							= CreateConVar("More_Damage_CRT", 					"1.0",  "Extra multiple of critical strike",				 CVAR_FLAGS, true, 0.0);
	
	JockeyKilledExp					= CreateConVar("GainExp_Kill_Jockey",				"200",	"kill Jockey gain exp", CVAR_FLAGS, true, 0.0);
	HunterKilledExp					= CreateConVar("GainExp_Kill_hunter",				"250",	"Hunter", CVAR_FLAGS, true, 0.0);
	ChargerKilledExp				= CreateConVar("GainExp_Kill_Charger",				"250",	"Charger", CVAR_FLAGS, true, 0.0);
	SmokerKilledExp					= CreateConVar("GainExp_Kill_Smoker",				"200",	"Smoker", CVAR_FLAGS, true, 0.0);
	SpitterKilledExp				= CreateConVar("GainExp_Kill_Spitter",				"200",	"Spitter", CVAR_FLAGS, true, 0.0);
	BoomerKilledExp					= CreateConVar("GainExp_Kill_Boomer",				"150",	"Boomer", CVAR_FLAGS, true, 0.0);
	TankKilledExp					= CreateConVar("GainExp_Kill_Tank",					"0.3",	"gain exp per damage to tank", CVAR_FLAGS, true, 0.0);
	WitchKilledExp					= CreateConVar("GainExp_Kill_Witch",				"5000",	"kill Witch", CVAR_FLAGS, true, 0.0);

	LvUpExpRate	= CreateConVar("rpg_LvUp_Exp_Rate",	"2000",	"coefficient: upgrade_need_exp = coefficient*(now_level+1)", CVAR_FLAGS, true, 1.0);
}

HookEvents()
{
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("player_hurt",	Event_PlayerHurt);
	HookEvent("witch_killed",	Event_WitchKilled);
}

public OnMapStart()
{
	for(new client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client)&& !IsFakeClient(client) && IsValidClient(client))
		{
			CheckExpTimer[client] = CreateTimer(1.0, PlayerLevelUp, client, TIMER_REPEAT);
			//SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
		}
	}
}

public OnClientConnected(client)
{
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		Lv[client] = 1;
		EXP[client] = 0;
		CRT[client] = 0;
		FireSpeedLv[client] = 0;
		MeleeSpeedLv[client] = 0;
		CheckExpTimer[client] = CreateTimer(1.0, PlayerLevelUp, client, TIMER_REPEAT);
		//SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	decl String:WeaponUsed[256];
	GetEventString(event, "weapon", WeaponUsed, sizeof(WeaponUsed));
	
	if(IsValidClient(victim))
	{
		if(GetClientTeam(victim) == TEAM_INFECTED)
		{
			new iClass = GetEntProp(victim, Prop_Send, "m_zombieClass");
			
			if(IsValidClient(attacker))
			{
				if(GetClientTeam(attacker) == TEAM_SURVIVORS)	
				{
					if(!IsFakeClient(attacker))
					{
						switch (iClass)
						{
						case 1: //smoker
							{
								new EXPGain = GetConVarInt(SmokerKilledExp);
								EXP[attacker] += EXPGain;
							}
						case 2: //boomer
							{
								new EXPGain = GetConVarInt(BoomerKilledExp);
								EXP[attacker] += EXPGain;
							}
						case 3: //hunter
							{
								new EXPGain = GetConVarInt(HunterKilledExp);
								EXP[attacker] += EXPGain;
							}
						case 4: //spitter
							{
								new EXPGain = GetConVarInt(SpitterKilledExp);
								EXP[attacker] += EXPGain;
							}
						case 5: //jackey
							{
								new EXPGain = GetConVarInt(JockeyKilledExp);
								EXP[attacker] += EXPGain;
							}
						case 6: //charger
							{
								new EXPGain = GetConVarInt(ChargerKilledExp);
								EXP[attacker] += EXPGain;
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_WitchKilled(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(killer))
	{
		if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
		{
			EXP[killer] += GetConVarInt(WitchKilledExp);
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg = GetEventInt(event, "dmg_health");
	new CRTchance = GetRandomInt(0, 100);
	new Float:ADDdmg = 0.0;
	
	if (IsValidClient(attacker))
	{
		if(!IsFakeClient(attacker))
		{
			if (IsValidClient(victim))
			{
				if(GetEntProp(victim, Prop_Send, "m_zombieClass") == CLASS_TANK)
				{
					if(CRTchance <= CRT[attacker])
						ADDdmg = GetConVarFloat(CRTDmg)*dmg;
					SetEventInt(event, "dmg_health", RoundToNearest(dmg + ADDdmg));
					EXP[attacker] += (dmg+ADDdmg)*GetConVarInt(TankKilledExp);
				}
			}
		}
	}
	return Plugin_Changed;
}

public Action:PlayerLevelUp(Handle:timer, any:target)
{
	if(IsClientInGame(target))
	{
		if(EXP[target] >= GetConVarInt(LvUpExpRate)*(Lv[target]+1))
		{
			
			Lv[target] += 1;
			EXP[target] -= GetConVarInt(LvUpExpRate)*(Lv[target]+1);
			CRT[target] += 2;
			if(WeaponLv[target] < 14)	//gun
			{
				FireSpeedLv[target] += 1;
				if(Lv[target] > 20+WeaponLv[target]*20) 
				{
					WeaponLv[target] += 1;
					EXP[target] = 0;
					CRT[target] = 0;
					FireSpeedLv[target] = 0;
				}
			}
			else		// melee
			{
				MeleeSpeedLv[target] += 1;
				if(Lv[target] > 320+(WeaponLv[target]-15)*16)
				{
					WeaponLv[target] += 1;
					EXP[target] = 0;
					CRT[target] = 0;
					MeleeSpeedLv[target] = 0;
				}
			}
			//RemoveWeapon(target);			// remove weapon
			GiveWeapon(target, WeaponLv[target]);	// give you Corresponding grade's weapon
			if(FireSpeedLv[target] > 0 || MeleeSpeedLv[target] > 0)
				SetWeaponSpeed();
		}
		else
		{
			PrintHintText(target, "Level Limited!!!");
		}
	}
	return Plugin_Changed;
}

RemoveWeapon(client)
{
	RemoveItemFromSlot(client, WEP_SLOT_PRIMARY);
	RemoveItemFromSlot(client, WEP_SLOT_MELEE);	
}

stock RemoveItemFromSlot(client, slot)
{
	new ent = GetPlayerWeaponSlot(client, slot);
	if( ent != -1 )
	{
		RemovePlayerItem(client, ent);
	}
}

GiveWeapon(client, lv)
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	new String:weapon = WeaponClass[lv];
	FakeClientCommand(client, "give %s", weapon);
}
/*							
									//In this function I need limit player just use their corresponding grade's weapon
public Action:OnWeaponCanUse(client, weapon)
{
	new String:Weapon[32] = WeaponClass[Lv[client]];
	
	
	
	
	
	
	
	
	
}
*/
/*****************************			//I think I can't change weapon's firespeed in plugin, so I copy some RPG's code but I'm no sure it works
									//***********************************************************************************************
									//****Below this line I want implementing certain functions to increase weapon's fire speed******
									//***********************************************************************************************
SetWeaponSpeed()
{
	decl ent;

	for(new i = 0; i < WRQL; i++)
	{
		ent = WRQ[i];
		if(IsValidEdict(ent))
		{
			decl String:entclass[65];
			GetEdictClassname(ent, entclass, sizeof(entclass));
			if(StrContains(entclass, "weapon")>=0)
			{
				new Float:MAS = Multi[i];
				SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", MAS);
				new Float:ETime = GetGameTime();
				new Float:time = (GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack") - ETime)/MAS;
				SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", time + ETime);
				time = (GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack") - ETime)/MAS;
				SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", time + ETime);
				CreateTimer(time, NormalWeapSpeed, ent);
			}
		}
	}
}
public Action:NormalWeapSpeed(Handle:timer, any:ent)
{
	KillTimer(timer);
	timer = INVALID_HANDLE;

	if(IsValidEdict(ent))
	{
		decl String:entclass[65];
		GetEdictClassname(ent, entclass, sizeof(entclass));
		if(StrContains(entclass, "weapon")>=0)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 1.0);
		}
	}
	return Plugin_Handled;
}
public Action:Event_WeaponFire(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		if(FireSpeedLv[target]>0)
		{
			new ent = GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
			decl String:entclass[65];
			GetEdictClassname(ent, entclass, sizeof(entclass));

			if(ent == GetPlayerWeaponSlot(target, 0) || (ent == GetPlayerWeaponSlot(target, 1) && StrContains(entclass, "melee")<0))
			{
				WRQ[WRQL] = ent;
				Multi[WRQL] = FireSpeedEffect[target];
				WRQL++;
			}
		}
	}
	return Plugin_Continue;
}
***********************************/
