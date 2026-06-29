// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================
#define PLUGIN_VERSION "3"
public Plugin:myinfo =
{
	name 			= "Gnome Hunt",
	author 			= "AlexTheRegent",
	description 	= "",
	version 		= PLUGIN_VERSION,
	url 			= ""
}

// ==============================================================================================================================
// >>> DEFINES
// ==============================================================================================================================
#pragma newdecls required
#define MPS 		MAXPLAYERS+1
#define PMP 		PLATFORM_MAX_PATH
#define MTF 		MENU_TIME_FOREVER
#define CID(%0) 	GetClientOfUserId(%0)
#define UID(%0) 	GetClientUserId(%0)
#define SZF(%0) 	%0, sizeof(%0)
#define LC(%0) 		for (int %0 = 1; %0 <= MaxClients; ++%0) if ( IsClientInGame(%0) )

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================
char 			g_rewardCommand[256];
char 			g_model[PMP];

float 			g_spawnTimeMin;
float 			g_spawnTimeMax;
float 			g_lifetimeMin;
float 			g_lifetimeMax;

bool			g_blastProtection;
bool			g_onSpawnMessage;
bool			g_onDespawnMessage;
bool			g_onDestoyedMessage;
bool			g_onDestoyedByWorldMessage;

int 			g_spawnChance;

// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================
ArrayList		g_arrayOrigin;
ArrayList		g_arrayAngles;
Handle 			g_spawnTimer;
Menu			g_menuAction;
Menu			g_menuOrigin;
Menu			g_menuAngles;
int 			g_gnome;

