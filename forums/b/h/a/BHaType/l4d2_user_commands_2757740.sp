#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#include <dhooks>

#undef REQUIRE_PLUGIN
#include <smac>

#pragma newdecls required

#define IsFinite(%0) ((%0 & view_as<float>(0x7F800000)) != view_as<float>(0x7F800000))

public Plugin myinfo =
{
    name = "[L4D2] Usercommands Check",
    author = "BHaType",
	version = "1.1"
};

enum CUserCmd
{
	command_number = 4,
	tick_count = 8,
	viewangles = 12,
	forwardmove = 24,
	sidemove = 28,
	upmove = 32,
	_buttons = 36
};

methodmap CUserCommand 
{
	public CUserCommand (int command)
	{
		return view_as<CUserCommand>(command);
	}
	
	public int Get (CUserCmd propertie)
	{
		return LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie), NumberType_Int32); 
	}
	
	public void GetVector (CUserCmd propertie, float vVec[3])
	{
		vVec[0] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie), NumberType_Int32)); 
		vVec[1] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie) + view_as<Address>(4), NumberType_Int32)); 
		vVec[2] = view_as<float>(LoadFromAddress(view_as<Address>(this) + view_as<Address>(propertie) + view_as<Address>(8), NumberType_Int32));
	}
	
	public void Set (CUserCmd propertie, any data)
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie), data, NumberType_Int32); 
	}
	
	public void SetVector (CUserCmd propertie, float vVec[3])
	{
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie), view_as<int>(vVec[0]), NumberType_Int32); 
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie + tick_count), view_as<int>(vVec[1]), NumberType_Int32); 
		StoreToAddress(view_as<Address>(this) + view_as<Address>(propertie + viewangles), view_as<int>(vVec[2]), NumberType_Int32); 
	}
}

DynamicHook g_hProcessCommand;

const float g_flMaxEntityEulerAngle = 360000.0;
const float g_flMaxEntityPosCoord = 16384.0;

enum struct CCommandContext
{
	float detection;
	int ignored_commands;
}

CCommandContext gCommandContext[MAXPLAYERS + 1];
int m_nTickBase;

bool g_bSMAC;

ConVar sm_usercmd_null_invalid_commands;
int g_iNull;

public void OnLibraryAdded (const char[] name) 
{ 
	if ( strcmp(name, "smac") == 0 ) 
		g_bSMAC = true; 
}

public void OnLibraryRemoved (const char[] name) 
{ 
	if ( strcmp(name, "smac") == 0 ) 
		g_bSMAC = false; 
}

