#define PLUGIN_VERSION		"1.2"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooksDetour>

#define DEBUG 0
#define GAMEDATA		"FollowTarget_Detour"
#define FILE_PATH "addons/gLogs/folow_target.log"

public Plugin myinfo =
{
	name = "[L4D2][NIX] FollowTarget_Detour",
	author = "Dragokas & TheTrick",
	description = "Fixing the valve crash with null pointer dereference in CMoveableCamera::FollowTarget",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2725811&postcount=19"
}

Handle hDetour;
Handle hfile;

int g_pEntityList;
int g_camIndex;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) {
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	}
	
	SetupDetour(hGameData);
	
	g_pEntityList = GetEntityListPtr(hGameData);
	delete hGameData;
	
	hfile = OpenFile(FILE_PATH, "a");
	if (hfile == null) {
		SetFailState("No found file %s", FILE_PATH);
	}
}

public void OnPluginEnd()
{
	if (hfile != null) {
		delete hfile;
	}
	hfile = null;
	
	if( !DHookDisableDetour(hDetour, false, FollowTarget) )
		SetFailState("Failed to disable detour \"CMoveableCamera::FollowTarget\".");
}

void SetupDetour(Handle hGameData)
{
	hDetour = DHookCreateFromConf(hGameData, "CMoveableCamera::FollowTarget");
	if( !hDetour )
		SetFailState("Failed to find \"CMoveableCamera::FollowTarget\" signature.");
	if( !DHookEnableDetour(hDetour, false, FollowTarget) )
		SetFailState("Failed to start detour \"CMoveableCamera::FollowTarget\".");
}

int GetEntityListPtr(Handle hGameData)
{
	int pFunc = view_as<int>(GameConfGetAddress(hGameData, "CMoveableCamera::FollowTarget"));
	if( pFunc == 0 ) SetFailState("Failed to find \"CMoveableCamera::FollowTarget\" signature.");

	g_camIndex = GameConfGetOffset(hGameData, "Camera_Index");
	if( g_camIndex == -1 ) SetFailState("Failed to load \"Camera_Index\" value.");
	
	int iOffsetOpcode = GameConfGetOffset(hGameData, "g_pEntityList_Opcode_Offset");
	if( iOffsetOpcode == -1 ) SetFailState("Failed to load \"g_pEntityList_Opcode_Offset\" offset.");
	
	int iRelOffset = GameConfGetOffset(hGameData, "g_pEntityList_Relative_Offset");
	if( iRelOffset == -1 ) SetFailState("Failed to load \"g_pEntityList_Relative_Offset\" offset.");
	
	int iBytesMatch = GameConfGetOffset(hGameData, "g_pEntityList_Bytes");
	if( iBytesMatch == -1 ) SetFailState("Failed to load \"g_pEntityList_Bytes\" offset.");
	
	int iCheck = LoadFromAddress(view_as<Address>(pFunc + iOffsetOpcode), NumberType_Int16);
	if( iCheck != iBytesMatch ) SetFailState("Failed to load, byte mis-match @ %d (0x%04X != 0x%04X)", iOffsetOpcode, iCheck, iBytesMatch);
	
	int iEntityListOffset = iOffsetOpcode + iRelOffset;
	
	int pEntityList = SafeDeref(pFunc + iEntityListOffset);
	if( pEntityList == 0 ) SetFailState("Failed to find \"g_pEntityList\" structure.");

	return SafeDeref(pEntityList);
}

