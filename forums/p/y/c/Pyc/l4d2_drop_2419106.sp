#define PLUGIN_VERSION "1.6.0"
	
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>	

#pragma semicolon 						1

#pragma newdecls required
 
char WeaponNames[][] =
{
	"weapon_pumpshotgun",
	"weapon_autoshotgun",
	"weapon_rifle",
	"weapon_smg",
	"weapon_hunting_rifle",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_grenade_launcher",
	"weapon_rifle_m60", //0-16
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_chainsaw",
	"weapon_melee", //17-20
	"weapon_pipe_bomb",
	"weapon_molotov",
	"weapon_vomitjar", //21-23
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary", //24-27
	"weapon_pain_pills",
	"weapon_adrenaline", //28-29
	"weapon_gascan",
	"weapon_propanetank",
	"weapon_oxygentank",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_fireworkcrate" //30-35
};
	
int MODEL_DEFIB;

public Plugin myinfo =
{
	name = "[L4D2] Weapon Drop",
	author = "Machine, dcx2, Electro",
	description = "Allows players to drop the weapon they are holding",
	version = PLUGIN_VERSION,
	url = "forums.alliedmods.net"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegConsoleCmd("sm_drop", Command_Drop);
	
	CreateConVar("sm_drop_version", PLUGIN_VERSION, "[L4D2] Weapon Drop Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public void OnMapStart()
{
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);
}

public Action Command_Drop(int client, int args)
{
	if (args == 1 || args > 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
			ReplyToCommand(client, "[SM] Usage: sm_drop <#userid|name> <slot to drop>");
	}
	else if (args < 1)
	{
		int slot;
		char weapon[32];
		GetClientWeapon(client, weapon, sizeof(weapon));
		for (int count=0; count<=35; count++)
		{
			switch(count)
			{
				case 17: slot = 1;
				case 21: slot = 2;
				case 24: slot = 3;
				case 28: slot = 4;
				case 30: slot = 5;
			}
			if (StrEqual(weapon, WeaponNames[count]))
			{
				DropSlot(client, slot, true);
			}
		}
	}
	else if (args == 2)
	{
		if (GetAdminFlag(GetUserAdmin(client), Admin_Root))
		{
			char target[MAX_TARGET_LENGTH], arg[8];
			GetCmdArg(1, target, sizeof(target));
			GetCmdArg(2, arg, sizeof(arg));
			int slot = StringToInt(arg);

			int targetid = StringToInt(target);
			if (targetid > 0 && IsClientInGame(targetid))
			{
				DropSlot(targetid, slot, true);
				return Plugin_Handled;
			}

			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
	
			if ((target_count = ProcessTargetString(
				target,
				client,
				target_list,
				MAXPLAYERS,
				0,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for (int i=0; i<target_count; i++)
			{
				DropSlot(target_list[i], slot, true);
			}
		}
	}

	return Plugin_Handled;
}

void DropSlot(int client, int slot, bool away)
{
	if (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		
// enable drop for 2nd slot (pistol, melee)
		if (weapon > 0 && IsValidEntity(weapon)) // && slot != 1)
		{
			CallWeaponDrop(client, weapon, slot, away);
		}
	}
}

void CallWeaponDrop(int client, int weapon, int slot, bool away)
{		
	float vecTarget[3];
	if (GetPlayerEye(client, vecTarget))
	{
// add check slot for grenades
		if (slot == 2)
		{
// and enable slow drop only grenade for fix spamming
			if (GetEntPropFloat(weapon,Prop_Data,"m_flNextPrimaryAttack") >= GetGameTime())
			{
				return;
			}
		}
		
		float vecAngles[3], vecVelocity[3]; 
		GetClientEyeAngles(client, vecAngles);
		
		GetAngleVectors(vecAngles, vecVelocity, NULL_VECTOR, NULL_VECTOR);

		vecVelocity[0] *= 300.0;
		vecVelocity[1] *= 300.0;
		vecVelocity[2] *= 300.0;
		
		SetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", -1);
		ChangeEdictState(client, FindDataMapOffs(client, "m_hActiveWeapon"));
		
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
		
		if (away)
		{
			TeleportEntity(weapon, NULL_VECTOR, NULL_VECTOR, vecVelocity);
		}
		
		char classname[32];
		GetEdictClassname(weapon, classname, sizeof(classname));
		if (StrEqual(classname,"weapon_defibrillator"))
		{
			SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", MODEL_DEFIB);
		}
	}
}

bool GetPlayerEye(int client, float vecTarget[3]) 
{
	float Origin[3], Angles[3];
	GetClientEyePosition(client, Origin);
	GetClientEyeAngles(client, Angles);

	Handle trace = TR_TraceRayFilterEx(Origin, Angles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(trace)) 
	{
		TR_GetEndPosition(vecTarget, trace);
		CloseHandle(trace);
		return true;
	}
	
	CloseHandle(trace);
	return false;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > GetMaxClients() || !entity;
}
