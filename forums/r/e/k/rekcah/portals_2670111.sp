#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new bluepos[3];
new redpos[3];

new BluePortal = 0;
new RedPortal = 0;

new bool:PortalUseDelay = false;
new bool:PortalSeperated = false;
new bool:PortalsActive = false;

#define PORTAL_MDL "models/props_mall/mall_shopliftscanner.mdl"
#define PORTAL_SND "weapons/defibrillator/defibrillator_use.wav"

public OnPluginStart()
{
	RegConsoleCmd("sm_startportals", Start_Portal, "allow use of portals");
	RegConsoleCmd("sm_blue", Blue_Move, "move blue portal");
	RegConsoleCmd("sm_red", Red_Move, "move red portal");
	RegConsoleCmd("sm_killportals",Kill_Portal, "remove portals");
	
	HookEvent("round_end", Event_RoundChange)
	
}

public OnMapStart()
{
	PortalUseDelay = false;
	PortalSeperated = false;
	PortalsActive = false;
	PrecacheSound(PORTAL_SND);
}

public Event_RoundChange(Handle:event, String:name[], bool:dontBroadcast)
{
	PortalUseDelay = false;
	PortalSeperated = false;
	PortalsActive = false;
	
}

public Action:Start_Portal(client, args)
{
	if (!PortalsActive)
	{
		decl Float:pos[3];
		decl Float:ang[3];
		GetClientAbsOrigin(client, pos);
		GetClientEyeAngles(client, ang);
		
		ang[0] = NULL_VECTOR[0];
		ang[2] = NULL_VECTOR[2];

		BluePortal = EntIndexToEntRef(CreateEntityByName("prop_physics_override"));
		DispatchKeyValue( EntRefToEntIndex(BluePortal), "model", PORTAL_MDL);
		DispatchKeyValue( EntRefToEntIndex(BluePortal), "Solid", "6");
		DispatchKeyValueVector( EntRefToEntIndex(BluePortal), "Origin", pos );
		DispatchKeyValueVector( EntRefToEntIndex(BluePortal), "Angles", ang );
		DispatchSpawn(EntRefToEntIndex(BluePortal));
		//AcceptEntityInput(BluePortal, "EnableCollision");
		SetEntityMoveType(EntRefToEntIndex(BluePortal), MOVETYPE_NONE);
		SetEntityRenderColor(EntRefToEntIndex(BluePortal), 0, 0, 255, 200);
		SetGlowBlue(EntRefToEntIndex(BluePortal))
	
		SDKHook(EntRefToEntIndex(BluePortal), SDKHook_Touch, TouchBlue);
		
		RedPortal = EntIndexToEntRef(CreateEntityByName("prop_physics_override"));
		DispatchKeyValue( EntRefToEntIndex(RedPortal), "model", PORTAL_MDL);
		DispatchKeyValue( EntRefToEntIndex(RedPortal), "Solid", "6");
		DispatchKeyValueVector( EntRefToEntIndex(RedPortal), "Origin", pos );
		DispatchKeyValueVector( EntRefToEntIndex(RedPortal), "Angles", ang );
		DispatchSpawn(EntRefToEntIndex(RedPortal));
		//AcceptEntityInput(RedPortal, "EnableCollision");
		SetEntityMoveType(EntRefToEntIndex(RedPortal), MOVETYPE_NONE);
		SetEntityRenderColor(EntRefToEntIndex(RedPortal), 255, 0, 0, 200);
		SetGlowRed(EntRefToEntIndex(RedPortal))
		
		SDKHook(EntRefToEntIndex(RedPortal), SDKHook_Touch, TouchRed);
		
		PortalsActive = true;
	}
}

public Action:TouchBlue(entity, other)
{	
	// if portals arent indelay and have been seperated and are active
	if(!PortalUseDelay && PortalSeperated && PortalsActive && IsValidClient(other))
	{
	
		//PrintToChatAll("%i touch blue %N",entity,other);		
		
		decl Float:BlueClientOrigin[3];
		decl Float:BlueClientAngle[3];
		decl Float:PlayerVec[3];
		decl Float:PlayerAng[3];
		GetEntPropVector(EntRefToEntIndex(RedPortal), Prop_Data, "m_vecOrigin", PlayerVec);
		GetEntPropVector(EntRefToEntIndex(RedPortal), Prop_Data, "m_angRotation", PlayerAng);
		BlueClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[2] = (PlayerVec[2] + 10);

		BlueClientAngle[0] = PlayerAng[0];
		BlueClientAngle[1] = PlayerAng[1];
		BlueClientAngle[2] = PlayerAng[2];
	
		TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
		
		EmitSoundToAll(PORTAL_SND);
		
		CreateTimer(1.0, resetportal, 0, 0);
		PortalUseDelay = true;
	}
	
}

