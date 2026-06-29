#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_NAME "Scawp"
#define PLUGIN_AUTHOR "Kewaii"
#define PLUGIN_DESCRIPTION "Switch from Scout and AWP"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_TAG "[Scawp by Kewaii]"
public Plugin:myinfo =
{
    name        =    PLUGIN_NAME,
    author        =    PLUGIN_AUTHOR,
    description    =    PLUGIN_DESCRIPTION,
    version        =    PLUGIN_VERSION,
    url            =    "http://kewaiigamer.info"
};

new hasScout[MAXPLAYERS+1] = {false, ...};
public OnPluginStart()
{
	RegAdminCmd("sm_scout", Command_Scout, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_scawp", Command_Scout, ADMFLAG_CUSTOM1);
}


public Action:Command_Scout(client, args)
{
	new wep = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if (!hasScout[client])
	{
		if(wep != -1)
			AcceptEntityInput(wep, "Kill");
		new newWep = GivePlayerItem(client, "weapon_ssg08");
		SetEntPropEnt(newWep, Prop_Data, "m_hOwnerEntity", client);
		EquipPlayerWeapon(client, newWep);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", newWep);
		hasScout[client] = true;
	}	
	else
	{
		if(wep != -1)
			AcceptEntityInput(wep, "Kill");
		new newWep = GivePlayerItem(client, "weapon_awp");
		SetEntPropEnt(newWep, Prop_Data, "m_hOwnerEntity", client);
		EquipPlayerWeapon(client, newWep);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", newWep);
		hasScout[client] = false;
	}
}

