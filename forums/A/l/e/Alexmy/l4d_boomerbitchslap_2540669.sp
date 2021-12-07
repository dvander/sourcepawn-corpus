#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.5"
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY


Handle cvar_enabled = null;
bool canslap[MAXPLAYERS+1];
bool gotslapped[MAXPLAYERS+1];
Handle SlapPower = null,       SlapCooldown = null,  SlapAnnounce = null, SlappedTime = null;
Handle boomer_claw_dmg = null, boomer_health = null, boomer_vomit = null, boomer_speed = null;

public Plugin myinfo = 
{
	name = "L4D_BoomerBitchSlap",
	author = "AtomicStryker",
	description = "Left 4 Dead Boomer Bitch Slap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=97952"
}


public void OnPluginStart()
{
	CreateConVar("l4d_boomerbitchslap_version", PLUGIN_VERSION, " Boomer Bitch Slap Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled    = CreateConVar("l4d_boomerbitchslap_enabled","1", " Enable/Disable the Boomer Bitch Slap Plugin ",              CVAR_FLAGS);
	SlapPower       = CreateConVar("l4d_boomerbitchslap_power","150.0", " How much Force is applied to the victim ",                CVAR_FLAGS);
	SlapCooldown    = CreateConVar("l4d_boomerbitchslap_cooldown","10.0", " How many seconds before Boomer can Slap again ",        CVAR_FLAGS);
	SlapAnnounce    = CreateConVar("l4d_boomerbitchslap_announce","0", " Do Slaps get announced in the Chat Area ",                 CVAR_FLAGS);
	SlappedTime     = CreateConVar("l4d_boomerbitchslap_disabletime","2.0", " For how many seconds cant a slapped Survivor Melee ", CVAR_FLAGS);
	
	boomer_claw_dmg = CreateConVar("l4d_boomer_claw_dmg", "4", "The damage of a Boomer melee    [Default 4]  ",FCVAR_NOTIFY);
	boomer_health   = CreateConVar("l4d_boomer_health", "4000", "Health Boomer                  [Default 50] ",FCVAR_NOTIFY);
	boomer_vomit    = CreateConVar("l4d_boomer_vomit", "0","Boomer can vomit on the survivors ? [Default 1]  ",FCVAR_NOTIFY);
	boomer_speed    = CreateConVar("l4d_boomer_speed", "220",   "The speed of a Boomer          [Default 175]",FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_boomerbitchslap");
	
	HookEvent("player_hurt",  PlayerHurt);	
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	SetConVarInt(FindConVar("boomer_pz_claw_dmg"), GetConVarInt(boomer_claw_dmg), true, false);
	SetConVarInt(FindConVar("z_exploding_health"), GetConVarInt(boomer_health),   true, false);
	SetConVarInt(FindConVar("z_vomit"),            GetConVarInt(boomer_vomit),    true, false);
	SetConVarInt(FindConVar("z_exploding_speed"),  GetConVarInt(boomer_speed),    true, false);
}

public Action PlayerHurt(Event event, const char [] name, bool dontBroadcast)
{
	int slapper = GetClientOfUserId(event.GetInt("attacker"));
	int target = GetClientOfUserId(event.GetInt("userid"));
	
	if (target == 0 || !IsClientInGame(target) || GetClientTeam(target) != 2) return Plugin_Continue;
	
	char weapon[256];
	GetEventString(event, "weapon", weapon, 256);
	if (StrEqual(weapon, "boomer_claw") && GetClientTeam(target) == 2 && GetConVarInt(cvar_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))
	{
		if (!IsFakeClient(target))
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(SlappedTime), ResetSlapped, target, TIMER_FLAG_NO_MAPCHANGE);
			PrintCenterText(target, "Got Bitch Slapped by %N!!!!", slapper);
			
			if (GetConVarInt(SlapAnnounce)) PrintToChatAll("%N was Bitch Slapped by %N and couldn't melee back", target, slapper);
			
			for (int i=1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i)) EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "You Bitch Slapped %N", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		float HeadingVector[3], AimVector[3];
		float power = GetConVarFloat(SlapPower);

		GetClientEyeAngles(slapper, HeadingVector);
	
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
		
		float current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		float resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = power*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(SlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(SlapCooldown), ResetSlap, slapper, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action ResetSlap(Handle timer, Handle slapper)
{
	canslap[slapper] = true;
}

public Action ResetSlapped(Handle timer, Handle target)
{
	gotslapped[target] = false;
}

public Action PlayerSpawn(Event event, const char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	{
		char class[100];
		if(client) GetClientModel(client, class, sizeof(class));
		if (StrContains(class, "boomer", false) != -1)
		{
			canslap[client]=true;
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (gotslapped[client])
	{
		if (buttons & IN_ATTACK2)
		{
			buttons &= ~IN_ATTACK2;
			PrintCenterText(client, "Can't melee after being Bitch Slapped!");
			FakeClientCommandEx(client, "vocalize ReviveMeINterrupted");
		}
	}
	return Plugin_Continue;
}