#include <sourcemod>
#include <sdktools>
#include <store>
#include <cstrike>


new g_knifes[MAXPLAYERS+1];

public OnPluginStart()
{
    Store_RegisterItemType("knife",OnEquip);
    HookEvent("player_spawn",KnifeSpawn);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "store-inventory"))
    {
        Store_RegisterItemType("knife", OnEquip);
    }   
}

// This will be called when the attributes are loaded.


// This will be called when players use our item in their inventory.
public Store_ItemUseAction:OnEquip(client, itemId, bool:equipped)
{
	if (!IsClientInGame(client))
	{
		return Store_DoNothing;
	}

	decl String:knifeName[STORE_MAX_NAME_LENGTH];
	Store_GetItemName(itemId, knifeName, sizeof(knifeName));


	if(StrEqual(knifeName,"bayonet")) g_knifes[client]=1;
	else if(StrEqual(knifeName,"gut")) g_knifes[client]=2;
	else if(StrEqual(knifeName,"flip")) g_knifes[client]=3;
	else if(StrEqual(knifeName,"m9bayonet")) g_knifes[client]=4;
	else if(StrEqual(knifeName,"karambit")) g_knifes[client]=5;
	//else if(StrEqual(knifeName,"m9")) g_knifes[client]=2;
	else if(StrEqual(knifeName,"butterfly")) g_knifes[client]=6;
	else g_knifes[client]=0;

	if (equipped)
	{        
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

		PrintToChat(client, "%s%t", STORE_PREFIX, "Unequipped item", displayName);

		return Store_UnequipItem;
	}

	else
	{
		decl String:displayName[STORE_MAX_DISPLAY_NAME_LENGTH];
		Store_GetItemDisplayName(itemId, displayName, sizeof(displayName));

		PrintToChat(client, "%s%t", STORE_PREFIX, "Equipped item", displayName);

		return Store_EquipItem;
	}  
}

public Action:KnifeSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{ 
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);


	new currentknife = GetPlayerWeaponSlot(client, 2);
	if(IsValidEntity(currentknife) && currentknife != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, currentknife);
	}
	
	new knife;

	switch(g_knifes[client])
	{
		case 1:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_bayonet");
				EquipPlayerWeapon(client,knife);
			}
		}
		
		case 2:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_knife_gut");
				EquipPlayerWeapon(client,knife);
			}
		}
		
		case 3:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_knife_flip");
				EquipPlayerWeapon(client,knife);
			}
		}
		
		case 4:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_knife_m9_bayonet");
				EquipPlayerWeapon(client,knife);
			}
		}
		
		case 5:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_knife_karambit");
				EquipPlayerWeapon(client,knife);
			}
		}
		
		case 6:
		{
			if(IsPlayerAlive(client))
			{
				knife = GivePlayerItem(client, "weapon_knife_tactical");
				EquipPlayerWeapon(client,knife);
			}
		}
		default: 
		{
			if(IsPlayerAlive(client))
			{
				if(GetClientTeam(client)==2)
				{
					knife = GivePlayerItem(client, "weapon_knife_t");
					EquipPlayerWeapon(client,knife);
				}
				if(GetClientTeam(client)==3)
				{
					knife = GivePlayerItem(client, "weapon_knife");
					EquipPlayerWeapon(client,knife);
				}
			}
		}
	}
}