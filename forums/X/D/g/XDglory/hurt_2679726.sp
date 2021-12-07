/* put the line below after all of the includes!
#pragma newdecls required
*/

#pragma newdecls required
#define DMG_GENERIC 0
#define DMG_CRUSH (1 << 0)
#define DMG_BULLET (1 << 1)
#define DMG_SLASH (1 << 2)
#define DMG_BURN (1 << 3)
#define DMG_VEHICLE (1 << 4)
#define DMG_FALL (1 << 5)
#define DMG_BLAST (1 << 6)
#define DMG_CLUB (1 << 7)
#define DMG_SHOCK (1 << 8)
#define DMG_SONIC (1 << 9)
#define DMG_ENERGYBEAM (1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE (1 << 11)
#define DMG_NEVERGIB (1 << 12)
#define DMG_ALWAYSGIB (1 << 13)
#define DMG_DROWN (1 << 14)
#define DMG_TIMEBASED (DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE (1 << 15)
#define DMG_NERVEGAS (1 << 16)
#define DMG_POISON (1 << 17)
#define DMG_RADIATION (1 << 18)
#define DMG_DROWNRECOVER (1 << 19)
#define DMG_ACID (1 << 20)
#define DMG_SLOWBURN (1 << 21)
#define DMG_REMOVENORAGDOLL (1 << 22)
#define DMG_PHYSGUN (1 << 23)
#define DMG_PLASMA (1 << 24)
#define DMG_AIRBOAT (1 << 25)
#define DMG_DISSOLVE (1 << 26)
#define DMG_BLAST_SURFACE (1 << 27)
#define DMG_DIRECT (1 << 28)
#define DMG_BUCKSHOT (1 << 29)

/**
* Deals specified damage to indicated client by indicated attacker with indicated weapon
*
* @param victim Client index of victim
* @param damage Amount of damage to inflict on victim
* @param attacker Client index of attacker
* @param dmg_type Type of damage (see #defines)
* @param weapon String value of weapon name, if desired
* @noreturn
*/

void DealDamage(int victim, int damage, int attacker = 0, int dmg_type = DMG_GENERIC, char[] weapon = "") {
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim)) {
		char dmg_str[16];
		IntToString(damage,dmg_str,16);
		char dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		int pointHurt=CreateEntityByName("point_hurt");
		if (pointHurt) {
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			
			if(!StrEqual(weapon,"")) {
				DispatchKeyValue(pointHurt,"classname",weapon);
			}
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			DispatchKeyValue(pointHurt,"classname","point_hurt");
			DispatchKeyValue(victim,"targetname","war3_donthurtme");
			RemoveEdict(pointHurt);
		}
	}
}
