/*
update log [06.06.2010]
add admin cvar sm_portals_admin
delete force function not work correctly

update log [07.06.2010]
add admin command to delete all portals on map sm_pd
change default value sm_portals_noprops to 1, props not work correctly
disable use particle effect and Screen Fade effect for props

update log [08.06.2010]
bugs, maybe fix something
add function to remove client portal when he disconnect 

update log [15.06.2010]
add alexip121093 code
another fix for jump bag, now you can't spawn portal if some entity block it
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION	"1.4"

new Handle:cv_PortalMDL = INVALID_HANDLE;
new Handle:cv_sndPortalGO = INVALID_HANDLE;
new Handle:cv_sndPortalERROR = INVALID_HANDLE;
new Handle:cv_sndPortalFX = INVALID_HANDLE;
new Handle:cv_particle = INVALID_HANDLE;
new Handle:cv_noBots = INVALID_HANDLE;
new Handle:cv_noProps = INVALID_HANDLE;
new Handle:cv_adminOnly = INVALID_HANDLE;

new bool:g_noBots = false;
new bool:g_noProps = false;

new redtblue[4096] = 0;
new bluetred[4096] = 0;
new cred[MAXPLAYERS] = 0;
new cblue[MAXPLAYERS] = 0;

new String:g_PortalMDL[PLATFORM_MAX_PATH];
new String:g_sndPortalGO[PLATFORM_MAX_PATH];
new String:g_sndPortalERROR[PLATFORM_MAX_PATH];
new String:g_sndPortalFX[PLATFORM_MAX_PATH];
new String:g_particle[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Portals",
	author = "FluD (tnx hihi1210)",
	description = "Secret AlliedModders teleportation device",
	version = PLUGIN_VERSION,
	url = "www.alliedmods.net"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_p", Command_Portal, "[SM] info: Spawn Portal or teleport specefic portal, red or blue");
	RegAdminCmd("sm_pd", Command_PortalDelete, ADMFLAG_BAN, "Delete all portals in map");

	cv_particle = CreateConVar("sm_portals_particle", "electrical_arc_01_system", "Particle effect", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cv_PortalMDL = CreateConVar("sm_portals_model","models/props_mall/mall_shopliftscanner.mdl", "Portal model", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cv_sndPortalGO = CreateConVar("sm_portals_soundgo","weapons/defibrillator/defibrillator_use.wav", "Sound when someone teleported", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cv_sndPortalERROR = CreateConVar("sm_portals_sounderror","buttons/button11.wav", "Sound on error acquired", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cv_sndPortalFX = CreateConVar("sm_portals_soundfx","ui/pickup_misc42.wav", "Sound if teleport used", FCVAR_PLUGIN|FCVAR_NOTIFY);

	cv_noProps = CreateConVar("sm_portals_noprops","0", "if 1 = props like gascans pipe bomp cant teleport", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cv_noBots = CreateConVar("sm_portals_nobots","0","0 = bots can use portal, 1 = only players", FCVAR_PLUGIN|FCVAR_NOTIFY);
	cv_adminOnly = CreateConVar("sm_portals_admin","0","0 = players can spawn portal, 1 = only admin players", FCVAR_PLUGIN|FCVAR_NOTIFY);

	CreateConVar("sm_portals_version", PLUGIN_VERSION, "Portals Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookConVarChange(cv_noBots,notBot);
	HookConVarChange(cv_noProps,notProp);

	AutoExecConfig(true, "Portals");
}

//convar hooks
public notBot(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_noBots = GetConVarBool(cv_noBots);
}

public notProp(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_noProps = GetConVarBool(cv_noProps);
}

public OnMapStart()
{
	InitPrecache();
	
	new max_entities = GetMaxEntities();
	for (new i = 0; i < max_entities; i++)
	{
		if (redtblue[i] !=0)
		{
			redtblue[i] =  0;
		}
		if (bluetred[i] !=0)
		{
			bluetred[i] =  0;
		}
	}
}

public OnConfigsExecuted()
{
	InitPrecache();
}

public OnClientPutInServer(client)
{
	if (IsClientInGame(client) && !IsFakeClient(client) )
	{
		cred[client] = 0;
		cblue[client] = 0;
	}
}

public OnClientDisconnect(client)
{
	if (cblue[client] !=0 && cred[client] !=0)
	{
		if (IsValidEdict(cblue[client]))
		{
			bluetred[cblue[client]] =0;
			SDKUnhook(cblue[client], SDKHook_Touch, TouchBlue);
			RemoveEdict(cblue[client]);
		}
		if (IsValidEdict(cred[client]))
		{
			redtblue[cred[client]] =0;
			SDKUnhook(cred[client], SDKHook_Touch, TouchRed);
			RemoveEdict(cred[client]);
		}
		cblue[client] =0;
		cred[client] =0;
	}
}

public Action:Command_PortalDelete(client, args)
{
	for (new clients = 1; clients <= (GetRealClientCount(true)); clients++)
	{
		if (cblue[client] !=0 && cred[client] !=0)
		{
			if (IsValidEdict(cblue[client]))
			{
				bluetred[cblue[client]] =0;
				SDKUnhook(cblue[client], SDKHook_Touch, TouchBlue);
				RemoveEdict(cblue[client]);
			}
			if (IsValidEdict(cred[client]))
			{
				redtblue[cred[client]] =0;
				SDKUnhook(cred[client], SDKHook_Touch, TouchRed);
				RemoveEdict(cred[client]);
			}
			cblue[client] =0;
			cred[client] =0;
		}
	}
	return Plugin_Continue;
}

public Action:Command_Portal(client, args)
{
	if (GetConVarInt( cv_adminOnly ) > 0 )
	{
		if (!GetAdminFlag( GetUserAdmin( client ), Admin_Generic, Access_Effective ) )
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
		decl String:text[5];
		decl Float:ClientOrigin[3];
		decl Float:EyeAngles[3];
		decl Float:TelePortalOrigin[3];
		decl Float:TelePortalAngle[3];

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
		if(StrEqual(text, "red", false))
		{
			if (IsValidEntity(cred[client]))
			{
				// if in chat see red or Red teleport Red portal
				TeleportEntity(cred[client], TelePortalOrigin, TelePortalAngle, TelePortalOrigin);
				PrintToChat(client,"Teleport RedPortal");
				return Plugin_Handled;
			}
		}
		else if(StrEqual(text, "blue", false))
		{
			// if in chat see blue or Blue teleport Blue portal
			if (IsValidEntity(cblue[client]))
			{
				TeleportEntity(cblue[client], TelePortalOrigin, TelePortalAngle, TelePortalOrigin);
				PrintToChat(client,"Teleport BluePortal");
				return Plugin_Handled;
			}
		}

	}
	if (cblue[client] ==0 && cred[client]==0)
	{
		decl Float:ClientOrigin[3];
		decl Float:EyeAngles[3];
		decl Float:BluePortalOrigin[3];
		decl Float:BluePortalAngle[3];
		//Initialize

		GetCollisionPoint(client, ClientOrigin);
		GetClientEyeAngles(client, EyeAngles);

		//Math
		BluePortalOrigin[0] = ClientOrigin[0];
		BluePortalOrigin[1] = ClientOrigin[1];
		BluePortalOrigin[2] = ClientOrigin[2];

		BluePortalAngle[0] = NULL_VECTOR[0];
		BluePortalAngle[1] = (EyeAngles[1] + 180);
		BluePortalAngle[2] = NULL_VECTOR[2];
		new Blue = CreateEntityByName("prop_physics_override");

		DispatchKeyValue( Blue, "model", g_PortalMDL);
		DispatchKeyValue( Blue, "name", "BlueTeleport");
		DispatchKeyValue( Blue, "Solid", "6");
		DispatchKeyValueVector( Blue, "Origin", BluePortalOrigin );
		DispatchKeyValueVector( Blue, "Angles", BluePortalAngle );
		DispatchSpawn(Blue);
		AcceptEntityInput(Blue, "EnableCollision");

		SetEntityMoveType(Blue, MOVETYPE_NONE);
		SetEntityRenderMode(Blue, RENDER_NORMAL);
		SetEntityRenderFx(Blue, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(Blue, 50, 100, 250, 255);

		SDKHook(Blue, SDKHook_Touch, TouchBlue);
		PrintToChat(client,"Blue Portal Spawned");
		cblue[client] = Blue;
		return Plugin_Handled;
	}
	else if (cblue[client] !=0 && cred[client]==0)
	{
		// if blue create make red
		decl Float:ClientOrigin[3];
		decl Float:EyeAngles[3];
		decl Float:RedPortalOrigin[3];
		decl Float:RedPortalAngle[3];

		GetCollisionPoint(client, ClientOrigin);
		GetClientEyeAngles(client, EyeAngles);

		//Math
		RedPortalOrigin[0] = ClientOrigin[0];
		RedPortalOrigin[1] = ClientOrigin[1];
		RedPortalOrigin[2] = ClientOrigin[2];

		RedPortalAngle[0] = NULL_VECTOR[0];
		RedPortalAngle[1] = (EyeAngles[1] + 180);
		RedPortalAngle[2] = NULL_VECTOR[2];

		//make portal ent
		new Red = CreateEntityByName("prop_physics_override");

		DispatchKeyValue( Red, "model", g_PortalMDL);
		DispatchKeyValue( Red, "name", "RedTeleport");
		DispatchKeyValue( Red, "Solid", "6");
		DispatchKeyValueVector( Red, "Origin", RedPortalOrigin );
		DispatchKeyValueVector( Red, "Angles", RedPortalAngle );
		DispatchSpawn(Red);
		AcceptEntityInput(Red, "EnableCollision");

		//portal visual effects
		SetEntityMoveType(Red, MOVETYPE_NONE);
		SetEntityRenderMode(Red, RENDER_NORMAL);
		SetEntityRenderFx(Red, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(Red, 245, 30, 10, 255);

		//start hook and show it
		SDKHook(Red, SDKHook_Touch, TouchRed);
		PrintToChat(client,"Red Portal Spawned");
		cred[client] = Red;
		bluetred[cblue[client]] = Red;
		redtblue[Red] = cblue[client];
		return Plugin_Handled;
	}

	//if red and blue create so need to delete it
	else if (cblue[client] !=0 && cred[client] !=0)
	{
		if (IsValidEdict(cblue[client]))
		{
			bluetred[cblue[client]] =0;
			SDKUnhook(cblue[client], SDKHook_Touch, TouchBlue);
			RemoveEdict(cblue[client]);
		}
		if (IsValidEdict(cred[client]))
		{
			redtblue[cred[client]] =0;
			SDKUnhook(cred[client], SDKHook_Touch, TouchRed);
			RemoveEdict(cred[client]);
		}
		cblue[client] =0;
		cred[client] =0;
	}
	return Plugin_Continue;
}

//same as TouchRed
public Action:TouchBlue(entity, other)
{
	if (g_noBots)
	{
		if (IsFakeClient(other))
		{
			return Plugin_Handled;
		}
	}

	if (BlockWorld(other))
	{
		return Plugin_Handled;
	}
	
	if (g_noProps)
	{
		if ((other >= MAXPLAYERS))
		{
			return Plugin_Handled;
		}
	}
	if (bluetred[entity] ==0 || !IsValidEdict(bluetred[entity]))
	{
		EmitSoundToAll(g_sndPortalERROR, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		PrintToChat(other,"Error! Red Portal not exist");
		return Plugin_Handled;
	}
	new pitchX = GetRandomInt(60, 180);
	EmitSoundToAll(g_sndPortalFX, entity, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 40, -1, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(g_sndPortalGO, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitchX, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	decl Float:RedClientOrigin[3];
	decl Float:RedClientAngle[3];
	decl Float:PlayerVec[3];
	decl Float:PlayerAng[3];
	GetEntPropVector(bluetred[entity], Prop_Data, "m_vecOrigin", PlayerVec);
	GetEntPropVector(bluetred[entity], Prop_Data, "m_angRotation", PlayerAng);
	RedClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
	RedClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
	RedClientOrigin[2] = (PlayerVec[2] + 10);

	RedClientAngle[0] = PlayerAng[0];
	RedClientAngle[1] = PlayerAng[1];
	RedClientAngle[2] = PlayerAng[2];

	if (other <= MAXPLAYERS)
	{
		ShowParticle(PlayerVec, "electrical_arc_01_system", 5.0);
		ScreenFade(other, 255, 255, 255, 255, 50, 1);
	}

	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderFx(entity, RENDERFX_STROBE_FASTER);
	SetEntityRenderColor(entity, 255, 255, 255, 200);
	CreateTimer(3.0, ResetRed, entity);
	TeleportEntity(other, RedClientOrigin, RedClientAngle, RedClientOrigin);
	return Plugin_Continue;
}

public Action:TouchRed(entity, other)
{
	//nobots ?
	if (g_noBots)
	{
		if (IsFakeClient(other))
		{
			//it's bot so.. get off
			return Plugin_Handled;
		}
	}
	//noprops
	if (g_noProps)
	{
		if ((other >= MAXPLAYERS))
		{
			return Plugin_Handled;
		}
	}
	
	if (BlockWorld(other))
	{
		return Plugin_Handled;
	}
	
	//if that client or bots alowed, do stuff
	if (redtblue[entity] ==0 || !IsValidEdict(redtblue[entity])){
		EmitSoundToAll(g_sndPortalERROR, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
		PrintToChat(other,"Error! Blue Portal not exist");
		return Plugin_Handled;
	}
	//pitch effect
	new pitchX = GetRandomInt(60, 180);
	EmitSoundToAll(g_sndPortalFX, entity, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, SND_NOFLAGS, SNDVOL_NORMAL, 40, -1, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(g_sndPortalGO, other, SNDCHAN_REPLACE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, pitchX, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);

	//some math stuff
	decl Float:BlueClientOrigin[3];
	decl Float:BlueClientAngle[3];
	decl Float:PlayerVec[3];
	decl Float:PlayerAng[3];
	GetEntPropVector(redtblue[entity], Prop_Data, "m_vecOrigin", PlayerVec);
	GetEntPropVector(redtblue[entity], Prop_Data, "m_angRotation", PlayerAng);
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
	CreateTimer(3.0, ResetBlue, entity);
	TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
	return Plugin_Continue;
}


//Timers
//Functions
//etc
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	/* Show particle effect you like */
	new particle = CreateEntityByName("info_particle_system");
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

