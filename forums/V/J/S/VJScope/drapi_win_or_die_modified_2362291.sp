/*  <DR. API WIN OR DIE> (c) by <De Battista Clint - (http://doyou.watch)    */
/*                                                                           */
/*                 <DR. API WIN OR DIE> is licensed under a                  */
/* Creative Commons Attribution-NonCommercial-NoDerivs 4.0 Unported License. */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*  work.  If not, see <http://creativecommons.org/licenses/by-nc-nd/4.0/>.  */
//***************************************************************************//
//***************************************************************************//
//*****************************DR. API WIN OR DIE****************************//
//***************************************************************************//
//***************************************************************************//

//***********************************//
//*************DEFINE****************//
//***********************************//

#define CVARS 									FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
#define DEFAULT_FLAGS 							FCVAR_PLUGIN|FCVAR_NOTIFY
#define TAG_WOR 								"[WIN OR DIE] - "
#define PLUGIN_VERSION							"1.0.1"

//***********************************//
//*************INCLUDE***************//
//***********************************//

#undef REQUIRE_PLUGIN
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <autoexec>
#include <csgocolors>

#pragma newdecls required

//***********************************//
//***********PARAMETERS**************//
//***********************************//

//Handle
Handle cvar_active_wod;

//Bool
bool B_active_wod 							= false;

//String
static char M_WOD_MODEL_1[] 				= "models/props_street/garbage_can.mdl";
char M_HALO01[] 							= "materials/sprites/halo01.vmt";

//Customs
int M_WOD_DECALS_BLOOD[13];
int M_HALO01_PRECACHED;

//Informations plugin
public Plugin myinfo =
{
	name = "DR.API WIN OR DIE",
	author = "Dr. Api",
	description = "DR.API WIN OR DIE by Dr. Api",
	version = PLUGIN_VERSION,
	url = "http://zombie4ever.eu"
}

/***********************************************************/
/*********************** PLUGIN START **********************/
/***********************************************************/
public void OnPluginStart()
{
	LoadTranslations("drapi/drapi_win_or_die.phrases");
	AutoExecConfig_SetFile("drapi_win_or_die", "sourcemod/drapi");
	
	AutoExecConfig_CreateConVar("aio_win_or_die_version", PLUGIN_VERSION, "Version", CVARS);
	
	cvar_active_wod 					= AutoExecConfig_CreateConVar("active_wod",  				"1", 					"Enable/Disable Win or Die", 			DEFAULT_FLAGS, 		true, 0.0, 		true, 1.0);
	
	RegAdminCmd("sm_wod",				Command_WOD,		ADMFLAG_CHANGEMAP, 		"Test the Win or Die effect");
	
	HookEvent("round_end", 				Event_RoundEnd);
	
	HookEvents();
	
	AutoExecConfig_ExecuteFile();
	
}

/***********************************************************/
/******************** WHEN CVAR CHANGED ********************/
/***********************************************************/
void HookEvents()
{
	HookConVarChange(cvar_active_wod, 				Event_CvarChange);
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
	B_active_wod 			= GetConVarBool(cvar_active_wod);
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
	M_HALO01_PRECACHED = PrecacheModel(M_HALO01);
	PrecacheModel(M_WOD_MODEL_1, true);
	PrecacheDecalsBlood();
	UpdateState();
}

/***********************************************************/
/********************* WHEN ROUND END **********************/
/***********************************************************/
public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	if(B_active_wod)
	{
		int I_winner = GetEventInt(event, "winner");
		
		if(I_winner != 1)
		{
			for(int i = 1; i <= MaxClients; ++i)
			{
				if(Client_IsIngame(i))
				{
					if(GetClientTeam(i) != I_winner && IsPlayerAlive(i))
					{
						CreateGarbage(i);
						CreateTimer(1.0, KillPlayers, i);
					}
				}
			}
		}
	}
}

/***********************************************************/
/********************* CREATE GARBAGE **********************/
/***********************************************************/
void CreateGarbage(int client)
{
	int cage = CreateEntityByName("prop_dynamic_override");
	
	if(IsValidEdict(cage))
	{
		float vec[3];
		GetClientAbsOrigin(client, vec);
		
		//SetEntityModel(cage, M_WOR_MODEL_1);
		//if(B_active_wod_dev)
		//{
		//	PrintToChat(client, "Model:%s", M_WOD_MODEL_1);
		//}
		
		DispatchKeyValue(cage, "model", M_WOD_MODEL_1);
		DispatchKeyValue(cage, "StartDisabled", "false");
		DispatchKeyValue(cage, "Solid", "6");

		SetEntProp(cage, Prop_Data, "m_CollisionGroup", 5);
		SetEntProp(cage, Prop_Data, "m_nSolidType", 6);
		//SetEntPropFloat(cage, Prop_Data, "m_flModelScale", 50.0);

		DispatchSpawn(cage);

		AcceptEntityInput(cage, "Enable");
		AcceptEntityInput(cage, "TurnOn");
		AcceptEntityInput(cage, "DisableMotion");
		
		TeleportEntity(cage, vec, NULL_VECTOR, NULL_VECTOR);
		
		CPrintToChat(client, "%t", "WOD useless chat");
		PrintCenterText(client, "%t", "WOD useless alert"); 
    }
	
}

