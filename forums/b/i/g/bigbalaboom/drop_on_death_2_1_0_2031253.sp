#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "2.1.0"

new Handle:g_Cvar_DropAll = INVALID_HANDLE;
new Handle:g_Cvar_DropKnife = INVALID_HANDLE;
new Handle:g_Cvar_DropArmor = INVALID_HANDLE;
new Handle:g_Cvar_ArmorMin = INVALID_HANDLE;
new Handle:g_Cvar_UseSprite = INVALID_HANDLE;
new Handle:g_Cvar_Model = INVALID_HANDLE;
new Handle:g_Cvar_Resize = INVALID_HANDLE;
new Handle:g_Cvar_Offset = INVALID_HANDLE;
new Handle:g_Cvar_Sound = INVALID_HANDLE;
new Handle:g_Cvar_RespawnRemove = INVALID_HANDLE;

new String:g_ModelSprite[] = "sprites/blueglow1.vmt";
new String:g_ModelArmor[512];
new String:g_SoundPickup[512];

new g_EntityModels[MAXPLAYERS + 1] = {-1, ...};
new g_EntitySprites[MAXPLAYERS + 1] = {-1, ...};
new g_Values[MAXPLAYERS + 1] = {0, ...};

new g_AmmoOffset = -1;

public Plugin:myinfo =
{
	name = "Drop On Death",
	author = "bigbalaboom",
	description = "Drop all weapons and remaining armor on death.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	CreateConVar("sm_drop_on_death_version", PLUGIN_VERSION, "Drop On Death Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_Cvar_DropAll = CreateConVar("sm_drop_all_on_death", "1", "Toggles dropping all weapons and armor on death.", FCVAR_PLUGIN);
	g_Cvar_DropKnife = CreateConVar("sm_drop_knife_on_death", "1", "Toggles dropping knife on death.", FCVAR_PLUGIN);
	g_Cvar_DropArmor = CreateConVar("sm_drop_armor_on_death", "1", "Toggles dropping armor on death.", FCVAR_PLUGIN);
	g_Cvar_ArmorMin = CreateConVar("sm_drop_armor_min", "10", "Minimum amount of armor to enable armor drop.", FCVAR_PLUGIN);
	g_Cvar_UseSprite = CreateConVar("sm_drop_armor_sprite", "1", "Toggles sprite and physical model for dropped armor.", FCVAR_PLUGIN);
	g_Cvar_Model = CreateConVar("sm_drop_armor_model", "models/props/cs_italy/orange.mdl", "Model used for dropped armor.", FCVAR_PLUGIN);
	g_Cvar_Resize = CreateConVar("sm_drop_armor_model_resize", "1.0", "Size of model to be scaled.", FCVAR_PLUGIN);
	g_Cvar_Offset = CreateConVar("sm_drop_armor_model_voffset", "0.0", "Vertical offset of armor model.", FCVAR_PLUGIN);
	g_Cvar_Sound = CreateConVar("sm_drop_armor_pickup_sound", "items/itempickup.wav", "Sound used for picking up armor.", FCVAR_PLUGIN);
	g_Cvar_RespawnRemove = CreateConVar("sm_drop_armor_respawn_remove", "0", "Toggles removing dropped armor on resapwn.", FCVAR_PLUGIN);
	AutoExecConfig(true, "drop_on_death");

	HookConVarChange(g_Cvar_DropAll, OnConVarChange);
	HookConVarChange(g_Cvar_DropArmor, OnConVarChange);
	HookConVarChange(g_Cvar_Model, OnConVarChange);
	HookConVarChange(g_Cvar_Sound, OnConVarChange);

	g_AmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");

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
	PrecacheModel(g_ModelSprite);
	GetConVars();
}

public OnConVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	decl String:CvarName[64];
	GetConVarName(cvar, CvarName, sizeof(CvarName));

	if (StrEqual(CvarName, "sm_drop_armor_model") || StrEqual(CvarName, "sm_drop_armor_pickup_sound"))
	{
		GetConVars();
	}
	else if (StrEqual(newvalue, "0"))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			RemoveEntities(i);
		}
	}
}