public Action:TouchRed(entity, other)
{
	// if portals arent indelay and have been seperated and are active
	if(!PortalUseDelay && PortalSeperated && PortalsActive && IsValidClient(other))
	{
		decl Float:BlueClientOrigin[3];
		decl Float:BlueClientAngle[3];
		decl Float:PlayerVec[3];
		decl Float:PlayerAng[3];
		GetEntPropVector(EntRefToEntIndex(BluePortal), Prop_Data, "m_vecOrigin", PlayerVec);
		GetEntPropVector(EntRefToEntIndex(BluePortal), Prop_Data, "m_angRotation", PlayerAng);
		BlueClientOrigin[0] = (PlayerVec[0] + 50 * Cosine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[1] = (PlayerVec[1] + 50 * Sine(DegToRad(PlayerAng[1])));
		BlueClientOrigin[2] = (PlayerVec[2] + 10);

		BlueClientAngle[0] = PlayerAng[0];
		BlueClientAngle[1] = PlayerAng[1];
		BlueClientAngle[2] = PlayerAng[2];
	
		TeleportEntity(other, BlueClientOrigin, BlueClientAngle, BlueClientOrigin);
		
		EmitSoundToAll(PORTAL_SND);
		
		CreateTimer(1.0, resetportal, 0, 0);
		PortalUseDelay = true;
	}
}

public Action:resetportal(Handle:hTimer, any:client)
{
	PortalUseDelay = false;
}

public Action:Blue_Move(client, args)
{
	decl Float:Pos[3];
	decl Float:Ang[3];
	
	if (GetNewPos(client,bluepos))
	{
		GetClientEyeAngles(client, Ang);
		Ang[0] = NULL_VECTOR[0];
		Ang[1] += 180;
		Ang[2] = NULL_VECTOR[2];
		TeleportEntity(EntRefToEntIndex(BluePortal) , bluepos, Ang, NULL_VECTOR);
		
		PortalSeperated = true;
	}
}

public Action:Red_Move(client, args)
{
	decl Float:Pos[3];
	decl Float:Ang[3];
		
	if (GetNewPos(client,redpos))
	{
		GetClientEyeAngles(client,Ang);
		Ang[0] = NULL_VECTOR[0];
		Ang[1] += 180;
		Ang[2] = NULL_VECTOR[2];
		TeleportEntity(EntRefToEntIndex(RedPortal) ,redpos, Ang, NULL_VECTOR);
		
		PortalSeperated = true;
	}
}

bool GetNewPos(client, Float:vecBuffer[3])
{
	decl Float:vPos[3];
	decl Float:vAng[3];
	
	decl Float:nPos[3];
	
	GetClientEyePosition(client,vPos);
	GetClientEyeAngles(client,vAng);
	
	new Handle:trace = TR_TraceRayFilterEx(vPos, vAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, client);

	if (TR_DidHit(trace))
	{
		//TR_GetEndPosition(vecBuffer, trace);
		TR_GetEndPosition(nPos, trace);
	
		if (GetVectorDistance(vPos, nPos) > 220)
		{	
			PrintCenterText(client,"out of range");
			return false;
		}
			vecBuffer[0]=nPos[0]
			vecBuffer[1]=nPos[1]
			vecBuffer[2]=nPos[2]

			CloseHandle(trace);
		return true;
	}
	return false;
}

public bool:TraceFilter(entity, contentsMask, any:client)
{
	if( entity == client )return false;
	return true;
}

SetGlowRed(gun)
{
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_iGlowType", 3);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRange", 0);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRangeMin", 1);
	new red=0;
	new gree=0;
	new blue=0;
		red=200;
		gree=0;
		blue=0;
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

SetGlowBlue(gun)
{
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_iGlowType", 3);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRange", 0);
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_nGlowRangeMin", 1);
	new red=0;
	new gree=0;
	new blue=0;
		red=0;
		gree=0;
		blue=200;
	
	SetEntProp(EntRefToEntIndex(gun), Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536));	
}

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}
public Action:Kill_Portal(client, args)
{
	if(PortalsActive)
	{
		AcceptEntityInput( EntRefToEntIndex(BluePortal) , "Kill" );
		AcceptEntityInput( EntRefToEntIndex(RedPortal) , "Kill" );
	
		PortalUseDelay = false;
		PortalSeperated = false;
		PortalsActive = false;
	}
}
public Plugin:myinfo =
{
	name = "Portals V2",
	author = "Spirit",
	description = "create improved portals",
	version = "1.0",
	url = "NONE"
}



