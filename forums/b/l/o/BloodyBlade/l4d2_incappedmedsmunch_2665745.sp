#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.1.9"

#define STRING_LENGTH		32
static const int TEAM_SURVIVORS						= 2;
static const int PILLS_ADRENALINE_SLOT				= 4;
static const int PASS_PILLS_MINIMUM_DISTANCE		= 200;


static Handle MunchTimer[MAXPLAYERS+1]; //if run through, revives the player. gets aborted by button or hurt event
static bool buttondelay[MAXPLAYERS+1];
static bool IncapDelay[MAXPLAYERS+1];
static bool DelayedAdvertise[MAXPLAYERS+1];
static bool IsMunchingMed[MAXPLAYERS+1]; //lets the hooks find the players they need to check up

static ConVar DelaySetting;
static ConVar DropCVAR;
static ConVar DurationCVAR;
static Handle sdkRevive = INVALID_HANDLE;
static bool InRound = false;

static char GrabProps[4][STRING_LENGTH+1];

public Plugin myinfo = 
{
	name = "L4D2 Incapped Meds Munch",
	author = "AtomicStryker",
	description = "You can press USE while incapped to use your pills/arenaline and revive yourself",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109655"
}

public void OnPluginStart()
{
	PrepSDKCall();
	InitArray();
	
	CreateConVar("l4d2_incappedmedsmunch_version", PLUGIN_VERSION, " Version of L4D2 Incapped Meds Munch on this server ", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	DelaySetting = CreateConVar("l4d2_incappedmedsmunch_delaytime", "5.0", " How long before an Incapped Survivor can use meds ", FCVAR_NONE|FCVAR_NOTIFY);
	DurationCVAR = CreateConVar("l4d2_incappedmedsmunch_duration", "3.0", " How long do you need for reviving yourself ", FCVAR_NONE|FCVAR_NOTIFY);
	DropCVAR = CreateConVar("l4d2_incappedmedsmunch_dropmeds", "0", " Does being interrupted cause you to drop meds ", FCVAR_NONE|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d2_incappedmedsmunch");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_incapacitated", Event_Incap);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_start", Event_RoundChange);
	HookEvent("round_end", Event_RoundChange);
	HookEvent("round_end", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("finale_win", RoundEnd);
}

static void InitArray()
{
	strcopy(GrabProps[0], STRING_LENGTH, "m_tongueOwner");
	strcopy(GrabProps[1], STRING_LENGTH, "m_pounceAttacker");
	strcopy(GrabProps[2], STRING_LENGTH, "m_jockeyAttacker");
	strcopy(GrabProps[3], STRING_LENGTH, "m_pummelAttacker");
}

static void PrepSDKCall()
{
	Handle config = LoadGameConfigFile("l4d2medsmunch");
	if (config == INVALID_HANDLE)
	{
		SetFailState("Cant load medsmunch gamedata file");
	}

	StartPrepSDKCall(SDKCall_Player);
	
	if (!PrepSDKCall_SetFromConf(config, SDKConf_Signature, "CTerrorPlayer_OnRevived"))
	{
		CloseHandle(config);
		SetFailState("Cant find CTerrorPlayer_OnRevived Signature in gamedata file");
	}
	
	CloseHandle(config);
	sdkRevive = EndPrepSDKCall();

	if (sdkRevive == INVALID_HANDLE)
	{
		SetFailState("Cant initialize CTerrorPlayer_OnRevived SDKCall, Signature broken");
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_USE && !buttondelay[client] && !IsMunchingMed[client])
	{
		if (GetClientTeam(client)!=TEAM_SURVIVORS) return Plugin_Continue;
		if (!IsPlayerIncapped(client)) return Plugin_Continue;
		if (!InRound) return Plugin_Continue;
		if (IncapDelay[client]) return Plugin_Continue;
		
		// Whoever pressed USE must be valid, connected, ingame, Survivor and Incapped
		// a little buttondelay because the cmd fires too fast.
		buttondelay[client] = true;
		CreateTimer(1.0, ResetDelay, client);
		
		// Check for an Infected making love to you first.
		if (IsBeingPwnt(client))
		{
			PrintToChat(client, "\x04Get that Infected off you first.");
			return Plugin_Continue;
		}
		
		// Check for the Survivor Pendant
		if (IsBeingRevived(client))
		{
			PrintToChat(client, "\x04You're being revived already.");
			return Plugin_Continue;
		}
		
		int Meds = GetPlayerWeaponSlot(client, PILLS_ADRENALINE_SLOT);
		if (Meds == -1) // this gets returned if you got no Pillz.
		{
			PrintToChat(client, "\x04You aint got no Meds.");
			return Plugin_Continue;
		}
		else //if you DONT have NO PILLs ... you must have some :P
		{
			//commence ze actions!
			IsMunchingMed[client] = true;
			MunchTimer[client] = CreateTimer(GetConVarFloat(DurationCVAR), MunchFinished, client);
			SetupProgressBar(client, GetConVarFloat(DurationCVAR));
			
			PrintToChatAll("\x04%N\x01 is attempting to self revive!", client);
		}
	}
	
	if ((buttons & ~IN_USE || !buttons) && IsMunchingMed[client])
	{
		InterruptMunch(client);
	}
	
	if (buttons & IN_ATTACK2 && !buttondelay[client]) //the pass meds to incapped dudes code
	{
		if (GetClientTeam(client)!=TEAM_SURVIVORS) return Plugin_Continue;
		if (IsPlayerIncapped(client)) return Plugin_Continue;
		
		buttondelay[client] = true;
		CreateTimer(0.5, ResetDelay, client);

		int Meds = GetPlayerWeaponSlot(client, PILLS_ADRENALINE_SLOT);
		if (Meds == -1) return Plugin_Continue; // this means he has NO Meds
		
		char medstring[128];
		GetEdictClassname(Meds, medstring, sizeof(medstring));
		
		int target = GetClientAimTarget(client, true);
		if (target < 1
		|| !IsPlayerIncapped(target)
		|| GetClientTeam(target) != TEAM_SURVIVORS)
		{
			return Plugin_Continue;
		}
		
		if (GetPlayerWeaponSlot(target, PILLS_ADRENALINE_SLOT) != -1)
		{
			PrintToChat(client, "\x04Target already has Meds");
			return Plugin_Continue;
		}
		
		float pos1[3], pos2[3];
		GetClientAbsOrigin(client, pos1);
		GetClientAbsOrigin(target, pos2);
		
		if (GetVectorDistance(pos1, pos2) > PASS_PILLS_MINIMUM_DISTANCE)
		{
			PrintToChat(client, "\x04You must get closer to pass your Meds");
			return Plugin_Continue;
		}
		
		if (IsValidEdict(Meds))
		{
			RemoveEdict(Meds);
		}
		
		if (StrEqual(medstring, "weapon_pain_pills", false)) CheatCommand(target, "give", "pain_pills");
		else if (StrEqual(medstring, "weapon_adrenaline", false)) CheatCommand(target, "give", "adrenaline");
		
		//FakeClientCommand(target, "vocalize PlayerThanks");
		
		PrintToChatAll("\x04%N\x01 passed meds to the incapped \x04%N\x01!", client, target);
	}
	
	return Plugin_Continue;
}

public Action ResetDelay(Handle timer, any client)
{
	buttondelay[client] = false;
}

public Action AdvertisePills(Handle timer, any client)
{
	IncapDelay[client] = false;
	DelayedAdvertise[client] = false;
	
	if (client < 1
	|| !IsClientInGame(client)
	|| GetClientTeam(client) != TEAM_SURVIVORS
	|| !IsPlayerIncapped(client))
	{
		return;
	}
	
	if (IsBeingPwnt(client) || IsBeingRevived(client))
	{
		DelayedAdvertise[client] = true;
		return;
	}
	
	int Meds = GetPlayerWeaponSlot(client, PILLS_ADRENALINE_SLOT); // Slots start at 0. Slot Five equals 4 here.
	if (Meds != -1) // this means he has anything but NO Pills xD
	{
		PrintToChat(client, "\x01You have \x04Pills/Adrenaline\x01, you can now hold \x04USE\x01 to chug them and stand back up by yourself");
		PrintToChat(client, "\x01Warning! \x03ANY interruption\x01 will cause you to \x03drop your meds\x01 onto the floor; \x04DONT GET ATTACKED, DONT LET GO OF USE");
	}
}

static int InterruptMunch(int client)
{
	KillProgressBar(client);
	IsMunchingMed[client] = false;
	
	if (MunchTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MunchTimer[client]);
		MunchTimer[client] = INVALID_HANDLE;
	}
	
	if (GetConVarBool(DropCVAR))
	{
		int Meds = GetPlayerWeaponSlot(client, PILLS_ADRENALINE_SLOT);
		if (!IsValidEdict(Meds))
		{
			return;
		}
		
		char medstring[256];
		GetEdictClassname(Meds, medstring, sizeof(medstring));
		RemoveEdict(Meds);
		
		int droppedstuff = CreateEntityByName(medstring);
		int ticktime = RoundToNearest( FloatDiv( GetGameTime() , GetTickInterval() ) ) + 5;
		SetEntProp(droppedstuff, Prop_Data, "m_nNextThinkTick", ticktime);
		DispatchSpawn(droppedstuff);
		ActivateEntity(droppedstuff);
		
		float position[3], randomvec[3];
		GetClientAbsOrigin(client, position);
		position[2] += 20.0; //lift the dropped med a wee bit higher
		randomvec[0] = GetRandomFloat(0.0, 45.0);
		randomvec[1] = GetRandomFloat(0.0, 45.0);
		randomvec[2] = GetRandomFloat(15.0, 45.0); //toss it a random direction
		
		TeleportEntity(droppedstuff, position, NULL_VECTOR, randomvec);
		
		PrintToChat(client, "\x04Self Reviving was interrupted! You flinched, \x03dropping your meds!");
	}
	else PrintToChat(client, "\x04Self Reviving was interrupted!");
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsMunchingMed[client])
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (attacker > 0) 
		{
			PrintToChatAll("\x04%N\x01 stopped \x04%N\x01 from self reviving!", attacker, client);
			InterruptMunch(client);
		}
		else attacker = GetEventInt(event, "attackerentid");
		{
			if (attacker > 0) //player_hurt is being fired for bleeding out, attacker entity being 0
			{
				PrintToChatAll("\x04%N\x01 was stopped from self reviving!", client);
				InterruptMunch(client);
			}
		}
	}
}

