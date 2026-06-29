#include <sourcemod>
#include <sdktools>





//Change it and recompile if you want to use other overlay
#define OVERLAY50 "overlays/+50"
#define OVERLAY100 "overlays/+100"
//





#define PLUGIN_VERSION "1.0"

new muertes[MAXPLAYERS+1] = 0;


public Plugin:myinfo = {
	name = "SM Call of duty mod",
	author = "Franc1sco steam: franug",
	description = "cod",
	version = PLUGIN_VERSION,
	url = "http://www.servers-cfg.foroactivo.com"
};

public OnPluginStart() 
{
	CreateConVar("sm_codmod_version", PLUGIN_VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre)

	HookEvent("round_start", Event_RoundStart);
}

public OnMapStart()
{

	decl String:download1[128];
	Format(download1, sizeof(download1), "materials/%s.vtf",OVERLAY50);
	AddFileToDownloadsTable(download1);

	decl String:download2[128];
	Format(download2, sizeof(download2), "materials/%s.vmt",OVERLAY50);
	AddFileToDownloadsTable(download2);

	decl String:download3[128];
	Format(download3, sizeof(download3), "%s.vtf",OVERLAY50);
	PrecacheDecal(download3);

	decl String:download4[128];
	Format(download4, sizeof(download4), "%s.vmt",OVERLAY50);
	PrecacheDecal(download4);



	decl String:download5[128];
	Format(download5, sizeof(download5), "materials/%s.vtf",OVERLAY100);
	AddFileToDownloadsTable(download5);

	decl String:download6[128];
	Format(download6, sizeof(download6), "materials/%s.vmt",OVERLAY100);
	AddFileToDownloadsTable(download6);

	decl String:download7[128];
	Format(download7, sizeof(download7), "%s.vtf",OVERLAY100);
	PrecacheDecal(download7);

	decl String:download8[128];
	Format(download8, sizeof(download8), "%s.vmt",OVERLAY100);
	PrecacheDecal(download8);

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x))
		{
			muertes[x] = 0;
		}
	}
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!IsValidClient(client))
		return;

	++muertes[client];

	new count = 0;
	if(muertes[client] >= 3)
	{
		count = GetClientFrags(client);
		count += 99;
		SetEntProp(client, Prop_Data, "m_iFrags", count);
		ShowOverlayToClient(client,OVERLAY100);
		muertes[client] = 0;
	}
	else
	{
		count = GetClientFrags(client);
		count += 49;
		SetEntProp(client, Prop_Data, "m_iFrags", count);
		ShowOverlayToClient(client,OVERLAY50);
	}

	CreateTimer(0.5, clean, client);
}

public Action:clean(Handle:timer, any:client)
{
	if (IsClientInGame(client))
		ShowOverlayToClient(client,"");
}

ShowOverlayToClient(client, const String:overlaypath[])
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}


public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
