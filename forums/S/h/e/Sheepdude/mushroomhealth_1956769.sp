#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.1"

#define SND_MUSH "items/mushroom1.wav"
#define SND_PRE_MUSH "sound/items/mushroom1.wav"
new String:MDL_MUSH[3][48] = {"models/items/medkit_small.mdl", "models/items/medkit_medium.mdl", "models/items/medkit_large.mdl"};

new Handle:h_cvarVersion = INVALID_HANDLE;
new Handle:h_cvarEnable = INVALID_HANDLE;
new Handle:h_cvarHealth = INVALID_HANDLE;
new Handle:h_cvarMaxHealth = INVALID_HANDLE;
new Handle:h_cvarDieTime = INVALID_HANDLE;
new Handle:h_cvarOffset = INVALID_HANDLE;
new Handle:h_cvarModel = INVALID_HANDLE;

new bool:g_cvarEnable;
new g_cvarHealth;
new g_cvarMaxHealth;
new Float:g_cvarDieTime;
new Float:g_cvarOffset;
new g_cvarModel;

public Plugin:myinfo = 
{
	name = "Mushroom Health",
	author = "L. Duke, Sheepdude",
	description = "Players drop mushroom health packs when they die.",
	version = PLUGIN_VERSION,
	url = "www.lduke.com"
}

/**********
 *Forwards*
***********/

public OnPluginStart()
{
	// Plugin convars
	h_cvarVersion = CreateConVar("sm_mh_version", PLUGIN_VERSION, "Mushroom Health plugin version", FCVAR_SPONLY|FCVAR_NOTIFY);
	h_cvarEnable = CreateConVar("sm_mh_enable", "1", "1 - Enable or 0 - Disable plugin.", 0, true, 0.0, true, 1.0);
	h_cvarHealth = CreateConVar("sm_mh_health", "100", "How much health to restore after touching a mushroom", 0);
	h_cvarMaxHealth = CreateConVar("sm_mh_maxhealth", "100", "The maximum health a player can heal to", 0);
	h_cvarDieTime = CreateConVar("sm_mh_time", "15.0", "Time until the mushroom disappears (seconds).", 0, true, 1.0, true, 60.0);
	h_cvarOffset = CreateConVar("sm_mh_offset", "0.0", "Vertical position offset for the mushrooms.", 0);
	h_cvarModel = CreateConVar("sm_mh_model", "1", "Mushroom model (0 - small, 1 - medium, 2 - large)", 0, true, 0.0, true, 2.0);
	
	// Convar hooks
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	HookConVarChange(h_cvarEnable, OnConvarChanged);
	HookConVarChange(h_cvarHealth, OnConvarChanged);
	HookConVarChange(h_cvarMaxHealth, OnConvarChanged);
	HookConVarChange(h_cvarDieTime, OnConvarChanged);
	HookConVarChange(h_cvarOffset, OnConvarChanged);
	HookConVarChange(h_cvarModel, OnConvarChanged);
	
	AutoExecConfig(true, "mushroomhealth");
	UpdateAllConvars();
	
	// Event hooks
	if(g_cvarEnable)
		HookEvent("player_death", OnPlayerDeath);
}

public OnMapStart()
{
	// Precache and download models
	for(new i = 0; i < sizeof(MDL_MUSH); i++)
		PrecacheModel(MDL_MUSH[i], true);
	AddFolderToDownloadTable("models/items");
	AddFolderToDownloadTable("materials/models/items");	
	
	// Precache and download sounds
	PrecacheSound(SND_MUSH, true);
	AddFileToDownloadsTable(SND_PRE_MUSH);
}

/********
 *Plugin*
*********/

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Make sure client is a player
	if(client < 1 || client > MaxClients)
		return Plugin_Handled;

	// Obtain player position and change vertical offset
	new Float:pos[3];
	GetClientAbsOrigin(client, pos);
	pos[2] += g_cvarOffset;
	
	// Create mushroom entity
	new ent = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(ent))
	{
		DispatchKeyValue(ent, "model", MDL_MUSH[g_cvarModel]);
		DispatchKeyValue(ent, "solid", "6"); 
		DispatchSpawn(ent);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		SDKHook(ent, SDKHook_StartTouch, MushroomTouch);
		CreateTimer(g_cvarDieTime, KillMushroom, ent);
	}
	return Plugin_Handled;
}

public Action:KillMushroom(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		// Check that the entity at the index is still the mushroom
		decl String:ModelName[128];
		GetEntPropString(entity, Prop_Data, "m_ModelName", ModelName, sizeof(ModelName));
		if(!strcmp(MDL_MUSH[g_cvarModel], ModelName, false))
			RemoveEdict(entity);
	}	
}

/**********
 *SDKHooks*
***********/

public MushroomTouch(iMushroom, iEntity) 
{
	// Continue only if the touching entity is a player
	if(iEntity > 0 && iEntity <= MaxClients && IsPlayerAlive(iEntity))
	{
		new Float:pos[3];
		GetEntPropVector(iMushroom, Prop_Send, "m_vecOrigin", pos);
		EmitSoundToAll(SND_MUSH, 0, _, _, _, _, _, _, pos);
		RemoveEdict(iMushroom);
		new health = GetClientHealth(iEntity);
		if(health < g_cvarMaxHealth)
		{
			if(health + g_cvarHealth <= g_cvarMaxHealth)
				SetEntityHealth(iEntity, health + g_cvarHealth);
			else
				SetEntityHealth(iEntity, g_cvarMaxHealth);
		}
	}
}

/********
 *Stocks*
*********/

stock AddFolderToDownloadTable(const String:Directory[], bool:recursive=false) 
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

/*********
 *Convars*
**********/

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == h_cvarEnable)
	{
		g_cvarEnable = GetConVarBool(h_cvarEnable);
		if(g_cvarEnable)
			HookEvent("player_death", OnPlayerDeath);
		else
			UnhookEvent("player_death", OnPlayerDeath);
	}
	else
		UpdateAllConvars();
}

UpdateAllConvars()
{
	SetConVarString(h_cvarVersion, PLUGIN_VERSION);
	g_cvarEnable = GetConVarBool(h_cvarEnable);
	g_cvarHealth = GetConVarInt(h_cvarHealth);
	g_cvarMaxHealth = GetConVarInt(h_cvarMaxHealth);
	g_cvarDieTime = GetConVarFloat(h_cvarDieTime);
	g_cvarOffset = GetConVarFloat(h_cvarOffset);
	g_cvarModel = GetConVarInt(h_cvarModel);
}