/*          <DR.API SKIN C.DRONE EFFECTS> (c) by <De Battista Clint          */
/*                                                                           */
/*             <DR.API SKIN C.DRONE EFFECTS> is licensed under a             */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//************************DR.API SKIN C.DRONE EFFECTS************************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[SKIN C.DRONE EFFECTS] -"
//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <store>

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_skin_collector_drone_efffects_dev;

Handle cvar_skin_collector_drone_efffects_red_min;
Handle cvar_skin_collector_drone_efffects_green_min;
Handle cvar_skin_collector_drone_efffects_blue_min;

Handle cvar_skin_collector_drone_efffects_red_max;
Handle cvar_skin_collector_drone_efffects_green_max;
Handle cvar_skin_collector_drone_efffects_blue_max;

Handle TimerSetColorSkin[MAXPLAYERS+1]									= INVALID_HANDLE;

//Bool
bool B_active_skin_collector_drone_efffects_dev										= false;

//Customs
int C_skin_collector_drone_efffects_red_min;
int C_skin_collector_drone_efffects_green_min;
int C_skin_collector_drone_efffects_blue_min;

int C_skin_collector_drone_efffects_red_max;
int C_skin_collector_drone_efffects_green_max;
int C_skin_collector_drone_efffects_blue_max;

int LightColor[MAXPLAYERS+1]											= INVALID_ENT_REFERENCE;
int droneEffect[MAXPLAYERS + 1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API SKIN C.DRONE EFFECTS",
	author = "Dr. Api",
	description = "DR.API SKIN C.DRONE EFFECTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	Store_RegisterHandler("droneeff", "", droneeff_OnMapStart, droneeff_Reset, droneeff_Config, droneeff_Equip, droneeff_Remove, true);
	AutoExecConfig_SetFile("drapi_skin_collector_drone_efffects", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_version", PLUGIN_VERSION, "Version", CVARS);
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("player_death", onPlayerDeath);
	cvar_active_skin_collector_drone_efffects_dev			= AutoExecConfig_CreateConVar("drapi_active_skin_collector_drone_efffects_dev", 			"0", 					"Enable/Disable Dev Mod", 				DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	cvar_skin_collector_drone_efffects_red_min					= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_red_min", 			"0", 					"Min. Red", 							DEFAULT_FLAGS);
	cvar_skin_collector_drone_efffects_green_min				= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_green_min", 			"0", 					"Min. Green", 							DEFAULT_FLAGS);	
	cvar_skin_collector_drone_efffects_blue_min					= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_blue_min", 			"150", 					"Min. Blue", 							DEFAULT_FLAGS);

	cvar_skin_collector_drone_efffects_red_max					= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_red_max", 			"150", 					"Max. Red", 							DEFAULT_FLAGS);
	cvar_skin_collector_drone_efffects_green_max				= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_green_max", 			"150", 					"Max. Green", 							DEFAULT_FLAGS);	
	cvar_skin_collector_drone_efffects_blue_max					= AutoExecConfig_CreateConVar("drapi_skin_collector_drone_efffects_blue_max", 			"255", 					"Max. Blue", 							DEFAULT_FLAGS);	
	
	HookEventsCvars();
	
	AutoExecConfig_ExecuteFile();
}

public Action:onPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new m_iEquipped = Store_GetEquippedItem(client, "droneeff");
	if (m_iEquipped < 0) {
		return Plugin_Continue;
	}
	droneEffect[client] = 1;
	return Plugin_Handled;
}

public Action:onPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	droneEffect[client] = 0;
	return Plugin_Handled;
}

public droneeff_OnMapStart()
{
}

public droneeff_Reset()
{
}

public droneeff_Config(&Handle:kv, itemid)
{
	Store_SetDataIndex(itemid, 0);
	return true;
}

public droneeff_Equip(client, id)
{
	droneEffect[client] = 1;
	return -1;
}

public droneeff_Remove(client, id)
{
	droneEffect[client] = 0;
}

/***********************************************************/
/************************ PLUGIN END ***********************/
/***********************************************************/
public void OnPluginEnd()
{
	int i = 1;
	while(i <= MaxClients)
	{
		if(IsClientInGame(i))
		{
			if(TimerSetColorSkin[i] != INVALID_HANDLE)
			{
				ClearTimer(TimerSetColorSkin[i]);
			}
			
			if(IsValidEntRef(LightColor[i]))
			{
				RemoveEntity(LightColor[i]);
			}
		}
		i++;
	}
}

