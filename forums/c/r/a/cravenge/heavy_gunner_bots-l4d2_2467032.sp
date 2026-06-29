#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.1"

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static Handle:ShouldPickUp = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Heavy Gunner Bots", 
	author = PLUGIN_AUTHOR, 
	description = "Makes Bots Use Heavy Guns With Heavy Damages.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=262276"
};

public OnPluginStart()
{
	CreateConVar("heavy_gunner_bots-l4d2_version", PLUGIN_VERSION, "Heavy Gunner Bots Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > 2048 || classname[0] != 'w' || classname[1] != 'e' || classname[2] != 'a')
	{
		return;
	}
	
	CreateTimer(2.0, CheckEntityForGrab, entity);
}

public Action:CheckEntityForGrab(Handle:timer, any:entity)
{
	if (!IsValidEntity(entity))
	{
		return Plugin_Stop;
	}
	
	decl String:classname[128];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "weapon_", false) != -1)
	{
		if (IsMLauncher(entity) && ShouldPickUp != INVALID_HANDLE)
		{
			if (!IsT3Owned(entity))
			{
				for (new i = 0; i <= GetArraySize(ShouldPickUp) - 1; i++)
				{
					if (entity == GetArrayCell(ShouldPickUp, i))
					{
						return Plugin_Stop;
					}
					else if (!IsValidEntity(GetArrayCell(ShouldPickUp, i)))
					{
						RemoveFromArray(ShouldPickUp, i);
					}
				}
				PushArrayCell(ShouldPickUp, entity);
			}
		}
	}
	
	return Plugin_Stop;
}

public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > 2048)
	{
		return;
	}
	
	if (IsMLauncher(entity) && ShouldPickUp != INVALID_HANDLE)
	{
		if (!IsT3Owned(entity))
		{
			for (new i = 0; i <= GetArraySize(ShouldPickUp) - 1; i++)
			{
				if (entity == GetArrayCell(ShouldPickUp, i))
				{
					RemoveFromArray(ShouldPickUp, i);
				}
			}
		}
	}
}

public Action:L4D2_OnFindScavengeItem(client, &item)
{
	if (!item)
	{
		decl Float:Origin[3], Float:TOrigin[3];
		new iWeapon = GetPlayerWeaponSlot(client, 0);
		if (!IsValidEdict(iWeapon) || !HaveEnoughAmmo(client, iWeapon) || UsingT1(client, iWeapon))
		{
			for (new i = 0; i <= GetArraySize(ShouldPickUp) - 1; i++)
			{
				if (!IsValidEntity(GetArrayCell(ShouldPickUp, i)))
				{
					return Plugin_Continue;
				}
				
				decl String:waClass[64];
				GetEntityClassname(GetArrayCell(ShouldPickUp, i), waClass, sizeof(waClass));
				if (StrEqual(waClass, "predicted_viewmodel") || StrContains(waClass, "scene") != -1 || StrContains(waClass, "ability") != -1)
				{
					return Plugin_Continue;
				}
				
				GetEntPropVector(GetArrayCell(ShouldPickUp, i), Prop_Send, "m_vecOrigin", Origin);
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", TOrigin);
				new Float:distance = GetVectorDistance(TOrigin, Origin);
				if (distance < 300)
				{
					item = GetArrayCell(ShouldPickUp, i);
					return Plugin_Changed;
				}
			}
		}
	}
	else if (IsMLauncher(item))
	{
		new PrimWeapon = GetPlayerWeaponSlot(client, 0);
		if (PrimWeapon > 0 && IsValidEntity(PrimWeapon) && IsValidEdict(PrimWeapon))
		{
			if (HaveEnoughAmmo(client, PrimWeapon))
			{
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

stock bool:IsMLauncher(entity)
{
	if (entity > 0 || entity < 2048)
	{
		decl String:classname[128];
		decl String:modelname[128];
		if (IsValidEntity(entity))
		{
			GetEntityClassname(entity, classname, 128);
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(classname, "weapon_grenade_launcher") || StrEqual(classname, "weapon_grenade_launcher_spawn") || StrEqual(classname, "weapon_rifle_m60") || StrEqual(classname, "weapon_rifle_m60_spawn") || StrEqual(modelname, "models/w_models/weapons/w_grenade_launcher.mdl") || StrEqual(modelname, "models/w_models/weapons/w_m60.mdl"))
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:IsT3Owned(weapon)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			if (GetPlayerWeaponSlot(i, 0) == weapon)
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:HaveEnoughAmmo(client, weapon)
{
	if (weapon > 0 && IsValidEntity(weapon) && IsValidEdict(weapon))
	{
		new iPrimType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iPrimType);
		if (!IsMLauncher(weapon) && ammo > 10)
		{
			return true;
		}
	}
	return false;
}

stock bool:UsingT1(client, weapon)
{
	if (weapon > 0 && IsValidEntity(weapon) && IsValidEdict(weapon))
	{
		decl String:classname[128], String:modelname[128];
		
		GetEntityClassname(weapon, classname, 128);
		GetEntPropString(weapon, Prop_Data, "m_ModelName", modelname, 128);
		
		if (StrContains(classname, "smg", false) != -1 || StrContains(classname, "pumpshotgun", false) != -1 || StrContains(classname, "shotgun_chrome", false) != -1 || StrContains(modelname, "smg", false) != -1 || StrEqual(modelname, "models/w_models/weapons/w_shotgun.mdl") || StrEqual(modelname, "models/w_models/weapons/w_pumpshotgun_a.mdl"))
		{
			return true;
		}
	}
	return false;
}

stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
} 

public OnMapStart()
{
	ShouldPickUp = CreateArray();
}

public OnMapEnd()
{
	CloseHandle(ShouldPickUp);
	ShouldPickUp = INVALID_HANDLE;
}

