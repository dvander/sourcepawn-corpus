#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Stugger"
#define PLUGIN_VERSION "1.5"

#include <sourcemod>
#include <sdktools>

#define sTag "\x04[STACK]\x01"
#define sError "\x05ERROR\x01"

#define MAX_STACKS 5
#define GHOST_COUNT 6

int g_SelectedPropRef[MAXPLAYERS + 1] = { -1, ... };

int g_StackPropsRefs[MAXPLAYERS + 1][MAX_STACKS];

int g_GhostPropsRefs[MAXPLAYERS + 1][GHOST_COUNT];
int g_SelectedDirection[MAXPLAYERS + 1] =  { -1, ... };

int g_StackCount[MAXPLAYERS + 1] =  { 1, ... };
float g_StackOffset[MAXPLAYERS + 1];

float g_LastButtonPress[MAXPLAYERS + 1];

Handle g_ClientStackTimer[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "PropStack",
	author = PLUGIN_AUTHOR,
	description = "Duplicate and stack up to 5 props in up to 6 different directions at an optional offset and stack count.",
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_stack", Cmd_Stack, 0, "Duplicate and stack the prop you're looking at. Use twice.");
}

public OnMapStart() 
{
	for (int i = 0; i <= MAXPLAYERS; i++) {
		g_SelectedPropRef[i] = -1;
		g_StackCount[i] = 1;
		g_SelectedDirection[i] = -1;
		
		for (int j = 0; j < MAX_STACKS; j++) {
			g_StackPropsRefs[i][j] = -1;
		}
		for (int g = 0; g < GHOST_COUNT; g++) {
			g_GhostPropsRefs[i][g] = -1;
		}
		
		g_ClientStackTimer[i] = null;
	}
}

