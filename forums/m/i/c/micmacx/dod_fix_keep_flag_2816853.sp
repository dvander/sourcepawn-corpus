#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Fix to keep original flag Flag",
	author = "Micmacx",
	description = "Fix to keep original flag Flag",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
}

public OnPluginStart()
{

	CreateConVar("dod_fix_keep_flag", PLUGIN_VERSION, "DoD plugin Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	HookEventEx("dod_round_start", OnRound, EventHookMode_Post)
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/alliedflag.vmt");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/alliedflag.vtf");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/axisflag.vmt");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/axisflag.vtf");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/britflag.vmt");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/britflag.vtf");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/neutralflag.vmt");
	AddFileToDownloadsTable("materials/models/mapmodels/flags2/neutralflag.vtf");
	AddFileToDownloadsTable("models/mapmodels/flags2.dx80.vtx");
	AddFileToDownloadsTable("models/mapmodels/flags2.dx90.vtx");
	AddFileToDownloadsTable("models/mapmodels/flags2.mdl");
	AddFileToDownloadsTable("models/mapmodels/flags2.sw.vtx");
	AddFileToDownloadsTable("models/mapmodels/flags2.vvd");
	PrecacheModel("models/mapmodels/flags2.mdl");
}

public OnClientAuthorized(client, const String:auth[])
{

	QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);

}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if(IsClientConnected(client))
	{
		if(strcmp(cvarValue1, "none", true) == 0)
		{
			KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
		}
		if(strcmp(cvarValue1, "mapsonly", true) == 0)
		{
			KickClient(client, "Please enable the option for skins - Allow custom files or nosounds - in Day of defeat:source-->options-->Multiplayer");
		}
	}
}

public Action:OnRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	new entity;
	while ((entity = FindEntityByClassname(entity, "dod_control_point")) != -1)
	{
	
 
		if(IsValidEntity(entity))
		{
			new String:modelname[128];
			GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
			if (StrEqual(modelname, "models/mapmodels/flags.mdl"))
			{
				SetEntityModel(entity, "models/mapmodels/flags2.mdl")
				DispatchKeyValue(entity, "point_allies_model", "models/mapmodels/flags2.mdl");
				DispatchKeyValue(entity, "point_axis_model", "models/mapmodels/flags2.mdl");
				DispatchKeyValue(entity, "point_reset_model", "models/mapmodels/flags2.mdl");
			}
		}
	}
}