public PrecacheParticle(String:particlename[])
{
	/* Precache particle */
	new particle = CreateEntityByName("info_particle_system");
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

public Action:DeleteParticles(Handle:timer, any:particle)
{
	/* Delete particle */
	if (IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		RemoveEdict(particle);
	}
}

public Action:ResetRed(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 6);
		SetEntityRenderFx(entity, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(entity, 50, 100, 250, 255);
	}
}

stock GetCollisionPoint(client, Float:pos[3])
{
	decl Float:vOrigin[3], Float:vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);

		return;
	}

	CloseHandle(trace);
}

public Action:ResetBlue(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))
	{
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 6);
		SetEntityRenderFx(entity, RENDERFX_PULSE_FAST);
		SetEntityRenderColor(entity, 245, 30, 10, 255);
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target);
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
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

stock GetRealClientCount( bool:inGameOnly = true ) {
	new clients = 0;
	for( new i = 1; i <= GetMaxClients(); i++ ) {
		if( ( ( inGameOnly ) ? IsClientInGame( i ) : IsClientConnected( i ) ) && !IsFakeClient( i ) ) {
			clients++;
		}
	}
	return clients;
}

InitPrecache()
{
	GetConVarString(cv_PortalMDL, g_PortalMDL, sizeof(g_PortalMDL));
	GetConVarString(cv_particle, g_particle, sizeof(g_particle));
	GetConVarString(cv_sndPortalGO, g_sndPortalGO, sizeof(g_sndPortalGO));
	GetConVarString(cv_sndPortalERROR, g_sndPortalERROR, sizeof(g_sndPortalERROR));
	GetConVarString(cv_sndPortalFX, g_sndPortalFX, sizeof(g_sndPortalFX));

	PrecacheModel(g_PortalMDL, true);
	PrecacheParticle(g_particle);
	PrecacheSound(g_sndPortalGO, true);
	PrecacheSound(g_sndPortalERROR, true);
	PrecacheSound(g_sndPortalFX, true);
}

BlockWorld(other)
{
	decl String:m_ModelName[PLATFORM_MAX_PATH];

	if (other == -1)
	{
		return true;
	}
	
	if (!IsValidEntity (other))
	{
		return true;
	}

	GetEntPropString(other, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	
	if (StrContains(m_ModelName, "*") != -1)
	{			
		return true;
	}
	return false;
}