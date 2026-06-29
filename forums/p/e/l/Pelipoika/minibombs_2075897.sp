#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define SND_SHOOT			"weapons/grenade_launcher_shoot.wav"
#define SND_WARN			"misc/doomsday_lift_warning.wav"
#define MDL_BOMBLET			"models/weapons/w_models/w_stickybomb.mdl"

new Handle:g_hCvarEnabled,		bool:g_bCvarEnabled;
new Handle:g_hCvarSpawnDelay,	Float:g_flCvarSpawnDelay;
new Handle:g_hCvarBombDamage,	Float:g_flCvarBombDamage;

public Plugin:myinfo = 
{
	name = "[TF2] Minibombs",
	author = "Pelipoika",
	description = "Makes stickies spit out lil bomblets",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	g_hCvarEnabled = CreateConVar("sm_minibombs_enabled", "1.0", "Enable Minibombs \n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);
	
	g_hCvarSpawnDelay = CreateConVar("sm_minibombs_spawndelay", "5.0", "How often should a sticky spawn a minibomb? (Seconds)", FCVAR_PLUGIN, true, 0.0);
	g_flCvarSpawnDelay = GetConVarFloat(g_hCvarSpawnDelay);
	HookConVarChange(g_hCvarSpawnDelay, OnConVarChange);
	
	g_hCvarBombDamage = CreateConVar("sm_minibombs_damage", "20.0", "How much damage should a minibomb do?", FCVAR_PLUGIN, true, 0.0);
	g_flCvarBombDamage = GetConVarFloat(g_hCvarBombDamage);
	HookConVarChange(g_hCvarBombDamage, OnConVarChange);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	g_flCvarSpawnDelay = GetConVarFloat(g_hCvarSpawnDelay);
	g_flCvarBombDamage = GetConVarFloat(g_hCvarBombDamage);
}

public OnMapStart()
{
	PrecacheSound(SND_SHOOT);
	PrecacheSound(SND_WARN);
	PrecacheModel(MDL_BOMBLET);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_bCvarEnabled && StrEqual(classname,"tf_projectile_pipe_remote"))
	{
		CreateTimer(2.0, Timer_SetProps, EntIndexToEntRef(entity));
	}
}

public Action:Timer_SetProps(Handle:timer, any:entity)
{
	new ent = EntRefToEntIndex(entity);
	decl String:sClass[32];
	
	if (ent > 0 && ent > MaxClients && IsValidEntity(ent) && GetEntityClassname(ent, sClass, sizeof(sClass)))
	{
		if(StrEqual(sClass, "tf_projectile_pipe_remote") && GetEntProp(ent, Prop_Send, "m_bTouched") && GetEntProp(ent, Prop_Send, "m_iType") != 2)
		{
			new client = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
			new clientteam = GetClientTeam(client);			//Throwers team

			if(!CheckCommandAccess(client, "sm_minibombs_access", 0))
				return Plugin_Handled;
		
			new Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			
			decl Float:g_angles[3], Float:g_angles2[3];		//Rotate sticky a bit when it shoots a bomblet
			GetEntPropVector(ent, Prop_Send, "m_angRotation", g_angles);

			g_angles2[0] = (g_angles[0] += GetRandomFloat(5.0,45.0));
			g_angles2[1] = (g_angles[1] += GetRandomFloat(5.0,45.0));
			g_angles2[2] = (g_angles[2] += GetRandomFloat(5.0,45.0));
			
			decl Float:ang[3];
			ang[0] = GetRandomFloat(-90.0, 90.0); 			//Left, Right
			ang[1] = GetRandomFloat(-90.0, 90.0); 			//Forward, Back
			ang[2] = GetRandomFloat(240.0, 340.0); 			//Up, Down
			
			new pitch = 150;
			EmitAmbientSound(SND_SHOOT, pos, ent, _, _, _, pitch);
			
			new ent2 = CreateEntityByName("tf_projectile_pipe");
			
			if(ent2 != -1)
			{					
				SetEntPropEnt(ent2, Prop_Data, "m_hThrower", client);
				SetEntProp(ent2, Prop_Send, "m_iTeamNum", clientteam);
				SetEntProp(ent2, Prop_Send, "m_bCritical", true);
				SetEntPropFloat(ent2, Prop_Send, "m_flModelScale", 0.8);
				SetEntPropFloat(ent2, Prop_Send, "m_flDamage", g_flCvarBombDamage);
				
				DispatchSpawn(ent2);
				
				SetEntityModel(ent2, MDL_BOMBLET);
				
				TeleportEntity(ent2, pos, NULL_VECTOR, ang);							//Teleport bomblet to momma stickybomb
				TeleportEntity(ent, NULL_VECTOR, g_angles2, NULL_VECTOR);				//Rotate	
				
				CreateTimer(g_flCvarSpawnDelay, Timer_SetProps, EntRefToEntIndex(ent));		//The cycle continues..
			}
		}
	}
	return Plugin_Handled;
}