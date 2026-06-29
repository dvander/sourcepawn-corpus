#include <sourcemod>
#include <sdkhooks>

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PreThinkPost, Hook_PreThinkPost);
}

public Hook_PreThinkPost(client)
{
    SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
}