/***********************************************************/
/****************** PRECACHE BLOOD DECALS ******************/
/***********************************************************/
void PrecacheDecalsBlood()
{
	M_WOD_DECALS_BLOOD[0] = PrecacheDecal("decals/blood_splatter.vtf");
	M_WOD_DECALS_BLOOD[1] = PrecacheDecal("decals/bloodstain_003.vtf");
	M_WOD_DECALS_BLOOD[2] = PrecacheDecal("decals/bloodstain_101.vtf");
	M_WOD_DECALS_BLOOD[3] = PrecacheDecal("decals/bloodstain_002.vtf");
	M_WOD_DECALS_BLOOD[4] = PrecacheDecal("decals/bloodstain_001.vtf");
	M_WOD_DECALS_BLOOD[5] = PrecacheDecal("decals/blood8.vtf");
	M_WOD_DECALS_BLOOD[6] = PrecacheDecal("decals/blood7.vtf");
	M_WOD_DECALS_BLOOD[7] = PrecacheDecal("decals/blood6.vtf");
	M_WOD_DECALS_BLOOD[8] = PrecacheDecal("decals/blood5.vtf");
	M_WOD_DECALS_BLOOD[9] = PrecacheDecal("decals/blood4.vtf");
	M_WOD_DECALS_BLOOD[10] = PrecacheDecal("decals/blood3.vtf");
	M_WOD_DECALS_BLOOD[11] = PrecacheDecal("decals/blood2.vtf");
	M_WOD_DECALS_BLOOD[12] = PrecacheDecal("decals/blood1.vtf");
}

/***********************************************************/
/******************** TIMER KILL PLAYER ********************/
/***********************************************************/
public Action KillPlayers(Handle timer, any client)
{
	Explode(client);
}

/***********************************************************/
/********************** PLAYER EXPLODE *********************/
/***********************************************************/
void Explode(int victim)
{
	if(Client_IsIngame(victim))
	{
		float pos[3];
		GetClientAbsOrigin(victim, pos);
		int victim_death = GetEntProp(victim, Prop_Data, "m_iDeaths");
		int vicitm_frags = GetEntProp(victim, Prop_Data, "m_iFrags");
		
		int explosion = CreateEntityByName("env_explosion");
		
		if(explosion != -1)
		{
			SetEntityHealth(victim, 1);
			
			// Stuff we will need
			float vector[3];
			int damage = 500;
			int radius = 128;
			int team = GetEntProp(victim, Prop_Send, "m_iTeamNum");
						
			// We're going to use eye level because the blast can be clipped by almost anything.
			// This way there's no chance that a small street curb will clip the blast.
			GetClientEyePosition(victim, vector);
						
				
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntProp(explosion, Prop_Data, "m_spawnflags", 264);
			SetEntProp(explosion, Prop_Data, "m_iMagnitude", damage);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", radius);
			
			DispatchKeyValue(explosion, "rendermode", "5");
						
			DispatchSpawn(explosion);
			ActivateEntity(explosion);

			TE_SetupExplosion(pos, M_HALO01_PRECACHED, 5.0, 1, 0, 100, 1500);
			TE_Start("World Decal");
			TE_WriteVector("m_vecOrigin", pos);
			int random = GetRandomInt(0, 12);
			TE_WriteNum("m_nIndex", M_WOD_DECALS_BLOOD[random]);
		
			TE_SendToAll();
			
			TeleportEntity(explosion, vector, NULL_VECTOR, NULL_VECTOR);
			EmitSoundToAll("weapons/hegrenade/explode3.wav", explosion, 1, 90);		
			AcceptEntityInput(explosion, "Explode");

			EmitSoundToAll("weapons/c4/c4_explode1.wav", explosion, 1, 90);
			
			SetEntProp(victim, Prop_Data, "m_iFrags", vicitm_frags);
			SetEntProp(victim, Prop_Data, "m_iDeaths", victim_death + 1);
		}
	}
}

/***********************************************************/
/******************* COMMAND KILL TEST *********************/
/***********************************************************/
public Action Command_WOD(int client, int args) 
{
	CreateGarbage(client);
	CreateTimer(2.0, KillPlayers, client);
	return Plugin_Handled;
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