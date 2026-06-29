#include <sdkhooks>

char logtext[256];
int damagetypes[128] ,count;

char X_Damagetypes[32][2][32] =
{
    {"DMG_CRUSH"				,"(1 << 0)"},
	{"DMG_BULLET"				,"(1 << 1)"},
    {"DMG_SLASH"				,"(1 << 2)"},
	{"DMG_BURN"					,"(1 << 3)"},
	{"DMG_VEHICLE"				,"(1 << 4)"},
	{"DMG_FALL"					,"(1 << 5)"},
	{"DMG_BLAST"				,"(1 << 6)"},
    {"DMG_CLUB"					,"(1 << 7)"},
    {"DMG_SHOCK"				,"(1 << 8)"},
    {"DMG_SONIC"				,"(1 << 9)"},
	{"DMG_ENERGYBEAM"			,"(1 << 10)"},
    {"DMG_PREVENT_PHYSICS_FORCE","(1 << 11)"},
    {"DMG_NEVERGIB"				,"(1 << 12)"},
	{"DMG_ALWAYSGIB"			,"(1 << 13)"},
	{"DMG_DROWN"				,"(1 << 14)"},
    {"DMG_PARALYZE"				,"(1 << 15)"},
    {"DMG_NERVEGAS"				,"(1 << 16)"},
    {"DMG_POISON"				,"(1 << 17)"},
	{"DMG_RADIATION"			,"(1 << 18)"},
	{"DMG_DROWNRECOVER"			,"(1 << 19)"},
    {"DMG_ACID"					,"(1 << 20)"},
	{"DMG_SLOWBURN"				,"(1 << 21)"},
    {"DMG_REMOVENORAGDOLL"		,"(1 << 22)"},
    {"DMG_PHYSGUN"				,"(1 << 23)"},
    {"DMG_PLASMA"				,"(1 << 24)"},
	{"DMG_AIRBOAT"				,"(1 << 25)"},
	{"DMG_DISSOLVE"				,"(1 << 26)"},
	{"DMG_BLAST_SURFACE"		,"(1 << 27)"},
	{"DMG_DIRECT"				,"(1 << 28)"},
    {"DMG_BUCKSHOT"				,"(1 << 29)"},
    {"DMG_HEADSHOT"				,"(1 << 30)"},
    {"DMG_DISMEMBER"			,"(1 << 31)"}
};

public OnPluginStart()
{
	BuildPath(Path_SM, logtext, sizeof(logtext), "logs\\DmgType.log" );
	LogToFile(logtext , "DamageType Bitflags Reader");
	LogToFile(logtext , "==============================================================================");
	LogToFile(logtext , "For More Details :");
	LogToFile(logtext , " https://developer.valvesoftware.com/wiki/Damage_types#Damage_type_table");
	LogToFile(logtext , " https://forums.alliedmods.net/showpost.php?p=991802&postcount=2");
	LogToFile(logtext , "==============================================================================");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (HasEntProp(entity, Prop_Data, "m_takedamage"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	static int j;
	for (j=0 ; j < count ; j++)
	{
		if (damagetype == damagetypes[j])
		{
			return Plugin_Continue;
		}
	}
	
	damagetypes[count++] = damagetype;
	
	static char T_Weapon[32],T_Attacker[32],T_Inflictor[32],T_Victim[32],T_DmgType[128];
	
	if (IsValidEdict(victim))	GetEdictClassname(victim, T_Victim, sizeof(T_Victim));
	else	Format(T_Victim ,sizeof(T_Victim) , "%d",victim);
	
	if (IsValidEdict(attacker))	GetEdictClassname(attacker, T_Attacker, sizeof(T_Attacker));
	else	Format(T_Attacker ,sizeof(T_Attacker) , "%d",attacker);
	
	if (IsValidEdict(inflictor))	GetEdictClassname(inflictor, T_Inflictor, sizeof(T_Inflictor));
	else	Format(T_Inflictor ,sizeof(T_Inflictor) , "%d",inflictor);
	
	if (IsValidEdict(weapon))	GetEdictClassname(weapon, T_Weapon, sizeof(T_Weapon));
	else	Format(T_Weapon ,sizeof(T_Weapon) , "%d",weapon);
	
	Format(T_DmgType ,sizeof(T_DmgType) , "");
	
	for (int i=0; i<32 ; i++)
	{
		if ( damagetype&(1 << i) )
		{
			Format(T_DmgType ,sizeof(T_DmgType) , "%s | %s" , T_DmgType , X_Damagetypes[i][0]);
		}
	}
	Format(T_DmgType ,sizeof(T_DmgType) , "%s" , T_DmgType[3]);
	
	LogToFile(logtext , "attacker  :%s ." ,T_Attacker );
	LogToFile(logtext , "victim  : %s  ." ,T_Victim   );
	LogToFile(logtext , "inflictor : %s." ,T_Inflictor);
	LogToFile(logtext , "inflictor %s attacker ." , inflictor==attacker ? "=" : "≠");
	LogToFile(logtext , "weapon : %s ." ,T_Weapon);
	LogToFile(logtext , "damage : %f ." ,damage);
	//LogToFile(logtext , "Damage Force:  (%f, %f ,%f) .",damageForce[0],damageForce[1],damageForce[2]);
	LogToFile(logtext , "DamageTypes: %s .",T_DmgType);

	LogToFile(logtext , "-------------------------------------------------------------------------------");	

	return Plugin_Continue;
}