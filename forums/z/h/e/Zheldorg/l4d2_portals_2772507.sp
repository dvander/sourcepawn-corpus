#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION	"1.5.0"

ConVar g_hCvar_PortalMDL;
ConVar g_hCvar_sndPortalGO;
ConVar g_hCvar_sndPortalERROR;
ConVar g_hCvar_sndPortalFX;
ConVar g_hCvar_particle;
ConVar g_hCvar_noBots;
ConVar g_hCvar_noProps;
ConVar g_hCvar_adminOnly;

bool g_noBots;
bool g_noProps;
int g_adminOnly;

char g_PortalMDL		[PLATFORM_MAX_PATH];
char g_sndPortalGO		[PLATFORM_MAX_PATH];
char g_sndPortalERROR	[PLATFORM_MAX_PATH];
char g_sndPortalFX		[PLATFORM_MAX_PATH];
char g_particle			[PLATFORM_MAX_PATH];

Handle g_hPortalTrie = INVALID_HANDLE;
enum {ALL = 0, BR = 1, GP = 2};
enum RGBA {R = 0, G = 1, B = 2, A = 3};
enum PORTDAT {CLIENT = 0, PTCOLOR = 1};
enum PORTCOLOR {BLUE = 0, RED = 1, GREEN = 2, PINK = 3};
PORTCOLOR PORTPAIR[PORTCOLOR] = {RED, BLUE, PINK, GREEN};
static const char g_sPortName[PORTCOLOR][6] = {"Blue", "Red", "Green", "Pink"};
int g_iRGB[PORTCOLOR][RGBA] = {{50,100,250,255},{245,30,10,255}, {10,245,100,255}, {245,35,150,255}};
int g_iClientPortals[MAXPLAYERS+1][PORTCOLOR];

public Plugin myinfo =
{
	name = "Portals",
	author = "FluD (tnx hihi1210),Zheldorg",
	description = "Teleportation device",
	version = PLUGIN_VERSION,
	url = "www.alliedmods.net"
}

public void OnPluginStart()
{
	CreateConVar("sm_portals_version", PLUGIN_VERSION, "Portals Version", FCVAR_NOTIFY);
	
	g_hCvar_particle = 			CreateConVar("sm_portals_particle",		"electrical_arc_01_system", 					"Particle effect",										FCVAR_NOTIFY);
	g_hCvar_PortalMDL =			CreateConVar("sm_portals_model",		"models/props_mall/mall_shopliftscanner.mdl",	"Portal model",											FCVAR_NOTIFY);
					
	g_hCvar_sndPortalGO =		CreateConVar("sm_portals_soundgo",		"weapons/defibrillator/defibrillator_use.wav",	"Sound when someone teleported",						FCVAR_NOTIFY);
	g_hCvar_sndPortalERROR =	CreateConVar("sm_portals_sounderror",	"buttons/button11.wav",							"Sound on error acquired",								FCVAR_NOTIFY);
	g_hCvar_sndPortalFX =		CreateConVar("sm_portals_soundfx",		"ui/pickup_misc42.wav",							"Sound if teleport used",								FCVAR_NOTIFY);

	g_hCvar_noProps =			CreateConVar("sm_portals_noprops",		"0", 											"if 1 = props like gascans pipe bomp cant teleport",	FCVAR_NOTIFY);
	g_hCvar_noBots =			CreateConVar("sm_portals_nobots",		"0",											"0 = bots can use portal, 1 = only players",			FCVAR_NOTIFY);
	g_hCvar_adminOnly =			CreateConVar("sm_portals_admin",		"0",											"0 = players can spawn portal, 1 = only admin players",	FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_p", 		Command_Portal, 							"[SM] info: Spawn Portal or teleport specefic portal, red or blue");
	RegConsoleCmd("sm_pd", 		Command_PortalDelete, 						"[SM] info: Delete all BV portals in map");
	RegAdminCmd("sm_pdall",		Command_PortalDeleteAll,	ADMFLAG_BAN,	"Delete all BV portals in map");
	
	HookEvent("round_end",		Event_RoundEnd,			EventHookMode_PostNoCopy);
	
	g_hCvar_noProps.			AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_noBots.				AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "l4d2_portals");
	GetCvars();
	
	g_hPortalTrie = CreateTrie();
}

//convar hooks
public void ConVarChanged_Cvars(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
}

