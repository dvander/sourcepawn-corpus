/*
* [TF2] Funny Class Gibs 
* Author(s): retsam (Original author: Raven Coda)
* File: funnyclassgibs.sp
* Description: Shows class specific item gibs.
**************************************************************************
* Original author and credit goes to Raven Coda. This plugin has been
* recoded from his original. http://forums.alliedmods.net/showthread.php?p=661702
*************************************************************************
*
* 
* 0.4 - Added cvar for backstab gibbing.
*     - Added cvar for headshot gibbing.
*     - Added cvar to toggle blast damage gibbing.
*     - Changed name of sentrygun cvar.
*
* 0.3 - Fixed the decl model size for engineer function.
*     - Enabled medic.
*     - Added bonesaw for medic gib model. Removed glasses model.
*     - Raised default max zaxis velocity to 500.
*     - Changed default gibcount cvar to 5 instead of 6. 
*
* 0.2 - Removed the fadeout on gibs code. More efficient to just remove the models instead of worrying about a few millaseconds of fade effect. 
*     - Moved the removeragdoll code to under each class in the 'switch' so ragdolls arnt removed if class cvars are disabled.
* 
* 0.1 - Plugin recoded to use class item specific gibs instead of all the random stuff from the default 'funny gibs' plugin.
*     - Pyro gibs are random particle flame effects due to not finding any viable models.
*     - Scout gibs randomize between baseball and energydrink models.
*     - Engineer gibs randomize between many different machine parts.
*     - Decided to exclude Spy class from gibbing due to lack of models found and issues with dead ringer.
*     - Added cvar to disable/allow the default gore/gibs(convar tf_playergib).
*     - Added cvar to enable gibbing from normal sentrygun and wrangler fire.
*     - Added cvar to control how many gibs are spawned. 
*     - Added cvar to control the duration the gibs stay on the map.
*     - Added cvars for all classes to toggle gibbing for specific classes.
*     - Added auto-created config.
*     - Added detecting damage based on damagebits instead of weapon names.
*     - Removed any 'Edict' related coded and replaced with AcceptEntityInput/IsValidEntity.
*     - Changed CreateEntityByName method to 'prop_physics_override' instead of 'prop_physics' due to the c_ and w_ models.
*     - Changed method for setting collision.
*     - Removed or fixed various bad coding in original plugin.
*     - Recoded the crazy way the previous plugin was randomizing models. 
*     - Changed the particle used for the blood impact effect.
*     - Fixed fadeout timer code.
*     - Fixed the bizarre 'instanced_scripted_scene' errors. (I think?) 
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.4"

#define DMG_BLAST			(1 << 6)	// explosive blast damage
#define DMG_ALWAYSGIB		(1 << 13)	// with this bit set, any damage type can be made to gib victims upon death.

//Gib Models
#define MODEL_BASEBALL "models/weapons/w_models/w_baseball.mdl"
#define MODEL_ENERGYDRINK "models/weapons/c_models/c_energy_drink/c_energy_drink.mdl"
#define MODEL_SANDWICH "models/weapons/c_models/c_sandwich/c_sandwich.mdl"
#define MODEL_URINEJAR "models/weapons/c_models/urinejar.mdl"
#define MODEL_BOTTLE "models/weapons/w_models/w_bottle.mdl"
#define MODEL_BUGLE "models/weapons/c_models/c_bugle/c_bugle.mdl"
#define MODEL_BONESAW "models/weapons/w_models/w_bonesaw.mdl"

new Handle:Cvar_playergibs = INVALID_HANDLE;
new Handle:Cvar_AllowNormGibs = INVALID_HANDLE;
new Handle:Cvar_SentrygunGibs = INVALID_HANDLE;
new Handle:Cvar_HeadshotGibs = INVALID_HANDLE;
new Handle:Cvar_BackstabGibs = INVALID_HANDLE;
new Handle:Cvar_BlastDmgGibs = INVALID_HANDLE;
new Handle:Cvar_GibsCount = INVALID_HANDLE;
new Handle:Cvar_GibsDuration = INVALID_HANDLE;
new Handle:Cvar_ScoutGibs = INVALID_HANDLE;
new Handle:Cvar_SniperGibs = INVALID_HANDLE;
new Handle:Cvar_SoldierGibs = INVALID_HANDLE;
new Handle:Cvar_DemomanGibs = INVALID_HANDLE;
new Handle:Cvar_MedicGibs = INVALID_HANDLE;
new Handle:Cvar_HeavyGibs = INVALID_HANDLE;
new Handle:Cvar_PyroGibs = INVALID_HANDLE;
new Handle:Cvar_EngineerGibs = INVALID_HANDLE;

new Float:g_fcvarGibsDuration;

new g_cvarSentryGibs;
new g_cvarHeadshotGibs;
new g_cvarBackstabGibs;
new g_cvarBlastDmgGibs;
new g_cvarGibCount;
new g_cvarScoutGibs;
new g_cvarSniperGibs;
new g_cvarSoldierGibs;
new g_cvarDemomanGibs;
new g_cvarMedicGibs;
new g_cvarHeavyGibs;
new g_cvarPyroGibs;
new g_cvarEngyGibs;
//new g_clrRenderOffs;

public Plugin:myinfo = {
	name = "Funny Class Gibs",
	author = "retsam",
	description = "Shows class specific item gibs.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=136218"
};

//Engineer Models
new const String:EngGibs[][] = 
{
	"models/weapons/c_models/c_pda_engineer/c_pda_engineer.mdl",
	"models/player/gibs/gibs_bolt.mdl",
	"models/player/gibs/gibs_gear1.mdl",
	"models/player/gibs/gibs_gear2.mdl",
	"models/player/gibs/gibs_gear3.mdl",
	"models/player/gibs/gibs_gear4.mdl",
	"models/player/gibs/gibs_gear5.mdl",
	"models/player/gibs/gibs_spring1.mdl",
	"models/player/gibs/gibs_spring2.mdl"
};

public OnPluginStart() 
{ 
	/*
g_clrRenderOffs = FindSendPropOffs("CBaseEntity", "m_clrRender");
	if(g_clrRenderOffs == -1)
	{
		SetFailState("Could not find \"m_clrRender\" offsets.");
	}
	*/

	CreateConVar("sm_funnyclassgibs_version", PLUGIN_VERSION, "Version of Funny Class Gibs", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_AllowNormGibs = CreateConVar("sm_funnyclassgibs_defaultgibs", "0", "Allow default gibs in addition to replaced fun gibs?(1/0 = yes/no) (Could affect performance)");
	Cvar_BlastDmgGibs = CreateConVar("sm_funnyclassgibs_blastdamage", "1", "Enable gibs from blast damage?(rockets, grenades, explode damage, etc)(1/0 = yes/no)");
	Cvar_SentrygunGibs = CreateConVar("sm_funnyclassgibs_sentryguns", "0", "Enable gibs from sentrygun kills?(1/0 = yes/no)");
	Cvar_HeadshotGibs = CreateConVar("sm_funnyclassgibs_headshots", "0", "Enable gibs from headshots?(1/0 = yes/no)");
	Cvar_BackstabGibs = CreateConVar("sm_funnyclassgibs_backstabs", "0", "Enable gibs from backstabs?(1/0 = yes/no)");
	Cvar_GibsCount = CreateConVar("sm_funnyclassgibs_gibcount", "5", "Number of gibs to create. (Raising this value will affect performance)", _, true, 1.0, true, 25.0);
	Cvar_GibsDuration = CreateConVar("sm_funnyclassgibs_duration", "15.0", "Time in seconds before the gibs are removed.", _, true, 1.0, true, 100.0);
	Cvar_ScoutGibs = CreateConVar("sm_funnyclassgibs_scout", "1", "Enable gibs for scouts?(1/0 = yes/no)");
	Cvar_SniperGibs = CreateConVar("sm_funnyclassgibs_sniper", "1", "Enable gibs for snipers?(1/0 = yes/no)");
	Cvar_SoldierGibs = CreateConVar("sm_funnyclassgibs_soldier", "1", "Enable gibs for soldiers?(1/0 = yes/no)");
	Cvar_DemomanGibs = CreateConVar("sm_funnyclassgibs_demoman", "1", "Enable gibs for demomen?(1/0 = yes/no)");
	Cvar_MedicGibs = CreateConVar("sm_funnyclassgibs_medic", "1", "Enable gibs for medics?(1/0 = yes/no)");
	Cvar_HeavyGibs = CreateConVar("sm_funnyclassgibs_heavy", "1", "Enable gibs for heavies?(1/0 = yes/no)");
	Cvar_PyroGibs = CreateConVar("sm_funnyclassgibs_pyro", "1", "Enable gibs for pyros?(1/0 = yes/no)");
	Cvar_EngineerGibs = CreateConVar("sm_funnyclassgibs_engineer", "1", "Enable gibs for engineers?(1/0 = yes/no)");

	Cvar_playergibs = FindConVar("tf_playergib");
	SetConVarFlags(Cvar_playergibs, GetConVarFlags(Cvar_playergibs)^FCVAR_NOTIFY);

	// events
	HookEvent("player_death", Hook_PlayerDeath, EventHookMode_Post);
	
	HookConVarChange(Cvar_BlastDmgGibs, Cvars_Changed);
	HookConVarChange(Cvar_SentrygunGibs, Cvars_Changed);
	HookConVarChange(Cvar_BackstabGibs, Cvars_Changed);
	HookConVarChange(Cvar_HeadshotGibs, Cvars_Changed);
	HookConVarChange(Cvar_GibsCount, Cvars_Changed);
	HookConVarChange(Cvar_GibsDuration, Cvars_Changed);
	HookConVarChange(Cvar_ScoutGibs, Cvars_Changed);
	HookConVarChange(Cvar_SniperGibs, Cvars_Changed);
	HookConVarChange(Cvar_SoldierGibs, Cvars_Changed);
	HookConVarChange(Cvar_DemomanGibs, Cvars_Changed);
	HookConVarChange(Cvar_MedicGibs, Cvars_Changed);
	HookConVarChange(Cvar_HeavyGibs, Cvars_Changed);
	HookConVarChange(Cvar_PyroGibs, Cvars_Changed);
	HookConVarChange(Cvar_EngineerGibs, Cvars_Changed);

	AutoExecConfig(true, "plugin.funnyclassgibs");
}

