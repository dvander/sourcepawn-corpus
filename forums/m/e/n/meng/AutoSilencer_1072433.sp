/*
	AutoSilencer by meng
		Automatically puts a silencer on the M4A1.
*/

#include <sourcemod>
#include <sdktools>

new g_SilencerOn;

public OnPluginStart()
{
	g_SilencerOn = FindSendPropOffs("CWeaponM4A1", "m_bSilencerOn");
	HookEvent("item_pickup", EventItemPickup);
}

public EventItemPickup(Handle:event, const String:name[],bool:dontBroadcast)
{
	decl String:item[32]; GetEventString(event, "item", item, sizeof(item));
	if (StrEqual(item, "m4a1")){
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new m4 = GetPlayerWeaponSlot(client, 0);
		SetEntData(m4, g_SilencerOn, 1);
	}
}