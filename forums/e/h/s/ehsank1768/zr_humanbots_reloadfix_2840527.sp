#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1

new g_iLastWeaponSlot[MAXPLAYERS + 1];
new bool:g_bSwitchingToSecondary[MAXPLAYERS + 1];
new Handle:g_SwitchTimer[MAXPLAYERS + 1];
new g_iSavedAmmoType[MAXPLAYERS + 1];
new g_iSavedAmmoCount[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Auto Reload",
	author = "Your Name",
	description = "Automatically reload when ammo reaches 1",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	// Plugin started
}

public OnClientPutInServer(client)
{
	g_iLastWeaponSlot[client] = -1;
	g_bSwitchingToSecondary[client] = false;
	g_SwitchTimer[client] = INVALID_HANDLE;
	g_iSavedAmmoType[client] = -1;
	g_iSavedAmmoCount[client] = -1;
	SDKHook(client, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitch);
}

public OnClientDisconnect(client)
{
	g_iLastWeaponSlot[client] = -1;
	g_bSwitchingToSecondary[client] = false;
	if (g_SwitchTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_SwitchTimer[client]);
		g_SwitchTimer[client] = INVALID_HANDLE;
	}
}

public Action:OnWeaponCanSwitch(client, weapon)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	// Only affect bots
	if (!IsFakeClient(client))
		return Plugin_Continue;
	
	if (!IsValidEntity(weapon))
		return Plugin_Continue;
	
	// Get the weapon slot
	new iSlot = GetPlayerWeaponSlot(client, weapon);
	if (iSlot == -1)
	{
		// Try to find which slot this weapon is in
		for (new slot = 0; slot <= 5; slot++)
		{
			new iSlotWeapon = GetPlayerWeaponSlot(client, slot);
			if (iSlotWeapon == weapon)
			{
				iSlot = slot;
				break;
			}
		}
	}
	
	new iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	new iCurrentSlot = -1;
	if (iCurrentWeapon != -1)
	{
		for (new slot = 0; slot <= 5; slot++)
		{
			new iSlotWeapon = GetPlayerWeaponSlot(client, slot);
			if (iSlotWeapon == iCurrentWeapon)
			{
				iCurrentSlot = slot;
				break;
			}
		}
	}
	
	// Check if trying to switch from primary to secondary
	if (iCurrentSlot == SLOT_PRIMARY && iSlot == SLOT_SECONDARY)
	{
		//PrintToChat(client, "Switching from primary to secondary - blocked!");
		
		// Get the primary weapon's ammo type and save it
		if (iCurrentWeapon != -1)
		{
			new ammoType = GetEntProp(iCurrentWeapon, Prop_Data, "m_iPrimaryAmmoType");
			if (ammoType != -1)
			{
				// Get current reserve ammo before blocking
				new reserveAmmo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammoType);
				
				// Save the ammo values for restoration
				g_iSavedAmmoType[client] = ammoType;
				g_iSavedAmmoCount[client] = reserveAmmo;
				
				// Try to restore ammo in next frame using a small delay
				CreateTimer(0.01, Timer_RestoreAmmo, client, 0);
			}
		}
		
		// Block the switch - return Plugin_Handled to prevent switching
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	// Only affect bots
	if (!IsFakeClient(client))
		return Plugin_Continue;
	
	// Get the player's active weapon
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (iWeapon == -1)
		return Plugin_Continue;
	
	// Get the current ammo count in the clip
	new iClip1 = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
	
	// If ammo is 1, trigger reload and block firing
	if (iClip1 == 1)
	{
	buttons &= ~IN_ATTACK; // Remove IN_ATTACK (fire) button to prevent firing
	buttons |= IN_RELOAD;
	}
	
	return Plugin_Continue;
}

public Action:Timer_RestoreAmmo(Handle:timer, client)
{
	// Restore the saved ammo
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (g_iSavedAmmoType[client] != -1 && g_iSavedAmmoCount[client] != -1)
		{
			SetEntProp(client, Prop_Send, "m_iAmmo", g_iSavedAmmoCount[client], _, g_iSavedAmmoType[client]);
			
			// Reset saved values
			g_iSavedAmmoType[client] = -1;
			g_iSavedAmmoCount[client] = -1;
		}
	}
	return Plugin_Stop;
}

bool:IsValidClient(client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