void GetCvars()
{
	g_adminOnly =	g_hCvar_adminOnly.	IntValue;
	g_noProps =		g_hCvar_noProps.	BoolValue;
	g_noBots =		g_hCvar_noBots.		BoolValue;	
}

public void OnMapStart()
{
	InitPrecache();
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int iClient = 1; iClient <= (MaxClients); iClient++)
	{
		for (PORTCOLOR COLOR = BLUE; COLOR <= PINK; COLOR++)
		{
			g_iClientPortals[iClient][COLOR] = 0;
		}
	}
	ClearTrie(g_hPortalTrie);
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	InitPrecache();
}

public void OnClientPutInServer(int client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) )
	{
		for (PORTCOLOR COLOR = BLUE; COLOR <= PINK; COLOR++)
		{
			g_iClientPortals[client][COLOR] = 0;
		}
	}
}

public void OnClientDisconnect(int client)
{
	ClearPortals(client, ALL);
}

public Action Command_PortalDeleteAll(int client, int args)
{
	for (int iClient = 1; iClient <= (MaxClients); iClient++)
	{
		ClearPortals(iClient, ALL);
	}
	return Plugin_Handled;
}

public Action Command_PortalDelete(int client, int args)
{
	if (g_adminOnly > 0)
	{
		if (!GetAdminFlag(GetUserAdmin(client), Admin_Generic, Access_Effective))
		{
			ReplyToCommand( client, "[SM] Only admin can use this command" );
			return Plugin_Handled;
		}
	}
	if (args == 1)
	{
		//get args
		char ArgString[6]; 
		GetCmdArgString(ArgString, sizeof(ArgString));	
		
		switch(ArgString[0])
		{
			case 'b': ClearPortals(client, BR); // blue-red
			case 'r': ClearPortals(client, BR); // blue-red
			case 'g': ClearPortals(client, GP); // green-pink
			case 'p': ClearPortals(client, GP); // green-pink
		}
		return Plugin_Handled;
	}
	ClearPortals(client, ALL);
	return Plugin_Handled;
}

public void ClearPortals(int client, int mode)
{
	PORTCOLOR MAX;
	PORTCOLOR START;
	switch(mode)
	{
		case ALL:	{START = BLUE;	MAX = PINK;}
		case BR:	{START = BLUE;	MAX = RED;}
		case GP: 	{START = GREEN;	MAX = PINK;}
	}
	for (PORTCOLOR COLOR = START; COLOR <= MAX; COLOR++)
	{
		if (g_iClientPortals[client][COLOR] != 0)
		{
			if (IsValidEdict(g_iClientPortals[client][COLOR]))
			{
				SDKUnhook(g_iClientPortals[client][COLOR], SDKHook_Touch, TouchPortal);
				RemoveEdict(g_iClientPortals[client][COLOR]);
				char portal_key[10];
				FormatEx(portal_key, sizeof(portal_key), "%x", g_iClientPortals[client][COLOR]);
				RemoveFromTrie(g_hPortalTrie, portal_key);
			}
			g_iClientPortals[client][COLOR] = 0;
		}
	}
}

public Action Command_Portal(int client, int args)
{
	if (g_adminOnly > 0 )
	{
		if (!GetAdminFlag(GetUserAdmin(client), Admin_Generic, Access_Effective))
		{
			ReplyToCommand( client, "[SM] Only admin can use this command" );
			return Plugin_Handled;
		}
	}
	
/*	if (GetClientAimTarget(client, false) >= 0)
	{
		PrintToChat(client,"[SM] Bad Portal Position try Other");
		return Plugin_Handled;
	} */
	
	if (args == 1)
	{
		//get args
		char ArgString[6]; 
		GetCmdArgString(ArgString, sizeof(ArgString));	
		
		switch(ArgString[0])
		{
			case 'b': g_iClientPortals[client][BLUE]	= SetupPortalEntity(client, BLUE); // blue
			case 'r': g_iClientPortals[client][RED]		= SetupPortalEntity(client, RED);  // red
			case 'g': g_iClientPortals[client][GREEN]	= SetupPortalEntity(client, GREE); // green
			case 'p': g_iClientPortals[client][PINK]	= SetupPortalEntity(client, PINK); // pink
		}
		return Plugin_Handled;
	}
	if (g_iClientPortals[client][BLUE] == 0 && g_iClientPortals[client][RED] == 0)
	{
		g_iClientPortals[client][BLUE] = SetupPortalEntity(client, BLUE);
		return Plugin_Handled;
	}
	else if (g_iClientPortals[client][BLUE] != 0 && g_iClientPortals[client][RED] == 0)
	{
		g_iClientPortals[client][RED] = SetupPortalEntity(client, RED);
		return Plugin_Handled;
	}
	else ClearPortals(client, BR); //if Red and blue create so need to delete it
	return Plugin_Handled;
}



