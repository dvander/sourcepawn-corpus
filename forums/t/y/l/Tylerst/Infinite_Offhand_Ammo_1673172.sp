#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Infinite OffHand Ammo",
	author = "Tylerst",
	description = "http://tinyurl.com/7wnd5g",
	version = "1.0.0",
	url = "none"
}

new Handle:hInfiniteOffhandAmmo = INVALID_HANDLE;

new offset_ammo;

public OnPluginStart()
{
	LoadTranslations("common.phrases");	
	hInfiniteOffhandAmmo = CreateConVar("sm_infinite_offhand_ammo", "0", "Enable/Disable infinite offhand ammo for everyone);
	offset_ammo = FindSendPropInfo("CBasePlayer", "m_iAmmo");

}

public OnGameFrame()
{
	if(GetConVarBool(hInfiniteOffhandAmmo))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if((IsClientInGame(i) && IsPlayerAlive(i)))
			{
				new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
				if(!IsValidEntity(weapon)) continue;
				new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")*4;
				SetEntData(i, ammotype+offset_ammo, 99, 4, true);
			}
		}
	}
}