#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.6"
#define	TEAM_SURVIVORS	2
#define	TEAM_INFECTED	3
#define CVAR_FLAGS FCVAR_SPONLY|FCVAR_NOTIFY

ConVar l4d2_detonation_scale_damage;
ConVar l4d2_grenade_detonation_force;
ConVar l4d2_pipe_detonation_force;
ConVar l4d2_barrel_detonation_force;
ConVar l4d2_bomb_detonation_force;
ConVar l4d2_detonation_force_immunity;
ConVar l4d2_detonation_force_ghost_mode;
ConVar l4d2_detonation_force_disable_gamemodes;

Handle sdkCallPushPlayer = INVALID_HANDLE;
Handle GameConf = INVALID_HANDLE;

bool isl4d2;
bool EnablePlugin;

public Plugin myinfo =
{
	name = "L4D2 Detonation Force",
	author = "OIRV",
	description = "Explosions throws survivors and SI in the air",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1759636"
};

public void OnPluginStart()
{
	/* Console vars */
	CreateConVar("l4d2_detonation_force_version", PLUGIN_VERSION, "L4D2 Detonation Force Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d2_bomb_detonation_force = CreateConVar("l4d2_bomb_detonation_force", "250", "Sets bomb explosion power", CVAR_FLAGS);
	l4d2_pipe_detonation_force = CreateConVar("l4d2_pipe_detonation_force", "300", "Sets pipe bomb explosion power", CVAR_FLAGS);
	l4d2_barrel_detonation_force = CreateConVar("l4d2_barrel_detonation_force", "250", "Sets fuel barrel explosion power", CVAR_FLAGS);
	l4d2_grenade_detonation_force = CreateConVar("l4d2_grenade_detonation_force", "50", "Sets grenade launcher explosion power", CVAR_FLAGS);	
	//l4d2_detonation_force_enable = CreateConVar("l4d2_detonation_force_enable", "1", "Enable/Disable plugin", CVAR_FLAGS);
	l4d2_detonation_scale_damage = CreateConVar("l4d2_detonation_scale_damage", "0.0", "% force as damage", CVAR_FLAGS);		
	l4d2_detonation_force_immunity = CreateConVar("l4d2_detonation_force_immunity", "1", "Entity immune to the explosion: 0 nobody, 1 survivors, 2 infected", CVAR_FLAGS);		
	l4d2_detonation_force_ghost_mode = CreateConVar("l4d2_detonation_force_ghost_mode", "0", "Enable/Disable knock back in infected ghost", CVAR_FLAGS);		
	l4d2_detonation_force_disable_gamemodes =  CreateConVar("l4d2_detonation_force_disable_gamemodes", "empty", "Disable plugin in selected game modes", CVAR_FLAGS);	
	
	AutoExecConfig(true, "l4d2_detonation_force");
	
	/* Getting the name of the game */
	char sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	/* For L4D 2 */
	if (StrEqual(sGame, "left4dead2", false))
	{
		isl4d2 = true;  // set the flag to true

		/* loading the signature for the "throw function" for l4d 2 */		
		GameConf = LoadGameConfigFile("l4d2_detonationforce");	
		if(GameConf == INVALID_HANDLE)
		{
			SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly.");
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(GameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		sdkCallPushPlayer = EndPrepSDKCall();
		
		if(sdkCallPushPlayer == INVALID_HANDLE)
		{
			SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
		}
		CloseHandle(GameConf);
	}
	/* For L4D 1 */
	else
	{
		if (StrEqual(sGame, "left4dead", false))
		{
			isl4d2 = false; // set the flag to false
		}
		else
		{
			SetFailState("L4D2 Explosion Force supports L4D and L4D 2 only"); // the current game isn't l4d or l4d2
		}
	}

	HookConVarChange(l4d2_detonation_force_disable_gamemodes, VarGameModesChange);
}

public void LoadGameModes()
{
	/*Get current game mode*/
	ConVar gamemode = FindConVar("mp_gamemode");
	static char currentGameMode[64];
	GetConVarString(gamemode, currentGameMode, sizeof(currentGameMode));

	/* Split the string with the game modes to disable */
	static char gamemodes[32][32];
	static char buffer[512];
	GetConVarString(l4d2_detonation_force_disable_gamemodes, buffer, sizeof(buffer));
	ExplodeString(buffer, ",", gamemodes, sizeof gamemodes, sizeof gamemodes[]);

	/* if the string contains "*" */
	if(StrEqual(buffer, "*", false))
	{
		PrintToServer("l4d2_DetonationForce: Disabled for all game modes");
		EnablePlugin = false;
		return;
	}
	EnablePlugin = true;  
	
	for(int i = 0; i < 32; i++)
	{
		/* if any of the selected gamemodes from config file is equal to the current gamemode */
		if(StrEqual(currentGameMode, gamemodes[i], false))
		{
			EnablePlugin = false;			// disable plugin
			PrintToServer("l4d2_DetonationForce %s: Disabled",currentGameMode);
			break;
		}
	}
	if(EnablePlugin == true)
	{
		/* the current game mode has not been found in the config file game modes */
			PrintToServer("l4d2_DetonationForce %s: Enabled",currentGameMode);
	}
}

public void OnMapStart()
{
	LoadGameModes();
}

public void VarGameModesChange(ConVar convar, const char[] oldValue, const char[] newValue) 
{
	LoadGameModes();
}

public void OnEntityDestroyed(int entity)
{
	if( EnablePlugin == false || entity <= 0 || !IsValidEntity(entity) || !IsValidEdict(entity)) return; // some checks to see if it is worth continuing

	char EntityName[128];
	if(!GetEdictClassname(entity, EntityName, sizeof(EntityName))) return; // getting the name of the destroyed entity and an extra check

	 /* checks if the entity is an explosive */
	if (StrEqual(EntityName, "prop_fuel_barrel", false) || StrEqual(EntityName, "pipe_bomb_projectile", false) || StrEqual(EntityName, "grenade_launcher_projectile", false))
	{
		float force;
		if(StrEqual(EntityName, "grenade_launcher_projectile", false))
		{			
			force = float(GetConVarInt(l4d2_grenade_detonation_force)); // getting the power for the grenade launcher
		}
		else
		if(StrEqual(EntityName, "prop_fuel_barrel", false))
		{
			force = float(GetConVarInt(l4d2_barrel_detonation_force));	// getting the power for the fuel barrel
		}
		else
		{			
			if(GetEntityFlags(entity) == 1)
			{
				force = float(GetConVarInt(l4d2_pipe_detonation_force));	// getting the power for the pipe bomb
			}
			else
			{
				force = float(GetConVarInt(l4d2_bomb_detonation_force));	// getting the power for the rest of the explosives
			}
		}
		for (int client = 1; client <= MaxClients; client++)
		{ 			
			Fly(entity, client, force); // checks if any client is affected by the explosion
		}
	}
}

public int Fly(int explosion, int target, float power)
{
	if(target <= 0 || !IsValidEntity(target) || !IsValidEdict(target)) return; // check if the taget is a valid entity

	if(GetEntData(target,FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1) == 1) // check if the target is in ghost mode
	{
		if(GetConVarInt(l4d2_detonation_force_ghost_mode) == 0) return; // check if we can throw ghosts
	}

	float targetPos[3];
	float explosionPos[3];
	float traceVec[3];
	float resultingFling[3];

	/* getting the target and explosion position */
	GetEntPropVector(target, Prop_Data, "m_vecOrigin", targetPos);		
	GetEntPropVector(explosion, Prop_Data,"m_vecOrigin", explosionPos);

	power = power - GetVectorDistance(targetPos,explosionPos);	// an easy way to define the explosion power, is the "base power" minus the distance between the target and the explosion

	if(power < 1) return; // if the power is irrelevant, doesn't worth to continue

	/* getting the resulting */	
	MakeVectorFromPoints(explosionPos, targetPos, traceVec);
	GetVectorAngles(traceVec, resultingFling);

	resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;
	resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
	resultingFling[2] = power + (power * 0.5);

	/* for L4D 1 */	
	if(!isl4d2)	
	{
		if (GetClientTeam(target) == TEAM_SURVIVORS)
		{
			if(GetConVarInt(l4d2_detonation_force_immunity) == 0 || GetConVarInt(l4d2_detonation_force_immunity) + 1 == TEAM_INFECTED) // check if isn't immune
			{
				DamageEffect(target,RoundToNearest(power * GetConVarFloat(l4d2_detonation_scale_damage)));	// apply damage to the survivor
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resultingFling);// teleporting the survivor with the resulting
			}
		}
		else
		if (GetClientTeam(target) == TEAM_INFECTED)
		{
			if(GetConVarInt(l4d2_detonation_force_immunity) == 0 || GetConVarInt(l4d2_detonation_force_immunity) + 1 == TEAM_SURVIVORS) // check if isn't immune
			{
				DamageEffect(target,RoundToNearest(power * GetConVarFloat(l4d2_detonation_scale_damage)));	// apply damage to the infected
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resultingFling);// teleporting the infected with the resulting
			}
		}
		return;
	}
	/* for L4D 2 */	
	if (GetClientTeam(target) == TEAM_SURVIVORS)
	{
		if(GetConVarInt(l4d2_detonation_force_immunity) == 0 || GetConVarInt(l4d2_detonation_force_immunity) + 1 == TEAM_INFECTED)
		{
			DamageEffect(target,RoundToNearest(power * GetConVarFloat(l4d2_detonation_scale_damage)));	// apply damage to the survivor
			SDKCall(sdkCallPushPlayer, target, resultingFling, 76, target, 2.0);// throwing survivor with animation 76 (charge animation)
		}
	}
	else
	if (GetClientTeam(target) == TEAM_INFECTED)
	{
		if(GetConVarInt(l4d2_detonation_force_immunity) == 0 || GetConVarInt(l4d2_detonation_force_immunity) + 1 == TEAM_SURVIVORS)
		{
			DamageEffect(target,RoundToNearest(power * GetConVarFloat(l4d2_detonation_scale_damage)));	// apply damage to the infected
			SDKCall(sdkCallPushPlayer, target, resultingFling, 2, target, 2.0); // throwing infected with animation 2 (jump animation)
		}
	}
}

public void DamageEffect(int target, int damage)
{
	char sDamage[12];
	IntToString(damage, sDamage, sizeof(sDamage));			// converting the damage from int to string

	int pointHurt = CreateEntityByName("point_hurt");		// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");		// mark target
	DispatchKeyValue(pointHurt,	"Damage", sDamage);			// Set damage
	DispatchKeyValue(pointHurt, "DamageTarget",	"hurtme");	// Target Assignment
	DispatchKeyValue(pointHurt, "DamageType", "65536");		// Type of damage
	DispatchSpawn(pointHurt);								// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt");					// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill");					// Remove point_hurt
	DispatchKeyValue(target, "targetname", "cake");			// Clear target's mark
}