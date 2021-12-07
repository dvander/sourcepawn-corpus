#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon		1

static Float:KnockBack;
// -= Handles =-
/*
new Handle:g_weapon_glock  = INVALID_HANDLE;
new Handle:g_weapon_p228  = INVALID_HANDLE;
new Handle:g_weapon_deagle  = INVALID_HANDLE;
new Handle:g_weapon_fiveseven  = INVALID_HANDLE;
new Handle:g_weapon_elite  = INVALID_HANDLE;
new Handle:g_weapon_m3  = INVALID_HANDLE;
new Handle:g_weapon_xm1014  = INVALID_HANDLE;
new Handle:g_weapon_tmp  = INVALID_HANDLE;
new Handle:g_weapon_mac10  = INVALID_HANDLE;
new Handle:g_weapon_ump45  = INVALID_HANDLE;
new Handle:g_weapon_mp5navy  = INVALID_HANDLE;
new Handle:g_weapon_p90  = INVALID_HANDLE;
new Handle:g_weapon_galil  = INVALID_HANDLE;
new Handle:g_weapon_ak47  = INVALID_HANDLE;
*/
new Handle:g_weapon_m4a1  = INVALID_HANDLE;
/*
new Handle:g_weapon_aug  = INVALID_HANDLE;
new Handle:g_weapon_sg552  = INVALID_HANDLE;
new Handle:g_weapon_m249  = INVALID_HANDLE;
new Handle:g_weapon_scout  = INVALID_HANDLE;
new Handle:g_weapon_awp  = INVALID_HANDLE;
new Handle:g_weapon_sg550  = INVALID_HANDLE;
new Handle:g_weapon_g3sg1  = INVALID_HANDLE;
*/
// -= Floats =-
/*
new Float:h_weapon_glock;
new Float:h_weapon_p228;
new Float:h_weapon_deagle;
new Float:h_weapon_fiveseven;
new Float:h_weapon_elite;
new Float:h_weapon_m3;
new Float:h_weapon_xm1014;
new Float:h_weapon_tmp;
new Float:h_weapon_mac10;
new Float:h_weapon_ump45;
new Float:h_weapon_mp5navy;
new Float:h_weapon_p90;
new Float:h_weapon_galil;
new Float:h_weapon_ak47;
*/
new Float:h_weapon_m4a1;
/*
new Float:h_weapon_aug;
new Float:h_weapon_sg552;
new Float:h_weapon_m249;
new Float:h_weapon_scout;
new Float:h_weapon_awp;
new Float:h_weapon_sg550;
new Float:h_weapon_g3sg1;
*/

