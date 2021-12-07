#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:Cvar_Listen;
new Handle:Cvar_Alltalk;

public Plugin:myinfo =
{
	name = "Admin Listener",
	author = "Maxis010",
	description = "Admins hear all Voice chat regardless of All Talk",
	version = "1.0.0",
	url = ""
};

public OnPluginStart()
{
	Cvar_Listen = CreateConVar("sm_listener_enabled", "0", "Admin Listener Enabled/Disabled");
	Cvar_Alltalk = FindConVar("sv_alltalk");
}

public OnClientPostAdminCheck()
{
	CheckAdmin();
}

public CheckAdmin()
{
	if(GetConVarInt(Cvar_Listen) == 1 && GetConVarInt(Cvar_Alltalk) == 0)
	{
		new maxclients = GetMaxClients();
		for(new i=1; i <= maxclients; i++)
		{
			if(GetAdminFlag(i, ADMFLAG_ROOT) == true)
			{
				SetClientListeningFlags(i, VOICE_LISTENALL);
			}
		}
	}
}