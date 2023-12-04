#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION	"1.4.1a"

ConVar g_hCvar_PortalMDL;
ConVar g_hCvar_sndPortalGO;
ConVar g_hCvar_sndPortalERROR;
ConVar g_hCvar_sndPortalFX;
ConVar g_hCvar_particle;
ConVar g_hCvar_noBots;
ConVar g_hCvar_noProps;
ConVar g_hCvar_adminOnly;

bool g_noBots = false;
bool g_noProps = false;

Handle g_hPortalTrie = INVALID_HANDLE;
enum RGBA {R = 0, G = 1, B = 2, A = 3};
enum PORTDAT {CLIENT = 0, PORTCOLOR = 1};
enum PORTCOLORS {RED = 0, BLUE = 1};// , GREEN = 2, PINK = 3};
int g_iClientPortals[MAXPLAYERS+1][PORTCOLORS];
int g_iRGB[PORTCOLORS][RGBA];
char g_PortalMDL[PLATFORM_MAX_PATH];
char g_sndPortalGO[PLATFORM_MAX_PATH];
char g_sndPortalERROR[PLATFORM_MAX_PATH];
char g_sndPortalFX[PLATFORM_MAX_PATH];
char g_particle[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "Portals(BV&OR)",
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
	
	RegConsoleCmd("sm_p", 		Command_Portal, 						"[SM] info: Spawn Portal or teleport specefic portal, red or blue");
	RegAdminCmd("sm_pd",		Command_PortalDelete,	ADMFLAG_BAN,	"Delete all BV portals in map");

	
	g_hCvar_noProps.			AddChangeHook(ConVarChanged_Cvars);
	g_hCvar_noBots.				AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "l4d2_portals");
	GetCvars();
	
	g_hPortalTrie = CreateTrie();
	SetupColors();
}

public void SetupColors()
{
	g_iRGB[RED][R] = 245;
	g_iRGB[RED][G] = 30;
	g_iRGB[RED][B] = 10;
	g_iRGB[RED][A] = 255;
	g_iRGB[BLUE][R] = 50;
	g_iRGB[BLUE][G] = 100;
	g_iRGB[BLUE][B] = 250;
	g_iRGB[BLUE][A] = 255;
}

//convar hooks
public void ConVarChanged_Cvars(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	GetCvars();
}

void GetCvars()
{
	g_noProps =	g_hCvar_noProps.	BoolValue;
	g_noBots =	g_hCvar_noBots.		BoolValue;	
}

public void OnMapStart()
{
	InitPrecache();
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int clients = 1; clients <= (MaxClients); clients++)
	{
		g_iClientPortals[clients][RED] = 0;
		g_iClientPortals[clients][BLUE] = 0;
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
		g_iClientPortals[client][RED] = 0;
		g_iClientPortals[client][BLUE] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	ClearPortals(client);
}

public Action Command_PortalDelete(int client, int args)
{
	for (int clients = 1; clients <= (MaxClients); clients++)
	{
		ClearPortals(client);
	}
	return Plugin_Continue;
}

public void ClearPortals(int client)
{
/*	for (PORTCOLORS COLOR = RED; COLOR < PORTCOLORS; COLOR++)
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
	} */
	if (g_iClientPortals[client][RED] != 0)
	{
		if (IsValidEdict(g_iClientPortals[client][RED]))
		{
			SDKUnhook(g_iClientPortals[client][RED], SDKHook_Touch, TouchPortal);
			RemoveEdict(g_iClientPortals[client][RED]);
			char portal_key[10];
			FormatEx(portal_key, sizeof(portal_key), "%x", g_iClientPortals[client][RED]);
			RemoveFromTrie(g_hPortalTrie, portal_key);
		}
		g_iClientPortals[client][BLUE] = 0;
	}
	if (g_iClientPortals[client][BLUE] != 0)
	{
		if (IsValidEdict(g_iClientPortals[client][BLUE]))
		{
			SDKUnhook(g_iClientPortals[client][BLUE], SDKHook_Touch, TouchPortal);
			RemoveEdict(g_iClientPortals[client][BLUE]);
			char portal_key[10];
			FormatEx(portal_key, sizeof(portal_key), "%x", g_iClientPortals[client][BLUE]);
			RemoveFromTrie(g_hPortalTrie, portal_key);
		}
		g_iClientPortals[client][BLUE] = 0;
	}
}

