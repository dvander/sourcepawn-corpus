#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zr_tools>
#include <zombiereloaded>
#include <emitsoundany>

public Plugin myinfo =
{
	name        	= "[ZR] Zombie Class: Hunter",
	author      	= "Extr1m (Michail)",
	description 	= "Adds a unique class of zombies",
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

new Float:g_LeapLastTime[MAXPLAYERS + 1];
new bool:g_LeapClassEnable[MAXPLAYERS + 1]

//stock const char g_sound[] = "zr/hunter_jump.mp3";

public OnMapStart()
{
	decl String:buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);

	PrecacheSoundAny(SoundMP3); 

	for (new i = 1; i <= MaxClients; i++)
	{
		g_LeapLastTime[i] = INVALID_HANDLE;
	}
}

public void OnPluginStart()
{	
	gCV_PEnabled 		= 	CreateConVar("sm_hunter_enabled", "1", "Responsible for the operation of the class on the server", 0, true, 0.0, true, 1.0);
	gCV_PLeapCooldown 	= 	CreateConVar("sm_hunter_cooldown", "6.0", "The time between each jump", 0, true, 0.0, true, 60.0);
	gCV_PLeapPower		= 	CreateConVar("sm_hunter_leappower", "650.0", "The power of the jump", 0, true, 0.0, true, 2700.0);
	gCV_PSound_mp3		= 	CreateConVar("sm_hunter_sound", "zr/hunter_jump.mp3", "Way to the sound");
	
	gCV_PEnabled.AddChangeHook(ConVarChange);
	gCV_PLeapCooldown.AddChangeHook(ConVarChange);
	gCV_PLeapPower.AddChangeHook(ConVarChange);
	gCV_PSound_mp3.AddChangeHook(ConVarChange);
	
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PLeapCooldown = gCV_PLeapCooldown.FloatValue;
	gF_PLeapPower = gCV_PLeapPower.FloatValue;
	
	AutoExecConfig(true, "zr_class_hunter", "zombiereloaded");
	
	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	gB_PEnabled = gCV_PEnabled.BoolValue;
	gF_PLeapCooldown = gCV_PLeapCooldown.FloatValue;
	gF_PLeapPower = gCV_PLeapPower.FloatValue;

	gCV_PSound_mp3.GetString(SoundMP3, sizeof(SoundMP3));
	
	decl String:buffer[PLATFORM_MAX_PATH]; 
	Format(buffer, sizeof(buffer), "sound/%s", SoundMP3);

	AddFileToDownloadsTable(buffer);
	PrecacheSoundAny(SoundMP3); 
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	decl String:buffer[64];
	ZRT_GetClientAttributeString(client, "class_zombie", buffer, sizeof(buffer));
	
	if(StrEqual(buffer, "hunter", false))
		g_LeapClassEnable[client] = true;
	else
		g_LeapClassEnable[client] = false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{	
	if (gB_PEnabled && IsPlayerAlive(client) && ZR_IsClientZombie(client))
	{
		if(g_LeapClassEnable[client])
		{
			if (!(buttons & (IN_USE | IN_DUCK) == (IN_USE | IN_DUCK)))
				return Plugin_Continue;
		
			if (GetGameTime() - g_LeapLastTime[client] < gF_PLeapCooldown) 
			{
				PrintHintText(client, "Reloading - %.1f", gF_PLeapCooldown - (GetGameTime() - g_LeapLastTime[client]));
				return Plugin_Continue;
			}		
			
			if (!(GetEntityFlags(client) & FL_ONGROUND) || RoundToNearest(GetVectorLength(vel)) < 80)
				return Plugin_Continue;
				
			static Float:fwd[3];
			static Float:velocity[3];
			static Float:up[3];
			GetAngleVectors(angles, fwd, velocity, up);
			NormalizeVector(fwd, velocity);
			ScaleVector(velocity, gF_PLeapPower);

			float fOriginClient[3];
			GetClientAbsOrigin( client, fOriginClient );
			
			EmitAmbientSoundAny(SoundMP3, fOriginClient);
			SetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", velocity);

			g_LeapLastTime[client] = GetGameTime();
		}
	}
	return Plugin_Continue;
}		