#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <fix_safedoor_use>

#define PLUGIN_VERSION "1.3"

#define DEBUG 0

public Plugin myinfo =
{
	name = "[L4D2] Fix saferoom door +use",
	author = "glhf3000",
	description = "Fixes annoying +USE bug when there are props/survivors between player and the door",
	version = PLUGIN_VERSION,
	url = ""
}

///////////////////

#define MAX_BUTTONS 25
int g_LastButtons[MAXPLAYERS+1];

///////////////////

enum struct doorEnum {
	int		id;
	float 	origin[3];
	float 	center[3];
	float 	sideMinsCenter[3];
	float 	sideMaxsCenter[3];
	int 	spawnflags;
}

doorEnum doors[2];

///////////////////

enum struct toogleData {
	int		client;
	int 	entity;
}

///////////////////

ConVar	cvDistanceToOpen;
ConVar	cvDistanceToClose;
ConVar	cvWaitForPermissionToWork;

float 	distanceToOpen, distanceToClose;
float 	distanceToOpen2, distanceToClose2;
float 	distanceToTraceToOpen, distanceToTraceToClose;

bool 	waitForPermissionToWork;

bool 	enabled = false;
bool 	lateLoad;

///////////////////

char logFilePath[PLATFORM_MAX_PATH];
char date[16];

