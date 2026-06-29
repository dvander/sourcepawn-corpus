#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "3.0.0"

#define MDL_MUSH "models/items/ld1/mushroom_large.mdl"
#define SND_MUSH "items/mushroom1.wav"
#define SND_PRE_MUSH "sound/items/mushroom1.wav"
#define MDL_LARGEMEDKIT "models/items/medkit_large.mdl"
#define MDL_BDAYKIT "models/items/medkit_large_bday.mdl"
#define MDL_HALLOWEENKIT "models/props_halloween/halloween_medkit_large.mdl"

new Handle:HealthSize,
Handle:DieTime,
Handle:MedicOnly,
Handle:MushroomSize,
Handle:DropChance = INVALID_HANDLE;

new String:medSize[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "[TF2] Mushroom Health",
	author = "L. Duke, Updated by Chaosxk",
	description = "Players drop health mushroom pack when they die.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart() {
	CreateConVar("sm_mh_version", PLUGIN_VERSION, "Mushroom Health version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HealthSize = CreateConVar("sm_mh_healthsize", "0", "Size of mushroom? (0 - Small || 1 - Medium || 2 - Large)", 0, true, 1.0, true, 3.0); 
	DieTime = CreateConVar("sm_mh_time", "15", "Time before mushroom is removed. (Default: 15)"); 
	MedicOnly = CreateConVar("sm_mh_mediconly", "0", "Who can drop mushrooms? (1 - Medic only || 0 - All)");
	MushroomSize = CreateConVar("sm_mh_size", "1.0", "How big should mushrooms be? (Default: 1.0)");
	DropChance = CreateConVar("sm_mh_dropchance", "0.65", "Chance of mushroom dropping. (0.0 - 1.0) (Default: 0.65)");
	HookEvent("player_death", DropMushroom);
	AutoExecConfig(true, "mushroomhealth");
}

public OnMapStart() {
	PrecacheFiles();
}

public Action:DropMushroom(Handle:event, const String:name[], bool:dontBroadcast) {	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client)) {
		new bool:medicOnly = GetConVarBool(MedicOnly);
		new TFClassType:playerClass = TF2_GetPlayerClass(client);
		if(medicOnly == false || medicOnly == true && playerClass == TFClass_Medic) {
			if(GetRandomFloat(0.0, 1.0) <= GetConVarFloat(DropChance)) {
				switch(GetConVarInt(HealthSize)) {
					case 1: medSize = "item_healthkit_small";
					case 2: medSize = "item_healthkit_medium";
					case 3: medSize = "item_healthkit_full";
				}
				
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				
				new entity = CreateEntityByName(medSize);
				if(IsValidEntity(entity)) {
					DispatchKeyValue(entity, "powerup_model", MDL_MUSH);
					TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
					DispatchSpawn(entity);
					ActivateEntity(entity);
					//old way used OnPlayerTouchAll
					HookSingleEntityOutput(entity, "OnPlayerTouch", PlayerPickedUp, true);
					SetEntPropFloat(entity, Prop_Send, "m_flModelScale", GetConVarFloat(MushroomSize));
					CreateTimer(GetConVarFloat(DieTime), DieMushroomDie, entity);
				}
			}
		}
	}
}

public Action:DieMushroomDie(Handle:timer, any:item) {
	if(IsValidEntity(item)) {
		decl String:ModelName[PLATFORM_MAX_PATH];
		GetEntPropString(item, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
		if(StrEqual(MDL_MUSH, ModelName, false)) {
			AcceptEntityInput(item, "Kill");
		}
	}
}

public PlayerPickedUp(const String:output[], caller, activator, Float:delay) {
	new Float:pos[3];
	GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
	EmitSoundToAll(SND_MUSH, 0, _, _, _, _, _, _, pos);
	AcceptEntityInput(caller, "Kill");
}

PrecacheFiles() {
	PrecacheModel(MDL_MUSH, true);
	PrecacheModel(MDL_LARGEMEDKIT, true); 
	PrecacheModel(MDL_BDAYKIT, true);
	PrecacheModel(MDL_HALLOWEENKIT, true);

	PrecacheSound(SND_MUSH, true);
	PrecacheSound(SND_PRE_MUSH, true);
	AddFileToDownloadsTable(SND_PRE_MUSH);
	AddFolderToDownloadTable("models/items/ld1");
	AddFolderToDownloadTable("materials/models/items/ld1");
}

AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) {
	decl String:FileName[64], String:Path[512];
	new Handle:Dir = OpenDirectory(Directory), FileType:Type;
	while(ReadDirEntry(Dir, FileName, sizeof(FileName), Type)) {
		if(Type == FileType_Directory && recursive)          {           
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

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}