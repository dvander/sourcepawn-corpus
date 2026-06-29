#include <sourcemod>
#include <sdktools>

#define VERSION "1"

	public Plugin:myinfo = 
	{
		name = "Umbrella Unit",
		author = ".Echo",
		description = "Turns all players into Umbrella soldiers",
		version = VERSION,
		url = "www.ke0.us"
	}
	
    public OnMapStart()
    {
        HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
        InitPrecache();
    }

    InitPrecache()
    {
        PrecacheModel("models/player/natalya/umbrella_sas/umbrella_sas.mdl");

        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.mdl");
        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.dx90.vtx");
        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.dx80.vtx");
        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.phy");
        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.sw.vtx");
        AddFileToDownloadsTable("models/player/natalya/umbrella_sas/umbrella_sas.vvd");
        AddFileToDownloadsTable("materials/models/player/natalya/umbrella_sas/ct_sas.vtf");
        AddFileToDownloadsTable("materials/models/player/natalya/umbrella_sas/ct_sas_normal.vtf");
        AddFileToDownloadsTable("materials/models/player/natalya/umbrella_sas/ct_sas.vmt");
        AddFileToDownloadsTable("materials/models/player/natalya/umbrella_sas/ct_sas_glass.vmt");
    }

    public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
    {
        new user = GetClientOfUserId(GetEventInt(event, "userid"));
        SetEntityModel(user,"models/player/natalya/umbrella_sas/umbrella_sas.mdl");
    }