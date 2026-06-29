/*
    AutoSilencer by meng
        Automatically puts a silencer on the M4A1.
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
	for(new i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponEquip, Hook_OnWeaponEquip);
}

public Action:Hook_OnWeaponEquip(client, weapon)
{
    decl String:item[20]; item[0] = '\0';
    GetEdictClassname(weapon, item, sizeof(item));

    if (StrEqual(item, "weapon_m4a1")){
		SetEntProp(weapon, Prop_Send, "m_bSilencerOn", 1);
		SetEntProp(weapon, Prop_Send, "m_weaponMode", 1);
    }
}