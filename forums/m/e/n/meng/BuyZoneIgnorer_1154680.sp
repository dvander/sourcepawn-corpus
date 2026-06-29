#include <sourcemod>
#include <sdkhooks>

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink);
}

public OnPreThink(client)
{
	SetEntProp(client, Prop_Send, "m_bInBuyZone", 1);
}