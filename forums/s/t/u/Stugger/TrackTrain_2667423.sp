/*LAST UPDATE: October 9th, 2019 5:30 PM - animation while train running*/

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Stugger"
#define PLUGIN_VERSION "2.5"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "TrackTrain",
	author = PLUGIN_AUTHOR,
	description = "Create, edit, save and load custom func_tracktrain systems in-game",
	version = PLUGIN_VERSION,
	url = ""
};

#define sUsage "\x05Usage\x01"
#define sError "\x06Error\x01"
#define sTag "\x06[TRAIN]\x01"

#define MAX_PLAYER_TRAINS 5 
#define MAX_PATH_TRACKS 15
#define MAX_BUTTONS 2

#define MAX_SPEED 2000
#define MAX_HEIGHT 1000

#define DEFAULT_SPEED "80"

#define TOTAL_SETTINGS 7 // Increase if more settings added

char MAGIC_BRUSH_MODEL[PLATFORM_MAX_PATH];
char TRACK_MODEL[PLATFORM_MAX_PATH];
char BUTTON_MODEL[PLATFORM_MAX_PATH];

int g_pPathEnts[MAXPLAYERS + 1][MAX_PLAYER_TRAINS][MAX_PATH_TRACKS];
int g_pPathPropEnts[MAXPLAYERS + 1][MAX_PLAYER_TRAINS][MAX_PATH_TRACKS];
int g_pTrainButtons[MAXPLAYERS + 1][MAX_PLAYER_TRAINS][MAX_BUTTONS];

bool g_pDisplayDeleteMsg[MAXPLAYERS + 1] = {true, ...};

int g_pCurrentTrain[MAXPLAYERS + 1] = {0, ...};
int g_pTrainEnts[MAXPLAYERS + 1][MAX_PLAYER_TRAINS];
bool g_pActiveTrains[MAXPLAYERS + 1][MAX_PLAYER_TRAINS];

char g_tSettings[MAXPLAYERS + 1][MAX_PLAYER_TRAINS][TOTAL_SETTINGS][128];
char g_pTrainModel[MAXPLAYERS + 1][128]; //setting 0
char g_pTrainSound[MAXPLAYERS + 1][128]; //setting 1
char g_pTrainAnim[MAXPLAYERS + 1][128]; //setting 2
char g_pTrainSpeed[MAXPLAYERS + 1][128]; //setting 3
char g_pTrainHeight[MAXPLAYERS + 1][128]; //setting 4
char g_pTrainOrient[MAXPLAYERS + 1][128]; //setting 5
//setting 6 is the rotation offset of the train prop (if client rotates it)

public void OnPluginStart()
{	
	char GameFolder[32];
	GetGameFolderName(GameFolder, sizeof(GameFolder));
	
	// 	CSGO
	if(StrContains(GameFolder, "csgo", false) != -1) {
		MAGIC_BRUSH_MODEL = "models/props/cs_office/vending_machine.mdl";
		TRACK_MODEL = "models/props/cs_office/trash_can_p8.mdl";
		BUTTON_MODEL = "models/props/cs_office/fire_extinguisher.mdl"; // no idea of any model names in csgo
	} 
	// L4D / L4D2
	else if(StrContains(GameFolder, "left4dead", false) != -1) {
		MAGIC_BRUSH_MODEL = "models/props_office/vending_machine01.mdl";
		TRACK_MODEL = "models/props_junk/garbage_sodacan01a.mdl";
		BUTTON_MODEL = "models/props_mill/freightelevatorbutton02.mdl";
	}
	// HL2DM / CS:S
	else { 
		MAGIC_BRUSH_MODEL = "models/props_interiors/vendingmachinesoda01a.mdl";
		TRACK_MODEL = "models/props_junk/popcan01a.mdl";
		BUTTON_MODEL = "models/props_combine/combinebutton.mdl";
	}
	
	RegAdminCmd("sm_train_track", Cmd_SpawnTrack, 0,   "Spawn a path_track prop");
	RegAdminCmd("sm_train_button", Cmd_SpawnButton, 0, "Spawn a button to toggle the train");
	
	RegAdminCmd("sm_train_model", Cmd_SetModel, 0,  "<modelpath>|raypoint - Set the model of the train");
	RegAdminCmd("sm_train_sound", Cmd_SetSound, 0,  "<soundpath> - Set the sound the train will emit (0/off/none for no sound which is default)");
	RegAdminCmd("sm_train_animation", Cmd_SetAnimation, 0,  "<animation>|<train#> <animation> - Set the animation of the train (0/off/none for no animation which is default)");
	RegAdminCmd("sm_train_speed", Cmd_SetSpeed, 0,  "<0-2000> - Set the speed at which the train travels");
	RegAdminCmd("sm_train_height", Cmd_SetHeight, 0, "<-1000 to 1000> - Set the height that the train will ride above/below the tracks");
	RegAdminCmd("sm_train_orientation", Cmd_SetOrient, 0, "<0-3> - Set the turn type of the train (0 is fixed for doors/elevators)");
	
	RegAdminCmd("sm_train_start", Cmd_StartTrain, 0,  "Execute the current train");
	RegAdminCmd("sm_train_edit", Cmd_EditTrain, 0, "<train#>|raypoint - Edit the specified (1-MAX) trains tracks/buttons/settings");
	RegAdminCmd("sm_train_delete", Cmd_KillTrain, 0,  "<train#>|raypoint - Delete the specified (1-MAX) train");
	
	RegAdminCmd("sm_train_save", Cmd_SaveTrain, 0, "<train#> <alias> - Save the specified active train under an alias to be loaded later (2 arguments)");
	RegAdminCmd("sm_train_load", Cmd_LoadTrain, 0, "<alias> - Load a train from a save alias");
	RegAdminCmd("sm_train_saves", Cmd_PrintSaves, 0, "Print the aliases of any saves you have on the current map");
}

public void OnMapStart()
{
	PrecacheModel(MAGIC_BRUSH_MODEL, true);
	PrecacheModel(TRACK_MODEL, true);
	PrecacheModel(BUTTON_MODEL, true);
	
	for(int i = 0; i < MAXPLAYERS; i++) {
		g_pCurrentTrain[i] = 0;
		g_pTrainModel[i] = NULL_STRING;
		g_pTrainSound[i] = "none";
		g_pTrainAnim[i] = "idle";
		g_pTrainSpeed[i] = DEFAULT_SPEED;
		g_pTrainHeight[i] = "0";
		g_pTrainOrient[i] = "0";
		for(int j = 0; j < MAX_PLAYER_TRAINS; j++) {
			g_pActiveTrains[i][j] = false;
			g_pTrainEnts[i][j] = -1;
			for(int k = 0; k < MAX_PATH_TRACKS; k++) {
				g_pPathEnts[i][j][k] = -1;
				g_pPathPropEnts[i][j][k] = -1;
				if(k < MAX_BUTTONS) 
					g_pTrainButtons[i][j][k] = -1;
				if(k < TOTAL_SETTINGS)
					g_tSettings[i][j][k] = NULL_STRING;
			}
		}
	}
}

