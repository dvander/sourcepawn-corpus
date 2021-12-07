
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define VERSION "v1.0"

new g_Drops[MAXPLAYERS+1];


public Plugin:myinfo =
{
	name = "SM Gun Spamming Slayer",
	author = "Franc1sco Steam: franug",
	description = "Slay gun spammers",
	version = VERSION,
	url = "http://servers-cfg.foroactivo.com/"
}

public OnPluginStart()
{
	CreateConVar("sm_GunSpammingSlayer", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_start", Event_RoundStart);

}

public OnClientPostAdminCheck(client)
{
    g_Drops[client] = 0;
}

public Action:OnWeaponDrop(client, weapon)
{
    g_Drops[client] += 1;
    if (g_Drops[client] >= 20)
    {
        ForcePlayerSuicide(client);
	decl String:other[32];
	GetClientName(client, other, sizeof(other));
        PrintToChatAll("\x04[GunSpammingSlayer]\x01 %s is slayed for spamming guns");
    }
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= (GetMaxClients()+1); i++)
	{
		if (IsClientInGame(i))
		{
                        g_Drops[i] = 0;
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}


