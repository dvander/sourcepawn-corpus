// Original fix plugin made by Mr. Zero, just borrowed some basic stuff.
#define PLUGIN_NAME "No Mercy Elevator Fix (Co-op Version)"
#define PLUGIN_AUTHOR "Shadowysn (Co-op method), Mr. Zero (Plugin used as base)"
#define PLUGIN_DESC "Teleports players to a fake elevator clone to prevent the elevator bug and let players jump."
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "http://forums.alliedmods.net/showthread.php?t=143008"
#define PLUGIN_NAME_SHORT "Co-op Elevator Fix"
#define PLUGIN_NAME_TECH "coopelevatorfix"

#define TEAM_SURVIVOR 2
#define TEAM_PASSING 4
#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define NO_MERCY_MAP4 "c8m4_interior"

#define ELEVATOR_FLOOR "elevator"
#define ELEVATOR_FLOOR_CLONE "elevator_clone"
#define ELEVATOR_FLOOR_CLONE_SND "elevator_clone_fakesnd"
#define ELEVATOR_FLOOR_CLONE_LIGHT "elevator_clone_fakelight"
#define ELEVATOR_MODEL "elevator_model"
#define ELEVATOR_BUTTON "elevator_button"
#define ELEVATOR_DOOR "door_elev"
#define ELEVATOR_PANEL "elevator panel"
#define ELEVATOR_PANELSND "elevator_inside_number_sound"
#define ELEVATOR_CLONEGENERIC "elevator_generic_clone"
#define FIXUP_NAME "elevator_fix_checkup"
//#define BLOCKER_NAME "tsu_elevator_nofall_survivor_tabbernaut"
//ent_remove_all elevator_clone;ent_remove_all elevator_model_clone;ent_remove_all door_elev_clone;ent_remove_all "elevator panel_clone";ent_remove_all elevator_generic_clone

#define TELEPORTER_START "plugin_elevator_teleport_start"
#define TELEPORTER_END "plugin_elevator_teleport_end"
#define TELEPORTER_TARG_START "plugin_elevator_teletarget_start"
#define TELEPORTER_TARG_END "plugin_elevator_teletarget_end"
#define TELEPORTER_PASSING_START "plugin_elevator_telepassing_start"
#define TELEPORTER_PASSING_END "plugin_elevator_telepassing_end"

#define FILTER_PASSING "plugin_filter_passing"
#define FILTER_NOPASSING "plugin_filter_nopassing"

#define DECOYS_TARGETNAME "plugin_fake_bots"

#define BEHAVIOUR_CVAR "sb_l4d1_survivor_behaviour"

static float[] elevator_pos = {13432.0, 15245.0, 5542.0};
//static float[] elevator_clone_pos = {13432.0, 15245.0, 6280.0};
static float[] elevator_clone_pos = {-8960.0, -8210.0, -6005.0};
static int elevator_clone = -1;
/*static int elevator_roof = -1;
static int elevator_door1 = -1;
static int elevator_door2 = -1;
static int elevator_buttonpanel = -1;
static int elevator_numberbrush = -1;*/

int decoy_bill = -1;
int decoy_zoey = -1;
int decoy_francis = -1;
int decoy_louis = -1;

static bool hasRoundEnded = false;
static bool isNoMercyMap4 = false;

ConVar ElevFix_SpawnTeam4;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	CreateConVar("l4d2_coopelevatorfix_version", PLUGIN_VERSION, "No Mercy Elevator Fix (Co-op) Version", FCVAR_NONE | FCVAR_NOTIFY);
	
	ElevFix_SpawnTeam4 = CreateConVar("l4d2_coopelevatorfix_team4", "0", "Create 'The Passing' bots to take places in real elevator to attempt to fool Infected players. Cannot adjust for actual survivors, and can bug out.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("round_end", round_end, EventHookMode_PostNoCopy);
	
	RegAdminCmd("sm_tempelev", tempelev_cmd, ADMFLAG_CHEATS, "Temp.");
	RegAdminCmd("sm_tempattach", tempattach_cmd, ADMFLAG_CHEATS, "Temp.");
	
	AutoExecConfig(true, "NoMercyElevatorFix_Coop");
}

