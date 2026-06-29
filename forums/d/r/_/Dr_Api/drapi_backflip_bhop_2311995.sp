/*     <DR.API BACKFLIP> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                   <DR.API BACKFLIP> is licensed under a                   */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*  work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.  */
//***************************************************************************//
//***************************************************************************//
//******************************DR.API BACKFLIP******************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.1"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[BACKFLIP] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <autoexec>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_backflip_dev;

Handle cvar_backflip_jump_apogee_timer;
Handle cvar_backflip_jump_apogee;
Handle cvar_backflip_jump_timer;
Handle cvar_backflip_rotation;

//Bool
bool B_cvar_active_backflip_dev								= false;

bool AllowToFlip[MAXPLAYERS + 1]							= false;
bool AllowToJump[MAXPLAYERS + 1]							= false;

//Floats
float F_backflip_jump_apogee_timer;
float F_backflip_jump_timer;
float F_backflip_jump_apogee;
float F_backflip_rotation;

float JumpHeight[MAXPLAYERS + 1];
float JumpHeightTimer[MAXPLAYERS + 1];
float TimerJump[MAXPLAYERS + 1];
float TimerDoublePressKeyJump[MAXPLAYERS + 1];
float F_Clone_Angles[MAXPLAYERS + 1][3];

//Char
char S_InvisibleModel[PLATFORM_MAX_PATH]					= "models/player/ct_animations.mdl";
char S_Client_Model[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

//Customs
int degres[MAXPLAYERS + 1]									= 0;
int GetFlipRotation;
int C_iClone[MAXPLAYERS + 1];
int LastButton[MAXPLAYERS + 1];


//Informations plugin
public Plugin myinfo =
{
	name = "DR.API BACKFLIP",
	author = "Dr. Api",
	description = "DR.API BACKFLIP by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://doyou.watch"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	AutoExecConfig_SetFile("drapi_backflip", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_backflip_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_backflip_dev					= AutoExecConfig_CreateConVar("drapi_active_backflip_dev", 					"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_backflip_jump_apogee_timer				= AutoExecConfig_CreateConVar("drapi_backflip_jump_apogee_timer", 			"0.19", 				"Timer to get height position", 		DEFAULT_FLAGS);
	cvar_backflip_jump_apogee					= AutoExecConfig_CreateConVar("drapi_backflip_jump_apogee", 				"40.0", 				"Min. Height to allow Flip", 			DEFAULT_FLAGS);
	cvar_backflip_jump_timer					= AutoExecConfig_CreateConVar("drapi_backflip_jump_timer", 					"1.0", 					"Timer between each jump", 				DEFAULT_FLAGS);
	cvar_backflip_rotation						= AutoExecConfig_CreateConVar("drapi_backflip_rotation", 					"15.0", 					"Roation angle", 						DEFAULT_FLAGS);
	
	HookEvent("player_jump", 		Event_PlayerJump);
	HookEvent("player_footstep", 	Event_PlayerFootstep);
	HookEvent("player_death", 		Event_PlayerDeath);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_backflip_dev, 				Event_CvarChange);
	
	HookConVarChange(cvar_backflip_jump_apogee_timer, 		Event_CvarChange);
	HookConVarChange(cvar_backflip_jump_apogee, 			Event_CvarChange);
	HookConVarChange(cvar_backflip_jump_timer, 				Event_CvarChange);
	HookConVarChange(cvar_backflip_rotation, 				Event_CvarChange);
}

/***********************************************************/
/******************** WHEN CVARS CHANGE ********************/
/***********************************************************/
public void Event_CvarChange(Handle cvar, const char[] oldValue, const char[] newValue)
{
	UpdateState();
}

/***********************************************************/
/*********************** UPDATE STATE **********************/
/***********************************************************/
void UpdateState()
{
	B_cvar_active_backflip_dev 					= GetConVarBool(cvar_active_backflip_dev);
	
	F_backflip_jump_apogee_timer 				= GetConVarFloat(cvar_backflip_jump_apogee_timer);
	F_backflip_jump_apogee 						= GetConVarFloat(cvar_backflip_jump_apogee);
	F_backflip_jump_timer 						= GetConVarFloat(cvar_backflip_jump_timer);
	F_backflip_rotation 						= GetConVarFloat(cvar_backflip_rotation);
}

/***********************************************************/
/******************* WHEN CONFIG EXECUTED ******************/
/***********************************************************/
public void OnConfigsExecuted()
{
	//UpdateState();
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
}

/***********************************************************/
/******************** WHEN PLAYER WALK *********************/
/***********************************************************/
public void Event_PlayerFootstep(Handle event, char[] error, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	AllowToFlip[client] = false;
	degres[client] 		= 0;
}

/***********************************************************/
/******************** WHEN PLAYER JUMP *********************/
/***********************************************************/
public void Event_PlayerJump(Handle event, char[] error, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//int knife_owner 		= GetPlayerWeaponSlot(client, 2);
	//int weapon_owner		= GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	AllowToFlip[client] = false;
	
	if(IsAdminEx(client) /*&& weapon_owner != knife_owner*/)	
	{
		TimerDoublePressKeyJump[client] = GetEngineTime();
		LastButton[client]				= GetClientButtons(client);
		
		//if(AllowToJump[client])
		{
			float F_Origin[3];
			GetClientAbsOrigin(client, F_Origin);
			JumpHeight[client] = F_Origin[2];
			CreateTimer(F_backflip_jump_apogee_timer, Timer_GetJumpHeight, GetClientUserId(client));
			AllowToJump[client] = false;
			if(B_cvar_active_backflip_dev)
			{
				PrintToChat(client, "%s AllowToJump", TAG_CHAT);
			}
		}
		
		if(B_cvar_active_backflip_dev)
		{
			PrintToChat(client, "%s Event_PlayerJump", TAG_CHAT);
		}
	}
}

/***********************************************************/
/******************* WHEN PLAYER DEATH *********************/
/***********************************************************/
public void Event_PlayerDeath(Handle event, char[] error, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClearClone(client);
}
	
/***********************************************************/
/**************** TIMER GET HEIGHT APOGEE ******************/
/***********************************************************/
public Action Timer_GetJumpHeight(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	float F_Origin[3];
	GetClientAbsOrigin(client, F_Origin);
	JumpHeightTimer[client] = F_Origin[2];
	
	float apogee = JumpHeightTimer[client] - JumpHeight[client];
	float now = GetEngineTime();
	if(apogee > F_backflip_jump_apogee && now >= TimerJump[client])
	{
		float F_Velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", F_Velocity);
		
		F_Velocity[2] += 0.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, F_Velocity);
		
		AllowToFlip[client] = true;
		TimerJump[client] = now + F_backflip_jump_timer;
			
		if(B_cvar_active_backflip_dev)
		{
			PrintToChatAll("%s Allow Jump", TAG_CHAT);
		}
	}
	else
	{
		AllowToFlip[client] = false;
		
		if(B_cvar_active_backflip_dev)
		{
			PrintToChatAll("%s Disallow Jump", TAG_CHAT);
		}
	}
	
	if(B_cvar_active_backflip_dev)
	{
		PrintToChatAll("%s Height: %f - %f = %f", TAG_CHAT, JumpHeightTimer[client], JumpHeight[client], apogee);
	}
}

/***********************************************************/
/********************** ON GAME FRAME **********************/
/***********************************************************/
public void OnGameFrame()
{
	for (int i = 1; i <= MAXPLAYERS+1; i++)
	{
		if(Client_IsIngame(i) && !IsFakeClient(i) && IsAdminEx(i))
		{
			int buttons = GetClientButtons(i);
			
			if((buttons & IN_JUMP) && !(LastButton[i] & IN_JUMP))
			{
				float time = GetEngineTime();
				if(TimerDoublePressKeyJump[i] < time)
				{
					AllowToJump[i] = true;
				}
				else if(TimerDoublePressKeyJump[i] >= time + 0.2)
				{
					AllowToJump[i] = false;
				}
			}
			LastButton[i] = buttons;
		}
	}
}
/***********************************************************/
/****************** WHEN PLAYER HOLD KEYS ******************/
/***********************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{

	if(Client_IsIngame(client) && !IsFakeClient(client) && IsAdminEx(client))
	{
		if(!(GetEntityFlags(client) & FL_ONGROUND) && AllowToFlip[client])
		{
			SetBackFlip(client);
			SetWeaponsRender(client, RENDER_NONE);
			
		}
		else if((GetEntityFlags(client) & FL_ONGROUND))
		{
			ClearClone(client);
			SetWeaponsRender(client, RENDER_NORMAL);
		}
	}

}

/***********************************************************/
/********************** SET BACK FLIP **********************/
/***********************************************************/
void SetBackFlip(int client)
{
	if(IsValidEntRef(C_iClone[client]))
	{
		RotateClone(client, C_iClone[client]);
	}
	else
	{
		GetClientModel(client, S_Client_Model[client], PLATFORM_MAX_PATH); 
		CreateClone(client, S_Client_Model[client]);
		GetFlipRotation = GetRandomInt(0, 1);
	}
	
}

/***********************************************************/
/***************** SET RENDERMODE WEAPONS ******************/
/***********************************************************/
void SetWeaponsRender(int client, RenderMode Mode)
{
	int knife 		= GetPlayerWeaponSlot(client, CS_SLOT_KNIFE);
	int primary 	= GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	int secondary 	= GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	
	if(knife != -1)
	{
		SetEntityRenderMode(knife , 	Mode);
	}
	
	if(primary != -1)
	{
		SetEntityRenderMode(primary , 	Mode);
	}
	
	if(secondary != -1)
	{
		SetEntityRenderMode(secondary , Mode);
	}
}
/***********************************************************/
/********************** CREATE CLONE ***********************/
/***********************************************************/
void CreateClone(int client, char[] model)
{
	int ent = CreateEntityByName("prop_dynamic_override");
	if (ent == -1)
	{
		return;
	}
	
	if (!IsModelPrecached(S_InvisibleModel))
	{
    	if(!PrecacheModel(S_InvisibleModel))
    	{
    		return;
    	}
    }
	
	SetEntityModel(ent, model);
	SetEntityModel(client, S_InvisibleModel);
	
	//DispatchKeyValue(ent, "model", model);
	
	DispatchSpawn(ent);
	
	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	
	SetVariantString("Hop");
	AcceptEntityInput(ent, "SetAnimation", -1, -1, 0); 
	
	float pos[3], angle[3];
	GetClientAbsOrigin(client, pos);
	GetClientEyeAngles(client, angle);
	
	float Direction[3], AmmoPos[3];
	Direction[0] = pos[0];
	Direction[1] = pos[1];
	Direction[2] = pos[2];

	Handle Trace = TR_TraceRayFilterEx(pos, Direction, MASK_SOLID, RayType_EndPoint, TraceFilterAll, client);
	TR_GetEndPosition(AmmoPos, Trace);
	CloseHandle(Trace);
	
	TeleportEntity(ent, AmmoPos, angle, NULL_VECTOR);
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	SetVariantString(iTarget);
	AcceptEntityInput(ent, "SetParent");
	
	
	C_iClone[client] 	= EntIndexToEntRef(ent);
	
	GetEntPropVector(ent, Prop_Data, "m_angRotation", F_Clone_Angles[client]);
	F_Clone_Angles[client][0] = 0.0;
	
	
	SDKHook(ent, SDKHook_SetTransmit, ShouldHide);
	
	if(B_cvar_active_backflip_dev)
	{
		PrintToChatAll("%s prop: %s", TAG_CHAT, model);
	}
}

/***********************************************************/
/********************** SHOULD HIDE ************************/
/***********************************************************/
public Action ShouldHide(int ent, int client)
{
		int owner 				= GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int m_hObserverTarget 	= GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		
		if(IsValidEntRef(C_iClone[owner]) && owner == client)
		{
			if(m_hObserverTarget != 0)
			{
				return Plugin_Handled;
			}
		}
		
		return Plugin_Continue;
}

/***********************************************************/
/*********************** CLEAR CLONE ***********************/
/***********************************************************/
void ClearClone(int client)
{
	if(IsValidEntRef(C_iClone[client]))
	{
		RemoveEntity(C_iClone[client]);
		SetEntityModel(client, S_Client_Model[client]);
	}
	
	AllowToFlip[client] = false;
	degres[client] 		= 0;
}

/***********************************************************/
/********************** ROTATE CLONE ***********************/
/***********************************************************/
void RotateClone(int client, int entity)
{
	int clone = EntRefToEntIndex(entity);

	if(GetFlipRotation)
	{
		F_Clone_Angles[client][0] += F_backflip_rotation;
	}
	else
	{
		F_Clone_Angles[client][0] -= F_backflip_rotation;
	}
	
	degres[client] += RoundFloat(F_backflip_rotation);
	
	if(degres[client] < 360)
	{
		TeleportEntity(clone, NULL_VECTOR, F_Clone_Angles[client], NULL_VECTOR);
		if(B_cvar_active_backflip_dev)
		{
			//PrintToChatAll("%s rotate: %f, degres: %i", TAG_CHAT, F_Clone_Angles[client][0], degres[client]);
		}
	}
	else if(degres[client] >= 360)
	{
		RemoveEntity(C_iClone[client]);
		SetEntityModel(client, S_Client_Model[client]);
		
		AllowToFlip[client] 		= false;
		AllowToJump[client] 		= false;
		degres[client] 				= 0;
		F_Clone_Angles[client][0] 	= 0.0;

		if(B_cvar_active_backflip_dev)
		{
			//PrintToChatAll("%s degres: %i", TAG_CHAT, degres[client]);
		}
	}

}

/***********************************************************/
/********************** TRACE FILTER ***********************/
/***********************************************************/
public bool TraceFilterAll(int caller, int contentsMask, any SphereNum)
{
	char modelname[128];
	GetEntPropString(caller, Prop_Data, "m_ModelName", modelname, 128);
	
	char checkclass[64];
	GetEdictClassname(caller, checkclass,sizeof(checkclass));
	
	return !(StrEqual(checkclass, "player", false) ||(caller==SphereNum));
}

/***********************************************************/
/********************* REMOVE ENTITY ***********************/
/***********************************************************/
void RemoveEntity(int Ref)
{

	int entity = EntRefToEntIndex(Ref);
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
		//Ref = INVALID_ENT_REFERENCE;
	}
		
}