public OnConfigsExecuted()
{
	g_cvarBlastDmgGibs = GetConVarInt(Cvar_BlastDmgGibs);
	g_cvarSentryGibs = GetConVarInt(Cvar_SentrygunGibs);
	g_cvarHeadshotGibs = GetConVarInt(Cvar_HeadshotGibs);
	g_cvarBackstabGibs = GetConVarInt(Cvar_BackstabGibs);
	g_cvarGibCount = GetConVarInt(Cvar_GibsCount);
	g_fcvarGibsDuration = GetConVarFloat(Cvar_GibsDuration);
	g_cvarScoutGibs = GetConVarInt(Cvar_ScoutGibs);
	g_cvarSniperGibs = GetConVarInt(Cvar_SniperGibs);
	g_cvarSoldierGibs = GetConVarInt(Cvar_SoldierGibs);
	g_cvarDemomanGibs = GetConVarInt(Cvar_DemomanGibs);
	g_cvarMedicGibs = GetConVarInt(Cvar_MedicGibs);
	g_cvarHeavyGibs = GetConVarInt(Cvar_HeavyGibs);
	g_cvarPyroGibs = GetConVarInt(Cvar_PyroGibs);
	g_cvarEngyGibs = GetConVarInt(Cvar_EngineerGibs);

	if(GetConVarInt(Cvar_AllowNormGibs) == 0)
	{
		if(GetConVarInt(Cvar_playergibs) == 1)
		{
			LogAction(-1, 0, "Detected tf_playergib enabled. Setting convar disabled.");
			SetConVarInt(Cvar_playergibs, 0);
		}
	}
}

