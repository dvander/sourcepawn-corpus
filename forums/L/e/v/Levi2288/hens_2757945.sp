#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Levi2288 "
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required
char chickenModel[] = "models/chicken/chicken.mdl";
//char chickenDeathSounds[][] = ("ambient/creatures/chicken_death_01.wav", "ambient/creatures/chicken_death_02.wav", "ambient/creatures/chicken_death_03.wav");
char chickenSec[][] = {"ACT_WALK", "ACT_RUN", "ACT_IDLE", "ACT_JUMP", "ACT_GLIDE", "ACT_LAND", "ACT_HOP"};
int playerSkin[MAXPLAYERS + 1] = -1;
int serverSkin[MAXPLAYERS + 1] = 0;
Handle animationsTimer[MAXPLAYERS + 1];
int lastFlags[MAXPLAYERS + 1];

bool wasIdle[MAXPLAYERS + 1] = false;
bool wasRunning[MAXPLAYERS + 1] = false;
bool isWalking[MAXPLAYERS + 1] = false;
bool wasWalking[MAXPLAYERS + 1] = false;
bool isMoving[MAXPLAYERS + 1] = false;
int flyCounter[MAXPLAYERS + 1];

bool isChicken[MAXPLAYERS + 1];
bool g_bHensEnable = false;

char playersModels[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

bool wasRotLocked[MAXPLAYERS + 1];

const float chickenRunSpeed = 102.0; //Match real chicken run speed (kind of)
const float chickenWalkSpeed = 6.5; //Match real chicken walk speed (kind of)
const float maxFallSpeed = -100.0;

ConVar sm_chickens_canattack;

int chickens[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Hens plugin",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_hens", hens, ADMFLAG_ROOT);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	sm_chickens_canattack = CreateConVar("sm_chickens_canattack", "1","can chickens use weapons?");
	
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	DisableChicken(client_index);
	g_bHensEnable = false;
	PrintToChatAll("\x04[Hens]\x01 Chicken mode \x09Off\x01");
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client_index = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_bHensEnable && GetClientTeam(client_index) == CS_TEAM_T)
	{
		SetChicken(client_index);
	}
	else
	{
		DisableChicken(client_index);
	}

}
public void OnMapStart()
{

	PrecacheModel(chickenModel, true);
}

public Action hens(int client, int args)
{
	g_bHensEnable = !g_bHensEnable;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i) && !IsFakeClient(i))
			{
				SetChicken(i);
			}
		}
	}
	
	PrintToChatAll("\x04[Hens]\x01 Chicken mode \x09On\x01");
}

void SetChicken(int client_index)
{
	isChicken[client_index] = true;
	//Delete fake model to prevent glitches
	DisableFakeModel(client_index);
	
	// Get player model to revert it on chicken disable
	char modelName[PLATFORM_MAX_PATH];
	GetEntPropString(client_index, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	playersModels[client_index] = modelName;
	
	//Only for hitbox -> Collision hull still the same
	SetEntityModel(client_index, chickenModel);
	//Little chicken is weak
	SetEntityHealth(client_index, 100);
	//Hide the real player model (because animations won't play)
	//SDKHook(client_index, SDKHook_SetTransmit, Hook_SetTransmit); //Crash server
	SetEntityRenderMode(client_index, RENDER_NONE); //Make sure immunity alpha is set to 0 or it won't work
	//Create a fake chicken model with animation
	CreateFakeModel(client_index);
}


void CreateFakeModel(int client_index)
{
	chickens[client_index] = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(chickens[client_index])) {
		SetEntityModel(chickens[client_index], chickenModel);
		
		//Set skin/hat
		if (playerSkin[client_index] != -1)
			SetEntProp(chickens[client_index], Prop_Send, "m_nSkin", playerSkin[client_index]); //0=normal 1=brown chicken
		else
			SetEntProp(chickens[client_index], Prop_Send, "m_nSkin", serverSkin[client_index]);
		//Teleports the chicken at the player's feet
		
		//Parents the chicken to the player and attaches it
		SetVariantString("!activator"); AcceptEntityInput(chickens[client_index], "SetParent", client_index, chickens[client_index], 0);
		float nullPos[3], nullRot[3];
		TeleportEntity(chickens[client_index], nullPos, nullRot, NULL_VECTOR);
		//Keep player's hitbox, disable collisions for the fake chicken
		DispatchKeyValue(chickens[client_index], "solid", "0");
		//Spawn the chicken!
		DispatchSpawn(chickens[client_index]);
		ActivateEntity(chickens[client_index]);
		//Sets the base animation (to spawn with)
		SetVariantString(chickenSec[2]); AcceptEntityInput(chickens[client_index], "SetAnimation");
		//Plays the animation
		animationsTimer[client_index] = CreateTimer(0.1, Timer_ChickenAnim, GetClientUserId(client_index), TIMER_REPEAT);
	}
}

