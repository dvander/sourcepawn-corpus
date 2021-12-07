#include <tf2_stocks>

#define PLUGIN_VERSION "0.0.0"

public Plugin:myinfo = 
{
	name = "[TF2] Light Me!",
	author = "DarthNinja",
	description = "Fire! Fire! Fire!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
}

public OnPluginStart()
{
	RegAdminCmd("lightme", lightme, ADMFLAG_SLAY);
}

public Action:lightme(client, args)
{	
	new entity = GetPlayerWeaponSlot(client, 0);
	SetEntProp(entity, Prop_Send, "m_bArrowAlight", 1);
	return Plugin_Handled;
}


