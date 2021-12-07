#include <sourcemod>
#pragma semicolon 1
#include <tf2items>
#include <tf2_stocks>
#include <clientprefs>

bool hasAustralium[MAXPLAYERS+1];
Handle cHasAustralium;

#define PLUGIN_VERSION "1.0"
#define AUS_ATTRS "2027 ; 1 ; 2022 ; 1 ; 542 ; 1"
#define AUS_ATTRS_NEG "1 ; 0.0"

public Plugin myinfo = {
	name		= "[TF2] Australium Weapons",
	author		= "Nanochip",
	description = "Give yourself australium weapons!",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2445005"
};

public void OnPluginStart()
{
	CreateConVar("sm_australium_version", PLUGIN_VERSION, "Australium Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_australium", Cmd_Australium);
	
	HookEvent("post_inventory_application", OnResupply);
	
	cHasAustralium = RegClientCookie("sm_australium_cookie", "", CookieAccess_Private);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		hasAustralium[i] = false;
		if(IsClientInGame(i) && AreClientCookiesCached(i)) OnClientCookiesCached(i);
	}
}

public Action OnResupply(Handle event, char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, remwep);
}

public void OnClientAuthorized(client, const char[] auth)
{
	hasAustralium[client] = false;
}

public OnClientCookiesCached(client)
{
	char value[11];
	GetClientCookie(client, cHasAustralium, value, sizeof(value));
	if (StrEqual(value, "true"))
	{
		if (CheckCommandAccess(client, "sm_australium", 0, false))
		{
			hasAustralium[client] = true;
		}
		else
		{
			SetClientCookie(client, cHasAustralium, "false");
		}
	}
}

public void OnGameFrame()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || !IsPlayerAlive(client)) return;
		
		if (!hasAustralium[client])
		{
			if (IsAustralium(client, 0))
			{
				int ammo = GetAmmo(client, 0);
				int clip = GetClip(client, 0);
				switch (GetIndexOfWeaponSlot(client, 0))
				{
					case 200:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_scattergun", 13, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 45:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_scattergun", 45, 69, 6, "44 ; 1 ; 6 ; 0.5 ; 45 ; 1.2 ; 1 ; 0.9 ; 3 ; 0.34 ; 43 ; 1 ; 328 ; 1", "stock", false);
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 205:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_rocketlauncher", 18, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 228:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_rocketlauncher", 228, 69, 6, "741 ; 20 ; 3 ; 0.75 ; 328 ; 1", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 208:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_flamethrower", 21, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 206:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_grenadelauncher", 19, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 202:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_minigun", 15, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 424:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_minigun", 424, 69, 6, "87 ; 0.8 ; 238 ; 1 ; 5 ; 1.2 ; 106 ; 0.8", "stock", false);
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 141:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_sentry_revenge", 141, 69, 6, "136 ; 1 ; 15 ; 0 ; 3 ; 0.5 ; 551 ; 1", "stock", false);
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 36:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_syringegun_medic", 36, 69, 6, "16 ; 3 ; 129 ; -2", "stock", false);
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 201:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_sniperrifle", 14, 69, 6, "", "stock");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 61:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_revolver", 61, 69, 6, "51 ; 1 ; 1 ; 0.85 ; 5 ; 1.2 ; 15 ; 0", "stock", false);
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
				}
			}
			
			if (IsAustralium(client, 1))
			{
				int ammo = GetAmmo(client, 1);
				int clip = GetClip(client, 1);
				switch (GetIndexOfWeaponSlot(client, 1))
				{
					case 203:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_smg", 16, 69, 6, "", "stock");
						SetAmmo(client, ammo, 1);
						SetClip(client, clip, 1);
					}
					case 211:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_medigun", 29, 69, 6, "", "stock");
					}
					case 207:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_pipebomblauncher", 20, 69, 6, "", "stock");
						SetAmmo(client, ammo, 1);
						SetClip(client, clip, 1);
					}
				}
			}
			
			if (IsAustralium(client, 2))
			{
				switch (GetIndexOfWeaponSlot(client, 2))
				{
					case 38:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_fireaxe", 38, 69, 6, "209 ; 1 ; 1 ; 0.67 ; 15 ; 0 ; 773 ; 1.75 ; 5 ; 1.2", "stock", false);
					}
					case 194:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_knife", 4, 69, 6, "", "stock");
					}
					case 197:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_wrench", 7, 69, 6, "", "stock");
					}
					case 132:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_sword", 132, 69, 6, "781 ; 1 ; 15 ; 0 ; 125 ; -25 ; 219 ; 1 ; 292 ; 6 ; 388 ; 6 ; 551 ; 1", "stock", false);
					}
					case 1071:
					{
						TF2_RemoveWeaponSlot(client, 2);
						switch(TF2_GetPlayerClass(client))
						{
							case TFClass_Scout:		SpawnWeapon(client, "tf_weapon_bat", 0, 69, 6, "", "stock");
							case TFClass_Soldier:	SpawnWeapon(client, "tf_weapon_shovel", 6, 69, 6, "", "stock");
							case TFClass_Pyro:		SpawnWeapon(client, "tf_weapon_fireaxe", 2, 69, 6, "", "stock");
							case TFClass_DemoMan:	SpawnWeapon(client, "tf_weapon_bottle", 1, 69, 6, "", "stock");
							case TFClass_Heavy:		SpawnWeapon(client, "tf_weapon_fists", 5, 69, 6, "", "stock");
							case TFClass_Medic:		SpawnWeapon(client, "tf_weapon_bonesaw", 8, 69, 6, "", "stock");
							case TFClass_Sniper:	SpawnWeapon(client, "tf_weapon_club", 3, 69, 6, "", "stock");
						}
					}
				}
			}
		}
		
		else
		{
			if (!IsAustralium(client, 0))
			{
				int ammo = GetAmmo(client, 0);
				int clip = GetClip(client, 0);
				switch (GetIndexOfWeaponSlot(client, 0))
				{
					case 13:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_scattergun", 200, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 45:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_scattergun", 45, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 18:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_rocketlauncher", 205, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 228:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_rocketlauncher", 228, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 21:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_flamethrower", 208, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 19:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_grenadelauncher", 206, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 15:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_minigun", 202, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 424:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_minigun", 424, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 141:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_sentry_revenge", 141, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 36:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_syringegun_medic", 36, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 14:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_sniperrifle", 201, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
					case 61:
					{
						TF2_RemoveWeaponSlot(client, 0);
						SpawnWeapon(client, "tf_weapon_revolver", 61, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 0);
						SetClip(client, clip, 0);
					}
				}
			}
			
			if (!IsAustralium(client, 1))
			{
				int ammo = GetAmmo(client, 1);
				int clip = GetClip(client, 1);
				switch (GetIndexOfWeaponSlot(client, 1))
				{
					case 16:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_smg", 203, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 1);
						SetClip(client, clip, 1);
					}
					case 29:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_medigun", 211, 69, 6, AUS_ATTRS, "nano_australium");
					}
					case 20:
					{
						TF2_RemoveWeaponSlot(client, 1);
						SpawnWeapon(client, "tf_weapon_pipebomblauncher", 207, 69, 6, AUS_ATTRS, "nano_australium");
						SetAmmo(client, ammo, 1);
						SetClip(client, clip, 1);
					}
				}
			}
			
			if (!IsAustralium(client, 2))
			{
				switch (GetIndexOfWeaponSlot(client, 2))
				{
					case 38:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_fireaxe", 38, 69, 6, AUS_ATTRS, "nano_australium");
					}
					case 4:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_knife", 194, 69, 6, AUS_ATTRS, "nano_australium");
					}
					case 7:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_wrench", 197, 69, 6, AUS_ATTRS, "nano_australium");
					}
					case 132:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_sword", 132, 69, 6, AUS_ATTRS, "nano_australium");
					}
					case 0:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_bat", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 6:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_shovel", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 2:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_fireaxe", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 1:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_bottle", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 5:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_fists", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 8:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_bonesaw", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
					case 3:
					{
						TF2_RemoveWeaponSlot(client, 2);
						SpawnWeapon(client, "tf_weapon_club", 1071, 69, 6, "150 ; 1 ; 542 ; 0", "nano_australium");
					}
				}
			}
		}
	}
}