GetConVars()
{
	GetConVarString(g_Cvar_Model, g_ModelArmor, 512);
	GetConVarString(g_Cvar_Sound, g_SoundPickup, 512);

	if (!StrEqual(g_ModelArmor, ""))
	{
		PrecacheModel(g_ModelArmor);
	}
	if (!StrEqual(g_SoundPickup, ""))
	{
		PrecacheSound(g_SoundPickup);
	}
}

public OnTouch(client, entity)
{
	if (GetConVarBool(g_Cvar_DropAll) && GetConVarBool(g_Cvar_DropArmor))
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
				new value = g_Values[StringToInt(PlayerIndex)];
				SetEntProp(client, Prop_Send, "m_ArmorValue", (CurrentArmor + value > 100 ? 100 : CurrentArmor + value), 1);
				EmitSoundToClient(client, g_SoundPickup);
				RemoveEntities(StringToInt(PlayerIndex));
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(g_Cvar_RespawnRemove))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		RemoveEntities(client);
	}
}

RemoveEntities(client)
{
	if (g_EntityModels[client] != -1)
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
					if (GetConVarFloat(g_Cvar_Resize) != 1.0)
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
					// TODO: sometimes reported as "not a CBaseEntity"
					AcceptEntityInput(i, "Kill");
				}
			}
		}

		g_EntityModels[client] = -1;
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
	if (GetConVarBool(g_Cvar_DropAll))
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
		if (GetConVarBool(g_Cvar_DropArmor) && armor > GetConVarInt(g_Cvar_ArmorMin))
		{
			g_Values[client] = armor;

			g_EntityModels[client] = CreateEntityByName("prop_dynamic_override");
			new String:EntityArmorName[64];
			Format(EntityArmorName, sizeof(EntityArmorName), "prop_dynamic_dod_%i", client);
			DispatchKeyValue(g_EntityModels[client], "targetname", EntityArmorName);
			DispatchKeyValue(g_EntityModels[client], "model", g_ModelArmor);
			DispatchKeyValue(g_EntityModels[client], "disableshadows", "1");
			DispatchKeyValue(g_EntityModels[client], "solid", "6");
			SetEntProp(g_EntityModels[client], Prop_Send, "m_usSolidFlags", 12);
			SetEntProp(g_EntityModels[client], Prop_Send, "m_CollisionGroup", 1);
			if (GetConVarBool(g_Cvar_UseSprite))
			{
				SetEntityRenderMode(g_EntityModels[client], RENDER_TRANSCOLOR);
				SetEntityRenderColor(g_EntityModels[client], _, _, _, 0);
			}
			DispatchSpawn(g_EntityModels[client]);
			if (GetConVarFloat(g_Cvar_Resize) != 1.0)
			{
				SetEntPropFloat(g_EntityModels[client], Prop_Send, "m_flModelScale", GetConVarFloat(g_Cvar_Resize));
			}
			new Float:position[3];
			GetClientAbsOrigin(client, position);
			position[2] += GetConVarFloat(g_Cvar_Offset);
			TeleportEntity(g_EntityModels[client], position, NULL_VECTOR, NULL_VECTOR);

			if (GetConVarBool(g_Cvar_UseSprite))
			{
				g_EntitySprites[client] = CreateEntityByName("env_sprite");
				new String:EntitySpriteName[64];
				Format(EntitySpriteName, sizeof(EntitySpriteName), "env_sprite_dod_%i", client);
				DispatchKeyValue(g_EntitySprites[client], "classname", EntitySpriteName);
				DispatchKeyValue(g_EntitySprites[client], "model", g_ModelSprite);
				DispatchKeyValue(g_EntitySprites[client], "rendermode", "5");
				DispatchKeyValue(g_EntitySprites[client], "rendercolor", "255 255 255");
				DispatchKeyValue(g_EntitySprites[client], "renderamt", "255");
				DispatchSpawn(g_EntitySprites[client]);
				position[2] += 20;
				TeleportEntity(g_EntitySprites[client], position, NULL_VECTOR, NULL_VECTOR);
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