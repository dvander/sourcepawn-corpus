#include <tf2_stocks>
#include <tf2items>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], index, level, quality, ent)
{
	switch (index)
	{
		case 772: // Baby Face's Blaster
			CreateTimer(0.1, Timer_ReplaceBFBWithScattergun, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_ReplaceBFBWithScattergun(Handle:event, any:uid)
{
	new client = GetClientOfUserId(uid);
	if (!client) return;
	new primary = GetPlayerWeaponSlot(client, 0);
	if (-1 == primary) return;
	if (772 != GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex")) return; // Make sure that they still have it
	
	TF2_RemoveWeaponSlot(client, 0);
	
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
	if (hWeapon == INVALID_HANDLE) return; // ?????
	TF2Items_SetClassname(hWeapon, "tf_weapon_scattergun");
	TF2Items_SetItemIndex(hWeapon, 13);
	TF2Items_SetLevel(hWeapon, 1);
	TF2Items_SetQuality(hWeapon, 0);
	
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	
	EquipPlayerWeapon(client, entity);
}