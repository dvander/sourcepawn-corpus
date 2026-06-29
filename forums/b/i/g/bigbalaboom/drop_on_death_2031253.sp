#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "3.0.0"

new Handle:g_Cvar_DropOnDeath = INVALID_HANDLE;
new Handle:g_Cvar_DropKnife = INVALID_HANDLE;
new Handle:g_Cvar_DropAmmo = INVALID_HANDLE;
new Handle:g_Cvar_AmmoSound = INVALID_HANDLE;
new Handle:g_Cvar_DropArmor = INVALID_HANDLE;
new Handle:g_Cvar_ArmorMin = INVALID_HANDLE;
new Handle:g_Cvar_ArmorDepreciation = INVALID_HANDLE;
new Handle:g_Cvar_ArmorSprite = INVALID_HANDLE;
new Handle:g_Cvar_ArmorModel = INVALID_HANDLE;
new Handle:g_Cvar_ArmorResize = INVALID_HANDLE;
new Handle:g_Cvar_ArmorOffset = INVALID_HANDLE;
new Handle:g_Cvar_ArmorSound = INVALID_HANDLE;
new Handle:g_Cvar_ArmorRemove = INVALID_HANDLE;

new String:g_SoundAmmo[512];
new String:g_SpriteArmor[] = "sprites/blueglow1.vmt";
new String:g_ModelArmor[512];
new String:g_SoundArmor[512];

new g_ArmorSprites[MAXPLAYERS + 1] = {-1, ...};
new g_ArmorModels[MAXPLAYERS + 1] = {-1, ...};
new g_ArmorValues[MAXPLAYERS + 1] = {0, ...};

new g_AmmoOffset = -1;
new g_GroundAmmoOffset = -1;

new String:g_Weapons[24][] = 
{
	"weapon_glock", "weapon_usp", "weapon_p228", "weapon_deagle", "weapon_elite", "weapon_fiveseven",
	"weapon_m3", "weapon_xm1014",
	"weapon_mac10", "weapon_mp5navy", "weapon_p90", "weapon_ump45", "weapon_tmp",
	"weapon_galil", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_sg552", "weapon_aug",
	"weapon_g3sg1", "weapon_sg550", "weapon_awp", "weapon_scout",
	"weapon_m249"
};

new g_WeaponCaps[24] = 
{
	120, 100, 52, 35, 120, 100,
	32, 32,
	100, 120, 100, 100, 120,
	90, 90, 90, 90, 90, 90,
	90, 90, 30, 90,
	200
};

public Plugin:myinfo =
{
	name = "Drop On Death",
	author = "bigbalaboom",
	description = "Drop weapons, ammo, and armor on death.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_drop_on_death_version", PLUGIN_VERSION, "Drop On Death Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_DropOnDeath = CreateConVar("sm_drop_on_death", "1", "Toggles plugin on and off.", FCVAR_PLUGIN);
	g_Cvar_DropKnife = CreateConVar("sm_drop_knife_on_death", "0", "Toggles dropping knife on death.", FCVAR_PLUGIN);
	g_Cvar_DropAmmo = CreateConVar("sm_drop_ammo_on_death", "1", "Toggles dropping ammo on death.", FCVAR_PLUGIN);
	g_Cvar_AmmoSound = CreateConVar("sm_drop_ammo_pickup_sound", "items/itempickup.wav", "Sound used for picking up ammo.", FCVAR_PLUGIN);
	g_Cvar_DropArmor = CreateConVar("sm_drop_armor_on_death", "1", "Toggles dropping armor on death.", FCVAR_PLUGIN);
	g_Cvar_ArmorMin = CreateConVar("sm_drop_armor_min", "10", "Minimum amount of armor to enable armor drop.", FCVAR_PLUGIN);
	g_Cvar_ArmorDepreciation = CreateConVar("sm_drop_armor_depreciation", "0.6", "Percentage of depreciation for dropped armor.", FCVAR_PLUGIN);
	g_Cvar_ArmorSprite = CreateConVar("sm_drop_armor_sprite", "1", "Toggles sprite and physical model for dropped armor.", FCVAR_PLUGIN);
	g_Cvar_ArmorModel = CreateConVar("sm_drop_armor_model", "models/props/cs_italy/orange.mdl", "Model used for dropped armor.", FCVAR_PLUGIN);
	g_Cvar_ArmorResize = CreateConVar("sm_drop_armor_model_resize", "1.0", "Size of model to be scaled.", FCVAR_PLUGIN);
	g_Cvar_ArmorOffset = CreateConVar("sm_drop_armor_model_voffset", "0.0", "Vertical offset of armor model.", FCVAR_PLUGIN);
	g_Cvar_ArmorSound = CreateConVar("sm_drop_armor_pickup_sound", "items/ammopickup.wav", "Sound used for picking up armor.", FCVAR_PLUGIN);
	g_Cvar_ArmorRemove = CreateConVar("sm_drop_armor_respawn_remove", "0", "Toggles removing dropped armor on resapwn.", FCVAR_PLUGIN);

	AutoExecConfig(true, "drop_on_death");

	HookConVarChange(g_Cvar_DropOnDeath, OnConVarChange);
	HookConVarChange(g_Cvar_AmmoSound, OnConVarChange);
	HookConVarChange(g_Cvar_DropArmor, OnConVarChange);
	HookConVarChange(g_Cvar_ArmorModel, OnConVarChange);
	HookConVarChange(g_Cvar_ArmorSound, OnConVarChange);

	g_AmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_GroundAmmoOffset = FindSendPropInfo("CWeaponCSBase", "m_fAccuracyPenalty");

	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_Kill, "explode");

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_Touch, OnTouch);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
}

