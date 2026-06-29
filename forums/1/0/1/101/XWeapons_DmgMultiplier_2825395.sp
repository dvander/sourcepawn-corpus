#include <sdkhooks>

ConVar X_CVARS[18];					// 18 is number of Convars and so the number of your game weapons [Bullets Only] 
float X_Store[MAXPLAYERS+1][3];		// [0]:Active Weapon Index   [1]:Custom dmgMultiplier  [2]:Server dmgMultiplier

char X_Weapons[][][] =
{
    {"X_DmgMultiplier_pistol"			,"1.2"},
    {"X_DmgMultiplier_rifle"			,"1.2"},
    {"X_DmgMultiplier_autoshotgun"		,"1.2"},
	{"X_DmgMultiplier_hunting_rifle"	,"1.2"},
	{"X_DmgMultiplier_pistol_magnum"	,"1.2"},
	{"X_DmgMultiplier_pumpshotgun"		,"1.2"},
    {"X_DmgMultiplier_rifle_ak47"		,"1.2"},
    {"X_DmgMultiplier_rifle_sg552"		,"1.2"},
    {"X_DmgMultiplier_rifle_desert"		,"1.2"},
	{"X_DmgMultiplier_shotgun_spas"		,"1.2"},
    {"X_DmgMultiplier_shotgun_chrome"	,"1.2"},
    {"X_DmgMultiplier_smg_silenced"		,"1.2"},
    {"X_DmgMultiplier_smg_mp5"			,"1.2"},
	{"X_DmgMultiplier_sniper_awp"		,"1.2"},
    {"X_DmgMultiplier_sniper_military"	,"1.2"},
    {"X_DmgMultiplier_sniper_scout"		,"1.2"},
    {"X_DmgMultiplier_rifle_m60"		,"1.2"},
	{"X_DmgMultiplier_smg"				,"1.2"}
};

public OnPluginStart()
{
	for (int i=0; i<18 ; i++)
	{
		X_CVARS[i]=CreateConVar(X_Weapons[i][0], X_Weapons[i][1] ,_, FCVAR_NOTIFY, true ,0.0 ,true ,10.0);
	}
	//AutoExecConfig(true, "XWeapons_DmgMultiplier");
}

public OnClientPostAdminCheck(client)
{
	X_Store[client][1] = 1.0;	// default Players Level , This Is for Extra Usage (Custom Additional dmgMultiplier for each player) .
	SDKHook(client, SDKHook_WeaponCanSwitchTo , On_WeaponSwitch);
}

void On_WeaponSwitch(client , Weapon) 
{
	if ( X_Store[client][0] == Weapon) return;
	
	static char Weapon_Name[32];
	GetEdictClassname(Weapon , Weapon_Name , 32);
	
	for (int i=0; i<18 ; i++)
	{
		if ( !strncmp(X_Weapons[i][0][16],Weapon_Name[7],10,false) )
		{
			X_Store[client][2] = GetConVarFloat(X_CVARS[i]);
			//PrintToChat(client , "Server damage multiplier = %.2f ",X_Store[client][2]);
			break;
		}
	}
	
	X_Store[client][0] = float(Weapon);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (HasEntProp(entity, Prop_Data, "m_takedamage"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype)
{
	if ( damagetype&2 )
	{
		damage *= X_Store[attacker][1] * X_Store[attacker][2];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}