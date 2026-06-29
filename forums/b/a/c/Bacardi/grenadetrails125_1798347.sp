/**
	Original  Grenade Trails 1.1 = https://forums.alliedmods.net/showthread.php?t=68057

	This 1.2
	- SDKHooks require
	- Cvar: gt_enables "1" // 0 = Disable, 1 = Enable, 2 = For admins
	- Admin override: "sm_grenade_trails" (adminflag "a" by default)

	This 1.2.5
	- support clientpref
	- Cvar: gt_enables "3" //
	1 = enable for non-admins
	2 = enable for admins
	16 = exclude bots
*/

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <clientprefs>


public Plugin:myinfo = 
{
	name = "Grenade Trails",
	description = "Adds a trail to grenades.",
	author = "Bacardi",
	version = "1.2.5",
	url = "https://forums.alliedmods.net/showthread.php?t=195944"
}

#define FragColor 	{225,0,0,225}
#define FlashColor 	{255,116,0,225}
#define SmokeColor	{0,225,0,225}

new g_iCvarMode;
new g_iBeamSpriteIndex;
new bool:g_bCanCheckGrenades;
new bool:g_bIsActive[MAXPLAYERS+1];


public OnPluginStart()
{
	new Handle:cvar = CreateConVar("gt_enables", "3", "Grenade Trails\n1 = non-admins\n2 = admins\n16 = exlude bots", FCVAR_NONE, true, 0.0, true, 19.0);
	g_iCvarMode = GetConVarInt(cvar);
	HookConVarChange(cvar, cvar_change);
	CloseHandle(cvar);

	// Plugin reloaded ?
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public OnMapEnd()
{
	g_bCanCheckGrenades = false;
}

public OnMapStart()
{
	g_bCanCheckGrenades = true;
	g_iBeamSpriteIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public cvar_change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_iCvarMode = StringToInt(newValue);

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	g_bIsActive[client] = false;

	if( !g_iCvarMode || !(g_iCvarMode & 3) ) // Disabled
	{
		return;
	}

	if( IsFakeClient(client) ) // Bots
	{
		if( g_iCvarMode & 1 && !(g_iCvarMode & 16) )
		{
			g_bIsActive[client] = true;
		}
		return;
	}

	new bool:haveaccess = CheckCommandAccess(client, "sm_grenade_trails", ADMFLAG_RESERVATION);

	if( g_iCvarMode & 1 && g_iCvarMode & 2 ) // everyone
	{
		g_bIsActive[client] = true;
	}
	else
	{
		g_bIsActive[client] = haveaccess; // admins only

		if( g_iCvarMode & 1 ) // non-admins only
		{
			g_bIsActive[client] = !haveaccess;
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if( !g_iCvarMode || !(g_iCvarMode & 3) ) // Disabled
	{
		return;
	}

	if(g_bCanCheckGrenades && StrContains(classname, "_projectile", false) != -1)
	{
		new Handle:datapack = INVALID_HANDLE;
		CreateDataTimer(0.0, projectile, datapack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(datapack, entity);
		WritePackString(datapack, classname);
		ResetPack(datapack);
	}
}

public Action:projectile(Handle:timer, Handle:datapack)
{
	new entity = ReadPackCell(datapack);
	new m_hThrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");

	if(0 < m_hThrower <= MaxClients && g_bIsActive[m_hThrower])
	{
		new String:classname[30];
		ReadPackString(datapack, classname, sizeof(classname));

		if(StrContains(classname, "hegrenade", false) != -1)
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, FragColor);
			TE_SendToAll();
		}
		else if(StrContains(classname, "flashbang", false) != -1)
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, FlashColor);
			TE_SendToAll();
		}
		else // smokegrenade and rest grenades
		{
			TE_SetupBeamFollow(entity, g_iBeamSpriteIndex,	0, Float:1.0, Float:3.0, Float:3.0, 1, SmokeColor);
			TE_SendToAll();	
		}
	}
}