public int SetupPortalEntity(int client, PORTCOLOR COLOR, MODE mode)
{
	float ClientOrigin[3];
	float EyeAngles[3];
	float PortalOrigin[3];
	float PortalAngle[3];
	
	GetCollisionPoint(client, ClientOrigin);
	GetClientEyeAngles(client, EyeAngles);
	
	//Math
	PortalOrigin[0] = ClientOrigin[0];
	PortalOrigin[1] = ClientOrigin[1];
	PortalOrigin[2] = ClientOrigin[2];

	PortalAngle[0] = NULL_VECTOR[0];
	PortalAngle[1] = (EyeAngles[1] + 180);
	PortalAngle[2] = NULL_VECTOR[2];
	// just teleports if already exists
	if (g_iClientPortals[client][COLOR]!=0 && IsValidEntity(g_iClientPortals[client][COLOR]))
	{
		TeleportEntity(g_iClientPortals[client][COLOR], PortalOrigin, PortalAngle, PortalOrigin);
		PrintToChat(client,"Teleport %s Portal", g_sPortName[COLOR]);
		return g_iClientPortals[client][COLOR];
	}
	//make portal ent
	char sTeleportName[32];
	Format(sTeleportName, sizeof(sTeleportName), "%sTeleport", g_sPortName[COLOR]);
	
	int EntPortal = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue( EntPortal, "model", g_PortalMDL);
	DispatchKeyValue( EntPortal, "name", sTeleportName);
	DispatchKeyValue( EntPortal, "Solid", "6");
	DispatchKeyValueVector( EntPortal, "Origin", PortalOrigin );
	DispatchKeyValueVector( EntPortal, "Angles", PortalAngle );
	DispatchSpawn(EntPortal);
	AcceptEntityInput(EntPortal, "EnableCollision");
	
	//portal visual effects
	SetEntityMoveType(EntPortal, MOVETYPE_NONE);
	SetEntityRenderMode(EntPortal, RENDER_NORMAL);
	SetEntityRenderFx(EntPortal, RENDERFX_PULSE_FAST);
	SetEntityRenderColor(EntPortal, g_iRGB[COLOR][R], g_iRGB[COLOR][G], g_iRGB[COLOR][B], g_iRGB[COLOR][A]); // Entity Color
	
	//reg portal in PortalTrie
	char portal_key[10];
	FormatEx(portal_key, sizeof(portal_key), "%x", EntPortal);
	int datArr[PORTDAT];
	datArr[CLIENT] = client;
	datArr[PTCOLOR] = view_as<int>(COLOR);
	SetTrieArray(g_hPortalTrie, portal_key, datArr, sizeof(datArr), true);	
	
	//start hook and show it
	SDKHook(EntPortal, SDKHook_Touch, TouchPortal);
	PrintToChat(client,"%s Portal Spawned", g_sPortName[COLOR]);
	return EntPortal;
}

