#pragma semicolon 1

#define PLUGIN_AUTHOR "DeathChaos25"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>


#define GRENADE_LAUNCHER	"models/w_models/weapons/w_grenade_launcher.mdl"
#define M60	                "models/w_models/weapons/w_m60.mdl"

static Handle:ShouldPickUp = INVALID_HANDLE;
static const GRENADE_LAUNCHER_OFFSET_IAMMO = 68;

new const String:sWeapons[15][] = 
{
	"models/w_models/weapons/w_shotgun.mdl", 
	"models/w_models/weapons/w_autoshot_m4super.mdl", 
	"models/w_models/weapons/w_smg_uzi.mdl", 
	"models/w_models/weapons/w_rifle_m16a2.mdl", 
	"models/w_models/weapons/w_smg_a.mdl", 
	"models/w_models/weapons/w_pumpshotgun_a.mdl", 
	"models/w_models/weapons/w_desert_rifle.mdl", 
	"models/w_models/weapons/w_shotgun_spas.mdl", 
	"models/w_models/weapons/w_rifle_ak47.mdl", 
	"models/w_models/weapons/w_smg_mp5.mdl", 
	"models/w_models/weapons/w_rifle_sg552.mdl", 
	"models/w_models/weapons/w_sniper_mini14.mdl", 
	"models/w_models/weapons/w_sniper_military.mdl", 
	"models/w_models/weapons/w_sniper_awp.mdl", 
	"models/w_models/weapons/w_sniper_scout.mdl"
};

public Plugin myinfo = 
{
	name = "[L4D2] Bots Pickup T3s", 
	author = PLUGIN_AUTHOR, 
	description = "Allows bots to use Tier 3 guns (Grenade Launchers and M60s)", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=262276"
};

public OnPluginStart()
{
	CreateConVar("sm_tier3_bots_version", PLUGIN_VERSION, "[L4D2] Tier 3 using bots Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	CreateTimer(5.0, CheckForWeapons, _, TIMER_REPEAT);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (entity <= 0 || entity > 2048 || classname[0] != 'w')return;
	CreateTimer(2.0, CheckEntityForGrab, entity);
}

public Action:CheckForWeapons(Handle:Timer)
{
	// trying to account for late loading and unexpected
	// or unreported weapons (stripper created weapons dont seem to fire OnEntityCreated)
	if (!IsServerProcessing())
	{
		return;
	}
	
	for (new entity = 0; entity < 2048; entity++)
	{
		if (!IsValidEntity(entity))
		{
			continue;
		}
		new String:modelname[128];
		new String:classname[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrEqual(modelname, GRENADE_LAUNCHER, false) || StrEqual(modelname, M60, false)
			 || StrEqual(classname, "weapon_rifle_m60_spawn", false)
			 || StrEqual(classname, "weapon_rifle_m60", false)
			 || StrEqual(classname, "weapon_grenade_launcher_spawn", false)
			 || StrEqual(classname, "weapon_grenade_launcher", false))
		{
			if (!IsT3Owned(entity))
			{
				for (new i = 0; i <= GetArraySize(ShouldPickUp) - 1; i++)
				{
					if (entity == GetArrayCell(ShouldPickUp, i))
					{
						return;
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
}

public Action:CheckEntityForGrab(Handle:timer, any:entity)
{
	if (IsValidEntity(entity) && ShouldPickUp != INVALID_HANDLE)
	{
		new String:modelname[128];
		new String:classname[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
		GetEntityClassname(entity, classname, sizeof(classname));
		if (StrEqual(modelname, GRENADE_LAUNCHER, false) || StrEqual(modelname, M60, false)
			 || StrEqual(classname, "weapon_rifle_m60_spawn", false)
			 || StrEqual(classname, "weapon_rifle_m60", false)
			 || StrEqual(classname, "weapon_grenade_launcher_spawn", false)
			 || StrEqual(classname, "weapon_grenade_launcher", false))
		{
			//PrintToChatAll("Weapon %s added to array!", modelname);
			PushArrayCell(ShouldPickUp, entity);
		}
	}
}


public OnEntityDestroyed(entity)
{
	if (entity <= 0 || entity > 2048)return;
	
	if (ShouldPickUp != INVALID_HANDLE)
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

public Action:L4D2_OnFindScavengeItem(client, &item)
{
	if (!item)
	{
		decl Float:Origin[3], Float:TOrigin[3];
		if (ShouldPickUp != INVALID_HANDLE)
		{
			for (new i = 0; i <= GetArraySize(ShouldPickUp) - 1; i++)
			{
				if(!IsValidEdict(i))
				{
					RemoveFromArray(ShouldPickUp, i);
					continue;
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
	
	else if (item > 0)
	{
		if (IsValidEdict(GetPlayerWeaponSlot(client, 0)))
		{
			new Primary = GetPlayerWeaponSlot(client, 0);
			new String:classname[128];
			GetEdictClassname(Primary, classname, sizeof(classname));
			
			if (StrEqual(classname, "weapon_rifle_m60"))
			{
				new String:modelname[128];
				GetEntPropString(item, Prop_Data, "m_ModelName", modelname, 128);
				new clip = GetEntProp(Primary, Prop_Send, "m_iClip1");
				new iPrimType = GetEntProp(Primary, Prop_Send, "m_iPrimaryAmmoType");
				new ammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, iPrimType);
				
				for (new i = 0; i <= 14; i++)
				{
					if (StrEqual(modelname, sWeapons[i]) && ammo+clip > 0)
					{
						return Plugin_Handled;
					}
				}
			}
			else if (StrEqual(classname, "weapon_grenade_launcher"))
			{
				new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
				new GLAmmo = GetEntData(client, iAmmoOffset + GRENADE_LAUNCHER_OFFSET_IAMMO);
				if (GLAmmo != 0)
				{
					new String:modelname[128];
					GetEntPropString(item, Prop_Data, "m_ModelName", modelname, 128);
					for (new i = 0; i <= 14; i++)
					{
						if (StrEqual(modelname, sWeapons[i]) && GLAmmo < 0)
						{
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock GetSafeEntityName(entity, String:TheName[], TheNameSize)
{
	if (entity > 0 && IsValidEntity(entity))
	{
		GetEntityClassname(entity, TheName, TheNameSize);
	}
	else
	{
		strcopy(TheName, TheNameSize, "Invalid");
	}
}

stock bool:IsT3Owned(weapon)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			if (GetPlayerWeaponSlot(i, 0) == weapon)
			{
				return true;
			}
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
	ShouldPickUp = INVALID_HANDLE;
}