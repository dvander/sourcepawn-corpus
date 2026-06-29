#include <sourcemod>
#include <sdktools>
#include <left4downtown>
#define PLUGIN_VERSION "1.1.0"

#define TEST_DEBUG 0
#define TEST_DEBUG_LOG 1

public Plugin:myinfo = 
{
	name = "L4D Tank Vote",
	author = "AtomicStryker",
	description = " Lets Infected vote about who gets tank instead of randomizing it ",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=104696"
}

static Handle:fhZombieAbortControl = INVALID_HANDLE;
static Handle:TankVoteMenu = INVALID_HANDLE;
static bool:letTankPass = false;
static designatedTank = -1;
static finaleTankCount = 0;

new String:g_sBossNames[10][10]={"","smoker","boomer","hunter","spitter","jockey","charger","witch","tank","survivor"};

public OnPluginStart()
{
	CreateConVar("l4d_tankvote_version", PLUGIN_VERSION, " Version of L4D Tank Vote on this server", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);

	LoadTranslations("common.phrases");
	
	//AutoExecConfig(true, "l4d_tankvote");
	
	HookEvent("finale_start", FinaleStart_Event);
	HookEvent("player_death", TankKilled_Event);
	HookEvent("round_end", RoundEnd_Event);
	
	//Initialize SDK Stuff
	if (fhZombieAbortControl == INVALID_HANDLE)
	{
		new Handle:gConf = INVALID_HANDLE;
		gConf = LoadGameConfigFile("InfectedAPI");
		//CTerrorPlayer::PlayerZombieAbortControl(client,float=0)
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "ZombieAbortControl");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		fhZombieAbortControl = EndPrepSDKCall();
		CloseHandle(gConf);
		if (fhZombieAbortControl == INVALID_HANDLE)
		{
			SetFailState("Infected API can't get ZombieAbortControl SDKCall!");
		}
	}
}

public FinaleStart_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	finaleTankCount = GetConVarInt(FindConVar("director_finale_panic_waves"));
	
	DebugPrintToAll("Finale_Start event fired! Finale Tanks: %i", finaleTankCount);
	
	finaleTankCount--;
	TankVote();
}

public TankKilled_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client) return;
	
	if (GetEntProp(client, Prop_Send, "m_zombieClass") != 8) return;

	DebugPrintToAll("Tank Death event fired!");

	if (IsVoteInProgress() || !ItsFinaleTime())
	{
		return;
	}
	
	finaleTankCount--;
	DebugPrintToAll("Remaining Finale Tanks: %i", finaleTankCount);
	
	if (finaleTankCount < 1) return;

	TankVote();
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	designatedTank = -1;
	letTankPass = false;
}

public Action:L4D_OnSpawnTank(const Float:vector[3], const Float:qangle[3])
{
	if (letTankPass)
	{
		return Plugin_Continue;
	}

	if (IsVoteInProgress())
	{
		//DebugPrintToAll("L4D_OnSpawnTank forward fired again, vote running, blocked it!");
		return Plugin_Handled;
	}

	DebugPrintToAll("L4D_OnSpawnTank forward fired!");
	
	if (!ItsFinaleTime())
	{
		if (TankVote()) return Plugin_Handled;
	}
	
	else if (designatedTank > -1) // case Finale, and a Tank was elected
	{
		TankSpawner(designatedTank); // i do not use Plugin_Handled, but direct the Tank to be spawned for the correct person
	}
	
	return Plugin_Continue;
}

static bool:TankVote() // returns true if a Vote was created, and false if not
{
	TankVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(TankVoteMenu, "Vote on who gets to be Tank next");
	
	DebugPrintToAll("Initializing Tank Vote Menu");
	
	decl String:name[MAX_NAME_LENGTH], String:number[10];
	new electables, pool[16];
	
	AddMenuItem(TankVoteMenu, "0", "Randomize it!");
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? not eligible, skip
		
		DebugPrintToAll("Found valid Tank Choice: %N", i);
		
		Format(name, sizeof(name), "%N", i);
		Format(number, sizeof(number), "%i", i);
		AddMenuItem(TankVoteMenu, number, name);
		
		pool[electables] = i;
		electables++;
	}
	
	DebugPrintToAll("Valid Tank Choices Amount: %i", electables);
	
	if (electables > 1) //only do all that if there are more than 1 possible tank players
	{
		SetMenuExitButton(TankVoteMenu, false);
		
		VoteMenu(TankVoteMenu, pool, electables, 10);
		return true;
	}
	
	return false;
}

