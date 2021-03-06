#define DEBUG

#define PLUGIN_AUTHOR "Stugger"
#define PLUGIN_VERSION "2.2"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "GrabEnt",
	author = PLUGIN_AUTHOR,
	description = "Grab then Move, Push/Pull or Rotate the entity you're looking at until released",
	version = PLUGIN_VERSION,
	url = ""
};

int g_pGrabbedEnt[MAXPLAYERS + 1];
int g_eRotationAxis[MAXPLAYERS + 1] =  { -1, ... };
int g_eOriginalColor[MAXPLAYERS + 1][4];

float g_pLastButtonPress[MAXPLAYERS + 1];
float g_fGrabOffset[MAXPLAYERS + 1][3];
float g_fGrabDistance[MAXPLAYERS + 1];

bool g_pWasInNoclip[MAXPLAYERS + 1];
bool g_pInRotationMode[MAXPLAYERS + 1];
bool g_eReleaseFreeze[MAXPLAYERS + 1] =  { true, ... };

Handle g_eGrabTimer[MAXPLAYERS+1];

int g_BeamSprite; 
int g_HaloSprite;

public void OnPluginStart()
{
	RegAdminCmd("sm_grabent_freeze", Cmd_ReleaseFreeze, ADMFLAG_CHEATS, "<0/1> - Toggle entity freeze/unfreeze on release.");
	RegAdminCmd("+grabent", Cmd_Grab, ADMFLAG_CHEATS, "Grab the entity in your crosshair.");
	RegAdminCmd("-grabent", Cmd_Release, ADMFLAG_CHEATS, "Release the grabbed entity.");
}

public void OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt", true);
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt", true);
	
	for (int i = 0; i < MAXPLAYERS; i++) {
		g_pGrabbedEnt[i] = -1;
		g_eRotationAxis[i] = -1;
		g_pLastButtonPress[i] = 0.0;
		
		g_pWasInNoclip[i] = false;
		g_pInRotationMode[i] = false;
		g_eReleaseFreeze[i] = true;
		
		g_eGrabTimer[i] = null;
	}
}
public void OnClientDisconnect(client)
{
	if (g_pGrabbedEnt[client] != -1 && IsValidEntity(g_pGrabbedEnt[client]))
		Cmd_Release(client, 0);
		
	g_eRotationAxis[client] = -1;
	
	g_pLastButtonPress[client] = 0.0;
	
	g_pWasInNoclip[client] = false;
	g_pInRotationMode[client] = false;
	g_eReleaseFreeze[client] = true;
}

//============================================================================
//							FREEZE SETTING COMMAND							//
//============================================================================
public Action Cmd_ReleaseFreeze(client, args)
{
	if (args < 1) {
		ReplyToCommand(client, "\x04[SM]\x01 \x05sm_grabent_freeze <0/1>\x01 -- \x050\x01: Entity unfreeze on release, \x051\x01: Entity freeze on release");
		return Plugin_Handled;
	}
	
	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg)); TrimString(sArg);
	
	if (!StrEqual(sArg, "0") && !StrEqual(sArg, "1")) {
		ReplyToCommand(client, "\x04[SM]\x01 ERROR: Value can only be either 0 or 1");
		return Plugin_Handled;
	}

	g_eReleaseFreeze[client] = StrEqual(sArg, "1") ? true : false;
	
	PrintToChat(client, "\x04[SM]\x01 Entities will now be \x05%s\x01 on Release!", g_eReleaseFreeze[client] == true ? "Frozen" : "Unfrozen");
	return Plugin_Handled;
}