public void OnMapStart()
{
	ResetPluginEntities();
	char map[32];
	GetCurrentMap(map, 32);
	isNoMercyMap4 = StrEqual(map, NO_MERCY_MAP4, false);
	if (isNoMercyMap4)
	{
		hasRoundEnded = true;
		ConVar behaviour = FindConVar(BEHAVIOUR_CVAR);
		if (behaviour != null)
		{ SetConVarInt(behaviour, 0); } // This is to prevent the decoy bots from crumpling against the elevator door in their ride
	}
}

Action tempelev_cmd(int client, any args)
{
	CloneElevator();
}

Action tempattach_cmd(int client, any args)
{
	AttachOutputs();
}

void player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (!hasRoundEnded || !isNoMercyMap4) return;
	
	int clientID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(clientID);
	if (!IsValidClient(client)) return;
	int is_Incap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || is_Incap) return;
	
	hasRoundEnded = false;
	
	//DoBlockerFix();
	CloneElevator();
	AttachOutputs();
	if (GetConVarBool(ElevFix_SpawnTeam4))
	{ CreateTimer(2.0, CreateDecoys, -1, TIMER_FLAG_NO_MAPCHANGE); }
}

void round_end(Handle event, const char[] name, bool dontBroadcast)
{
	if (!isNoMercyMap4) return;
	hasRoundEnded = true;
	ResetPluginEntities();
}

void ResetPluginEntities()
{
	elevator_clone = -1;
	/*elevator_roof = -1;
	elevator_door1 = -1;
	elevator_door2 = -1;
	elevator_buttonpanel = -1;
	elevator_numberbrush = -1;*/
	/*if (IsValidClient(decoy_bill) && IsFakeClient(decoy_bill))
	{ AcceptEntityInput(decoy_bill, "Kill"); }
	if (IsValidClient(decoy_zoey) && IsFakeClient(decoy_zoey))
	{ AcceptEntityInput(decoy_zoey, "Kill"); }
	if (IsValidClient(decoy_francis) && IsFakeClient(decoy_francis))
	{ AcceptEntityInput(decoy_francis, "Kill"); }
	if (IsValidClient(decoy_louis) && IsFakeClient(decoy_louis))
	{ AcceptEntityInput(decoy_louis, "Kill"); }*/
	RemoveDecoys();
	decoy_bill = -1;
	decoy_zoey = -1;
	decoy_francis = -1;
	decoy_louis = -1;
}

void RemoveDecoys()
{
	int one_bot = FindEntityByTargetname(-1, DECOYS_TARGETNAME);
	if (IsValidEntity(one_bot))
	{
		char temp_str[128];
		Format(temp_str, sizeof(temp_str), "OnUser4 %s:Kill::0.0:1", DECOYS_TARGETNAME);
		SetVariantString(temp_str);
		AcceptEntityInput(one_bot, "AddOutput");
		AcceptEntityInput(one_bot, "FireUser4");
	}
}

