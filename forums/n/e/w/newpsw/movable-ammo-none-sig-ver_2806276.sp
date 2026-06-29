#include <sdktools>
#include <sdkhooks>
#include <vscript_proxy>

public Plugin myinfo =
{
	name        = "Movable Ammo",
	author      = "Dysphie & newpsw",
	description = "Allows ammo to be transported when it doesn't fit in a player's inventory",
	version     = "1.0.2",
	url         = "https://github.com/dysphie/nmrih-movable-ammo"
};

int Cammoinfo[9+1] = {0, ...};

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEdict(entity))
		return;

	if (StrEqual(classname, "item_ammo_box"))
	{
		SDKHook(entity, SDKHook_Use, OnAmmoBoxUse);
	}
	else if(StrEqual(classname, "player_pickup"))
	{
		SDKHook(entity, SDKHook_Spawn, OnPickupSpawned);
	}
}

void OnPickupSpawned(int entity)
{
	RequestFrame(GetAttachedEntity, EntIndexToEntRef(entity));
}

void GetAttachedEntity(int pickup_ref)
{
	int pickup = EntRefToEntIndex(pickup_ref);
	if (pickup == -1)
		return;

	int entity = GetEntPropEnt(pickup, Prop_Data, "m_attachedEntity");
	int client = GetEntPropEnt(pickup, Prop_Data, "m_hParent");

	if (entity == -1 || client == -1 || !IsPlayerAlive(client))
		return;

	char alias[64];
	GetEntityClassname(entity, alias, sizeof(alias));
	
	if(StrEqual(alias, "prop_physics"))
	{
		if(!(0 < GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity") <= MaxClients))
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", alias, sizeof(alias));
			if(StrContains(alias, "vscript/") != -1 || StrContains(alias, "ammo/") != -1)
			{
				SetEntPropEnt(pickup, Prop_Data, "m_hOwnerEntity", entity);
				SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
			}
		}
	}
}

Action OnAmmoBoxUse(int ammobox, int activator, int caller, UseType type, float value)
{
	if (!(0 < caller <= MaxClients) || !IsValidEntity(ammobox))
		return Plugin_Continue;
	char amodel[32];
	GetEntPropString(ammobox, Prop_Data, "m_ModelName", amodel, sizeof(amodel));
	if(StrContains(amodel, "vscript/") < 0 && StrContains(amodel, "ammo/") < 0)
		return Plugin_Continue;

	if(!IsClientConnected(activator) || IsFakeClient(activator) || !IsPlayerAlive(activator) && GetEntProp(activator, Prop_Send, "m_iPlayerState") != 0)
		return Plugin_Continue;
	
	if(RunEntVScriptBool(caller, "HasLeftoverWeight(1)"))
		return Plugin_Continue;
	
	int entity = CreateEntityByName("prop_physics_override");
	if (entity != -1 && IsValidEntity(entity))
	{
		float vOrigin[3];
		GetEntPropVector(ammobox, Prop_Send, "m_vecOrigin", vOrigin);
		float vAngeles[3];
		GetEntPropVector(ammobox, Prop_Send, "m_angRotation", vAngeles);
		char item[64];
		GetEntPropString(ammobox, Prop_Data, "m_ModelName", item, sizeof(item));
		DispatchKeyValue(entity, "model", item);
		DispatchKeyValue(entity, "spawnflags", "4");
		DispatchKeyValue(entity, "glowable", "1");
		DispatchKeyValue(entity, "glowblip", "0");
		DispatchKeyValueFloat(entity, "glowdistance", 110.0);
		DispatchKeyValue(entity, "glowcolor", "255 0 0");
		TeleportEntity(entity, vOrigin, vAngeles, NULL_VECTOR);
		AcceptEntityInput(entity, "enableglow"); 
		DispatchSpawn(entity);
		Cammoinfo[caller] = GetEntProp(ammobox, Prop_Data, "m_iAmmoCount");
		//PrintToChatAll("Ammo count: %d", Cammoinfo[caller]);
		SetVariantString("OnUser1 !self:Kill::0.0:1");
		AcceptEntityInput(ammobox, "AddOutput");
		AcceptEntityInput(ammobox, "FireUser1");
		AcceptEntityInput(entity, "use", caller);
	}
	return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
	if (!IsValidEdict(entity) || !IsValidEntity(entity)) {
		return;
	}
	
	char classname[15];
	GetEntityClassname(entity, classname, sizeof(classname));
	if(StrEqual(classname, "player_pickup"))
	{
		int dweapon = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidEdict(dweapon) && IsValidEntity(dweapon))
		{
			int client = GetEntPropEnt(dweapon, Prop_Data, "m_hOwnerEntity");
			GetEntityClassname(dweapon, classname, sizeof(classname));
			//PrintToChatAll("Weapon : %d Client : %d", dweapon, client);
			if(IsValidPlayer(client))
			{
				if(StrEqual(classname, "prop_physics"))
				{
					float vOrigin[3];
					GetEntPropVector(dweapon, Prop_Send, "m_vecOrigin", vOrigin);
					float vAngeles[3];
					GetEntPropVector(dweapon, Prop_Send, "m_angRotation", vAngeles);
					
					int ammo_spawner = CreateEntityByName("item_ammo_box");
					if (ammo_spawner != -1 && DispatchSpawn(ammo_spawner))
					{
						char amodel[64], Tcode[32];
						GetEntPropString(dweapon, Prop_Data, "m_ModelName", amodel, sizeof(amodel));
						if (StrContains(amodel, "9mm") > -1 || StrContains(amodel, "glock17") > -1 || StrContains(amodel, "mp5") > -1 || StrContains(amodel, "m92fs") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_9mm\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "45acp") > -1 || StrContains(amodel, "1911") > -1 || StrContains(amodel, "mac10") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_45acp\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "357") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_357\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "22lr") > -1 || StrContains(amodel, "mkiii") > -1 || StrContains(amodel, "1022") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_22lr\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "556") > -1 || StrContains(amodel, "m16") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_556\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "762") > -1 || StrContains(amodel, "cz858") > -1 || StrContains(amodel, "sks") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_762mm\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "308") > -1 || StrContains(amodel, "fnfal") > -1 || StrContains(amodel, "sako85") > -1 || StrContains(amodel, "jae700") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_308\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "12g") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_12gauge\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "arrow_box") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_arrow\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "gascan") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_fuel\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "barricadeboard") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_board\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						else if(StrContains(amodel, "flares") > -1)
						{
							FormatEx(Tcode, sizeof(Tcode), "SetAmmoType(\"ammobox_flare\")");
							RunEntVScript(ammo_spawner, Tcode);
						}
						char Ncode[24];
						FormatEx(Ncode, sizeof(Ncode), "SetAmmoCount(%d)", Cammoinfo[client]);
						RunEntVScript(ammo_spawner, Ncode);
						SetEntityModel(ammo_spawner, amodel);
						
						TeleportEntity(ammo_spawner, vOrigin, vAngeles, NULL_VECTOR);
						RemoveEntity(dweapon);
					}
				}
			}
		}
	}
}

bool IsValidPlayer(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}