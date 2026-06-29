#include <sourcemod>
#include <sdktools>

#pragma newdecls required
 
bool PlayerIsAlreadyInGodMode[MAXPLAYERS+1] = false;
 
public Plugin myinfo =
{
    name = "BuyZone Protection",
    author = "SkippeR",
    description = "",
    version = "1.0",
    url = "http://steamcommunity.com/id/XxSkippeRxX/"
};
 
public void OnPluginStart()
{
    HookEvent("enter_buyzone", Event_entrarbuyzone, EventHookMode_Post);
    HookEvent("exit_buyzone", Event_sairbuyzone, EventHookMode_Post);
}
 
public Action Event_entrarbuyzone(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!PlayerIsAlreadyInGodMode[client])
	{
        PlayerIsAlreadyInGodMode[client] = true;
        SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
        PrintToChat(client, "[\x02BuyZone - Protect\x01] You have entered \x02BuyZone\01, you are \x02protected\x01 from any damage!");
    }
}
 
public Action Event_sairbuyzone(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(PlayerIsAlreadyInGodMode[client])
	{
	    PlayerIsAlreadyInGodMode[client] = false;
        PrintToChat(client, "[\x02BuyZone - Protect\x01] You are \x04unprotected\x01 from any damage!");
        SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
    }
}