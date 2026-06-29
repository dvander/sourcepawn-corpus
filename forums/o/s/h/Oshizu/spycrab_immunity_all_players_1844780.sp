#include <tf2items>
#include <tf2_stocks>

public Plugin:myinfo =
{
	name = "[TF2] Invicible Spycrab PDA",
	author = "Oshizu",
	description = "Write !spycrab.",
	version = "1.0",
	url = "http://www.sourcemod.net",
}

public OnPluginStart()
{
	RegConsoleCmd("sm_spycrab_pda", pda);
}

public Action:pda(client, args)
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
	TF2Items_SetClassname(hWeapon, "tf_weapon_pda_spy");
	TF2Items_SetItemIndex(hWeapon, 27);
	TF2Items_SetLevel(hWeapon, 10);
	TF2Items_SetQuality(hWeapon, 0);
	TF2Items_SetNumAttributes(hWeapon, 1);
	TF2Items_SetAttribute(hWeapon, 0, 128, 1.0);
	TF2Items_SetAttribute(hWeapon, 1, 412, 0.0);
	new weapon = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, weapon);
	TF2_RemoveWeaponSlot(client, 3)
	
	
	
}