//================================================================================
//																				//
//				***		PATH AND BUTTON SPAWN COMMANDS		***					//
//																				//
//================================================================================
//============================================================================
//							SPAWN PATH PROPS COMMAND						//
//============================================================================
public Action Cmd_SpawnTrack(client, args) 
{
	int currentTrain = GetCurrentTrain(client);
	
	if(currentTrain == MAX_PLAYER_TRAINS) {
		PrintToChat(client, "%s %s: You've reached the [\x05%d\x01/\x05%d\x01] Train limit! Delete a train to start a new one", sTag, sError, MAX_PLAYER_TRAINS, MAX_PLAYER_TRAINS);
		return Plugin_Handled;
	}
	if(GetPathTrackCount(client, currentTrain) == MAX_PATH_TRACKS) {
		PrintToChat(client, "%s %s: You've reached the [\x05%d\x01/\x05%d\x01] Track limit for this path!", sTag, sError, MAX_PATH_TRACKS, MAX_PATH_TRACKS);
		return Plugin_Handled;
	}
	
	int pathProp;
	char pathPropName[64], cAuth[128];
	
	// Name, Create and Store the Path Prop
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
	for(int i = 0; i < MAX_PATH_TRACKS; i++) {
		if(g_pPathPropEnts[client][currentTrain][i] <= 0 || !IsValidEntity(g_pPathPropEnts[client][currentTrain][i])) {
			// Name Path Prop
			Format(pathPropName, sizeof(pathPropName), "%s_%d_pathprop%d", cAuth, g_pCurrentTrain[client], i);
			
			// Create and Store the Path Prop
			pathProp = CreateTrackProp(pathPropName);
			g_pPathPropEnts[client][currentTrain][i] = pathProp;
			
			PrintToChat(client, "%s Placed Track [\x04%d\x01/\x05%d\x01] for Train [\x04%d\x01]", sTag, i+1, MAX_PATH_TRACKS, currentTrain+1);
			break;
		}
	}	
	
	// Teleport the Path Prop
	float rayPos[3], clientPos[3], clientEyePos[3], clientAngle[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientEyePosition(client, clientEyePos);
	GetClientEyeAngles(client, clientAngle);

	TR_TraceRayFilter(clientEyePos, clientAngle, MASK_SOLID, RayType_Infinite, TraceRayFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE)) {
		TR_GetEndPosition(rayPos);
	}
	
	TeleportEntity(pathProp, rayPos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

//============================================================================
//							SPAWN BUTTON COMMAND							//
//============================================================================
public Action Cmd_SpawnButton(client, args) 
{
	int currentTrain = GetCurrentTrain(client);
	
	if(currentTrain == MAX_PLAYER_TRAINS) {
		PrintToChat(client, "%s %s: You've reached the [\x05%d\x01/\x05%d\x01] Train limit! Delete a train to start a new one", sTag, sError, MAX_PLAYER_TRAINS, MAX_PLAYER_TRAINS);
		return Plugin_Handled;
	}
	
	int buttonCount = GetTrainButtonCount(client, currentTrain);
		
	if(buttonCount == MAX_BUTTONS) {
		PrintToChat(client, "%s %s: You've reached the [\x05%d\x01/\x05%d\x01] Button limit for Train [\x04%d\x01]!", sTag, sError, buttonCount, MAX_BUTTONS, currentTrain+1);
		return Plugin_Handled;
	}
	
	int buttonProp;
	char buttonName[64], cAuth[128];

	// Name, Create and Store the Button
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
	for (int i = 0; i < MAX_BUTTONS; i++) {
		if(g_pTrainButtons[client][currentTrain][i] <= 0 || !IsValidEntity(g_pTrainButtons[client][currentTrain][i])) {
			// Name Button
			FormatEx(buttonName, sizeof(buttonName), "%s_%d_button%d", cAuth, currentTrain, i);
			
			// Create and Store Button
			buttonProp = CreateButton(buttonName);
			g_pTrainButtons[client][currentTrain][i] = buttonProp;
			
			break;
		}
	}
	
	// Teleport the Button
	float rayPos[3], clientPos[3], clientEye[3], clientAngle[3];
	GetClientAbsOrigin(client, clientPos);
	GetClientEyePosition(client, clientEye);
	GetClientEyeAngles(client, clientAngle);

	TR_TraceRayFilter(clientEye, clientAngle, MASK_SOLID, RayType_Infinite, TraceRayFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
		TR_GetEndPosition(rayPos);
	
	//keeping button 40 units higher than players foot position, unless raypoint is above 40 units
	if(RoundFloat(rayPos[2]) <= RoundFloat(clientPos[2]+40.0)) {
		rayPos[2] += ((clientPos[2]+40.0)-rayPos[2]);
	}
	
	TeleportEntity(buttonProp, rayPos, NULL_VECTOR, NULL_VECTOR);
		
	PrintToChat(client, "%s Attached Button [\x04%d\x01/\x05%d\x01] to Train [\x04%d\x01]", sTag, buttonCount+1, MAX_BUTTONS, currentTrain + 1);
	return Plugin_Handled;
}

//================================================================================
//																				//
//					***		TRAIN SETTINGS COMMANDS		***						//
//																				//
//================================================================================
//============================================================================
//								SET MODEL COMMAND							//
//============================================================================
public Action Cmd_SetModel(client, args)
{
	// Check if stealing model path from existing prop
	if(args < 1) {
		int aimTarg = GetClientAimTarget(client, false);
		
		if(aimTarg < 0 || !IsValidEntity(aimTarg)) {
			PrintToChat(client, "%s %s: Set the model of your train by looking at a prop or entering a path - \x04sm_train_model <model path>\x01", sTag, sUsage);
			return Plugin_Handled;
		}
		
		char sClass[32], sModel[128];
		GetEntityClassname(aimTarg, sClass, sizeof(sClass));
		
		if(StrContains(sClass, "prop_physics", false) == -1 && StrContains(sClass, "prop_dynamic", false) == -1) {
			PrintToChat(client, "%s %s: You cannot steal this entities model!", sTag, sError);
			return Plugin_Handled;
		}
		
		GetEntPropString(aimTarg, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		
		if(StrContains(sModel, "models", false) != -1) {
			g_pTrainModel[client] = sModel;
			
			PrintToChat(client, "%s \x03Model set to \"%s\"\x01", sTag, sModel);
			return Plugin_Handled;
		}

	}
	
	// Otherwise set model from argument
	char modelArg[128];
	GetCmdArg(1, modelArg, sizeof(modelArg)); TrimString(modelArg);
	
	if(PrecacheModel(modelArg) == 0 || StrContains(modelArg, "models/", false) == -1 || StrContains(modelArg, ".mdl") == -1) {
		PrintToChat(client, "%s %s: Invalid model! Example model: \x04\"models/props_junk/bicycle01a.mdl\"\x01", sTag, sError);
		return Plugin_Handled;
	}
	
	g_pTrainModel[client] = modelArg;
	
	PrintToChat(client, "%s \x03Model Set!\x01", sTag);
	return Plugin_Handled;
}

//============================================================================
//								SET SOUND COMMAND							//
//============================================================================
public Action Cmd_SetSound(client, args)
{
	if(args != 1) {
		PrintToChat(client, "%s %s: Set the movement sound that your train will emit - \x04sm_train_sound <sound path>\x01", sTag, sUsage);
		return Plugin_Handled;
	}
	
	char soundArg[128];
	GetCmdArg(1, soundArg, sizeof(soundArg)); TrimString(soundArg);
	
	if(StrEqual(soundArg, "none", false) || StrEqual(soundArg, "off", false) || StrEqual(soundArg, "0", false)) {
		g_pTrainSound[client] = soundArg;
		PrintToChat(client, "%s \x03Sound Disabled!\x01", sTag);
		return Plugin_Handled;
	}
	
	if(PrecacheSound(soundArg) == false || StrContains(soundArg, ".wav") == -1) {
		PrintToChat(client, "%s %s: Invalid sound! Example sound: \x04\"npc/attack_helicopter/aheli_rotor_loop1.wav\"\x01", sTag, sError);
		return Plugin_Handled;
	}
	
	g_pTrainSound[client] = soundArg;
	
	PrintToChat(client, "%s \x03Sound Set!\x01", sTag);
	return Plugin_Handled;
}

//============================================================================
//							SET ANIMATION COMMAND							//
//============================================================================
public Action Cmd_SetAnimation(client, args)
{
	if(args < 2) { 
		if(args < 1) {
			PrintToChat(client, "%s %s: Set the animation your train will play - \x04sm_train_animation <animation>\x01", sTag, sUsage);
			return Plugin_Handled;
		}
		else { // args == 1
			char animArg[128];
			GetCmdArg(1, animArg, sizeof(animArg)); TrimString(animArg);
			
			if(StrEqual(animArg, "none", false) || StrEqual(animArg, "off", false) || StrEqual(animArg, "0", false)) {
				PrintToChat(client, "%s \x03Animation Disabled!\x01", sTag);
				g_pTrainAnim[client] = "idle";
				g_tSettings[client][GetCurrentTrain(client)][2] = "idle";
			}
			else {
				g_pTrainAnim[client] = animArg;
				g_tSettings[client][GetCurrentTrain(client)][2] = animArg;
				
				PrintToChat(client, "%s \x03Animation set to \"%s\"\x01", sTag, animArg);
			}
			
			return Plugin_Handled;
		}
	}
	else { // args >= 2 (get train num and animation)
		char trainArg[16], animArg[128];
		GetCmdArg(1, trainArg, sizeof(trainArg)); TrimString(trainArg);
		GetCmdArg(2, animArg, sizeof(animArg)); TrimString(animArg);
		
		// Check if no active trains
		if(GetActiveTrainCount(client) <= 0) {
			PrintToChat(client, "%s %s: You don't have any active trains!", sTag, sError);
			return Plugin_Handled;
		}
		
		// Check if trainarg is numeric
		if(!IsStringNumeric(trainArg)) {
			PrintToChat(client, "%s %s: Only numbers are allowed for a train index! - \x04sm_train_animation <\x041\x01-\x04%d\x01> <animation>\x01", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
			
		int selectedTrain = StringToInt(trainArg)-1;
	
		// Check if input is within bounds
		if(selectedTrain < 0 || selectedTrain+1 > MAX_PLAYER_TRAINS) {
			PrintToChat(client, "%s %s: Index out of bounds! Only <\x041\x01-\x04%d\x01> allowed!", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		// Check if selected train is active
		if(g_pActiveTrains[client][selectedTrain] == false) {
			PrintToChat(client, "%s %s: Train [\x06%d\x01] is not active!", sTag, sError, selectedTrain+1);
			return Plugin_Handled;
		}
		
		int trainProp = GetEntPropEnt(g_pTrainEnts[client][selectedTrain], Prop_Data, "m_hMoveChild");
		
		if(StrEqual(animArg, "none", false) || StrEqual(animArg, "off", false) || StrEqual(animArg, "0", false)) {
			g_tSettings[client][selectedTrain][2] = "idle";
			
			PrintToChat(client, "%s \x03Animation Disabled!\x01", sTag);
		}
		else {
			g_tSettings[client][selectedTrain][2] = animArg;
			SetVariantString(animArg);
			
			PrintToChat(client, "%s \x03Animation for Train [\x04%s\x01] set to \"%s\"\x01", sTag, trainArg, animArg);
		}
		
		AcceptEntityInput(trainProp, "SetAnimation");
		return Plugin_Handled;
	}
}

//============================================================================
//								SET SPEED COMMAND							//
//============================================================================
public Action Cmd_SetSpeed(client, args)
{
	if(args != 1) {
		PrintToChat(client, "%s %s: Set the speed of which your train will travel - \x04sm_train_speed <1-%d>\x01", sTag, sUsage, MAX_SPEED);
		return Plugin_Handled;
	}
	
	char speedArg[16];
	GetCmdArg(1, speedArg, sizeof(speedArg)); TrimString(speedArg);
	
	if(!IsStringNumeric(speedArg)) {	
		PrintToChat(client, "%s %s: Only numbers are allowed!", sTag, sUsage);
		return Plugin_Handled;
	}
	
	if(StringToInt(speedArg) < 1 || StringToInt(speedArg) > MAX_SPEED ) {
		PrintToChat(client, "%s %s: Speed value out of bounds! (<1-%d> / Default: %s)", sTag, sUsage, MAX_SPEED, DEFAULT_SPEED);
		return Plugin_Handled;
	} 

	g_pTrainSpeed[client] = speedArg;
	
	PrintToChat(client, "%s \x03Speed set to %s\x01", sTag, speedArg);
	return Plugin_Handled;
}

//============================================================================
//							SET HEIGHT COMMAND								//
//============================================================================
public Action Cmd_SetHeight(client, args)
{
	if(args != 1) {
		PrintToChat(client, "%s %s: Set the height that your train will ride above/below the tracks - \x04sm_train_height <-%d to %d>\x01", sTag, sUsage, MAX_HEIGHT, MAX_HEIGHT);
		return Plugin_Handled;
	}
	
	char heightArg[16];
	GetCmdArg(1, heightArg, sizeof(heightArg)); TrimString(heightArg);
	
	if(!IsStringNumeric(heightArg)) {	
		PrintToChat(client, "%s %s: Only numbers are allowed!", sTag, sUsage);
		return Plugin_Handled;
	}
	
	if(StringToInt(heightArg) < (0-MAX_HEIGHT) || StringToInt(heightArg) > MAX_HEIGHT ) {
		PrintToChat(client, "%s %s: Height out of Bounds! (-%d to %d)", sTag, sUsage, MAX_HEIGHT, MAX_HEIGHT);
		return Plugin_Handled;
	} 

	g_pTrainHeight[client] = heightArg;
	
	PrintToChat(client, "%s \x03Height set to %s\x01", sTag, heightArg);
	return Plugin_Handled;
}

//============================================================================
//							SET ORIENTATION COMMAND							//
//============================================================================
public Action Cmd_SetOrient(client, args)
{
	if(args != 1) {
		PrintToChat(client, "%s %s: Set the turn type of your train - \x04sm_train_orientation <0-3>\x01", sTag, sUsage);
		return Plugin_Handled;
	}
	
	char orientArg[4];
	GetCmdArg(1, orientArg, sizeof(orientArg)); TrimString(orientArg);
	
	if(!IsStringNumeric(orientArg)) {	
		PrintToChat(client, "%s %s: Only numbers are allowed!", sTag, sUsage);
		return Plugin_Handled;
	}
	
	if(StringToInt(orientArg) < 0 || StringToInt(orientArg) > 3 ) {
		PrintToChat(client, "%s %s: Invalid Orientation! (<0-3> / Default: 0)", sTag, sUsage);
		return Plugin_Handled;
	} 

	g_pTrainOrient[client] = orientArg;
	
	PrintToChat(client, "%s \x03Orientation set to %s\x01", sTag, orientArg);
	return Plugin_Handled;
}

//================================================================================
//																				//
//			    ***		START/EDIT/DELETE TRAIN COMMANDS		***				//
//																				//
//================================================================================
//============================================================================
//								START TRAIN COMMAND							//
//============================================================================
public Action Cmd_StartTrain(client, args) 
{
	int currentTrain = GetCurrentTrain(client);
	
	if(currentTrain == MAX_PLAYER_TRAINS) {
		PrintToChat(client, "%s All of your Trains are already active!", sTag);
		return Plugin_Handled;
	}
	
	int pathTrackCount = GetPathTrackCount(client, currentTrain);

	if(pathTrackCount < 2) {
		PrintToChat(client, "%s %s: You must place at least two tracks to form a path!", sTag, sError);
		return Plugin_Handled;
	}
	
	// Path needs to be whole in order to function properly
	bool brokenPath = false;
	for(int i = 0; i < MAX_PATH_TRACKS; i++) {
		if(g_pPathPropEnts[client][currentTrain][i] <= 0 || !IsValidEntity(g_pPathPropEnts[client][currentTrain][i])) {
			for (int j = i+1; j < MAX_PATH_TRACKS; j++) {
				if(g_pPathPropEnts[client][currentTrain][j] > 0 && IsValidEntity(g_pPathPropEnts[client][currentTrain][j])) {
				PrintToChat(client, "%s %s: You must replace Track [\x06%d\x01]", sTag, sError, i+1);
				brokenPath = true;
				break;
				}
			}
		}
	}
	if (brokenPath == true) return Plugin_Handled;
	
	if(StrContains(g_pTrainModel[client], "models", false) == -1 || StrContains(g_pTrainModel[client], ".mdl", false) == -1) {
		PrintToChat(client, "%s %s: You must first set a train model with \x04sm_train_model\x01", sTag, sError);
		return Plugin_Handled;
	}
	
	// Get the positions of the path props to place the path_tracks at same origin
	float vecTracks[MAX_PATH_TRACKS][3];
	for(int i = 0; i < pathTrackCount; i++) {
		// Store position
		GetEntPropVector(g_pPathPropEnts[client][currentTrain][i], Prop_Send, "m_vecOrigin", vecTracks[i]);
		
		// Render the track models invisible
		SetEntityRenderMode(g_pPathPropEnts[client][currentTrain][i], RENDER_TRANSALPHA);
		SetEntityRenderColor(g_pPathPropEnts[client][currentTrain][i], 255, 255, 255, 0);
	}	
	
	char cAuth[128], trackName[32], firstTrackName[32], prevTrackName[32], trainName[32], trainPropName[32];
	
	// Format names with user auth
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
		
	FormatEx(firstTrackName, sizeof(firstTrackName), "%s_%d_track0", cAuth, currentTrain);
	FormatEx(trainName, sizeof(trainName), "%s_train%d", cAuth, currentTrain);
	FormatEx(trainPropName, sizeof(trainPropName), "%s_trainprop%d", cAuth, currentTrain);

	bool loop = !TrainHasButton(client, currentTrain);
	
	// Create the path, starting from the last track
	for(int i = pathTrackCount - 1; i >= 0; i--)
	{
		FormatEx(trackName, sizeof(trackName), "%s_%d_track%d", cAuth, currentTrain, i);
		g_pPathEnts[client][currentTrain][i] = CreatePath(client, trackName, vecTracks[i], prevTrackName, pathTrackCount, loop);
	
		strcopy(prevTrackName, sizeof(prevTrackName), trackName);
	}	
	
	// Loop the track if no button is attached (reverse and toggle if has button)
	if(loop) {
		SetEntPropString(g_pPathEnts[client][currentTrain][pathTrackCount - 1], Prop_Data, "m_target", firstTrackName);
		ActivateEntity(g_pPathEnts[client][currentTrain][pathTrackCount - 1]);
	}
	
	// Create and Store the func_tracktrain
	int tracktrain = CreateTrackTrain(client, trainName, firstTrackName);
	g_pTrainEnts[client][currentTrain] = tracktrain;

	// Create train prop
	int trainProp = CreateTrainProp(client, trainPropName);
	
	// Parent train prop to the func_tracktrain
	ParentToEntity(trainProp, tracktrain);	
	
	// Store the tracktrain settings
	g_tSettings[client][currentTrain][0] = g_pTrainModel[client];
	g_tSettings[client][currentTrain][1] = g_pTrainSound[client];
	g_tSettings[client][currentTrain][2] = g_pTrainAnim[client];
	g_tSettings[client][currentTrain][3] = g_pTrainSpeed[client];
	g_tSettings[client][currentTrain][4] = g_pTrainHeight[client];
	g_tSettings[client][currentTrain][5] = g_pTrainOrient[client];
	
	// Reset settings except model
	g_pTrainSound[client] = "none";
	g_pTrainAnim[client] = "idle";
	g_pTrainSpeed[client] = DEFAULT_SPEED;
	g_pTrainHeight[client] = "0";
	g_pTrainOrient[client] = "0";
	
	// Rotate the train prop (If Rotated)
	char sAngBuffers[3][128];
	float ang[3];
	ExplodeString(g_tSettings[client][currentTrain][6], " ", sAngBuffers, 3, 128); TrimString(sAngBuffers[2]);
	ang[0] = StringToFloat(sAngBuffers[0]);
	ang[1] = StringToFloat(sAngBuffers[1]);
	ang[2] = StringToFloat(sAngBuffers[2]);
	
	TeleportEntity(trainProp, NULL_VECTOR, ang, NULL_VECTOR);

	// Activate Train and set current train to the next available slot
	SetTrainActive(client, currentTrain, true);
	SetCurrentTrain(client, GetNextActiveTrain(client));
	
	PrintToChat(client, "%s Train [\x04%d\x01] Started! You own [\x04%d\x01/\x05%d\x01] Trains.", sTag, currentTrain + 1, GetActiveTrainCount(client), MAX_PLAYER_TRAINS);
	return Plugin_Handled;
}

//============================================================================
//								EDIT TRAIN COMMAND							//
//============================================================================
public Action Cmd_EditTrain(client, args) 
{
	int selectedTrain, currentTrain, trainCount;
	
	currentTrain = GetCurrentTrain(client);
	trainCount = GetActiveTrainCount(client);
	
	//check if all trains are active ("you have no active trains"!)
	if(trainCount <= 0) {
		PrintToChat(client, "%s %s: You don't have any active trains!", sTag, sError);
		return Plugin_Handled;
	}
	
	// Check if Editing from raypoint
	if(args < 1) {
		int aimTarg = GetClientAimTarget(client, false);
		
		// Check if Target is a Valid Entity
		if(aimTarg < 0 || !IsValidEntity(aimTarg)) {
			PrintToChat(client, "%s %s: Edit an active train by looking at it or indexing it - \x04sm_train_edit <1-%d>\x01", sTag, sUsage, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		
		char targetname[128], cAuth[64], ownerAuth[16];
		
		GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
		
		GetEntPropString(aimTarg, Prop_Data, "m_iName", targetname, sizeof(targetname));
		strcopy(ownerAuth, sizeof(ownerAuth), targetname);
		
		// Check if Target is a Train
		if(StrContains(targetname, "_trainprop") == -1) {
			PrintToChat(client, "%s %s: Edit an active train by looking at it or indexing it - \x04sm_train_edit <1-%d>\x01", sTag, sUsage, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		// Check Ownership
		if(!StrEqual(ownerAuth, cAuth)) {
			PrintToChat(client, "%s %s: You do not own this train!", sTag, sError);
			return Plugin_Handled;
		}
		// Get Train # from Name and Set Selected
		selectedTrain = GetFromName(aimTarg, "index");
	}
	// Otherwise Edit from argument
	else {

		char trainArg[16];
		GetCmdArg(1, trainArg, sizeof(trainArg)); TrimString(trainArg);
		
		// Check if trainarg is numeric
		if(!IsStringNumeric(trainArg)) {
			PrintToChat(client, "%s %s: Only numbers are allowed! <\x041\x01-\x04%d\x01>", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		
		selectedTrain = StringToInt(trainArg)-1;
		
		// Check if input is within bounds
		if(selectedTrain < 0 || selectedTrain+1 > MAX_PLAYER_TRAINS) {
			PrintToChat(client, "%s %s: Index out of bounds! Only <\x041\x01-\x04%d\x01> allowed!", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		// Check if already editing selected train
		if(selectedTrain == currentTrain) {
			PrintToChat(client, "%s %s: You're already currently editing Train [\x04%d\x01]!", sTag, sError, selectedTrain+1);
			return Plugin_Handled;
		}
		// Check if selected train is active
		if(g_pActiveTrains[client][selectedTrain] == false) {
			PrintToChat(client, "%s %s: Train [\x06%d\x01] is not active!", sTag, sError, selectedTrain+1);
			return Plugin_Handled;
		}
	}
	
	int newTrackCount = GetPathTrackCount(client, selectedTrain);
	
	// Delete any spawned buttons and/or track props if there are any
	if(currentTrain < MAX_PLAYER_TRAINS)
		KillButtonsAndTracks(client, currentTrain);

	int trainProp;
	float ang[3];
	
	// Kill the selected(editing) tracktrain
	if(g_pTrainEnts[client][selectedTrain] > 0 && IsValidEntity(g_pTrainEnts[client][selectedTrain])) {
		// Store trainprops Rotation before killing
		trainProp = GetEntPropEnt(g_pTrainEnts[client][selectedTrain], Prop_Data, "m_hMoveChild");
		GetEntPropVector(trainProp, Prop_Send, "m_angRotation", ang);
		
		// Kill tracktrain
		AcceptEntityInput(g_pTrainEnts[client][selectedTrain], "Kill");
		g_pTrainEnts[client][selectedTrain] = -1;
	}
	// Kill the selected(editing) trains path_tracks
	for(int i = 0; i < newTrackCount; i++) {
		if(g_pPathEnts[client][selectedTrain][i] > 0 && IsValidEntity(g_pPathEnts[client][selectedTrain][i])) {
			AcceptEntityInput(g_pPathEnts[client][selectedTrain][i], "Kill");
			g_pPathEnts[client][selectedTrain][i] = -1;
			
			// Render the track props visible again
			SetEntityRenderColor(g_pPathPropEnts[client][selectedTrain][i], 0, 0, 255, 255);
			SetEntityRenderFx(g_pPathPropEnts[client][selectedTrain][i], RENDERFX_PULSE_FAST);
		}
	}
	
	// Load train specific settings
	g_pTrainModel[client] = g_tSettings[client][selectedTrain][0];
	g_pTrainSound[client] = g_tSettings[client][selectedTrain][1];
	g_pTrainAnim[client] = g_tSettings[client][selectedTrain][2];
	g_pTrainSpeed[client] = g_tSettings[client][selectedTrain][3];
	g_pTrainHeight[client] = g_tSettings[client][selectedTrain][4];
	g_pTrainOrient[client] = g_tSettings[client][selectedTrain][5];
	
	// Store the Rotation of the train prop
	char sBuffer[32], sAng[32];
	FloatToString(ang[0], sBuffer, 32); StrCat(sAng, 32, sBuffer); StrCat(sAng, 32, " ");
	FloatToString(ang[1], sBuffer, 32); StrCat(sAng, 32, sBuffer); StrCat(sAng, 32, " ");
	FloatToString(ang[2], sBuffer, 32); StrCat(sAng, 32, sBuffer);
	
	g_tSettings[client][selectedTrain][6] = sAng; //stored train prop rotation
	
	// Deactivate and set the current train to the train being edited
	SetTrainActive(client, selectedTrain, false);
	SetCurrentTrain(client, selectedTrain);
	
	PrintToChat(client, "%s Editing Train [\x04%d\x01]", sTag, selectedTrain + 1);
	return Plugin_Handled;
}

//============================================================================
//								DELETE TRAIN COMMAND						//
//============================================================================
public Action Cmd_KillTrain(int client, int args)
{
	int selectedTrain, trainCount;
	trainCount = GetActiveTrainCount(client);
	
	// Check if no active trains
	if(trainCount <= 0) {
		PrintToChat(client, "%s %s: You don't have any active trains!", sTag, sError);
		return Plugin_Handled;
	}
	// Check if Deleting from raypoint
	if(args < 1) {
		int aimTarg = GetClientAimTarget(client, false);
		
		// Check if Target is a Valid Entity
		if(aimTarg < 0 || !IsValidEntity(aimTarg)) {
			PrintToChat(client, "%s %s: Delete an active train by looking at it or indexing it - \x04sm_train_delete <1-%d>\x01", sTag, sUsage, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		
		char targetname[128], cAuth[64], ownerAuth[16];
		
		GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
		
		GetEntPropString(aimTarg, Prop_Data, "m_iName", targetname, sizeof(targetname));
		strcopy(ownerAuth, sizeof(ownerAuth), targetname);
		
		// Check if Target is a Train
		if(StrContains(targetname, "_trainprop") == -1) {
			PrintToChat(client, "%s %s: Delete an active train by looking at it or indexing it - \x04sm_train_delete <1-%d>\x01", sTag, sUsage, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		// Check Ownership (TODO? Override access so admin with certain flag can delete other players trains)
		if(!StrEqual(ownerAuth, cAuth)) {
			PrintToChat(client, "%s %s: You do not own this train!", sTag, sError);
			return Plugin_Handled;
		}
		// Get Train # from Name and Set Selected
		selectedTrain = GetFromName(aimTarg, "index");
	}
	// Otherwise Delete from argument
	else {
		char trainArg[16];
		
		GetCmdArg(1, trainArg, sizeof(trainArg)); TrimString(trainArg);
		
		// Check if trainarg is numeric
		if(!IsStringNumeric(trainArg)) {
			PrintToChat(client, "%s %s: Only numbers are allowed! <\x041\x01-\x04%d\x01>", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		
		selectedTrain = StringToInt(trainArg)-1;
		
		// Check if input is within bounds
		if(selectedTrain < 0 || selectedTrain+1 > MAX_PLAYER_TRAINS) {
			PrintToChat(client, "%s %s: Index out of bounds! Only <\x041\x01-\x04%d\x01> allowed!", sTag, sError, MAX_PLAYER_TRAINS);
			return Plugin_Handled;
		}
		// Check if selected train is active
		if(g_pActiveTrains[client][selectedTrain] == false) {
			PrintToChat(client, "%s %s: Train [\x06%d\x01] is not active!", sTag, sError, selectedTrain+1);
			return Plugin_Handled;
		}
	}
	
	// Delete the func_tracktrain
	if(g_pActiveTrains[client][selectedTrain] == true && g_pTrainEnts[client][selectedTrain] > 0 && IsValidEntity(g_pTrainEnts[client][selectedTrain])) {
		AcceptEntityInput(g_pTrainEnts[client][selectedTrain], "Kill");
		g_pTrainEnts[client][selectedTrain] = -1;
		trainCount--;
		 
		// Delete the buttons and trackprops if any
		KillButtonsAndTracks(client, selectedTrain);
		
		for(int i = 0; i < MAX_PATH_TRACKS; i++) {
			// Delete the path_tracks
			if(g_pPathEnts[client][selectedTrain][i] > 0 && IsValidEntity( g_pPathEnts[client][selectedTrain][i] ) ) {
				AcceptEntityInput( g_pPathEnts[client][selectedTrain][i], "Kill");
				g_pPathEnts[client][selectedTrain][i] = -1;
			}
		}
		
		// Deactivate the train
		SetTrainActive(client, selectedTrain, false);
		
		// Choosing Next Current Train -->
		int currentTrain = GetCurrentTrain(client);
		
		// If at MAX Trains, but one was just deleted, set current train to next active (The one that was deleted)
		if(currentTrain == MAX_PLAYER_TRAINS && trainCount < MAX_PLAYER_TRAINS) {
			SetCurrentTrain(client, GetNextActiveTrain(client));
		}
		// If current train has no parts, then set current train to the lowest index (Comes after above to avoid invalid indexing)
		else if(GetPathTrackCount(client, currentTrain) <= 0 && !TrainHasButton(client, currentTrain)) {
			SetCurrentTrain(client, GetNextActiveTrain(client));
		}
	}
	
	PrintToChat(client, "%s Train [\x06%d\x01] deleted!", sTag, selectedTrain+1);
	return Plugin_Handled;
}

//================================================================================
//																				//
//			   		***		SAVE AND LOAD TRAIN COMMANDS	***					//
//																				//
//================================================================================
//============================================================================
//								SAVE TRAIN COMMAND							//
//============================================================================
public Action Cmd_SaveTrain(client, args)
{
	if(args < 2) {
		PrintToChat(client, "%s %s: Save an active train under an alias to be loaded later - \x04sm_train_save <train#> <alias>\x01", sTag, sUsage);
		return Plugin_Handled;
	}
	
	int trainCount = GetActiveTrainCount(client);
	
	if(trainCount <= 0) {
		PrintToChat(client, "%s %s: You don't have any active Trains!", sTag, sError);
		return Plugin_Handled;
	}
	
	char trainArg[16];
	GetCmdArg(1, trainArg, sizeof(trainArg)); TrimString(trainArg);
	
	if(!IsStringNumeric(trainArg)) {	
		PrintToChat(client, "%s %s: Only numbers are allowed for a train index!", sTag, sUsage);
		return Plugin_Handled;
	}
	
	int selectedTrain = StringToInt(trainArg)-1;
	
	if(selectedTrain < 0 || selectedTrain+1 > MAX_PLAYER_TRAINS) {
		PrintToChat(client, "%s %s: Invalid index! Only <\x041\x01-\x04%d\x01> allowed!\x01", sTag, sError, MAX_PLAYER_TRAINS);
		return Plugin_Handled;
	}
	if(g_pActiveTrains[client][selectedTrain] == false) {
		PrintToChat(client, "%s %s: Train [\x06%d\x01] is not active!", sTag, sError, selectedTrain+1);
		return Plugin_Handled;
	}
	
	char alias[64], cAuth[64];
	GetCmdArg(2, alias, sizeof(alias)); TrimString(alias);
	
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
	ReplaceString(cAuth, sizeof(cAuth), ":", "-"); //filename appropriate
	ReplaceString(cAuth, sizeof(cAuth), "U", "u", true); //lowercase for linux support
	
	char FileName[PLATFORM_MAX_PATH], sPath[PLATFORM_MAX_PATH], sMap[256];

	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "tracktrains/saves/%s", sMap);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);

	BuildPath(Path_SM, sPath, sizeof(sPath), "tracktrains/saves/%s/%s", sMap, cAuth);
	if(!DirExists(sPath))
		CreateDirectory(sPath, 511);
		
	BuildPath(Path_SM, FileName, sizeof(FileName), "tracktrains/saves/%s/%s/%s.txt", sMap, cAuth, alias);
	if (FileExists(FileName, true))
	{
		DeleteFile(FileName);
		PrintToChat(client, "%s Save under alias \x04%s \x01already exists ...Overwriting old save", sTag, alias);
	}	
	
	Handle _file = OpenFile(FileName, "w+");
	
	float ang[3], pos[3]; 
	
	int buttonCount = GetTrainButtonCount(client, selectedTrain);
	int trackCount = GetPathTrackCount(client, selectedTrain);
	
	// Write Train buttons
	WriteFileLine(_file, "%d", buttonCount); //number of buttons
	for (int i = 0; i < buttonCount; i++) {
		GetEntPropVector(g_pTrainButtons[client][selectedTrain][i], Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(g_pTrainButtons[client][selectedTrain][i], Prop_Send, "m_angRotation", ang);
		
		WriteFileLine(_file, "%f %f %f", pos[0], pos[1], pos[2]); //button position
		WriteFileLine(_file, "%f %f %f", ang[0], ang[1], ang[2]); //button rotation
	}
	
	// Write Train Settings
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][0]); //train model
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][1]); //train sound
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][2]); //train animation
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][3]); //train speed
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][4]); //train height
	WriteFileLine(_file, "%s", g_tSettings[client][selectedTrain][5]); //train orientation
	
	// Write Train Tracks
	WriteFileLine(_file, "%d", trackCount); //number of path tracks
	for (int i = 0; i < trackCount; i++) {
		GetEntPropVector(g_pPathPropEnts[client][selectedTrain][i], Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(g_pPathPropEnts[client][selectedTrain][i], Prop_Send, "m_angRotation", ang);
		
		WriteFileLine(_file, "%f %f %f", pos[0], pos[1], pos[2]); //path prop position
		WriteFileLine(_file, "%f %f %f", ang[0], ang[1], ang[2]); //path prop rotation		
	}

	// Write Train Prop Rotation, if Orientation is fixed
	if(StrEqual(g_tSettings[client][selectedTrain][5], "0")) {
		int trainProp = GetEntPropEnt(g_pTrainEnts[client][selectedTrain], Prop_Data, "m_hMoveChild");
		GetEntPropVector(trainProp, Prop_Send, "m_angRotation", ang);

		WriteFileLine(_file, "%f %f %f", ang[0], ang[1], ang[2]); //train prop rotation
	}
	
	FlushFile(_file);
	CloseHandle(_file);
	
	PrintToChat(client, "%s Saved Train [\x04%d\x01] under alias \x04%s\x01", sTag, selectedTrain + 1, alias);
	return Plugin_Handled;
}

//============================================================================
//								LOAD TRAIN COMMAND							//
//============================================================================
public Action Cmd_LoadTrain(client, args)
{
	if(args < 1) {
		PrintToChat(client, "%s %s: Load a train from a save alias - \x04sm_train_load <alias>\x01", sTag, sUsage);
		return Plugin_Handled;
	}
	
	int trainCount = GetActiveTrainCount(client);
	
	if(trainCount == MAX_PLAYER_TRAINS) {
		PrintToChat(client, "%s %s: You've reached the [\x05%d\x01/\x05%d\x01] Train limit! Delete a train to load another", sTag, sError, MAX_PLAYER_TRAINS, MAX_PLAYER_TRAINS);
		return Plugin_Handled;
	}
	
	int currentTrain = GetCurrentTrain(client);
	
	char alias[64], cAuth[64], formatAuth[64];
	GetCmdArg(1, alias, sizeof(alias));
	
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
	strcopy(formatAuth, sizeof(formatAuth), cAuth);
	ReplaceString(formatAuth, sizeof(formatAuth), ":", "-"); //filename appropriate
	ReplaceString(formatAuth, sizeof(formatAuth), "U", "u", true); //lowercase for linux support

	char FileName[PLATFORM_MAX_PATH], sMap[256];

	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, FileName, sizeof(FileName), "tracktrains/saves/%s/%s/%s.txt", sMap, formatAuth, alias);

	if(!FileExists(FileName, true)) {
		PrintToChat(client, "%s %s: The save alias \x04%s\x01 does not exist on this map!", sTag, sError, alias);
		return Plugin_Handled;
	}
	
	Handle _file;
	char _sFileBuffer[512], sBuffers[3][128];
	
	int buttonCount, trackCount;
	float pos[3], ang[3];
	
	// Delete any buttons and/or trackprops that are spawned
	if(currentTrain < MAX_PLAYER_TRAINS)
		KillButtonsAndTracks(client, currentTrain);
	
	_file = OpenFile(FileName, "r");
	
	// Read Button Count (determines how many lines down to read for pos/ang)
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	buttonCount = StringToInt(_sFileBuffer);
	
	// Train Buttons
	for (int i = 0; i < buttonCount; i++) {
		// Name Button
		char name[64];
		FormatEx(name, sizeof(name), "%s_%d_button%d", cAuth, currentTrain, i);
		
		// Create and Store Button
		int button = CreateButton(name);
		g_pTrainButtons[client][currentTrain][i] = button;
		
		//  Read Button Position
		ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer));
		ExplodeString(_sFileBuffer, " ", sBuffers, 3, 128); TrimString(sBuffers[2]);
		pos[0] = StringToFloat(sBuffers[0]);
		pos[1] = StringToFloat(sBuffers[1]);
		pos[2] = StringToFloat(sBuffers[2]);
		
		// Read Button Rotation
		ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer));
		ExplodeString(_sFileBuffer, " ", sBuffers, 3, 128); TrimString(sBuffers[2]);
		ang[0] = StringToFloat(sBuffers[0]);
		ang[1] = StringToFloat(sBuffers[1]);
		ang[2] = StringToFloat(sBuffers[2]);
		
		TeleportEntity(button, pos, ang, NULL_VECTOR);
	}
	
	// Read Train Model
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainModel[client], 128, _sFileBuffer);
	PrecacheModel(g_pTrainModel[client]);
	
	// Read Train Sound
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainSound[client], 128, _sFileBuffer);
	PrecacheSound(g_pTrainSound[client]);
	
	// Read Train Animation
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainAnim[client], 128, _sFileBuffer);
	
	// Read Train Speed
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainSpeed[client], 128, _sFileBuffer);

	// Read Train Height
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainHeight[client], 128, _sFileBuffer);
	
	// Read Train Orientation
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	strcopy(g_pTrainOrient[client], 128, _sFileBuffer);
	
	// Read Train Track Count
	ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer)); TrimString(_sFileBuffer);
	trackCount = StringToInt(_sFileBuffer);
	
	// Train Track Props
	for (int i = 0; i < trackCount; i++) {
		// Name Track Prop
		char pathPropName[64];
		Format(pathPropName, sizeof(pathPropName), "%s_%d_pathprop%d", cAuth, g_pCurrentTrain[client], i);	
		
		// Create and Store Track Prop
		int trackProp = CreateTrackProp(pathPropName);
		g_pPathPropEnts[client][currentTrain][i] = trackProp;

		// Read Track Position
		ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer));
		ExplodeString(_sFileBuffer, " ", sBuffers, 3, 128); TrimString(sBuffers[2]);
		pos[0] = StringToFloat(sBuffers[0]);
		pos[1] = StringToFloat(sBuffers[1]);
		pos[2] = StringToFloat(sBuffers[2]);
		
		// Read Track Rotation
		ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer));
		ExplodeString(_sFileBuffer, " ", sBuffers, 3, 128); TrimString(sBuffers[2]);
		ang[0] = StringToFloat(sBuffers[0]);
		ang[1] = StringToFloat(sBuffers[1]);
		ang[2] = StringToFloat(sBuffers[2]);
		
		TeleportEntity(trackProp, pos, ang, NULL_VECTOR);
	}
	
	// Read Train Prop Rotation (if line exists)
	if(ReadFileLine(_file, _sFileBuffer, sizeof(_sFileBuffer))) {
		ExplodeString(_sFileBuffer, " ", sBuffers, 3, 128); TrimString(sBuffers[2]);
		ang[0] = StringToFloat(sBuffers[0]);
		ang[1] = StringToFloat(sBuffers[1]);
		ang[2] = StringToFloat(sBuffers[2]);
	}
	
	// Close File
	FlushFile(_file);
	CloseHandle(_file);
	
	// Start Train
	Cmd_StartTrain(client, 0);
	
	// Set Rotation of the Train Prop if it has rotation (Must be done after Start)
	if(ang[0] != 0.0 || ang[1] != 0.0 || ang[2] != 0.0) {
		int trainProp = GetEntPropEnt(g_pTrainEnts[client][currentTrain], Prop_Data, "m_hMoveChild");
		TeleportEntity(trainProp, NULL_VECTOR, ang, NULL_VECTOR);
	}
	
	PrintToChat(client, "%s Loaded Train [\x04%d\x01] from alias \x04%s\x01", sTag, currentTrain+1, alias);
	return Plugin_Handled;
}

