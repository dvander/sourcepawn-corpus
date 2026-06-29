//Includes//
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
//External//
#include <smlib>

//Defines//
#define GHOST_COLLISION 1
#define GHOST_SOLID 22
#define PLUGIN_VERSION "1.0"
#define MAX_DIST 10000.0
#define EVERYONE 0			//Every player
#define SAME_TEAM 1			//Every player in the same team
#define WITH_VOICE_LINES 2	//Every player in the same team AND with mvm voice lines


//Globals//
new g_RCE = 0;//Round Can End
new String:g_ClassNames[TFClassType][16] = { "Unknown", "Scout", "Sniper", "Soldier", "Demoman", "Medic", "Heavy", "Pyro", "Spy", "Engineer"};
//new money [MAXPLAYERS+1];

//Handles//
new Handle:cvarSTTEnable;

//new Handle:hGameConf;
//new Handle:hSetTrack;

//Plugin Info
public Plugin:myinfo =
{
	name = "Stop That Tank",
	author = "Classic & tDTH",
	description = "Replace the payload cart with a tank.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Model precache
public OnMapStart()
{
	if (GetConVarBool(cvarSTTEnable))
	{
		PrecacheModel("models/props_mvm/robot_hologram.mdl");
		PrecacheModel("models/bots/boss_bot/bomb_mechanism.mdl"); 
		PrecacheModel("models/bots/boss_bot/boss_tank.mdl");
		PrecacheModel("models/bots/boss_bot/boss_tank_damage1.mdl");
		PrecacheModel("models/bots/boss_bot/boss_tank_damage2.mdl");
		PrecacheModel("models/bots/boss_bot/boss_tank_damage3.mdl");
		PrecacheModel("models/bots/boss_bot/boss_tank_part1_destruction.mdl");
		PrecacheModel("models/bots/boss_bot/static_boss_tank.mdl");
		PrecacheModel("models/bots/boss_bot/tank_track.mdl");
		PrecacheModel("models/bots/boss_bot/tank_track_R.mdl");
		PrecacheModel("models/bots/boss_bot/tank_track_L.mdl");
	}
}

//Commands, CVars & Events
public OnPluginStart()
{
	//Commands
	RegAdminCmd("sm_log_ent", Command_Log_Ents, ADMFLAG_ROOT,"Logs every entity to a file");
	
	//CVars
	CreateConVar("sm_stt_version", PLUGIN_VERSION, "Stop That Tank version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarSTTEnable = CreateConVar("sm_stt_enabled", "1", "Enabled Stop That Tank?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	//Events
	HookEvent("teamplay_setup_finished", RoundReallyStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start",	RoundStart,EventHookMode_PostNoCopy);
	HookEntityOutput("path_track", "OnPass", Passing);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("teamplay_point_captured", Event_PointCaptured);
	
	//hGameConf = LoadGameConfigFile("stoptank");
	//StartPrepSDKCall(SDKCall_Entity);
	//PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFTankBoss::SetStartingPathTrackNode");
	//PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	//hSetTrack = EndPrepSDKCall();
}

//Prepares the cart/tank and the track
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		//Removes lights, effects and models from the cart. At this moment, this is hardcoded for every map.
		RemoveCart();
		
		//Moves the 2 last path_track entities so the 'deploy bomb' animation looks right. It's harcoded for every map and I don't think that this will change.
		MoveTrack();
		
		//Creates the Tank entity with 0 speed.
		CreateTank();
		
		
	}
}

public OnEntityCreated(entity, const String:classname[])
{
    if(StrEqual(classname, "tank_boss"))
    {
		new String:map[32];
		GetCurrentMap(map,sizeof(map));
		if(StrEqual(map, "pl_badwater"))
		{	

			//SDKCall(hSetTrack, entity, "minecart_path_12"); // Sets up spawned tank_boss to follow path_track named path_gaben__4chan_was_here"
		}
    }
}  

//When set-up time ends
public Action:RoundReallyStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		PrintToChatAll("[STT] The tank will start moving in 15 seconds!");
		CreateTimer(15.0, Tank_Start);
	}	
}

