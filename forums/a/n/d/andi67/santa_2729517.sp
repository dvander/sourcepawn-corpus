#include <sourcemod>
#include <sdktools>

#pragma newdecls required


public void OnPluginStart() 
{
    HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
} 

public Action Event_Spawn(Handle event,  const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(client))
	{
		int team = GetClientTeam(client);
		if (team==2)
		{
			SetEntityModel(client,"models/player/vad36santa/red.mdl");
		}
		else if (team==3)
		{
			SetEntityModel(client,"models/player/vad36santa/blue.mdl");
		}		
	}
}

public void OnMapStart()
{
	PrecacheModel("models/player/vad36santa/red.mdl", true);
	PrecacheModel("models/player/vad36santa/blue.mdl", true);	
	
	AddFileToDownloadsTable("models/player/vad36santa/red.dx80.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/red.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/red.mdl");
	AddFileToDownloadsTable("models/player/vad36santa/red.phy");
	AddFileToDownloadsTable("models/player/vad36santa/red.sw.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/red.vvd");

	AddFileToDownloadsTable("models/player/vad36santa/blue.dx80.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/blue.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/blue.mdl");
	AddFileToDownloadsTable("models/player/vad36santa/blue.phy");
	AddFileToDownloadsTable("models/player/vad36santa/blue.sw.vtx");
	AddFileToDownloadsTable("models/player/vad36santa/blue.vvd");

	AddFileToDownloadsTable("materials/models/player/vad36santa/Santa_N.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36santa/Santa_D.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36santa/Santa_D.vtf");
	AddFileToDownloadsTable("materials/models/player/vad36santa/Santa_D_B.vmt");
	AddFileToDownloadsTable("materials/models/player/vad36santa/Santa_D_B.vtf");

	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.sw.vtx");
	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.vvd");
	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.dx80.vtx");
	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.dx90.vtx");
	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.mdl");
	AddFileToDownloadsTable("models/player/vad36lollipop/lolli.phy");
}