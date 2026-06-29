#include <sourcemod>
#include <sdktools>

static const	PISTOL_OFFSET_IAMMO	= 4;
static const	PISTOL_MAGNUM_OFFSET_IAMMO	= 8;

new ammo;

public OnPluginStart()
{
	HookEvent("player_use", Event_PlayerUse);
}

public Event_PlayerUse(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "targetid");
	
	if (IsValidEdict(entity))
	{
		decl String:ent_name[64];
		GetEdictClassname(entity, ent_name, sizeof(ent_name));

		ammo = GetConVarInt(FindConVar("ammo_pistol_max"));
		new iAmmo = FindDataMapOffs(client, "m_iAmmo");

		new String:weapon[32];
		GetEdictClassname(GetPlayerWeaponSlot(client, 1), weapon, 32);
		if (StrEqual(weapon, "weapon_pistol"))
		{
			new current = GetEntData(client, (iAmmo + PISTOL_OFFSET_IAMMO));
			
			if (current >= ammo)
			{
				return;
			}
			
			else if (StrEqual(ent_name, "weapon_ammo_spawn", false))
			{
				new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
				SetEntData(client, iAmmoOffset + PISTOL_OFFSET_IAMMO, ammo);
			}
		}

		else if (StrEqual(weapon, "weapon_pistol_magnum"))
		{
			new currentmg = GetEntData(client, (iAmmo + PISTOL_MAGNUM_OFFSET_IAMMO));
			
			if (currentmg >= ammo)
			{
				return;
			}
			
			else if (StrEqual(ent_name, "weapon_ammo_spawn", false))
			{
				new iAmmoOffset = FindDataMapOffs(client, "m_iAmmo");
				SetEntData(client, iAmmoOffset + PISTOL_MAGNUM_OFFSET_IAMMO, ammo);
			}
		}
	}
	return;	
}
