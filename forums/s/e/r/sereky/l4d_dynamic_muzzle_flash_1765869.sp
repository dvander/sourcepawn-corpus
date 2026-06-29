#define PLUGIN_VERSION 		"1.0"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Dynamic Muzzle Flash
*	Author	:	SilverShot, sereky
*	Descrp	:	Adds dynamic muzzle flash to gunfire.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=186558

========================================================================================
	Change Log:

1.0 (01-Jun-2012)
	- Initial release.

======================================================================================*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS				FCVAR_PLUGIN|FCVAR_NOTIFY
#define CHAT_TAG				"\x05[Dynamic Light] \x01"


static
	// Cvar Handles/Variables
	Handle:g_hCvarAllow, Handle:g_hCvarAlpha, Handle:g_hCvarColor, Handle:g_hCvarDist,
	Handle:g_hCvarHide, Handle:g_hCvarHull, Handle:g_hCvarTime, Handle:g_hCvarMultip, Handle:g_hCvarModes, Handle:g_hCvarModesOff,
	bool:g_bCvarAllow, g_iCvarAlpha, g_iCvarDist, g_iCvarHide, g_iCvarColor,
	String:g_iCvarHull,
	Float:g_iCvarTime, Float:g_iCvarMultip,

	// Plugin Variables
	Handle:g_hMPGameMode,
	g_iTransmit[MAXPLAYERS+1],
	g_iLightIndex[MAXPLAYERS+1],
	bool:fired[MAXPLAYERS+1];
new Float:flGameTime[MAXPLAYERS+1];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin:myinfo =
{
	name = "[L4D & L4D2] Dynamic Muzzle Flash",
	author = "SilverShot, sereky",
	description = "Adds dynamic muzzle flash to gunfire",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=186558"
}

public OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d_dynamic_muzzle_flash_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarAlpha =		CreateConVar(	"l4d_dynamic_muzzle_flash_size",			"255.0",		"Size of the light.", CVAR_FLAGS );
	g_hCvarColor =		CreateConVar(	"l4d_dynamic_muzzle_flash_color",			"250 150 30",	"The light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarDist =		CreateConVar(	"l4d_dynamic_muzzle_flash_distance",		"5",			"Distance the light shines before not lighting up.", CVAR_FLAGS );
	g_hCvarHide =		CreateConVar(	"l4d_dynamic_muzzle_flash_hide",			"1",			"0=Show the dynamic light to the owner using it. 1=Hide the dynamic light so only other players can see it.", CVAR_FLAGS );
	g_hCvarHull =		CreateConVar(	"l4d_dynamic_muzzle_flash_bright",			"1",			"Brightness of the light.", CVAR_FLAGS );
	g_hCvarTime =		CreateConVar(	"l4d_dynamic_muzzle_flash_time",			"0.1",			"The light will disappear after this many seconds.", CVAR_FLAGS );
	g_hCvarMultip =		CreateConVar(	"l4d_dynamic_muzzle_flash_multiplier",		"0.5",			"1.0=Off. Other value randomly changes the size of the light.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d_dynamic_muzzle_flash_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_dynamic_muzzle_flash_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	CreateConVar(						"l4d_dynamic_muzzle_flash_version",		PLUGIN_VERSION,	"Dynamic Light plugin version.", CVAR_FLAGS|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_dynamic_muzzle_flash");

	g_hMPGameMode = FindConVar("mp_gamemode");
	HookConVarChange(g_hMPGameMode,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModes,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarModesOff,		ConVarChanged_Allow);
	HookConVarChange(g_hCvarAllow,			ConVarChanged_Allow);
	HookConVarChange(g_hCvarAlpha,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarDist,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHide,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarHull,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarTime,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarMultip,			ConVarChanged_Cvars);
	HookConVarChange(g_hCvarColor,			ConVarChanged_Color);
}

public OnPluginEnd()
{
	for( new i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}


// ====================================================================================================
//					CVARS
// ====================================================================================================
public OnConfigsExecuted()
	IsAllowed();

public ConVarChanged_Color(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:sColor[16];
	GetConVarString(g_hCvarColor, sColor, sizeof(sColor));

	for( new i = 0; i <= MaxClients; i++ )
	{
		if( IsValidEntRef(g_iLightIndex[i]) )
		{
			SetVariantString(sColor);
			AcceptEntityInput(g_iLightIndex[i], "color");
		}
	}
}

public ConVarChanged_Cvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetCvars();
	for( new i = 1; i <= MaxClients; i++ )
	{
		DeleteLight(i);
	}
}

public ConVarChanged_Allow(Handle:convar, const String:oldValue[], const String:newValue[])
	IsAllowed();

GetCvars()
{
	decl String:sColor[16];
	GetConVarString(g_hCvarColor, sColor, sizeof(sColor));
	g_iCvarColor = GetColor(sColor);
	g_iCvarAlpha = GetConVarInt(g_hCvarAlpha);
	g_iCvarDist = GetConVarInt(g_hCvarDist);
	g_iCvarHide = GetConVarInt(g_hCvarHide);
	g_iCvarHull = GetConVarInt(g_hCvarHull);
	g_iCvarTime = GetConVarFloat(g_hCvarTime);
	g_iCvarMultip = g_iCvarAlpha * GetConVarFloat(g_hCvarMultip);
}

