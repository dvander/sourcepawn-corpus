#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>

public TF2Items_OnGiveNamedItem_Post(client, String:classname[], itemDefinitionIndex, itemLevel, itemQuality, entityIndex)
{
	if (StrEqual(classname, "tf_weapon_flaregun", false) || StrEqual(classname, "tf_weapon_flaregun_revenge", false))
		return; // It's a flare gun already
	if (entityIndex != GetPlayerWeaponSlot(client, 1)) return; // Not a secondary weapon
	TF2Items_GiveWeapon(client, 39);
}