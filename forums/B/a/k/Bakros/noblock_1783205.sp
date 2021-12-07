#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <sendproxy>
#define VERSION "1.0.1"

#pragma semicolon 1

new Handle:sm_noblock;
new Handle:g_CvarVersion;

new bool:g_Enabled;
public Plugin:myinfo =
{
	name = "Bakr's NoBlock",
	author = "Bakr",
	description = "A new NoBlock plugin, designed to avoid the Mayhem bug.",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	g_CvarVersion = CreateConVar("sm_noblock_ver", VERSION, "Bakr's Noblock version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	SetConVarString(g_CvarVersion,VERSION);
	sm_noblock = CreateConVar("sm_noblock_enabled", "1","Enable/Disable noblock",0,true,0.0,true,1.0);
	g_Enabled = GetConVarBool(sm_noblock);
	HookConVarChange(sm_noblock,ConVarChange_Enabled);
	
	if(g_Enabled){
		Hook();
	}
}

public ConVarChange_Enabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_Enabled = GetConVarBool(sm_noblock);
	if (g_Enabled) {
		Hook();
	} else {
		UnHook();
	}
}

Hook(){
	for(new client=1;client<=MaxClients;client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
		SendProxy_Hook(client, "m_CollisionGroup", Prop_Int, ProxyCallback);
	}
}

UnHook()
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(!IsClientInGame(client))
		{
			continue;
		}
		
		SDKUnhook(client, SDKHook_ShouldCollide, ShouldCollide);
		SendProxy_Unhook(client, "m_CollisionGroup", ProxyCallback);
	}
}

public OnClientDisconnect(client){
	if(g_Enabled){
		SDKUnhook(client, SDKHook_ShouldCollide, ShouldCollide);
		SendProxy_Unhook(client, "m_CollisionGroup", ProxyCallback);
	}
}

public OnClientPutInServer(client)
{
	if(g_Enabled){
		SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
		SendProxy_Hook(client, "m_CollisionGroup", Prop_Int, ProxyCallback);
	}
}

public Action:ProxyCallback(entity, String:propname[], &iValue, element)
{	
	iValue = 2;
	return Plugin_Changed;
}

public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:result)
{
	if (contentsmask == 33636363)
	{
		result = false;
		return false;
	}
	
	return true;
}