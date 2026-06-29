#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

//#define PLUGIN_VERSION "1.0"
#define PLUGIN_VERSION "1.1 BETA 1"
#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

#define ANIM_HEAL	1
#define ANIM_HELPED 2
#define ANIM_HELPER	3
#define ANIM_TANK	4

int g_iClone[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
int g_iAnimsToPlay[MAXPLAYERS+1];
bool g_bIsBot[MAXPLAYERS+1] = {false, ...};
Handle l4d_funny_animation_bots;
Handle l4d_funny_animation_enabled;
Handle l4d_funny_animation_healer;
Handle l4d_funny_animation_healed;
Handle l4d_funny_animation_helper;
Handle l4d_funny_animation_helped;
Handle l4d_funny_animation_tank;

/*char g_sAnimationsHeal[47][64] = 
{
	"incap_crawl", "Idle_Standing_SniperZoomed", "CalmRun_Elites", "CalmRunN_PumpShotgun_layer",
	"CalmWalk_Elites", "Collapse_to_Hanging", "CrouchWalk_GasCan", "deathpose_back",
	"deathpose_front", "drag", "Fall", "Flinch_01", "Flinch_Ledge_01", "Heal_Self_Crouching_01",
	"Idle_Crouching_Elites", "Idle_Crouching_Grenade_Ready", "Idle_Fall_From_TankPunch", "Idle_Falling",
	"Idle_Incap_Hanging2", "Idle_Incap_Standing_SmokerChoke_germany", "Idle_Rescue_01c", "Idle_Standing_Minigun",
	"Idle_Tongued_choking_ground", "Jump_GasCan_01", "Ladder_Ascend", "Ladder_Descend", "Land_Injured",
	"Melee_Shove_Running_Rifle", "Melee_Stomp_Standing_Rifle", "Melee_Straight_Standing_Rifle", "melee_sweep_o2",
	"Pickup_Standing_M4", "Pickup_Standing_M4_layer", "Pills_Swallow", "Pulled_Running_Rifle", "Push_Pull",
	"Run_Elites", "Run_FirstAidKit", "Run_Grenade_Ready", "Shoot_Running_Grenade2", "shoot_standing_gascan2",
	"Shoved_Backward", "Shoved_Forward", "Shoved_Leftward", "Shoved_Rightward", "Unholster_Standing_Elites", "Walk_Grenade_Ready"
};*/

int g_iSequencesHeal[12] = {232, 516, 516, 516, 519, 520, 521, 526, 534, 534, 534, 535};
int g_iSequencesHelper[3] = {464, 465, 492};
int g_iSequencesHelped[10] = {494, 495, 516, 519, 528, 529, 530, 532, 533, 534};
int g_iSequencesTank[] = {11, 17, 18, 23, 24, 26, 27, 28, 29, 71, 72, 73};
int g_iRandomMax[5] = {
	0,
	sizeof(g_iSequencesHeal)-1, 
	sizeof(g_iSequencesHelped)-1, 
	sizeof(g_iSequencesHelper)-1,
	sizeof(g_iSequencesTank)-1};

public Plugin myinfo =
{
	name = "L4D1 Funny Heal Animation",
	author = "Axel Juan Nieves",
	description = "Funny Healing Animation: Hold DUCK while healing/helping to switch thru animations.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateConVar("l4d_heal_animation_version", PLUGIN_VERSION, "", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	l4d_funny_animation_enabled = CreateConVar("l4d_funny_animation_enabled", "1", "Enable/Disable this plugin.", 0);
	l4d_funny_animation_bots = CreateConVar("l4d_funny_animation_bots", "1", "Allow funny animations on bots?", 0);
	l4d_funny_animation_healed = CreateConVar("l4d_funny_animation_healed", "0", "Alow funny animations on being healed survivors?", 0);
	l4d_funny_animation_healer = CreateConVar("l4d_funny_animation_healer", "1", "Alow funny animations on healer survivors?", 0);
	l4d_funny_animation_helped = CreateConVar("l4d_funny_animation_helped", "1", "Alow funny animations on being helped survivors?", 0);
	l4d_funny_animation_helper = CreateConVar("l4d_funny_animation_helper", "1", "Alow funny animations on helper survivors?", 0);
	l4d_funny_animation_tank = CreateConVar("l4d_funny_animation_tank", "1", "Alow funny animations on Tank?", 0);
	
	AutoExecConfig(true, "l4d_funny_survivor_animation");
	
	//LoadTranslations("l4d_funny_survivor_animation");
	
	HookEvent("heal_begin", event_heal_begin);
	HookEvent("heal_success", SetNormalAnimation);
	HookEvent("heal_end", SetNormalAnimation);
	HookEvent("heal_interrupted", SetNormalAnimation);
	HookEvent("player_death", SetNormalAnimation);
	HookEvent("player_team", SetNormalAnimation);
	HookEvent("revive_begin", event_revive_begin);
	HookEvent("revive_success", SetNormalAnimation);
	HookEvent("revive_end", SetNormalAnimation);
	HookEvent("player_incapacitated", event_player_incapacitated);
}

public void event_heal_begin(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_funny_animation_enabled) )
		return;
	
	//We need to create a clone to work in. We cannot set animation from client entity.
	int client1 = GetClientOfUserId(GetEventInt(event, "userid")); //healer
	int client2 = GetClientOfUserId(GetEventInt(event, "subject")); //healed
	
	if ( GetConVarBool(l4d_funny_animation_healer) )
	{
		if ( IsFakeClient(client1) )
		{
			if ( GetConVarBool(l4d_funny_animation_bots) )
				g_bIsBot[client1] = true;
			else
				return;
		}
		else
			g_bIsBot[client1] = false;
		g_iAnimsToPlay[client1] = 0-ANIM_HEAL;
		CreateClone(client1);
	}
	if ( GetConVarBool(l4d_funny_animation_healed) )
	{
		if ( IsFakeClient(client2) )
		{
			if ( GetConVarBool(l4d_funny_animation_bots) )
				g_bIsBot[client2] = true;
			else
				return;
		}
		else
			g_bIsBot[client2] = false;
		g_iAnimsToPlay[client2] = 0-ANIM_HEAL;
		CreateClone(client2);
	}
}

