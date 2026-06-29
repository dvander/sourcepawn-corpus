#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#define PLUGIN_VERSION "2.0"

#define MAX_CLAWS 50
#define HUMAN_KNIFE "models/weapons/v_knife_t.mdl"

new Handle:CvarVersion, Handle:CvarEnable, Handle:CvarClawsPath, Handle:DownListPath;

new bool:enabled;

new String:Path[PLATFORM_MAX_PATH];
new String:downlistpath[PLATFORM_MAX_PATH];
new String:Claws[MAX_CLAWS+1][PLATFORM_MAX_PATH];

new MaxClaws;

#define EF_NODRAW 32


new bool:SpawnCheck[MAXPLAYERS+1];
new ClientVM[MAXPLAYERS+1][2];
new bool:IsCustom[MAXPLAYERS+1];




new ModeloJugadorP[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Zombie Claws",
	author = "Despirator and Franc1sco steam: franug",
	description = "Zombie Claws",
	version = PLUGIN_VERSION,
	url = "http://www.uea-clan.com/"
};

public OnPluginStart()
{
	CvarEnable = CreateConVar("zr_zombieclaws_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	CvarVersion = CreateConVar("zr_zombieclaws_version", PLUGIN_VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CvarClawsPath = CreateConVar("zr_zombieclaws_path", "cfg/sourcemod/zombiereloaded/zombie_claws.txt", "Path to the zombie claws list");
	DownListPath = CreateConVar("zr_zombieclaws_downloadpath", "addons/sourcemod/data/downlist_zrclaws.ini", "Path to the download list of zombie claws");
	
	HookConVarChange(CvarEnable, CvarChanges);
	HookConVarChange(CvarClawsPath, CvarChanges);
	HookConVarChange(CvarEnable, CvarChanges);
	HookConVarChange(DownListPath, CvarChanges);
	
	AutoExecConfig(true, "zombiereloaded/zombie_claws");


	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);


    
	for (new client = 1; client <= MaxClients; client++) 
	{ 
		if (IsClientInGame(client)) 
        	{
            		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
            
            		//find both of the clients viewmodels
            		ClientVM[client][0] = GetEntPropEnt(client, Prop_Send, "m_hViewModel");
            
            		new PVM = -1;
            		while ((PVM = FindEntityByClassname(PVM, "predicted_viewmodel")) != -1)
            		{
                		if (GetEntPropEnt(PVM, Prop_Send, "m_hOwner") == client)
                		{
                    			if (GetEntProp(PVM, Prop_Send, "m_nViewModelIndex") == 1)
                    			{
                        			ClientVM[client][1] = PVM;
                        			break;
                    			}
                		}
            		}
        	} 
    	}
}

public OnConfigsExecuted()
{
	enabled = GetConVarBool(CvarEnable);
	GetConVarString(CvarClawsPath, Path, sizeof(Path));
	GetConVarString(DownListPath, downlistpath, sizeof(downlistpath));
	
	File_ReadDownloadList(downlistpath);
	LoadModels();
}

public CvarChanges(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == CvarEnable)
		enabled = GetConVarBool(convar); else
	if (convar == CvarClawsPath)
		strcopy(Path, sizeof(Path), newValue); else
	if (convar == DownListPath)
		strcopy(downlistpath, sizeof(downlistpath), newValue); else
	if (convar == CvarVersion)
		if (!StrEqual(newValue, PLUGIN_VERSION))
			SetConVarString(CvarVersion, PLUGIN_VERSION);
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	if (!enabled)
		return;
		

	new ClawNumber = Math_GetRandomInt(1, MaxClaws);
	//Weapon_SetViewModelIndex(client, Claws[ClawNumber]);
	ModeloJugadorP[client] = PrecacheModel(Claws[ClawNumber]);
}

LoadModels()
{
	decl String:buf[4];
	decl String:Line[PLATFORM_MAX_PATH];
	
	new Handle:filehandle = OpenFile(Path, "r");
	
	MaxClaws = 0;
	
	if (filehandle  == INVALID_HANDLE)
	{
		LogError("Claws list %s doesn't exist", Path);
		return;
	}
	
	while(!IsEndOfFile(filehandle) && MaxClaws < MAX_CLAWS)
	{
		ReadFileLine(filehandle,Line,sizeof(Line));
	
		new pos;
		pos = StrContains((Line), "//");
		if (pos != -1)
			Line[pos] = '\0';
	
		pos = StrContains((Line), "#");
		if (pos != -1)
			Line[pos] = '\0';
			
		pos = StrContains((Line), ";");
		if (pos != -1)
			Line[pos] = '\0';
	
		TrimString(Line);
		
		if (Line[0] == '\0')
			continue;
		
		File_GetExtension(Line, buf, sizeof(buf));
		
		if (!strcmp(buf, "mdl", false) && FileExists(Line))
		{
			MaxClaws++;
			Claws[MaxClaws] = Line;
		}
		else
			LogError("Model not found or invalid %s", Line);
	}
	CloseHandle(filehandle);
	if (MaxClaws)
		LogMessage("%i claws loaded", MaxClaws);
	else
	{
		LogMessage("None claw was loaded");
		enabled = false;
	}
}

