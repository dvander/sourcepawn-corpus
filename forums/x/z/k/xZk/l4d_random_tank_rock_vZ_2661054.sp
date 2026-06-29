// ====================================================================================================
// File
// ====================================================================================================
//#file "l4d_random_tank_rock.sp"

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME					 "[L4D & L4D2] Random Tank Rock"
#define PLUGIN_AUTHOR				 "Mart"
#define PLUGIN_DESCRIPTION			 "Randomize the rock model thrown by the Tank."
#define PLUGIN_VERSION				 "1.0.Z"
#define PLUGIN_URL					 "https://forums.alliedmods.net/showthread.php?t=315775"

/*
// ====================================================================================================
Change Log:

1.0.0 (23-April-2019)
	- Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
//#pragma newdecls required

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Defines
// ====================================================================================================
#define CVAR_FLAGS					 FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION	 FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define TEAM_INFECTED				 3
#define L4D1_ZOMBIECLASS_TANK		 5
#define L4D2_ZOMBIECLASS_TANK		 8

#define MODEL_CONCRETE_CHUNK		 "models/props_debris/concrete_chunk01a.mdl"
#define MODEL_TREE_TRUNK			 "models/props_foliage/tree_trunk.mdl"

#define MODEL_ROCK0 "models/props_debris/concrete_chunk01a.mdl"
#define MODEL_ROCK1 "models/props_debris/concrete_chunk01c.mdl"
#define MODEL_ROCK2 "models/props_debris/concrete_chunk02a.mdl"
#define MODEL_ROCK3 "models/props_debris/concrete_chunk07a.mdl"
#define MODEL_ROCK4 "models/props_debris/concrete_chunk08a.mdl"
#define MODEL_ROCK5 "models/props_debris/concrete_chunk09a.mdl"
#define MODEL_ROCK6 "models/props_debris/concrete_section64floor001b.mdl.mdl"
									 
#define TYPE_CONCRETE_CHUNK			 (1 << 0) // 1 | 01
#define TYPE_TREE_TRUNK				 (1 << 1) // 2 | 10

#define CONFIG_FILENAME              "l4d_random_tank_rock"
// ====================================================================================================
// Native Cvar Handles
// ====================================================================================================
static Handle hCvar_MPGameMode = INVALID_HANDLE;

// ====================================================================================================
// Plugin Cvar Handles
// ====================================================================================================
static Handle hCvar_Enabled = INVALID_HANDLE;
static Handle hCvar_ModelType = INVALID_HANDLE;
static Handle hCvar_GameModesOn = INVALID_HANDLE;
static Handle hCvar_GameModesOff = INVALID_HANDLE;
static Handle hCvar_GameModesToggle = INVALID_HANDLE;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
static bool	  g_bL4D2Version;
static bool	  bCvar_Enabled;

// ====================================================================================================
// int - Plugin Cvar Variables
// ====================================================================================================
static int	  iCvar_ModelType;
static int	  iCvar_GameModesToggle;
static int	  iCvar_CurrentMode;

// ====================================================================================================
// string - Native Cvar Variables
// ====================================================================================================
static char	  sCvar_MPGameMode[16];

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
static char	  sCvar_GameModesOn[512];
static char	  sCvar_GameModesOff[512];


int EntThrow[MAXPLAYERS+1];
int EntRefThrow[MAXPLAYERS+1];

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();

	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
		return APLRes_SilentFailure;
	}
	
	g_bL4D2Version = (engine == Engine_Left4Dead2);

	return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
	// Register Plugin ConVars
	hCvar_MPGameMode = FindConVar("mp_gamemode"); // Native Game Mode ConVar
	CreateConVar("l4d_random_tank_rock_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
	hCvar_Enabled		  = CreateConVar("l4d_random_tank_rock_enabled",		  "1", "Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
	hCvar_ModelType		  = CreateConVar("l4d_random_tank_rock_model_type",		  "3", "Which models should be applied to the rock thrown by the Tank.\nKnown values: 1 = Only Rock, 2 = Only Trunk, 3 = Rock [50% chance] or Trunk [50% chance].", CVAR_FLAGS, true, 1.0, true, 3.0);
	hCvar_GameModesOn	  = CreateConVar("l4d_random_tank_rock_gamemodes_on",	  "",  "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
	hCvar_GameModesOff	  = CreateConVar("l4d_random_tank_rock_gamemodes_off",	  "",  "Turn off the plugin in these game modes, separate by commas (no spaces). Empty = none.\nKnown values: coop,realism,versus,survival,scavenge,teamversus,teamscavenge,\nmutation[1-20],community[1-6],gunbrain,l4d1coop,l4d1vs,holdout,dash,shootzones.", CVAR_FLAGS);
	hCvar_GameModesToggle = CreateConVar("l4d_random_tank_rock_gamemodes_toggle", "0", "Turn on the plugin in these game modes.\nKnown values: 0 = all, 1 = coop, 2 = survival, 4 = versus, 8 = scavenge.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for \"coop\" (1) and \"survival\" (2).", CVAR_FLAGS, true, 0.0, true, 15.0);

	// Hook Plugin ConVars Change
	HookConVarChange(hCvar_MPGameMode, Event_ConVarChanged);
	HookConVarChange(hCvar_Enabled, Event_ConVarChanged);
	HookConVarChange(hCvar_ModelType, Event_ConVarChanged);
	HookConVarChange(hCvar_GameModesOn, Event_ConVarChanged);
	HookConVarChange(hCvar_GameModesOff, Event_ConVarChanged);
	HookConVarChange(hCvar_GameModesToggle, Event_ConVarChanged);

	//AutoExecConfig(true, CONFIG_FILENAME);

	// Admin Commands
	RegAdminCmd("sm_l4d_random_tank_rock_print_cvars", AdmCmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
	Precaches();
}

/****************************************************************************************************/