public OnConfigsExecuted()
{
	PrecacheModel(g_SpriteArmor);
	GetConVars();
}

public OnConVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	decl String:CvarName[64];
	GetConVarName(cvar, CvarName, sizeof(CvarName));

	if (StrEqual(CvarName, "sm_drop_ammo_pickup_sound") || StrEqual(CvarName, "sm_drop_armor_model") || StrEqual(CvarName, "sm_drop_armor_pickup_sound"))
	{
		GetConVars();
	}
	else if (GetConVarInt(g_Cvar_DropOnDeath) && GetConVarInt(g_Cvar_DropArmor) && StrEqual(newvalue, "0"))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			RemoveEntities(i);
		}
	}
}

GetConVars()
{
	GetConVarString(g_Cvar_AmmoSound, g_SoundAmmo, 512);
	GetConVarString(g_Cvar_ArmorModel, g_ModelArmor, 512);
	GetConVarString(g_Cvar_ArmorSound, g_SoundArmor, 512);

	if (!StrEqual(g_SoundAmmo, ""))
	{
		PrecacheSound(g_SoundAmmo);
	}
	if (!StrEqual(g_ModelArmor, ""))
	{
		PrecacheModel(g_ModelArmor);
	}
	if (!StrEqual(g_SoundArmor, ""))
	{
		PrecacheSound(g_SoundArmor);
	}
}