//============================================================================
//								PRINT SAVES COMMAND							//
//============================================================================
public Action Cmd_PrintSaves(client, args)
{
	char cAuth[64], formatAuth[64];
	
	GetClientAuthId(client, AuthId_Steam3, cAuth, sizeof(cAuth), true);
	strcopy(formatAuth, sizeof(formatAuth), cAuth);
	ReplaceString(formatAuth, sizeof(formatAuth), ":", "-"); //filename appropriate
	ReplaceString(formatAuth, sizeof(formatAuth), "U", "u", true); //lowercase for linux support

	char sMap[256], sPath[PLATFORM_MAX_PATH];

	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, sPath, sizeof(sPath), "tracktrains/saves/%s/%s", sMap, formatAuth);

	if (!DirExists(sPath)) {
		PrintToChat(client, "%s %s: You don't have any saves on the current map!", sTag, sError);
		return Plugin_Handled;
	}
        
	PrintToChat(client, "%s Save aliases on current map:", sTag);
	
	int fCounter = 0;
	char fBuffer[256][64];

	DirectoryListing dList = OpenDirectory(sPath);
	
	while(dList.GetNext(fBuffer[fCounter], sizeof(fBuffer))) {
		if(StrEqual(fBuffer[fCounter], ".") || StrEqual(fBuffer[fCounter], ".."))
			continue;
			
		ReplaceString(fBuffer[fCounter], sizeof(fBuffer), ".txt", "", false);
		PrintToChat(client, "%d. %s", fCounter, fBuffer[fCounter++]);
	} 
	
	return Plugin_Handled;
}

