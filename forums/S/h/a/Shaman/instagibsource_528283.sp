/*
instagibsource.sp
InstaGib: Source
This plugin is coded by Alican "AlicanC" Çubukçuoðlu (alicancubukcuoglu@gmail.com)
Copyright (C) 2007 Alican Çubukçuoðlu
*/
/*
Plugin Change Log (N: New, C: Changed, S: Same, R: Removed)

v0.0.2
Files included:
	N|gamedata/instagibsource.games.txt
	N|scripting/instagibsource.sp
Release Notes:
	None.
Changes:
	None.

v0.0.1
Files included:
	N|gamedata/instagibsource.games.txt
	N|scripting/instagibsource.sp
Release Notes:
	SStocks is needed to compile this plugin.
Changes:
	First release.
*/
/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sstocks>

//||||||||||||||||||||Plugin Information

new const String:PLUGIN_NAME[]= "InstaGib: Source";
new const String:PLUGIN_DESCRIPTION[]= "UT's InstaGib mod for CS: S.";
#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo=
	{
	name= PLUGIN_NAME,
	author= "Alican 'AlicanC' Çubukçuoðlu",
	description= PLUGIN_DESCRIPTION,
	version= PLUGIN_VERSION,
	url= "http://www.sourcemod.net/"
	}

//||||||||||||||||||||Constants and defines

new const String:Sound_RailgunFire[]= "instagibsource/railgf1a.wav";
new const String:Sound_RailgunFire_Long[]= "sound/instagibsource/railgf1a.wav";
new const String:Sound_PlayerDeath[]= "instagibsource/gibsplt1.wav";
new const String:Sound_PlayerDeath_Long[]= "sound/instagibsource/gibsplt1.wav";
#define BEAMMODELS 5

//||||||||||||||||||||Variables

new Handle:GameConfig;
new Handle:SDKC_RemoveAllItems;
new Handle:SDKC_Weapon_ShootPosition;
new String:InstaGibWeapon[16];
new String:InstaGibWeapon_Long[24];
new Cache_Beam[BEAMMODELS+1];

//||||||||||||||||||||Initialization

public OnPluginStart()
	{
	//Check modification
	if(!CheckMod("cstrike"))
		Fail(PLUGIN_NAME, "This plugin only works with Counter-Strike: Source.");
	//Check required gamedata file
	CheckRequiredFile("gamedata/instagibsource.games.txt", PLUGIN_NAME);
	
	//Default InstaGib weapon
	Format(InstaGibWeapon, sizeof(InstaGibWeapon), "awp");
	Format(InstaGibWeapon_Long, sizeof(InstaGibWeapon_Long), "weapon_%s", InstaGibWeapon);
	
	//Version ConVar
	CreateConVar("instagibsource_version", PLUGIN_VERSION, "InstaGib: Source Version", FCVAR_PLUGIN|FCVAR_SPONLY);
	
	//ConVars
	CreateConVar("instagibsource_enable", "1", "Enable/Disable InstaGib: Source.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	CreateConVar("instagibsource_beamcolor", "2", "InstaGib: Source beam color. 0: Random(1, 2 or 3), 1: Red, 2: Green, 3: Blue, 4: Colorful", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 4.0);
	CreateConVar("instagibsource_beamtype", "3", "InstaGib: Source beam type. 0: Random, 1: Laser Beam, 2: Plasma Beam, 3: Phys Beam, 4: Laser, 6: Lightning", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, float(BEAMMODELS));
	CreateConVar("instagibsource_weapon", "awp", "InstaGib: Source InstaGib weapon.", FCVAR_PLUGIN|FCVAR_NOTIFY);

	//Load GameConfig
	GameConfig= LoadGameConfigFile("instagibsource.games");
	
	//Prepare for RemoveAllItems SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConfig, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	SDKC_RemoveAllItems= EndPrepSDKCall();
	
	//Prepare for Weapon_ShootPosition SDK call
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(GameConfig, SDKConf_Virtual, "Weapon_ShootPosition");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByValue);
	SDKC_Weapon_ShootPosition= EndPrepSDKCall();
	
	//Event hooks
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("bullet_impact", Event_BulletImpact, EventHookMode_Post);
	
	//ConVar change hooks
	HookConVarChange(FindConVar("instagibsource_weapon"), CVarChange_InstaGibWeapon);
	
	//Command hooks
	RegConsoleCmd("drop", Command_Drop);
	
	//Execute config
	AutoExecConfig();
	}

