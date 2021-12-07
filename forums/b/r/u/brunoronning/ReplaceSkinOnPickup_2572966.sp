#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo =
{
	name        = "[SM] Replace Skin On Pickup",
	author      = "RonninG.",
	description = "#",
	version     = "1.0.0",
	url         = "https://forums.alliedmods.net/showthread.php?t=304540"
};

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

public void OnWeaponEquipPost(int iClient, int iWeapon)
{
	if (!IsValidEdict(iWeapon))
		return;

	if (GetEntProp(iWeapon, Prop_Send, "m_hPrevOwner") > 0)
		return;

	char szClass[64];
	GetEdictClassname(iWeapon, szClass, sizeof(szClass));

	if (SafeRemoveWeapon(iClient, iWeapon))
	{
		DataPack pack = new DataPack();
		RequestFrame(Frame_ReplaceWeapon, pack);
		pack.WriteCell(GetClientUserId(iClient));
		pack.WriteString(szClass);
	}
}

public void Frame_ReplaceWeapon(DataPack pack)
{
	pack.Reset();
	int iClient = GetClientOfUserId(pack.ReadCell());
	char szClass[64];
	pack.ReadString(szClass, sizeof(szClass));
	delete pack;

	if (!iClient || !IsClientInGame(iClient))
		return;

	int iWeapon = GivePlayerItem(iClient, szClass);
	EquipPlayerWeapon(iClient, iWeapon);
}

// Snippet from: https://bitbucket.org/SM91337/csgo-items/
stock bool SafeRemoveWeapon(int iClient, int iWeapon)
{
	int iDefIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");

	if (iDefIndex < 0 || iDefIndex > 700)
		return false;

	if (HasEntProp(iWeapon, Prop_Send, "m_bInitialized"))
	{
		if (GetEntProp(iWeapon, Prop_Send, "m_bInitialized") == 0)
			return false;
	}

	if (HasEntProp(iWeapon, Prop_Send, "m_bStartedArming"))
	{
		if (GetEntSendPropOffs(iWeapon, "m_bStartedArming") > -1)
			return false;
	}

	if (!RemovePlayerItem(iClient, iWeapon))
		return false;

	int iWorldModel = GetEntPropEnt(iWeapon, Prop_Send, "m_hWeaponWorldModel");

	if (IsValidEdict(iWorldModel) && IsValidEntity(iWorldModel))
	{
		if (!AcceptEntityInput(iWorldModel, "Kill"))
			return false;
	}

	if (iWeapon == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"))
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", -1);

	AcceptEntityInput(iWeapon, "Kill");
	return true;
}