Action CreateDecoys(Handle timer)
{
	if (!IsValidEntity(elevator_clone)) return;
	
	RemoveDecoys();
	AvoidCharacter(true);
	SpawnPassingSurvivor(4);
	SpawnPassingSurvivor(5);
	SpawnPassingSurvivor(6);
	SpawnPassingSurvivor(7);
	AvoidCharacter(false);
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (!IsFakeClient(client) || !IsPassingSurvivor(client)) continue;
		char name_str[128];
		GetEntPropString(client, Prop_Data, "m_iName", name_str, sizeof(name_str));
		if (name_str[0]) continue;
		
		TeleportEntity(client, elevator_clone_pos, NULL_VECTOR, NULL_VECTOR);
		
		int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (character == 4)
		{ decoy_bill = client; }
		else if (character == 5)
		{ decoy_zoey = client; }
		else if (character == 6)
		{ decoy_francis = client; }
		else if (character == 7)
		{ decoy_louis = client; }
	}
	DispatchKeyValue(decoy_bill, "targetname", DECOYS_TARGETNAME);
	DispatchKeyValue(decoy_zoey, "targetname", DECOYS_TARGETNAME);
	DispatchKeyValue(decoy_francis, "targetname", DECOYS_TARGETNAME);
	DispatchKeyValue(decoy_louis, "targetname", DECOYS_TARGETNAME);
	SetVariantInt(0);
	AcceptEntityInput(decoy_bill, "SetGlowEnabled");
	SetVariantInt(0);
	AcceptEntityInput(decoy_zoey, "SetGlowEnabled");
	SetVariantInt(0);
	AcceptEntityInput(decoy_francis, "SetGlowEnabled");
	SetVariantInt(0);
	AcceptEntityInput(decoy_louis, "SetGlowEnabled");
	
	SetEntProp(decoy_bill, Prop_Send, "m_survivorCharacter", 8);
	SetEntProp(decoy_zoey, Prop_Send, "m_survivorCharacter", 8);
	SetEntProp(decoy_francis, Prop_Send, "m_survivorCharacter", 8);
	SetEntProp(decoy_louis, Prop_Send, "m_survivorCharacter", 8);
}
void SpawnPassingSurvivor(int character)
{
	int spawn = CreateEntityByName("info_l4d1_survivor_spawn");
	if (!IsValidEntity(spawn))
	{ return; }
	TeleportEntity(spawn, elevator_clone_pos, NULL_VECTOR, NULL_VECTOR);
	
	char temp_str[8];
	IntToString(character, temp_str, sizeof(temp_str));
	DispatchKeyValue(spawn, "character", temp_str);
	
	DispatchSpawn(spawn);
	ActivateEntity(spawn);
	AcceptEntityInput(spawn, "SpawnSurvivor");
	AcceptEntityInput(spawn, "Kill");
}

// Credits to Silvers for the original function in his holdout plugin. https://forums.alliedmods.net/showthread.php?t=188966
g_iAvoidChar[MAXPLAYERS+1] = {-1,...};
void AvoidCharacter(bool avoid)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsValidClient(i) && IsSurvivor(i) )
		{
			if( avoid )
			{
				// Save character type
				g_iAvoidChar[i] = GetEntProp(i, Prop_Send, "m_survivorCharacter");
				SetEntProp(i, Prop_Send, "m_survivorCharacter", 8);
			} else {
				// Restore player type
				if( g_iAvoidChar[i] != -1 )
				{
					SetEntProp(i, Prop_Send, "m_survivorCharacter", g_iAvoidChar[i]);
					g_iAvoidChar[i] = -1;
				}
			}
		}
	}

	if( !avoid )
	{
		for( int i = 1; i <= MAXPLAYERS; i++ )
			g_iAvoidChar[i] = -1;
	}
}

void AttachOutputs()
{
	/*int elevator_orig = FindEntityByTargetname(-1, ELEVATOR_FLOOR);
	if (IsValidEntity(elevator_orig))
	{ HookSingleEntityOutput(elevator_orig, "OnReachedTop", Output_OnReachedTop, true); }
	int elevator_button = FindEntityByTargetname(-1, ELEVATOR_BUTTON);
	if (IsValidEntity(elevator_button))
	{ HookSingleEntityOutput(elevator_button, "OnPressed", Output_OnPressed, true); }*/
	
	char temp_str[128];
	int elevator_button = FindEntityByTargetname(-1, ELEVATOR_BUTTON);
	if (IsValidEntity(elevator_button))
	{
		Format(temp_str, sizeof(temp_str), "OnPressed %s:TurnOn::2.50:1", ELEVATOR_FLOOR_CLONE_LIGHT);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		
		Format(temp_str, sizeof(temp_str), "OnPressed %s:Enable::2.50:1", TELEPORTER_START);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnPressed %s:Disable::2.51:1", TELEPORTER_START);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnPressed %s:Enable::2.50:1", TELEPORTER_PASSING_END);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnPressed %s:Disable::2.51:1", TELEPORTER_PASSING_END);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnPressed %s:SetGlowEnabled:1:2.50:1", DECOYS_TARGETNAME);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnPressed %s:PlaySound::3.0:1", ELEVATOR_FLOOR_CLONE_SND);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_button, "AddOutput");
		HookSingleEntityOutput(elevator_button, "OnPressed", Output_OnPressed, true);
	}
	
	int elevator_orig = FindEntityByTargetname(-1, ELEVATOR_FLOOR);
	if (IsValidEntity(elevator_orig))
	{
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:Enable::0.0:1", TELEPORTER_END);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:Disable::0.01:1", TELEPORTER_END);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:Kill::0.0:1", DECOYS_TARGETNAME);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
		
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:TurnOff::1.0:1", ELEVATOR_FLOOR_CLONE_LIGHT);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
		
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:Enable::0.0:1", TELEPORTER_PASSING_START);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
		Format(temp_str, sizeof(temp_str), "OnReachedTop %s:Disable::0.01:1", TELEPORTER_PASSING_START);
		SetVariantString(temp_str);
		AcceptEntityInput(elevator_orig, "AddOutput");
	}
}