public OnMapStart()
{
	for (new x = 0; x < sizeof(EngGibs); x++)
	{
		PrecacheModel(EngGibs[x], true);
	}

	PrecacheModel(MODEL_BASEBALL, true);
	PrecacheModel(MODEL_ENERGYDRINK, true);
	PrecacheModel(MODEL_SANDWICH, true);
	PrecacheModel(MODEL_URINEJAR, true);
	PrecacheModel(MODEL_BOTTLE, true);
	PrecacheModel(MODEL_BUGLE, true);
	PrecacheModel(MODEL_BONESAW, true);
}

public Hook_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damagebits = GetEventInt(event, "damagebits");
	new customkill = GetEventInt(event, "customkill");
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	return;
	
	//PrintToChatAll("Damagebits are: %i", damagebits);

	new bool:bReplaceGibs = false;
	
	if(((damagebits & (DMG_BLAST | DMG_ALWAYSGIB)) > 0))
	{
		if(g_cvarBlastDmgGibs)
		{
			//PrintToChatAll("Blast damage detected!");
			bReplaceGibs = true;
		}
	}
	else if(customkill == 1) //headshots
	{
		if(g_cvarHeadshotGibs)
		{
			bReplaceGibs = true;
		}
	}
	else if(customkill == 2) //backstabs
	{
    if(g_cvarBackstabGibs)
    {
      bReplaceGibs = true;
    }
  }
	else if(g_cvarSentryGibs)
	{
		decl String:weaponName[32];
		GetEventString(event, "weapon", weaponName, sizeof(weaponName));
		//PrintToChatAll("Weapon is: %s", weaponName);
		if((StrContains(weaponName, "sentry", false) > -1) || (StrContains(weaponName, "wrangler", false) > -1))
		{
			//PrintToChatAll("Sentry damage detected!");
			bReplaceGibs = true;
		}
	}
	
	if(bReplaceGibs)
	{
		//PrintToChatAll("Replacing Gibs..");
		ReplaceGibs(client);
	}
}