public void OnPluginStart()
{
	////////////
	HookEvent("round_start",	Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
	
	////////////
	cvDistanceToOpen 			= CreateConVar("l4d2_fix_safedoor_use_distance_to_open", 					"100", 	"You will be able to OPEN doors from this distance");
	cvDistanceToClose 			= CreateConVar("l4d2_fix_safedoor_use_distance_to_close", 					"115", 	"You will be able to CLOSE doors from this distance");
	cvWaitForPermissionToWork	= CreateConVar("l4d2_fix_safedoor_use_wait_permission_from_other_plugin", 	"0", 	"In case you use unscrambler or door locker, wait for it (to use native)");

	CreateConVar("l4d2_fix_safedoor_use_version", PLUGIN_VERSION, "Saferoom Door Fix Use plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "l4d2_fix_safedoor_use");
	
	////////////
	cvDistanceToOpen.AddChangeHook(ConVarChanged);
	cvDistanceToClose.AddChangeHook(ConVarChanged);
	cvWaitForPermissionToWork.AddChangeHook(ConVarChanged);

	////////////
	setVars();

	if(lateLoad)
	{
		#if DEBUG 
			LogDebug("");
			LogDebug("OnPluginStart> lateLoad: %i", lateLoad);
		#endif
		
		enabled = true;

		findDoors();
	}
}

void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	setVars();
}

void setVars()
{
	distanceToOpen			= float(cvDistanceToOpen.IntValue);
	distanceToClose			= float(cvDistanceToClose.IntValue);
	
	distanceToOpen2 		= distanceToOpen*distanceToOpen;
	distanceToClose2 		= distanceToClose*distanceToClose;
	
	distanceToTraceToOpen	= distanceToOpen*2;
	distanceToTraceToClose	= distanceToClose*2;
	
	waitForPermissionToWork	= cvWaitForPermissionToWork.BoolValue;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG 
		LogDebug("");
		LogDebug("Event_RoundStart> ");
	#endif
			
	findDoors();
	
	enabled = !waitForPermissionToWork;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	enabled = false;
}

// start here
void findDoors()
{
	doors[0].id = -1;
	doors[1].id = -1;
	
	int entDoorFirst = L4D_GetCheckpointFirst();
	int entDoorLast = L4D_GetCheckpointLast();
	
	if(entDoorFirst > 0) 
	{
		fillDoorInfo(entDoorFirst, doors[0]);
		
		HookSingleEntityOutput(entDoorFirst, "OnOpen", OnOpen);
	}
	
	if(entDoorLast > 0) 
	{
		fillDoorInfo(entDoorLast, doors[1]);
		
		HookSingleEntityOutput(entDoorLast, "OnOpen", OnOpen);
		HookSingleEntityOutput(entDoorLast, "OnClose", OnClose);
	}
	
	#if DEBUG 
		LogDebug("findDoors> %i / %i", doors[0].id, doors[1].id); 
	#endif
}

bool fillDoorInfo(int entity, doorEnum door)
{
	float origin[3], mins[3], maxs[3], angles[3];
	float center[3], sideMinsCenter[3], sideMaxsCenter[3];
	float centerRot[3], sideMinsCenterRot[3], sideMaxsCenterRot[3];

	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
	
	door.spawnflags = GetEntProp(entity, Prop_Send, "m_spawnflags");

	//////////////////////////////////	
	center[0] = (mins[0] + maxs[0])/2.0;
	center[1] = (mins[1] + maxs[1])/2.0;
	center[2] = (mins[2] + maxs[2])/2.0;
		
	sideMinsCenter[0] = center[0];
	sideMinsCenter[1] = mins  [1];
	sideMinsCenter[2] = center[2];
		
	sideMaxsCenter[0] = center[0];
	sideMaxsCenter[1] = maxs  [1];
	sideMaxsCenter[2] = center[2];
	
	//////////////////////////////////
	rotateVector(center, angles, centerRot);
	rotateVector(sideMinsCenter, angles, sideMinsCenterRot);
	rotateVector(sideMaxsCenter, angles, sideMaxsCenterRot);
	
	//////////////////////////////////
	AddVectors(centerRot, origin, door.center);
	AddVectors(sideMinsCenterRot, origin, door.sideMinsCenter);
	AddVectors(sideMaxsCenterRot, origin, door.sideMaxsCenter);

	//////////////////////////////////
	door.id = entity;
	door.origin = origin;
	
	return true;
}

public void OnUsePress(int client)
{
	float origin[3];
	int state;
	
	float distToCompareTo2, distToTrace;

	GetClientEyePosition(client, origin);
	
	for(int i = 1; i >= 0; i--)
	{
		if(doors[i].id <= 0) continue;
		
		#if DEBUG 
			LogDebug("");
		#endif
		
		// last door on c10m3 or elsewhere
		if(i == 1 && doors[i].spawnflags & DOOR_FLAG_STARTS_LOCKED)
		{
			#if DEBUG 
				LogDebug("OnUsePress> door[%i] has DOOR_FLAG_STARTS_LOCKED set, skip", i);
			#endif
			
			continue;
		}
				
		state = GetEntProp(doors[i].id, Prop_Send, "m_eDoorState");
		
		#if DEBUG 
			LogDebug("OnUsePress> state: %i", state);
		#endif
		
		if(state == DOOR_STATE_OPENED)
		{
			distToCompareTo2 = distanceToClose2;	// square
			
			distToTrace = distanceToTraceToClose;	// hit can be < center/mins/maxs
		} 
		else if (state == DOOR_STATE_CLOSED) 
		{
			distToCompareTo2 = distanceToOpen2;		// square
			
			distToTrace = distanceToTraceToOpen;	// hit can be < center/mins/maxs
		} 
		else 
		{
			#if DEBUG 
				LogDebug("OnUsePress> door is opening/closing, ignored");
			#endif
			
			continue; 
		}
		
		#if DEBUG
			float distToCompareTo, distCenter, distMinsSide, distMaxsSide;
			
			if(state == DOOR_STATE_OPENED)
			{
				distToCompareTo = distanceToClose;
			} 
			else if (state == DOOR_STATE_CLOSED) 
			{
				distToCompareTo = distanceToOpen;
			}
			
			distCenter = GetVectorDistance(origin, doors[i].center, false);
			distMinsSide = GetVectorDistance(origin, doors[i].sideMinsCenter, false);
			distMaxsSide = GetVectorDistance(origin, doors[i].sideMaxsCenter, false);
		
			LogDebug("OnUsePress> door - cent/side1/side2 - compareTo: %i - %.1f / %.1f / %.1f - %.1f", doors[i].id, distCenter, distMinsSide, distMaxsSide, distToCompareTo);
		#endif
		
		if(	GetVectorDistance(origin, doors[i].center, true) <= distToCompareTo2 ||				// squares
			GetVectorDistance(origin, doors[i].sideMinsCenter, true) <= distToCompareTo2 ||
			GetVectorDistance(origin, doors[i].sideMaxsCenter, true) <= distToCompareTo2)
		{
			traceDoor(client, origin, distToTrace);
			
			#if DEBUG 
				LogDebug("OnUsePress> close to door %i", doors[i].id);
			#endif
			
			continue; 
		}
	}
}

void traceDoor(int client, float origin[3], float distToTrace)
{
	float angles[3], endPoint[3];
	float fwd[3], right[3], up[3];

	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);

	GetAngleVectors(angles, fwd, right, up);
	
	for (int i = 0; i <= 2; i++)
	{
		endPoint[i] = origin[i] + (fwd[i] * distToTrace);
	}

	TR_EnumerateEntities(origin, endPoint, PARTITION_SOLID_EDICTS, RayType_EndPoint, enumerateEnts, client);
}

