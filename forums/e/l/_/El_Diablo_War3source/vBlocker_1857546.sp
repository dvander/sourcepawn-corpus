#pragma semicolon 1


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Spam[66];

public Plugin:myinfo =
{
	name = "Vaccinator Blocker",
	author = "El Diablo",
	description = "Uses SDKHook to watch for weapons switch, and blocks the vaccinator.",
	version = "1.0.1.2",
	url = "http://www.war3evo.com"
};


public OnClientPutInServer(client){
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
}

public SDK_OnWeaponSwitchPost(client, weapon)
{
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
		new activeweapondata = GetEntDataEnt2(client, activeweapon);
		if(IsValidEntity(activeweapondata))
		{
			new weaponindex = GetEntProp(activeweapondata, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponindex==998)
			{
				CreateTimer(0.1, BlockingTimer,client);
				Spam[client]=10;

				// force player into slot 0 immediately
				new weaponslot = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponslot);
			}
		}
	}
}

// Timer created to prevent player from switching back due to any possible client lag issues.
// Remove the timer at your own risk.
public Action:BlockingTimer(Handle:timer, any:client)
{
 	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		// informs player that the vaccinator doesn't work currently.
		PrintCenterText(client,"The Vaccinator is not allowed right now as it doesn't work properly. All Weapons Cooldown %i seconds.",Spam[client]);

		// This forces the player to use slot 0 until timer is off.
		new weaponX = GetPlayerWeaponSlot(client, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);

		// Make sure player can not switch back to weapon by adding a built in timer.
		// this ensures if a player is lagging that they will still not be able to use
		// the weapon.
		Spam[client]=Spam[client]-1;
		if(Spam[client]>0)
			CreateTimer(1.0, BlockingTimer,client);
	}
}