//================================================================================
//																				//
//							***	HOOKS AND FILTERS	***							//
//																				//
//================================================================================
//============================================================================
//								HOOK BUTTON USE								//
//============================================================================
public OnButtonUse(int button) {
	char targetname[128], authButton[16], authTrain[16];
	int trainIndex;
	
	GetEntPropString(button, Prop_Data, "m_iName", targetname, sizeof(targetname));
	strcopy(authButton, sizeof(authButton), targetname);
	
	trainIndex = GetFromName(button, "train");
	
	for(int i = 1; i < MaxClients; i++) {
		if(g_pTrainEnts[i][trainIndex] > 0 && IsValidEntity(g_pTrainEnts[i][trainIndex])) {
			GetEntPropString(g_pTrainEnts[i][trainIndex], Prop_Data, "m_iName", targetname, sizeof(targetname));
			strcopy(authTrain, sizeof(authTrain), targetname);
			if(StrEqual(authButton, authTrain)) {
				AcceptEntityInput(g_pTrainEnts[i][trainIndex], "Reverse");
				AcceptEntityInput(g_pTrainEnts[i][trainIndex], "Toggle");
				break;
			}
		}		
	}
}

//============================================================================
//							HOOK ENTITY DESTROYED							//
//============================================================================
public OnEntityDestroyed(entity) {
	// Useful with a delete entity command
	char targetname[128], ownerAuth[16], cAuth[16];
	
	GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if(StrContains(targetname,"_pathprop", true) != -1 || StrContains(targetname,"_button", true) != -1) {
		strcopy(ownerAuth, sizeof(ownerAuth), targetname);
		for(int i = 1; i < MaxClients; i++) {
			if(IsClientInGame(i)) {				
				GetClientAuthId(i, AuthId_Steam3, cAuth, sizeof(cAuth), true);
				if(StrEqual(ownerAuth, cAuth)) {
					int train = GetFromName(entity, "train");
					int index = GetFromName(entity, "index");
					if(StrContains(targetname,"_button", true) != -1) {
						g_pTrainButtons[i][train][index] = -1;
						if(g_pDisplayDeleteMsg[i] == true)
							PrintToChat(i, "%s Deleted Button for Train [\x04%d\x01]", sTag, train+1);
						break;
					}
					else if(StrContains(targetname,"_pathprop", true) != -1) {
						g_pPathPropEnts[i][train][index] = -1;
						if(g_pDisplayDeleteMsg[i] == true)
							PrintToChat(i, "%s Deleted Track [\x06%d\x01] for Train [\x04%d\x01]", sTag, index+1, train+1);
						break;
					}
				}
			}	
		}	
	}
}
//============================================================================
//							FILTER FOR SPAWNING								//
//============================================================================
public bool TraceRayFilterPlayer(int entityAtPoint, int mask, any:client)
{
	if(entityAtPoint == client)
		return false;
	return true;
}

