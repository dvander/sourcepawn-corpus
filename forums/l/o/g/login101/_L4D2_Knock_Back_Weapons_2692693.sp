#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define DEBUG 1

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Handle:GunzWeapon		 	= INVALID_HANDLE;
new Handle:KnockBackSurvivor	= INVALID_HANDLE;
new Handle:KnockBackTank		= INVALID_HANDLE;
new Handle:RemoveDamage 	 	= INVALID_HANDLE;
new Handle:hForce 			 	= INVALID_HANDLE;
new Handle:vForce 			 	= INVALID_HANDLE;

// Event Weapons Count
#define eventWeaponsCount 19

// Event Weapons Name
static const String:eventWeapons[eventWeaponsCount][32] = {
	"pistol",
	"pistol_magnum",
	"smg",
	"smg_silenced",
	"smg_mp5",
	"rifle",
	"rifle_m60",
	"rifle_desert",
	"rifle_ak47",
	"rifle_sg552",
	"pumpshotgun",
	"shotgun_chrome",
	"autoshotgun",
	"shotgun_spas",
	"huntingrifle",
	"sniper_military",
	"sniper_scout",
	"sniper_awp",
	"grenade_launcher"
};

// Event Weapons Power
new Handle:ForceOfWeapons[eventWeaponsCount] = {
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE,
	INVALID_HANDLE
};

public Plugin:myinfo = 
{
	name = "[L4D2] Knock Back Weapons",
	author = "ztar + Himitsu-",
	description = "Knock Back Weapons",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	GunzWeapon		  	= CreateConVar("l4d2_gunz_weapon",			"1", 	"Enable KS(?)", 			CVAR_FLAGS);
	KnockBackSurvivor	= CreateConVar("l4d2_KnockBack_survivor",	"1", 	"Are you KnockBack king?", 	CVAR_FLAGS);
	KnockBackTank		= CreateConVar("l4d2_KnockBack_tank",		"1", 	"Are you KnockBack king?", 	CVAR_FLAGS);
	RemoveDamage	  	= CreateConVar("l4d2_removeffdamage",		"1", 	"Remove FF damage.", 		CVAR_FLAGS);
	hForce			  	= CreateConVar("l4d2_smashrate_h",			"1.5", 	"Horizontal force rate", 	CVAR_FLAGS);
	vForce			  	= CreateConVar("l4d2_smashrate_v",			"1.0", 	"Vertical force rate", 		CVAR_FLAGS);
	
	ForceOfWeapons[0] 	= CreateConVar("l4d2_force_pistol",				"100", "Knock Back force of your Pistol", 			CVAR_FLAGS);
	ForceOfWeapons[1] 	= CreateConVar("l4d2_force_pistol_magnum",		"100", "Knock Back force of your Pistol Magnum", 	CVAR_FLAGS);
	ForceOfWeapons[2] 	= CreateConVar("l4d2_force_smg",				"100", "Knock Back force of your Smg", 				CVAR_FLAGS);
	ForceOfWeapons[3] 	= CreateConVar("l4d2_force_smg_silenced",		"100", "Knock Back force of your Smg_silenced", 	CVAR_FLAGS);
	ForceOfWeapons[4] 	= CreateConVar("l4d2_force_smg_mp5",			"100", "Knock Back force of your Smg_mp5", 			CVAR_FLAGS);
	ForceOfWeapons[5] 	= CreateConVar("l4d2_force_rifle",				"100", "Knock Back force of your Rifle", 			CVAR_FLAGS);
	ForceOfWeapons[6] 	= CreateConVar("l4d2_force_rifle_m60",			"100", "Knock Back force of your Rifle M60",	 	CVAR_FLAGS);
	ForceOfWeapons[7] 	= CreateConVar("l4d2_force_rifle_desert",		"100", "Knock Back force of your Rifle Desert", 	CVAR_FLAGS);
	ForceOfWeapons[8] 	= CreateConVar("l4d2_force_rifle_ak47",			"100", "Knock Back force of your Rifle Ak47", 		CVAR_FLAGS);
	ForceOfWeapons[9] 	= CreateConVar("l4d2_force_rifle_sg552",		"100", "Knock Back force of your Rifle SG552", 		CVAR_FLAGS);
	ForceOfWeapons[10] 	= CreateConVar("l4d2_force_pumpshotgun",		"100", "Knock Back force of your Pump Shotgun", 	CVAR_FLAGS);
	ForceOfWeapons[11] 	= CreateConVar("l4d2_force_shotgun_chrome",		"100", "Knock Back force of your Shotgun Chrome", 	CVAR_FLAGS);
	ForceOfWeapons[12] 	= CreateConVar("l4d2_force_autoshotgun",		"100", "Knock Back force of your Auto Shotgun", 	CVAR_FLAGS);
	ForceOfWeapons[13] 	= CreateConVar("l4d2_force_shotgun_spas",		"100", "Knock Back force of your Shotgun Spas", 	CVAR_FLAGS);
	ForceOfWeapons[14] 	= CreateConVar("l4d2_force_huntingrifle",		"100", "Knock Back force of your Hunting Rifle", 	CVAR_FLAGS);
	ForceOfWeapons[15] 	= CreateConVar("l4d2_force_sniper_military",	"100", "Knock Back force of your Sniper Military", 	CVAR_FLAGS);
	ForceOfWeapons[16] 	= CreateConVar("l4d2_force_sniper_scout",		"100", "Knock Back force of your Sniper Scout", 	CVAR_FLAGS);
	ForceOfWeapons[17] 	= CreateConVar("l4d2_force_sniper_awp",			"100", "Knock Back force of your Sniper Awp", 		CVAR_FLAGS);
	ForceOfWeapons[18] 	= CreateConVar("l4d2_force_grenade_launcher",	"100", "Knock Back force of your Grenade Launcher", CVAR_FLAGS);

	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d2_KnockBack_Weapons");
}

