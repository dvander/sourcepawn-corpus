#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

#define CVAR_FLAGS 									FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

#define CHARACTER_NICK								0
#define CHARACTER_ROCHELLE							1
#define CHARACTER_COACH								2
#define CHARACTER_ELLIS								3

#define STRING_LENGHT								56

static const String:GAMEDATA_FILENAME[]				= "l4d2addresses";
static const String:INCAP_ENTPROP[]					= "m_isIncapacitated";
static const String:HANGING_ENTPROP[]				= "m_isHangingFromLedge";
static const String:LEDGEFALLING_ENTPROP[]			= "m_isFallingFromLedge";
static const String:VELOCITY_ENTPROP[]				= "m_vecVelocity";
//static const String:CHARACTER_ENTPROP[]				= "m_survivorCharacter";
static const String:BOOMER_WEAPON[]					= "boomer_claw";
static const String:PUNCH_SOUND[]					= "player/survivor/hit/int/Punch_Boxing_FaceHit1.wav";
													// "physics/body/body_medium_break3.wav"
													// "doors/heavy_metal_stop1.wav"

static const Float:SLAP_VERTICAL_MULTIPLIER			= 1.5;
static const TEAM_SURVIVOR							= 2;


static Handle:cvar_enabled							= INVALID_HANDLE;
static Handle:cvar_slapPower						= INVALID_HANDLE;
static Handle:cvar_slapCooldownTime					= INVALID_HANDLE;
static Handle:cvar_slapAnnounceMode					= INVALID_HANDLE;
static Handle:cvar_slapOffLedges					= INVALID_HANDLE;

static Float:lastSlapTime[MAXPLAYERS+1]				= 0.0;

public Plugin:myinfo = 
{
	name = "L4D2 Boomer Bitch Slap",
	author = " AtomicStryker",
	description = "Left 4 Dead 2 Boomer Bitch Slap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=97952"
}

public OnPluginStart()
{
	Require_L4D2();

	CreateConVar("l4d2_boomerbitchslap_version", PLUGIN_VERSION, " L4D2 Boomer Bitch Slap Plugin Version ", CVAR_FLAGS|FCVAR_DONTRECORD);
	
	cvar_enabled = CreateConVar("l4d2_boomerbitchslap_enabled", "1", " Enable/Disable the Boomer Bitch Slap Plugin ", CVAR_FLAGS);
	cvar_slapPower = CreateConVar("l4d2_boomerbitchslap_power", "150.0", " How much Force is applied to the victim ", CVAR_FLAGS);
	cvar_slapCooldownTime = CreateConVar("l4d2_boomerbitchslap_cooldown", "15.0", " How many seconds before Boomer can Slap again ", CVAR_FLAGS);
	cvar_slapAnnounceMode = CreateConVar("l4d2_boomerbitchslap_announce", "1", " Do Slaps get announced in the Chat Area ", CVAR_FLAGS);
	cvar_slapOffLedges = CreateConVar("l4d2_boomerbitchslap_ledgeslap", "0", " Enable/Disable Slapping hanging people off ledges ", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d2_boomerbitchslap");
	
	HookEvent("player_hurt", PlayerHurt);
}

public Action:PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new slapper = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!slapper) slapper = 1;
	if (!target || !IsClientInGame(target)) return;
	
	decl String:weapon[STRING_LENGHT];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if (GetConVarInt(cvar_enabled)
		&& GetClientTeam(target) == TEAM_SURVIVOR
		&& StrEqual(weapon, BOOMER_WEAPON)
		&& CanSlapAgain(slapper))
	{
		if (!GetEntProp(target, Prop_Send, INCAP_ENTPROP))
		{
			if (!IsFakeClient(target)) // none of this applies for bots.
			{
				PrintCenterText(target, "Got Bitch Slapped by %N!!!", slapper);
				
				if (GetConVarInt(cvar_slapAnnounceMode)) PrintToChatAll("\x04%N\x01 was \x02Bitch Slapped\x01 by \x04%N\x01!", target, slapper);
				
				//decl String:painSound[STRING_LENGHT];
				//GetSurvivorPainSound(target, painSound);
				
				for (new i=1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						EmitSoundToClient(i, PUNCH_SOUND, target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
						//EmitSoundToClient(i, painSound, target, SNDCHAN_AUTO, SNDLEVEL_GUNFIRE);
					}
				}
			}
			
			PrintCenterText(slapper, "YOU BITCHSLAPPED %N", target);
			
			decl Float:HeadingVector[3], Float:AimVector[3];
			new Float:power = GetConVarFloat(cvar_slapPower);

			GetClientEyeAngles(slapper, HeadingVector);
		
			AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
			AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
			
			decl Float:current[3];
			GetEntPropVector(target, Prop_Data, VELOCITY_ENTPROP, current);
			
			decl Float:resulting[3];
			resulting[0] = FloatAdd(current[0], AimVector[0]);	
			resulting[1] = FloatAdd(current[1], AimVector[1]);
			resulting[2] = power * SLAP_VERTICAL_MULTIPLIER;
			
			L4D2_Fling(target, resulting, slapper);
			
			lastSlapTime[slapper] = GetEngineTime();
		}
		else if (GetEntProp(target, Prop_Send, HANGING_ENTPROP) && GetConVarBool(cvar_slapOffLedges))
		{
			SetEntProp(target, Prop_Send, INCAP_ENTPROP, 0);
			SetEntProp(target, Prop_Send, HANGING_ENTPROP, 0);
			SetEntProp(target, Prop_Send, LEDGEFALLING_ENTPROP, 0);
		
			StopFallingSounds(target);
			
			PrintCenterText(slapper, "YOU BITCHSLAPPED %N", target);
			PrintCenterText(target, "Got Bitch Slapped by %N!!!", slapper);
		}
	}
}