//================================================================================
//																				//
//			***		UTILTIES FOR CREATING/DELETING TRAIN		***				//
//																				//
//================================================================================
//============================================================================
//								CREATION UTILS								//
//============================================================================
stock int CreateTrackProp(const char[] name)
{
	int ent = CreateEntityByName("prop_physics_override");

	DispatchKeyValue(ent, "targetname", name);
	DispatchKeyValue(ent, "model", TRACK_MODEL);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);
		
	if(DispatchSpawn(ent)) {
		SetEntityRenderColor(ent, 0, 0, 255, 255);
		SetEntityRenderFx(ent, RENDERFX_PULSE_FAST);
		AcceptEntityInput(ent, "DisableMotion");
	}
	
	return ent;
}
/////
stock int CreateButton(const char[] name)
{
	int ent = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue(ent, "targetname", name);
	DispatchKeyValue(ent, "model", BUTTON_MODEL);
	DispatchKeyValue(ent, "spawnflags", "256");

	if (DispatchSpawn(ent)) {
		AcceptEntityInput(ent, "DisableMotion");
		SDKHook(ent, SDKHook_Use, OnButtonUse);
	}
	
	return ent;
}
/////
stock int CreatePath(int client, const char[] name, const float pos[3], const char[] nexttarget, int count, bool loop)
{
	int ent = CreateEntityByName("path_track");
	
	DispatchKeyValue(ent, "targetname", name);
	DispatchKeyValue(ent, "target", nexttarget);
		
	DispatchSpawn(ent);
	
	if(loop == true) {
		if(ent != g_pPathEnts[client][g_pCurrentTrain[client]][count-1])
			ActivateEntity(ent);
	}
	else {
		ActivateEntity(ent);
	}
		
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	return ent;
}
/////
stock int CreateTrackTrain(int client, const char[] name, const char[] firstpath)
{
	int ent = CreateEntityByName("func_tracktrain");
	
	#define SF_NOUSERCONTROL 2
	#define SF_PASSABLE 8
	#define SF_UNBLOCKABLE 512
	#define SF_NO_ROTATE 1
	#define SF_FIXED_ORIENT 16
	
	char spawnflags[16];
	if(StrEqual(g_pTrainOrient[client], "0"))
		FormatEx(spawnflags, sizeof(spawnflags), "%i", SF_NO_ROTATE | SF_FIXED_ORIENT | SF_NOUSERCONTROL | SF_PASSABLE | SF_UNBLOCKABLE);
	else
		FormatEx(spawnflags, sizeof(spawnflags), "%i", SF_NOUSERCONTROL | SF_PASSABLE | SF_UNBLOCKABLE);
	
	DispatchKeyValue(ent, "targetname", name);
	DispatchKeyValue(ent, "target", firstpath);
	DispatchKeyValue(ent, "model", MAGIC_BRUSH_MODEL);
	DispatchKeyValue(ent, "startspeed", g_pTrainSpeed[client]);
	DispatchKeyValue(ent, "speed", g_pTrainSpeed[client]);
	DispatchKeyValue(ent, "orientationtype", g_pTrainOrient[client]);
	DispatchKeyValue(ent, "height", g_pTrainHeight[client]);
	
	if (!StrEqual(g_pTrainSound[client], "none", false) || !StrEqual(g_pTrainSound[client], "off", false) || !StrEqual(g_pTrainSound[client], "0", false))
		DispatchKeyValue(ent, "MoveSound", g_pTrainSound[client]);
	
	DispatchKeyValue(ent, "wheels", "256");
	DispatchKeyValue(ent, "bank", "0");
	
	DispatchKeyValue(ent, "spawnflags", spawnflags);
	DispatchSpawn(ent);
	
	SetEntProp(ent, Prop_Send, "m_fEffects", 32);
	
	return ent;
}
/////
stock int CreateTrainProp(int client, const char[] name)
{
	int ent = CreateEntityByName("prop_dynamic_override");
	
	DispatchKeyValue(ent, "targetname", name);
	DispatchKeyValue(ent, "solid", "1");
	DispatchKeyValue(ent, "model", g_pTrainModel[client]);
	
	DispatchSpawn(ent);
	
	if(!StrEqual(g_pTrainAnim[client], "0") || !StrEqual(g_pTrainAnim[client], "none") || !StrEqual(g_pTrainAnim[client], "off")) {
		SetVariantString(g_pTrainAnim[client]);
		AcceptEntityInput(ent, "SetAnimation");
	}
	
	return ent;
}
/////
stock bool ParentToEntity(int ent, target)
{
	SetVariantEntity(target);

	return AcceptEntityInput(ent, "SetParent");
}

