/*
// ====================================================================================================
Change Log:
0.0.1 (10-October-2022)
    - Initial release.
0.0.2 (10-October-2022)
    - added cVars
0.0.3 (11-October-2022)
    -  added dynamic height spawn code from silvers fork of Zuko & McFlurry [L4D2] Weapon/Zombie Spawner
0.0.4 (11-October-2022)
    -  added check for Exception reported: Client index -1 is invalid, suggestion by Marttt
0.0.5 (12-October-2022)
    -  added small firework on vanish
0.0.6 (19-Octover-2022)
    -  added TIMER_FLAG_NO_MAPCHANGE for mapchange
0.0.7 (31-Octover-2023)
    -  try to fix cvars & added boomer, hunter, smoker, tank

// ====================================================================================================
*/
/****************************************************************************************************
* Plugin     : L4D - Halloween Jumpscare
* Version    : 0.0.7
* Game       : Left 4 Dead
* Author     : Finishlast
*
* Testers    : Myself 
* Website    : www.l4d.com
* Purpose    : This plugin makes you pee in fear at halloween
* Thanks     : To Silvers for code that I don't fully understand 
*              https://forums.alliedmods.net/showthread.php?p=2008481
*	       Krufftys Killers & King_OXO reporting problem with invalid index
*	       Marttt suggetion to fix it
*	       Sout12 reporting problem with timer
****************************************************************************************************/


// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D] Halloween Jumpscare"
#define PLUGIN_AUTHOR                 "Finishlast"
#define PLUGIN_DESCRIPTION            "This plugin makes you pee in fear at halloween"
#define PLUGIN_VERSION                "0.0.7"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?p=2790590"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}



#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

Handle g_timer = INVALID_HANDLE; 


// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS			FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION	FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define PARTICLE_BOMB1			"mini_fireworks"

// ====================================================================================================
// Defines
// ====================================================================================================
#define SCARE1				"models/infected/witch.mdl"
#define SCARE2				"models/infected/smoker.mdl"
#define SCARE3				"models/infected/hunter.mdl"
#define SCARE4				"models/infected/boomer.mdl"
#define SCARE5				"models/infected/hulk.mdl"

#define SOUND_SCREAM1			"npc\\witch\\voice\\die\\headshot_death_1.wav"
#define SOUND_SCREAM2			"npc\\witch\\voice\\die\\female_death_1.wav"
#define SOUND_SCREAM3			"npc\\witch\\voice\\pain\\witch_pain_1.wav"
#define SOUND_SCREAM4			"npc\\witch\\voice\\attack\\female_distantscream1.wav"
#define SOUND_SCREAM5			"npc\\witch\\voice\\attack\\female_distantscream2.wav"
#define SOUND_SCREAM6			"npc\\witch\\voice\\retreat\\horrified_1.wav"
#define SOUND_SCREAM7			"npc\\witch\\voice\\retreat\\horrified_2.wav"
#define SOUND_SCREAM8			"npc\\witch\\voice\\retreat\\horrified_3.wav"
#define SOUND_SCREAM9			"npc\\witch\\voice\\retreat\\horrified_4.wav"
#define SOUND_TSCREAM1			"player\\tank\\voice\\yell\\hulk_yell_8.wav"
#define SOUND_TSCREAM2			"player\\tank\\voice\\yell\\hulk_yell_2.wav"
#define SOUND_SSCREAM1			"player\\smoker\\voice\\warn\\smoker_warn_01.wav"
#define SOUND_SSCREAM2			"player\\smoker\\voice\\warn\\smoker_warn_03.wav"
#define SOUND_HSCREAM1			"player\\hunter\\voice\\attack\\hunter_attackmix_01.wav"
#define SOUND_HSCREAM2			"player\\hunter\\voice\\attack\\hunter_pounce_04.wav"
#define SOUND_BSCREAM1			"player\\boomer\\voice\\alert\\boomer_alert_10.wav"
#define SOUND_BSCREAM2			"player\\boomer\\voice\\pain\\boomer_shoved_05.wav"




// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_JumpScareInterval;
ConVar g_hCvar_JumpScareChance;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float    g_fCvar_JumpScareInterval  = 30.0;
float dissolvePos[3];	

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int    g_iCvar_JumpScareChance= 10;
int ent_scare1;

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_halloween_jumpscare"