public Action Command_Portal(int client, int args)
{
	if (GetConVarInt(g_hCvar_adminOnly) > 0 )
	{
		if (!GetAdminFlag(GetUserAdmin(client), Admin_Generic, Access_Effective))
		{
			ReplyToCommand( client, "[SM] Only admin can use this command" );
			return Plugin_Continue;
		}
	}
	
	if (GetClientAimTarget(client, false) >= 0)
	{
		PrintToChat(client,"[SM] Bad Portal Position try Other");
		return Plugin_Handled;
	}
	
	if (args < 2)
	{
		char text[7];
		float ClientOrigin[3];
		float EyeAngles[3];
		float TelePortalOrigin[3];
		float TelePortalAngle[3];

		//math to get portal spawn point
		GetCollisionPoint(client, ClientOrigin);
		GetClientEyeAngles(client, EyeAngles);

		TelePortalOrigin[0] = ClientOrigin[0];
		TelePortalOrigin[1] = ClientOrigin[1];
		TelePortalOrigin[2] = ClientOrigin[2];

		TelePortalAngle[0] = NULL_VECTOR[0];
		TelePortalAngle[1] = (EyeAngles[1] + 180);
		TelePortalAngle[2] = NULL_VECTOR[2];

		//get args
		GetCmdArgString(text, sizeof(text));
		if (strcmp(text, "red", false) == 0)
		{
			if (IsValidEntity(g_iClientPortals[client][RED]))
			if (g_iClientPortals[client][RED]!=0)
			{
				TeleportEntity(g_iClientPortals[client][RED], TelePortalOrigin, TelePortalAngle, TelePortalOrigin);
				PrintToChat(client,"Teleport RedPortal");
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client,"RedPortal not exist");
				return Plugin_Handled;
			}
		}
		else if (strcmp(text, "blue", false) == 0)
		{
			if (IsValidEntity(g_iClientPortals[client][BLUE]))
			if (g_iClientPortals[client][BLUE]!=0)
			{
				TeleportEntity(g_iClientPortals[client][BLUE], TelePortalOrigin, TelePortalAngle, TelePortalOrigin);
				PrintToChat(client,"Teleport BluePortal");
				return Plugin_Handled;
			}
			else
			{
				PrintToChat(client,"BluePortal not exist");
				return Plugin_Handled;
			}
		}

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
	//if Red and blue create so need to delete it
	else ClearPortals(client);
	return Plugin_Continue;
}



public int SetupPortalEntity(int client, PORTCOLORS color)
{
	float ClientOrigin[3];
	float EyeAngles[3];
	float PortalOrigin[3];
	float PortalAngle[3];
	//Initialize
	GetCollisionPoint(client, ClientOrigin);
	GetClientEyeAngles(client, EyeAngles);
	//Math
	PortalOrigin[0] = ClientOrigin[0];
	PortalOrigin[1] = ClientOrigin[1];
	PortalOrigin[2] = ClientOrigin[2];

	PortalAngle[0] = NULL_VECTOR[0];
	PortalAngle[1] = (EyeAngles[1] + 180);
	PortalAngle[2] = NULL_VECTOR[2];
	//make portal ent
	char name[10];
	char sTeleportName[32];
	switch (color)
	{
		case RED: Format(name, sizeof(name), "Red");
		case BLUE: Format(name, sizeof(name), "Blue");
	}
	
	Format(sTeleportName, sizeof(sTeleportName), "%sTeleport", name);
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
	SetEntityRenderColor(EntPortal, g_iRGB[color][R], g_iRGB[color][G], g_iRGB[color][B], g_iRGB[color][A]); // Entity Color
	//reg portal in PortalTrie
	char portal_key[10];
	FormatEx(portal_key, sizeof(portal_key), "%x", EntPortal);
	int datArray[PORTDAT];
	datArray[CLIENT] = client;
	datArray[PORTCOLOR] = view_as<int>(color);
	SetTrieArray(g_hPortalTrie, portal_key, datArray, sizeof(datArray), true);	
	//start hook and show it
	SDKHook(EntPortal, SDKHook_Touch, TouchPortal);
	PrintToChat(client,"%s Portal Spawned", name);
	return EntPortal;
}