public OnTouch(client, entity)
{
	if (GetConVarBool(g_Cvar_DropOnDeath))
	{
		if(GetConVarBool(g_Cvar_DropArmor))
		{
			decl String:ModelName[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
			if (StrEqual(ModelName, g_ModelArmor))
			{
				new CurrentArmor = GetEntProp(client, Prop_Send, "m_ArmorValue");
				if (CurrentArmor < 100)
				{
					decl String:TargetName[64], String:PlayerIndex[64];
					GetEntPropString(entity, Prop_Data, "m_iName", TargetName, sizeof(TargetName));
					strcopy(PlayerIndex, sizeof(PlayerIndex), TargetName[17]);
					new value = g_ArmorValues[StringToInt(PlayerIndex)];
					SetEntProp(client, Prop_Send, "m_ArmorValue", CurrentArmor + value > 100 ? 100 : CurrentArmor + value, 1);
					EmitSoundToClient(client, g_SoundArmor);
					RemoveEntities(StringToInt(PlayerIndex));
				}
			}
		}

		if(GetConVarBool(g_Cvar_DropAmmo))
		{
			decl String:classname[64];
			GetEdictClassname(entity, classname, sizeof(classname));
			if(StrContains(classname, "weapon_") != -1)
			{
				for(new i = 0; i < 24; i++)
				{
					if(StrEqual(classname, g_Weapons[i]))
					{
						new MatchedSlot = -1;
						new slot1 = GetPlayerWeaponSlot(client, _:0);
						new slot2 = GetPlayerWeaponSlot(client, _:1);
						decl String:slot1_classname[64], String:slot2_classname[64];

						if(slot1 != -1)
						{
							GetEdictClassname(slot1, slot1_classname, sizeof(slot1_classname));
							if(StrEqual(classname, slot1_classname))
							{
								MatchedSlot = slot1;
							}
						}
						if(slot2 != -1)
						{
							GetEdictClassname(slot2, slot2_classname, sizeof(slot2_classname));
							if(StrEqual(classname, slot2_classname))
							{
								MatchedSlot = slot2;
							}
						}

						if(MatchedSlot != -1)
						{
							new AmmoType = GetEntProp(MatchedSlot, Prop_Send, "m_iPrimaryAmmoType");
							new ReserveAmmo = GetEntData(client, (g_AmmoOffset + (AmmoType * 4)));
							new ReverseAmmoOnGround = GetEntData(entity, g_GroundAmmoOffset + 8);
							new MaxCapacity = g_WeaponCaps[i];

							if(ReserveAmmo < MaxCapacity)
							{
								if(ReserveAmmo + ReverseAmmoOnGround >= MaxCapacity)
								{
									SetEntData(client, (g_AmmoOffset + (AmmoType * 4)), MaxCapacity);
									SetEntData(entity, g_GroundAmmoOffset + 8, ReverseAmmoOnGround - MaxCapacity + ReserveAmmo);
								}
								else
								{
									SetEntData(client, (g_AmmoOffset + (AmmoType * 4)), ReserveAmmo + ReverseAmmoOnGround);
									SetEntData(entity, g_GroundAmmoOffset + 8, 0);
								}

								EmitSoundToClient(client, g_SoundAmmo);
							}
						}

						break;
					}
				}
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_ArmorRemove))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RemoveEntities(client);
	}
}

RemoveEntities(client)
{
	if (g_ArmorModels[client] != -1)
	{
		for (new i = 0; i < GetMaxEntities(); i++)
		{
			if (IsValidEntity(i))
			{
				new String:iName[64], String:tName[64];
				GetEntPropString(i, Prop_Data, "m_iName", iName, sizeof(iName));
				Format(tName, sizeof(tName), "prop_dynamic_dod_%i", client);
				if (StrEqual(iName, tName))
				{
					if (GetConVarFloat(g_Cvar_ArmorResize) != 1.0)
					{
						SetEntPropFloat(i, Prop_Send, "m_flModelScale", 1.0);
					}
					AcceptEntityInput(i, "Kill");
				}

				new String:cName[64], String:sName[64];
				GetEdictClassname(i, cName, sizeof(cName));
				Format(sName, sizeof(sName), "env_sprite_dod_%i", client);
				if (StrEqual(cName, sName))
				{
					AcceptEntityInput(i, "Kill");
				}
			}
		}

		g_ArmorModels[client] = -1;
	}
}

public Action:Command_Kill(client, const String:command[], args)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		DropItems(client);
		ForcePlayerSuicide(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetClientHealth(client) <= 0)
	{
		DropItems(client);
	}
}