/***********************************************************/
/********************* IS VALID CLIENT *********************/
/***********************************************************/
stock bool Client_IsValid(int client, bool checkConnected=true)
{
	if (client > 4096) 
	{
		client = EntRefToEntIndex(client);
	}

	if (client < 1 || client > MaxClients) 
	{
		return false;
	}

	if (checkConnected && !IsClientConnected(client)) 
	{
		return false;
	}
	
	return true;
}

/***********************************************************/
/******************** IS CLIENT IN GAME ********************/
/***********************************************************/
stock bool Client_IsIngame(int client)
{
	if (!Client_IsValid(client, false)) 
	{
		return false;
	}

	return IsClientInGame(client);
}

/***********************************************************/
/****************** CHECK IF IS AN ADMIN *******************/
/***********************************************************/
stock bool IsAdminEx(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_CHANGEMAP 
	/*|| GetUserFlagBits(client) & ADMFLAG_RESERVATION*/
	|| GetUserFlagBits(client) & ADMFLAG_GENERIC
	|| GetUserFlagBits(client) & ADMFLAG_KICK
	|| GetUserFlagBits(client) & ADMFLAG_BAN
	|| GetUserFlagBits(client) & ADMFLAG_UNBAN
	|| GetUserFlagBits(client) & ADMFLAG_SLAY
	|| GetUserFlagBits(client) & ADMFLAG_CHANGEMAP
	|| GetUserFlagBits(client) & ADMFLAG_CONVARS
	|| GetUserFlagBits(client) & ADMFLAG_CONFIG
	|| GetUserFlagBits(client) & ADMFLAG_CHAT
	|| GetUserFlagBits(client) & ADMFLAG_VOTE
	|| GetUserFlagBits(client) & ADMFLAG_PASSWORD
	|| GetUserFlagBits(client) & ADMFLAG_RCON
	|| GetUserFlagBits(client) & ADMFLAG_CHEATS
	|| GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
} 

/***********************************************************/
/******************** IS VALID ENTITY **********************/
/***********************************************************/
stock bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}