public Action MunchFinished(Handle timer, any client)
{
	IsMunchingMed[client] = false;
	MunchTimer[client] = INVALID_HANDLE;
	
	if (!IsClientInGame(client)) return;
	ReviveClient(client);
	KillProgressBar(client);
}

static void ReviveClient(int client)
{
	int Meds = GetPlayerWeaponSlot(client, PILLS_ADRENALINE_SLOT);
	if (IsValidEdict(Meds))
	{
		RemoveEdict(Meds);
	}
	
	PrintToChatAll("\x04%N\x01 used his \x04pills/adrenaline\x01 and revived himself!", client);
	
	SDKCall(sdkRevive, client);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	//ReviveWorkAround(client);
}

/*
static ReviveWorkAround(client)
{
	new count = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	count++;
	
	CheatCommand(client, "give", "health");
	
	SetEntProp(client, Prop_Send, "m_currentReviveCount", count);
	
	CreateTimer(0.1, SetHP1, client); // set hard health delayed
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("survivor_revive_health")));
}

public Action:SetHP1(Handle:timer, any:client)
{
	SetEntityHealth(client, 1);
}
*/

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)
	&& (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 1))
	{
		return true;
	}
	return false;
}

stock bool IsBeingRevived(int client)
{
	return IsValidClient(GetEntPropEnt(client, Prop_Send, "m_reviveOwner"));
}

static bool IsBeingPwnt(int client)
{
	for (int i = 0; i < sizeof(GrabProps); i++)
	{
		if (IsValidClient(GetEntPropEnt(client, Prop_Send, GrabProps[i])))
		{
			return true;
		}
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if (client > 0)
	{
		if (IsClientInGame(client))
		{
			return true;
		}
	}
	return false;
}

stock void SetupProgressBar(int client, float time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
}

stock void KillProgressBar(int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
}

stock void CheatCommand(int client, const char[] command, const char[] args = "")
{
	int userflags = GetUserFlagBits(client);
	if (!(userflags & ADMFLAG_ROOT)) SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, args);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

// *********** EVENT GRUNTWORK ****************

public void Event_RoundChange (Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1 ; i <= MaxClients ; i++)
	{
		IsMunchingMed[i] = false;
		
		if (MunchTimer[i] != INVALID_HANDLE)
		{
			KillTimer(MunchTimer[i]);
			MunchTimer[i] = INVALID_HANDLE;
		}
	}
}

public void OnMapStart()
{
	InRound = true;
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	InRound = false;
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	InRound = true;
}

public void Event_Incap(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapDelay[client] = true;
	CreateTimer(GetConVarFloat(DelaySetting), AdvertisePills, client);
}