public Action Timer_ChickenAnim(Handle timer, int userid) //Must reset falling anim each 1s (doesn't loop)
{
	int client_index = GetClientOfUserId(userid);
	if (client_index && IsClientInGame(client_index) && IsValidEntity(chickens[client_index]))
	{
		int currentFlags = GetEntityFlags(client_index);
		//If client started fly, change his animation (falling), or set it back if 1s passed
		if (!(currentFlags & FL_ONGROUND) && flyCounter[client_index] == 0)
		{
			SetVariantString(chickenSec[4]); AcceptEntityInput(chickens[client_index], "SetAnimation");
			wasRunning[client_index] = false;
			wasIdle[client_index] = false;
			wasWalking[client_index] = false;
			flyCounter[client_index]++;
			//PrintToChat(client_index, "Falling");
		}
		//If flying, count time passed
		else if (!(currentFlags & FL_ONGROUND))
		{
			flyCounter[client_index]++;
			if (flyCounter[client_index] == 9)
				flyCounter[client_index] = 0;
		}
		//If grounded
		else if (currentFlags & FL_ONGROUND)
		{
			flyCounter[client_index] = 0;
			//If client is not moving, not already idle, set him idle
			if (!isMoving[client_index] && !wasIdle[client_index])
			{
				SetVariantString(chickenSec[2]); AcceptEntityInput(chickens[client_index], "SetAnimation");
				wasRunning[client_index] = false;
				wasIdle[client_index] = true;
				wasWalking[client_index] = false;
				//PrintToChat(client_index, "Idle");
			}
			//if pressing the walk key, is not already walking, is moving, set him walking
			else if (isWalking[client_index] && !wasWalking[client_index] && isMoving[client_index])
			{
				SetVariantString(chickenSec[0]); AcceptEntityInput(chickens[client_index], "SetAnimation");
				wasRunning[client_index] = false;
				wasIdle[client_index] = false;
				wasWalking[client_index] = true;
				//PrintToChat(client_index, "Walking");
			}
			//if is not pressing walk, not already running, is moving, set him running
			else if (!isWalking[client_index] && !wasRunning[client_index] && isMoving[client_index])
			{
				SetVariantString(chickenSec[1]); AcceptEntityInput(chickens[client_index], "SetAnimation");
				wasRunning[client_index] = true;
				wasIdle[client_index] = false;
				wasWalking[client_index] = false;
				//PrintToChat(client_index, "Running");
			}
		}
		lastFlags[client_index] = currentFlags;
	}
}

void DisableFakeModel(int client_index)
{
	if (chickens[client_index] != 0 && IsValidEdict(chickens[client_index]))
	{
		RemoveEdict(chickens[client_index]);
		chickens[client_index] = 0;
	}
}

public void SetClientSpeed(int client_index)
{
	float vel[3];
	float factor;
	GetEntPropVector(client_index, Prop_Data, "m_vecVelocity", vel);
	float velNorm = SquareRoot(vel[0]*vel[0] + vel[1]*vel[1] + vel[2]*vel[2]);
	if (isWalking[client_index] && velNorm > chickenWalkSpeed)
		factor = chickenWalkSpeed;
	else if (!isWalking[client_index] && velNorm > chickenRunSpeed)
		factor = chickenRunSpeed;
	
	for (int i = 0; i < sizeof(vel); i++)
	{
		if (factor > 0.0)
		{
			vel[i] /= velNorm;
			vel[i] *= factor;
		}
	}
	TeleportEntity(client_index, NULL_VECTOR, NULL_VECTOR, vel);
}

public void SlowPlayerFall(int client_index)
{
	float vel[3];
	GetEntPropVector(client_index, Prop_Data, "m_vecVelocity", vel);
	if (vel[2] < 0.0)
	{
		float oldSpeed = vel[2];
		// Player is falling too fast, lets slow him to maxFallSpeed
		if(vel[2] < maxFallSpeed)
			vel[2] = maxFallSpeed;
		// Fallspeed changed
		if(oldSpeed != vel[2])
			TeleportEntity(client_index, NULL_VECTOR, NULL_VECTOR, vel);
	}
}

public Action OnPlayerRunCmd(int client_index, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client_index) || !isChicken[client_index])
		return Plugin_Continue;
		
	if (buttons & IN_ATTACK && isChicken[client_index] && sm_chickens_canattack)
	{
		buttons &= ~IN_ATTACK;
    	//return Plugin_Continue;
	}
	
	
	//Change player's animations based on key pressed
	isWalking[client_index] = (buttons & IN_SPEED) || (buttons & IN_DUCK);
	isMoving[client_index] = vel[0] > 0.0 || vel[0] < 0.0;
	if (isMoving[client_index] || !(GetEntityFlags(client_index) & FL_ONGROUND))
		SetRotationLock(client_index, true);
	else
		SetRotationLock(client_index, false);
	
	if ((buttons & IN_JUMP) && !(GetEntityFlags(client_index) & FL_ONGROUND))
	{
		SlowPlayerFall(client_index);
	}
	
	
	return Plugin_Changed;
}

void SetRotationLock(int client_index, bool enabled)
{
	if (enabled && !wasRotLocked[client_index])
	{
		SetVariantString("!activator"); AcceptEntityInput(chickens[client_index], "SetParent", client_index, chickens[client_index], 0);
		float nullPos[3], nullRot[3];
		TeleportEntity(chickens[client_index], nullPos, nullRot, NULL_VECTOR);
		wasRotLocked[client_index] = true;
	}
	else if (!enabled)
	{
		AcceptEntityInput(chickens[client_index], "SetParent");
		float pos[3];
		GetClientAbsOrigin(client_index, pos);
		TeleportEntity(chickens[client_index], pos, NULL_VECTOR, NULL_VECTOR);
		wasRotLocked[client_index] = false;
	}
}

public void DisableChicken(int client)
{

	isChicken[client] = false;
	DisableFakeModel(client);
	SetEntityRenderMode(client, RENDER_NORMAL);


}