#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"
#define TEAM_SURVIVOR	2

//int g_CTRL_pressed[MAXPLAYERS+1];
int g_iHealing[MAXPLAYERS+1];
int g_iClone[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
Handle l4d_heal_animation_bots;
Handle l4d_heal_animation_enabled;
Handle l4d_heal_animation_run;

char g_sAnimations[47][64] = 
{
	"incap_crawl", 
	"Idle_Standing_SniperZoomed",
	"CalmRun_Elites",
	"CalmRunN_PumpShotgun_layer",
	"CalmWalk_Elites",
	"Collapse_to_Hanging",
	"CrouchWalk_GasCan",
	"deathpose_back",
	"deathpose_front",
	"drag",
	"Fall",
	"Flinch_01",
	"Flinch_Ledge_01",
	"Heal_Self_Crouching_01",
	"Idle_Crouching_Elites",
	"Idle_Crouching_Grenade_Ready",
	"Idle_Fall_From_TankPunch",
	"Idle_Falling",
	"Idle_Incap_Hanging2",
	"Idle_Incap_Standing_SmokerChoke_germany",
	"Idle_Rescue_01c",
	"Idle_Standing_Minigun",
	"Idle_Tongued_choking_ground",
	"Jump_GasCan_01",
	"Ladder_Ascend",
	"Ladder_Descend",
	"Land_Injured",
	"Melee_Shove_Running_Rifle",
	"Melee_Stomp_Standing_Rifle",
	"Melee_Straight_Standing_Rifle",
	"melee_sweep_o2",
	"Pickup_Standing_M4",
	"Pickup_Standing_M4_layer",
	"Pills_Swallow",
	"Pulled_Running_Rifle",
	"Push_Pull",
	"Run_Elites",
	"Run_FirstAidKit",
	"Run_Grenade_Ready",
	"Shoot_Running_Grenade2",
	"shoot_standing_gascan2",
	"Shoved_Backward",
	"Shoved_Forward",
	"Shoved_Leftward",
	"Shoved_Rightward",
	"Unholster_Standing_Elites",
	"Walk_Grenade_Ready"
};

public Plugin myinfo =
{
	name = "L4D1 Funny Heal Animation",
	author = "Axel Juan Nieves",
	description = "Funny Healing Animation: Press DUCK while healing to switch animations.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("l4d_heal_animation_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	l4d_heal_animation_enabled = CreateConVar("l4d_heal_animation_enabled", "1", "Enable/Disable this plugin.", 0);
	l4d_heal_animation_bots = CreateConVar("l4d_heal_animation_bots", "1", "Allow funny animations on bots?", 0);
	l4d_heal_animation_run = CreateConVar("l4d_heal_animation_run", "1", "Alow funny animations on...? 1:healer, 2:healed, 3:both", 0, true, 1.0, true, 3.0);
	
	AutoExecConfig(true, "l4d_heal_animation");
	
	//LoadTranslations("l4d_heal_animation");
	
	HookEvent("heal_begin", event_heal_started);
	HookEvent("heal_success", event_heal_stopped);
	HookEvent("heal_end", event_heal_stopped);
	HookEvent("heal_interrupted", event_heal_stopped);
	HookEvent("player_death", event_heal_stopped);
	HookEvent("player_team", event_heal_stopped);
	
}

public void event_heal_started(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_heal_animation_enabled) )
		return;
	
	//We need to create a clone to work in. We cannot set animation from client entity.
	int client1 = GetClientOfUserId(GetEventInt(event, "userid")); //healer
	int client2 = GetClientOfUserId(GetEventInt(event, "subject")); //healed
	
	switch ( GetConVarInt(l4d_heal_animation_run) )
	{
		case 1:
			CreateClone(client1);
		case 2:
			CreateClone(client2);
		case 3:
		{
			CreateClone(client1);
			CreateClone(client2);
		}
	}
	
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if ( !GetConVarBool(l4d_heal_animation_enabled) ) return Plugin_Continue;
	if ( !IsValidClientAlive(client) ) return Plugin_Continue;
	//if ( IsFakeClient(client) ) return Plugin_Continue;
	//if ( GetClientTeam(client)!=TEAM_SURVIVOR ) return Plugin_Continue;
	if ( g_iHealing[client]==0 ) return Plugin_Continue;
	
	if ( buttons&IN_DUCK ){}
	else if ( g_iHealing[client]==2 ){}
	else if ( g_iHealing[client]==-2 ){}
	else return Plugin_Continue;
	
	int iRand = GetRandomInt(0, 46);
	int clone = EntRefToEntIndex(g_iClone[client]);
	if ( !IsValidEntity(clone) )
	{
		//PrintToChatAll("FATAL ERROR: Clone doesnt exist!");
		return Plugin_Continue;
	}
	
	//make sure this condition runs once per healing
	if ( g_iHealing[client] > 0 )
	{
		SetEntityRenderMode(clone, RENDER_NORMAL); //make clone visible
		SetEntityRenderMode(client, RENDER_NONE); //make original survivor visible
		g_iHealing[client] *= -1; 
	}
	
	// Set animation...
	SetVariantString(g_sAnimations[iRand]);
	AcceptEntityInput(clone, "SetAnimation");
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", 4.0); //animation speed 1.0=normal

	//random angle is funniest...
	float fAngle[3];
	//fAngle[0] = 180.0 * GetRandomInt(0, 1);
	fAngle[1] = GetRandomFloat(0.0, 360.0);
	//fAngle[2] = 180.0 * GetRandomInt(0, 1);
	TeleportEntity(clone, NULL_VECTOR, fAngle, NULL_VECTOR);
	
	//PrintToConsole(client, "Success! Random animation(%i): %s", iRand, g_sAnimations[iRand]);
	return Plugin_Continue;
}