public OnClientDisconnect(client)
{
	if (IsPlayerStacking(client))
		StackRelease(client, "kill");
		
	g_SelectedPropRef[client] = -1;
	g_StackCount[client] = 1;
	g_SelectedDirection[client] = -1;
	
	for (int j = 0; j < MAX_STACKS; j++) {
		g_StackPropsRefs[client][j] = -1;
	}
	for (int g = 0; g < GHOST_COUNT; g++) {
		g_GhostPropsRefs[client][g] = -1;
	}
	
	g_ClientStackTimer[client] = null;
}
//***************************************************************************************//
//																						 //
//									SM_STACK COMMAND									 //
//																						 //
//***************************************************************************************//
public Action Cmd_Stack(client, args) 
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Handled;
	
	// If already stacking, then release the stacks
	if (IsPlayerStacking(client)) {
		if (g_SelectedDirection[client] < 0 || !IsPlayerAlive(client)) {
			PrintToChat(client, "%s Stack Canceled", sTag);
			StackRelease(client, "kill");
		}
		else
			StackRelease(client, "release");
			
		return Plugin_Handled;
	}
	
	int selectedProp = GetEntityIndexAtRay(client);
	
	if (selectedProp < 0 || !IsValidEntity(selectedProp)) 
		return Plugin_Handled;
	
	// If the entity is a child, it will have a 0 0 0 position, so we won't stack those
	bool hasParent = GetEntPropEnt(selectedProp, Prop_Data, "m_hMoveParent") != -1;
	if (hasParent) {
		PrintToChat(client, "%s %s: Props with parents cannot be stacked!", sTag, sError);
		return Plugin_Handled;
	}
	
	// Store the selected prop
	g_SelectedPropRef[client] = EntIndexToEntRef(selectedProp);
	
	// Get the stack count, if one is supplied
	if(args > 0) { 
		char stackArg[16];
		GetCmdArg(1, stackArg, sizeof(stackArg)); TrimString(stackArg);
		
		for (int i = 0; i < strlen(stackArg); i++) {
			if (!IsCharNumeric(stackArg[i])) {
				PrintToChat(client, "%s %s: Invalid stack count. Only numbers are allowed!", sTag, sError);
				return Plugin_Handled;
			}
		}
		
		if (StringToInt(stackArg) > 5 || StringToInt(stackArg) < 1) {
			PrintToChat(client, "%s %s: You can only stack a maximum of %d props!", sTag, sError, MAX_STACKS);
			return Plugin_Handled;
		}
		
		g_StackCount[client] = StringToInt(stackArg);
	}
	else
		g_StackCount[client] = 1;
	
	// Reset the control variables
	g_StackOffset[client] = 0.0;
	g_SelectedDirection[client] = -1;
	
	// Make sure settings can be changed immediately
	g_LastButtonPress[client] = GetGameTime() - 2.0;
	
	// Disable clients weapon prior to timer
	SetWeaponDelay(client, 1.0);
	
	// Give selected prop a non-ambiguous name to avoid error when parenting ghosts
	char clientAuth[18], selectedPropName[32];
	GetClientAuthId(client, AuthId_Steam3, clientAuth, sizeof(clientAuth));
	Format(selectedPropName, sizeof(selectedPropName), "%s_selectedProp", clientAuth);
	DispatchKeyValue(selectedProp, "targetname", selectedPropName);
	
	// Create the ghost props
	CreateGhosts(client, selectedProp);
	
	// Create the timer
	g_ClientStackTimer[client] = CreateTimer(0.1, Timer_Stacking, client, TIMER_REPEAT);

	return Plugin_Handled;
}
//***************************************************************************************//
//																						 //
//									STACK TIMER											 //
//																						 //
//***************************************************************************************//
public Action Timer_Stacking(Handle timer, any client) 
{ 
	if (!IsValidEntity(client) || client < 1 || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Stop;
	
	if (!IsValidEntRef(g_SelectedPropRef[client])) {
		PrintToChat(client, "%s Stack Canceled", sTag);
		StackRelease(client, "kill");
		return Plugin_Stop;
	}
	
	int selectedProp = EntRefToEntIndex(g_SelectedPropRef[client]);
	
	// Continuously delay use of weapon, as to not fire any bullets when adjusting settings
	SetWeaponDelay(client, 1.0);
	
	// Check to see if client RayPoint is touching a ghost prop, if so, set that side selected
	int selectedGhost = GetEntityIndexAtRay(client);
	if (selectedGhost != -1 && IsValidEntity(selectedGhost) && selectedGhost != selectedProp) {
		for (int i = 0; i < GHOST_COUNT; i++) {
			if (selectedGhost == EntRefToEntIndex(g_GhostPropsRefs[client][i])) {
				g_SelectedDirection[client] = i;
				UpdateStackProps(client);
			}
		}
	}
	
	// Check Client Buttons
	int buttonPress = GetClientButtons(client);
	
	// If RELOAD+ATTACK1 then INCREASE offset by 1.0
	if ((buttonPress & IN_ATTACK) && (buttonPress & IN_RELOAD)) {
		g_StackOffset[client] += 1.0;
		UpdateGhostProps(client);
		UpdateStackProps(client);
	}
	// If RELOAD+ATTACK2 then DECREASE offset by 1.0 (negatives allowed)
	else if ((buttonPress & IN_ATTACK2) && (buttonPress & IN_RELOAD)) {
		g_StackOffset[client] -= 1.0;
		UpdateGhostProps(client);
		UpdateStackProps(client);
	} 
	else if (GetGameTime() - g_LastButtonPress[client] >= 0.25) {
		// If ATTACK1 then increase stack count by 1
		if ((buttonPress & IN_ATTACK) && g_StackCount[client] < MAX_STACKS) {
			g_StackCount[client] += 1;
			g_LastButtonPress[client] = GetGameTime();
			
			PrintCenterText(client, "Stack Count: %d", g_StackCount[client]);
		}
		// If ATTACK2 then reduce stack count by 1
		else if ((buttonPress & IN_ATTACK2) && g_StackCount[client] > -1) {
			g_StackCount[client] -= 1;
			g_LastButtonPress[client] = GetGameTime();
			
			if (g_StackCount[client] == 0) PrintCenterText(client, "Stack Canceled");
			else PrintCenterText(client, "Stack Count: %d", g_StackCount[client]);
		}
	}
	
	// If stack count was decreased to 0, then cancel the stack
	if (g_StackCount[client] <= 0) {
		PrintToChat(client, "%s Stack Canceled", sTag);
		StackRelease(client, "kill");
		return Plugin_Handled;
	}

	// Spawn any missing stacks (from stack count being increased or dupe being deleted)
	for (int i = 0; i < g_StackCount[client]; i++) {
		if(!IsValidEntRef(g_StackPropsRefs[client][i])) {
			CreateStacks(client, selectedProp, 1);
			UpdateStackProps(client);
			break;
		}
	}
	
	// Check to make sure array has no gaps, shift down accordingly
	int temp, count = 0;  
	for (int i = 0; i < MAX_STACKS; i++) { 
		if (IsValidEntRef(g_StackPropsRefs[client][i])) { 
			temp = g_StackPropsRefs[client][count]; 
			g_StackPropsRefs[client][count] = g_StackPropsRefs[client][i]; 
			g_StackPropsRefs[client][i] = temp; 
			count++; 
		} 
	} 
	
	// If count is greater than stack count, then delete the extras (from stack count being decreased)
	if (count > g_StackCount[client]) {
		for (int i = MAX_STACKS-1; i >= 0; i--) {
			if (IsValidEntRef(g_StackPropsRefs[client][i])) {
				DeleteEntity(g_StackPropsRefs[client][i]);
				g_StackPropsRefs[client][i] = -1;
				count--;
			}
			if (count == g_StackCount[client])
				break;
		}
	}
	
	return Plugin_Handled;
}
//***************************************************************************************//
//																						 //
//									STACK RELEASE										 //
//																						 //
//***************************************************************************************//
public Action StackRelease(int client, char action[32]) 
{	
	if (!IsValidEntity(client) || client < 1 || client > MaxClients || !IsClientInGame(client)) 
		return Plugin_Handled;
		
	// Depending on arg, or whether player is colliding, either Kill, Release OR, Restore stack
	bool collision = false;
	
	for (int i = 0; i < MAX_STACKS; i++) {
		if(IsValidEntRef(g_StackPropsRefs[client][i])) {
			if (StrEqual(action, "kill", false)) {
				DeleteEntity(g_StackPropsRefs[client][i]);
				g_StackPropsRefs[client][i] = -1;
			}
			else {
				SetEntProp(g_StackPropsRefs[client][i], Prop_Data, "m_CollisionGroup", 0); //solid	for collision test
				
				// Check to see if possible collision which will cause player stuck
				float mins[3], maxs[3], origin[3];
				GetClientMins(client, mins);
				GetClientMaxs(client, maxs);
				GetClientAbsOrigin(client, origin); 
				
				TR_TraceHullFilter(origin, origin, mins, maxs, MASK_SOLID, TraceHullHitStack, client);
				if(TR_DidHit(INVALID_HANDLE))
					collision = true;	
				}
			}
		}

	// If player is not colliding with stack upon release
	if (!collision) {
		// Allow near-immediate use of weapon
		SetWeaponDelay(client, 0.5);
		
		// Kill the timer
		if (g_ClientStackTimer[client] != null) {
			KillTimer(g_ClientStackTimer[client]);
			g_ClientStackTimer[client] = null;
		}
		
		// Release the stacks
		if (StrEqual(action, "release"))
			PrintToChat(client, "%s Stacked \x05%d\x01 Pro%s", sTag, g_StackCount[client], g_StackCount[client]  > 1 ? "ps" : "p");
		for (int i = 0; i < MAX_STACKS; i++) {
			if(IsValidEntRef(g_StackPropsRefs[client][i])) {
				SetEntityRenderColor(g_StackPropsRefs[client][i], 255, 255, 255, 255); // colored
				SetEntProp(g_StackPropsRefs[client][i], Prop_Data, "m_CollisionGroup", 0); // solid
				g_StackPropsRefs[client][i] = -1;
			}
		}
		
		// Kill the ghost props
		for (int i = 0; i < GHOST_COUNT; i++) {
			if(IsValidEntRef(g_GhostPropsRefs[client][i])) {
				DeleteEntity(g_GhostPropsRefs[client][i]);
				g_GhostPropsRefs[client][i] = -1;
			}
		}
		
		// Give selected prop a name not similar to name while selected
		DispatchKeyValue(g_SelectedPropRef[client], "targetname", "somerandomname");
		
		// Reset variables
		g_SelectedPropRef[client] = -1;
		g_SelectedDirection[client] = -1;
		g_StackOffset[client] = 0.0;
		g_StackCount[client] = 1;
		
		return Plugin_Stop;
	}
	// Otherwise there is collision, remain in stack. Return the stacks nonsolid and semi transparent.
	else {
		PrintToChat(client, "%s %s: You may get stuck if you stack here!", sTag, sError);
		
		for (int i = 0; i < MAX_STACKS; i++) {
			if(IsValidEntRef(g_StackPropsRefs[client][i])) {
				SetEntityRenderColor(g_StackPropsRefs[client][i], 255, 255, 255, 250); // transparent
				SetEntProp(g_StackPropsRefs[client][i], Prop_Data, "m_CollisionGroup", 1); // non solid
			}
		}
	}
	return Plugin_Handled;
}
//***************************************************************************************//
//																						 //
//									UPDATE STACK PROPS									 //
//																						 //
//***************************************************************************************//
stock void UpdateStackProps(int client)
{
	int selectedProp = EntRefToEntIndex(g_SelectedPropRef[client]);
	int direction = g_SelectedDirection[client];
	
	float pos[3], ang[3];
	GetEntPropVector(selectedProp, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(selectedProp, Prop_Send, "m_angRotation", ang);
	
	for (int s = 0; s < g_StackCount[client]; s++) {
		if (IsValidEntRef(g_StackPropsRefs[client][s])) {
			int stackProp = EntRefToEntIndex(g_StackPropsRefs[client][s]);
			
			if (g_SelectedDirection[client] == -1)
				TeleportEntity(stackProp, pos, ang, NULL_VECTOR);
				
			else {
				int axis = RoundToFloor(float(direction) / 2);
				
				float newpos[3];
				newpos[0] = GetPosAtDistance(selectedProp, (g_StackOffset[client]*(s+1))+(GetEntMaxs(selectedProp, axis)*(s+1)), direction, 0);
				newpos[1] = GetPosAtDistance(selectedProp, (g_StackOffset[client]*(s+1))+(GetEntMaxs(selectedProp, axis)*(s+1)), direction, 1);
				newpos[2] = GetPosAtDistance(selectedProp, (g_StackOffset[client]*(s+1))+(GetEntMaxs(selectedProp, axis)*(s+1)), direction, 2);	
				
				TeleportEntity(stackProp, newpos, ang, NULL_VECTOR);
			}	
		}
	}
}
//***************************************************************************************//
//																						 //
//									UPDATE GHOST PROPS									 //
//																						 //
//***************************************************************************************//
stock void UpdateGhostProps(int client)
{
	int selectedProp = EntRefToEntIndex(g_SelectedPropRef[client]);
	
	float ang[3];
	GetEntPropVector(selectedProp, Prop_Send, "m_angRotation", ang);
	
	for (int g = 0; g < GHOST_COUNT; g++) {
		if (IsValidEntRef(g_GhostPropsRefs[client][g])) {
			AcceptEntityInput(g_GhostPropsRefs[client][g], "ClearParent");
			
			int axis = RoundToFloor(float(g) / 2);
 
			float newpos[3];
			newpos[0] = GetPosAtDistance(selectedProp, GetEntMaxs(selectedProp, axis)+g_StackOffset[client], g, 0);
			newpos[1] = GetPosAtDistance(selectedProp, GetEntMaxs(selectedProp, axis)+g_StackOffset[client], g, 1);
			newpos[2] = GetPosAtDistance(selectedProp, GetEntMaxs(selectedProp, axis)+g_StackOffset[client], g, 2);
			
			TeleportEntity(g_GhostPropsRefs[client][g], newpos, ang, NULL_VECTOR);
			
			SetVariantEntity(selectedProp);
			AcceptEntityInput(g_GhostPropsRefs[client][g], "SetParent");
		}
	}
}
//***************************************************************************************//
//																						 //
//									CODE UTILITIES										 //
//																						 //
//***************************************************************************************//
stock void CreateStacks(int client, int entity, int amount)
{
	float pos[3], ang[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
		
	char sModel[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	for (int i = 0; i < amount; i++) {
		int stack = CreateEntityByName("prop_physics_override");
	
		DispatchKeyValue(stack, "model", sModel);
		SetEntProp(stack, Prop_Send, "m_CollisionGroup", 1);
		
		if (DispatchSpawn(stack)) {
			AcceptEntityInput(stack, "DisableMotion");
			SetEntityRenderMode(stack, RENDER_TRANSALPHA);
			SetEntityRenderColor(stack, 255, 255, 255, 250);
			
			for (int j = 0; j < MAX_STACKS; j++) {
				if (!IsValidEntRef(g_StackPropsRefs[client][j])) {
					g_StackPropsRefs[client][j] = EntIndexToEntRef(stack);
					break;
				}
			}
			
			TeleportEntity(stack, pos, ang, NULL_VECTOR);
		}
	}
}
/////
stock void CreateGhosts(int client, int entity)
{
	float ang[3];
	GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);
	
	char sModel[128];
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	
	for (int i = 0; i < GHOST_COUNT; i++) {
		int ghost = CreateEntityByName("prop_physics_override");
	
		DispatchKeyValue(ghost, "model", sModel);
		SetEntProp(ghost, Prop_Send, "m_CollisionGroup", 1);
		
		if (DispatchSpawn(ghost)) {
			AcceptEntityInput(ghost, "DisableMotion");
			SetEntityRenderMode(ghost, RENDER_TRANSALPHA);
			
			SetEntityRenderFx(ghost, RENDERFX_PULSE_FAST);
			SetEntityRenderColor(ghost, 255, 255, 255, 70); 
			g_GhostPropsRefs[client][i] = EntIndexToEntRef(ghost);
			int axis = RoundToFloor(float(i) / 2);

			float newpos[3];
			newpos[0] = GetPosAtDistance(entity, GetEntMaxs(entity, axis), i, 0);
			newpos[1] = GetPosAtDistance(entity, GetEntMaxs(entity, axis), i, 1);
			newpos[2] = GetPosAtDistance(entity, GetEntMaxs(entity, axis), i, 2);
			
			TeleportEntity(ghost, newpos, ang, NULL_VECTOR);
			
			SetVariantEntity(entity);
			AcceptEntityInput(ghost, "SetParent");
		} 
	}
}
/////
stock void DeleteEntity(int entref)
{
	if (IsValidEntRef(entref))
		AcceptEntityInput(entref, "Kill");
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
stock float GetEntMaxs(int entity, int axis)
{
	if (IsValidEntity(entity)) {
		float mins[3], maxs[3];
		GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
		GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
		
		if 		(axis == 0) return maxs[0]*2; 
		else if (axis == 1) return maxs[1]*2;
		else if (axis == 2) return (mins[2] < -1.0) ? maxs[2]*2 : maxs[2];
	}
	return 0.0;
}
/////
stock float GetPosAtDistance(int entity, float distance, int vectordir, int returnaxis)
{ 
	float pos[3], ang[3], direction[3], endpos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);

	int axis = RoundToFloor(float(vectordir) / 2);
		
	if 		(axis == 0) GetAngleVectors(ang, direction, NULL_VECTOR, NULL_VECTOR);
	else if (axis == 1) GetAngleVectors(ang, NULL_VECTOR, direction, NULL_VECTOR);
	else if (axis == 2) GetAngleVectors(ang, NULL_VECTOR, NULL_VECTOR, direction);
	
	if (vectordir != 0 && vectordir % 2 != 0) NegateVector(direction);
		
	ScaleVector(direction, distance);
	AddVectors(pos, direction, endpos);

	return endpos[returnaxis];
}
/////
stock int GetEntityIndexAtRay(int client)
{ 	
	float clientEye[3], clientAngle[3];
	GetClientEyePosition(client, clientEye);
	GetClientEyeAngles(client, clientAngle);
	
	int ent = -1;
	
	TR_TraceRayFilter(clientEye, clientAngle, MASK_SOLID, RayType_Infinite, TraceRayFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE))
		ent = TR_GetEntityIndex();
	
	if (ent > 0 && IsValidEntity(ent)) {
		char sClass[64];
		GetEntityClassname(ent, sClass, sizeof(sClass));
		if ((StrContains(sClass, "prop_physics", false) != -1 || StrContains(sClass, "prop_dynamic", false) != -1))
			return ent;
	}
	return -1;
}
/////
stock bool IsPlayerStacking(int client) 
{
	return (IsValidEntRef(g_SelectedPropRef[client]) && g_ClientStackTimer[client] != null);
}
/////
stock bool IsValidEntRef(int entref) 
{
	return (entref != -1 && IsValidEntity(EntRefToEntIndex(entref)) && EntRefToEntIndex(entref) != INVALID_ENT_REFERENCE);
}
/////
//***************************************************************************************//
//																						 //
//									TRACE FILTERS										 //
//																						 //
//***************************************************************************************//
public bool TraceRayFilterPlayer(int entity, int mask, any client)
{
	return !(entity > 0 && entity <= MaxClients);
}  

public bool TraceHullHitStack(int entity, int mask, any client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsPlayerStacking(client)) {
		for (int i = 0; i < MAX_STACKS; i++) {
			if (entity == EntRefToEntIndex(g_StackPropsRefs[client][i]))
				return true;
		}
	}
	return false;
}