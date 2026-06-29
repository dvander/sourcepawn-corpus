#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.1"

#define MAX_CLAWS 50
#define HUMAN_KNIFE "models/weapons/v_knife_t.mdl"

new Handle:CvarVersion, Handle:CvarEnable, Handle:CvarClawsPath, Handle:DownListPath;

new bool:enabled;

new String:Path[PLATFORM_MAX_PATH];
new String:downlistpath[PLATFORM_MAX_PATH];
new String:Claws[MAX_CLAWS+1][PLATFORM_MAX_PATH];

new MaxClaws, Human_Knife, viewModelweaponindex[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Zombie Claws",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Zombie Claws",
	version = PLUGIN_VERSION,
	url = "http://www.hlmod.ru/"
};

public OnPluginStart()
{
	CvarEnable = CreateConVar("zr_zombieclaws_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	CvarVersion = CreateConVar("zr_zombieclaws_version", PLUGIN_VERSION, "Version of the plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CvarClawsPath = CreateConVar("zr_zombieclaws_path", "cfg/sourcemod/zombiereloaded/zombie_claws.txt", "Path to the zombie claws list");
	DownListPath = CreateConVar("zr_zombieclaws_downloadpath", "addons/sourcemod/data/downlist_zrclaws.ini", "Path to the download list of zombie claws");
	
	HookConVarChange(CvarEnable, CvarChanges);
	HookConVarChange(CvarClawsPath, CvarChanges);
	HookConVarChange(CvarEnable, CvarChanges);
	HookConVarChange(DownListPath, CvarChanges);
	
	AutoExecConfig(true, "zombiereloaded/zombie_claws");
}

public OnMapStart()
{
	Human_Knife = PrecacheModel(HUMAN_KNIFE);
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

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (!enabled)
		return;
		
	decl String:Weapon[32];
	new ActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	GetEdictClassname(ActiveWeapon, Weapon, sizeof(Weapon));
	
	if (StrEqual(Weapon, "weapon_knife"))
	{
		new ClawNumber = Math_GetRandomInt(1, MaxClaws);
		Weapon_SetViewModelIndex(client, Claws[ClawNumber]);
	}
}

public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	if (viewModelweaponindex[client])
	{
		SetEntProp(viewModelweaponindex[client], Prop_Send, "m_nModelIndex", Human_Knife);
		ChangeEdictState(viewModelweaponindex[client], FindDataMapOffs(viewModelweaponindex[client], "m_nModelIndex"));
	}
}

public OnClientDisconnect_Post(client)
{
	viewModelweaponindex[client] = 0;
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

Weapon_SetViewModelIndex(client, String:Model[])
{
	if (StrEqual(Model, "-1", false) || !IsClientInGame(client) || !IsPlayerAlive(client))
		return;
		
	new index = PrecacheModel(Model);
	
	if (index < 1)
	{
		LogError("Unable to precache model '%s'", Model);
		return;
	}
	
	viewModelweaponindex[client] = Weapon_GetViewModelIndex(client);
	
	if (viewModelweaponindex[client] < 1)
	{
		LogError("Unable to get a viewmodel index");
		return;
	}
	
	SetEntProp(viewModelweaponindex[client], Prop_Send, "m_nModelIndex", index);
	ChangeEdictState(viewModelweaponindex[client], FindDataMapOffs(viewModelweaponindex[client], "m_nModelIndex"));
}

Weapon_GetViewModelIndex(client)
{
	new index = -1;
	while ((index = FindEntityByClassname2(index, "predicted_viewmodel")) != -1)
	{
		new Owner = GetEntPropEnt(index, Prop_Send, "m_hOwner");
		new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		new Weapon = GetEntPropEnt(index, Prop_Send, "m_hWeapon");
		if (Owner != client)
			continue;
		if (ClientWeapon != Weapon)
			continue;
		return index;
	}
	return -1;
}

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