public void OnPluginStart()
{
	m_nTickBase = FindSendPropInfo("CBasePlayer", "m_nTickBase");
	
	sm_usercmd_null_invalid_commands = CreateConVar("sm_usercmd_null_invalid_commands", "0", "Null invalid commands");
	sm_usercmd_null_invalid_commands.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_user_commands");
	
	g_iNull = sm_usercmd_null_invalid_commands.IntValue;
	
	GameData data = new GameData("l4d2_user_commands");

	g_hProcessCommand = DynamicHook.FromConf(data, "ProcessUsercmds");
	
	delete data;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if ( IsClientConnected(i) )
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnConVarChanged (ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iNull = sm_usercmd_null_invalid_commands.IntValue;
}

public void OnClientPutInServer (int client)
{
	if ( !IsFakeClient(client) )
	{
		gCommandContext[client].ignored_commands = RoundToCeil(( 1.0 / GetTickInterval() ) * 2.5);
		g_hProcessCommand.HookEntity(Hook_Pre, client, ProcessUsercmds);
	}
}

public MRESReturn ProcessUsercmds (int client, DHookParam params)
{
	if ( gCommandContext[client].ignored_commands-- > 0 )
		return MRES_Ignored;
		
	//int numcmds = params.Get(2);
	int totalcmds = params.Get(3);
	int dropped_packets = params.Get(4);

	static char reason[96];

	int i;
	for ( i = totalcmds - 1; i >= 0; i-- )
	{
		int numcommand = totalcmds - 1 - i;
		CUserCommand command = CUserCommand(params.Get(1) + numcommand * 88);

		if ( !IsUserCommandValid(client, command, reason, sizeof reason) )
		{
			if ( g_iNull )
			{
				float vAngle[3];
		
				command.SetVector(viewangles, vAngle);
				
				command.Set(forwardmove, 0.0);
				command.Set(sidemove, 0.0);
				command.Set(upmove, 0.0);
				
				command.Set(_buttons, 0);
			}
			
			if ( GetEngineTime() - gCommandContext[client].detection >= 5.0 )
			{
				gCommandContext[client].detection = GetEngineTime();
				
				if ( !g_bSMAC )
				{
					LogMessage("Player %L is suspected in using invalid user commands (reason: %s, dropped packets %i)", client, reason, dropped_packets);
				}
				else
				{
					SMAC_Log("Player %L is suspected in using invalid user commands (reason: %s, dropped packets %i)", client, reason, dropped_packets);
				}
			}
		}
	}
	
	return MRES_Ignored;
}

bool IsUserCommandValid(int client, CUserCommand command, char[] reason, int length)
{
	int nCmdMaxTickDelta = RoundToCeil(( 1.0 / GetTickInterval() ) * 2.5);
	int nMinDelta = Max(0, GetGameTickCount() - nCmdMaxTickDelta);
	int nMaxDelta = GetGameTickCount() + nCmdMaxTickDelta;

	float flForwardmove, flSidemove, flUpmove;
	float vAngles[3];
	int tick;
	
	flForwardmove = view_as<float>(command.Get(forwardmove));
	flSidemove = view_as<float>(command.Get(sidemove));
	flUpmove = view_as<float>(command.Get(upmove));
	
	tick = GetEntData(client, m_nTickBase);
	command.GetVector(viewangles, vAngles);
	
	// PrintToChatAll("%N: tick: %i, foward: %.2f, side: %.2f, up: %.2f, angle: %.2f %.2f %.2f", client, tick, flForwardmove, flSidemove, flUpmove, vAngles[0], vAngles[1], vAngles[2]);

	if (tick < nMinDelta || tick >= nMaxDelta)
	{
		FormatEx(reason, length, "Tickbase out of bounds (min: %i, tick: %i, max: %i)", nMinDelta, tick, nMaxDelta);
		return false;
	}

	if (!(IsFinite(vAngles[0]) && IsFinite(vAngles[1]) && IsFinite(vAngles[2]) && IsEntityQAngleReasonable( vAngles )))
	{
		FormatEx(reason, length, "Invalid view angles (pitch: %.2f, yaw: %.2f, roll: %.2f)", vAngles[0], vAngles[1], vAngles[2]);
		return false;
	}
	
	if (!( IsFinite( flForwardmove ) && IsEntityCoordinateReasonable( flForwardmove ) ))
	{
		FormatEx(reason, length, "Invalid forward move (%.2f)", flForwardmove);
		return false;
	}
	
	if (!( IsFinite( flSidemove ) && IsEntityCoordinateReasonable( flSidemove ) ))
	{
		FormatEx(reason, length, "Invalid side move (%.2f)", flSidemove);
		return false;
	}
	
	if (!( IsFinite( flUpmove ) && IsEntityCoordinateReasonable( flUpmove ) ))
	{
		FormatEx(reason, length, "Invalid up move (%.2f)", flUpmove);
		return false;
	}

	return true;
}

bool IsEntityCoordinateReasonable ( const float c )
{
	float r = g_flMaxEntityPosCoord;
	return c > -r && c < r;
}

bool IsEntityQAngleReasonable( const float q[3] )
{
	float r = g_flMaxEntityEulerAngle;
	return
		q[0] > -r && q[0] < r &&
		q[1] > -r && q[1] < r &&
		q[2] > -r && q[2] < r;
}

int Max (int left, int right) { return left > right ? left : right; }