//Start moving the tank
public Action:Tank_Start(Handle:timer)
{
	StartMoving();
	g_RCE = 1;
	//To-Do, create here the health-bar entity
}

//This fires when the tank pass over a path_track
public Passing(const String:output[], caller, activator, Float:delay)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		new String:cN[32],String:aN[32],String:cC[32],String:aC[32];
		Entity_GetName(caller,cN, sizeof(cN)); 			//path_track name.
		Entity_GetClassName(caller,cC, sizeof(cC)); 		//path_track classname (this should be always "path_track" but i'm testing).
		Entity_GetName(activator,aN, sizeof(aN)); 		//Activator's name (normaly it will be "tank1").
		Entity_GetClassName(activator,aC, sizeof(aC)); 	//Activator's classname (this should be "tank_boss").
		
		//Uncomment this see over wich path_track is the tank now (will spam chat).
		//PrintToChatAll("caller: %i - %s activator: %i - %s",caller, cN, activator, aN);
			
		if(StrEqual(aC, "tank_boss")&&StrEqual(cC,"path_track"))
		{
			new ent = FindEntityByClassname(-1, "func_tracktrain");
			SetVariantString(cN);	
			
			//How does it work? When the tank pass over a path_track, the plugin moves the cart to that path_track
			//So it 'jumps' on every path_track (also I move the cart with a slow speed so the jumps are smaller).
			//I tried to create the tank as a func_tracktrain's child. It worked but the tank was reversed and it's movement was weird.
			if(true == AcceptEntityInput(ent,"TeleportToPathTrack"))
			{
				//This is hardcoded for every map
				new String:map[32];
				GetCurrentMap(map,sizeof(map));
				if(StrEqual(map, "pl_badwater") && StrEqual(cN, "minecart_path_128"))
				{
					//PrintToChatAll("[STT] The tank is going to deploy the bomb!");
					//Here I should call a function to print that line and start the deploying bomb alert sound.
					CreateTimer(7.5, STT_Twin);
				}
				if(StrEqual(map, "pl_upward") && StrEqual(cN, "minecart_path_174"))
				{
					//PrintToChatAll("[STT] The tank is going to deploy the bomb!");
					CreateTimer(7.5, STT_Twin);				
				}
				if(StrEqual(map, "pl_barnblitz") && StrEqual(cN, "track_a_186"))
				{
					//PrintToChatAll("[STT] The tank is going to deploy the bomb!");
					CreateTimer(7.5, STT_Twin);				
				}
			}
		}
	}
}

//The timer for the bomb deploy animation (aprox. 7.5 seconds)
public Action:STT_Twin(Handle:timer)
{
	/*To-Do:
		*Check if the tank is still alive (important if, in the future, RED team doesn't win after killing it)
		
		*Trigger the big boom at the end. I'm not sure how to do this, 
		there is a "trigger_once" entity that triggers all final entities,
		but it has a filter for cart/team/player and I want to by-pass that and just trigger it.
		  
		*Set the last point as capped. Right now, the blue team does win but it doesn't count the last point
	
	*/
	new String:map[32];
	GetCurrentMap(map,sizeof(map));
	new cap
	
	if(StrEqual(map, "pl_badwater"))
	{	
		cap = Entity_FindByName("end_pit_destroy_particle");
		AcceptEntityInput(cap,"Start");
		cap = Entity_FindByName("stage3_capture_shake");
		AcceptEntityInput(cap,"StartShake");
		cap = Entity_FindByName("stage3_capture_wav");
		AcceptEntityInput(cap,"PlaySound");
		
	}
	
	if(StrEqual(map, "pl_upward"))
	{	
		cap = Entity_FindByName("end_pit_destroy_particle");
		AcceptEntityInput(cap,"Start");
		cap = Entity_FindByName("stage3_capture_shake");
		AcceptEntityInput(cap,"StartShake");
		cap = Entity_FindByName("stage3_capture_wav");
		AcceptEntityInput(cap,"PlaySound");
		
	}
	if(StrEqual(map, "pl_barnblitz"))
	{	
		cap = Entity_FindByName("end_pit_destroy_particle");
		AcceptEntityInput(cap,"Start");
		cap = Entity_FindByName("stage3_capture_shake");
		AcceptEntityInput(cap,"StartShake");
		cap = Entity_FindByName("stage3_capture_wav");
		AcceptEntityInput(cap,"PlaySound");
	}
	if(StrEqual(map, "pl_frontier_final"))
	{	
		cap = Entity_FindByName("final_destruction");
		AcceptEntityInput(cap,"Start");
		cap = Entity_FindByName("final_shake ");
		AcceptEntityInput(cap,"StartShake");
		cap = Entity_FindByName("final_sound");
		AcceptEntityInput(cap,"PlaySound");
	}
	SetWinner(3);
	cap = FindEntityByClassname(-1, "tank_boss");
	AcceptEntityInput(cap,"KillHierarchy");
}