public void event_revive_begin(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_funny_animation_enabled) )
		return;
	
	//We need to create a clone to work in. We cannot set animation from client entity.
	int client1 = GetClientOfUserId(GetEventInt(event, "userid")); //helper
	int client2 = GetClientOfUserId(GetEventInt(event, "subject")); //helped
	
	if ( GetConVarBool(l4d_funny_animation_helped) )
	{
		if ( IsFakeClient(client2) )
		{
			if ( GetConVarBool(l4d_funny_animation_bots) )
				g_bIsBot[client2] = true;
			else
				return;
		}
		else
			g_bIsBot[client2] = false;
		g_iAnimsToPlay[client2] = 0-ANIM_HELPED;
		CreateClone(client2);
	}
	if ( GetConVarBool(l4d_funny_animation_helper) )
	{
		if ( IsFakeClient(client1) )
		{
			if ( GetConVarBool(l4d_funny_animation_bots) )
				g_bIsBot[client1] = true;
			else
				return;
		}
		else
			g_bIsBot[client1] = false;
		g_iAnimsToPlay[client1] = 0-ANIM_HELPER;
		CreateClone(client1);
	}
}

public void event_player_incapacitated(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarBool(l4d_funny_animation_enabled) )
		return;
	if ( !GetConVarBool(l4d_funny_animation_tank) )
		return;
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsPlayerTank(client) )
		return;
	
	if ( IsFakeClient(client) )
	{
		if ( GetConVarBool(l4d_funny_animation_bots) )
			g_bIsBot[client] = true;
		else
			return;
	}
	else
		g_bIsBot[client] = false;
	
	//We need to create a clone to work in. We cannot set animation from client's entity.
	g_iAnimsToPlay[client] = 0-ANIM_TANK;
	CreateClone(client);
}