// ====================================================================================================================================================


// ====================================================================================================================================================

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

new String:_smlib_empty_twodimstring_array[][] = { { '\0' } };

stock File_AddToDownloadsTable(const String:path[], bool:recursive=true, const String:ignoreExts[][]=_smlib_empty_twodimstring_array, size=0)
{
	if (path[0] == '\0') {
		return;
	}

	if (FileExists(path)) {
		
		new String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));
		
		if (StrEqual(fileExtension, "bz2", false) || StrEqual(fileExtension, "ztmp", false)) {
			return;
		}
		
		if (Array_FindString(ignoreExts, size, fileExtension) != -1) {
			return;
		}

		AddFileToDownloadsTable(path);
	}
	else if (recursive && DirExists(path)) {

		decl String:dirEntry[PLATFORM_MAX_PATH];
		new Handle:__dir = OpenDirectory(path);

		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
				continue;
			}
			
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
		}
		
		CloseHandle(__dir);
	}
	else if (FindCharInString(path, '*', true)) {
		
		new String:fileExtension[4];
		File_GetExtension(path, fileExtension, sizeof(fileExtension));

		if (StrEqual(fileExtension, "*")) {

			decl
				String:dirName[PLATFORM_MAX_PATH],
				String:fileName[PLATFORM_MAX_PATH],
				String:dirEntry[PLATFORM_MAX_PATH];

			File_GetDirName(path, dirName, sizeof(dirName));
			File_GetFileName(path, fileName, sizeof(fileName));
			StrCat(fileName, sizeof(fileName), ".");

			new Handle:__dir = OpenDirectory(dirName);
			while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

				if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
					continue;
				}

				if (strncmp(dirEntry, fileName, strlen(fileName)) == 0) {
					Format(dirEntry, sizeof(dirEntry), "%s/%s", dirName, dirEntry);
					File_AddToDownloadsTable(dirEntry, recursive, ignoreExts, size);
				}
			}

			CloseHandle(__dir);
		}
	}

	return;
}

stock File_ReadDownloadList(const String:path[])
{
	new Handle:file = OpenFile(path, "r");
	
	if (file  == INVALID_HANDLE) {
		return;
	}

	new String:buffer[PLATFORM_MAX_PATH];
	while (!IsEndOfFile(file)) {
		ReadFileLine(file, buffer, sizeof(buffer));
		
		new pos;
		pos = StrContains(buffer, "//");
		if (pos != -1) {
			buffer[pos] = '\0';
		}
		
		pos = StrContains(buffer, "#");
		if (pos != -1) {
			buffer[pos] = '\0';
		}

		pos = StrContains(buffer, ";");
		if (pos != -1) {
			buffer[pos] = '\0';
		}
		
		TrimString(buffer);
		
		if (buffer[0] == '\0') {
			continue;
		}

		File_AddToDownloadsTable(buffer);
	}

	CloseHandle(file);
}

stock File_GetExtension(const String:path[], String:buffer[], size)
{
	new extpos = FindCharInString(path, '.', true);
	
	if (extpos == -1)
	{
		buffer[0] = '\0';
		return;
	}

	strcopy(buffer, size, path[++extpos]);
}

stock Math_GetRandomInt(min, max)
{
	new random = GetURandomInt();
	
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}



stock Array_FindString(const String:array[][], size, const String:str[], bool:caseSensitive=true, start=0)
{
	if (start < 0) {
		start = 0;
	}

	for (new i=start; i < size; i++) {

		if (StrEqual(array[i], str, caseSensitive)) {
			return i;
		}
	}
	
	return -1;
}

stock bool:File_GetFileName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	File_GetBaseName(path, buffer, size);
	
	new pos_ext = FindCharInString(buffer, '.', true);

	if (pos_ext != -1) {
		buffer[pos_ext] = '\0';
	}
}



stock bool:File_GetDirName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	new pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
		
		if (pos_start == -1) {
			buffer[0] = '\0';
			return;
		}
	}
	
	strcopy(buffer, size, path);
	buffer[pos_start] = '\0';
}