public MRESReturn FollowTarget(int pThis, Handle hReturn, Handle hParams)
{
	if( !CameraHasTarget(pThis) )
	{
		if( pThis && IsValidEntity(pThis) )
		{
			AcceptEntityInput(pThis, "Disable");
		}
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

bool CameraHasTarget(int pCamera) // thanks to @TheTrick for helping with disassembly understanding
{
	/*
		v2 = *(this + 281*4); // dwBitField (LB == entIndex; HB == serial)
		
		if ( v2 != -1 )
		{
			v3 = (char *)g_pEntityList[v2 & 0xFFF]; // entIndex
			
			if ( *(v3 + 2 * 4) == v2 >> 12 ) // if (g_pEntityList[index].Unknown2 == serial)
			{
				v1 = (CBaseEntity *)*(v3 + 1 * 4); // = g_pEntityList[index].Unknown1
			}
		}
	*/
	
	int camAddr, entIndex, serial_cam, serial_cli, cliAddr;
	
	int codeStage = 0;
	
	if (pCamera && IsValidEntity(pCamera) )
	{
		codeStage = 1;
		camAddr = view_as<int>(GetEntityAddress(pCamera));
		
		int bf = SafeDeref( camAddr + g_camIndex*4 ); // bit-field, holding client index + serial
		
		entIndex = bf & 0xFFF;
		serial_cam = bf >> 12;
		
		if( entIndex && IsValidEntity(entIndex) )
		{
			codeStage = 2;
			int pEntityStruct = g_pEntityList + entIndex*16; // array of 16-bytes struct
			
			serial_cli = SafeDeref( pEntityStruct + 2*4 );
			
			if( serial_cli == serial_cam )
			{
				codeStage = 3;
				cliAddr = SafeDeref( pEntityStruct + 1*4 );
				
				if( IsValidClientAddress(cliAddr) )
				{
					//codeStage = 4;
					return true;
				}
			}
		}
	}
	
	Crash_logs("########### CMoveableCamera::FollowTarget server 9 crash is successfully prevented!");
	Crash_logs("########### CMoveableCamera::FollowTarget code stage: %d!", codeStage);
	char entName[128];
	if (pCamera != -1 && IsValidEntity(pCamera)) {
		GetEntityClassname(pCamera, entName, sizeof(entName));
		Crash_logs("########### CMoveableCamera::FollowTarget - index: %d, Name: %s", pCamera, entName);
		GetEntityNetClass(pCamera, entName, sizeof(entName));
		Crash_logs("########### CMoveableCamera::FollowTarget - Netclass name: %s", entName);
	} else {
		Crash_logs("########### CMoveableCamera::FollowTarget - Invalid entity: %d", pCamera);
	}
	
	if (entIndex != -1 && IsValidEntity(entIndex)) {
		GetEntityClassname(entIndex, entName, sizeof(entName));
		Crash_logs("########### EntIndex - index: %d, Name: %s", entIndex, entName);
		GetEntityNetClass(entIndex, entName, sizeof(entName));
		Crash_logs("########### EntIndex- Netclass name: %s", entName);
	} else {
		Crash_logs("########### Invalid entity. EntIndex %d", entIndex);
	}
	
	Crash_logs("########### camAddr = %i", camAddr);
	Crash_logs("########### entIndex = %i", entIndex);
	Crash_logs("########### serial_cam = %i (0x%X)", serial_cam, serial_cam);
	Crash_logs("########### serial_cli = %i (0x%X)", serial_cli, serial_cli);
	Crash_logs("########### cliAddr = %i (0x%X)", cliAddr, cliAddr);
	
	Crash_logs("########### CMoveableCamera::FollowTarget end crash log!");
	Crash_logs("  ");
	return false;
}

int SafeDeref(int Addr)
{
	if( Addr != 0 )
	{
		return LoadFromAddress(view_as<Address>(Addr), NumberType_Int32);
	}
	return 0;
}

bool IsValidClientAddress(int Addr)
{
	if( Addr == 0 )
		return false;

	for( int cli = 1; cli <= MaxClients; cli++ )
	{
		if( IsClientInGame(cli) && GetEntityAddress(cli) == view_as<Address>(Addr) )
		{
			return true;
		}
	}
	return false;
}

void Crash_logs(const char[] Message, any ...) 
{
	char StrFormat[255], cTime[64], CVS_Map[128];
	GetCurrentMap(CVS_Map, sizeof(CVS_Map));
	
	VFormat(StrFormat, sizeof(StrFormat), Message, 2);
	FormatTime(cTime, sizeof(cTime), "%x %X");
	Format(StrFormat, sizeof(StrFormat), "[%s] [%s] %s", cTime, CVS_Map, StrFormat);
	
	WriteFileLine(hfile, StrFormat);
	FlushFile(hfile);
}
