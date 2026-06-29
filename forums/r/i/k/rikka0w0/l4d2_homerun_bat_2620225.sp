#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define DEBUG 0
#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define MODEL_SCALE_THRESHOLD 1.5

ConVar GunzWeapon;
ConVar RequireLargeMelee;
ConVar HomerunSurvivor;
ConVar HomerunTank;
ConVar RemoveDamage;
ConVar hForce;
ConVar vForce;

ConVar ForceOfBat;
ConVar ForceOfCri;
ConVar ForceOfBar;
ConVar ForceOfGui;
ConVar ForceOfAxe;
ConVar ForceOfPan;
ConVar ForceOfKat;
ConVar ForceOfMac;
ConVar ForceOfTon;
ConVar ForceOfKni;
ConVar ForceOfSld;
ConVar ForceOfClb;

public Plugin myinfo = 
{
	name = "[L4D2] Homerun Bat",
	author = "rikka0w0 & ztar",
	description = "Melee weapon causes nice Homerun. Original author homepage(Japanese): http://ztar.blog7.fc2.com/",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=311453"
}

public void OnPluginStart() 
{
	GunzWeapon		  = CreateConVar("l4d2_gunz_weapon","1", "Enable KS(?)", CVAR_FLAGS);
	RequireLargeMelee = CreateConVar("l4d2_homerun_largemelee", "0", "Only large weapon can smash the tank back", CVAR_FLAGS);
	HomerunSurvivor	  = CreateConVar("l4d2_homerun_survivor","1", "Are you Homerun king?", CVAR_FLAGS);
	HomerunTank		  = CreateConVar("l4d2_homerun_tank","1", "Are you Homerun king?", CVAR_FLAGS);
	RemoveDamage	  = CreateConVar("l4d2_removeffdamage","1", "Remove FF damage.", CVAR_FLAGS);
	hForce			  = CreateConVar("l4d2_smashrate_h","1.5", "Horizontal force rate", CVAR_FLAGS);
	vForce			  = CreateConVar("l4d2_smashrate_v","1.0", "Vertical force rate", CVAR_FLAGS);
	
	ForceOfBat = CreateConVar("l4d2_force_bat","350", "Swing force of your Baseball bat", CVAR_FLAGS);
	ForceOfCri = CreateConVar("l4d2_force_cri","280", "Swing force of your Cricket bat", CVAR_FLAGS);
	ForceOfBar = CreateConVar("l4d2_force_bar","250", "Swing force of your Crowbar", CVAR_FLAGS);
	ForceOfGui = CreateConVar("l4d2_force_gui","800", "Swing force of your Guitar", CVAR_FLAGS);
	ForceOfAxe = CreateConVar("l4d2_force_axe","260", "Swing force of your Fire axe", CVAR_FLAGS);
	ForceOfPan = CreateConVar("l4d2_force_pan","350", "Swing force of your Flying pan", CVAR_FLAGS);
	ForceOfKat = CreateConVar("l4d2_force_kat","210", "Swing force of your Katana", CVAR_FLAGS);
	ForceOfMac = CreateConVar("l4d2_force_mac","200", "Swing force of your Machete", CVAR_FLAGS);
	ForceOfTon = CreateConVar("l4d2_force_ton","240", "Swing force of your Tonfa", CVAR_FLAGS);
	ForceOfKni = CreateConVar("l4d2_force_kni","100", "Swing force of your Knife", CVAR_FLAGS);
	ForceOfSld = CreateConVar("l4d2_force_sld","230", "Swing force of your Shield", CVAR_FLAGS);
	ForceOfClb = CreateConVar("l4d2_force_clb","380", "Swing force of your golfclub", CVAR_FLAGS);
	
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("player_hurt", Event_Player_Hurt, EventHookMode_Pre);
	
	AutoExecConfig(true,"l4d2_homerun_bat");
}

