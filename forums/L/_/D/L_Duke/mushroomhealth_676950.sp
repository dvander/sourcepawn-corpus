#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0.2"

#define MDL_MUSH "models/items/ld1/mushroom_large.mdl"
#define SND_MUSH "items/mushroom1.wav"
#define SND_PRE_MUSH "sound/items/mushroom1.wav"

new Handle:cvSize = INVALID_HANDLE;
new Handle:cvDieTime = INVALID_HANDLE;
new Handle:cvMedicOnly = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Mushroom Health",
	author = "L. Duke",
	description = "players drop mushroom health packs when they die",
	version = PLUGIN_VERSION,
	url = "www.lduke.com"
}

public OnPluginStart()
{
	CreateConVar("sm_mh_version", PLUGIN_VERSION, "Mushroom Health version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvSize = CreateConVar("sm_mh_healthsize", "3", "medkit equivalent (1=small, 2=medium, 3=large)", 0, true, 1.0, true, 3.0); 
	cvDieTime = CreateConVar("sm_mh_time", "15.0", "time before mushroom is removed (seconds)", 0, true, 1.0, true, 60.0); 
	cvMedicOnly = CreateConVar("sm_mh_mediconly", "0", "only the medic drops mushrooms on death (0=all players, 1=medic only)");
	
	HookEvent("player_death", DropMeAMushroom);
		
}

public OnEventShutdown()
{
	UnhookEvent("player_death", DropMeAMushroom);
}

public OnMapStart()
{
	
	// precache and download models
	PrecacheModel("models/items/medkit_large.mdl", true); 
	PrecacheModel(MDL_MUSH, true);
	AddFolderToDownloadTable("models/items/ld1");
	AddFolderToDownloadTable("materials/models/items/ld1");	
	
	// precache and download sounds
	PrecacheSound(SND_MUSH, true);
	AddFileToDownloadsTable(SND_PRE_MUSH);
}

public Action:DropMeAMushroom(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarBool(cvMedicOnly))
	{
		if (TF2_GetPlayerClass(client)!=TFClass_Medic)
			return;
	}

	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	
	// setup mushroom size
	new size=GetConVarInt(cvSize);
	new String:kittype[256];
	switch (size)
	{
		case 1:
		{
			strcopy(kittype, sizeof(kittype), "item_healthkit_small");
		}
		case 2:
		{
			strcopy(kittype, sizeof(kittype), "item_healthkit_medium");
		}
		default:
		{
			strcopy(kittype, sizeof(kittype), "item_healthkit_full");
		}
		
	}
	
	// create new entity
	new ent = CreateEntityByName(kittype);
	if (IsValidEntity(ent))
	{
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		SetEntityModel(ent, MDL_MUSH);
		HookSingleEntityOutput(ent, "OnPlayerTouch", PlayerPickedUp, true);
		CreateTimer(GetConVarFloat(cvDieTime), DieMushroomDie, ent);
	}
}

public Action:DieMushroomDie(Handle:timer, any:item)
{
	if(IsValidEntity(item))
	{
		decl String:ModelName[128];
		GetEntPropString(item, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
		if(!strcmp(MDL_MUSH, ModelName, false))
		{
			RemoveEdict(item);
		}
		else
		{
			//PrintToServer("not deleting mushroom, model does not match '%s'", ModelName);

		}
	}
	else
	{
		//PrintToServer("not deleting mushroom, invalid entity");
	}	
}

public PlayerPickedUp(const String:output[], caller, activator, Float:delay)
{
	new Float:pos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
	EmitSoundToAll(SND_MUSH, 0, _, _, _, _, _, _, pos);
	RemoveEdict(caller);
}

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
{
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type))     
	{
		if(Type == FileType_Directory && recursive)         
		{           
			FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
			AddFolderToDownloadTable(FileName);
			continue;
			
		}                 
		if (Type != FileType_File) continue;
		FormatEx(Path, sizeof(Path), "%s/%s", Directory, FileName);
		AddFileToDownloadsTable(Path);
	}
	return;	
}