void Precaches()
{
	PrecacheModel(MODEL_CONCRETE_CHUNK, true);
	PrecacheModel(MODEL_TREE_TRUNK, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
	GetCvars();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
	// tested works with bugs...
	/*
	if (StrEqual(classname, "tank_rock", false)){
		SDKHook(entity, SDKHook_SpawnPost, OnSpawn_Rock);
		SDKHook(entity, SDKHook_Think, OnThink_Rock);
		//SDKHook(entity, SDKHook_Touch,OnTouch_Rock);
		//HookSingleEntityOutput(entity, "OnKilled", OnKilled_Rock,true); //testear************
	}
	*/
	//PrintToChatAll("%d ",entity);	
	
	//untested possibly work better
	if (StrEqual(classname, "tank_rock", false))
		RequestFrame(OnTankRockNextFrame, EntIndexToEntRef(entity));
}

public void OnEntityDestroyed(int entity)
{
	if(!IsValidEnt(entity))
		return;
	char classname[64];
	GetEntityClassname(entity, classname, sizeof classname);
	if (StrEqual(classname, "tank_rock", false)){
		int ent = GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
		if(IsValidEnt(entity))
			RemoveParent(ent);
	}
	
}

public void OnKilled_Rock (const char[] output, int caller, int activator, float delay){
	
	
	int entity=caller;
	if(IsValidEntity(entity)){
		int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(IsValidClient(client)){
			if(IsValidEntRef(EntRefThrow[client])){
				int ent=EntRefToEntIndex(EntRefThrow[client]);
				ThrowEntity(caller);
			}
		}
	}
	
}

public void OnSpawn_Rock(int entity){

	if (!bCvar_Enabled)
		return;

	if (!IsAllowedGameMode())
		return;
	
	if (!IsValidEntity(entity))
		return;
		
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	
	if (!IsValidClient(client))
		return;
	
	if (!IsPlayerAlive(client))
		return;

	if (GetClientTeam(client) != TEAM_INFECTED)
		return;

	if (IsPlayerGhost(client))
		return;

	if (GetZombieClass(client) != (g_bL4D2Version ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK))
		return;

	//SetEntProp(entity,Prop_Send,"m_nSolidType",0);
	
	int ent=GetEntSoon(client, 300.0, "prop_physics");
	if(ent>0){
		EntRefThrow[client]=EntIndexToEntRef(ent);
		SetEntProp(ent,Prop_Send,"m_nSolidType",0);
		
		//SetParentAttachment(client,ent,"rhand",true,{100.0,100.0,100.0});
		//SetParentAttachment(client,ent,"rhand");//-------------
		SetParent(ent,entity);
		//PrintToChatAll("z ROCK %d: !",ent);
		return;
	}
	//PrintToChatAll("x ROCK %d: !!!",entity);
	return;

}

public void OnThink_Rock(int entity){
	
	if(GetEntityMoveType(entity) == MOVETYPE_FLYGRAVITY){
	//if(GetEntProp(entity,Prop_Send,"moveparent")<=0){
		//AcceptEntityInput(entity,"KillHierarchy"); //kill effect particle
		
		//ThrowRock(entity);
		ThrowEntity(entity);
	}
	
}



void ThrowEntity(int entity)
{
	if(IsValidEntity(entity))
	{
		
		int client=GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
		if(IsValidClient(client)){
			
			int ent = EntRefToEntIndex(EntRefThrow[client]);
			if(ent>0 && IsValidEntity(ent) && ent!=INVALID_ENT_REFERENCE)
			{
				AcceptEntityInput(entity,"KillHierarchy");
				float speed=GetConVarFloat(FindConVar("z_tank_throw_force"));
				int target=GetLookPlayer(client);
				RemoveParent(ent);
				//SetEntProp(ent,Prop_Send,"m_nSolidType",6); //bug impact rock...
				SetEntityMoveType(ent,MOVETYPE_VPHYSICS);
				SetEntProp(ent,Prop_Send,"m_nSolidType",6);
				if(IsValidClient(target)){
					PushEntity(ent,target,speed);
				}
				EntRefThrow[client]=0;
			}
		}
	}
}

void ThrowRock(int entity)
{
	float velocity[3];
	//new ent=rock[thetank];
	if(IsValidEntity(entity))
	{		
		PrintToChatAll("rock?!");
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
		new Float:flVector=GetVectorLength(velocity);
		if (flVector > 500.0)
		{
			new Float:pos[3];// cambiar pos del other proyectil
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			
			int client=GetEntPropEnt(entity,Prop_Data,"m_hOwnerEntity");
			AcceptEntityInput(entity,"KillHierarchy");
			
			//new si=GetEntPropEnt(client,Prop_Data,"m_hMoveChild");
			
			int ent = EntRefToEntIndex(EntRefThrow[client]);
			PrintToChatAll("%d Rock!!!",ent);
			if(ent>0 && IsValidEntity(ent) && ent!=INVALID_ENT_REFERENCE)
			{
				//RemoveEdict(ent);
				RemoveParent(ent);
				SetEntProp(ent,Prop_Send,"m_nSolidType",6);
				NormalizeVector(velocity, velocity);
				new Float: speed=GetConVarFloat(FindConVar("z_tank_throw_force"));
				ScaleVector(velocity, speed*1.4);
				SetEntityMoveType(ent,MOVETYPE_VPHYSICS);//bug fly lauch
				TeleportEntity(ent, pos, NULL_VECTOR, velocity);	
				
				//ShowParticle(pos, "electrical_arc_01_system", 3.0);
				PrintToChatAll("launch Rock!!!!");
				EntRefThrow[client]=0;
				//SDKUnhook(entity, SDKHook_ThinkPost,OnThink_Rock);
			}
				
			
		}	
		 
	}
	return;
}

/****************************************************************************************************/

void OnTankRockNextFrame(int iEntRef)
{
	if (!bCvar_Enabled)
		return;

	if (!IsAllowedGameMode())
		return;
	
	if (!IsValidEntRef(iEntRef))
		return;
	
	int entity = EntRefToEntIndex(iEntRef);
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if (!IsValidClient(client))
		return;
	
	if (!IsPlayerAlive(client))
		return;

	if (GetClientTeam(client) != TEAM_INFECTED)
		return;

	if (IsPlayerGhost(client))
		return;

	if (GetZombieClass(client) != (g_bL4D2Version ? L4D2_ZOMBIECLASS_TANK : L4D1_ZOMBIECLASS_TANK))
		return;
	//-
	int ent=GetEntSoon(client, 500.0, "prop_physics");
	// stuck push objtects prop dinamics? 
	//if(ent<=0)
		// ent=GetEntSoon(client,500.0,"prop_dinamic");
	
	if(IsValidEnt(ent)){
		SetParent(ent, entity);
		//PrintToChatAll("Pickup Object? %d:",ent);
		return;
	}

	int iCase;
	if (iCvar_ModelType & TYPE_CONCRETE_CHUNK && iCvar_ModelType & TYPE_TREE_TRUNK)
		iCase = GetRandomInt(0, 10);
	else if (iCvar_ModelType & TYPE_CONCRETE_CHUNK)
		iCase = 1;
	else if (iCvar_ModelType & TYPE_TREE_TRUNK)
		iCase = 2;
	
	switch (iCase)
	{
		case 0: SetEntityModel(entity, MODEL_CONCRETE_CHUNK);
		case 1: SetEntityModel(entity, MODEL_ROCK0);
		case 2: SetEntityModel(entity, MODEL_ROCK1);
		case 3: SetEntityModel(entity, MODEL_ROCK2);
		case 4: SetEntityModel(entity, MODEL_ROCK3);
		case 5: SetEntityModel(entity, MODEL_ROCK4);
		case 6: SetEntityModel(entity, MODEL_ROCK5);
		case 7: SetEntityModel(entity, MODEL_ROCK6);
		default:SetEntityModel(entity, MODEL_TREE_TRUNK);
	}
}

int GetEntSoon(int client, float distance, const char[] classname){
	float pos_client[3];
	float pos_ent[3];
	GetClientEyePosition(client, pos_client);
	//GetClientAbsOrigin(client, targetVector1);
	int ent=-1;
	float dis_min = 0.0;
	int entity;
	while ((ent = FindEntityByClassname(ent,  classname )) > 0)
	{
		if (IsValidEnt(ent))
		{
			GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", pos_ent);
			float dis = GetVectorDistance(pos_client, pos_ent);
			if(dis < distance && (dis < dis_min || dis_min == 0.0))
			{
				dis_min = dis;
				entity=ent;
			}
		}
	}
	return entity;
}

//https://forums.alliedmods.net/showthread.php?t=303286
stock PushEntity(int entity, int client, float strength=10.0)
{
	if(IsValidEntity(entity))
	{
		// get positions of both entity and client 
		float pos1[3], pos2[3];
		GetClientAbsOrigin(client, pos1);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos2);

		// create push velocity
		float vPush[3];
		//MakeVectorFromPoints(pos1, pos2, vPush);
		MakeVectorFromPoints(pos2, pos1, vPush);
		NormalizeVector(vPush, vPush);
		ScaleVector(vPush, strength);

		// push entity
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vPush);
	}
}
//https://forums.alliedmods.net/showthread.php?p=2429846
stock Entity_PushForce(iEntity, Float:fForce, Float:fAngles[3], Float:fMax=0.0, bool:bAdd=false)
{
	static Float:fVelocity[3];
	
	fVelocity[0] = fForce * Cosine(DegToRad(fAngles[1])) * Cosine(DegToRad(fAngles[0]));
	fVelocity[1] = fForce * Sine(DegToRad(fAngles[1])) * Cosine(DegToRad(fAngles[0]));
	fVelocity[2] = fForce * Sine(DegToRad(fAngles[0]));
	
	GetAngleVectors(fAngles, fVelocity, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(fVelocity, fVelocity);
	ScaleVector(fVelocity, fForce);
	
	if(bAdd) {
		static Float:fMainVelocity[3];
		GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fMainVelocity);
		
		fVelocity[0] += fMainVelocity[0];
		fVelocity[1] += fMainVelocity[1];
		fVelocity[2] += fMainVelocity[2];
	}
	
	if(fMax > 0.0) {
		fVelocity[0] = ((fVelocity[0] > fMax) ? fMax : fVelocity[0]);
		fVelocity[1] = ((fVelocity[1] > fMax) ? fMax : fVelocity[1]);
		fVelocity[2] = ((fVelocity[2] > fMax) ? fMax : fVelocity[2]);
	}
	
	TeleportEntity(iEntity, NULL_VECTOR, NULL_VECTOR, fVelocity);
}  
//https://forums.alliedmods.net/showthread.php?t=261708
stock void SetParent(int child, int parent)
{
	float vPos[3];
	GetEntPropVector(parent, Prop_Data, "m_vecAbsOrigin", vPos);
	TeleportEntity(child, vPos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(child, "SetParent", parent, child);
	//TeleportEntity(child, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR); // BUG POS on Parented...
}

// player "eyes" "righteye" "lefteye" "partyhat" "head" "flag"
// weapon "muzzle" "eject_brass"
stock SetParentAttachment(iParent, iChild, const String:szAttachment[] = "", Float:vOffsets[3] = {0.0,0.0,0.0})
{
	SetVariantString("!activator");
	AcceptEntityInput(iChild, "SetParent", iParent, iChild);

	if (szAttachment[0] != '\0') // Use at least a 0.01 second delay between SetParent and SetParentAttachment inputs.
	{
		SetVariantString(szAttachment); // "head"

		if (!AreVectorsEqual(vOffsets, Float:{0.0,0.0,0.0})) // NULL_VECTOR
		{
			decl Float:vPos[3];
			GetEntPropVector(iParent, Prop_Send, "m_vecOrigin", vPos);
			AddVectors(vPos, vOffsets, vPos);
			TeleportEntity(iChild, vPos, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(iChild, "SetParentAttachmentMaintainOffset", iParent, iChild);
		}
		else
		{
			AcceptEntityInput(iChild, "SetParentAttachment", iParent, iChild);
		}
	}
}

stock bool:AreVectorsEqual(Float:vVec1[3], Float:vVec2[3])
{
	return (vVec1[0] == vVec2[0] && vVec1[1] == vVec2[1] && vVec1[2] == vVec2[2]);
}  

//https://forums.alliedmods.net/showthread.php?p=761706
stock void RemoveParent(int entity){
	
	if(IsValidEntity(entity)){
		
		float origin[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
		AcceptEntityInput(entity, "ClearParent");
		TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
	}
}

// ====================================================================================================
// ConVars
// ====================================================================================================
void Event_ConVarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
	GetConVarString(hCvar_MPGameMode, sCvar_MPGameMode, sizeof(sCvar_MPGameMode));
	TrimString(sCvar_MPGameMode);
	bCvar_Enabled = GetConVarBool(hCvar_Enabled);
	iCvar_ModelType = GetConVarInt(hCvar_ModelType);
	GetConVarString(hCvar_GameModesOn, sCvar_GameModesOn, sizeof(sCvar_GameModesOn));
	TrimString(sCvar_GameModesOn);
	GetConVarString(hCvar_GameModesOff, sCvar_GameModesOff, sizeof(sCvar_GameModesOff));
	TrimString(sCvar_GameModesOff);
	iCvar_GameModesToggle = GetConVarInt(hCvar_GameModesToggle);
}

// ====================================================================================================
// Admin Commands - Print to Console
// ====================================================================================================
Action AdmCmdPrintCvars(int client, int args)
{
	PrintToConsole(client, "");
	PrintToConsole(client, "======================================================================");
	PrintToConsole(client, "");
	PrintToConsole(client, "----------------- Plugin Cvars (l4d_random_tank_rock) ----------------");
	PrintToConsole(client, "");
	PrintToConsole(client, "l4d_random_tank_rock_version : %s", PLUGIN_VERSION);
	PrintToConsole(client, "l4d_random_tank_rock_enabled : %b (%s)", bCvar_Enabled, bCvar_Enabled ? "true" : "false");
	PrintToConsole(client, "l4d_random_tank_rock_model_type : %i", iCvar_ModelType);
	PrintToConsole(client, "----------------------------------------------------------------------");
	PrintToConsole(client, "mp_gamemode : %s", sCvar_MPGameMode);
	PrintToConsole(client, "l4d_random_tank_rock_gamemodes_on : %s", sCvar_GameModesOn);
	PrintToConsole(client, "l4d_random_tank_rock_gamemodes_off : %s", sCvar_GameModesOff);
	PrintToConsole(client, "l4d_random_tank_rock_gamemodes_toggle : %d", iCvar_GameModesToggle);
	PrintToConsole(client, "IsAllowedGameMode : %b (%s)", IsAllowedGameMode(), IsAllowedGameMode() ? "true" : "false");
	PrintToConsole(client, "");
	PrintToConsole(client, "======================================================================");
	PrintToConsole(client, "");

	return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if the current game mode is valid to run the plugin.
 *
 * @return				True if game mode is valid, false otherwise.
 */
bool IsAllowedGameMode()
{
	if (hCvar_MPGameMode == null || hCvar_MPGameMode == INVALID_HANDLE)
		return false;

	if (iCvar_GameModesToggle != 0)
	{
		int entity = CreateEntityByName("info_gamemode");
		DispatchSpawn(entity);
		HookSingleEntityOutput(entity, "OnCoop", OnGameMode, true);
		HookSingleEntityOutput(entity, "OnSurvival", OnGameMode, true);
		HookSingleEntityOutput(entity, "OnVersus", OnGameMode, true);
		HookSingleEntityOutput(entity, "OnScavenge", OnGameMode, true);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "PostSpawnActivate");
		AcceptEntityInput(entity, "Kill");

		if (iCvar_CurrentMode == 0)
			return false;

		if (!(iCvar_GameModesToggle & iCvar_CurrentMode))
			return false;
	}

	char sGameModes[512], sGameMode[512];
	strcopy(sGameMode, sizeof(sCvar_MPGameMode), sCvar_MPGameMode);
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	strcopy(sGameModes, sizeof(sCvar_GameModesOn), sCvar_GameModesOn);
	if (!StrEqual(sGameModes, "", false))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	strcopy(sGameModes, sizeof(sCvar_GameModesOff), sCvar_GameModesOff);
	if (!StrEqual(sGameModes, "", false))
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}

/****************************************************************************************************/

/**
 * Sets the running game mode int value.
 *
 * @param output		output.
 * @param caller		caller.
 * @param activator		activator.
 * @param delay			delay.
 * @noreturn
 */
int OnGameMode(const char[] output, int caller, int activator, float delay)
{
	if (StrEqual(output, "OnCoop", false))
		iCvar_CurrentMode = 1;
	else if (StrEqual(output, "OnSurvival", false))
		iCvar_CurrentMode = 2;
	else if (StrEqual(output, "OnVersus", false))
		iCvar_CurrentMode = 4;
	else if (StrEqual(output, "OnScavenge", false))
		iCvar_CurrentMode = 8;
	else
		iCvar_CurrentMode = 0;
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client		Client index.
 * @return				True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Validates if the client is a ghost.
 *
 * @param client		Client index.
 * @return				True if client is a ghost, false otherwise.
 */
bool IsPlayerGhost(int client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}

/****************************************************************************************************/

/**
 * Get the specific L4D2 zombie class id from the client.
 *
 * @return L4D			1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2			1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED

 */
int GetZombieClass(int client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass");
}

/****************************************************************************************************/

/**
 * Validates if is a valid entity reference.
 *
 * @param client		Entity reference.
 * @return				True if entity reference is valid, false otherwise.
 */
bool IsValidEntRef(int iEntRef)
{
	return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

//-
stock int GetLookPlayer(int client){
	return GetEntPropEnt(client,Prop_Send,"m_lookatPlayer");
}

stock bool IsTank(int client)
{
	if(IS_VALID_INFECTED(client) )
	{
		char classname[32];
		GetEntityNetClass(client, classname, sizeof(classname));
		if(StrEqual(classname, "Tank", false))
		{
			return true;
		}
	}
	return false;
}

stock bool IsValidEnt(int entity){
	return (entity > 0 && IsValidEntity(entity) && entity != INVALID_ENT_REFERENCE);
}