public Action Event_Weapon_Fire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	char weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	
	/* Check current melee weapon */
	if(StrEqual(weapon, "melee") && GetConVarInt(GunzWeapon))
	{
		GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weapon, sizeof(weapon));
		if (StrEqual(weapon, "katana") ||
			StrEqual(weapon, "machete") ||
			StrEqual(weapon, "knife"))
		{
			if(!(GetEntityFlags(client) & FL_ONGROUND))
			{
				/* Slash! */
				Smash(client, client, 350.0, 2.0, -0.1);
			}
		}
	}
	return Plugin_Continue;
}

public Action Event_Player_Hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	float power = 200.0;
	char weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	
	/* Check current melee weapon */
	if(StrEqual(weapon, "melee"))
	{
		int weaponID = GetPlayerWeaponSlot(client, 1);	// Get player's melee weapon ID
		GetEntPropString(weaponID, Prop_Data, "m_strMapSetScriptName", weapon, sizeof(weapon));
		
		#if DEBUG
		PrintToChatAll("[DEBUG] Weapon name->%s = %f", weapon, modelScale);
		#endif
		
		/* return if HomerunTank is OFF */
		if(HomerunTank.IntValue == 0 && GetEntProp(target, Prop_Send, "m_zombieClass") == 8)
			return Plugin_Continue;
		
		/* return if HomerunSurvivor is OFF */
		if(HomerunSurvivor.IntValue == 0 && (GetClientTeam(client) == GetClientTeam(target)))
			return Plugin_Continue;
		
		float modelScale = GetEntPropFloat(weaponID, Prop_Data,"m_flModelScale");
		/* Not a large enough weapon!*/
		if (RequireLargeMelee.IntValue == 1 && modelScale <= MODEL_SCALE_THRESHOLD)
			return Plugin_Continue;
		
		/* remove FF damage */
		if(RemoveDamage.IntValue && (GetClientTeam(client) == GetClientTeam(target)))
			SetEntityHealth(target, (GetEventInt(event,"dmg_health")+ GetEventInt(event,"health")));
		
		/* Set Power */
		if(StrEqual(weapon, "baseball_bat")){
			power = ForceOfBat.FloatValue;
		}else if(StrEqual(weapon, "cricket_bat")){
			power = ForceOfCri.FloatValue;
		}else if(StrEqual(weapon, "crowbar")){
			power = ForceOfBar.FloatValue;
		}else if(StrEqual(weapon, "electric_guitar")){
			power = ForceOfGui.FloatValue;
		}else if(StrEqual(weapon, "fireaxe")){
			power = ForceOfAxe.FloatValue;
		}else if(StrEqual(weapon, "frying_pan")){
			power = ForceOfPan.FloatValue;
		}else if(StrEqual(weapon, "katana")){
			power = ForceOfKat.FloatValue;
		}else if(StrEqual(weapon, "machete")){
			power = ForceOfMac.FloatValue;
		}else if(StrEqual(weapon, "tonfa")){
			power = ForceOfTon.FloatValue;
		}else if(StrEqual(weapon, "knife")){
			power = ForceOfKni.FloatValue;
		}else if(StrEqual(weapon, "riot_shield")){
			power = ForceOfSld.FloatValue;
		}else if(StrEqual(weapon, "golfclub")){
			power = ForceOfClb.FloatValue;
		}
		
		/* Smash target */
		Smash(client, target, power, hForce.FloatValue,vForce.FloatValue);
	}
	return Plugin_Continue;
}

void Smash(int client, int target, float power, float powHor, float powVec)
{
	/* Smash target */
	float HeadingVector[3];
	float AimVector[3];
	GetClientEyeAngles(client, HeadingVector);
	
	AimVector[0] = FloatMul(Cosine(DegToRad(HeadingVector[1])), power * powHor);
	AimVector[1] = FloatMul(Sine(DegToRad(HeadingVector[1])), power * powHor);
	
	float current[3];
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
	
	float resulting[3];
	resulting[0] = FloatAdd(current[0], AimVector[0]);	
	resulting[1] = FloatAdd(current[1], AimVector[1]);
	resulting[2] = power * powVec;
	
	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
}