public OnPluginStart()
{
/*
	g_weapon_glock = CreateConVar("zps_glock_knockback_strength", "120.0", "Forca");
	g_weapon_p228 = CreateConVar("zps_p228_knockback_strength", "120.0", "Forca");
	g_weapon_deagle = CreateConVar("zps_deagle_knockback_strength", "120.0", "Forca");
	g_weapon_fiveseven = CreateConVar("zps_fiveseven_knockback_strength", "120.0", "Forca");
	g_weapon_elite = CreateConVar("zps_elite_knockback_strength", "120.0", "Forca");
	g_weapon_m3 = CreateConVar("zps_m3_knockback_strength", "120.0", "Forca");
	g_weapon_xm1014 = CreateConVar("zps_xm1014_knockback_strength", "120.0", "Forca");
	g_weapon_tmp = CreateConVar("zps_tmp_knockback_strength", "120.0", "Forca");
	g_weapon_mac10 = CreateConVar("zps_mac10_knockback_strength", "120.0", "Forca");
	g_weapon_ump45 = CreateConVar("zps_ump45_knockback_strength", "120.0", "Forca");
	g_weapon_mp5navy = CreateConVar("zps_mp5navy_knockback_strength", "120.0", "Forca");
	g_weapon_p90 = CreateConVar("zps_p90_knockback_strength", "120.0", "Forca");
	g_weapon_galil = CreateConVar("zps_galil_knockback_strength", "120.0", "Forca");
	g_weapon_ak47 = CreateConVar("zps_ak47_knockback_strength", "120.0", "Forca");
*/
	g_weapon_m4a1 = CreateConVar("zps_m4a1_knockback_strength", "120.0", "Forca");
/*
	g_weapon_aug = CreateConVar("zps_aug_knockback_strength", "120.0", "Forca");
	g_weapon_sg552 = CreateConVar("zps_sg552_knockback_strength", "120.0", "Forca");
	g_weapon_m249 = CreateConVar("zps_m249_knockback_strength", "120.0", "Forca");
	g_weapon_scout = CreateConVar("zps_scout_knockback_strength", "120.0", "Forca");
	g_weapon_awp = CreateConVar("zps_awp_knockback_strength", "120.0", "Forca");
	g_weapon_sg550 = CreateConVar("zps_sg550_knockback_strength", "120.0", "Forca");
	g_weapon_g3sg1 = CreateConVar("zps_g3sg1_knockback_strength", "120.0", "Forca");
*/
	AutoExecConfig(true, "zps_knockback");
/*
	h_weapon_glock = GetConVarFloat(g_weapon_glock);
	HookConVarChange(g_weapon_glock, OnConVarChanged);
	h_weapon_p228 = GetConVarFloat(g_weapon_p228);
	HookConVarChange(g_weapon_p228, OnConVarChanged);
	h_weapon_deagle = GetConVarFloat(g_weapon_deagle);
	HookConVarChange(g_weapon_deagle, OnConVarChanged);
	h_weapon_fiveseven = GetConVarFloat(g_weapon_fiveseven);
	HookConVarChange(g_weapon_fiveseven, OnConVarChanged);
	h_weapon_elite = GetConVarFloat(g_weapon_elite);
	HookConVarChange(g_weapon_elite, OnConVarChanged);
	h_weapon_m3 = GetConVarFloat(g_weapon_m3);
	HookConVarChange(g_weapon_m3, OnConVarChanged);
	h_weapon_xm1014 = GetConVarFloat(g_weapon_xm1014);
	HookConVarChange(g_weapon_xm1014, OnConVarChanged);
	h_weapon_tmp = GetConVarFloat(g_weapon_tmp);
	HookConVarChange(g_weapon_tmp, OnConVarChanged);
	h_weapon_mac10 = GetConVarFloat(g_weapon_mac10);
	HookConVarChange(g_weapon_mac10, OnConVarChanged);
	h_weapon_ump45 = GetConVarFloat(g_weapon_ump45);
	HookConVarChange(g_weapon_ump45, OnConVarChanged);
	h_weapon_mp5navy = GetConVarFloat(g_weapon_mp5navy);
	HookConVarChange(g_weapon_mp5navy, OnConVarChanged);
	h_weapon_p90 = GetConVarFloat(g_weapon_p90);
	HookConVarChange(g_weapon_p90, OnConVarChanged);
	h_weapon_galil = GetConVarFloat(g_weapon_galil);
	HookConVarChange(g_weapon_galil, OnConVarChanged);
	h_weapon_ak47 = GetConVarFloat(g_weapon_ak47);
	HookConVarChange(g_weapon_ak47, OnConVarChanged);
*/
	h_weapon_m4a1 = GetConVarFloat(g_weapon_m4a1);
	HookConVarChange(g_weapon_m4a1, OnConVarChanged);
/*
	h_weapon_aug = GetConVarFloat(g_weapon_aug);
	HookConVarChange(g_weapon_aug, OnConVarChanged);
	h_weapon_sg552 = GetConVarFloat(g_weapon_sg552);
	HookConVarChange(g_weapon_sg552, OnConVarChanged);
	h_weapon_m249 = GetConVarFloat(g_weapon_m249);
	HookConVarChange(g_weapon_m249, OnConVarChanged);
	h_weapon_scout = GetConVarFloat(g_weapon_scout);
	HookConVarChange(g_weapon_scout, OnConVarChanged);
	h_weapon_awp = GetConVarFloat(g_weapon_awp);
	HookConVarChange(g_weapon_awp, OnConVarChanged);
	h_weapon_sg550 = GetConVarFloat(g_weapon_sg550);
	HookConVarChange(g_weapon_sg550, OnConVarChanged);
	h_weapon_g3sg1 = GetConVarFloat(g_weapon_g3sg1);
	HookConVarChange(g_weapon_g3sg1, OnConVarChanged);
*/
	HookEvent("player_hurt", OnPlayerHurt);
}

