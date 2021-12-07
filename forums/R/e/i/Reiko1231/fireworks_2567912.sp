// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <emitsoundany>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================
#define PLUGIN_VERSION "1.0"
public Plugin:myinfo =
{
	name 			= "[Fireworks] Core",
	author 			= "AlexTheRegent",
	description 	= "",
	version 		= PLUGIN_VERSION,
	url 			= ""
}

// ==============================================================================================================================
// >>> DEFINES
// ==============================================================================================================================
//#pragma newdecls required
#define MPS 		MAXPLAYERS+1
#define PMP 		PLATFORM_MAX_PATH
#define MTF 		MENU_TIME_FOREVER
#define CID(%0) 	GetClientOfUserId(%0)
#define UID(%0) 	GetClientUserId(%0)
#define SZF(%0) 	%0, sizeof(%0)
#define LC(%0) 		for (new %0 = 1; %0 <= MaxClients; ++%0) if ( IsClientInGame(%0) ) 

#define DEBUG
#if defined DEBUG
stock DebugMessage(const String:message[], any:...)
{
	decl String:sMessage[256];
	VFormat(sMessage, sizeof(sMessage), message, 2);
	PrintToServer("[Debug] %s", sMessage);
}
#define DbgMsg(%0); DebugMessage(%0);
#else
#define DbgMsg(%0);
#endif

#define MODEL_INVISIBLE "models/props/cs_italy/orange.mdl"
#define LENGTH_FIREWORK_NAME		64

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================
new Handle:		g_hForward_OnFireworksLoaded;	// forward

new Handle:		g_hTrie_FireworkData;			// name -> firework data

new Handle:		g_hArray_FireworkNames;			// firework names

new bool:		g_bIsLoaded;					// is configs loaded

new 			g_iRoundCounter; 				// do not spawn fireworks from previous round

// ==============================================================================================================================
// >>> LOCAL INCLUDES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> FORWARDS
// ==============================================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bIsLoaded = false;
	RegPluginLibrary("fireworks_core");
	CreateNative("Fireworks_IsFireworksLoaded"	, Native_IsFireworksLoaded);
	CreateNative("Fireworks_IsFireworkExists"	, Native_IsFireworkExists);
	CreateNative("Fireworks_SpawnFirework"		, Native_SpawnFirework);
	CreateNative("Fireworks_GetFireworksNames"	, Native_GetFireworksNames);
	CreateNative("Fireworks_ReloadFireworks"	, Native_ReloadFireworks);
	return APLRes_Success;
}

