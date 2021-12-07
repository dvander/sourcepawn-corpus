#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.5"

public Plugin:myinfo = 
{
	name = "L4D2 Ammo Control MOD",
	author = "AtomicStryker",
	description = " Allows Customization of some gun related game mechanics ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1020236"
}

public OnPluginStart()
{
	HookEvent("upgrade_pack_added", Event_SpecialAmmo);
}

public Action:Event_SpecialAmmo(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new upgradeid = GetEventInt(event, "upgradeid");
	decl String:class[256];
	GetEdictClassname(upgradeid, class, sizeof(class));
	
	if (StrEqual(class, "upgrade_laser_sight"))
		return;
	
	new RND = GetRandomInt(1, 4);
	if (RND == 1)
	{
		PrintToChat(client, "\x05You have found a laser sight!");
		give_laser_sight(client);
	}
	else
	{
		if (GetSpecialAmmoInPlayerGun(client) > 1)
		{
			new AMMORND = GetRandomInt(1, 3);
			SetSpecialAmmoInPlayerGun(client, AMMORND * GetSpecialAmmoInPlayerGun(client));
		}
	}
	RemoveEdict(upgradeid);
}

public give_laser_sight(client)
{
	new flags = GetCommandFlags("upgrade_add");
	SetCommandFlags("upgrade_add", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "upgrade_add laser_sight");
	SetCommandFlags("upgrade_add", flags);
}

stock GetSpecialAmmoInPlayerGun(client) //returns the amount of special rounds in your gun
{
	if (!client) client = 1;
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		return GetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 1);
	else return 0;
}

stock SetSpecialAmmoInPlayerGun(client, amount)
{
	if (!client) client = 1;
	new gunent = GetPlayerWeaponSlot(client, 0);
	if (IsValidEdict(gunent))
		SetEntProp(gunent, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", amount, 1);
}