GetColor(String:sTemp[])
{
	decl String:sColors[3][4];
	ExplodeString(sTemp, " ", sColors, 3, 4);

	new color;
	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);
	return color;
}

IsAllowed()
{
	new bool:bAllowCvar = GetConVarBool(g_hCvarAllow);
	new bool:bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bAllowCvar == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bAllowCvar == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();

		for( new i = 1; i <= MaxClients; i++ )
		{
			DeleteLight(i);
		}
	}
}

bool:IsAllowedGameMode()
{
	if( g_hMPGameMode == INVALID_HANDLE )
		return false;

	decl String:sGameModes[64], String:sGameMode[64];
	GetConVarString(g_hMPGameMode, sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	GetConVarString(g_hCvarModes, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	GetConVarString(g_hCvarModesOff, sGameModes, sizeof(sGameModes));
	if( strcmp(sGameModes, "") )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
HookEvents()
{
	HookEvent("weapon_fire", Event_FireStart);
}

UnhookEvents()
{
	UnhookEvent("weapon_fire", Event_FireStart);
}

public Action:Event_FireStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sTemp[32];

	GetClientWeapon(client, sTemp, sizeof(sTemp));
	new slot = GetPlayerWeaponSlot(client, 0);
	if (slot != -1)
	{
		new String:sniper[32];
		GetEdictClassname(slot, sniper, 32);
		if( StrEqual(sTemp, sniper))
		{
			fired[client] = true;
			return;
		}
	}
	if(StrContains(sTemp, "weapon_pistol") != -1)
	{
		fired[client] = true;
	}
}

// ====================================================================================================
//					DYNAMIC LIGHT ON/OFF
// ====================================================================================================
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if( g_bCvarAllow )
	{
		new entity = g_iLightIndex[client];


		if( GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		{
			if( IsValidEntRef(entity) == true )
				DeleteLight(client);

			return;
		}


		// Missing light, create entity
		if( IsValidEntRef(entity) == false )
		{
			entity = CreateLight(client);
		}

		TeleportDynamicLight(client, entity);

		new ammo;
		if(fired[client] == true)
		{
			ammo = GetRandomInt(1, 2);
		}
		if (ammo == 1)
		{
			SetVariantInt(g_iCvarAlpha);
			AcceptEntityInput(entity, "distance");
			AcceptEntityInput(entity, "TurnOn");
			flGameTime[client] = GetGameTime() +g_iCvarTime;
			fired[client] = false;
		}
		if (ammo == 2)
		{
			SetVariantFloat(g_iCvarMultip);
			AcceptEntityInput(entity, "distance");
			AcceptEntityInput(entity, "TurnOn");
			flGameTime[client] = GetGameTime() +g_iCvarTime;
			fired[client] = false;
		}

		if(flGameTime[client] <= GetGameTime())
		{
			AcceptEntityInput(entity, "TurnOff");
		}
	}
}

DeleteLight(client)
{
	new entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;

	if( IsValidEntRef(entity) )
	{
		AcceptEntityInput(entity, "Kill");

		if( g_iTransmit[client] == 1 )
		{
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
			g_iTransmit[client] = 0;
		}
	}
}

CreateLight(client)
{
	new entity = g_iLightIndex[client];
	if( IsValidEntRef(entity) )
		return 0;

	entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	decl String:sTemp[5];
	IntToString(g_iCvarHull, sTemp, sizeof(sTemp));
	DispatchKeyValue(entity, "brightness", sTemp);
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", float(g_iCvarAlpha));
	DispatchKeyValue(entity, "style", "-1");
	SetEntProp(entity, Prop_Send, "m_clrRender", g_iCvarColor);
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOff");

	g_iTransmit[client] = 0;
	if( g_iCvarHide == 1 )
	{
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
		g_iTransmit[client] = 1;
	}

	g_iLightIndex[client] = EntIndexToEntRef(entity);
	return entity;
}

public Action:Hook_SetTransmitLight(entity, client)
{
	if( g_iLightIndex[client] == EntIndexToEntRef(entity) )
		return Plugin_Handled;
	return Plugin_Continue;
}

TeleportDynamicLight(client, entity)
{
	decl Float:vLoc[3], Float:vPos[3], Float:vAng[3];

	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vLoc);

	new Handle:trace;
	trace = TR_TraceRayFilterEx(vLoc, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		new Float:fDist = GetVectorDistance(vLoc, vPos);

		if( fDist <= g_iCvarDist )
		{
			GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
			vPos[0] -= vAng[0];
			vPos[1] -= vAng[1];
			vPos[2] -= vAng[2];
			TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		}
		else
		{
			GetAngleVectors(vAng, vAng, NULL_VECTOR, NULL_VECTOR);
			vLoc[0] += vAng[0] * (g_iCvarDist);
			vLoc[1] += vAng[1] * (g_iCvarDist);
			vLoc[2] += vAng[2] * (g_iCvarDist);
			TeleportEntity(entity, vLoc, NULL_VECTOR, NULL_VECTOR);
		}
	}

	CloseHandle(trace);
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )
	{
		return false;
	}
	if(entity < MaxClients)
	{
		if (GetClientTeam(entity) == 2 )
		{
			return false;
		}
	}
	return true;
}

bool:IsValidEntRef(entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}