public OnPluginStart() 
{
	// plugin version
	CreateConVar("sm_fireworks_version", PLUGIN_VERSION, "version of fireworks plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		
	// reload configs
	RegAdminCmd("sm_fireworks_reload", Command_FireworksReload, ADMFLAG_ROOT);
	
	// hook event
	HookEvent("round_start", Ev_RoundStart, EventHookMode_PostNoCopy);
	
	// create load forward
	g_hForward_OnFireworksLoaded = CreateGlobalForward("Fireworks_OnFireworksLoaded", ET_Ignore);
}

public OnAllPluginsLoaded()
{
	// read configs
	ReadFireworks();
}

ReadFireworks()
{
	// clear memory
	if ( g_hArray_FireworkNames != INVALID_HANDLE ) {
		decl Handle:hArray_Rockets, Handle:hTrie_RocketData, String:sFireworkName[LENGTH_FIREWORK_NAME];
		new iLength = GetArraySize(g_hArray_FireworkNames);
		for ( new i = 0; i < iLength; ++i ) {
			GetArrayString(g_hArray_FireworkNames, i, SZF(sFireworkName));
			if ( GetTrieValue(g_hTrie_FireworkData, sFireworkName, hArray_Rockets) ) {
				new iRockets = GetArraySize(hArray_Rockets);
				for ( new j = 0; j < iRockets; ++j ) {
					hTrie_RocketData = GetArrayCell(hArray_Rockets, j);
					CloseHandle(hTrie_RocketData);
				}
			}
		}
		CloseHandle(g_hArray_FireworkNames);
		CloseHandle(g_hTrie_FireworkData);
	}
	
	// loop through files in fireworks directory
	decl String:sPath[PMP];
	BuildPath(Path_SM, SZF(sPath), "configs/fireworks/");
	new Handle:hDirectory = OpenDirectory(sPath);
	if ( hDirectory != INVALID_HANDLE ) {
		g_hTrie_FireworkData = CreateTrie();
		g_hArray_FireworkNames = CreateArray(ByteCountToCells(LENGTH_FIREWORK_NAME));
		
		decl String:sFileName[PMP], String:sFilePath[PMP], FileType:type;
		while ( ReadDirEntry(hDirectory, SZF(sFileName), type) ) {
			if ( type == FileType_File ) {
				FormatEx(SZF(sFilePath), "%s%s", sPath, sFileName);
				// cut extension
				strcopy(sFileName, strlen(sFileName)-3, sFileName);
				ReadFirework(sFilePath, sFileName);
			}
		}
	}
	else {
		LogError("Directory \"%s\" not found", sPath);
		SetFailState("Directory \"%s\" not found", sPath);
	}
		
	// call forward
	Call_StartForward(g_hForward_OnFireworksLoaded);
	Call_Finish();
	
	// configs are loaded
	g_bIsLoaded = true;
}

ReadFirework(const String:sPath[], const String:sName[])
{
	new Handle:hKeyValues = CreateKeyValues("firework");
	if ( !FileToKeyValues(hKeyValues, sPath) ) {
		LogError("File \"%s\" not found", sPath);
		SetFailState("File \"%s\" not found", sPath);
	}
	if ( !KvGotoFirstSubKey(hKeyValues) ) {
		LogError("File \"%s\" empty or broken", sPath);
		SetFailState("File \"%s\" empty or broken", sPath);
	}
	
	decl Handle:hArray_Rockets, Handle:hTrie_RocketData;
	hArray_Rockets = CreateArray();
	do {
		hTrie_RocketData = CreateTrie();
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "box_model");
		KvFloatToTrieValue( hKeyValues, hTrie_RocketData, "box_duration"		, 1.0);
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "box_origin"			, "0.0 0.0 0.0");
		
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "launch_delay"		, "1.0 1.0");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "launch_sound");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "launch_vel_x"		, "0.0 0.0");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "launch_vel_y"		, "0.0 0.0");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "launch_vel_z"		, "100.0 1000.0");
		
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "trail_model");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "trail_particle");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "trail_color");
		KvFloatToTrieValue( hKeyValues, hTrie_RocketData, "trail_duration");
		
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "firework_particle");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "firework_color1");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "firework_color2");
		KvStringToTrieValue(hKeyValues, hTrie_RocketData, "firework_sound");
		KvFloatToTrieValue( hKeyValues, hTrie_RocketData, "firework_duration"	, 1.0);
		
		PushArrayCell(hArray_Rockets, hTrie_RocketData);
	} while ( KvGotoNextKey(hKeyValues) );
	CloseHandle(hKeyValues);
	
	PushArrayString(g_hArray_FireworkNames, sName);
	SetTrieValue(g_hTrie_FireworkData, sName, hArray_Rockets);
}

KvStringToTrieValue(Handle:hKeyValues, Handle:hTrie, String:sKey[], String:sDefaultValue[] = "")
{
	decl String:sBuffer[64];
	KvGetString(hKeyValues, sKey, SZF(sBuffer), sDefaultValue);
	if ( sBuffer[0] != '\0' ) {
		SetTrieString(hTrie, sKey, sBuffer);
	}
}

KvFloatToTrieValue(Handle:hKeyValues, Handle:hTrie, String:sKey[], Float:fDefaultValue = 0.0)
{
	decl Float:fBuffer;
	fBuffer = KvGetFloat(hKeyValues, sKey, fDefaultValue);
	if ( fBuffer != 0.0 ) {
		SetTrieValue(hTrie, sKey, fBuffer);
	}
}

