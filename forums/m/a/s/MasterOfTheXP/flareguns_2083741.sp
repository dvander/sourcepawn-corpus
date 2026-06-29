#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (StrEqual(classname, "tf_weapon_flaregun", false) || StrEqual(classname, "tf_weapon_flaregun_revenge", false))
		return; // It's a flare gun already
	new Handle:data;
	CreateDataTimer(0.0, Timer_CheckFlareGun, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetClientUserId(client));
	WritePackCell(data, EntIndexToEntRef(entityIndex));
	ResetPack(data);
}

public Action:Timer_CheckFlareGun(Handle:timer, Handle:data)
{
	new client = GetClientOfUserId(ReadPackCell(data));
	if (!client) return;
	new entityIndex = EntRefToEntIndex(ReadPackCell(data));
	if (entityIndex <= MaxClients) return;
	
	if (entityIndex != GetPlayerWeaponSlot(client, 1)) return;
	TF2Items_GiveWeapon(client, 39);
}