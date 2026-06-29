#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY


new Handle:cvar_enabled = INVALID_HANDLE;
new bool:canslap[MAXPLAYERS+1];
new bool:gotslapped[MAXPLAYERS+1];
new Handle:SlapPower = INVALID_HANDLE;
new Handle:SlapCooldown = INVALID_HANDLE;
new Handle:SlapAnnounce = INVALID_HANDLE;
new Handle:SlappedTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D_BoomerBitchSlap",
	author = " AtomicStryker",
	description = "Left 4 Dead Boomer Bitch Slap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=97952"
}


public OnPluginStart()
{
	CreateConVar("l4d_boomerbitchslap_version", PLUGIN_VERSION, " Boomer Bitch Slap Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_enabled = CreateConVar("l4d_boomerbitchslap_enabled","1", " Enable/Disable the Boomer Bitch Slap Plugin ", CVAR_FLAGS);
	SlapPower = CreateConVar("l4d_boomerbitchslap_power","150.0", " How much Force is applied to the victim ", CVAR_FLAGS);
	SlapCooldown = CreateConVar("l4d_boomerbitchslap_cooldown","10.0", " How many seconds before Boomer can Slap again ", CVAR_FLAGS);
	SlapAnnounce = CreateConVar("l4d_boomerbitchslap_announce","1", " Do Slaps get announced in the Chat Area ", CVAR_FLAGS);
	SlappedTime = CreateConVar("l4d_boomerbitchslap_disabletime","3.0", " For how many seconds cant a slapped Survivor Melee ", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_boomerbitchslap");
	
	HookEvent("player_hurt",PlayerHurt);	
	HookEvent("player_spawn", PlayerSpawn);
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new slapper = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (target == 0 || !IsClientInGame(target) || GetClientTeam(target) != 2) return Plugin_Continue;
	
	decl String:weapon[256];
	GetEventString(event, "weapon", weapon, 256);
		
	if ( StrEqual(weapon, "boomer_claw") && GetClientTeam(target) == 2 && GetConVarInt(cvar_enabled) && canslap[slapper] && !GetEntProp(target, Prop_Send, "m_isIncapacitated"))
	{
		//PrintToChatAll("Boomer Attack caught, setting Melee Fatigue");
		if (!IsFakeClient(target)) // none of this applies for bots.
		{
			gotslapped[target] = true;
			CreateTimer(GetConVarFloat(SlappedTime), ResetSlapped, target);
			PrintCenterText(target, "Got Bitch Slapped by %N!!!!", slapper);
			
			if (GetConVarInt(SlapAnnounce)) PrintToChatAll("%N was Bitch Slapped by %N and couldn't melee back", target, slapper);
			
			//EmitSoundToClient(target, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
			// "physics/body/body_medium_break3.wav"
			// "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav"
			// "doors/heavy_metal_stop1.wav"
			
			for (new i=1; i <= MaxClients; i++)
			{
				// If it's not the boomer himself, emit the sound to the client (it will appear to come from the victim)
				if (IsClientInGame(i))
					EmitSoundToClient(i, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav", target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
			}
		}
		
		PrintCenterText(slapper, "You Bitch Slapped %N", target);
		EmitSoundToClient(slapper, "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav");
		
		decl Float:HeadingVector[3], Float:AimVector[3];
		new Float:power = GetConVarFloat(SlapPower);

		GetClientEyeAngles(slapper, HeadingVector);
	
		AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
		AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
		
		decl Float:current[3];
		GetEntPropVector(target, Prop_Data, "m_vecVelocity", current);
		
		decl Float:resulting[3];
		resulting[0] = FloatAdd(current[0], AimVector[0]);	
		resulting[1] = FloatAdd(current[1], AimVector[1]);
		resulting[2] = power*2;
		
		TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
		
		if (GetConVarFloat(SlapCooldown)>0)
		{
			canslap[slapper] = false;
			CreateTimer(GetConVarFloat(SlapCooldown), ResetSlap, slapper);
		}
	}
	return Plugin_Continue;
	
}

public Action:ResetSlap(Handle:timer, Handle:slapper)
{
	canslap[slapper] = true;
}

public Action:ResetSlapped(Handle:timer, Handle:target)
{
	gotslapped[target] = false;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client)==3)
	{
		decl String:class[100];
		GetClientModel(client, class, sizeof(class));
		
		if (StrContains(class, "boomer", false) != -1)
		{
			canslap[client]=true;
		}
	}
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
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