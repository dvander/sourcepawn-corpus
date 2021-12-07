#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new m_iMVPs_offset;
new bool:g_ballow[MAXPLAYERS+1];

public Plugin:myinfo = {
	name 		= "MVP 1337",
	author 		= "",
	description = "Give certain admins 1337 MVP stars",
	version 	= "0",
};

public OnPluginStart()
{
	m_iMVPs_offset = FindSendPropInfo("CCSPlayerResource", "m_iMVPs");
}

public OnClientPostAdminCheck(client)
{
	g_ballow[client] = CheckCommandAccess(client, "sm_mvp_leet", ADMFLAG_CUSTOM1);
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrContains(classname, "_player_manager") != -1)
	{
		SDKHook(entity, SDKHook_ThinkPost, PlayerManager_OnThinkPost);
	}
}

public PlayerManager_OnThinkPost(entity)
{
	new m_iMVPs[MaxClients];
	GetEntDataArray(entity, m_iMVPs_offset, m_iMVPs, MaxClients);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && g_ballow[i])
		{
			m_iMVPs[i] = 1337;
		}
	}
	SetEntDataArray(entity, m_iMVPs_offset, m_iMVPs, MaxClients);
}