//Fires on the tank's death (I think that there is a 'OnDeath' output for this entity, I should use it).
public OnEntityDestroyed(entity)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		new String:sNam[32]
		Entity_GetName(entity,sNam,sizeof(sNam));
		if (StrEqual(sNam, "tank1") && g_RCE == 1)
		{
			PrintToChatAll("[STT] Say good bye to that tank!");
			SetWinner(2);
		}
	}
}

//Uses the game_round_win entity to set the winner
public SetWinner(winner)
{
	if(g_RCE == 1)
	{
		new iEnt = -1;
		iEnt = FindEntityByClassname(iEnt, "game_round_win");
		
		if (iEnt < 1)
		{
			iEnt = CreateEntityByName("game_round_win");
			if (IsValidEntity(iEnt))
			{
				DispatchSpawn(iEnt);
			}
			else
			{
				PrintToChatAll( "Unable to find or create a game_round_win entity!");
			}
		}
		
		
		if (winner == 1)
		{
			winner --;
		}
		
		SetVariantInt(winner);
		AcceptEntityInput(iEnt, "SetTeam");
		AcceptEntityInput(iEnt, "RoundWin");
		g_RCE =0;
	}
	
}



//Simple client-check
stock IsValidClient( client )
{
	//Check for client "ID"
	if  ( client <= 0 || client > MaxClients ) 
		return false;
	
	//Check for client is in game
	if ( !IsClientInGame( client ) ) 
		return false;
	
	return true;
}
/*
//Hooks touch event on every cash pack dropped in order to give critz 
//(works but at this time, RED wins if they destroy the tank).
public OnEntityCreated(entity)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		new String:sEnt[32]
		Entity_GetClassName(entity,sEnt,sizeof(sEnt));
		if (StrEqual(sEnt, "item_currencypack_custom"))
		{
			SDKHook( entity, SDKHook_Touch, OnCashTouch );
		}
	}
}

//Cash functions
//Event for touching the cash
public OnCashTouch( entity, client )
{
	if( IsValidClient( client ) )
	{	
		if( IsValidEntity( entity ) )
		{
			money[client]++;
			AddCritz(client);
		}
	}
}

//Adding critz
public AddCritz(client)
{
	if( money[client] > 0 )
	{
		TF2_AddCondition(client, TFCond:TFCond_CritCanteen, 2.5);
	}
}
 
//This should make that the critz-time staks (eg: if I get 2 cash packs, I get twice critz time)
public TF2_OnConditionRemoved(client, TFCond:cond)
{
	if (GetConVarBool(cvarSTTEnable))
	{
		if( cond == TFCond_CritCanteen)
		{
			money[client]--;
			AddCritz(client);
		}
	}
}
*/