/*void Output_OnReachedTop(const char[] output, int caller, int activator, float delay)
{
	PrintToChatAll("yey");
}*/

void Output_OnPressed(const char[] output, int caller, int activator, float delay)
{
	//PrintToChatAll("pressed");
	CreateTimer(2.0, Pressed_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Pressed_Timer(Handle timer)
{
	//PrintToChatAll("pressedtimer");
	int bill = -1;
	int zoey = -1;
	int louis = -1;
	int francis = -1;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client)) continue;
		if (!IsSurvivor(client)) continue;
		int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (character == 0 || character == 4)
		{ bill = client; }
		else if (character == 1 || character == 5)
		{ zoey = client; }
		else if (character == 2 || character == 7)
		{ louis = client; }
		else if (character == 3 || character == 6)
		{ francis = client; }
	}
	SetStatsOfDecoy(decoy_bill, bill);
	SetStatsOfDecoy(decoy_zoey, zoey);
	SetStatsOfDecoy(decoy_louis, louis);
	SetStatsOfDecoy(decoy_francis, francis);
}
void SetStatsOfDecoy(int decoy, int real)
{
	if (IsValidClient(decoy) && IsFakeClient(decoy))
	{
		if (!IsPlayerAlive(real))
		{ AcceptEntityInput(decoy, "Kill"); }
		else
		{
			SetEntityHealth(decoy, GetClientHealth(real));
			SetEntPropFloat(decoy, Prop_Send, "m_healthBuffer", GetEntPropFloat(real, Prop_Send, "m_healthBuffer"));
			SetEntProp(decoy, Prop_Send, "m_currentReviveCount", GetEntProp(real, Prop_Send, "m_currentReviveCount"));
			SetEntProp(decoy, Prop_Send, "m_bIsOnThirdStrike", GetEntProp(real, Prop_Send, "m_bIsOnThirdStrike"));
			SetEntProp(decoy, Prop_Send, "m_isIncapacitated", GetEntProp(real, Prop_Send, "m_isIncapacitated"));
		}
	}
}

/*int GetTeleporter(bool isEntrance = true)
{
	if (isEntrance)
	{
		return FindEntityByTargetname(TELEPORTER_START);
	}
	else
	{
		return FindEntityByTargetname(TELEPORTER_END);
	}
	return -1;
}*/