public void OnMapStart()
{
	PrecacheModel(SCARE1, true);
	PrecacheModel(SCARE2, true);
	PrecacheModel(SCARE3, true);
	PrecacheModel(SCARE4, true);
	PrecacheModel(SCARE5, true);
        PrecacheSound(SOUND_SCREAM1);
        PrecacheSound(SOUND_SCREAM2);
        PrecacheSound(SOUND_SCREAM3);
        PrecacheSound(SOUND_SCREAM4);
        PrecacheSound(SOUND_SCREAM5);
        PrecacheSound(SOUND_SCREAM6);
        PrecacheSound(SOUND_SCREAM7);
        PrecacheSound(SOUND_SCREAM8);
        PrecacheSound(SOUND_SCREAM9);
        PrecacheSound(SOUND_TSCREAM1);
        PrecacheSound(SOUND_TSCREAM2);
        PrecacheSound(SOUND_SSCREAM1);
        PrecacheSound(SOUND_SSCREAM2);
        PrecacheSound(SOUND_HSCREAM1);
        PrecacheSound(SOUND_HSCREAM2);
        PrecacheSound(SOUND_BSCREAM1);
        PrecacheSound(SOUND_BSCREAM2);


}

public void OnPluginStart()
{
	CreateConVar("l4d_tank_car_smash_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
  	g_hCvar_JumpScareInterval = CreateConVar("l4d_jumpscareinterval", 		"30.0", 	"Set jumpscare interval", CVAR_FLAGS);
   	g_hCvar_JumpScareChance = CreateConVar("l4d_jumpscarechance", 		"10", 	"Percent chance for a jumpscare. 1-100", CVAR_FLAGS);

   	// Load plugin configs from .cfg
   	AutoExecConfig(true, CONFIG_FILENAME);
	
	HookEvent("round_freeze_end", event_round_freeze_end, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	/* Clean up timers */
	if (g_timer != INVALID_HANDLE) {
		delete(g_timer);
		g_timer = INVALID_HANDLE;
	}  
}

public void OnConfigsExecuted()
{
    GetCvars();

}

public void GetCvars()
{
        g_fCvar_JumpScareInterval = GetConVarFloat(g_hCvar_JumpScareInterval);
        g_iCvar_JumpScareChance = g_hCvar_JumpScareChance.IntValue;
}

public void event_round_freeze_end(Event event, const char[] name, bool dontBroadcast)
{

	g_timer = CreateTimer(g_fCvar_JumpScareInterval, gate, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

}

public Action gate(Handle timer)
{
	int toscare = GetRandomPlayerFromTeam(2);
	if(toscare != -1)
	{
		int tempchance=GetRandomInt(1, 100);
		//PrintToChatAll("Chance upperlimit:  %i", tempchance);
		//PrintToChatAll("Chance Convar:  %i", g_iCvar_JumpScareChance);
		//PrintToChatAll("Who is to be scared?:  %i", toscare);
		//PrintToChatAll("Scareinterval?:  %f", GetConVarFloat(g_hCvar_JumpScareInterval));

 		//Chance 10% every 30sec
		if(tempchance <= g_iCvar_JumpScareChance)
		{		
		if(IsClientInGame(toscare) && IsPlayerAlive(toscare))
  		{
							switch (GetRandomInt(1,5))
			{
				case 1: 
				{
   				float vPos[3], vAng[3];		
				ent_scare1 = CreateEntityByName("prop_dynamic_override"); 
 				DispatchKeyValue(ent_scare1, "model", SCARE1);
				DispatchKeyValue(ent_scare1, "solid", "0");
				DispatchKeyValue(ent_scare1, "disableshadows", "1");
				DispatchKeyValue(ent_scare1, "DefaultAnim", "Idle_Pre_Retreat");
				SetVariantString("OnUser1 !self:Kill::3:-1");
				AcceptEntityInput(ent_scare1, "AddOutput");
				AcceptEntityInput(ent_scare1, "FireUser1"); 
				DispatchSpawn(ent_scare1);
				GetClientEyePosition(toscare, vPos);
				GetClientEyeAngles(toscare, vAng);
				vPos[2] -= 62;

				SetTeleportEndPoint(toscare, vPos, vAng);
				vAng[0] = 0.0;	
				vAng[1] += 180.0;
				vAng[2] = 0.0;

				TeleportEntity(ent_scare1, vPos, vAng, NULL_VECTOR);
				dissolvePos=vPos;
  				PrintToChatAll("[SM] BOOOOOOOOOO!");
				CreateTimer(2.6, dissolve);
				switch (GetRandomInt(1,9))
					{
						case 1: Command_Play(SOUND_SCREAM1);
						case 2: Command_Play(SOUND_SCREAM2);
						case 3: Command_Play(SOUND_SCREAM3);
						case 4: Command_Play(SOUND_SCREAM4);
						case 5: Command_Play(SOUND_SCREAM5);
						case 6: Command_Play(SOUND_SCREAM6);
						case 7: Command_Play(SOUND_SCREAM7);
						case 8: Command_Play(SOUND_SCREAM8);
						case 9: Command_Play(SOUND_SCREAM9);
					}
				}
				case 2: 
				{
   				float vPos[3], vAng[3];		
				ent_scare1 = CreateEntityByName("prop_dynamic_override"); 
 				DispatchKeyValue(ent_scare1, "model", SCARE2);
				DispatchKeyValue(ent_scare1, "solid", "0");
				DispatchKeyValue(ent_scare1, "disableshadows", "1");
				DispatchKeyValue(ent_scare1, "DefaultAnim", "Idle_Upper_Knife");
				SetVariantString("OnUser1 !self:Kill::3:-1");
				AcceptEntityInput(ent_scare1, "AddOutput");
				AcceptEntityInput(ent_scare1, "FireUser1"); 
				DispatchSpawn(ent_scare1);
				GetClientEyePosition(toscare, vPos);
				GetClientEyeAngles(toscare, vAng);
				vPos[2] -= 62;

				SetTeleportEndPoint(toscare, vPos, vAng);
				vAng[0] = 0.0;	
				vAng[1] += 180.0;
				vAng[2] = 0.0;

				TeleportEntity(ent_scare1, vPos, vAng, NULL_VECTOR);
				dissolvePos=vPos;
  				PrintToChatAll("[SM] BOOOOOOOOOO!");
				CreateTimer(2.6, dissolve);
				switch (GetRandomInt(1,2))
					{
						case 1: Command_Play(SOUND_SSCREAM1);
						case 2: Command_Play(SOUND_SSCREAM2);
					}
				}
				case 3: 
				{
   				float vPos[3], vAng[3];		
				ent_scare1 = CreateEntityByName("prop_dynamic_override"); 
 				DispatchKeyValue(ent_scare1, "model", SCARE3);
				DispatchKeyValue(ent_scare1, "solid", "0");
				DispatchKeyValue(ent_scare1, "disableshadows", "1");
				DispatchKeyValue(ent_scare1, "DefaultAnim", "Melee");
				SetVariantString("OnUser1 !self:Kill::3:-1");
				AcceptEntityInput(ent_scare1, "AddOutput");
				AcceptEntityInput(ent_scare1, "FireUser1"); 
				DispatchSpawn(ent_scare1);
				GetClientEyePosition(toscare, vPos);
				GetClientEyeAngles(toscare, vAng);
				vPos[2] -= 62;

				SetTeleportEndPoint(toscare, vPos, vAng);
				vAng[0] = 0.0;	
				vAng[1] += 180.0;
				vAng[2] = 0.0;

				TeleportEntity(ent_scare1, vPos, vAng, NULL_VECTOR);
				dissolvePos=vPos;
  				PrintToChatAll("[SM] BOOOOOOOOOO!");
				CreateTimer(2.6, dissolve);
				switch (GetRandomInt(1,2))
					{
						case 1: Command_Play(SOUND_HSCREAM1);
						case 2: Command_Play(SOUND_HSCREAM2);
					}
				}
				case 4: 
				{
   				float vPos[3], vAng[3];		
				ent_scare1 = CreateEntityByName("prop_dynamic_override"); 
 				DispatchKeyValue(ent_scare1, "model", SCARE4);
				DispatchKeyValue(ent_scare1, "solid", "0");
				DispatchKeyValue(ent_scare1, "disableshadows", "1");
				DispatchKeyValue(ent_scare1, "DefaultAnim", "Vomit_Attack");
				SetVariantString("OnUser1 !self:Kill::3:-1");
				AcceptEntityInput(ent_scare1, "AddOutput");
				AcceptEntityInput(ent_scare1, "FireUser1"); 
				DispatchSpawn(ent_scare1);
				GetClientEyePosition(toscare, vPos);
				GetClientEyeAngles(toscare, vAng);
				vPos[2] -= 62;

				SetTeleportEndPoint(toscare, vPos, vAng);
				vAng[0] = 0.0;	
				vAng[1] += 180.0;
				vAng[2] = 0.0;

				TeleportEntity(ent_scare1, vPos, vAng, NULL_VECTOR);
				dissolvePos=vPos;
  				PrintToChatAll("[SM] BOOOOOOOOOO!");
				CreateTimer(2.6, dissolve);
				switch (GetRandomInt(1,2))
					{
						case 1: Command_Play(SOUND_BSCREAM1);
						case 2: Command_Play(SOUND_BSCREAM2);
					}
				}


				case 5: 
				{
   				float vPos[3], vAng[3];		
				ent_scare1 = CreateEntityByName("prop_dynamic_override"); 
 				DispatchKeyValue(ent_scare1, "model", SCARE5);
				DispatchKeyValue(ent_scare1, "solid", "0");
				DispatchKeyValue(ent_scare1, "disableshadows", "1");
				DispatchKeyValue(ent_scare1, "DefaultAnim", "Idle_Yell");
				SetVariantString("OnUser1 !self:Kill::3:-1");
				AcceptEntityInput(ent_scare1, "AddOutput");
				AcceptEntityInput(ent_scare1, "FireUser1"); 
				DispatchSpawn(ent_scare1);
				GetClientEyePosition(toscare, vPos);
				GetClientEyeAngles(toscare, vAng);
				vPos[2] -= 62;

				SetTeleportEndPoint(toscare, vPos, vAng);
				vAng[0] = 0.0;	
				vAng[1] += 180.0;
				vAng[2] = 0.0;

				TeleportEntity(ent_scare1, vPos, vAng, NULL_VECTOR);
				dissolvePos=vPos;
  				PrintToChatAll("[SM] BOOOOOOOOOO!");
				CreateTimer(2.6, dissolve);
				switch (GetRandomInt(1,2))
					{
						case 1: Command_Play(SOUND_TSCREAM1);
						case 2: Command_Play(SOUND_TSCREAM2);
					}
				}


				}

				
			}


                }


	}
	return Plugin_Continue;
}
 
public Action dissolve(Handle timer)
{
    	int entity1;
	entity1 = CreateEntityByName("info_particle_system");
	if( entity1 != -1 )
	{
		DispatchKeyValue(entity1, "effect_name", PARTICLE_BOMB1);
		DispatchSpawn(entity1);
		ActivateEntity(entity1);
		AcceptEntityInput(entity1, "start");
		TeleportEntity(entity1, dissolvePos, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("OnUser1 !self:Kill::2:-1");
		AcceptEntityInput(entity1, "AddOutput");
		AcceptEntityInput(entity1, "FireUser1");
	}
	return Plugin_Continue;
}

stock int GetRandomPlayerFromTeam(int team)
{
	int[] clients = new int[MaxClients + 1];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetClientTeam(i) == team && IsPlayerAlive(i)))
	clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}

public Action Command_Play(const char[] arguments)
{
	for(int i=1; i<=MaxClients; i++)
	{
		if( !IsClientInGame(i) )
		continue;
     	  	ClientCommand(i, "playgamesound %s", arguments);
		

	}  
	return Plugin_Continue;
}

float GetGroundHeight(float vPos[3])
{
    float vAng[3];

    Handle trace = TR_TraceRayFilterEx(vPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_ALL, RayType_Infinite, _TraceFilter);
    if( TR_DidHit(trace) )
        TR_GetEndPosition(vAng, trace);

    delete trace;
    return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
    float vAngles[3], vOrigin[3];

    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);
    vAngles[0]=20.0;
    Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, _TraceFilter);

    if( TR_DidHit(trace) )
    {
        float vBuffer[3], vStart[3], distance;

        TR_GetEndPosition(vStart, trace);
        distance = -15.0;
        GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
        vPos[0] = vStart[0] + (vBuffer[0] * distance);
        vPos[1] = vStart[1] + (vBuffer[1] * distance);
        vPos[2] = vStart[2] + (vBuffer[2] * distance);
        vPos[2] = GetGroundHeight(vPos);
        if( vPos[2] == 0.0 )
        {
            delete trace;
            return false;
        }

        vAng = vAngles;
    }
    else
    {
        delete trace;
        return false;
    }

    delete trace;
    return true;
} 

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}