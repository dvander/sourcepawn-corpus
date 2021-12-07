#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

new Handle:All_team = INVALID_HANDLE;
new Handle:GENERIC = INVALID_HANDLE;
new Handle:CRUSH = INVALID_HANDLE;
new Handle:BULLET = INVALID_HANDLE;
new Handle:SLASH = INVALID_HANDLE;
new Handle:BURN = INVALID_HANDLE;
new Handle:VEHICLE = INVALID_HANDLE;
new Handle:FALL = INVALID_HANDLE;
new Handle:BLAST = INVALID_HANDLE;
new Handle:CLUB = INVALID_HANDLE;
new Handle:SHOCK = INVALID_HANDLE;
new Handle:SONIC = INVALID_HANDLE;
new Handle:ENERGYBEAM = INVALID_HANDLE;
new Handle:PREVENT_PHYSICS_FORCE = INVALID_HANDLE;
new Handle:NEVERGIB = INVALID_HANDLE;
new Handle:ALWAYSGIB = INVALID_HANDLE;
new Handle:DROWN = INVALID_HANDLE;
new Handle:PARALYZE = INVALID_HANDLE;
new Handle:NERVEGAS = INVALID_HANDLE;
new Handle:POISON = INVALID_HANDLE;
new Handle:RADIATION = INVALID_HANDLE;
new Handle:DROWNRECOVER = INVALID_HANDLE;
new Handle:ACID = INVALID_HANDLE;
new Handle:SLOWBURN = INVALID_HANDLE;
new Handle:REMOVENORAGDOLL = INVALID_HANDLE;
new Handle:PHYSGUN = INVALID_HANDLE;
new Handle:PLASMA = INVALID_HANDLE;
new Handle:AIRBOAT = INVALID_HANDLE;
new Handle:DISSOLVE = INVALID_HANDLE;
new Handle:BLAST_SURFACE = INVALID_HANDLE;
new Handle:DIRECT = INVALID_HANDLE;
new Handle:BUCKSHOT = INVALID_HANDLE;
new Handle:LASTGENERICFLAG = INVALID_HANDLE;
new Handle:HEADSHOT = INVALID_HANDLE;

new g_type;

public Plugin:myinfo = {
	name = "Select to close the damage type or friendly damage type",
	author = "AK978",
	version = "1.0"
}

public OnPluginStart(){
	All_team = CreateConVar("sm_all_team_damage", "0", "All Team Damage.", 0);
	
	GENERIC = CreateConVar("sm_GENERIC_damage", "0", "Generic damage.", 0);
	CRUSH = CreateConVar("sm_CRUSH_damage", "0", "Damage from physics objects.", 0);
	BULLET = CreateConVar("sm_BULLET_damage", "0", "Damage from bullets.", 0);
	SLASH = CreateConVar("sm_SLASH_damage", "0", "Damage from most melee attacks (that scratch, lacerate, or cut).", 0);
	BURN = CreateConVar("sm_BURN_damage", "0", "Burn damage.", 0);
	VEHICLE = CreateConVar("sm_VEHICLE_damage", "0", "Hit by a vehicle.", 0);
	FALL = CreateConVar("sm_FALL_damage", "0", "Damage from high falls. (can be used to disable player fall damage).", 0);
	BLAST = CreateConVar("sm_BLAST_damage", "0", "Damage from explosives (ear-ringing effect).", 0);
	CLUB = CreateConVar("sm_CLUB_damage", "0", "Damage from some enemy melee attacks (blunt or unarmed) e.g. Combine melee attack.", 0);
	SHOCK = CreateConVar("sm_SHOCK_damage", "0", "Damage from electricity (creates sparks and puff of smoke at damage position).", 0);
	SONIC = CreateConVar("sm_SONIC_damage", "0", "Damage from supersonic objects.", 0);
	ENERGYBEAM = CreateConVar("sm_ENERGYBEAM_damage", "0", "Laser or other high energy beam.", 0);
	PREVENT_PHYSICS_FORCE = CreateConVar("sm_PREVENT_PHYSICS_FORCE_damage", "0", "Prevent a physics force (e.g. Gravity Gun Jump on Props).", 0);
	NEVERGIB = CreateConVar("sm_NEVERGIB_damage", "0", "No damage type will be able to gib victims upon death.", 0);
	ALWAYSGIB = CreateConVar("sm_ALWAYSGIB_damage", "0", "Any damage type can be made to gib victims upon death.", 0);
	DROWN = CreateConVar("sm_DROWN_damage", "0", "Damage from drowning.", 0);
	PARALYZE = CreateConVar("sm_PARALYZE_damage", "0", "Damage from paralyzing.", 0);
	NERVEGAS = CreateConVar("sm_NERVEGAS_damage", "0", "Damage from nervegas. (GLaDOS's gas from the ending of Portal).", 0);
	POISON = CreateConVar("sm_POISON_damage", "0", "Damage from poison (e.g. black head crabs).", 0);
	RADIATION = CreateConVar("sm_RADIATION_damage", "0", "Damage from radiation (Geiger counter will also go off).", 0);
	DROWNRECOVER = CreateConVar("sm_DROWNRECOVER_damage", "0", "Drowning recovery (health regained after surfacing).", 0);
	ACID = CreateConVar("sm_ACID_damage", "0", "Damage from dangerous acids. (gives a light-cyan flash ingame).", 0);
	SLOWBURN = CreateConVar("sm_SLOWBURN_damage", "0", "Slow burning.", 0);
	REMOVENORAGDOLL = CreateConVar("sm_REMOVENORAGDOLL_damage", "0", "No ragdoll will be created, and the target will be quietly removed.", 0);
	PHYSGUN = CreateConVar("sm_PHYSGUN_damage", "0", "Damage from the Gravity Gun (e.g. pushing head crabs).", 0);
	PLASMA = CreateConVar("sm_PLASMA_damage", "0", "Turns the player's screen dark and plays sounds until the player's next footstep.", 0);
	AIRBOAT = CreateConVar("sm_AIRBOAT_damage", "0", "Damage from airboat gun.", 0);
	DISSOLVE = CreateConVar("sm_DISSOLVE_damage", "0", "Damage from combine technology e.g. combine balls and the core.", 0);
	BLAST_SURFACE = CreateConVar("sm_BLAST_SURFACE_damage", "0", "A blast on the surface of water that cannot harm things underwater", 0);
	DIRECT = CreateConVar("sm_DIRECT_damage", "0", "Damage from being on fire.(DMG_BURN relates to external sources hurting you)", 0);
	BUCKSHOT = CreateConVar("sm_BUCKSHOT_damage", "0", "Damage from shotguns. (not quite a bullet. Little, rounder, different.)", 0);
	LASTGENERICFLAG = CreateConVar("sm_LASTGENERICFLAG_damage", "0", "", 0);
	HEADSHOT = CreateConVar("sm_HEADSHOT_damage", "0", "Damage from a headshot.", 0);
	
	AutoExecConfig(true, "Close_DamageType");
}