//same as TouchPortal
public Action TouchPortal(int entity, int other)
{
	if (g_noBots && IsFakeClient(other)) return Plugin_Handled;
	
	if (g_noProps && other >= MaxClients) return Plugin_Handled;
	
	if (BlockWorld(other))	return Plugin_Handled;
	
	//if that client or bots alowed, do stuff
	char portal_key[10];
	FormatEx(portal_key, sizeof(portal_key), "%x", entity);
	int datArr[PORTDAT];
	GetTrieArray(g_hPortalTrie, portal_key, datArr, sizeof(datArr));
	int client = datArr[CLIENT];
	PORTCOLOR COLOR = view_as<PORTCOLOR>(datArr[PTCOLOR]);
	
	if (g_iClientPortals[client][PORTPAIR[COLOR]] == 0 || !IsValidEdict(g_iClientPortals[client][PORTPAIR[COLOR]]))
	{
		EmitSoundToAll(g_sndPortalERROR, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);	
		PrintToChat(other,"Error! %s Portal not exist", g_sPortName[PORTPAIR[COLOR]]);
		return Plugin_Handled;
	}
	//pitch effect
	int pitchX = GetRandomInt(60, 180);
	EmitSoundToAll(g_sndPortalFX,	entity,	SNDCHAN_STATIC,		SNDLEVEL_RAIDSIREN,	SND_NOFLAGS,	SNDVOL_NORMAL,	40,		-1, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(g_sndPortalGO,	other,	SNDCHAN_REPLACE,	SNDLEVEL_NORMAL,	SND_NOFLAGS,	SNDVOL_NORMAL,	pitchX,	-1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	//some math stuff
	float ClientOrigin[3];
	float ClientAngle[3];
	float PlayerVec[3];
	float PlayerAng[3];
	GetEntPropVector(g_iClientPortals[client][PORTPAIR[COLOR]], Prop_Data, "m_vecOrigin", PlayerVec);
	GetEntPropVector(g_iClientPortals[client][PORTPAIR[COLOR]], Prop_Data, "m_angRotation", PlayerAng);
	ClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
	ClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
	ClientOrigin[2] = (PlayerVec[2] + 10);
	ClientAngle[0] = PlayerAng[0];
	ClientAngle[1] = PlayerAng[1];
	ClientAngle[2] = PlayerAng[2];
	
	//main portal things
	if (other <= MaxClients)
	{
		ShowParticle(PlayerVec, "electrical_arc_01_system", 5.0);
		ScreenFade(other, 255, 255, 255, 255, 50, 1);
	}
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderFx(entity, RENDERFX_STROBE_FASTER);
	SetEntityRenderColor(entity, 255, 255, 255, 200);
	CreateTimer(3.0, ResetPortal, entity);
	TeleportEntity(other, ClientOrigin, ClientAngle, ClientOrigin);
	return Plugin_Continue;
}

//Timers, Functions ,etc
public void ShowParticle(float pos[3], char[] particlename, float time)
{
	/* Show particle effect you like */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
	}
}

public void PrecacheParticle(char[] particlename)
{
	/* Precache particle */
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
	}
}

public Action DeleteParticles(Handle timer, any particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		RemoveEdict(particle);
	}
	return Plugin_Handled;
}

public Action ResetPortal(Handle timer, any entity)
{
	if (IsValidEdict(entity))
	{
		char portal_key[10];
		FormatEx(portal_key, sizeof(portal_key), "%x", entity);
		int datArr[PORTDAT];
		GetTrieArray(g_hPortalTrie, portal_key, datArr, sizeof(datArr));
		PORTCOLOR COLOR = view_as<PORTCOLOR>(datArr[PTCOLOR]);		
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 6);
		SetEntityRenderFx(entity, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(entity, g_iRGB[COLOR][R], g_iRGB[COLOR][G], g_iRGB[COLOR][B], g_iRGB[COLOR][A]); // Entity Color
	}
	return Plugin_Handled;
}

void GetCollisionPoint(int client, float pos[3])
{
	float vOrigin[3];
	float vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) TR_GetEndPosition(pos, trace);
	delete trace;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

public void ScreenFade(int target, int r, int g, int b, int a, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type == 0)
	{
		BfWriteShort(msg, (0x0002 | 0x0008));
	}
	else
	{
		BfWriteShort(msg, (0x0001 | 0x0010));
	}
	BfWriteByte(msg, r);
	BfWriteByte(msg, g);
	BfWriteByte(msg, b);
	BfWriteByte(msg, a);
	EndMessage();
}

void InitPrecache()
{
	GetConVarString(g_hCvar_PortalMDL,		g_PortalMDL,		sizeof(g_PortalMDL));
	GetConVarString(g_hCvar_particle,		g_particle,			sizeof(g_particle));
	GetConVarString(g_hCvar_sndPortalGO,	g_sndPortalGO,		sizeof(g_sndPortalGO));
	GetConVarString(g_hCvar_sndPortalERROR,	g_sndPortalERROR,	sizeof(g_sndPortalERROR));
	GetConVarString(g_hCvar_sndPortalFX,	g_sndPortalFX,		sizeof(g_sndPortalFX));

	PrecacheParticle(g_particle);
	PrecacheModel(g_PortalMDL,		true);
	PrecacheSound(g_sndPortalGO,	true);
	PrecacheSound(g_sndPortalERROR,	true);
	PrecacheSound(g_sndPortalFX,	true);
}

bool BlockWorld(int other)
{
	char m_ModelName[PLATFORM_MAX_PATH];
	if (other == -1)							return true;	
	if (!IsValidEntity (other))					return true;
	GetEntPropString(other, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));	
	if (StrContains(m_ModelName, "*") != -1)	return true;
	return false;
}