static bool:CanSlapAgain(client)
{
	return ((GetEngineTime() - lastSlapTime[client]) > GetConVarFloat(cvar_slapCooldownTime));
}

// CTerrorPlayer::Fling(Vector  const&, PlayerAnimEvent_t, CBaseCombatCharacter *, float)
stock L4D2_Fling(target, Float:vector[3], attacker, Float:incaptime = 3.0)
{
	new Handle:MySDKCall = INVALID_HANDLE;
	new Handle:ConfigFile = LoadGameConfigFile(GAMEDATA_FILENAME);
	
	StartPrepSDKCall(SDKCall_Player);
	new bool:bFlingFuncLoaded = PrepSDKCall_SetFromConf(ConfigFile, SDKConf_Signature, "CTerrorPlayer_Fling");
	if(!bFlingFuncLoaded)
	{
		LogError("Could not load the Fling signature");
	}
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);

	MySDKCall = EndPrepSDKCall();
	if(MySDKCall == INVALID_HANDLE)
	{
		LogError("Could not prep the Fling function");
	}
	
	SDKCall(MySDKCall, target, vector, 76, attacker, incaptime); //76 is the 'got bounced' animation in L4D2
}

stock Require_L4D2()
{
	decl String:game[32];
	GetGameFolderName(game, sizeof(game));
	if (!StrEqual(game, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
}

stock StopFallingSounds(client)
{
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangTwoHands");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangOneHand");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFingers");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangAboutToFall");
	ClientCommand(client, "music_dynamic_stop_playing Event.LedgeHangFalling");
}

/*
static GetSurvivorPainSound(target, String:painSound[STRING_LENGHT-1])
{
	switch (GetEntProp(target, Prop_Send, CHARACTER_ENTPROP))
	{
		case CHARACTER_NICK:
		{
			switch (GetRandomInt(1,7))
			{
				case 1:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical01.wav");
				case 2:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical02.wav");
				case 3:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical03.wav");
				case 4:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical04.wav");
				case 5:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical05.wav");
				case 6:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical06.wav");
				case 7:		Format(painSound, sizeof(painSound), "player/survivor/voice/gambler/hurtcritical07.wav");
			}
		}
		case CHARACTER_ROCHELLE:
		{
			switch (GetRandomInt(1,4))
			{
				case 1:		Format(painSound, sizeof(painSound), "player/survivor/voice/producer/hurtcritical01.wav");
				case 2:		Format(painSound, sizeof(painSound), "player/survivor/voice/producer/hurtcritical02.wav");
				case 3:		Format(painSound, sizeof(painSound), "player/survivor/voice/producer/hurtcritical03.wav");
				case 4:		Format(painSound, sizeof(painSound), "player/survivor/voice/producer/hurtcritical04.wav");
			}
		}
		case CHARACTER_COACH:
		{
			switch (GetRandomInt(1,8))
			{
				case 1:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical01.wav");
				case 2:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical02.wav");
				case 3:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical03.wav");
				case 4:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical04.wav");
				case 5:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical05.wav");
				case 6:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical06.wav");
				case 7:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical07.wav");
				case 8:		Format(painSound, sizeof(painSound), "player/survivor/voice/coach/hurtcritical08.wav");
			}
		}
		case CHARACTER_ELLIS:
		{
			switch (GetRandomInt(1,6))
			{
				case 1:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical01.wav");
				case 2:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical02.wav");
				case 3:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical03.wav");
				case 4:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical04.wav");
				case 5:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical05.wav");
				case 6:		Format(painSound, sizeof(painSound), "player/survivor/voice/mechanic/hurtcritical06.wav");
			}
		}
	}
}
*/