DropItems(client)
{
	if (GetConVarBool(g_Cvar_DropOnDeath))
	{
		new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		decl String:active_weapon_name[64];
		GetEdictClassname(active_weapon, active_weapon_name, sizeof(active_weapon_name));

		new slot2, slot3;

		if ((slot2 = GetPlayerWeaponSlot(client, _:1)) != -1)
		{
			CS_DropWeapon(client, slot2, false);
		}

		if ((slot3 = GetPlayerWeaponSlot(client, _:2)) != -1 && GetConVarBool(g_Cvar_DropKnife))
		{
			CS_DropWeapon(client, slot3, false);
		}

		new number_of_hegrenades = GetEntData(client, g_AmmoOffset + 44);
		if (StrEqual(active_weapon_name, "weapon_hegrenade"))
		{
			number_of_hegrenades -= 1;
		}

		new number_of_flashbangs = GetEntData(client, g_AmmoOffset + 48);
		if (StrEqual(active_weapon_name, "weapon_flashbang"))
		{
			number_of_flashbangs -= 1;
		}

		new number_of_smokegrenades = GetEntData(client, g_AmmoOffset + 52);
		if (StrEqual(active_weapon_name, "weapon_smokegrenade"))
		{
			number_of_smokegrenades -= 1;
		}

		new slot4;
		while((slot4 = GetPlayerWeaponSlot(client, _:3)) != -1)
		{
			CS_DropWeapon(client, slot4, false);
			RemoveEdict(slot4);
		}

		SpawnWeapon(client, "weapon_hegrenade", number_of_hegrenades);
		SpawnWeapon(client, "weapon_flashbang", number_of_flashbangs);
		SpawnWeapon(client, "weapon_smokegrenade", number_of_smokegrenades);

		new armor = GetEntProp(client, Prop_Send, "m_ArmorValue");
		armor = RoundToNearest(armor * GetConVarFloat(g_Cvar_ArmorDepreciation));

		if (GetConVarBool(g_Cvar_DropArmor) && armor >= GetConVarInt(g_Cvar_ArmorMin))
		{
			g_ArmorValues[client] = armor;

			g_ArmorModels[client] = CreateEntityByName("prop_dynamic_override");
			new String:EntityArmorName[64];
			Format(EntityArmorName, sizeof(EntityArmorName), "prop_dynamic_dod_%i", client);
			DispatchKeyValue(g_ArmorModels[client], "targetname", EntityArmorName);
			DispatchKeyValue(g_ArmorModels[client], "model", g_ModelArmor);
			DispatchKeyValue(g_ArmorModels[client], "disableshadows", "1");
			DispatchKeyValue(g_ArmorModels[client], "solid", "6");
			SetEntProp(g_ArmorModels[client], Prop_Send, "m_usSolidFlags", 12);
			SetEntProp(g_ArmorModels[client], Prop_Send, "m_CollisionGroup", 1);
			if (GetConVarBool(g_Cvar_ArmorSprite))
			{
				SetEntityRenderMode(g_ArmorModels[client], RENDER_TRANSCOLOR);
				SetEntityRenderColor(g_ArmorModels[client], _, _, _, 0);
			}
			DispatchSpawn(g_ArmorModels[client]);
			if (GetConVarFloat(g_Cvar_ArmorResize) != 1.0)
			{
				SetEntPropFloat(g_ArmorModels[client], Prop_Send, "m_flModelScale", GetConVarFloat(g_Cvar_ArmorResize));
			}
			new Float:position[3];
			GetClientAbsOrigin(client, position);
			position[2] += GetConVarFloat(g_Cvar_ArmorOffset);
			TeleportEntity(g_ArmorModels[client], position, NULL_VECTOR, NULL_VECTOR);

			if (GetConVarBool(g_Cvar_ArmorSprite))
			{
				g_ArmorSprites[client] = CreateEntityByName("env_sprite");
				new String:EntitySpriteName[64];
				Format(EntitySpriteName, sizeof(EntitySpriteName), "env_sprite_dod_%i", client);
				DispatchKeyValue(g_ArmorSprites[client], "classname", EntitySpriteName);
				DispatchKeyValue(g_ArmorSprites[client], "model", g_SpriteArmor);
				DispatchKeyValue(g_ArmorSprites[client], "rendermode", "5");
				DispatchKeyValue(g_ArmorSprites[client], "rendercolor", "255 255 255");
				DispatchKeyValue(g_ArmorSprites[client], "renderamt", "255");
				DispatchSpawn(g_ArmorSprites[client]);
				position[2] += 20;
				TeleportEntity(g_ArmorSprites[client], position, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

SpawnWeapon(client, const String:weapon[], amount)
{
	if (!amount)
	{
		return;
	}

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);

	for (new i = 0; i < amount; i++)
	{
		new entity = CreateEntityByName(weapon);
		vec[2] += 10;
		DispatchSpawn(entity);
		TeleportEntity(entity, vec, NULL_VECTOR, NULL_VECTOR);
	}
}