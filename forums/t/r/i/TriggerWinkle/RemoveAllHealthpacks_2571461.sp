#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "AmmoPack/HealthPack remover",
	author = "TriggerWinkle",
}

public void OnPluginStart()
{
	RegAdminCmd("sm_removehealthpacks", ent_removehealth, ADMFLAG_GENERIC, "Removes all health packs from the map");
	RegAdminCmd("sm_removehp", ent_removehealth, ADMFLAG_GENERIC, "Removes all health packs from the map");
	RegAdminCmd("sm_hpremove", ent_removehealth, ADMFLAG_GENERIC, "Removes all health packs from the map");
	RegAdminCmd("sm_removeammopacks", ent_removeammo, ADMFLAG_GENERIC, "Removes all ammo packs from the map");
	RegAdminCmd("sm_removeammo", ent_removeammo, ADMFLAG_GENERIC, "Removes all ammo packs from the map");
	RegAdminCmd("sm_ammoremove", ent_removeammo, ADMFLAG_GENERIC, "Removes all ammo packs from the map");
}


public Action ent_removehealth(int client, int args)
{
	PrintToChat(client, "\x07FFD700[HealthPackRemover] \x01All the health packs are now removed");
	remove_entity_all("item_healthkit_full");
	remove_entity_all("item_healthkit_medium");
	remove_entity_all("item_healthkit_small");

	return Plugin_Handled;
}

public Action ent_removeammo(int client, int args)
{
	PrintToChat(client, "\x07FFD700[AmmoPackRemover] \x01All the ammo packs are now removed");
	remove_entity_all("item_ammopack_full");
	remove_entity_all("item_ammopack_medium");
	remove_entity_all("item_ammopack_small");

	return Plugin_Handled;
}

void remove_entity_all(char[] item_healthkit_full)
{
	int ent = -1;
	while((ent = FindEntityByClassname(ent, item_healthkit_full)) != -1)
	{
		PrintToServer("item_healthkit_full(%s) %i", item_healthkit_full, ent);
		AcceptEntityInput(ent, "Kill");
	}
}