bool IsAustralium(int client, int slot)
{
	char strName[32];
	int weaponEnt = GetPlayerWeaponSlot(client, slot);
	if (!IsValidEdict(weaponEnt)) return false;
	GetEntPropString(weaponEnt, Prop_Data, "m_iName", strName, sizeof(strName));
	return StrEqual(strName, "nano_australium");
}

public Action Cmd_Australium(int client, int args)
{
	if (!hasAustralium[client])
	{
		hasAustralium[client] = true;
		SetClientCookie(client, cHasAustralium, "true");
		ReplyToCommand(client, "[SM] Enabled Australium Weapons.");
	}
	else
	{
		hasAustralium[client] = false;
		SetClientCookie(client, cHasAustralium, "false");
		ReplyToCommand(client, "[SM] Disabled Australium Weapons.");
	}
	return Plugin_Handled;
}

stock int GetClip(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	return GetEntData(weapon, iAmmoTable);
}

stock void SetClip(int client, int ammo, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	int iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, iAmmoTable, ammo, 4, true);
}

stock int GetAmmo(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	return GetEntData(client, iOffset + iAmmoTable);
}

stock void SetAmmo(int client, int ammo, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
	int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
	SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
}

stock SpawnWeapon(client, String:name[], index, level, qual, String:att[], String:targetname[], bool:preserve = true)
{
	int flags = OVERRIDE_ALL|FORCE_GENERATION;
	if (preserve)
	{
		flags |= PRESERVE_ATTRIBUTES;
	}
	new Handle:hWeapon=TF2Items_CreateItem(flags);
	if(hWeapon==INVALID_HANDLE)
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2;
		for(new i; i<count; i+=2)
		{
			new attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	new entity=TF2Items_GiveNamedItem(client, hWeapon);
	DispatchKeyValue(entity, "targetname", targetname);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(client, slot));
}
 
stock int GetWeaponIndex(int weapon)
{
    return IsValidEnt(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}
 
stock bool IsValidEnt(int ent)
{
    return ent > MaxClients && IsValidEntity(ent);
}

public Action remwep(Handle timer)
{
	int ent = FindEntityByClassname(-1, "tf_dropped_weapon");
	while (ent != -1)
	{
		RemoveEdict(ent);
		ent = FindEntityByClassname(-1, "tf_dropped_weapon");
	}
}