stock bool:File_GetBaseName(const String:path[], String:buffer[], size)
{	
	if (path[0] == '\0') {
		buffer[0] = '\0';
		return;
	}
	
	new pos_start = FindCharInString(path, '/', true);
	
	if (pos_start == -1) {
		pos_start = FindCharInString(path, '\\', true);
	}
	
	pos_start++;
	
	strcopy(buffer, size, path[pos_start]);
}





/// agregados


public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public OnEntityCreated(entity, const String:classname[])
{
    if (StrEqual(classname, "predicted_viewmodel", false))
    {
        SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
    }
}

//find both of the clients viewmodels
public OnEntitySpawned(entity)
{
    new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
    if ((Owner > 0) && (Owner <= MaxClients))
    {
        if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
        {
            ClientVM[Owner][0] = entity;
        }
        else if (GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 1)
        {
            ClientVM[Owner][1] = entity;
        }
    }
}

public OnPostThinkPost(client)
{
    static OldWeapon[MAXPLAYERS + 1];
    static OldSequence[MAXPLAYERS + 1];
    static Float:OldCycle[MAXPLAYERS + 1];
    
    decl String:ClassName[30];
    new WeaponIndex;
    
    //handle spectators
    if (!IsPlayerAlive(client))
    {
        return;
    }
    
    WeaponIndex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    new Sequence = GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence");
    new Float:Cycle = GetEntPropFloat(ClientVM[client][0], Prop_Data, "m_flCycle");
    
    if (!IsValidEdict(WeaponIndex) || !enabled)
    {
        new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
        EntEffects |= EF_NODRAW;
        SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
        
        IsCustom[client] = false;
            
        OldWeapon[client] = WeaponIndex;
        OldSequence[client] = Sequence;
        OldCycle[client] = Cycle;
        
        return;
    }
    
    //just stuck the weapon switching in here aswell instead of a separate hook
    if (WeaponIndex != OldWeapon[client])
    {
        GetEdictClassname(WeaponIndex, ClassName, sizeof(ClassName));
        if (StrEqual("weapon_knife", ClassName, false) && ZR_IsClientZombie(client))
        {
            //hide viewmodel
            new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
            //unhide unused viewmodel
            EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects &= ~EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
            
            //set model and copy over props from viewmodel to used viewmodel
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nModelIndex", ModeloJugadorP[client]);
            SetEntPropEnt(ClientVM[client][1], Prop_Send, "m_hWeapon", GetEntPropEnt(ClientVM[client][0], Prop_Send, "m_hWeapon"));
            
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
            SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
            
            IsCustom[client] = true;
	    //SetEntityRenderMode(WeaponIndex, RENDER_TRANSCOLOR);
	    //SetEntityRenderColor(WeaponIndex, 255, 255, 255, 0);
        }
        else
        {
            //hide unused viewmodel if the current weapon isn't using it
            new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
            
            IsCustom[client] = false;
	    //SetEntityRenderMode(WeaponIndex, RENDER_NORMAL);
	    //SetEntityRenderColor(WeaponIndex, 255, 255, 255, 255);
        }
    }
    else
    {
        if (IsCustom[client])
        {
            //copy the animation stuff from the viewmodel to the used one every frame
            SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", GetEntProp(ClientVM[client][0], Prop_Send, "m_nSequence"));
            SetEntPropFloat(ClientVM[client][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(ClientVM[client][0], Prop_Send, "m_flPlaybackRate"));
            
            if ((Cycle < OldCycle[client]) && (Sequence == OldSequence[client]))
            {
                SetEntProp(ClientVM[client][1], Prop_Send, "m_nSequence", 0);
            }
        }
    }
    //hide viewmodel a frame after spawning
    if (SpawnCheck[client])
    {
        SpawnCheck[client] = false;
        if (IsCustom[client])
        {
            new EntEffects = GetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects");
            EntEffects |= EF_NODRAW;
            SetEntProp(ClientVM[client][0], Prop_Send, "m_fEffects", EntEffects);
        }
    }
    
    OldWeapon[client] = WeaponIndex;
    OldSequence[client] = Sequence;
    OldCycle[client] = Cycle;
}


//hide viewmodel on death
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new UserId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(UserId);
    
    new EntEffects = GetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects");
    EntEffects |= EF_NODRAW;
    SetEntProp(ClientVM[client][1], Prop_Send, "m_fEffects", EntEffects);
}

//when a player repsawns at round start after surviving previous round the viewmodel is unhidden
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new UserId = GetEventInt(event, "userid");
    new client = GetClientOfUserId(UserId);
    
    //use to delay hiding viewmodel a frame or it won't work
    SpawnCheck[client] = true;
}   