Float:GetVotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes), float(totalVotes));
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(TankVoteMenu);
	}
	
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		TankSpawner(0); // causes default Tank behaviour
	}
	
	else if (action == MenuAction_VoteEnd)
	{
		decl String:item[256], String:display[256], Float:percent;
		new votes, totalVotes;
		
		GetMenuVoteInfo(param2, votes, totalVotes);
		GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
		
		percent = GetVotePercent(votes, totalVotes);
		
		PrintToChatAll("Tank vote successful: %s (Received %i%% of %i votes)", display, RoundToNearest(100.0*percent), totalVotes);
		DebugPrintToAll("Tank vote successful: %s (Received %i%% of %i votes)", display, RoundToNearest(100.0*percent), totalVotes);
		
		new winner = StringToInt(item);
		
		if (!ItsFinaleTime())
		{
			TankSpawner(winner);
		}
		else
		{
			designatedTank = winner;
		}
	}
}

public Action:ResetPassBool(Handle:timer)
{
	letTankPass = false;
}


static bool:reswapInfected[MAXPLAYERS+1];
static bool:reghostInfected[MAXPLAYERS+1];
static bool:respawnInfected[MAXPLAYERS+1];
static infectedClass[MAXPLAYERS+1];
static infectedHealth[MAXPLAYERS+1];
static Float:vectors[MAXPLAYERS+1][3];
static Float:infangles[MAXPLAYERS+1][3];
static Float:velocity[MAXPLAYERS+1][3];
static const Float:nullorigin[3];


static TankSpawner(client)
{
	if (!client || !IsClientInGame(client))
	{
		letTankPass = true;
		DebugPrintToAll("Allowing random player tank");
		CreateTimer(10.0, ResetPassBool);
		return;
	}
	
	for (new i=1; i<=MaxClients; i++) //now to 'disable' all but the guy who is to be tank
	{
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip

		if (IsPlayerAlive(i))
		{
			respawnInfected[i] = true;
			if (IsPlayerGhost(i)) reghostInfected[i] = true;
			infectedClass[i] = GetEntProp(i, Prop_Send, "m_zombieClass");
			infectedHealth[i] = GetClientHealth(i);
			GetClientAbsOrigin(i, vectors[i]);
			GetClientEyeAngles(i, infangles[i]);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", velocity[i])
			
			TeleportEntity(i, nullorigin, NULL_VECTOR, NULL_VECTOR);
			ForcePlayerSuicide(i);
		}
		
		ChangeClientTeam(i, 1);
		reswapInfected[i] = true;
	}
	
	letTankPass = true;
	DebugPrintToAll("Allowing client specific Tank for %N", client);
	CreateTimer(10.0, ResetPassBool);
	
	CreateTimer(0.1, RevertPlayerStatus);
	
	designatedTank = -1;
}

public Action:RevertPlayerStatus(Handle:timer)
{
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++)
	{
		if (reswapInfected[i])
		{
			ChangeClientTeam(i, 3);
			reswapInfected[i] = false;
		}
		
		if (respawnInfected[i])
		{
			SpawnInfectedBoss(i, infectedClass[i], reghostInfected[i], false, ItsFinaleTime(), vectors[i], infangles[i], velocity[i]);
			SetEntityHealth(i, infectedHealth[i]);
			respawnInfected[i] = false;
		}
	}
}

