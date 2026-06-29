#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombieplague>
#include <emitsoundany>

#pragma newdecls required

public Plugin ZombieClassGirl =
{
	name        	= "[ZP] Zombie Class: Hunter",
	author      	= "Extr1m (Michail)",
	description 	= "Addon of zombie classses",
	version     	= "1.0",
	url         	= "https://sourcemod.net/"
}

// Cvars
ConVar gCV_PEnabled = null;
ConVar gCV_PLeapCooldown = null;
ConVar gCV_PLeapPower = null;
ConVar gCV_PSound_mp3 = null;

// Cached cvars
bool 	gB_PEnabled = true;
float 	gF_PLeapCooldown;
float 	gF_PLeapPower;
char SoundMP3[PLATFORM_MAX_PATH];

float g_LeapLastTime[MAXPLAYERS + 1];

#define ZOMBIE_CLASS_NAME				"@Hunter"
#define ZOMBIE_CLASS_MODEL				"models/player/custom_player/cso2_zombi/zombie.mdl"	
#define ZOMBIE_CLASS_CLAW				"models/zombie/normal_f/hand/hand_zombie_normal_f.mdl"	
#define ZOMBIE_CLASS_HEALTH				4000
#define ZOMBIE_CLASS_SPEED				1.0
#define ZOMBIE_CLASS_GRAVITY			0.9
#define ZOMBIE_CLASS_KNOCKBACK			1.0
#define ZOMBIE_CLASS_LEVEL				1
#define ZOMBIE_CLASS_FEMALE				YES
#define ZOMBIE_CLASS_VIP				NO
#define ZOMBIE_CLASS_DURATION			0	
#define ZOMBIE_CLASS_COUNTDOWN			0
#define ZOMBIE_CLASS_REGEN_HEALTH		50
#define ZOMBIE_CLASS_REGEN_INTERVAL		1.0

int gZombieHunter;
#pragma unused gZombieHunter

public void OnPluginStart()
{
	gCV_PEnabled 		= 	CreateConVar("sm_hunter_enabled", "1", "Responsible for the operation of the class on the server", 0, true, 0.0, true, 1.0);
	gCV_PLeapCooldown 	= 	CreateConVar("sm_hunter_cooldown", "6.0", "The time between each jump", 0, true, 0.0, true, 60.0);
	gCV_PLeapPower		= 	CreateConVar("sm_hunter_leappower", "650.0", "The power of the jump", 0, true, 0.0, true, 2700.0);
	gCV_PSound_mp3		= 	CreateConVar("sm_hunter_sound", "zp/hunter_jump.mp3", "Way to the sound");
	
	gCV_PEnabled.AddChangeHook(ConVarChange);
	gCV_PLeapCooldown.AddChangeHook(ConVarChange);
	gCV_PLeapPower.AddChangeHook(ConVarChange);
	gCV_PSound_mp3.AddChangeHook(ConVarChange);
	
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PLeapCooldown = gCV_PLeapCooldown.FloatValue;
	gF_PLeapPower = gCV_PLeapPower.FloatValue;
	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
	
	AutoExecConfig(true, "zp_class_hunter", "sourcemod/zp_class");
	

	gZombieHunter = ZP_RegisterZombieClass(ZOMBIE_CLASS_NAME, 
	ZOMBIE_CLASS_MODEL, 
	ZOMBIE_CLASS_CLAW, 
	ZOMBIE_CLASS_HEALTH, 
	ZOMBIE_CLASS_SPEED, 
	ZOMBIE_CLASS_GRAVITY, 
	ZOMBIE_CLASS_KNOCKBACK, 
	ZOMBIE_CLASS_LEVEL,
	ZOMBIE_CLASS_FEMALE,
	ZOMBIE_CLASS_VIP, 
	ZOMBIE_CLASS_DURATION, 
	ZOMBIE_CLASS_COUNTDOWN, 
	ZOMBIE_CLASS_REGEN_HEALTH, 
	ZOMBIE_CLASS_REGEN_INTERVAL);
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PLeapCooldown = gCV_PLeapCooldown.FloatValue;
	gF_PLeapPower = gCV_PLeapPower.FloatValue;

	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
	
	char buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);
	PrecacheSoundAny(SoundMP3); 
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);

	PrecacheSoundAny(SoundMP3); 

	for (int i = 1; i <= MaxClients; i++)
	{
		g_LeapLastTime[i] = 0.0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{	
	if (gB_PEnabled && IsPlayerExist(client) && ZP_GetClientZombieClass(client) == gZombieHunter)
	{
		if (!(buttons & (IN_RELOAD | IN_DUCK) == (IN_RELOAD | IN_DUCK)))
			return Plugin_Continue;

		if (GetGameTime() - g_LeapLastTime[client] < gF_PLeapCooldown) 
		{
			PrintHintText(client, "Reloading - %.1f", gF_PLeapCooldown - (GetGameTime() - g_LeapLastTime[client]));
			return Plugin_Continue;
		}		

		if (!(GetEntityFlags(client) & FL_ONGROUND) || RoundToNearest(GetVectorLength(vel)) < 80)
			return Plugin_Continue;

		static float fwd[3];
		static float velocity[3];
		static float up[3];
		GetAngleVectors(angles, fwd, velocity, up);
		NormalizeVector(fwd, velocity);
		ScaleVector(velocity, gF_PLeapPower);

		float fOriginClient[3];
		GetClientAbsOrigin(client, fOriginClient);

		EmitAmbientSoundAny(SoundMP3, fOriginClient);
		SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", velocity);

		g_LeapLastTime[client] = GetGameTime();
	}
	return Plugin_Continue;
}