public OnMapStart() 
{
	// add to download list, precache nessesary files
	decl Handle:hFile, String:sPath[PMP], String:sExtenstion[8], String:sLine[PMP];
	BuildPath(Path_SM, SZF(sPath), "configs/fireworks_dlist.txt");
	hFile = OpenFile(sPath, "r");
	while ( !IsEndOfFile(hFile) && ReadFileLine(hFile, sLine, sizeof(sLine)) )
	{
		TrimString(sLine);
		if ( StrContains(sLine, "//") == -1 && strlen(sLine) > 8 ) {
			if ( GetFileExtension(sLine, SZF(sExtenstion)) ) {
				// sound
				if ( StrEqual(sExtenstion, "mp3", false) || StrEqual(sExtenstion, "wav", false) ) {
					// cut 'sound/' prefix
					PrecacheSoundAny(sLine[6], true);
				}
				// model
				else if ( StrEqual(sExtenstion, "mdl", false) ) {
					PrecacheModel(sLine);
				}
				// particle
				else if ( StrEqual(sExtenstion, "pcf", false) ) {
					PrecacheGeneric(sLine, true);
				}
			}
			AddFileToDownloadsTable(sLine);
		}
	}
	CloseHandle(hFile);
	
	// for non existing models
	PrecacheModel(MODEL_INVISIBLE);
}

public OnConfigsExecuted() 
{
	
}

// ==============================================================================================================================
// >>> EVENTS
// ==============================================================================================================================
public Ev_RoundStart(Handle:hEvent, const String:sEvName[], bool:bSilent)
{
	g_iRoundCounter++;
}

// ==============================================================================================================================
// >>> COMMANDS
// ==============================================================================================================================
public Action:Command_FireworksReload(iClient, iArgc)
{
	ReadFireworks();
}

// ==============================================================================================================================
// >>> LOGIC
// ==============================================================================================================================
bool:IsFireworkExists(const String:sFireworkName[])
{
	decl iBuffer;
	return GetTrieValue(g_hTrie_FireworkData, sFireworkName, iBuffer);
} 

SpawnFirework(const String:sFireworkName[], const Float:vCenterOrigin[3], const Float:vDirectionAngles[3])
{
	decl Handle:hArray_Rockets;
	if ( !GetTrieValue(g_hTrie_FireworkData, sFireworkName, hArray_Rockets) ) {
		LogError("Firework \"%s\" not found", sFireworkName);
		return;
	}
	
	decl Handle:hRocketData;
	new iLength = GetArraySize(hArray_Rockets);
	for ( new i = 0; i < iLength; ++i ) {
		hRocketData = GetArrayCell(hArray_Rockets, i);
		PrepareRocket(hRocketData, vCenterOrigin, vDirectionAngles);
	}
}

PrepareRocket(const Handle:hRocketData, const Float:vCenterOrigin[3], const Float:vDirectionAngles[3]) 
{
	decl String:sBuffer[64], Float:vSpawnOrigin[3], Float:vShiftOrigin[3], Float:fDirectionAngle;
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "box_origin", SZF(sBuffer));
	StringToFloatArray(sBuffer, SZF(vShiftOrigin));
	
	// some math, rotate point around axis
	fDirectionAngle = vDirectionAngles[1] * 3.14159/180; 
	vSpawnOrigin[0] = vCenterOrigin[0] + (vShiftOrigin[0] * Cosine(fDirectionAngle) - vShiftOrigin[1] *   Sine(fDirectionAngle));
	vSpawnOrigin[1] = vCenterOrigin[1] + (vShiftOrigin[0] *   Sine(fDirectionAngle) + vShiftOrigin[1] * Cosine(fDirectionAngle));
	vSpawnOrigin[2] = vCenterOrigin[2] + vShiftOrigin[2];
	
	// prepare data for rocket
	new Handle:hDataPack = CreateDataPack();
	WritePackCell(hDataPack, g_iRoundCounter);
	WritePackCell(hDataPack, hRocketData);
	WritePackFloat(hDataPack, vSpawnOrigin[0]);
	WritePackFloat(hDataPack, vSpawnOrigin[1]);
	WritePackFloat(hDataPack, vSpawnOrigin[2]);
	WritePackFloat(hDataPack, fDirectionAngle);
	
	decl Float:vLaunchDelay[2], iCount;
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "launch_delay", SZF(sBuffer));
	iCount = StringToFloatArray2(sBuffer, vLaunchDelay);
	CreateTimer(iCount==1?vLaunchDelay[0]:GetRandomFloat(vLaunchDelay[0], vLaunchDelay[1]), Timer_SpawnRocket, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
	
	// launcher
	decl String:sModel[PMP];
	if ( GetTrieString(hRocketData, "box_model", SZF(sModel)) ) {
		new iLauncher = SpawnPropByOrigin(sModel, "prop_physics_override", vSpawnOrigin);
		SetEntityMoveType(iLauncher, MOVETYPE_NOCLIP);
		SetEntityRenderMode(iLauncher, RENDER_TRANSCOLOR);
		// for debug purposes
		// SetEntityRenderColor(iLauncher, 255, 255, 255, 120);
		
		decl Float:fBuffer;
		if ( GetTrieValue(hRocketData, "box_duration", fBuffer) ) {
			SetEntityLifetime(iLauncher, fBuffer);
		}
	}
}