//Removes lights, effects and models from the cart. At this moment, this is hardcoded for map.
public RemoveCart()
{
	g_RCE = 0;
	new String:map[32];
	GetCurrentMap(map,sizeof(map));
	
	//This is hardcoded for the map, in the future I will get every func_tracktrain's child and kill them.
	
	
	
	if(StrEqual(map, "pl_badwater") || StrEqual(map, "pl_upward"))
	{
		new cart = Entity_FindByName("cart_particles");//Cart's lights
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("cart_dispenser");//Dispenser 
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("cap_area");//Cart's area for capping/pushing
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("dispenser_trigger");//Dispenser's trigger
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_physprop");//cart's model
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("train2_hurt");//This can destroy the tank, I'm not sure but maybe this triggers the big boom at the end.
		AcceptEntityInput(cart, "KillHierarchy");
	}
	if(StrEqual(map, "pl_barnblitz") )
	{
		new cart = Entity_FindByName("bomb_light");//Cart's lights
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("Bomb_Dispense");//Dispenser 
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("Bomb_CapArea");//Cart's area for capping/pushing
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("Bomb_Dipense_Beam");//Dispenser's trigger
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("Bomb_Model");//cart's model
		AcceptEntityInput(cart, "KillHierarchy");
		//cart = Entity_FindByName("train2_hurt");//This can destroy the tank, I'm not sure but maybe this triggers the big boom at the end.
		//AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("bomb_sparks");//cart's sparks
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("bomb_sparks");//cart's sparks
		AcceptEntityInput(cart, "KillHierarchy");
	}
	if(StrEqual(map, "pl_frontier_final"))
	{
		new cart = Entity_FindByName("flatbed_tracktrain");
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("train_buildhurt");
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("cart_dispenser");//Dispenser 
		AcceptEntityInput(cart, "KillHierarchy");
		//cart = Entity_FindByName("flatcar_cap");//Cart's area for capping/pushing
		//AcceptEntityInput(cart, "KillHierarchy");
		//cart = Entity_FindByName("dispenser_trigger");//Dispenser's trigger
		//AcceptEntityInput(cart, "Kill");
		
		
		//cart = Entity_FindByName("minecart_hurt");//This can destroy the tank, I'm not sure but maybe this triggers the big boom at the end.
		//AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_spark_left");//cart's sparks
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_spark_right");//cart's sparks
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_prop");//cart's model
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_prop2");
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_prop3");
		AcceptEntityInput(cart, "KillHierarchy");
		cart = Entity_FindByName("minecart_tracktrain");
		SetEntProp(cart, Prop_Send, "m_CollisionGroup", GHOST_COLLISION);
		SetEntProp(cart, Prop_Send, "m_usSolidFlags", GHOST_SOLID);
	}
	new entc = FindEntityByClassname(-1, "func_tracktrain");
	//Makes the cart non-solid
	SetEntProp(entc, Prop_Send, "m_CollisionGroup", GHOST_COLLISION);
	SetEntProp(entc, Prop_Send, "m_usSolidFlags", GHOST_SOLID);
	
}