bool enumerateEnts(int entity, int client)
{
	char classname[64];
	if(!IsValidEntity(entity)) return true;
	
	GetEntPropString(entity, Prop_Data, "m_iClassname", classname, sizeof(classname));

	#if DEBUG 
		LogDebug("enumerate> %i - %s", entity, classname);
	#endif
	
	/////
	if(!StrEqual(classname, "prop_door_rotating_checkpoint")) 
		return true;
	
	/////
	DataPack hPack = new DataPack();
    hPack.WriteCell(client);
    hPack.WriteCell(entity);
	
	RequestFrame(toggleDoor, hPack);
	
	#if DEBUG 
		LogDebug("enumerateEnts> +");
	#endif
	
	return false;
}

void toggleDoor(Handle hDataPack)
{
	DataPack hPack = view_as<DataPack>(hDataPack);
    hPack.Reset(); 
	
    int client = hPack.ReadCell();
    int entity = hPack.ReadCell();
	
	delete hPack;
	
	int state = GetEntProp(entity, Prop_Send, "m_eDoorState");
	int spawnflags = GetEntProp(entity, Prop_Send, "m_spawnflags");

	if(spawnflags & DOOR_FLAG_IGNORE_USE)
	{
		#if DEBUG 
			LogDebug("toggleDoor> door: %i, spawnflags: %i, skip as DOOR_FLAG_IGNORE_USE is set", entity, spawnflags);
		#endif
		
		return;
	}
	
	#if DEBUG 
		LogDebug("toggleDoor> state: %i", state);
	#endif
	
	if(state == DOOR_STATE_OPENING_IN_PROGRESS || state == DOOR_STATE_CLOSING_IN_PROGRESS)
	{
		#if DEBUG 
			LogDebug("toggleDoor> opening/closing already, skip");
		#endif
		
		return;
	}
	
	SetEntProp(entity, Prop_Send, "m_bLocked", 0);
	
	// SetEntProp(entity, Prop_Data, "m_eOpenDirection", 0); // ???
	// AcceptEntityInput(entity, "Toggle", client, client);	// direction?

	if(state == DOOR_STATE_CLOSED)
		AcceptEntityInput(entity, "PlayerOpen", client, client);
	else 
		AcceptEntityInput(entity, "PlayerClose", client, client);
	
	sendUseEvent(client, entity);

	#if DEBUG 
		LogDebug("toggleDoor> +");
	#endif
	
	return;
}

void sendUseEvent(int client, int target)
{
    Event event = CreateEvent("player_use");
    if (event == null)
    {
        return;
    }
	
	event.SetInt("userid", GetClientUserId(client));
    event.SetInt("targetid", target);
    event.Fire();
	
	#if DEBUG 
		LogDebug("sendUseEvent> client %i -> door %i", client, target);
	#endif
}

void OnClose(const char[] output, int entity, int activator, float delay)
{
	RequestFrame(trackDoor, 1);
			
	#if DEBUG 
		LogDebug("OnClose> state: %i", GetEntProp(entity, Prop_Send, "m_eDoorState"));
	#endif
}

void OnOpen(const char[] output, int entity, int activator, float delay)
{
	for(int i = 1; i >= 0; i--)
	{
		if(doors[i].id == entity)
		{
			if(i == 1)
			{
				RequestFrame(trackDoor, i);
			}
			else
			{
				UnhookSingleEntityOutput(entity, "OnOpen", OnOpen);
				doors[i].id = -1;
			}
			
			#if DEBUG 
				LogDebug("OnOpen> state: %i", GetEntProp(entity, Prop_Send, "m_eDoorState"));
			#endif
			
			break;
		}
	}
}