public Action:Timer_SpawnRocket(Handle:hTimer, any:hDataPack)
{
	ResetPack(hDataPack);
	new iSpawnRound = ReadPackCell(hDataPack);
	if ( iSpawnRound != g_iRoundCounter ) {
		CloseHandle(hDataPack);
		return Plugin_Stop;
	}
	
	decl Handle:hRocketData, Float:vSpawnOrigin[3], Float:fDirectionAngle;
	hRocketData = ReadPackCell(hDataPack);
	vSpawnOrigin[0] = ReadPackFloat(hDataPack);
	vSpawnOrigin[1] = ReadPackFloat(hDataPack);
	vSpawnOrigin[2] = ReadPackFloat(hDataPack);
	fDirectionAngle = ReadPackFloat(hDataPack);
	CloseHandle(hDataPack);
	
	SpawnRocket(hRocketData, vSpawnOrigin, fDirectionAngle);
	return Plugin_Stop;
}

SpawnRocket(const Handle:hRocketData, const Float:vOrigin[3], const Float:vDirectionAngle)
{
	decl String:sBuffer[64], Float:vVelocity[3], Float:vBuffer[2];
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "launch_vel_x", SZF(sBuffer));
	StringToFloatArray(sBuffer, SZF(vBuffer));
	vVelocity[0] = GetRandomFloat(vBuffer[0], vBuffer[1]);
	
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "launch_vel_y", SZF(sBuffer));
	StringToFloatArray(sBuffer, SZF(vBuffer));
	vVelocity[1] = GetRandomFloat(vBuffer[0], vBuffer[1]);
	
	// same math again, rotate point around axis
	vBuffer[0] = vVelocity[0] * Cosine(vDirectionAngle) - vVelocity[1] *   Sine(vDirectionAngle);
	vBuffer[1] = vVelocity[0] *   Sine(vDirectionAngle) + vVelocity[1] * Cosine(vDirectionAngle);
	// update velocity
	vVelocity[0] = vBuffer[0];
	vVelocity[1] = vBuffer[1];
	
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "launch_vel_z", SZF(sBuffer));
	StringToFloatArray(sBuffer, SZF(vBuffer));
	vVelocity[2] = GetRandomFloat(vBuffer[0], vBuffer[1]);
	
	// spawn rocket
	decl String:sModel[PMP], iRocket;
	if ( GetTrieString(hRocketData, "trail_model", SZF(sModel)) ) {
		iRocket = SpawnPropByOrigin(sModel, "smokegrenade_projectile", vOrigin);
	}
	else {
		iRocket = SpawnPropByOrigin(MODEL_INVISIBLE, "smokegrenade_projectile", vOrigin);
		SetEntityModel(iRocket, MODEL_INVISIBLE);
		SetEntityRenderMode(iRocket, RENDER_NONE);
		// SetEntityRenderColor(iRocket, 255, 255, 255, 0);
		// works fine without hiding
		// upd: no, it is not
		// upd2: hiding not working too...
		// SetEntProp(iRocket, Prop_Data, "m_nNextThinkTick", -1);
		// to be sure it wont explode
	}
	// give rocket ability to achieve first cosmic velocity
	SetEntityMoveType(iRocket, MOVETYPE_NOCLIP);
	TeleportEntity(iRocket, NULL_VECTOR, NULL_VECTOR, vVelocity);
	
	decl String:sSound[PMP];
	if ( GetTrieString(hRocketData, "launch_sound", SZF(sSound)) ) {
		EmitSoundToAllAny(sSound, iRocket, SNDCHAN_STATIC);
	}
	
	new Handle:hDataPack = CreateDataPack();
	WritePackCell(hDataPack, EntIndexToEntRef(iRocket));
	WritePackCell(hDataPack, hRocketData);
	
	decl Float:fTrailDuration;
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieValue(hRocketData, "trail_duration", fTrailDuration);
	CreateTimer(fTrailDuration, Timer_ExplodeRocket, hDataPack, TIMER_FLAG_NO_MAPCHANGE);
	
	if ( GetTrieString(hRocketData, "trail_particle", SZF(sModel)) ) {
		new iTrail = CreateParticleByOrigin(sModel, vOrigin);
		if ( GetTrieString(hRocketData, "trail_color", SZF(sBuffer)) ) {
			SetParticleControlPoint(iTrail, 15, sBuffer, fTrailDuration);
		}
		
		if ( DispatchSpawn(iTrail) ) {
			ActivateEntity(iTrail);
			SetEntityLifetime(iTrail, fTrailDuration);
			
			SetVariantString("!activator");
			AcceptEntityInput(iTrail, "SetParent", iRocket);
		}
	}
}

