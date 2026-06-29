#include <sourcemod>
#include <sdktools>
#include <store>

public OnPluginStart()
{
    Store_RegisterItemType("weapon", OnWeaponUse);
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "store-inventory"))
    {
        Store_RegisterItemType("weapon", OnWeaponUse);
    }   
}

// This will be called when players use our item in their inventory.
public Store_ItemUseAction:OnWeaponUse(client, itemId, bool:equipped)
{
	switch (itemId)
	{
		case 150:
		{
			new WepId = CreateEntityByName("weapon_glock");
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			TeleportEntity(WepId, vec, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(WepId);
		}
		case 151:
		{
			new WepId = CreateEntityByName("weapon_fiveseven");
			new Float:vec[3];
			GetClientAbsOrigin(client, vec);
			TeleportEntity(WepId, vec, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(WepId);
		}
	}
	for(new i = 1; i <= MaxClients; i++)
	{
		if(GetClientTeam(i) == 3)
		{
		PrintToChat(i, "\x04Какой-то террорист приобрел оружие!");
		}
	}
    return Store_DeleteItem;
}