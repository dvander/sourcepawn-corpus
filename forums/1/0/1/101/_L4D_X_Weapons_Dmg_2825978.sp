#include <sdkhooks>

int X_DMG ,MAX;

ConVar X_CVARS[36];			// 36 is number of modified weapons based on l4d2 
int X_Store[33][3];			// [0]: Active Weapon Index   [1]: Active ConVar Index  [2]: Active Machine Gun Index

char X_Weapons[36][2][32] =
{
    {"X_DmgMultiplier_pistol"				,"1.1"},
    {"X_DmgMultiplier_rifle"				,"1.2"},
    {"X_DmgMultiplier_autoshotgun"			,"1.2"},
	{"X_DmgMultiplier_hunting_rifle"		,"1.2"},
	{"X_DmgMultiplier_pistol_magnum"		,"1.2"},
	{"X_DmgMultiplier_pumpshotgun"			,"1.2"},
	{"X_DmgMultiplier_machine_guns"			,"1.5"},
	{"X_DmgMultiplier_fire_burn"			,"2.0"},// Any burn , this includes molotovs ,gas can ,fire.... 
	{"X_DmgMultiplier_explosion"			,"2.0"},// projectile of grenade launcher is excluded (it is controlled by another convar)
    {"X_DmgMultiplier_rifle_ak47"			,"1.2"},
    {"X_DmgMultiplier_rifle_sg552"			,"1.2"},
    {"X_DmgMultiplier_rifle_desert"			,"1.2"},
	{"X_DmgMultiplier_shotgun_spas"			,"1.2"},
    {"X_DmgMultiplier_shotgun_chrome"		,"1.2"},
    {"X_DmgMultiplier_smg_silenced"			,"1.2"},
    {"X_DmgMultiplier_smg_mp5"				,"1.2"},
	{"X_DmgMultiplier_sniper_awp"			,"1.2"},
    {"X_DmgMultiplier_sniper_military"		,"1.2"},
    {"X_DmgMultiplier_sniper_scout"			,"1.2"},
    {"X_DmgMultiplier_rifle_m60"			,"1.2"},
	{"X_DmgMultiplier_smg"					,"1.2"},
	{"X_DmgMultiplier_Knife"				,"1.2"},
    {"X_DmgMultiplier_baseball_bat"			,"1.2"},
	{"X_DmgMultiplier_katana"				,"1.2"},
    {"X_DmgMultiplier_tonfa"				,"1.2"},
    {"X_DmgMultiplier_shovel"				,"1.2"},
    {"X_DmgMultiplier_cricket_bat"			,"1.2"},
	{"X_DmgMultiplier_golfclub"				,"1.2"},
	{"X_DmgMultiplier_crowbar"				,"1.2"},
    {"X_DmgMultiplier_fireaxe"				,"1.2"},
	{"X_DmgMultiplier_frying_pan"			,"1.2"},
    {"X_DmgMultiplier_electric_guitar"		,"1.2"},
    {"X_DmgMultiplier_machete"				,"1.2"},
    {"X_DmgMultiplier_pitchfork"			,"1.2"},
	{"X_DmgMultiplier_grenade_launcher"		,"1.2"},
	{"X_DmgMultiplier_chainsaw"				,"1.2"}
};

public OnPluginStart()
{
	switch ( GetEngineVersion() )
	{
		case Engine_Left4Dead2 :
		{
			MAX = 36 ;
			X_DMG = ( (DMG_BULLET) | (DMG_SLOWBURN) | (DMG_PLASMA)| (DMG_AIRBOAT) | (DMG_DISSOLVE) );
		}
		
		case Engine_Left4Dead :
		{
			MAX = 9 ;
			X_DMG = DMG_BULLET;
		}
		
		default :	SetFailState("Made 4 L4D");
	}
	
	for (int i=0; i<MAX ; i++)
	{
		X_CVARS[i]=CreateConVar(X_Weapons[i][0], X_Weapons[i][1] ,_, FCVAR_NOTIFY, true ,0.0 ,true ,10.0);
	}
	AutoExecConfig(true, "XWeapons_DmgMultiplier");
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_WeaponSwitchPost , On_WeaponSwitch);
}

void On_WeaponSwitch(client , Weapon) 
{
	// return if (switch the same weapon) OR (while using Machine Gun) OR (Climbing a ladder)
	if ( X_Store[client][0] == Weapon || X_Store[client][2] || GetEntityMoveType(client) == MOVETYPE_LADDER) return;
	
	static char Weapon_Name[32];
	GetEdictClassname(Weapon , Weapon_Name , 32);
	
	ReplaceString(Weapon_Name ,32 , "weapon_" , "" , false);
	
	if ( !strncmp("melee",Weapon_Name,5,false) )
	{
		GetEntPropString(Weapon ,Prop_Data, "m_strMapSetScriptName", Weapon_Name, 32);
	}
	
	for (int i=0; i<MAX ; i++)
	{
		if ( !strncmp(X_Weapons[i][0][16],Weapon_Name,10,false) )
		{
			X_Store[client][1] = i;
			PrintToChat(client , "Server damage multiplier = %.2f ",GetConVarFloat(X_CVARS[i]));
			break;
		}
	}
	
	X_Store[client][0] = Weapon;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (HasEntProp(entity, Prop_Data, "m_takedamage"))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	if ( StrContains(classname, "mounted_machine_gun" , false)!=-1 || StrContains(classname, "prop_minigun" , false)!=-1 )
	{
		SDKHook(entity, SDKHook_Use, OnMachineGunOwned);
	}
}

void OnMachineGunOwned(gun, user)
{
	if (X_Store[user][2] == 0)
	{	
		X_Store[user][2] = gun;
		X_Store[user][1] = 6;
		PrintToChat(user , "Server damage multiplier = %.2f ",GetConVarFloat(X_CVARS[6]));
		CreateTimer(0.5 ,Timer_Check_Machine_Gun , user , TIMER_REPEAT);
	}
}

public Action Timer_Check_Machine_Gun(Handle Timer,any user)
{
	if ( IsClientInGame(user) )
	{
		if ( GetEntPropEnt(user, Prop_Send, "m_hUseEntity") != X_Store[user][2] )
		{
			X_Store[user][2] = 0;
			int temp = X_Store[user][0];
			X_Store[user][0] = 0;
			On_WeaponSwitch(user , temp);
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	
	X_Store[user][2] = 0;
	return Plugin_Stop;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, float &damage, &damagetype)
{
	if (damagetype & X_DMG )
	{
		damage *= GetConVarFloat( X_CVARS[ X_Store[attacker][1] ] );
		return Plugin_Changed;
	}
	if (damagetype & DMG_BURN )
	{
		damage *= GetConVarFloat( X_CVARS[ 7 ] );
		return Plugin_Changed;
	}
	if (damagetype & DMG_BLAST )
	{
		damage *= GetConVarFloat( X_CVARS[ 8 ] );
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}