public OnMapStart()
{
	KnockBack = 5.0;
}

public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
/*
	if (convar == g_weapon_glock)
	{
		h_weapon_glock = StringToFloat(newValue);
	}
	else if (convar == g_weapon_p228)
	{
		h_weapon_p228 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_deagle)
	{
		h_weapon_deagle = StringToFloat(newValue);
	}
	else if (convar == g_weapon_fiveseven)
	{
		h_weapon_fiveseven = StringToFloat(newValue);
	}
	else if (convar == g_weapon_elite)
	{
		h_weapon_elite = StringToFloat(newValue);
	}
	else if (convar == g_weapon_m3)
	{
		h_weapon_m3 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_xm1014)
	{
		h_weapon_xm1014 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_tmp)
	{
		h_weapon_tmp = StringToFloat(newValue);
	}
	else if (convar == g_weapon_mac10)
	{
		h_weapon_mac10 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_ump45)
	{
		h_weapon_ump45 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_mp5navy)
	{
		h_weapon_mp5navy = StringToFloat(newValue);
	}
	else if (convar == g_weapon_p90)
	{
		h_weapon_p90 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_galil)
	{
		h_weapon_galil = StringToFloat(newValue);
	}
	else if (convar == g_weapon_ak47)
	{
		h_weapon_ak47 = StringToFloat(newValue);
	}
*/
	if (convar == g_weapon_m4a1)
	{
		h_weapon_m4a1 = StringToFloat(newValue);
	}
/*
	else if (convar == g_weapon_aug)
	{
		h_weapon_aug = StringToFloat(newValue);
	}
	else if (convar == g_weapon_sg552)
	{
		h_weapon_sg552 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_m249)
	{
		h_weapon_m249 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_scout)
	{
		h_weapon_scout = StringToFloat(newValue);
	}
	else if (convar == g_weapon_awp)
	{
		h_weapon_awp = StringToFloat(newValue);
	}
	else if (convar == g_weapon_sg550)
	{
		h_weapon_sg550 = StringToFloat(newValue);
	}
	else if (convar == g_weapon_g3sg1)
	{
		h_weapon_g3sg1 = StringToFloat(newValue);
	}
*/
}

public Action:OnPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	//Is Player:
	if(attacker != Client && Client != 0 && attacker != 0 && Client > 0 && Client < MaxClients && attacker > 0 && attacker < MaxClients)
	{

		//Create Knock Back:
		InstantKnockBack(Client, attacker);
	}

	//Return:
	return Plugin_Continue;
}
/*
public Action:OnTakeDamage(Client, &attacker, &inflictor, &weapon)
{

	//Is Player:
	if(attacker != Client && Client != 0 && attacker != 0 && Client > 0 && Client < MaxClients && attacker > 0 && attacker < MaxClients)
	{

		//Create Knock Back:
		InstantKnockBack(Client, attacker, weapon);
	}

	//Return:
	return Plugin_Continue;
}
*/
public Action:InstantKnockBack(Client, attacker)
{

	//Initulize:
	CreateKnockBack(Client, attacker);

	//Return:
	return Plugin_Continue;
}

stock Float:CreateKnockBack(Client, attacker)
{

	//Delare:
  	decl Float:EyeAngles[3],Float:Push[3];

	//Initialize:
  	GetClientEyeAngles(Client, EyeAngles);
	new String:weaponname[32];
	GetClientWeapon(Client, weaponname, sizeof(weaponname));
	if (StrEqual(weaponname, "weapon_m4a1", true))
	{
		Push[0] = (FloatMul(h_weapon_m4a1 - h_weapon_m4a1 - h_weapon_m4a1, Cosine(DegToRad(EyeAngles[1]))));

		Push[1] = (FloatMul(h_weapon_m4a1 - h_weapon_m4a1 - h_weapon_m4a1, Sine(DegToRad(EyeAngles[1]))));

		Push[2] = (FloatMul(-50.0, Sine(DegToRad(EyeAngles[0]))));

		//Multiply
		ScaleVector(Push, KnockBack);

		//Teleport:
		TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, Push);
	}
} 