//same as TouchPortal
public Action TouchPortal(int entity, int other)
{
	if (g_noBots && IsFakeClient(other)) return Plugin_Handled;
	
	if (g_noProps && other >= MAXPLAYERS) return Plugin_Handled;
	
	if (BlockWorld(other))	return Plugin_Handled;
	
	//if that client or bots alowed, do stuff
	char portal_key[10];
	FormatEx(portal_key, sizeof(portal_key), "%x", entity);
	int datArray[PORTDAT];
	GetTrieArray(g_hPortalTrie, portal_key, datArray, sizeof(datArray));
	int client = datArray[CLIENT];
	PORTCOLORS COLOR_OUT;
	
	switch (view_as<PORTCOLORS>(datArray[PORTCOLOR]))
	{
	 case BLUE: COLOR_OUT = RED;
	 case RED: COLOR_OUT = BLUE;
	}
		
	if (g_iClientPortals[client][COLOR_OUT] == 0 || !IsValidEdict(g_iClientPortals[client][COLOR_OUT]))
	{
		EmitSoundToAll(g_sndPortalERROR, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		switch (COLOR_OUT)
		{
		 case BLUE:	PrintToChat(other,"Error! Blue Portal not exist");
		 case RED:	PrintToChat(other,"Error! Red Portal not exist");
		}
		return Plugin_Handled;
	}
	//pitch effect
	int pitchX = GetRandomInt(60, 180);
	EmitSoundToAll(g_sndPortalFX,	entity,	SNDCHAN_STATIC,		SNDLEVEL_RAIDSIREN,	SND_NOFLAGS,	SNDVOL_NORMAL,	40,		-1, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(g_sndPortalGO,	other,	SNDCHAN_REPLACE,	SNDLEVEL_NORMAL,	SND_NOFLAGS,	SNDVOL_NORMAL,	pitchX,	-1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	
	//some math stuff
	float BlueClientOrigin[3];
	float BlueClientAngle[3];
	float PlayerVec[3];
	float PlayerAng[3];
	GetEntPropVector(g_iClientPortals[client][COLOR_OUT], Prop_Data, "m_vecOrigin", PlayerVec);
	GetEntPropVector(g_iClientPortals[client][COLOR_OUT], Prop_Data, "m_angRotation", PlayerAng);
	BlueClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
	BlueClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
	BlueClientOrigin[2] = (PlayerVec[2] + 10);
	
	BlueClientAngle[0] = PlayerAng[0];
	BlueClientAngle[1] = PlayerAng[1];
	BlueClientAngle[2] = PlayerAng[2];
	
	//main portal things
	if (other <= MAXPLAYERS)
	{
		ShowParticle(PlayerVec, "electrical_arc_01_system", 5.0);
		ScreenFade(other, 255, 255, 255, 255, 50, 1);
	}
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderFx(entity, RENDERFX_STROBE_FASTER);
	SetEntityRenderColor(entity, 255, 255, 255, 200);
	CreateTimer(3.0, ResetPortal, entity);
	TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
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
		int datArray[PORTDAT];
		GetTrieArray(g_hPortalTrie, portal_key, datArray, sizeof(datArray));
		PORTCOLORS color = view_as<PORTCOLORS>(datArray[PORTCOLOR]);
		
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 6);
		SetEntityRenderFx(entity, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(entity, g_iRGB[color][R], g_iRGB[color][G], g_iRGB[color][B], g_iRGB[color][A]); // Entity Color
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
	return (entity > MaxClients() || !entity);
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