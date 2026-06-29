#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <smlib>

#define DMG_GENERIC 0
new bool:BeingShot[2048] = {false, false, false, ...};
new GunOwner[2048];
new Handle:WeaponTimer[2048] = {INVALID_HANDLE, INVALID_HANDLE, INVALID_HANDLE, ...};

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropPost);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public OnWeaponDropPost(client, weapon)
{
	if(weapon <= 0 || !IsValidEntity(weapon) || !IsValidEdict(weapon) || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}
	decl String:weapon_name[32];
	GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
	if(StrContains(weapon_name, "glock", false) != -1 || 
	StrContains(weapon_name, "deagle", false) != -1 || 
	StrContains(weapon_name, "usp", false) != -1 ||
	StrContains(weapon_name, "p228", false) != -1 || 
	StrContains(weapon_name, "elite", false) != -1 || 
	StrContains(weapon_name, "fiveseven", false) != -1
	)
	{
		new Float:ang[3], Float:vec[3], Float:pos[3];
		GetClientEyeAngles(client, ang);
		GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec, vec);
		ScaleVector(vec, 2000.0); //Change this value to increase/decrease the throwing force.
		GetClientEyePosition(client, pos);
		TeleportEntity(weapon, pos, ang, vec);
		BeingShot[weapon] = true;
		GunOwner[weapon] = client;
		SDKHook(weapon, SDKHook_StartTouchPost, OnTouch);
	}
} 

public Action:OnWeaponCanUse(client, weapon)
{
    if (BeingShot[weapon])
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}  

public OnTouch(entity, client)
{
	if(client > 0 && client <= MaxClients && BeingShot[entity] && GetClientTeam(client) != GetClientTeam(GunOwner[entity]))
	{
		new Float:vel[3], Float:velTwo[3];
		Entity_GetAbsVelocity(entity, vel);
		velTwo[0] = vel[0]/10.0;
		velTwo[1] = vel[1]/10.0;
		velTwo[2] = vel[2]/10.0;
		Entity_SetAbsVelocity(entity, velTwo);
		if(vel[0] < 0)
		{
			vel[0] *= -1.0;
		}
		if(vel[1] < 0)
		{
			vel[1] *= -1.0;
		}
		if(vel[2] < 0)
		{
			vel[2] *= -1.0;
		}
		new String:classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		new damage = RoundFloat((vel[0] + vel[1] + vel[2])/100.0); //The damage is based in the velocity of the weapon. To increase the damage done you can change the velocity or decrease the number 100.0 at this line. The opposite is true.
		DealDamage(client, damage, GunOwner[entity], DMG_GENERIC, classname);
		PrintHintText(GunOwner[entity], "Damage: %i", damage);
		if(WeaponTimer[entity] != INVALID_HANDLE)
		{
			KillTimer(WeaponTimer[entity])
			WeaponTimer[entity] = INVALID_HANDLE;
		}
		BeingShot[entity] = false;
		SDKUnhook(entity, SDKHook_StartTouchPost, OnTouch);
	}
	WeaponTimer[entity] = CreateTimer(3.0, TurnWeaponNormal, entity);
}

public Action:TurnWeaponNormal(Handle:timer, any:weapon)
{
	BeingShot[weapon] = false;
	WeaponTimer[weapon] = INVALID_HANDLE;
}


DealDamage(victim,damage,attacker=0,dmg_type=DMG_GENERIC,String:weapon[]="") // function by pimpinjuice.
{
	if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
	{
		new String:dmg_str[16];
		IntToString(damage,dmg_str,16);
		new String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			DispatchKeyValue(victim,"targetname","war3_hurtme");
			DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
			DispatchKeyValue(pointHurt,"Damage",dmg_str);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			if(!StrEqual(weapon,""))
			{
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