#pragma semicolon 1
#include <sourcemod>
#include <sdktools>


new Sprite1;
new Sprite2;
new Handle:g_isEnabled = INVALID_HANDLE;
new Handle:g_givetime = INVALID_HANDLE;
new Handle:s_timer = INVALID_HANDLE;

new Float:myPos[3];
new Float:myAng[3];
new Float:trsPos[3];
new Float:trsPos002[3];


public Plugin:myinfo = 
{
	name = "[l4d2]knife shoot",
	author = "AK978",
	version = "1.5"
}

public OnPluginStart()
{
	g_isEnabled = CreateConVar("sm_knifeshoot_enable", "1", "(1 = ON ; 0 = OFF)", 0);
	g_givetime = CreateConVar("sm_knife_give_time", "2.0", "knife give time", 0);
}

public void OnMapStart()
{
	Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
	Sprite2 = PrecacheModel("materials/sprites/glow.vmt");
	
	PrecacheModel("models/props_junk/propanecanister001a.mdl", true);
}

public OnMapEnd()
{
	if (s_timer != INVALID_HANDLE)
	{
		KillTimer(s_timer);
		s_timer = INVALID_HANDLE;
	}
}

public Action:getpos(client)
{
	GetClientEyePosition(client, myPos);
	GetClientEyeAngles(client, myAng);
	new Handle:trace = TR_TraceRayFilterEx(myPos, myAng, CONTENTS_SOLID|CONTENTS_MOVEABLE, RayType_Infinite, TraceEntityFilterPlayer, client);

	if(TR_DidHit(trace))
		TR_GetEndPosition(trsPos, trace);

	CloseHandle(trace);
	
	for(new i = 0; i < 3; i++)
		trsPos002[i] = trsPos[i];

	decl Float:tmpVec[3];
	SubtractVectors(myPos, trsPos, tmpVec);
	NormalizeVector(tmpVec, tmpVec);
	ScaleVector(tmpVec, 36.0);
	SubtractVectors(myPos, tmpVec, trsPos);
		
	return;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{
	if (g_isEnabled)
	{
		if (iButtons == 2048)
		{
			 CreateTimer(0.1, CheckShoot, iClient);
		}		
	}
}

public Action:CheckShoot(Handle:timer, any:client)
{	
	new buttons;
	buttons = GetClientButtons(client);
		
	if(buttons & IN_ATTACK2)	
	{
		if (IsSurvivor(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{		
			if (CheckWeapon(client))
			{
				getpos(client);				
				laszer(client);			
				giveknife(client);					
			}
		}
	}
	return Plugin_Continue;
}


laszer(client)
{
	//創造雷射光線					
	new Float:PlayerOrigin[3];
	new Float:TeleportOrigin[3];
	GetCollisionPoint(client, PlayerOrigin);
	TeleportOrigin[0] = PlayerOrigin[0];
	TeleportOrigin[1] = PlayerOrigin[1];
	TeleportOrigin[2] = (PlayerOrigin[2] + 4);
	TE_SetupBeamPoints(myPos, TeleportOrigin, Sprite1, Sprite2, 0, 0, 1.0, 1.0, 1.0, 1, 0.0, {0,255,0,255}, 0);
	TE_SendToAll();

	// 創造爆炸，殺死感染，傷害特殊感染/倖存者，推動物理實體。			
	new entity = CreateEntityByName("prop_physics");
	DispatchKeyValue(entity, "model", "models/props_junk/propanecanister001a.mdl");
	DispatchSpawn(entity);
	SetEntData(entity, GetEntSendPropOffs(entity, "m_CollisionGroup"), 1, 1, true);
	TeleportEntity(entity, TeleportOrigin, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(entity, "break");
}

giveknife(client)
{
	//爆炸後移除小刀
	RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
	s_timer = CreateTimer(GetConVarFloat(g_givetime), buyknife, client);
}


bool CheckWeapon(int client)
{
	decl String:weapon[64];

	GetClientWeapon(client, weapon, sizeof(weapon));
	
	if(StrEqual(weapon, "weapon_melee"))
	{
		new g_weapon = GetPlayerWeaponSlot(client, 1);
		if (IsValidEntity(g_weapon))
		{
			GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_strMapSetScriptName", weapon, sizeof(weapon));		
			if (StrEqual(weapon, "knife"))
			{
				return true;
			}
		}
	}
	return false;
}

bool IsSurvivor(int client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}

public Action:buyknife(Handle:timer, any:client)
{
	BypassAndExecuteCommand(client, "give", "knife");
	s_timer = INVALID_HANDLE;
}

stock BypassAndExecuteCommand(client, String: strCommand[], String: strParam1[])
{
	new flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
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

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}