public ReplaceGibs(client)
{
	if(!IsClientInGame(client))
	return;

	if(!IsValidEntity(client))
	{
		LogError("Could not find Client.");  
		return;
	}

	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	ShowParticle(pos, "blood_impact_red_01", 2.0);

	new String:sModel[64];
	new TFClassType:class = TF2_GetPlayerClass(client);
	switch (class)
	{
	case 1: // Scout
		{
			if(!g_cvarScoutGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			new rand = GetRandomInt(0, 1);
			if(rand == 0)
			{
				sModel = MODEL_BASEBALL;
			}
			else
			{
				sModel = MODEL_ENERGYDRINK;
			}      
		}
	case 2: // Sniper
		{
			if(!g_cvarSniperGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			sModel = MODEL_URINEJAR;
		}
	case 3: // Soldier
		{
			if(!g_cvarSoldierGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			sModel = MODEL_BUGLE;
		}
	case 4: // Demoman
		{
			if(!g_cvarDemomanGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			sModel = MODEL_BOTTLE;
		}
	case 5: // Medic
		{
			if(!g_cvarMedicGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			sModel = MODEL_BONESAW;
		}
	case 6: // Heavy
		{
			if(!g_cvarHeavyGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			sModel = MODEL_SANDWICH;
		}
	case 7:// Pyro
		{
			if(!g_cvarPyroGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			ShowGibParticle(client, "buildingdamage_dispenser_fire0", 8.0);
			decl Float:flPos[3];
			for(new x = 0; x < g_cvarGibCount; x++)
			{
				flPos[0] = GetRandomFloat(-50.0, 75.0);
				flPos[1] = GetRandomFloat(-50.0, 75.0);
				flPos[2] = 0.0;
				
				ShowGibParticle(client, "burninggibs", 6.0, flPos[0], flPos[1], flPos[2]);
			}
			
			return;
		}
	case 8: // Spy
		{
			return;
		}
	case 9: // Engineer
		{
			if(!g_cvarEngyGibs)
			return;
			
			CreateTimer(0.0, RemoveRagdoll, client, TIMER_FLAG_NO_MAPCHANGE);
			
			decl model;
			for(new x = 0; x < g_cvarGibCount; x++)
			{
				model = GetRandomInt(0, sizeof(EngGibs) - 1);
				new gib = CreateEntityByName("prop_physics_override");
				
				DispatchKeyValue(gib, "model", EngGibs[model]);
				if(DispatchSpawn(gib))
				{
					if(IsValidEntity(gib))
					{
						SetEntProp(gib, Prop_Send, "m_CollisionGroup", 1);
						//SetEntProp(gib, Prop_Data, "m_CollisionGroup", 1);
						new Float:vel[3];
						vel[0] = GetRandomFloat(-100.0, 200.0);
						vel[1] = GetRandomFloat(-100.0, 200.0);
						vel[2] = GetRandomFloat(200.0, 400.0);
						TeleportEntity(gib, pos, NULL_VECTOR, vel);
						//SetEntityRenderMode(gib, RENDER_TRANSCOLOR);
						CreateTimer(g_fcvarGibsDuration, Timer_RemoveGib, gib, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
				else
				{
					LogError("Could not create gib.");
				}
			}
			
			return;
		}
	}

	for(new x = 0; x < g_cvarGibCount; x++)
	{
		new gib = CreateEntityByName("prop_physics_override");
		DispatchKeyValue(gib, "model", sModel);
		if(DispatchSpawn(gib))
		{
			if(IsValidEntity(gib))
			{
				SetEntProp(gib, Prop_Send, "m_CollisionGroup", 1);
				//SetEntProp(gib, Prop_Data, "m_CollisionGroup", 1);
				new Float:vel[3];
				vel[0] = GetRandomFloat(-100.0, 200.0);
				vel[1] = GetRandomFloat(-100.0, 200.0);
				vel[2] = GetRandomFloat(200.0, 500.0);
				TeleportEntity(gib, pos, NULL_VECTOR, vel);
				//SetEntityRenderMode(gib, RENDER_TRANSCOLOR);
				CreateTimer(g_fcvarGibsDuration, Timer_RemoveGib, gib, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			LogError("Could not create gib.");
		}
	}
}  

public Action:RemoveRagdoll(Handle:Timer, any:client)
{
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if(ragdoll > 0)
	{
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", -1);
		AcceptEntityInput(ragdoll, "kill");
	}
	else
	{
		LogError("Could not find ragdoll.");
	}
}

public Action:Timer_RemoveGib(Handle:Timer, any:ent)
{
	if(IsValidEntity(ent))
	{
		//decl String:classname[32];
		//GetEdictClassname(ent, classname, sizeof(classname));
		//PrintToChatAll("Ent Classname is: %s", classname);
		//if(StrEqual(classname, "prop_physics", false))
		//{
		AcceptEntityInput(ent, "kill");
		//}
	}
}

/*
public Action:RemoveGib(Handle:Timer, any:ent)
{
	if(IsValidEntity(ent))
	{
		CreateTimer(0.1, fadeout, ent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}


public Action:fadeout(Handle:Timer, any:ent)
{
	if(!IsValidEntity(ent))
	return Plugin_Stop;

	new alpha = GetEntData(ent, g_clrRenderOffs + 3, 1);
	if(alpha - 25 <= 0)
	{
		AcceptEntityInput(ent, "kill");
		return Plugin_Stop;
	}
	else
	{
		SetEntData(ent, g_clrRenderOffs + 3, alpha - 25, 1, true);
	}

	return Plugin_Continue;
}  
*/

stock ShowGibParticle(entity, String:type[], Float:time, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle))
	{
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		CreateTimer(time, Timer_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("ShowGibParticle: could not create info_particle_system.");
	}    
}

stock ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle))
	{
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, Timer_DeleteParticle, particle, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}    
}

public Action:Timer_DeleteParticle(Handle:timer, any:particle)
{
	if(IsValidEntity(particle))
	{
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "kill");
		}
	}
}

/*
stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}
*/

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if(convar == Cvar_GibsCount)
  {
    g_cvarGibCount = StringToInt(newValue);
  }
  else if(convar == Cvar_BlastDmgGibs)
  {
    g_cvarBlastDmgGibs = StringToInt(newValue);
  }
  else if(convar == Cvar_SentrygunGibs)
  {
    g_cvarSentryGibs = StringToInt(newValue);
  }
	else if(convar == Cvar_HeadshotGibs)
	{
		g_cvarHeadshotGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_BackstabGibs)
	{
		g_cvarBackstabGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_GibsDuration)
	{
		g_fcvarGibsDuration = StringToFloat(newValue);
	}
	else if(convar == Cvar_ScoutGibs)
	{
		g_cvarScoutGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_SniperGibs)
	{
		g_cvarSniperGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_SoldierGibs)
	{
		g_cvarSoldierGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_DemomanGibs)
	{
		g_cvarDemomanGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_MedicGibs)
	{
		g_cvarMedicGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_HeavyGibs)
	{
		g_cvarHeavyGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_PyroGibs)
	{
		g_cvarPyroGibs = StringToInt(newValue);
	}
	else if(convar == Cvar_EngineerGibs)
	{
		g_cvarEngyGibs = StringToInt(newValue);
	}
}