// ==============================================================================================================================
// >>> LOCAL INCLUDES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> FORWARDS
// ==============================================================================================================================
public void OnPluginStart() 
{
	LoadTranslations("gnome_hunt.phrases.txt");
	
	g_arrayOrigin = new ArrayList(3);
	g_arrayAngles = new ArrayList(3);
	
	g_menuAction = new Menu(Handler_MenuAction, MenuAction_DisplayItem);
	g_menuAction.AddItem("menu_action_origin", "");
	g_menuAction.AddItem("menu_action_angles", "");
	g_menuAction.AddItem("menu_action_save", "");
	g_menuAction.AddItem("menu_action_remove", "");
	g_menuAction.AddItem("menu_action_delete", "");
	
	g_menuOrigin = new Menu(Handler_MenuPosition, MenuAction_DisplayItem);
	g_menuOrigin.AddItem("menu_origin_add_x", "");
	g_menuOrigin.AddItem("menu_origin_sub_x", "");
	g_menuOrigin.AddItem("menu_origin_add_y", "");
	g_menuOrigin.AddItem("menu_origin_sub_y", "");
	g_menuOrigin.AddItem("menu_origin_add_z", "");
	g_menuOrigin.AddItem("menu_origin_sub_z", "");
	g_menuOrigin.ExitBackButton = true;
	
	g_menuAngles = new Menu(Handler_MenuRotation, MenuAction_DisplayItem);
	g_menuAngles.AddItem("menu_angles_add_x", "");
	g_menuAngles.AddItem("menu_angles_sub_x", "");
	g_menuAngles.AddItem("menu_angles_add_y", "");
	g_menuAngles.AddItem("menu_angles_sub_y", "");
	g_menuAngles.AddItem("menu_angles_add_z", "");
	g_menuAngles.AddItem("menu_angles_sub_z", "");
	g_menuAngles.ExitBackButton = true;
	
	RegAdminCmd("sm_gnome_hunt_menu", Command_GnomeHuntMenu, ADMFLAG_ROOT);
	
	CreateConVar("sm_gnome_hunt_version", PLUGIN_VERSION, "plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("sm_gnome_hunt_model", "models/props_junk/gnome.mdl", "gnome model");
	CreateConVar("sm_gnome_hunt_command", "sm_givecredits #{uid} 1000", "reward for destroying");
	CreateConVar("sm_gnome_hunt_spawn_time_min", "0.0", "min time to spawn", _, true, 0.0);
	CreateConVar("sm_gnome_hunt_spawn_time_max", "0.0", "max time to spawn", _, true, 0.0);
	CreateConVar("sm_gnome_hunt_lifetime_min", "0.0", "min lifetime", _, true, 0.0);
	CreateConVar("sm_gnome_hunt_lifetime_max", "0.0", "max lifetime (0.0 to life whole round)", _, true, 0.0);
	CreateConVar("sm_gnome_hunt_spawn_chance", "50", "spawn chance", _, true, 1.0, true, 100.0);
	CreateConVar("sm_gnome_hunt_blast_protection", "1", "Explosions can't kill gnome", _, true, 0.0, true, 1.0);
	CreateConVar("sm_gnome_hunt_spawn_message", "0", "Show message when gnome spawn", _, true, 0.0, true, 1.0);
	CreateConVar("sm_gnome_hunt_despawn_message", "0", "Show message when gnome's lifetime ends", _, true, 0.0, true, 1.0);
	CreateConVar("sm_gnome_hunt_destroyed_message", "1", "Show message when player kill gnome", _, true, 0.0, true, 1.0);
	CreateConVar("sm_gnome_hunt_destroyed_by_world_message", "1", "Show message when world kill gnome", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "gnome_hunt");
	
	HookEvent("round_start", Ev_RoundStart);
}

public void OnMapStart() 
{
	char map_name[64];
	GetCurrentMap(SZF(map_name));
	
	g_arrayOrigin.Clear();
	g_arrayAngles.Clear();
	
	char file[PMP];
	BuildPath(Path_SM, SZF(file), "configs/gnome_hunt/%s.txt", map_name);
	
	KeyValues kv = new KeyValues("data");
	if ( kv.ImportFromFile(file) ) {
		if ( kv.GotoFirstSubKey() ) {
			float array[3];
			do {
				kv.GetVector("origin", array);
				g_arrayOrigin.PushArray(array);
				
				kv.GetVector("angles", array);
				g_arrayAngles.PushArray(array);
				
			} while ( kv.GotoNextKey() );
		}
	}
	delete kv;
	
	BuildPath(Path_SM, SZF(file), "configs/gnome_hunt/dlist.txt");
	AddFilesToDownloadTable(file);
	
	g_spawnTimer = INVALID_HANDLE;
}

public void OnConfigsExecuted() 
{
	FindConVar("sm_gnome_hunt_model").GetString(SZF(g_model));
	FindConVar("sm_gnome_hunt_command").GetString(SZF(g_rewardCommand));
	
	g_spawnTimeMin= FindConVar("sm_gnome_hunt_spawn_time_min").FloatValue;
	g_spawnTimeMax= FindConVar("sm_gnome_hunt_spawn_time_max").FloatValue;
	g_lifetimeMin = FindConVar("sm_gnome_hunt_lifetime_min").FloatValue;
	g_lifetimeMax = FindConVar("sm_gnome_hunt_lifetime_max").FloatValue;
	
	g_blastProtection = FindConVar("sm_gnome_hunt_blast_protection").BoolValue;
	g_onSpawnMessage = FindConVar("sm_gnome_hunt_spawn_message").BoolValue;
	g_onDespawnMessage = FindConVar("sm_gnome_hunt_despawn_message").BoolValue;
	g_onDestoyedMessage = FindConVar("sm_gnome_hunt_destroyed_message").BoolValue;
	g_onDestoyedByWorldMessage = FindConVar("sm_gnome_hunt_destroyed_by_world_message").BoolValue;
	
	g_spawnChance = FindConVar("sm_gnome_hunt_spawn_chance").IntValue;
	
	PrecacheModel(g_model);
}

void AddFilesToDownloadTable(const char[] path)
{
	File file = OpenFile(path, "r");
	if ( file ) {
		char line[PMP];
		int slashes;
		
		while ( !file.EndOfFile() && file.ReadLine(SZF(line)) )
		{
			TrimString(line);
			slashes = StrContains(line, "//");
			if ( slashes != -1 ) {
				line[slashes] = 0;
			}
			
			if ( strlen(line) >= 4 ) {
				AddFileToDownloadsTable(line);
			}
		}
		
		CloseHandle(file);
	}
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public int Handler_MenuAction(Menu menu, MenuAction action, int client, int slot)
{
	switch ( action ) {
		case MenuAction_DisplayItem: {
			char text[128], item[32];
			menu.GetItem(slot, SZF(item));
			FormatEx(SZF(text), "%T", item, client);
			return RedrawMenuItem(text);
		}
		
		case MenuAction_Select: {
			char item[32];
			menu.GetItem(slot, SZF(item));
			
			if ( StrEqual(item, "menu_action_origin") ) {
				g_menuOrigin.SetTitle("%T", "menu_origin_title", client);
				g_menuOrigin.Display(client, MTF);
			}
			else if ( StrEqual(item, "menu_action_angles") ) {
				g_menuAngles.SetTitle("%T", "menu_angles_title", client);
				g_menuAngles.Display(client, MTF);
			}
			else if ( StrEqual(item, "menu_action_save") ) {
				int entity = EntRefToEntIndex(g_gnome);
				if ( !IsValidEntity(entity) ) {
					PrintToChat(client, "%T", "menu_gnome_not_found", client);
					return 0;
				}
				
				float origin[3], angles[3];
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
				GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angles);
				g_arrayOrigin.PushArray(origin);
				g_arrayAngles.PushArray(angles);
				
				KeyValues kv = new KeyValues("data");
				
				char map_name[64];
				GetCurrentMap(SZF(map_name));
				
				char file[PMP];
				BuildPath(Path_SM, SZF(file), "configs/gnome_hunt/%s.txt", map_name);
				kv.ImportFromFile(file);
				
				char num[4];
				int lastNum = g_arrayOrigin.Length-1;
				
				IntToString(lastNum, SZF(num));
				kv.JumpToKey(num, true);
				
				g_arrayOrigin.GetArray(lastNum, origin);
				g_arrayAngles.GetArray(lastNum, angles);
				kv.SetVector("origin", origin);
				kv.SetVector("angles", angles);
				
				kv.Rewind();
				kv.ExportToFile(file);
				delete kv;
				
				KillLastGnome();
			}
			else if ( StrEqual(item, "menu_action_remove") ) {
				KillLastGnome();
				
				float origin[3], angles[3];
				int length = g_arrayOrigin.Length;
				for ( int i = 0; i < length; ++i ) {
					g_arrayOrigin.GetArray(i, origin);
					g_arrayAngles.GetArray(i, angles);
					
					int entity = SpawnPropPhysicsByOrigin(g_model, origin, angles);
					SetEntityMoveType(entity, MOVETYPE_NONE);
					SDKHook(entity, SDKHook_OnTakeDamage, RemoveOnDamage);
				}
			}
			else if ( StrEqual(item, "menu_action_delete") ) {
				KillLastGnome();
				
				char map_name[64];
				GetCurrentMap(SZF(map_name));
				
				char file[PMP];
				BuildPath(Path_SM, SZF(file), "configs/gnome_hunt/%s.txt", map_name);
				KeyValues kv = new KeyValues("data");
				kv.ExportToFile(file);
				
				g_arrayOrigin.Clear();
				g_arrayAngles.Clear();
			}
		}
		
		case MenuAction_Cancel: {
			KillLastGnome();
		}
	}
	
	return 0;
}

public int Handler_MenuPosition(Menu menu, MenuAction action, int client, int slot)
{
	switch ( action ) {
		case MenuAction_DisplayItem: {
			char text[128], item[32];
			menu.GetItem(slot, SZF(item));
			FormatEx(SZF(text), "%T", item, client);
			return RedrawMenuItem(text);
		}
		
		case MenuAction_Select: {
			int entity = EntRefToEntIndex(g_gnome);
			if ( !IsValidEntity(entity) ) {
				PrintToChat(client, "%T", "menu_gnome_not_found", client);
				return 0;
			}
			
			float origin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
			
			char item[32];
			menu.GetItem(slot, SZF(item));
			static const float dx = 1.0;
			if ( StrEqual(item, "menu_origin_add_x") ) {
				origin[0] += dx;
			}
			else if ( StrEqual(item, "menu_origin_sub_x") ) {
				origin[0] -= dx;
			}
			else if ( StrEqual(item, "menu_origin_add_y") ) {
				origin[1] += dx;
			}
			else if ( StrEqual(item, "menu_origin_sub_y") ) {
				origin[1] -= dx;
			}
			else if ( StrEqual(item, "menu_origin_add_z") ) {
				origin[2] += dx;
			}
			else if ( StrEqual(item, "menu_origin_sub_z") ) {
				origin[2] -= dx;
			}
			
			TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
			g_menuOrigin.SetTitle("%T", "menu_origin_title", client);
			g_menuOrigin.Display(client, MTF);
		}
		
		case MenuAction_Cancel: {
			if ( slot == MenuCancel_ExitBack ) {
				g_menuAction.SetTitle("%T", "menu_action_title", client);
				g_menuAction.Display(client, MTF);
			}
			else {
				KillLastGnome();
			}
		}
	}
	
	return 0;
}

public int Handler_MenuRotation(Menu menu, MenuAction action, int client, int slot)
{
	switch ( action ) {
		case MenuAction_DisplayItem: {
			char text[128], item[32];
			menu.GetItem(slot, SZF(item));
			FormatEx(SZF(text), "%T", item, client);
			return RedrawMenuItem(text);
		}
		
		case MenuAction_Select: {
			int entity = EntRefToEntIndex(g_gnome);
			if ( !IsValidEntity(entity) ) {
				PrintToChat(client, "%T", "menu_gnome_not_found", client);
				return 0;
			}
			
			float angles[3];
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angles);
			
			char item[32];
			menu.GetItem(slot, SZF(item));
			static const float dx = 5.0;
			if ( StrEqual(item, "menu_angles_add_x") ) {
				angles[0] += dx;
			}
			else if ( StrEqual(item, "menu_angles_sub_x") ) {
				angles[0] -= dx;
			}
			else if ( StrEqual(item, "menu_angles_add_y") ) {
				angles[1] += dx;
			}
			else if ( StrEqual(item, "menu_angles_sub_y") ) {
				angles[1] -= dx;
			}
			else if ( StrEqual(item, "menu_angles_add_z") ) {
				angles[2] += dx;
			}
			else if ( StrEqual(item, "menu_angles_sub_z") ) {
				angles[2] -= dx;
			}
			
			TeleportEntity(entity, NULL_VECTOR, angles, NULL_VECTOR);
			g_menuAngles.SetTitle("%T", "menu_angles_title", client);
			g_menuAngles.Display(client, MTF);
		}
		
		case MenuAction_Cancel: {
			if ( slot == MenuCancel_ExitBack ) {
				g_menuAction.SetTitle("%T", "menu_action_title", client);
				g_menuAction.Display(client, MTF);
			}
			else {
				KillLastGnome();
			}
		}
	}
	
	return 0;
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
bool GetClientViewOriginAndAngles(const int client, float origin[3], float angles[3])
{
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	
	TR_TraceRayFilter(origin, angles, MASK_SOLID, RayType_Infinite, TR_DontHitSelf, client);
	if ( TR_DidHit(INVALID_HANDLE) )
	{
		TR_GetEndPosition(origin, INVALID_HANDLE);
		TR_GetPlaneNormal(INVALID_HANDLE, angles);
		GetVectorAngles(angles, angles);
		angles[0] += 90.0;
		return true;
	}
	
	return false;
}

public bool TR_DontHitSelf(int entity, int mask, any data) 
{ 
	return ( entity != data ); 
}

int SpawnPropPhysicsByOrigin(const char[] model, const float origin[3], const float angles[3]={0.0, 0.0, 0.0})
{
	int entity = CreateEntityByName("prop_physics");
	if ( IsValidEdict(entity) ) {
		DispatchKeyValueVector(entity, "origin", origin);
		DispatchKeyValueVector(entity, "angles", angles);
		DispatchKeyValue(entity, "model", model);
		
		if ( DispatchSpawn(entity) ) {
			return entity;
		}
		else {
			LogError("Can't dispatch prop_physics");
		}
	}
	else {
		LogError("Can't create prop_physics");
	}
	
	return -1;
}

void KillLastGnome()
{
	int entity = EntRefToEntIndex(g_gnome);
	if ( IsValidEntity(entity) && entity > MaxClients ) {
		AcceptEntityInput(entity, "Kill");
	}
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public int Ev_RoundStart(Event event, const char[] eventName, bool silent)
{
	if ( g_spawnTimer ) {
		KillTimer(g_spawnTimer);
		g_spawnTimer = INVALID_HANDLE;
	}
	
	int randomValue = GetRandomInt(1, 100);
	if ( randomValue <= g_spawnChance ) {
		float spawnDelay = GetRandomFloat(g_spawnTimeMin, g_spawnTimeMax);
		g_spawnTimer = CreateTimer(spawnDelay, Timer_SpawnGnome, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_SpawnGnome(Handle timer)
{
	int length = g_arrayOrigin.Length;
	if ( length == 0 ) {
		g_spawnTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	
	int gnomeNumber = GetRandomInt(0, length - 1);
	
	float origin[3], angles[3];
	g_arrayOrigin.GetArray(gnomeNumber, origin);
	g_arrayAngles.GetArray(gnomeNumber, angles);
	
	int entity = SpawnPropPhysicsByOrigin(g_model, origin, angles);
	SetEntityMoveType(entity, MOVETYPE_NONE);
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	g_gnome = EntIndexToEntRef(entity);
	
	if ( g_lifetimeMax > 0.0 ) {
		g_spawnTimer = CreateTimer(GetRandomFloat(g_lifetimeMin, g_lifetimeMax), Timer_AnnounceDespawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else {
		g_spawnTimer = INVALID_HANDLE;
	}
	
	if ( g_onSpawnMessage ) {
		PrintToChatAll("%t", "gnome_spawned");
	}
	return Plugin_Handled;
}

public Action Timer_AnnounceDespawn(Handle timer)
{
	int entity = EntRefToEntIndex(g_gnome);
	if ( IsValidEntity(entity) && entity > MaxClients ) {
		AcceptEntityInput(entity, "Kill");
		if ( g_onDespawnMessage ) {
			PrintToChatAll("%t", "gnome_despawned");
		}
	}
	
	g_spawnTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

// ==============================================================================================================================
// >>> 
// ==============================================================================================================================
public Action Command_GnomeHuntMenu(int client, int argc)
{
	float origin[3], angles[3];
	if ( GetClientViewOriginAndAngles(client, origin, angles) ) {
		KillLastGnome();
		
		g_menuAction.SetTitle("%T", "menu_action_title", client);
		g_menuAction.Display(client, MTF);
		
		int entity = SpawnPropPhysicsByOrigin(g_model, origin, angles);
		SetEntityMoveType(entity, MOVETYPE_NONE);
		g_gnome = EntIndexToEntRef(entity);
	}
	
	return Plugin_Handled;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if ( g_blastProtection && (damagetype & DMG_BLAST) ) {
		damage = 0.0;
		return Plugin_Changed;
	}
	
	if ( attacker > 0 && attacker <= MaxClients ) {
		char command[256], buffer[64];
		strcopy(SZF(command), g_rewardCommand);
		
		IntToString(UID(attacker), SZF(buffer));
		ReplaceString(SZF(command), "{uid}", buffer);
		
		IntToString(attacker, SZF(buffer));
		ReplaceString(SZF(command), "{cid}", buffer);
		
		GetClientName(attacker, SZF(buffer));
		ReplaceString(SZF(command), "{name}", buffer);
		
		PrintToServer(command);
		ServerCommand(command);
		AcceptEntityInput(victim, "Kill");
		
		if ( g_onDestoyedMessage ) {
			PrintToChatAll("%t", "gnome_destroyed", attacker);
		}
	}
	else {
		if ( g_onDestoyedByWorldMessage ) {
			PrintToChatAll("%t", "gnome_destroyed_by_world");
		}
	}
	return Plugin_Continue;
}

public Action RemoveOnDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	float gnomeOrigin[3], gnomeAngles[3];
	GetEntPropVector(victim, Prop_Send, "m_vecOrigin", gnomeOrigin);
	GetEntPropVector(victim, Prop_Data, "m_angAbsRotation", gnomeAngles);
	
	float origin[3], angles[3];
	int length = g_arrayOrigin.Length, index = -1;
	for ( int i = 0; i < length; ++i ) {
		g_arrayOrigin.GetArray(i, origin);
		g_arrayAngles.GetArray(i, angles);
		
		if ( gnomeOrigin[0] == origin[0] && gnomeOrigin[1] == origin[1] && gnomeOrigin[2] == origin[2] &&
			gnomeAngles[0] == angles[0] && gnomeAngles[1] == angles[1] && gnomeAngles[2] == angles[2] ) {
			index = i;
			break;
		}
	}
	
	if ( index != -1 ) {
		KeyValues kv = new KeyValues("data");
		
		char map_name[64];
		GetCurrentMap(SZF(map_name));
		
		char file[PMP];
		BuildPath(Path_SM, SZF(file), "configs/gnome_hunt/%s.txt", map_name);
		kv.ImportFromFile(file);
		
		char num[4];
		for ( int i = index; i < length-1; ++i ) {
			IntToString(i, SZF(num));
			kv.JumpToKey(num);
				
			g_arrayOrigin.GetArray(i+1, origin);
			g_arrayAngles.GetArray(i+1, angles);
			
			kv.SetVector("origin", origin);
			kv.SetVector("angles", angles);
			
			kv.GoBack();
		}
		
		IntToString(length-1, SZF(num));
		kv.JumpToKey(num);
		kv.DeleteThis();
		kv.Rewind();
		kv.ExportToFile(file);
		
		delete kv;
		
		g_arrayOrigin.Erase(index);
		g_arrayAngles.Erase(index);
	}
	else {
		PrintToChat(attacker, "%T", "menu_gnome_not_found", attacker);
	}
	
	AcceptEntityInput(victim, "Kill");
	return Plugin_Continue;
}
