/*        <DR.API GHOSTRIDER SKIN EFFECTS> (c) by <De Battista Clint         */
/*                                                                           */
/*           <DR.API GHOSTRIDER SKIN EFFECTS> is licensed under a            */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//**********************DR.API GHOSTRIDER SKIN EFFECTS***********************//
//***************************************************************************//
//***************************************************************************//

#pragma semicolon 1 

//***********************************//
//*************DEFINE****************//
//***********************************//
#define PLUGIN_VERSION 					"1.0.0"
#define CVARS 							FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define DEFAULT_FLAGS 					FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_CHAT						"[GHOSTRIDER SKIN EFFECTS] -"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <autoexec>
#include <sdkhooks>
#include <store>

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Customs
C_Flames[MAXPLAYERS+1];
int ghostEffect[MAXPLAYERS + 1];

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API GHOSTRIDER SKIN EFFECTS",
	author = "Dr. Api",
	description = "DR.API GHOSTRIDER SKIN EFFECTS by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}
/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	HookEvent("player_spawn", onPlayerSpawn);
	HookEvent("player_death", onPlayerDeath);
	Store_RegisterHandler("ghostridereff", "", ghostridereff_OnMapStart, ghostridereff_Reset, ghostridereff_Config, ghostridereff_Equip, ghostridereff_Remove, true);
	AutoExecConfig_SetFile("drapi_skin_ghostrider_effects", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("drapi_skin_ghostrider_effects_version", PLUGIN_VERSION, "Version", CVARS);
	
	AutoExecConfig_ExecuteFile();
	
	HookEvent("round_start", 	Event_RoundStart);
}

public Action:onPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new m_iEquipped = Store_GetEquippedItem(client, "ghostridereff");
	if (m_iEquipped < 0) {
		return Plugin_Continue;
	}
	ghostEffect[client] = 1;
	return Plugin_Handled;
}

public Action:onPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ghostEffect[client] = 0;
	return Plugin_Handled;
}

public ghostridereff_OnMapStart()
{
}

public ghostridereff_Reset()
{
}

public ghostridereff_Config(&Handle:kv, itemid)
{
	Store_SetDataIndex(itemid, 0);
	return true;
}

public ghostridereff_Equip(client, id)
{
	ghostEffect[client] = 1;
	return -1;
}

public ghostridereff_Remove(client, id)
{
	ghostEffect[client] = 0;
}

/***********************************************************/
/******************** WHEN ROUND START *********************/
/***********************************************************/
public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}		
		}
	}
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
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}
		}
		i++;
	}
}

/***********************************************************/
/********************* WHEN MAP START **********************/
/***********************************************************/
public void OnMapStart()
{
	PrecacheParticleEffect("office_fire");
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
			if(ghostEffect[i] == 1)
			{
				if(!IsValidEntRef(C_Flames[i]))
				{
					C_Flames[i] = AttachParticle(i, "office_fire");
				}
			}
			else
			{
				if(IsValidEntRef(C_Flames[i]))
				{
					RemoveEntity(C_Flames[i]);
				}			
			}
		}
		else
		{
			if(IsValidEntRef(C_Flames[i]))
			{
				RemoveEntity(C_Flames[i]);
			}			
		}
	}
}

stock int AttachParticle(int client, char[] particleType)
{
	int particle = CreateEntityByName("info_particle_system");
	
	if(IsValidEntity(particle))
	{
		SetEntPropEnt(particle, Prop_Data, "m_hOwnerEntity", client);
		DispatchKeyValue(particle, "effect_name", particleType);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		SetVariantString("forward");
		AcceptEntityInput(particle, "SetParentAttachment", particle , particle, 0);
		DispatchSpawn(particle);
		
		AcceptEntityInput(particle, "start");
		ActivateEntity(particle);
		
		float pos[3];
		GetEntPropVector(particle, Prop_Send, "m_vecOrigin", pos);
		
		pos[2] += 12.0;
		float vec_start[3];
		AddInFrontOf(pos, NULL_VECTOR, 12.0, vec_start);
		TeleportEntity(particle, vec_start, NULL_VECTOR, NULL_VECTOR);
		
		return EntIndexToEntRef(particle);
	}
	return -1;
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

/***********************************************************/
/*************** PRECACHE PARTICLE EFFECT ******************/
/***********************************************************/
stock void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	
	if (table == INVALID_STRING_TABLE)
	{
		table = FindStringTable("ParticleEffectNames");
	}
	
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock void AddInFrontOf(float vecOrigin[3], float vecAngle[3], float units, float output[3])
{
	float vecAngVectors[3];
	vecAngVectors = vecAngle; //Don't change input
	GetAngleVectors(vecAngVectors, vecAngVectors, NULL_VECTOR, NULL_VECTOR);
   
	for (int i; i < 3; i++)
	{
		output[i] = vecOrigin[i] + (vecAngVectors[i] * units);
	}
}