//============================================================================
//								DELETION UTILS								//
//============================================================================
// Delete buttons and track props if any are spawned in the world
stock void KillButtonsAndTracks(int client, int train) {
	g_pDisplayDeleteMsg[client] = false;
	// Delete Buttons
	if(TrainHasButton(client, train)) { 
		for (int i = 0; i < MAX_BUTTONS; i++) {
			if(g_pTrainButtons[client][train][i] > 0 && IsValidEntity(g_pTrainButtons[client][train][i])) {
				AcceptEntityInput(g_pTrainButtons[client][train][i], "Kill");
				g_pTrainButtons[client][train][i] = -1;
			}
		}
	}
	// Delete Track Props
	if(GetPathTrackCount(client, train) > 0) {
	for (int i = 0; i < MAX_PATH_TRACKS; i++) {
			if(g_pPathPropEnts[client][train][i] > 0 && IsValidEntity(g_pPathPropEnts[client][train][i])) {
				AcceptEntityInput(g_pPathPropEnts[client][train][i], "Kill");
				g_pPathPropEnts[client][train][i] = -1;
			}
		}
	}
	g_pDisplayDeleteMsg[client] = true;
}

//================================================================================
//																				//
//						***		CODE UTILITIES		***							//
//																				//
//================================================================================
stock bool IsStringNumeric(char[] string) {
	bool numeric = true;
	
	for (int i = 0; i < strlen(string); i++) {
		if(!IsCharNumeric(string[i])) {
			if(i == 0 && string[0] == '-')
				continue;
				
			numeric = false;
			break;
		}
	}
	return numeric;
}
//
stock void SetCurrentTrain(int client, int train) {
	g_pCurrentTrain[client] = train;
}
stock int GetCurrentTrain(int client) {
	return g_pCurrentTrain[client];
}
/////
stock void SetTrainActive(int client, int train, bool active) {
	g_pActiveTrains[client][train] = active;
}
stock int GetNextActiveTrain(int client) {
	for(int i = 0; i < MAX_PLAYER_TRAINS; i++) {
		if(g_pActiveTrains[client][i] == false)
			return i;
	}
	return MAX_PLAYER_TRAINS;
}
stock int GetActiveTrainCount(int client) {
	int count = 0;
	for(int i = 0; i < MAX_PLAYER_TRAINS; i++) {
		if(g_pTrainEnts[client][i] > 0 && IsValidEntity(g_pTrainEnts[client][i]))
			count++;
	}
	return count;
}
/////
stock int GetPathTrackCount(int client, int train) {
	int count = 0;
	for(int i = 0; i < MAX_PATH_TRACKS; i++) {
		if(g_pPathPropEnts[client][train][i] > 0 && IsValidEntity(g_pPathPropEnts[client][train][i]))
			count++;
	}
	return count;
}
/////
stock bool TrainHasButton(int client, int train) {
	return GetTrainButtonCount(client, train) > 0;
}
stock int GetTrainButtonCount(client, train) {
	int count = 0;
	for (int i = 0; i < MAX_BUTTONS; i++) {
		if(g_pTrainButtons[client][train][i] > 0 && IsValidEntity(g_pTrainButtons[client][train][i]))
			count++;
	}
	return count;
}
/////
stock int GetFromName(int entity, char[] data) {
	if(entity < 0 || !IsValidEntity(entity))
		return -1;
	
	char targetname[64], sIndex[12];
	
	GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
	
	if(StrEqual(data, "train")) {
		// From Button, PathProp or Track
		if(StrContains(targetname, "_button") != -1 || StrContains(targetname, "_pathprop") != -1 || StrContains(targetname, "_track") != -1) {
			for(int i = 0; i < strlen(targetname); i++) {
				if(targetname[i] == ']' && targetname[i+1] == '_' && IsCharNumeric(targetname[i+2])) {
					StrCat(sIndex, 12, targetname[i + 2]);
					if(targetname[i+3] != '_' && IsCharNumeric(targetname[i+3]))
						StrCat(sIndex, 12, targetname[i + 3]);
					break;
				}
			}
		}
	}
	else if(StrEqual(data, "index")) {
		if(IsCharNumeric(targetname[strlen(targetname)-2]))
			StrCat(sIndex, 12, targetname[strlen(targetname) - 2]);
		StrCat(sIndex, 12, targetname[strlen(targetname) - 1]); TrimString(sIndex);
	}
	
	if(IsCharNumeric(sIndex[0]))
		return StringToInt(sIndex);
		
	return -1;
}