//============================================================================
//							GRAB ENTITY COMMAND								//
//============================================================================
public Action Cmd_Grab(client, args) {
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Handled;
	
	if (g_pGrabbedEnt[client] > 0 && IsValidEntity(g_pGrabbedEnt[client])) {
		Cmd_Release(client, 0);
		return Plugin_Handled;
	}
		
	int ent = GetClientAimTarget(client, false);
	
	if (ent == -1 || !IsValidEntity(ent))
		return Plugin_Handled; //<-- timer to allow search for entity??
		
	float entOrigin[3], playerGrabOrigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", entOrigin);
	GetClientEyePosition(client, playerGrabOrigin);
	
	g_pGrabbedEnt[client] = ent;
	
	// Watch change in client physics type
	SDKHook(client, SDKHook_PreThink, OnPreThink);
	
	// Get the point at which the ray first hit the entity
	float initialRay[3];
	initialRay[0] = GetInitialRayPosition(client, 'x');
	initialRay[1] = GetInitialRayPosition(client, 'y');
	initialRay[2] = GetInitialRayPosition(client, 'z');
	
	// Calculate the offset between intitial ray hit and the entities origin
	g_fGrabOffset[client][0] = entOrigin[0] - initialRay[0];
	g_fGrabOffset[client][1] = entOrigin[1] - initialRay[1];
	g_fGrabOffset[client][2] = entOrigin[2] - initialRay[2];
	
	// Calculate the distance between ent and player
	float xDis = Pow(initialRay[0]-(playerGrabOrigin[0]), 2.0);
	float yDis = Pow(initialRay[1]-(playerGrabOrigin[1]), 2.0);
	float zDis = Pow(initialRay[2]-(playerGrabOrigin[2]), 2.0);
	g_fGrabDistance[client] = SquareRoot((xDis)+(yDis)+(zDis));

	// Get and Store entities original color (useful if colored)
	int entColor[4];
	int colorOffset = GetEntSendPropOffs(ent, "m_clrRender");
	
	if (colorOffset > 0) 
	{
		entColor[0] = GetEntData(ent, colorOffset, 1);
		entColor[1] = GetEntData(ent, colorOffset + 1, 1);
		entColor[2] = GetEntData(ent, colorOffset + 2, 1);
		entColor[3] = GetEntData(ent, colorOffset + 3, 1);
	}
	
	g_eOriginalColor[client][0] = entColor[0];
	g_eOriginalColor[client][1] = entColor[1];
	g_eOriginalColor[client][2] = entColor[2];
	g_eOriginalColor[client][3] = entColor[3];
	
	// Set entities color to grab color (green and semi-transparent)
	SetEntityRenderMode(ent, RENDER_TRANSALPHA);
	SetEntityRenderColor(ent, 0, 255, 0, 235);
	
	// Freeze entity
	char sClass[64];
	GetEntityClassname(ent, sClass, sizeof(sClass)); TrimString(sClass);
	
	if (StrEqual(sClass, "player", false))
		SetEntityMoveType(ent, MOVETYPE_NONE);
	else
		AcceptEntityInput(ent, "DisableMotion");
	
	// Disable weapon prior to timer
	SetWeaponDelay(client, 1.0);
	
	// Make sure rotation mode can immediately be entered
	g_pLastButtonPress[client] = GetGameTime() - 2.0;
	g_pInRotationMode[client] = false;
	
	DataPack pack;
	g_eGrabTimer[client] = CreateDataTimer(0.1, Timer_UpdateGrab, pack, TIMER_REPEAT);
	pack.WriteCell(client);
	
	return Plugin_Handled;
}
 