public OnMapStart()
	{
	//Precache beam model
	Cache_Beam[1]= PrecacheModel("materials/sprites/laserbeam.vmt");
	Cache_Beam[2]= PrecacheModel("materials/sprites/plasmabeam.vmt");
	Cache_Beam[3]= PrecacheModel("materials/sprites/physbeam.vmt");
	Cache_Beam[4]= PrecacheModel("materials/sprites/laser.vmt");
	Cache_Beam[5]= PrecacheModel("materials/sprites/lgtning.vmt");
	//Precache Railgun sound
	if(!PrecacheSound(Sound_RailgunFire, true))
		Fail("InstaGib: Source", "Can't precache sound: %s", Sound_RailgunFire_Long);
	AddFileToDownloadsTable(Sound_RailgunFire_Long);
	//Precache PlayerDeath sound
	if(!PrecacheSound(Sound_PlayerDeath, true))
		Fail("InstaGib: Source", "Can't precache sound: %s", Sound_PlayerDeath_Long);
	AddFileToDownloadsTable(Sound_PlayerDeath_Long);
	}

//||||||||||||||||||||Command hooks

public Action:Command_Drop(client, args)
	{
	if(!Running()){return Plugin_Continue;}
	//Prevent dropping
	return Plugin_Handled;
	}

//||||||||||||||||||||Event hooks

public CVarChange_InstaGibWeapon(Handle:CVar, const String:oldvalue[], const String:newvalue[])
	{
	if(!Running()){return;}
	//Return if the value isn't changed
	if(StrEqual(oldvalue, newvalue))
		return;
	//Set new IG weapon
	Format(InstaGibWeapon, sizeof(InstaGibWeapon), newvalue);
	Format(InstaGibWeapon_Long, sizeof(InstaGibWeapon_Long), "weapon_%s", InstaGibWeapon);
	//Remove all IG weapons from the game
	new entities= GetMaxEntities();
	for(new entity= 1; entity<=entities; entity++)
		{
		if(IsValidEntity(entity))
			{
			new String:classname[256], String:oldweapon[64];
			GetEdictClassname(entity, classname, sizeof(classname));
			Format(oldweapon, sizeof(oldweapon), "weapon_%s", oldvalue);
			if(StrEqual(classname, oldweapon))
				RemoveEdict(entity);
			}
		}
	//Give new weapons
	new clients= GetMaxClients();
	for(new client= 1; client<=clients; client++)
		{
		if(IsClientInGame(client) && IsPlayerAlive(client))
			GiveInstaGibWeapon(client);
		}
	}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Remove all weapons
	RemoveAllWeapons();
	}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who spawned?
	new client= GetClientOfUserId(GetEventInt(event, "userid"));
	//Set money to 0
	ClientMoney(client, "set", 0);
	//Give InstaGib weapon
	GiveInstaGibWeapon(client);
	}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return Plugin_Continue;}
	//Who is the victim?
	new victim= GetClientOfUserId(GetEventInt(event, "userid"));
	//Who is the attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "attacker"));
	//Return if damage recieved from world
	if(attacker==0)
		return Plugin_Continue;
	//Which weapon did our attacker use?
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//Return if our attacker didn't use the InstaGib weapon
	if(!StrEqual(weapon, InstaGibWeapon))
		return Plugin_Continue;
	//Set victim's HP to 0 for an instakill
	ClientHealth(victim, "set", 0);
	return Plugin_Continue;
	}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return Plugin_Continue;}
	//Who is the victim?
	new victim= GetClientOfUserId(GetEventInt(event, "userid"));
	//Who is the attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "attacker"));
	//Return if the attacker is world
	if(attacker==0)
		return Plugin_Continue;
	//Which weapon did our attacker use?
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//Return if our attacker didn't use the InstaGib weapon
	if(!StrEqual(weapon, InstaGibWeapon))
		return Plugin_Continue;
	//Where is the victim?
	new Float:PlayerLocation[3];
	GetClientAbsOrigin(victim, PlayerLocation);
	//Play the sound
	EmitSoundToAll(Sound_PlayerDeath, _, _, SNDLEVEL_GUNFIRE, _, _, _, _, PlayerLocation);
	//Remove ragdolls
	RemoveRagdolls();
	//Remove weapons
	RemoveWeapons(InstaGibWeapon_Long);
	return Plugin_Continue;
	}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Who is our attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "userid"));
	//Which weapon did our attacker use?
	decl String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	//Return if our attacker didn't use the IG weapon or IG weapon is knife
	if(!StrEqual(weapon, InstaGibWeapon) || StrEqual(InstaGibWeapon, "knife"))
		return;
	//Where is our attacker?
	new Float:PlayerLocation[3];
	GetClientAbsOrigin(attacker, PlayerLocation);
	//Play the sound
	EmitSoundToAll(Sound_RailgunFire, _, SNDCHAN_WEAPON, SNDLEVEL_GUNFIRE, _, _, _, _, PlayerLocation);
	}