void trackDoor(int doorIndex)
{	
	int state = GetEntProp(doors[doorIndex].id, Prop_Send, "m_eDoorState");
	
	if(state == DOOR_STATE_OPENING_IN_PROGRESS || state == DOOR_STATE_CLOSING_IN_PROGRESS)
	{
		RequestFrame(trackDoor, doorIndex);
		
		#if DEBUG 
			LogDebug("trackDoor> %i - %i", doors[doorIndex].id, state);
		#endif
	} 
	else 
	{
		fillDoorInfo(doors[doorIndex].id, doors[doorIndex]);
	}
}

void rotateVector(float vec[3], float angles[3], float result[3])
{
	// angles.x = impulse.y;
	// angles.y = impulse.z;
	// angles.z = impulse.x;
	// int x = 0;
	// int y = 1;
	// int z = 2; 
	// ->
	int x = 2;
	int y = 0;
	int z = 1;

	if(angles[x] != 0.0)
	{
		// x'=x;
		// y':=y*cos(L)+z*sin(L) ;
		// z':=-y*sin(L)+z*cos(L) ;
		
		result[0] = vec[0];
		result[1] = vec[1] * Cosine(DegToRad(angles[x])) + vec[2] * Sine(DegToRad(angles[x]));
		result[2] = -vec[1] * Sine(DegToRad(angles[x])) + vec[2] * Cosine(DegToRad(angles[x]));
	}
	
	if(angles[y] != 0.0)
	{
		// x'=x*cos(L)+z*sin(L);
		// y'=y;
		// z'=-x*sin(L)+z*cos(L);
		result[0] = vec[0] * Cosine(DegToRad(angles[y])) + vec[2] * Sine(DegToRad(angles[y]));
		result[1] = vec[1];
		result[2] = -vec[0] * Sine(DegToRad(angles[y])) + vec[2] * Cosine(DegToRad(angles[y]));
	}
	
	if(angles[z] != 0.0)
	{
		// x'=x*cos(L)-y*sin(L);
		// y'=-x*sin(L)+y*cos(L);
		// z'=z;
		
		result[0] = vec[0] * Cosine(DegToRad(angles[z])) - vec[1] * Sine(DegToRad(angles[z]));
		result[1] = -vec[0] * Sine(DegToRad(angles[z])) + vec[1] * Cosine(DegToRad(angles[z]));
		result[2] = vec[2];
	}
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if(client < 1 || client > MaxClients) return;
	if(!enabled || IsFakeClient(client) || GetClientTeam(client) != 2) return;
	
    for (int i = 0; i < MAX_BUTTONS; i++)
    {
        int button = (1 << i);
        
        if ((buttons & button))
        {
            if (!(g_LastButtons[client] & button) && (button & IN_USE))
            {
                OnUsePress(client);
            }
        }
    }
    
    g_LastButtons[client] = buttons;
}

public void OnClientDisconnect_Post(int client)
{
    g_LastButtons[client] = 0;
}

public void Native_FixSafedoorUseEnable(Handle plugin, int numParams)
{
	bool value = true;
	
	if(numParams > 0)
		value = GetNativeCell(1);
	
	enabled = value;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("l4d2_fix_safedoor_use");
	CreateNative("FixSafedoorUseEnable", Native_FixSafedoorUseEnable);
	
	lateLoad = late;
	
	FormatTime(date, sizeof(date), "%Y%m%d", GetTime());
	BuildPath(Path_SM, logFilePath, sizeof(logFilePath), "logs/fix_safedoor_use_%s.log", date);
	
	return APLRes_Success;
}


#if DEBUG
	void LogDebug(const char[] szFormat, any ...)
	{
		int iLen = strlen(szFormat) + 255; 
		char[] szBuffer = new char[iLen];
		VFormat(szBuffer, iLen, szFormat, 2);
			
		LogToFile(logFilePath, "[%i] %s", GetGameTickCount(), szBuffer);
			
		// PrintToServer(szBuffer);
	}
#endif