int CreateTeleporter(bool isEntrance = true, bool isPassing = false)
{
	int trigger_orig = FindEntityByHammerID(-1, 1199298);
	if (!IsValidEntity(trigger_orig))
	{ return -1; }
	int trigger = CreateEntityByName("trigger_teleport");
	if (!IsValidEntity(trigger))
	{ return -1; }
	
	char model_str[128];
	GetEntPropString(trigger_orig, Prop_Data, "m_ModelName", model_str, sizeof(model_str));
	SetEntityModel(trigger, model_str);
	
	float dif_pos[3];
	if (isEntrance)
	{
		dif_pos[0]=elevator_pos[0];dif_pos[1]=elevator_pos[1]+25.0;dif_pos[2]=elevator_pos[2]+60.0;
		if (isPassing)
		{
			DispatchKeyValue(trigger, "targetname", TELEPORTER_PASSING_START);
			DispatchKeyValue(trigger, "landmark", TELEPORTER_PASSING_START);
		}
		else
		{
			DispatchKeyValue(trigger, "targetname", TELEPORTER_START);
			DispatchKeyValue(trigger, "landmark", TELEPORTER_START);
		}
		DispatchKeyValue(trigger, "targetname", TELEPORTER_START);
		DispatchKeyValue(trigger, "landmark", TELEPORTER_START);
		DispatchKeyValue(trigger, "target", TELEPORTER_TARG_END);
		DispatchKeyValue(trigger, "parentname", ELEVATOR_FLOOR);
	}
	else
	{
		dif_pos[0]=elevator_clone_pos[0];dif_pos[1]=elevator_clone_pos[1]+25.0;dif_pos[2]=elevator_clone_pos[2]+60.0;
		if (isPassing)
		{
			DispatchKeyValue(trigger, "targetname", TELEPORTER_PASSING_END);
			DispatchKeyValue(trigger, "landmark", "!activator");
			DispatchKeyValue(trigger, "target", ELEVATOR_FLOOR);
		}
		else
		{
			DispatchKeyValue(trigger, "targetname", TELEPORTER_END);
			DispatchKeyValue(trigger, "landmark", TELEPORTER_END);
			DispatchKeyValue(trigger, "target", TELEPORTER_TARG_START);
		}
	}
	if (isPassing)
	{ DispatchKeyValue(trigger, "filtername", FILTER_PASSING); }
	else
	{ DispatchKeyValue(trigger, "filtername", FILTER_NOPASSING); }
	TeleportEntity(trigger, dif_pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(trigger, "spawnflags", "3");
	
	DispatchSpawn(trigger);
	ActivateEntity(trigger);
	
	if (isEntrance)
	{
		SetVariantString(ELEVATOR_FLOOR);
		AcceptEntityInput(trigger, "SetParent");
	}
	
	//SetVariantString("OnStartTouch !self:Disable::0.01:0");
	//AcceptEntityInput(trigger, "AddOutput");
	
	AcceptEntityInput(trigger, "Disable");
	
	if (!isPassing)
	{
		int target = CreateEntityByName("info_teleport_destination");
		TeleportEntity(target, dif_pos, NULL_VECTOR, NULL_VECTOR);
		if (isEntrance)
		{
			DispatchKeyValue(target, "targetname", TELEPORTER_TARG_START);
		}
		else
		{
			DispatchKeyValue(target, "targetname", TELEPORTER_TARG_END);
		}
		DispatchSpawn(target);
		ActivateEntity(target);
		if (isEntrance)
		{ SetVariantString(ELEVATOR_FLOOR); }
		AcceptEntityInput(trigger, "SetParent");
	}
	
	return trigger;
}

void CloneElevator()
{
	//int check_IfFix = FindEntityByClassname(-1, "info_target");
	bool has_FoundFix = false;
	
	/*for (int i = 1; i <= 12; i++) {
		if (IsValidEntity(check_IfFix))
		{
			char name[128];
			GetEntPropString(check_IfFix, Prop_Data, "m_iName", name, sizeof(name));
			if (StrEqual(name, FIXUP_NAME, false))
			{ has_FoundFix = true; break; }
			else
			{
				int temp = FindEntityByClassname(check_IfFix, "info_target");
				if (!IsValidEntity(temp)) break;
				check_IfFix = temp;
			}
		}
		else
		{ break; }
	}*/
	
	if (!has_FoundFix)
	{
		int filter = CreateEntityByName("filter_activator_team");
		DispatchKeyValue(filter, "targetname", FILTER_PASSING);
		DispatchKeyValue(filter, "filterteam", "4");
		DispatchSpawn(filter);
		filter = CreateEntityByName("filter_activator_team");
		DispatchKeyValue(filter, "targetname", FILTER_NOPASSING);
		DispatchKeyValue(filter, "filterteam", "4");
		DispatchKeyValue(filter, "Negated", "1");
		DispatchSpawn(filter);
		
		CreateTeleporter(true);
		CreateTeleporter(false);
		CreateTeleporter(true, true);
		CreateTeleporter(false, true);
		
		char clone_str[128];
		float dif_pos[3];
		
		if (!IsValidEntity(elevator_clone))
		{
			int elevator_orig = FindEntityByTargetname(-1, ELEVATOR_FLOOR);
			elevator_clone = CreateEntityByName("func_elevator");
			
			char model_str[128];
			GetEntPropString(elevator_orig, Prop_Data, "m_ModelName", model_str, sizeof(model_str));
			SetEntityModel(elevator_clone, model_str);
			
			TeleportEntity(elevator_clone, elevator_clone_pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(elevator_clone, "targetname", ELEVATOR_FLOOR_CLONE);
			DispatchSpawn(elevator_clone);
			ActivateEntity(elevator_clone);
			SetVariantString("OnUser1 trigger_nojump:Kill::0.0:1");
			AcceptEntityInput(elevator_clone, "AddOutput");
			AcceptEntityInput(elevator_clone, "FireUser1");
			
			int elevator_clone_light = CreateEntityByName("light_dynamic");
			DispatchKeyValue(elevator_clone_light, "targetname", ELEVATOR_FLOOR_CLONE_LIGHT);
			DispatchKeyValue(elevator_clone_light, "_light", "224 211 160 250");
			DispatchKeyValue(elevator_clone_light, "_inner_cone", "5");
			DispatchKeyValue(elevator_clone_light, "_cone", "60");
			DispatchKeyValue(elevator_clone_light, "brightness", "10");
			DispatchKeyValue(elevator_clone_light, "spawnflags", "1");
			DispatchSpawn(elevator_clone_light);
			ActivateEntity(elevator_clone_light);
			AcceptEntityInput(elevator_clone_light, "TurnOff");
			
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number00_left"), false, false);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number01_left"), false, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number02_left"), false, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number03_left"), false, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number00_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number01_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number02_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number03_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number04_right"), true, false);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number05_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number06_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number07_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number08_right"), true, true);
			CreateBrushNumber(FindEntityByTargetname(-1, "elevator_inside_number09_right"), true, true);
			
			//int elevator_roof_orig = FindEntityByTargetname(-1, ELEVATOR_MODEL);
			int elevator_roof = CreateEntityByName("prop_dynamic");
			SetEntityModel(elevator_roof, "models/props_interiors/elevator_interior.mdl");
			//SetEntPropEnt(elevator_roof, Prop_Send, "moveparent", elevator_clone);
			
			dif_pos[0]=elevator_clone_pos[0];dif_pos[1]=elevator_clone_pos[1]-25.0;dif_pos[2]=elevator_clone_pos[2];
			TeleportEntity(elevator_roof, dif_pos, view_as<float>({0.0, 270.0, 0.0}), NULL_VECTOR);
			Format(clone_str, sizeof(clone_str), "%s_clone", ELEVATOR_MODEL);
			DispatchKeyValue(elevator_roof, "targetname", clone_str);
			DispatchKeyValue(elevator_roof, "lightingorigin", "elevator_lighting");
			DispatchKeyValue(elevator_roof, "disableshadows", "1");
			DispatchSpawn(elevator_roof);
			ActivateEntity(elevator_roof);
			SetVariantString(ELEVATOR_FLOOR_CLONE);
			AcceptEntityInput(elevator_roof, "SetParent");
			
			CreateDoor(FindEntityByHammerID(-1, 4999347), false);
			
			CreateDoor(FindEntityByHammerID(-1, 4999344), true);
			
			//int elevator_buttonpanel_orig = FindEntityByTargetname(-1, ELEVATOR_PANEL);
			int elevator_buttonpanel = CreateEntityByName("prop_dynamic");
			SetEntityModel(elevator_buttonpanel, "models/props_interiors/elevator_panel.mdl");
			//SetEntPropEnt(elevator_buttonpanel, Prop_Send, "moveparent", elevator_clone);
			
			dif_pos[0]=elevator_clone_pos[0]+69.0;dif_pos[1]=elevator_clone_pos[1]-108.0;dif_pos[2]=elevator_clone_pos[2]+60.5;
			TeleportEntity(elevator_buttonpanel, dif_pos, view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
			Format(clone_str, sizeof(clone_str), "%s_clone", ELEVATOR_PANEL);
			DispatchKeyValue(elevator_buttonpanel, "targetname", clone_str);
			DispatchKeyValue(elevator_buttonpanel, "lightingorigin", "elevator_lighting");
			DispatchKeyValue(elevator_buttonpanel, "solid", "0");
			DispatchKeyValue(elevator_buttonpanel, "skin", "1");
			DispatchKeyValue(elevator_buttonpanel, "disableshadows", "1");
			DispatchSpawn(elevator_buttonpanel);
			ActivateEntity(elevator_buttonpanel);
			SetVariantString(ELEVATOR_FLOOR_CLONE);
			AcceptEntityInput(elevator_buttonpanel, "SetParent");
			
			int panel_snd = CreateEntityByName("ambient_generic");
			
			TeleportEntity(panel_snd, dif_pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(panel_snd, "targetname", ELEVATOR_PANELSND);
			DispatchKeyValue(panel_snd, "message", "Respawn.CountdownBeep");
			DispatchKeyValue(panel_snd, "SourceEntityName", clone_str);
			DispatchKeyValue(panel_snd, "health", "10");
			DispatchKeyValue(panel_snd, "spawnflags", "48");
			DispatchSpawn(panel_snd);
			ActivateEntity(panel_snd);
			
			SetVariantString(clone_str);
			AcceptEntityInput(panel_snd, "SetParent");
			
			// Elevator clone's fake sound (actually the elev doors) start
			int fakesnd = CreateEntityByName("ambient_generic");
			TeleportEntity(fakesnd, elevator_clone_pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(fakesnd, "targetname", ELEVATOR_FLOOR_CLONE_SND);
			DispatchKeyValue(fakesnd, "message", "Doors.Elevator.Open");
			//DispatchKeyValue(fakesnd, "SourceEntityName", ELEVATOR_FLOOR_CLONE);
			DispatchKeyValue(fakesnd, "health", "7");
			DispatchKeyValue(fakesnd, "spawnflags", "48");
			// Elevator clone's fake sound (actually the elev doors) end
			
			// Elevator clone's looping sound start
			fakesnd = CreateEntityByName("ambient_generic");
			TeleportEntity(fakesnd, elevator_clone_pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(fakesnd, "message", "plats/elevator_move_loop1.wav");
			DispatchKeyValue(fakesnd, "SourceEntityName", ELEVATOR_FLOOR_CLONE);
			DispatchKeyValue(fakesnd, "health", "5");
			// Elevator clone's looping sound end
			
			int elevator_numberbrush_orig = FindEntityByHammerID(-1, 5626349);
			int elevator_numberbrush = CreateEntityByName("func_brush");
			
			GetEntPropString(elevator_numberbrush_orig, Prop_Data, "m_ModelName", model_str, sizeof(model_str));
			SetEntityModel(elevator_numberbrush, model_str);
			//SetEntPropEnt(elevator_numberbrush, Prop_Send, "moveparent", elevator_clone);
			
			dif_pos[0]=elevator_clone_pos[0]+69.5;dif_pos[1]=elevator_clone_pos[1]-106.5;dif_pos[2]=elevator_clone_pos[2]+87.0;
			TeleportEntity(elevator_numberbrush, dif_pos, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(elevator_numberbrush, "targetname", ELEVATOR_CLONEGENERIC);
			DispatchKeyValue(elevator_numberbrush, "Solidity", "0");
			DispatchSpawn(elevator_numberbrush);
			ActivateEntity(elevator_numberbrush);
			SetVariantString(ELEVATOR_FLOOR_CLONE);
			AcceptEntityInput(elevator_numberbrush, "SetParent");
		}
	}
}

int CreateDoor(int door, bool isSecond = false)
{
	if (!IsValidEntity(door)) return -1;
	//if (IsValidEntity(elevator_door1) && IsValidEntity(elevator_door2)) return -1;
	
	int temp = CreateEntityByName("func_elevator");
	
	char model_str[128];
	GetEntPropString(door, Prop_Data, "m_ModelName", model_str, sizeof(model_str));
	SetEntityModel(temp, model_str);
	
	float dif_pos[3]; dif_pos[1] = elevator_clone_pos[1]-117.0; dif_pos[2] = elevator_clone_pos[2]+56.0;
	if (isSecond)
	{
		dif_pos[0] = elevator_clone_pos[0]-28.0;
		TeleportEntity(temp, dif_pos, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	}
	else
	{
		dif_pos[0] = elevator_clone_pos[0]+28.0;
		TeleportEntity(temp, dif_pos, view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	}
	char clone_str[128];
	Format(clone_str, sizeof(clone_str), "%s_clone", ELEVATOR_DOOR);
	DispatchKeyValue(temp, "targetname", clone_str);
	DispatchKeyValue(temp, "disableshadows", "1");
	DispatchSpawn(temp);
	ActivateEntity(temp);
	
	SetVariantString(ELEVATOR_FLOOR_CLONE);
	AcceptEntityInput(temp, "SetParent");
	
	/*if (isSecond)
	{ elevator_door2 = temp; }
	else
	{ elevator_door1 = temp; }*/
	return temp;
}

int CreateBrushNumber(int entity, bool useRight = false, bool startDisabled = true)
{
	if (!IsValidEntity(entity)) return -1;
	int temp = CreateEntityByName("func_brush");
	
	char model_str[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", model_str, sizeof(model_str));
	SetEntityModel(temp, model_str);
	
	float dif_pos[3]; dif_pos[1] = elevator_clone_pos[1]-106.5; dif_pos[2] = elevator_clone_pos[2]+87.0;
	if (useRight)
	{
		dif_pos[0] = elevator_clone_pos[0]+67.2;
	}
	else
	{
		dif_pos[0] = elevator_clone_pos[0]+71.7;
	}
	TeleportEntity(temp, dif_pos, NULL_VECTOR, NULL_VECTOR);
	
	char temp_str[128];
	GetEntPropString(entity, Prop_Data, "m_iName", temp_str, sizeof(temp_str));
	DispatchKeyValue(temp, "targetname", temp_str);
	if (startDisabled)
	{ DispatchKeyValue(temp, "StartDisabled", "1"); }
	//DispatchKeyValue(temp, "disableshadows", "0");
	//DispatchKeyValue(temp, "disablereceiveshadows", "0");
	
	TeleportEntity(temp, dif_pos, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(temp);
	ActivateEntity(temp);
	
	SetVariantString(ELEVATOR_FLOOR_CLONE);
	AcceptEntityInput(temp, "SetParent");
	
	return temp;
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!IsValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}

int FindEntityByHammerID(int index, int id)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!IsValidEntity(i)) continue;
		int hammerid = GetEntProp(i, Prop_Data, "m_iHammerID");
		if (hammerid != id) continue;
		return i;
	}
	return -1;
}

/*void DoBlockerFix()
{
	//CreateTimer(2.0, ElevatorFix, -1, TIMER_FLAG_NO_MAPCHANGE);
	int check_IfFix = FindEntityByClassname(-1, "env_physics_blocker");
	bool has_FoundFix = false;
	
	for (int i = 1; i <= 12; i++) {
		if (IsValidEntity(check_IfFix))
		{
			char name[128];
			GetEntPropString(check_IfFix, Prop_Data, "m_iName", name, sizeof(name));
			if (StrEqual(name, BLOCKER_NAME, false))
			{ has_FoundFix = true; break; }
			else
			{
				int temp = FindEntityByClassname(check_IfFix, "env_physics_blocker");
				if (!IsValidEntity(temp)) break;
				check_IfFix = temp;
			}
		}
		else
		{ break; }
	}
	
	if (!has_FoundFix)
	{
		int fixBlocker = CreateEntityByName("env_physics_blocker");
		DispatchKeyValue(fixBlocker, "targetname", BLOCKER_NAME);
		DispatchKeyValue(fixBlocker, "BlockType", "1");
		DispatchKeyValue(fixBlocker, "initialstate", "1");
		DispatchKeyValue(fixBlocker, "origin", "13541 15357 5543");
		TeleportEntity(fixBlocker, view_as<float>({13541.0, 15357.0, 5543.0}), NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(fixBlocker, "maxs", "0 0 0");
		DispatchKeyValue(fixBlocker, "maxs", "-222 -222 -222");
		//DispatchKeyValue(fixBlocker, "mapupdate", "1");
		DispatchSpawn(fixBlocker);
		//ActivateEntity(fixBlocker);
		SetVariantString(ELEVATOR_FLOOR);
		AcceptEntityInput(fixBlocker, "SetParent");
		//AcceptEntityInput(fixBlocker, "Enable");
		SetVariantString("OnUser1 trigger_nojump:Kill::0.0:1");
		AcceptEntityInput(fixBlocker, "AddOutput");
		AcceptEntityInput(fixBlocker, "FireUser1");
	}
}*/

/*Action ElevatorFix(Handle timer)
{
	
}*/

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == TEAM_SURVIVOR) return true;
	return false;
}

bool IsPassingSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == TEAM_PASSING) return true;
	return false;
}