public OnClientPutInServer(client){
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {	
	if (GetConVarBool(All_team) || GetClientTeam(attacker) == GetClientTeam(victim)){
		g_type = -1;
		check_damagetype();

		if (damagetype & g_type){
			if (damage != 0){
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue; 
}

check_damagetype(){
	if(GetConVarBool(GENERIC))
		g_type = 0;
	else if(GetConVarBool(CRUSH))
		g_type = 1;
	else if(GetConVarBool(BULLET))
		g_type = 2;
	else if(GetConVarBool(SLASH))
		g_type = 4;
	else if(GetConVarBool(BURN))
		g_type = 8;
	else if(GetConVarBool(VEHICLE))
		g_type = 16;
	else if(GetConVarBool(FALL))
		g_type = 32;
	else if(GetConVarBool(BLAST))
		g_type = 64;
	else if(GetConVarBool(CLUB))
		g_type = 128;
	else if(GetConVarBool(SHOCK))
		g_type = 256;
	else if(GetConVarBool(SONIC))
		g_type = 512;
	else if(GetConVarBool(ENERGYBEAM))
		g_type = 1024;
	else if(GetConVarBool(PREVENT_PHYSICS_FORCE))
		g_type = 2048;
	else if(GetConVarBool(NEVERGIB))
		g_type = 4096;
	else if(GetConVarBool(ALWAYSGIB))
		g_type = 8192;
	else if(GetConVarBool(DROWN))
		g_type = 16384;
	else if(GetConVarBool(PARALYZE))
		g_type = 32768;
	else if(GetConVarBool(NERVEGAS))
		g_type = 65536;
	else if(GetConVarBool(POISON))
		g_type = 131072;
	else if(GetConVarBool(RADIATION))
		g_type = 262144;
	else if(GetConVarBool(DROWNRECOVER))
		g_type = 524288;
	else if(GetConVarBool(ACID))
		g_type = 1048576;
	else if(GetConVarBool(SLOWBURN))
		g_type = 2097152;
	else if(GetConVarBool(REMOVENORAGDOLL))
		g_type = 4194304;
	else if(GetConVarBool(PHYSGUN))
		g_type = 8388608;
	else if(GetConVarBool(PLASMA))
		g_type = 16777216;
	else if(GetConVarBool(AIRBOAT))
		g_type = 33554432;
	else if(GetConVarBool(DISSOLVE))
		g_type = 67108864;
	else if(GetConVarBool(BLAST_SURFACE))
		g_type = 134217728;
	else if(GetConVarBool(DIRECT))
		g_type = 268435456;
	else if(GetConVarBool(BUCKSHOT))
		g_type = 536870912;
	else if(GetConVarBool(LASTGENERICFLAG))
		g_type = 1073741824;
	else if(GetConVarBool(HEADSHOT))
		g_type = 2147483648;
}