public void event_heal_stopped(Handle event, const char[] name, bool dontBroadcast)
{
	int client1 = GetClientOfUserId(GetEventInt(event, "userid"));
	int client2 = GetClientOfUserId(GetEventInt(event, "subject"));
	if ( IsValidClientIndex(client1) )
	{
		g_iHealing[client1] = 0;
		RemoveClone(client1);
	}
	if ( IsValidClientIndex(client2) )
	{
		g_iHealing[client2] = 0;
		RemoveClone(client2);
	}
}

stock bool RemoveClone(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
		
	//PrintToChatAll("Trying to remove clone...");
	int clone = EntRefToEntIndex(g_iClone[client]);
	SetEntityRenderMode(client, RENDER_NORMAL);
	
	if ( !IsValidEntity(clone) )
	{
		//PrintToChatAll("Clone(%i) not found!", clone);
		g_iClone[client] = INVALID_ENT_REFERENCE;
		return false;
	}
	
	//PrintToChatAll("Clone removed successfully. Ref=%i, Index=%i!!", g_iClone[client], clone);
	AcceptEntityInput(clone, "ClearParent");
	RemoveEntity(clone);
	g_iClone[client] = INVALID_ENT_REFERENCE;
	g_iHealing[client] = 0;
	return true;
}

stock bool CreateClone(int client)
{
	if ( !GetConVarBool(l4d_heal_animation_enabled) ) 
		return false;
	
	if ( !IsValidClientAlive(client) )
		return false;
	
	int clone = EntRefToEntIndex(g_iClone[client]);
	
	//check if clone already exists...
	if ( IsValidEntity(clone) )
	{
		return false;
	}
	
	//create a new clone...
	clone = CreateEntityByName("prop_dynamic");
	g_iClone[client] = EntIndexToEntRef(clone);
	//PrintToChatAll("Creating a clone first time. Ref(%i) Index(%i).", g_iClone[client], clone);
	
	char modelname[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
	
	//check if clone was created successfully...
	if ( !IsValidEntity(clone) )
	{
		//PrintToChatAll("Failed to create prop_dynamic '%s' (%N)", modelname, client);
		return false;
	}
	
	//-------------------------------------------------------------
	//if everything's alright...
	//-------------------------------------------------------------
	SetEntityModel(clone, modelname);
	
	//attach clone to survivor...
	SetVariantString("!activator");
	AcceptEntityInput(clone, "SetParent", client);
	
	//set position:
	TeleportEntity(clone, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
	//TeleportEntity(clone, NULL_VECTOR, NULL_VECTOR, NULL_VECTOR); //does not work
	//PrintToChat(client, "Clone created successfully!");
	
	//we need to make clone independent from survivor before setting their rendering.
	AcceptEntityInput(clone, "ClearParent");
	
	SetEntityRenderMode(clone, RENDER_NONE); //make clone invisible temporarily
	
	g_iHealing[client] = 1;
	if ( GetConVarBool(l4d_heal_animation_bots) )
	{
		if ( IsFakeClient(client) )
			g_iHealing[client] = 2;
	}
	return true;
}

public void OnClientDisconnect(int client)
{
	RemoveClone(client);
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}

public bool IsValidClientAlive(int client)
{
	if (client <= 0)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (!IsPlayerAlive(client))
		return false;
	
	return true;
}