public Action:Timer_ExplodeRocket(Handle:hTimer, any:hDataPack)
{
	ResetPack(hDataPack);
	new iRocket = EntRefToEntIndex(ReadPackCell(hDataPack));
	if ( iRocket == INVALID_ENT_REFERENCE ) {
		CloseHandle(hDataPack);
		return Plugin_Stop;
	}
	
	new Handle:hRocketData = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);
	
	ExplodeRocket(iRocket, hRocketData);
	return Plugin_Stop;
}

ExplodeRocket(const iRocket, const Handle:hRocketData)
{
	decl String:sBuffer[64], Float:vOrigin[3];
	GetEntPropVector(iRocket, Prop_Send, "m_vecOrigin", vOrigin);
	AcceptEntityInput(iRocket, "kill");
	
	decl Float:fFireworkDuration;
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieValue(hRocketData, "firework_duration", fFireworkDuration);
	
	// unsafe, but should be already handled by default value in KvGet*
	GetTrieString(hRocketData, "firework_particle", SZF(sBuffer));
	new iFirework = CreateParticleByOrigin(sBuffer, vOrigin);
	if ( GetTrieString(hRocketData, "firework_color1", SZF(sBuffer)) ) {
		SetParticleControlPoint(iFirework, 15, sBuffer, fFireworkDuration);
	}
	if ( GetTrieString(hRocketData, "firework_color2", SZF(sBuffer)) ) {
		SetParticleControlPoint(iFirework, 16, sBuffer, fFireworkDuration);
	}
	
	DispatchSpawn(iFirework);
	ActivateEntity(iFirework);
	SetEntityLifetime(iFirework, fFireworkDuration);
	
	decl String:sSound[PMP];
	if ( GetTrieString(hRocketData, "firework_sound", SZF(sSound)) ) {
		EmitSoundToAllAny(sSound, SOUND_FROM_PLAYER, SNDCHAN_STATIC);
	}
	
	// finally, we done
}

// ==============================================================================================================================
// >>> FUNCTIONS
// ==============================================================================================================================
SpawnPropByOrigin(const String:sModel[], const String:sClassName[], const Float:vOrigin[3], const Float:vAngles[3]={0.0, 0.0, 0.0})
{
	// create entity
	new iEntity = CreateEntityByName(sClassName);
	if ( IsValidEdict(iEntity) ) {
		// set entity origin
		DispatchKeyValueVector(iEntity, "origin", vOrigin);
		// set entity properties
		DispatchKeyValueVector(iEntity, "angles", vAngles);
		// set entity model
		DispatchKeyValue(iEntity, "model", sModel);
		
		// try to spawn
		if ( DispatchSpawn(iEntity) ) {
			// return entity index
			return iEntity;
		}
		else {
			LogError("Can't dispatch %s", sClassName);
		}
	}
	else {
		LogError("Can't create %s", sClassName);
	}
	
	// no entity created or spawned
	return -1;
}

SetEntityLifetime(iEntity, Float:fLifetime)
{
	decl String:sOutput[64];
	FormatEx(sOutput, sizeof(sOutput), "OnUser1 !self:kill::%f:1", fLifetime);
	SetVariantString(sOutput);
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser1");
}

CreateParticleByOrigin(const String:sEffectName[], const Float:vOrigin[3])
{
	// create entity
	new iEntity = CreateEntityByName("info_particle_system");
	// check for successfull creation
	if ( IsValidEdict(iEntity) ) {
		// set particle origin
		DispatchKeyValueVector(iEntity, "origin", vOrigin);
		// set particle properties
		DispatchKeyValue(iEntity, "effect_name", sEffectName);
		DispatchKeyValue(iEntity, "start_active", "1");
		
		// to set control points entity must be dispatched
		// and activated after control points 
		return iEntity;
	}
	else {
		LogError("Can't create info_particle_system");
	}
	
	// no entity created or spawned
	return -1;
}

