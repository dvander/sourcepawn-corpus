// ==============================================================================================================================
// >>> GLOBAL INCLUDES
// ==============================================================================================================================
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <fireworks_core>

// ==============================================================================================================================
// >>> PLUGIN INFORMATION
// ==============================================================================================================================
#define PLUGIN_VERSION "1.0.1"
public Plugin:myinfo =
{
	name 			= "[Fireworks] AdminMenu",
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

// ==============================================================================================================================
// >>> CONSOLE VARIABLES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> GLOBAL VARIABLES
// ==============================================================================================================================
new Handle:		g_hFireworksMenu;

// ==============================================================================================================================
// >>> LOCAL INCLUDES
// ==============================================================================================================================


// ==============================================================================================================================
// >>> FORWARDS
// ==============================================================================================================================
public OnPluginStart() 
{
	if ( Fireworks_IsFireworksLoaded() ) {
		Fireworks_OnFireworksLoaded();
	}
	
	CreateConVar("sm_fireworkds_adminmenu_version", PLUGIN_VERSION, "version of [Fireworks] AdminMenu plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_fireworks_adminmenu", Command_FireworksAdminMenu, ADMFLAG_ROOT);
}

public Fireworks_OnFireworksLoaded()
{
	if ( g_hFireworksMenu != INVALID_HANDLE ) {
		CloseHandle(g_hFireworksMenu);
	}
	
	g_hFireworksMenu = CreateMenu(Handler_FireworksMenu);
	SetMenuTitle(g_hFireworksMenu, "Select firework:\n ");
	
	new Handle:hFireworkNames = Fireworks_GetFireworksNames();
	new iLength = GetArraySize(hFireworkNames);
	
	decl String:sFireworkName[LENGTH_FIREWORK_NAME];
	for ( new i = 0; i < iLength; ++i ) {
		GetArrayString(hFireworkNames, i, SZF(sFireworkName));
		AddMenuItem(g_hFireworksMenu, sFireworkName, sFireworkName);
	}
}

public OnMapStart() 
{
	
}

public OnConfigsExecuted() 
{
	
}

// ==============================================================================================================================
// >>> COMMANDS
// ==============================================================================================================================
public Action:Command_FireworksAdminMenu(iClient, iArgc)
{
	DisplayMenu(g_hFireworksMenu, iClient, MTF);
	return Plugin_Handled;
}

// ==============================================================================================================================
// >>> HANDLERS
// ==============================================================================================================================
public Handler_FireworksMenu(Handle:hMenu, MenuAction:action, iClient, iSlot)
{
	switch ( action ) {
		case MenuAction_Select: {
			decl String:sFireworkName[LENGTH_FIREWORK_NAME];
			GetMenuItem(hMenu, iSlot, SZF(sFireworkName));
			
			if ( Fireworks_IsFireworkExists(sFireworkName) ) {
				decl Float:vOrigin[3], Float:vAngles[3];
				if ( GetClientViewOriginAndAngles(iClient, vOrigin, vAngles) ) {
					Fireworks_SpawnFirework(sFireworkName, vOrigin, vAngles);
					DisplayMenuAtItem(g_hFireworksMenu, iClient, GetMenuSelectionPosition(), MTF);
				}
				else {
					PrintToChat(iClient, "Surface not found");
				}
			}
			else {
				PrintToChat(iClient, "Firework with name \"%s\" doesn't exists", sFireworkName);
			}
		}
	}
}

// ==============================================================================================================================
// >>> FUNCTIONS
// ==============================================================================================================================
bool:GetClientViewOriginAndAngles(const iClient, Float:vOrigin[3], Float:vAngles[3])
{
	// get client eye position and angles
	GetClientEyePosition(iClient, vOrigin);
	GetClientEyeAngles(iClient, vAngles);
	
	// start trace ray
	TR_TraceRayFilter(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TR_DontHitSelf, iClient);
	// if hit something
	if ( TR_DidHit(INVALID_HANDLE) )
	{
		// get collusion origin
		TR_GetEndPosition(vOrigin, INVALID_HANDLE);
		// get angles 
		// TR_GetPlaneNormal(INVALID_HANDLE, vAngles);
		// find projection
		// GetVectorAngles(vAngles, vAngles);
		// vAngles[0] += 90.0;
		
		// return true
		return true;
	}
	
	// return false
	return false;
}

public bool:TR_DontHitSelf(int iEntity, int iMask, any iData) 
{ 
	return ( iEntity != iData ); 
}