public Action OnPlayerRunCmd(int client, int& buttons)
{
	if ( !GetConVarBool(l4d_funny_animation_enabled) ) return Plugin_Continue;
	if ( !IsValidClientAlive(client) ) return Plugin_Continue;
	if ( g_iAnimsToPlay[client]==0 ) return Plugin_Continue;
	
	int clone = EntRefToEntIndex(g_iClone[client]);
	if ( !IsValidEntity(clone) )
	{
		//PrintToChatAll("FATAL ERROR: Clone doesnt exist!");
		return Plugin_Continue;
	}
	
	//make sure this condition runs once per healing...
	if ( g_iAnimsToPlay[client]<0)
	{
		if (buttons&IN_DUCK==0)
		{
			if ( !g_bIsBot[client] )
				return Plugin_Continue;
		}
		DispatchKeyValue(clone, "StartGlowing", "1");
		DispatchSpawn(clone);
		SetEntityRenderMode(client, RENDER_NONE); //make original survivor visible
		SetEntityRenderMode(clone, RENDER_NORMAL); //make clone visible
		//AcceptEntityInput(clone, "SetParent", client);
		//TeleportEntity(clone, view_as<float>({0.0, 0.0, 0.0}), view_as<float>({0.0, 0.0, 0.0}), NULL_VECTOR);
		g_iAnimsToPlay[client] *= -1;
	}
	
	if ( buttons&IN_DUCK ){}
	else if ( g_bIsBot[client] ){}
	//else if ( g_iAnimsToPlay[client]<0 ){}
	else return Plugin_Continue;
	
	// Set animation old method...
	//SetVariantString(g_sAnimationsHeal[iRand]);
	//AcceptEntityInput(clone, "SetAnimation");
	switch ( Abs(g_iAnimsToPlay[client]) )
	{
		case ANIM_HEAL:
			SetEntProp(clone, Prop_Send, "m_nSequence", g_iSequencesHeal[GetRandomInt(0, g_iRandomMax[ANIM_HEAL])] );
		case ANIM_HELPED:
			SetEntProp(clone, Prop_Send, "m_nSequence", g_iSequencesHelped[GetRandomInt(0, g_iRandomMax[ANIM_HELPED])] );
		case ANIM_HELPER:
			SetEntProp(clone, Prop_Send, "m_nSequence", g_iSequencesHelper[GetRandomInt(0, g_iRandomMax[ANIM_HELPER])] );
		case ANIM_TANK:
			SetEntProp(clone, Prop_Send, "m_nSequence", g_iSequencesTank[GetRandomInt(0, g_iRandomMax[ANIM_TANK])] );
	}
	SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", 4.0); //animation speed 1.0=normal
	
	//random angle is funniest...
	float fAngle[3], fPos[3];
	fAngle[1] = GetRandomFloat(0.0, 360.0);
	
	GetClientAbsOrigin(client, fPos);
	fPos[0] += GetRandomFloat(-12.0, 12.0);
	fPos[1] += GetRandomFloat(-12.0, 12.0);
	fPos[2] += GetRandomFloat(-5.0, 5.0);
	//fPos[0] = GetRandomFloat(-12.0, 12.0);
	//fPos[1] = GetRandomFloat(-12.0, 12.0);
	//fPos[2] = GetRandomFloat(-5.0, 5.0);
	TeleportEntity(clone, fPos, fAngle, NULL_VECTOR);
	
	//random render color...
	SetEntityRenderColor( clone, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255) );
	
	return Plugin_Continue;
}

public void SetNormalAnimation(Handle event, const char[] name, bool dontBroadcast)
{
	int client1 = GetClientOfUserId(GetEventInt(event, "userid"));
	int client2 = GetClientOfUserId(GetEventInt(event, "subject"));
	if ( IsValidClientIndex(client1) )
	{
		g_iAnimsToPlay[client1] = 0;
		RemoveClone(client1);
	}
	if ( IsValidClientIndex(client2) )
	{
		g_iAnimsToPlay[client2] = 0;
		RemoveClone(client2);
	}
}

stock void RemoveClone(int client)
{
	if ( !IsValidClientIndex(client) )
		return;
	if ( IsValidClientInGame(client) )
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
	}
		
	int clone = EntRefToEntIndex(g_iClone[client]);
	if ( IsValidEntity(clone) )
	{
		AcceptEntityInput(clone, "ClearParent");
		AcceptEntityInput(clone, "Kill");
		//RemoveEntity(clone);
	}
	
	//PrintToChatAll("Clone removed successfully. Ref=%i, Index=%i!!", g_iClone[client], clone);
	
	g_iClone[client] = INVALID_ENT_REFERENCE;
	g_iAnimsToPlay[client] = 0;
	return;
}

stock bool CreateClone(int client)
{
	if ( !GetConVarBool(l4d_funny_animation_enabled) ) 
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
	clone = CreateEntityByName("prop_glowing_object");
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
	DispatchKeyValue(clone, "StartGlowing", "0");
	DispatchKeyValue(clone, "GlowForTeam", "2");
	SetEntityModel(clone, modelname);
	//DispatchSpawn(clone);
	SetEntityRenderMode(clone, RENDER_NONE); //make clone invisible temporarily
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

stock bool IsValidClientAlive(int client)
{
	if ( !IsValidClientInGame(client) )
		return false;
	
	if ( !IsPlayerAlive(client) )
		return false;
	
	return true;
}

stock bool IsPlayerTank(int client)
{
	/*decl String:playermodel[96];
	GetClientModel(client, playermodel, sizeof(playermodel));
	return (StrContains(playermodel, "hulk", false) > -1);*/
	if ( !IsValidClientInGame(client) )
		return false;
	if ( GetClientTeam(client)!=TEAM_INFECTED )
		return false;
	
	//sometimes Tank has m_zombieClass == 6 (maybe DLC3 tank)...
	if ( GetEntProp(client, Prop_Send, "m_zombieClass") >= 5 )
		return true;
	
	return false;
}

stock int Abs(int number)
{
	if ( number<0 )
		number *= -1;
	return number;
}