SetParticleControlPoint(const iParticle, const iControlPointNumber, const String:sValue[], const Float:fLifetime)
{
	new iControlPoint = CreateEntityByName("info_particle_system");
	
	decl String:sTargetName[64], String:sControlPoint[16];
	FormatEx(SZF(sTargetName), "firework_cp_%d", iControlPoint);
	FormatEx(SZF(sControlPoint), "cpoint%d", iControlPointNumber);
	
	DispatchKeyValue(iControlPoint, "origin", sValue);
	DispatchKeyValue(iControlPoint, "targetname", sTargetName);
	DispatchKeyValue(iParticle, sControlPoint, sTargetName);
	
	SetEntityLifetime(iControlPoint, fLifetime);
}

bool:GetFileExtension(const String:sFilePath[], String:sExtension[], iMaxLength) 
{
	new iLength = strlen(sFilePath);
	for ( new i = iLength-1; i >= 0; --i ) {
		if ( sFilePath[i] == '.' ) {
			strcopy(sExtension, iMaxLength, sFilePath[i+1]);
			return true;
		}
	}
	return false;
}

bool:StringToFloatArray(const String:sBuffer[], Float:vVector[], iLength)
{
	// !!! may be not enough some day
	decl String:sParts[8][8];
	if ( ExplodeString(sBuffer, " ", sParts, sizeof(sParts), sizeof(sParts[])) != iLength ) {
		LogError("StringToFloatArray length mismatch: %s, expected length: %d", sBuffer, iLength);
		return false;
	}
	
	for ( new i = 0; i < iLength; ++i ) {
		vVector[i] = StringToFloat(sParts[i]);
	}
	return true;
}

StringToFloatArray2(const String:sBuffer[], Float:vVector[])
{
	// !!! may be not enough some day
	decl String:sParts[8][8], iCount;
	iCount = ExplodeString(sBuffer, " ", sParts, sizeof(sParts), sizeof(sParts[]));
	for ( new i = 0; i < iCount; ++i ) {
		vVector[i] = StringToFloat(sParts[i]);
	}
	
	return iCount;
}

// bool:StringToIntArray(const String:sBuffer[], iVector[], iLength)
// {
	// decl String:sParts[iLength][8];
	// if ( ExplodeString(sBuffer, " ", sParts, sizeof(sParts), sizeof(sParts[])) != iLength ) {
		// LogError("StringToIntArray length mismatch: %s, expected length: %d", sBuffer, iLength);
		// return false;
	// }
	
	// for ( new i = 0; i < iLength; ++i ) {
		// iVector[i] = StringToInt(sParts[i]);
	// }
	// return true;
// }

// ==============================================================================================================================
// >>> NATIVES
// ==============================================================================================================================
public Native_IsFireworksLoaded(Handle:hPlugin, iNumParams)
{
	return _:g_bIsLoaded;
}

public Native_IsFireworkExists(Handle:hPlugin, iNumParams)
{
	decl String:sFireworkName[LENGTH_FIREWORK_NAME];
	GetNativeString(1, SZF(sFireworkName));
	return _:IsFireworkExists(sFireworkName);
}

public Native_SpawnFirework(Handle:hPlugin, iNumParams)
{
	decl String:sFireworkName[LENGTH_FIREWORK_NAME], Float:vOrigin[3], Float:vDirectionAngles[3];
	GetNativeString(1, SZF(sFireworkName));
	GetNativeArray(2, SZF(vOrigin));
	GetNativeArray(3, SZF(vDirectionAngles));
	
	if ( IsFireworkExists(sFireworkName) ) {
		SpawnFirework(sFireworkName, vOrigin, vDirectionAngles);
	}
	else {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid firework name \"%s\"", sFireworkName);
	}
	
	return 0;
}

public Native_GetFireworksNames(Handle:hPlugin, iNumParams)
{
	return _:g_hArray_FireworkNames;
}

public Native_ReloadFireworks(Handle:hPlugin, iNumParams)
{
	ReadFireworks();
	return 0;
}