public Action:Event_Weapon_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	#if DEBUG
		PrintToServer("DEBUG [Weapon_Fire] GetEventString() :: %s", weapon);
	#endif
	
	if(checkSmashWeapon(weapon) && GetConVarInt(GunzWeapon))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND))
		{
			/* Slash! */
			Smash(client, client, 350.0, 2.0, -0.1);
		}
	}
	return Plugin_Continue;
}

public Action:Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	#if DEBUG
		PrintToServer("DEBUG [Player_Hurt] GetEventString() :: %s", weapon);
	#endif
	
	if(checkSmashWeapon(weapon))
	{
		// return if not onGround 
		if(!(GetEntityFlags(target) & FL_ONGROUND))
			return Plugin_Continue;
	
		/* return if KnockBackTank is OFF */
		if(GetConVarInt(KnockBackTank) == 0 && GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
			return Plugin_Continue;
		
		/* return if KnockBackSurvivor is OFF */
		if(GetConVarInt(KnockBackSurvivor) == 0 && (GetClientTeam(client) == GetClientTeam(target)))
			return Plugin_Continue;
		
		/* remove FF damage */
		if(GetConVarInt(RemoveDamage) && (GetClientTeam(client) == GetClientTeam(target)))
			SetEntityHealth(target, (GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
			
		/* Smash target */
		Smash(client, target, getSmashPower(weapon, 200.0), GetConVarFloat(hForce), GetConVarFloat(vForce));
	}
	return Plugin_Continue;
}

Smash(client, target, Float:power, Float:powHor, Float:powVec)
{
	/* Smash target */
	decl Float:HeadingVector[3], Float:AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])) ,power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])) ,power * powHor);
	
	decl Float:current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	decl Float:resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}

stock bool:checkSmashWeapon(String:weapon[]){
	/* Check GetEventString() weapon Name */
	for(new i = 0; i < eventWeaponsCount; i++){
		if(StrEqual(weapon, eventWeapons[i])){
			return true;
		}
	}
	return false;
}

stock Float:getSmashPower(String:weapon[], Float:power){
	/* Check GetEventString() weapon Name */
	for(new i = 0; i < eventWeaponsCount; i++){
		if(StrEqual(weapon, eventWeapons[i])){
			return GetConVarFloat(ForceOfWeapons[i]);
		}
	}
	return power;
}