//Moves the 2 last path_track entities so the 'deploy bomb' animation looks right. It's harcoded for every map.
public MoveTrack()
{
	g_RCE = 0;
	new String:map[32];
	GetCurrentMap(map,sizeof(map));
	if(StrEqual(map, "pl_badwater"))
	{
	
		new Float:ang[3];
		new Float:vec[3];
		new path = Entity_FindByName("minecart_path_127");
		Entity_GetAbsOrigin(path,vec);
		vec[0]+= 210.0;
		path = Entity_FindByName("minecart_path_128");
		Entity_SetAbsOrigin(path,vec);
		path = Entity_FindByName("minecart_path_129");
		Entity_SetAbsOrigin(path,vec);
		//PrintToChatAll("path: %f %f %f",vec[0], vec[1], vec[2]);
		
		path = Entity_FindByName("cap_4");
		AcceptEntityInput(path,"HideModel");
		Entity_GetAbsOrigin(path,vec);
		//PrintToChatAll("Punto: %f %f %f",vec[0], vec[1], vec[2]);
		
		//vec[2] -= 40.0;
		new p_hatch = CreateEntityByName("item_ammopack_small");
		DispatchKeyValue(p_hatch, "powerup_model", "models/props_mvm/mann_hatch.mdl");
		DispatchSpawn(p_hatch);
		vec[0]-=20.0;
		vec[2] +=6.0;
		TeleportEntity(p_hatch, vec, NULL_VECTOR, NULL_VECTOR);
		SetEntProp(p_hatch, Prop_Send, "m_iTeamNum", 1, 4);
		path = Entity_FindByName("cap_4");
		Entity_GetAbsAngles(p_hatch,ang);
		Entity_GetAbsAngles(path,ang);
		//ang[1]=180.0;
		Entity_SetAbsAngles(p_hatch,ang);
	}
	
	if(StrEqual(map, "pl_upward"))
	{
		new Float:vec[3];
		new path = Entity_FindByName("minecart_path_173");
		Entity_GetAbsOrigin(path,vec);
		vec[1]+= 50.0;
		path = Entity_FindByName("minecart_path_174");
		Entity_SetAbsOrigin(path,vec);
		path = Entity_FindByName("minecart_path_175");
		Entity_SetAbsOrigin(path,vec);
	}
	
	if(StrEqual(map, "pl_barnblitz"))
	{
		new Float:vec[3];
		new path = Entity_FindByName("track_a_185");
		Entity_GetAbsOrigin(path,vec);
		vec[1]+= 30.0;
		path = Entity_FindByName("track_a_186");
		Entity_SetAbsOrigin(path,vec);
		vec[1]+= 20.0;
		path = Entity_FindByName("track_a_187");
		Entity_SetAbsOrigin(path,vec);
	}

}

//Creates the Tank entity with 0 speed.
public CreateTank()
{
	new entity = CreateEntityByName("tank_boss");
	Entity_SetName(entity, "tank1");
	
	
	//Inital stats they will be reseted on StartMoving() function.
	
	new HP = 2000;			//Inital life (remember that the tank is inmune first
	new SPD = 0;			//Velocity, it shouldn't move on round start.
	new TEAM = 3;			//Blue Team
		
	if(IsValidEntity(entity))
	{
		SetVariantInt(SPD); 
		AcceptEntityInput(entity, "SetSpeed");
		
		SetVariantInt(HP); 
		AcceptEntityInput(entity, "SetMaxHealth");
		SetVariantInt(HP); 
		AcceptEntityInput(entity, "SetHealth");
		SetEntProp(entity, Prop_Send, "m_iTeamNum", TEAM);
		
		
		DispatchSpawn(entity);
		//The tank will be inmune first
		SetEntProp(entity, Prop_Data, "m_takedamage", 0 , 1);
	}

}


public StartMoving()
{
	
	//Tank Stuff
	new entt = FindEntityByClassname(-1, "tank_boss");
	new SPD = 50;
	new HP;
	HP = 2200 * GetClientCount(true);
	SetVariantInt(HP); 
	AcceptEntityInput(entt, "SetMaxHealth");
	SetVariantInt(HP); 
	AcceptEntityInput(entt, "SetHealth");
	SetVariantInt(SPD); 
	AcceptEntityInput(entt, "SetSpeed");
	PrintToChatAll("[STT] Stop That Tank! (with %i HP)",HP);
	SetEntProp(entt, Prop_Data, "m_takedamage", 2 , 1);
	
	
	//HUD cart sutff
	new String:map[32];
	GetCurrentMap(map,sizeof(map));
	if(!StrEqual(map, "pl_frontier_final"))
	{
		//tean_train_watcher isn't the cart, it controls the cart logic and the HUD
		new entw = FindEntityByClassname(-1, "team_train_watcher"); 
		
		//This allow us to handle manually some cart's properties
		DispatchKeyValueFloat(entw,"handle_train_movement", 1.0);
		
		//This make the cart velocity slower than the normal one-capper speed
		new Float:vel = 0.25;
		SetVariantFloat(vel);
		AcceptEntityInput(entw,"SetSpeedForwardModifier");
		
		//Set the cappers number to 1. If I don't like the "x1" in the cart's hud, I could use the SetSpeed with a float.
		new cap = 1;
		SetVariantInt(cap); 
		AcceptEntityInput(entw, "SetNumTrainCappers");
	}
	
}

