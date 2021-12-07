#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required
int g_iOffsetAmmo = -1;
int g_iOffsetPrimaryAmmoType = -1;

public void OnPluginStart()
{
	g_iOffsetAmmo = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_iOffsetPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public Action OnWeaponEquipPost(int client, int weapon)
{
	int wp = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

	if(wp >= 43 && wp <= 49 || wp == 57 || wp == 68 || wp == 70 || wp >= 81 && wp <= 84)return;
	
	int ammotype = GetEntData(weapon, g_iOffsetPrimaryAmmoType);				///		from kgns Weapon & Knives
	int offset = g_iOffsetAmmo + (ammotype * 4);
	int ammo = GetEntData(client, offset);
	if(ammo != -1)
	{
		//PrintToChatAll("change ammo");
		DataPack pack;
		CreateDataTimer(0.01, ReserveAmmoTimer1, pack);							//second timer requied for compatibility with Weapon & Knives
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(offset);
		pack.WriteCell(ammo);
	}	
}

public Action ReserveAmmoTimer1(Handle timer, DataPack pack)
{
	ResetPack(pack);
	int clientIndex = GetClientOfUserId(pack.ReadCell());
	int offset = pack.ReadCell();
	int ammo = pack.ReadCell();
	//PrintToChatAll("mapconf: change ammo 2");
	if(clientIndex > 0 && IsClientInGame(clientIndex))
	{
		SetEntData(clientIndex, offset, 1, 4, true);
		DataPack pack2;
		CreateDataTimer(0.01, ReserveAmmoTimer2, pack2);
		pack2.WriteCell(GetClientUserId(clientIndex));
		pack2.WriteCell(offset);
		pack2.WriteCell(ammo);
	}
}

public Action ReserveAmmoTimer2(Handle timer, DataPack pack)
{
	ResetPack(pack);
	int clientIndex = GetClientOfUserId(pack.ReadCell());
	int offset = pack.ReadCell();
	int ammo = pack.ReadCell();
	//PrintToChatAll("mapconf: change ammo finish");
	if(clientIndex > 0 && IsClientInGame(clientIndex))
	{
		SetEntData(clientIndex, offset, ammo, 4, true);
	}
}
