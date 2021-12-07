#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "2304"
#define HOMING_ROCKETS_MAX 64

//////////////////////////////////////////////////
public Plugin:myinfo = 
{
	name = "TF2 Homing Rocket",
	author = "Leonardo",
	description = "N/A",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

//////////////////////////////////////////////////
// controls
new bool:g_ActiveHoming[MAXPLAYERS+1] = false;
// homing
new g_RocketsData[MAXPLAYERS+1][HOMING_ROCKETS_MAX];
new Handle:g_RocketFunc[MAXPLAYERS+1][HOMING_ROCKETS_MAX];
// cvars
new Handle:g_IsPluginOn = INVALID_HANDLE;
new Handle:g_IsDebugOn = INVALID_HANDLE;
new Handle:g_Accuracy = INVALID_HANDLE;
new Handle:g_AdminAccess = INVALID_HANDLE;
new Handle:g_ForceHoming = INVALID_HANDLE;
new Handle:g_ShowAim = INVALID_HANDLE;
// models
new g_bglow; // blue glow model
new g_rglow; // red glow model

//////////////////////////////////////////////////
public OnPluginStart()
{
	CreateConVar("sm_homingrocket", PLUGIN_VERSION, "Version of Homing Rockets", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_IsPluginOn = CreateConVar("sm_hr_enable","1","Enable/Disable Plugin (0 = disabled | 1 = enabled)", _, true, 0.0, true, 1.0);
	g_IsDebugOn = CreateConVar("sm_hr_debug","0","Enable/Disable Debug Mode (0 = disabled | 1 = enabled)", _, true, 0.0, true, 1.0);
	g_Accuracy = CreateConVar("sm_hr_accuracy", "1", "Homing start accuracy (0-10)", _, true, 0.0, true, 10.0);
	g_AdminAccess = CreateConVar("sm_hr_adminflag", "", "Admins Flag for access; make it empty to turn off.");
	g_ForceHoming = CreateConVar("sm_hr_forcehoming", "0", "Force homing on (1) or not (0).", _, true, 0.0, true, 1.0);
	g_ShowAim = CreateConVar("sm_hr_showaim", "1", "Show (1) dot on aim or not (0).", _, true, 0.0, true, 1.0);
}

//////////////////////////////////////////////////
public OnGameFrame()
{
	static bool:bPressed[65] = { false , ... };
	for (new client = 1; client <= MaxClients; client++)
	{
		if( IsClientInGame(client) && IsPlayerAlive(client) )
		{
			new String:playerWeapon[32];
			GetClientWeapon(client, playerWeapon, sizeof(playerWeapon));
			if( StrContains(playerWeapon, "tf_weapon_rocketlauncher", false) != -1 )
			{
				if(GetConVarInt(g_ShowAim)==1 && !TF2_HasCond(client, 7))
					if(g_ActiveHoming[client] || GetConVarInt(g_ForceHoming)==1)
					{
						new Float:TargetPos[3];
						GetPlayerEye(client, TargetPos);
						if(GetClientTeam(client)==2)
							TE_SetupGlowSprite( TargetPos, g_rglow, 0.1, 0.17, 75 );
						else
							TE_SetupGlowSprite( TargetPos, g_bglow, 0.1, 0.17, 25 );
						TE_SendToAll();
					}
				
				
				if(GetConVarInt(g_ForceHoming)==0)
					if(GetClientButtons(client) & IN_ATTACK2)
					{
						if(!bPressed[client])
						{
							if( GetConVarInt(g_IsDebugOn)>0 )
								PrintToServer("Activating: %N; status: %d",client,g_ActiveHoming[client]);
							g_ActiveHoming[client] = !g_ActiveHoming[client];
						}
						bPressed[client] = true;
					}
					else
						bPressed[client] = false;
			}
		}
	}
}

//////////////////////////////////////////////////
public OnMapStart()
{
	g_bglow = PrecacheModel("sprites/blueglow1.vmt");
	g_rglow = PrecacheModel("sprites/redglow1.vmt");
	for(new i = 1; i <= MAXPLAYERS; i++)
		g_ActiveHoming[i] = false;
}

//////////////////////////////////////////////////
public OnEntityCreated(entity, const String:classname[])
{
	if( GetConVarInt(g_IsPluginOn)>0 )
		if(StrEqual(classname,"tf_projectile_rocket"))
			SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);
}

//////////////////////////////////////////////////
public Hook_OnEntitySpawn(entity)
{
	if( GetConVarInt(g_IsPluginOn)>0 )
	{
		new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		decl bool:registered;
		registered = false;
		for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
			if(!registered)
				if(g_RocketsData[iOwner][i] != entity)
					registered = false;
				else
					registered = true;
		if(!registered)
			for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				if(!registered)
					if(g_RocketsData[iOwner][i] == 0)
					{
						g_RocketsData[iOwner][i] = entity;
						g_RocketFunc[iOwner][i] = CreateTimer(0.0005, Timer_RocketCheck, entity, TIMER_REPEAT);
						if( GetConVarInt(g_IsDebugOn)>0 )
							PrintToServer("Rocket's ID: %d; owner: %N (created)",entity,iOwner);
						registered = true;
					}
	}
}

//////////////////////////////////////////////////
public OnEntityDestroyed(entity)
{
	new String:className[32];
	GetEdictClassname(entity, className, sizeof(className));
	if(StrEqual(className,"tf_projectile_rocket"))
	{
		new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if( GetConVarInt(g_IsDebugOn)>0 )
			PrintToServer("Rocket's ID: %d; owner: %N (destroyed)",entity,iOwner);
		if(iOwner>0)
			for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
				if(g_RocketsData[iOwner][i] == entity)
				{
					g_RocketsData[iOwner][i] = 0;
					if(g_RocketFunc[iOwner][i] != INVALID_HANDLE)
						KillTimer(g_RocketFunc[iOwner][i]);
					g_RocketFunc[iOwner][i] = INVALID_HANDLE;
				}
	}
}

//////////////////////////////////////////////////
public Action:Timer_RocketCheck(Handle:timer, any:entity)
{
	if( GetConVarInt(g_IsPluginOn)>0 )
		if(IsValidEntity(entity))
		{
			new iOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
			if( ( iOwner > 0 ) && ( iOwner < MAXPLAYERS ) )
			{
				new curRocket = 0;
				for(new i = 0; i < HOMING_ROCKETS_MAX; i++)
					if(g_RocketsData[iOwner][i] == entity)
						curRocket = i;
				
				if( g_RocketFunc[iOwner][curRocket] != INVALID_HANDLE)
				{
					if( GetConVarInt(g_IsDebugOn)>0 )
						PrintToServer("Rocket's ID: %d; owner: %N (checked) (homing is %d)",entity,iOwner,(g_ActiveHoming[iOwner] || GetConVarInt(g_ForceHoming)==1));
					
					new bool:access;
					access = true;
					new String:sAAFlags[16];
					GetConVarString(g_AdminAccess,sAAFlags,sizeof(sAAFlags));
					if(strlen(sAAFlags)>0)
					{
						new fAAFlags = ReadFlagString(sAAFlags);
						if ( !(GetUserFlagBits(iOwner) & fAAFlags) )
							access = false;
					}
					
					if( IsClientInGame(iOwner) && IsPlayerAlive(iOwner) && access )
					{
						new String:playerWeapon[32];
						GetClientWeapon(iOwner, playerWeapon, sizeof(playerWeapon));
						if ( (StrContains(playerWeapon, "tf_weapon_rocketlauncher", false) != -1) && ( g_ActiveHoming[iOwner] || GetConVarInt(g_ForceHoming)==1 ) )
						{
							new Float:RocketPos[3];
							new Float:RocketAng[3];
							new Float:RocketVec[3];
							new Float:TargetPos[3];
							new Float:TargetVec[3];
							new Float:MiddleVec[3];
							
							GetPlayerEye(iOwner, TargetPos);
							
							GetEntPropVector( entity, Prop_Data, "m_vecAbsOrigin", RocketPos );
							GetEntPropVector( entity, Prop_Data, "m_angRotation", RocketAng );
							GetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", RocketVec );

							new Float:RocketSpeed = GetVectorLength( RocketVec );
							SubtractVectors( TargetPos, RocketPos, TargetVec );
							
							if ( GetConVarInt(g_Accuracy)==0 )
								NormalizeVector( TargetVec, RocketVec );
							else
							{
								if ( GetConVarInt(g_Accuracy)==1 )
									AddVectors( RocketVec, TargetVec, RocketVec );
								else if ( GetConVarInt(g_Accuracy)==2 )
								{
									AddVectors( RocketVec, TargetVec, MiddleVec );
									AddVectors( RocketVec, MiddleVec, RocketVec );
								}
								else //if ( GetConVarInt(g_Accuracy)>=3 )
								{
									AddVectors( RocketVec, TargetVec, MiddleVec );
									for( new j=0; j < GetConVarInt(g_Accuracy)-2; j++ )
										AddVectors( RocketVec, MiddleVec, MiddleVec );
									AddVectors( RocketVec, MiddleVec, RocketVec );
								}
								NormalizeVector( RocketVec, RocketVec );
							}
							
							GetVectorAngles( RocketVec, RocketAng );
							SetEntPropVector( entity, Prop_Data, "m_angRotation", RocketAng);

							ScaleVector( RocketVec, RocketSpeed );
							SetEntPropVector( entity, Prop_Data, "m_vecAbsVelocity", RocketVec );
						}
					}
				}
				else
				{
					g_RocketsData[iOwner][curRocket] = 0;
					if(g_RocketFunc[iOwner][curRocket] != INVALID_HANDLE)
						KillTimer(g_RocketFunc[iOwner][curRocket]);
					g_RocketFunc[iOwner][curRocket] = INVALID_HANDLE;
				}
			}
		}
}

//////////////////////////////////////////////////
bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	if(entity > GetMaxClients())
	{
		decl String:sClassname[128];
		GetEdictClassname(entity, sClassname, sizeof(sClassname));
		if(StrEqual(sClassname, "func_respawnroomvisualizer", false))
			return false;
		else
			return true;
	}
	else
		return false;
}

stock bool:TF2_HasCond(iClient, iCondBit=0)
{
	if( iClient>0 && iClient<=MaxClients && IsValidEdict(iClient) )
	{
		new iCondBits = GetEntProp(iClient, Prop_Send, "m_nPlayerCond");
		return (iCondBits>=0 && iCondBit>=0 ? ((iCondBits & (1 << iCondBit)) != 0) : false);
	}
	return false;
}