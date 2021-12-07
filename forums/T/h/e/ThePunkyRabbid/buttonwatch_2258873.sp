#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>
#tryinclude <colors_csgo>


public Plugin:myinfo =
{
name = "4way-fix2",
author = "Niko",
description = "Generates an output when a button is shot",
version = "2.0",
url = "forum.Elite-HunterZ.info"
}
new String:color_tag[16]         = "{olive}";
new String:color_name[16]        = "{green}";
new String:color_steamid[16]     = "{default}";
new String:color_use[16]         = "{red}";
new String:color_pickup[16]      = "{red}";
new String:color_drop[16]        = "{red}";
new String:color_disconnect[16]  = "{red}";
new String:color_death[16]       = "{red}";
new String:color_warning[16]     = "{red}";

public OnPluginStart()
{
HookEntityOutput( "func_button", "OnPressed", Event_Impact)
HookEntityOutput( "func_button", "OnDamaged", Event_Impact)
HookEntityOutput( "func_physbox", "OnBreak", Event_Impact2)
}

public Event_Impact(const String:output[], caller, activator, Float:Any) /*what is "Float:Any" exactly? what does it do?*/
{
decl String:user[MAX_NAME_LENGTH];
decl String:userid[512];
decl String:entity[512];
GetEntPropString(caller, Prop_Data, "m_iName", entity, sizeof(entity));
GetClientName(activator, user, sizeof(user));
GetClientAuthString(activator, userid, sizeof(userid));
PrintToChatAll("Entity name: %s \nActivator: %s \nUserID: %s",entity,user,userid);
return Plugin_Handled;
}
public Event_Impact2(const String:output[], caller, attacker, Float:Any) /*what is "Float:Any" exactly? what does it do?*/
{
decl String:user[MAX_NAME_LENGTH];
decl String:userid[512];
decl String:entity[512];
GetEntPropString(caller, Prop_Data, "m_iName", entity, sizeof(entity));
GetClientName(attacker, user, sizeof(user));
GetClientAuthString(attacker, userid, sizeof(userid));
PrintToChatAll("Entity name: %s \nActivator: %s \nUserID: %s",entity,user,userid);
return Plugin_Handled;
}