/***********************************************************/
/***************** WHEN CLIENT DISCONNECT ******************/
/***********************************************************/
public void OnClientDisconnect(int client)
{
	droneEffect[client] = 0;
	if(TimerSetColorSkin[client] != INVALID_HANDLE)
	{
		ClearTimer(TimerSetColorSkin[client]);
	}
	
	if(IsValidEntRef(LightColor[client]))
	{
		RemoveEntity(LightColor[client]);
	}
	
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEventsCvars()
{
	HookConVarChange(cvar_active_skin_collector_drone_efffects_dev, 				Event_CvarChange);

	HookConVarChange(cvar_skin_collector_drone_efffects_red_min, 					Event_CvarChange);
	HookConVarChange(cvar_skin_collector_drone_efffects_green_min, 					Event_CvarChange);
	HookConVarChange(cvar_skin_collector_drone_efffects_blue_min, 					Event_CvarChange);
	
	HookConVarChange(cvar_skin_collector_drone_efffects_red_max, 					Event_CvarChange);
	HookConVarChange(cvar_skin_collector_drone_efffects_green_max, 					Event_CvarChange);
	HookConVarChange(cvar_skin_collector_drone_efffects_blue_max, 					Event_CvarChange);
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
	B_active_skin_collector_drone_efffects_dev 					= GetConVarBool(cvar_active_skin_collector_drone_efffects_dev);
	
	C_skin_collector_drone_efffects_red_min 					= GetConVarInt(cvar_skin_collector_drone_efffects_red_min);
	C_skin_collector_drone_efffects_green_min 					= GetConVarInt(cvar_skin_collector_drone_efffects_green_min);
	C_skin_collector_drone_efffects_blue_min 					= GetConVarInt(cvar_skin_collector_drone_efffects_blue_min);
	
	C_skin_collector_drone_efffects_red_max 					= GetConVarInt(cvar_skin_collector_drone_efffects_red_max);
	C_skin_collector_drone_efffects_green_max 					= GetConVarInt(cvar_skin_collector_drone_efffects_green_max);
	C_skin_collector_drone_efffects_blue_max 					= GetConVarInt(cvar_skin_collector_drone_efffects_blue_max);
	
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	UpdateState();
}

/***********************************************************/
/******************** ON GAME FRAME ************************/
/***********************************************************/
public void OnGameFrame()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			
			if(droneEffect[i] == 1)
			{
				if(TimerSetColorSkin[i] == INVALID_HANDLE)
				{
					TimerSetColorSkin[i] 	= CreateTimer(0.1, Timer_SetColorSkin, GetClientUserId(i), TIMER_REPEAT);
					LightColor[i]			= CreateLight(i);
				}
			}
			else
			{
				if(TimerSetColorSkin[i] != INVALID_HANDLE)
				{
					ClearTimer(TimerSetColorSkin[i]);
					SetEntityRenderColor(i, 255, 255, 255, 255);
				}
				
				if(IsValidEntRef(LightColor[i]))
				{
					RemoveEntity(LightColor[i]);
				}
			}
			
		}
		else
		{
			if(TimerSetColorSkin[i] != INVALID_HANDLE)
			{
				ClearTimer(TimerSetColorSkin[i]);
			}
			
			if(IsValidEntRef(LightColor[i]))
			{
				RemoveEntity(LightColor[i]);
			}
		}
	}
}

/***********************************************************/
/********************* CREATE LIGHT ************************/
/***********************************************************/
int CreateLight(int client)
{
	float pos[3];
	GetClientAbsOrigin(client, pos);
	int entity = CreateEntityByName("light_dynamic");
	
	if(IsValidEntity(entity))
	{
		char iTarget[16];
		Format(iTarget, 16, "client%d", client);
		DispatchKeyValue(client, "targetname", iTarget);
	
		DispatchKeyValue(entity, "brightness", "0");
		DispatchKeyValueFloat(entity, "spotlight_radius", 500.0);
		DispatchKeyValueFloat(entity, "distance", 500.0);
		DispatchKeyValue(entity, "_light", "255 255 255 50");
		DispatchKeyValue(entity, "style", "0");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "TurnOn");
		
		pos[0] += 10.0;
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		
		SetVariantString(iTarget);
		AcceptEntityInput(entity, "SetParent", entity, entity, 0);
	
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);
		return EntIndexToEntRef(entity);
	}
	return -1;
}

/***********************************************************/
/******************* SET SKIN COLOR ************************/
/***********************************************************/
public Action Timer_SetColorSkin(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	int red 	= GetRandomInt(C_skin_collector_drone_efffects_red_min, C_skin_collector_drone_efffects_red_max);
	int green 	= GetRandomInt(C_skin_collector_drone_efffects_green_min, C_skin_collector_drone_efffects_green_max);
	int blue 	= GetRandomInt(C_skin_collector_drone_efffects_blue_min, C_skin_collector_drone_efffects_blue_max);
	
	int color;
	color = red;
	color += 256 * green;
	color += 65536 * blue;
	
	if(IsValidEntity(LightColor[client]))
	{
		SetEntProp(LightColor[client], Prop_Send, 	"m_clrRender", color);
	}
	
	SetEntityRenderColor(client, red, green, blue, 255);
}

/***********************************************************/
/********************** CLEAR TIMER ************************/
/***********************************************************/
stock void ClearTimer(Handle &timer)
{
    if (timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }     
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

/***********************************************************/
/********************* REMOVE ENTITY ***********************/
/***********************************************************/
void RemoveEntity(int ref)
{

	int entity = EntRefToEntIndex(ref);
	if (entity != -1)
	{
		AcceptEntityInput(entity, "Kill");
		ref = INVALID_ENT_REFERENCE;
	}
		
}