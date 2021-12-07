#include <sourcemod>
#include <tf2_stocks>

#define ROCKET_JUMPER_INDEX 237
#define STICKY_JUMPER_INDEX 265

ConVar g_cvEnable = null;

public void OnPluginStart()
{
	g_cvEnable = CreateConVar("sm_block_jumpers_enable", "1", "Enable/disable the plugin", _, true, 0.0, true, 1.0);

	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public void Event_PostInventoryApplication(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	RequestFrame(Frame_PostInventoryApplication, hEvent.GetInt("userid"));
}

public void Frame_PostInventoryApplication(any data)
{
	if (g_cvEnable.BoolValue)
	{
		int iClient = GetClientOfUserId(data);
		if (iClient != 0 && IsPlayerAlive(iClient))
		{
			int iPrimary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
			if (iPrimary != -1 && GetItemDefinitionIndex(iPrimary) == ROCKET_JUMPER_INDEX)
			{
				TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Primary);
				EquipFreeWeaponSlot(iClient);
				PrintToChat(iClient, "[SM] The Rocket Jumper is not allowed!");
			}

			int iSecondary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Secondary);
			if (iSecondary != -1 && GetItemDefinitionIndex(iSecondary) == STICKY_JUMPER_INDEX)
			{
				TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);
				EquipFreeWeaponSlot(iClient);
				PrintToChat(iClient, "[SM] The Sticky Jumper is not allowed!");
			}
		}
	}
}

int GetItemDefinitionIndex(int iEntity)
{
	return GetEntProp(iEntity, Prop_Send, "m_iItemDefinitionIndex");
}

void EquipWeapon(int iClient, int iWeapon)
{
	SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
}

void EquipFreeWeaponSlot(int iClient)
{
	int iWeapon = -1;
	for (int i = TFWeaponSlot_Primary; i <= TFWeaponSlot_Melee; i++)
	{
		iWeapon = GetPlayerWeaponSlot(iClient, i);
		if (iWeapon != -1)
		{
			EquipWeapon(iClient, iWeapon);
			break;
		}
	}
}