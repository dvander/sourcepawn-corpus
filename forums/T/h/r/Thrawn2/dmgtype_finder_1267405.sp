#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <sdkhooks>

public OnPluginStart() {
	RegConsoleCmd("sm_bm", Cmd_BleedMe);
}

public Action:Cmd_BleedMe(iClient, iArgs) {
	TF2_MakeBleed(iClient, iClient, 2.0);
}

public OnClientPutInServer(client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) {
	if ((damagetype & DMG_GENERIC)) {
		LogMessage("%N got DMG_GENERIC", victim);
	}
	if ((damagetype & DMG_CRUSH)) {
		LogMessage("%N got DMG_CRUSH", victim);
	}
	if ((damagetype & DMG_BULLET)) {
		LogMessage("%N got DMG_BULLET", victim);
	}
	if ((damagetype & DMG_SLASH)) {
		LogMessage("%N got DMG_SLASH", victim);
	}
	if ((damagetype & DMG_BURN)) {
		LogMessage("%N got DMG_BURN", victim);
	}
	if ((damagetype & DMG_VEHICLE)) {
		LogMessage("%N got DMG_VEHICLE", victim);
	}
	if ((damagetype & DMG_FALL)) {
		LogMessage("%N got DMG_FALL", victim);
	}
	if ((damagetype & DMG_BLAST)) {
		LogMessage("%N got DMG_BLAST", victim);
	}
	if ((damagetype & DMG_CLUB)) {
		LogMessage("%N got DMG_CLUB", victim);
	}
	if ((damagetype & DMG_SHOCK)) {
		LogMessage("%N got DMG_SHOCK", victim);
	}
	if ((damagetype & DMG_SONIC)) {
		LogMessage("%N got DMG_SONIC", victim);
	}
	if ((damagetype & DMG_ENERGYBEAM)) {
		LogMessage("%N got DMG_ENERGYBEAM", victim);
	}
	if ((damagetype & DMG_PREVENT_PHYSICS_FORCE)) {
		LogMessage("%N got DMG_PREVENT_PHYSICS_FORCE", victim);
	}
	if ((damagetype & DMG_NEVERGIB)) {
		LogMessage("%N got DMG_NEVERGIB", victim);
	}
	if ((damagetype & DMG_ALWAYSGIB)) {
		LogMessage("%N got DMG_ALWAYSGIB", victim);
	}
	if ((damagetype & DMG_DROWN)) {
		LogMessage("%N got DMG_DROWN", victim);
	}
	if ((damagetype & DMG_PARALYZE)) {
		LogMessage("%N got DMG_PARALYZE", victim);
	}
	if ((damagetype & DMG_NERVEGAS)) {
		LogMessage("%N got DMG_NERVEGAS", victim);
	}
	if ((damagetype & DMG_POISON)) {
		LogMessage("%N got DMG_POISON", victim);
	}
	if ((damagetype & DMG_RADIATION)) {
		LogMessage("%N got DMG_RADIATION", victim);
	}
	if ((damagetype & DMG_DROWNRECOVER)) {
		LogMessage("%N got DMG_DROWNRECOVER", victim);
	}
	if ((damagetype & DMG_ACID)) {
		LogMessage("%N got DMG_ACID", victim);
	}
	if ((damagetype & DMG_SLOWBURN)) {
		LogMessage("%N got DMG_SLOWBURN", victim);
	}
	if ((damagetype & DMG_REMOVENORAGDOLL)) {
		LogMessage("%N got DMG_REMOVENORAGDOLL", victim);
	}
	if ((damagetype & DMG_PHYSGUN)) {
		LogMessage("%N got DMG_PHYSGUN", victim);
	}
	if ((damagetype & DMG_PLASMA)) {
		LogMessage("%N got DMG_PLASMA", victim);
	}
	if ((damagetype & DMG_AIRBOAT)) {
		LogMessage("%N got DMG_AIRBOAT", victim);
	}
	if ((damagetype & DMG_DISSOLVE)) {
		LogMessage("%N got DMG_DISSOLVE", victim);
	}
	if ((damagetype & DMG_BLAST_SURFACE)) {
		LogMessage("%N got DMG_BLAST_SURFACE", victim);
	}
	if ((damagetype & DMG_DIRECT)) {
		LogMessage("%N got DMG_DIRECT", victim);
	}
	if ((damagetype & DMG_BUCKSHOT)) {
		LogMessage("%N got DMG_BUCKSHOT", victim);
	}
	return Plugin_Continue;
}