stock bool:ItsFinaleTime()
{
	new ent = FindEntityByClassname(-1, "terror_player_manager");

	if (ent > -1)
	{
		new offset = FindSendPropInfo("CTerrorPlayerResource", "m_isFinale");
		if (offset > 0)
		{
			if (GetEntData(ent, offset))
			{
				if (GetEntData(ent, offset) == 1) return true;
			}
		}
	}
	return false;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if TEST_DEBUG	|| TEST_DEBUG_LOG
	decl String:buffer[192];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[TANKVOTE] %s", buffer);
	PrintToConsole(0, "[TANKVOTE] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

/* Class Numbers - GetEntProp(client, Prop_Send, "m_zombieClass")

#define ZC_SMOKER 1
#define ZC_BOOMER 2
#define ZC_HUNTER 3
#define ZC_SPITTER 4
#define ZC_JOCKEY 5
#define ZC_CHARGER 6
*/
stock SpawnInfectedBoss(any:client, any:Class, bool:bGhost=false, bool:bAuto=true, bool:bGhostFinale=false ,const Float:Origin[3]={0.0,0.0,0.0},const Float:angles[3]={0.0,0.0,0.0},const Float:Velocity[3]={0.0,0.0,0.0})
{
	new bool:resetGhostState[MAXPLAYERS+1];
	new bool:resetIsAlive[MAXPLAYERS+1];
	new bool:resetLifeState[MAXPLAYERS+1];
	decl String:options[30];

	for (new i=1; i<=MaxClients; i++)
	{ 
		if (i == client) continue; //dont disable the chosen one
		if (!IsClientInGame(i)) continue; //not ingame? skip
		if (GetClientTeam(i) != 3) continue; //not infected? skip
		if (IsFakeClient(i)) continue; //a bot? skip
		
		if (IsPlayerGhost(i))
		{
			resetGhostState[i] = true;
			SetPlayerGhostStatus(i, false);
			resetIsAlive[i] = true; 
			SetPlayerIsAlive(i, true);
		}
		else if (!IsPlayerAlive(i))
		{
			resetLifeState[i] = true;
			SetPlayerLifeState(i, false);
		}
	}
	//spawn zombie
	Format(options,30,"%s%s",g_sBossNames[Class],(bAuto?" auto":""));
	CheatCommand(client, "z_spawn", options);
	
	// We restore the player's status
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhostState[i]) SetPlayerGhostStatus(i, true);
		if (resetIsAlive[i]) SetPlayerIsAlive(i, false);
		if (resetLifeState[i]) SetPlayerLifeState(i, true);
	}
	
	if (Origin[0] != 0.0) TeleportEntity(client, Origin, angles, Velocity);
	if (bGhost) InfectedForceGhost(client, true, bGhostFinale);
}

stock bool:InfectedForceGhost(client, SavePos=false, inFinaleAlso=false)
{
	decl Float:AbsOrigin[3];
	decl Float:EyeAngles[3];
	decl Float:Velocity[3];
	
	if (!IsClientInGame(client)) return false;
	if (GetClientTeam(client) != 3) return false;
	if (!IsPlayerAlive(client)) return false;
	if (IsPlayerGhost(client)) return false;
	if (IsFakeClient(client)) return false;
	
	if (SavePos)
	{
		GetClientAbsOrigin(client, AbsOrigin);
		GetClientEyeAngles(client, EyeAngles);
		Velocity[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		Velocity[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		Velocity[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");	
	}
	
	SetEntProp(client,Prop_Send, "m_isCulling", 1, 1);
	SDKCall(fhZombieAbortControl, client, 0.0);	
	if (SavePos) TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);	
	return true;
}

stock SetPlayerIsAlive(client, bool:alive)
{
	new offset = FindSendPropInfo("CTransitioningPlayer", "m_isAlive");
	if (alive) SetEntData(client, offset, 1, 1, true);
	else SetEntData(client, offset, 0, 1, true);
}

stock bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost", 1)) return true;
	return false;
}

stock SetPlayerGhostStatus(client, bool:ghost)
{
	if(ghost)
	{	
		SetEntProp(client, Prop_Send, "m_isGhost", 1, 1);
		SetEntityMoveType(client, MOVETYPE_ISOMETRIC)
	}
	
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0, 1);
		SetEntityMoveType(client, MOVETYPE_WALK)
	}
}

stock SetPlayerLifeState(client, bool:ready)
{
	if (ready) SetEntProp(client, Prop_Data, "m_lifeState", 1, 1);
	else SetEntProp(client, Prop_Data, "m_lifeState", 0, 1);
}

stock bool:isWin32()
{
	static WindowsOrLinux=0;
	if (WindowsOrLinux==0)
	{
		new Handle:conf = LoadGameConfigFile("InfectedAPI");
		WindowsOrLinux = GameConfGetOffset(conf, "WindowsOrLinux");
		CloseHandle(conf);
	}
	return WindowsOrLinux==1;
}

stock CheatCommand(client, const String:command[], const String:arguments[]="")
{
	if (!client || !IsClientInGame(client))
	{
		for (new target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target)) client = target;
		}
	}
	if (!client || !IsClientInGame(client)) return;
	
	new admindata = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, admindata);
}