//============================================================================
//							TIMER FOR GRAB ENTITY							//
//============================================================================
public Action Timer_UpdateGrab(Handle timer, DataPack pack) {
	int client;
	pack.Reset();
	client = pack.ReadCell();
	
	if (!IsValidEntity(client) || client < 1 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Stop;
	
	if (g_pGrabbedEnt[client] == -1 || !IsValidEntity(g_pGrabbedEnt[client]))
		return Plugin_Stop;
	
	// Continuously delay use of weapon, as to not fire any bullets when pushing/pulling/rotating
	SetWeaponDelay(client, 1.0);	
	
	// *** Enable/Disable Rotation Mode
	if (GetClientButtons(client) & IN_RELOAD) {
		// Avoid instant enable/disable of rotation mode by requiring a one second buffer
		if (GetGameTime() - g_pLastButtonPress[client] >= 1.0) {
			g_pLastButtonPress[client] = GetGameTime();
			g_pInRotationMode[client] = g_pInRotationMode[client] == true ? false : true;
			PrintToChat(client, "\x04[SM]\x01 Rotation Mode \x05%s\x01", g_pInRotationMode[client] == true ? "Enabled" : "Disabled");		
			
			// Restore the entities color and alpha if enabling
			if(g_pInRotationMode[client]) {
				SetEntityRenderColor(g_pGrabbedEnt[client], 255, 255, 255, 255);
				PrintToChat(client, "\x05[A]\x01 RED \x05[S]\x01 GREEN \x05[D]\x01 BLUE \x05[W]\x01 SHOW RINGS");
			}
			// Change back to grabbed color if disabling
			else
				SetEntityRenderColor(g_pGrabbedEnt[client], 0, 255, 0, 235);
		}
	}
	// ***In Rotation Mode
	if (g_pInRotationMode[client]) {
		SDKUnhook(client, SDKHook_PreThink, OnPreThink);
		SetEntityMoveType(client, MOVETYPE_NONE);
		
		float ang[3], pos[3], mins[3], maxs[3];
		GetEntPropVector(g_pGrabbedEnt[client], Prop_Send, "m_angRotation", ang);
		GetEntPropVector(g_pGrabbedEnt[client], Prop_Send, "m_vecOrigin", pos);
		GetEntPropVector(g_pGrabbedEnt[client], Prop_Send, "m_vecMins", mins);
		GetEntPropVector(g_pGrabbedEnt[client], Prop_Send, "m_vecMaxs", maxs);
		
		// If the entity is a child, it will have a null position, so we'll hesitantly use the parents position
		int parent = GetEntPropEnt(g_pGrabbedEnt[client], Prop_Data, "m_hMoveParent");
		if (parent > 0 && IsValidEntity(parent))
			GetEntPropVector(parent, Prop_Send, "m_vecOrigin", pos);
		
		// Get rotation axis from button press
		int buttonPress = GetClientButtons(client);	
		switch(buttonPress) {
			case IN_FORWARD: g_eRotationAxis[client] = -1;  // [W] = Show Rings
			case IN_MOVELEFT: g_eRotationAxis[client] = 0;  // [A] = x axis
			case IN_BACK: g_eRotationAxis[client] = 1; 		// [S] = y axis
			case IN_MOVERIGHT: g_eRotationAxis[client] = 2; // [D] = z axis
		}
			
		// Reset angles when A+S+D is pressed
		if((buttonPress & IN_MOVELEFT) && (buttonPress & IN_BACK) && (buttonPress & IN_MOVERIGHT)) { 
			ang[0] = 0.0; ang[1] = 0.0; ang[2] = 0.0;
			g_eRotationAxis[client] = -1;
		}
		
		// Largest side should dictate the diameter of the rings
		float diameter, sendAng[3];
		diameter = (maxs[0] > maxs[1]) ? (maxs[0] + 10.0) : (maxs[1] + 10.0);
		diameter = ((maxs[2] + 10.0) > diameter) ? (maxs[2] + 10.0) : diameter;
		
		// Sending original ang will cause non-stop rotation issue
		sendAng = ang; 
		
		// Draw rotation rings
		switch(g_eRotationAxis[client]) {
			case -1: CreateRing(client, sendAng, pos, diameter, 0, true); // all 3 rings
			case 0:  CreateRing(client, sendAng, pos, diameter, 0, false); // red (x)
			case 1:  CreateRing(client, sendAng, pos, diameter, 1, false); // green (y)
			case 2:  CreateRing(client, sendAng, pos, diameter, 2, false); // blue (z)
		}
		
		// Rotate with mouse if on a rotation axis (A,S,D)
		if (g_eRotationAxis[client] != -1) {
			// + Rotate
			if (GetClientButtons(client) & IN_ATTACK) 
				ang[g_eRotationAxis[client]] += 10.0;
			// - Rotate
			else if (GetClientButtons(client) & IN_ATTACK2) 
				ang[g_eRotationAxis[client]] -= 10.0;
		}
		
		TeleportEntity(g_pGrabbedEnt[client], NULL_VECTOR, ang, NULL_VECTOR);
	}
	// ***Not in Rotation Mode
	if (!g_pInRotationMode[client] || g_eRotationAxis[client] == -1) {
		// Keep track of player noclip as to avoid forced enable/disable
		if(!g_pInRotationMode[client]) {
			SDKHook(client, SDKHook_PreThink, OnPreThink);
			
			if (g_pWasInNoclip[client])
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
			else 
				SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
		}
		// Push entity (Allowed if we're in rotation mode, not on a rotation axis (-1))
		if (GetClientButtons(client) & IN_ATTACK) 
		{
			if (g_fGrabDistance[client] < 60)
	    		g_fGrabDistance[client] += 1;
			else
	    		g_fGrabDistance[client] += g_fGrabDistance[client] / 25;
		}
		// Pull entity (Allowed if we're in rotation mode, not on a rotation axis (-1))
		else if (GetClientButtons(client) & IN_ATTACK2 && g_fGrabDistance[client] > 25) 
		{
			if (g_fGrabDistance[client] < 60)
	    		g_fGrabDistance[client] -= 1;
			else
	    		g_fGrabDistance[client] -= g_fGrabDistance[client] / 25;		
		}
		
		g_eRotationAxis[client] = -1;
	}

	// *** Runs whether in rotation mode or not
	float entNewPos[3];
	entNewPos[0] = GetEntNewPosition(client, 'x') + g_fGrabOffset[client][0];
	entNewPos[1] = GetEntNewPosition(client, 'y') + g_fGrabOffset[client][1];
	entNewPos[2] = GetEntNewPosition(client, 'z') + g_fGrabOffset[client][2];
	
	TeleportEntity(g_pGrabbedEnt[client], entNewPos, NULL_VECTOR, NULL_VECTOR);
	
	return Plugin_Handled;
}

//============================================================================
//							RELEASE ENTITY COMMAND							//
//============================================================================
public Action Cmd_Release(client, args) {
	if (!IsValidEntity(client) || client < 1 || client > MaxClients || !IsClientInGame(client))
		return Plugin_Handled;
		
	if (g_pGrabbedEnt[client] == -1 || !IsValidEntity(g_pGrabbedEnt[client]))
		return Plugin_Handled;
		
	// Allow near-immediate use of weapon
	SetWeaponDelay(client, 0.2);
	
	// Avoid forced removal of noclip or player stuck
	if (GetEntityMoveType(client) == MOVETYPE_NONE && !g_pWasInNoclip[client])
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
	else if (GetEntityMoveType(client) == MOVETYPE_NOCLIP || g_pWasInNoclip[client])
		SetEntityMoveType(client, MOVETYPE_NOCLIP);
	
	// UNhook client physics
	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	
	// Unfreeze if target was a player and unfreeze if setting is set to 0
	char sClass[64];
	GetEntityClassname(g_pGrabbedEnt[client], sClass, sizeof(sClass)); TrimString(sClass);
	
	if (StrEqual(sClass, "player", false))
		SetEntityMoveType(g_pGrabbedEnt[client], MOVETYPE_WALK);
	else if (g_eReleaseFreeze[client] == false)
		AcceptEntityInput(g_pGrabbedEnt[client], "EnableMotion");
		
	// Restore color and alpha to original prior to grab
	SetEntityRenderColor(g_pGrabbedEnt[client], g_eOriginalColor[client][0], g_eOriginalColor[client][1], g_eOriginalColor[client][2], g_eOriginalColor[client][3]);
	
	// Kill the grab timer and reset control values
	if (g_eGrabTimer[client] != null) {
		KillTimer(g_eGrabTimer[client]);
		g_eGrabTimer[client] = null;
	}
	
	g_pGrabbedEnt[client] = -1;
	g_eRotationAxis[client] = -1;
	g_pInRotationMode[client] = false;
	
	return Plugin_Handled;
}

//============================================================================
//							***		UTILITIES	***							//
//============================================================================
stock float GetEntNewPosition(int client, char axis)
{ 
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		float endPos[3], clientEye[3], clientAngle[3], direction[3];
		GetClientEyePosition(client, clientEye);
		GetClientEyeAngles(client, clientAngle);

		GetAngleVectors(clientAngle, direction, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(direction, g_fGrabDistance[client]);
		AddVectors(clientEye, direction, endPos);

		TR_TraceRayFilter(clientEye, endPos, MASK_SOLID, RayType_EndPoint, TraceRayFilterEnt, client);
		if (TR_DidHit(INVALID_HANDLE))
			TR_GetEndPosition(endPos);

		if      (axis == 'x') return endPos[0]; 
		else if (axis == 'y') return endPos[1];
		else if (axis == 'z') return endPos[2];
	}

	return 0.0;
}
/////
stock float GetInitialRayPosition(int client, char axis)
{ 
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		float endPos[3], clientEye[3], clientAngle[3];
		GetClientEyePosition(client, clientEye);
		GetClientEyeAngles(client, clientAngle);

		TR_TraceRayFilter(clientEye, clientAngle, MASK_SOLID, RayType_Infinite, TraceRayFilterActivator, client);
		if (TR_DidHit(INVALID_HANDLE))
			TR_GetEndPosition(endPos);

		if      (axis == 'x') return endPos[0]; 
		else if (axis == 'y') return endPos[1];
		else if (axis == 'z') return endPos[2];
	}

	return 0.0;
}
/////
stock void SetWeaponDelay(int client, float delay)
{
	if (IsValidEntity(client) && client > 0 && client <= MaxClients && IsClientInGame(client)) {
		int pWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (IsValidEntity(pWeapon) && pWeapon != -1) {
			SetEntPropFloat(pWeapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + delay); 
			SetEntPropFloat(pWeapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + delay); 
		}
	}
}
/////
stock void CreateRing(int client, float ang[3], float pos[3], float diameter, int axis, bool trio)
{
	if (!IsValidEntity(client) || client < 1 || client > MaxClients || !IsClientInGame(client))
		return;
		
	float ringVecs[26][3];
	int ringColor[3][4];

	ringColor[0] = { 255, 0, 0, 255 };
	ringColor[1] = { 0, 255, 0, 255 };
	ringColor[2] = { 0, 0, 255, 255 };
	
	int numSides = (!trio) ? 26 : 17;
	float angIncrement = (!trio) ? 15.0 : 24.0;

	for (int i = 1; i < numSides; i++) {
		float direction[3], endPos[3];
		switch(axis) {
			case 0: GetAngleVectors(ang, direction, NULL_VECTOR, NULL_VECTOR);
			case 1:
			{
				ang[2] = 0.0;
				GetAngleVectors(ang, NULL_VECTOR, direction, NULL_VECTOR);
			}
			case 2: GetAngleVectors(ang, NULL_VECTOR, NULL_VECTOR, direction);
		}
	
		ScaleVector(direction, diameter);
		AddVectors(pos, direction, endPos);

		if (i == 1) ringVecs[0] = endPos;
			
		ringVecs[i] = endPos;
		ang[axis] += angIncrement;
		
		TE_SetupBeamPoints(ringVecs[i-1], ringVecs[i], g_BeamSprite, g_HaloSprite, 0, 15, 0.2, 2.5, 2.5, 1, 0.0, ringColor[axis], 10);
		TE_SendToClient(client, 0.0);
		
		if(trio && i == numSides-1 && axis < 2) {
			i = 0;
			ang[axis] -= angIncrement * (numSides-1);
			axis += 1;
		}
	}
}

//============================================================================
//							***		FILTERS		***							//
//============================================================================
public bool TraceRayFilterEnt(int entity, int mask, any:client)
{
	if (entity == client || entity == g_pGrabbedEnt[client]) 
		return false;
	return true;
}  
/////
public bool TraceRayFilterActivator(int entity, int mask, any:activator)
{
	if (entity == activator)
		return false;
	return true;
}

//============================================================================
//							***		HOOKS		***							//
//============================================================================
public OnPreThink(client) 
{
	if (GetEntityMoveType(client) == MOVETYPE_NOCLIP && GetEntityMoveType(client) != MOVETYPE_NONE)
		g_pWasInNoclip[client] = true;
	else
		g_pWasInNoclip[client] = false;
}