public Event_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	new cap = GetEventInt(event, "cpname")
	PrintToChatAll("[STT] %s captured!",cap);
}


//	Class is dead voice lines
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvarSTTEnable))
	{
		return;
	}
	
	new deathflags = GetEventInt(event, "death_flags");
	new bool:silentKill = GetEventBool(event, "silent_kill");
	
	if (silentKill || dontBroadcast || deathflags & TF_DEATHFLAG_DEADRINGER)
	{
		return;
	}

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim < 1 || victim > MaxClients || 3 == GetClientTeam(victim))
	{
		return;
	}

	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	new nearPlayer = FindNearestPlayer(victim, WITH_VOICE_LINES);
	if(nearPlayer != -1 && CheckClient(nearPlayer))
	{
		PlayClassDead(nearPlayer,victimClass);
	}

}

FindNearestPlayer(client,const type)
{
	new Float:pVec[3];
	new Float:nVec[3];
	GetClientEyePosition(client, pVec); 
	new found = -1;
	new Float:found_dist = MAX_DIST;
	new Float:aux_dist; 
	
	switch(type)
	{
		case EVERYONE:
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		
		case SAME_TEAM:
		{
			new pTeam = GetClientTeam(client);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i) && pTeam == GetClientTeam(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		case WITH_VOICE_LINES:
		{
			new pTeam = GetClientTeam(client);
			for (new i = 1; i <= MaxClients; i++)
			{
				if(i != client && CheckClient(i) && pTeam == GetClientTeam(i) && ClientHasVoiceLines(i))
				{
					GetClientEyePosition(i, nVec);
					aux_dist = GetVectorDistance(pVec, nVec, false)
					if(aux_dist < found_dist)
					{
						found = i;
						found_dist = aux_dist;
					}
				}
			}
		}
		
	}
	return found;
}

bool:ClientHasVoiceLines(client)
{
	if( TF2_GetPlayerClass(client) == TFClass_Soldier 
	|| TF2_GetPlayerClass(client) == TFClass_Medic 
	|| TF2_GetPlayerClass(client) == TFClass_Heavy 
	|| TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		return true;
	}
	return false;

}

PlayClassDead(client,TFClassType:victimClass)
{

	SetVariantString("randomnum:100");
	AcceptEntityInput(client, "AddContext");
	
	SetVariantString("IsMvMDefender:1");
	AcceptEntityInput(client, "AddContext");
	
	new String:victimClassContext[64];
	Format(victimClassContext, sizeof(victimClassContext), "victimclass:%s", g_ClassNames[victimClass]);

	SetVariantString(victimClassContext);
	AcceptEntityInput(client, "AddContext");

	SetVariantString("TLK_MVM_DEFENDER_DIED");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	AcceptEntityInput(client, "ClearContext");


}

bool:CheckClient(client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) ||
	TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || 
	TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
	{
		return false;
	}
	return true;
}


/*
 *	This is for research only, it creates a log file with all entities.
 *	All entities have a classname, but not an actual name.
 *	This could be usefull to understand how a map is made.
 */
public Action:Command_Log_Ents(client, args)
{	
	new Float:vec[3];
	new i =0;
	new ind;
	new String:map[32];
	GetCurrentMap(map,sizeof(map));
	PrintToChat(client, "Entities log in /logs/entityInfo.txt");
	new String:path[64];
	BuildPath(Path_SM, path, sizeof(path), "logs/entityInfo.txt");
	LogToFile(path,"Entities for %s",map);
	while(i<2048)
	{	
		if(IsValidEntity(i))
		{
			new String:targetname[32],String:classname[32];
			Entity_GetName(i,targetname, sizeof(targetname)); 
			Entity_GetClassName(i, classname, sizeof(classname)); 
			ind = Entity_FindByName(targetname);
			Entity_GetAbsOrigin(ind,vec);
			LogToFile(path,"%i - %s - %s | %f - %f - %f",i, targetname, classname, vec[0], vec[1], vec[2]);
		}
		i++
	}
	return Plugin_Handled;
}