public Event_BulletImpact(Handle:event, const String:name[], bool:dontBroadcast)
	{
	if(!Running()){return;}
	//Return if the InstaGib weapon is knife
	if(StrEqual(InstaGibWeapon, "knife"))
		return;
	//Who is our attacker?
	new attacker= GetClientOfUserId(GetEventInt(event, "userid"));
	//Where did the bullet came from?
	new Float:Weapon_ShootPosition[3];
	SDKCall(SDKC_Weapon_ShootPosition, attacker, Weapon_ShootPosition);
	//Where did the bullet hit?
	new Float:HitLocation[3];
	HitLocation[0]= GetEventFloat(event,"x");
	HitLocation[1]= GetEventFloat(event,"y");
	HitLocation[2]= GetEventFloat(event,"z");
	//Adjust Weapon_ShootPosition to make the beam start from the right place
	new Float:Distance= GetVectorDistance(Weapon_ShootPosition, HitLocation);
	Weapon_ShootPosition[1]-= 0.08;
	for(new i=0; i<=2; i++)
		Weapon_ShootPosition[i]+= (HitLocation[i]-Weapon_ShootPosition[i])*(40/Distance);
	//Setup the beam
	new Beam_Model, BeamColor[4], Float:BeamWidth, Float:BeamLife;
	//Color
	BeamColor[0]= 0; BeamColor[1]= 0; BeamColor[2]= 0; BeamColor[3]= 255;
	new color= IConVar("beamcolor");
	if(color!=4)
		{
		if(color==0)
			color= GetRandomInt(0, 2);
		else
			color--;
		BeamColor[color]= GetRandomInt(150, 255);
		}
		else if(color==4)
		{
		BeamColor[0]= GetRandomInt(0, 255);
		BeamColor[1]= GetRandomInt(0, 255);
		BeamColor[2]= GetRandomInt(0, 255);
		}
	//Width
	BeamWidth= GetRandomFloat(2.0, 5.0);
	//Life
	BeamLife= GetRandomFloat(0.2, 0.4);
	//Model
	new beamtype= IConVar("beamtype");
	if(beamtype==0)
		beamtype= GetRandomInt(1, BEAMMODELS);
	Beam_Model= Cache_Beam[beamtype];
	//Draw the beam
	TE_SetupBeamPoints(Weapon_ShootPosition, HitLocation, Beam_Model, 0, 0, 66, BeamLife, BeamWidth, BeamWidth, 0, 0.0, BeamColor, 0);
	TE_SendToAll();
	//Show an energy splash
	new Float:Direction[3]= {0.0, 0.0, 0.0};
	TE_SetupEnergySplash(HitLocation, Direction, false);
	TE_SendToAll();
	//Show some dust
	TE_SetupDust(HitLocation, Direction, 5.0, 1.0);
	TE_SendToAll();
	}

//||||||||||||||||||||FUNCTIONS

public Running()
	{
	return GetConVarBool(FindConVar("instagibsource_enable"));
	}

public bool:BConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "instagibsource_%s", subcv);
	return GetConVarBool(FindConVar(ConVarName));
	}

public IConVar(const String:subcv[])
	{
	new String:ConVarName[32];
	Format(ConVarName, 32, "instagibsource_%s", subcv);
	return GetConVarInt(FindConVar(ConVarName));
	}

public GiveInstaGibWeapon(client)
	{
	//Strip all weapons
	SDKCall(SDKC_RemoveAllItems, client, true);
	//Give InstaGib weapon
	GivePlayerItem(client, InstaGibWeapon_Long);
	//Give knife if IG weapon is not knife
	if(!StrEqual(InstaGibWeapon, "knife"))
		GivePlayerItem(client, "weapon_knife");
	}
/*
public CreateGib(Float:origin[3])
	{
	new entity= CreateEdict();
	}*/