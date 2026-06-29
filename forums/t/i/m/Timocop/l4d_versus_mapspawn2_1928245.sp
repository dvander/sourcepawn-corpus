#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

new Handle:hConVar_Enabled = INVALID_HANDLE;
new Handle:hConVar_InfectedType = INVALID_HANDLE;
new Handle:hConVar_InfectedTypeChance = INVALID_HANDLE;
new Handle:hConVar_InfectedWitchChance = INVALID_HANDLE;
new Handle:hConVar_SpawnDelay = INVALID_HANDLE;
new Handle:hConVar_InfectedTypeFChance = INVALID_HANDLE;
new Handle:hConVar_InfectedWitchFChance = INVALID_HANDLE;
new Handle:hConVar_SpawnDelayRepeat = INVALID_HANDLE;


new Handle:hDelayTimer = INVALID_HANDLE;

new bool:bEnabled = true;
new String:sMaxClassNames[64][32];
new iMaxClasses = 64;

new bool:IsValidGameMode = false;

new iInfectedTypeChance;
new iInfectedWitchChance;
new iInfectedTypeFinalChance;
new iInfectedWitchFinalChance;
new iSpawnDelay;
new iMaxDelayRepeatTime;
new iCurrentDelayRepeatTime;

new bool:IsFinal = false;

public Plugin:myinfo = 
{
	name = "Versus MapSpawn",
	author = "Coder:Timocop",
	description = "Versus MapSpawn",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{

	hConVar_Enabled = CreateConVar("l4d_versus_mapspawn_enabled", "1", "[1/0 PLUGIN ENABLED/DISABLED]", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	hConVar_InfectedType = CreateConVar("l4d_versus_mapspawn_infected_type", "tank", "[ALLOWED CLASSES] Use ';' to add more then one like: 'tank;smoker;hunter;mob'", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	hConVar_InfectedTypeChance = CreateConVar("l4d_versus_mapspawn_infected_chance", "50", "[1-100% = CHANCE | 0 = DISABLED] Chance to Spawn a random Infected Type (see 'l4d_versus_mapspawn_infected_type')", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	hConVar_InfectedWitchChance = CreateConVar("l4d_versus_mapspawn_wtich_chance", "75", "[1-100% = CHANCE | 0 = DISABLED] Chance to Spawn a Witch", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	hConVar_InfectedTypeFChance = CreateConVar("l4d_versus_mapspawn_infected_finalchance", "50", "[1-100% = CHANCE | 0 = DISABLED] Chance to Spawn a random Infected Type on final map start (see 'l4d_versus_mapspawn_infected_type')", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	hConVar_InfectedWitchFChance = CreateConVar("l4d_versus_mapspawn_wtich_finalchance", "100", "[1-100% = CHANCE | 0 = DISABLED] Chance to Spawn a Witch on final map start", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	hConVar_SpawnDelay = CreateConVar("l4d_versus_mapspawn_delay", "60", "[0.0 DIRECT SPAWN | >0.0 DELAY] Delay to spawn the infected", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	hConVar_SpawnDelayRepeat = CreateConVar("l4d_versus_mapspawn_delay_repeat", "1", "[0 = NO REPEAT | >0 = REPEAT SPAWN] Delay repeat to spawn new infected", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	HookConVarChange(hConVar_Enabled, ConVarChanged);
	HookConVarChange(hConVar_InfectedType, ConVarChanged);
	HookConVarChange(hConVar_InfectedTypeChance, ConVarChanged);
	HookConVarChange(hConVar_InfectedWitchChance, ConVarChanged);
	HookConVarChange(hConVar_InfectedTypeFChance, ConVarChanged);
	HookConVarChange(hConVar_InfectedWitchFChance, ConVarChanged);
	HookConVarChange(hConVar_SpawnDelay, ConVarChanged);
	
	HookEvent("round_end", eRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", eRoundStart, EventHookMode_PostNoCopy);
	HookEvent("finale_start", eFinalStart, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true, "l4d_versus_mapspawn");
	
	ConVarCalculation();
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ConVarCalculation();
}

ConVarCalculation()
{
	//###########
	bEnabled = GetConVarBool(hConVar_Enabled);
	//###########
	iInfectedTypeChance = GetConVarInt(hConVar_InfectedTypeChance);
	iInfectedWitchChance = GetConVarInt(hConVar_InfectedWitchChance);
	iInfectedTypeFinalChance = GetConVarInt(hConVar_InfectedTypeFChance);
	iInfectedWitchFinalChance = GetConVarInt(hConVar_InfectedWitchFChance);
	iSpawnDelay = GetConVarInt(hConVar_SpawnDelay);
	
	iMaxDelayRepeatTime = GetConVarInt(hConVar_SpawnDelayRepeat);
	iCurrentDelayRepeatTime = 0;
	//###########
	decl String:sConVar_AllowedClasses[256];
	GetConVarString(hConVar_InfectedType, sConVar_AllowedClasses, sizeof(sConVar_AllowedClasses));
	
	new iClassNumber = ReplaceString(sConVar_AllowedClasses, sizeof(sConVar_AllowedClasses), ";", ";", false);
	iMaxClasses = iClassNumber;

	ExplodeString(sConVar_AllowedClasses, ";", sMaxClassNames, iClassNumber + 1, 32);
}

public Action:eFinalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ConVarCalculation();
	IsValidGameMode = (GetGameMode() == 3);
	
	IsFinal = true;
	iCurrentDelayRepeatTime = 0;

	hDelayTimer = CreateTimer(float(iSpawnDelay), MainSpawn_Timer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	return Plugin_Continue;
}
public Action:eRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ConVarCalculation();
	IsValidGameMode = (GetGameMode() == 3);
	
	IsFinal = false;
	iCurrentDelayRepeatTime = 0;

	hDelayTimer = CreateTimer(float(iSpawnDelay), MainSpawn_Timer, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	
	return Plugin_Continue;
}
public Action:eRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	hDelayTimer = INVALID_HANDLE;
	
	ConVarCalculation();
	IsValidGameMode = (GetGameMode() == 3);
	
	IsFinal = false;
	iCurrentDelayRepeatTime = 0;

	return Plugin_Continue;
}

public Action:MainSpawn_Timer(Handle:timer, any:NothingOverHere)
{
	if(timer != hDelayTimer)
	return Plugin_Stop;
	
	if(!IsValidGameMode || !bEnabled)
	return Plugin_Stop;
	
	new bool:iManupulateChance_Infected = false;
	new bool:iManupulateChance_Witch = false;
	
	if(IsFinal)
	{
		iManupulateChance_Infected = (GetRandomInt(1, 100) <= iInfectedTypeFinalChance);
		iManupulateChance_Witch = (GetRandomInt(1, 100) <= iInfectedWitchFinalChance);
	}
	else
	{
		iManupulateChance_Infected = (GetRandomInt(1, 100) <= iInfectedTypeChance);
		iManupulateChance_Witch = (GetRandomInt(1, 100) <= iInfectedWitchChance);
	}
	
	new iRandomClient = GetRandomPlayer();
	
	if(iManupulateChance_Infected
			&& iRandomClient != -1)
	SpawnRandomInfected(iRandomClient);

	if(iManupulateChance_Witch
			&& iRandomClient != -1)
	Client_CheatCommand(iRandomClient, "z_spawn", "witch", "auto");
	
	iCurrentDelayRepeatTime += 1;
	
	if(iCurrentDelayRepeatTime <= iMaxDelayRepeatTime)
	return Plugin_Continue;
	else
	return Plugin_Stop;
}

stock bool:SpawnRandomInfected(client)
{
	new iRandom = GetRandomInt(0, iMaxClasses);
	new iRandomClient = GetRandomPlayer();
	
	if(iRandomClient != -1)
	{
		Client_CheatCommand(iRandomClient, "z_spawn", sMaxClassNames[iRandom], "auto");
		return true;
	}
	
	return false;
}

stock GetRandomPlayer()
{
	for(new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(!IsClientInGame(iClient))
		continue;
		
		if(IsFakeClient(iClient))
		continue;
		
		return iClient;
	}
	return -1;
}

stock Client_CheatCommand(iClient, String:sCommand[], const String:sArg1[]="", const String:sArg2[]="", const String:sArg3[]="")
{
	new iClientFlag = GetUserFlagBits(iClient);
	SetUserFlagBits(iClient, ADMFLAG_KICK);
	
	new iFlags = GetCommandFlags(sCommand);
	SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
	
	FakeClientCommand(iClient, "%s %s %s %s", sCommand, sArg1, sArg2, sArg3);
	
	SetCommandFlags(sCommand, iFlags);
	
	SetUserFlagBits(iClient, iClientFlag);
}

stock GetGameMode()
{
	new Handle:hGameMode = FindConVar("mp_gamemode");
	
	if(hGameMode == INVALID_HANDLE)
	return -1;
	
	decl String:sGameMode[16];
	GetConVarString(hGameMode, sGameMode, sizeof(sGameMode));

	CloseHandle(hGameMode);
	
	if (StrContains(sGameMode, "coop") != -1) return 1;
	else if (StrContains(sGameMode, "realism") != -1) return 2;
	else if (StrContains(sGameMode, "versus") != -1) return 3;
	else if (StrContains(sGameMode, "teamversus") != -1) return 4;
	else if (StrContains(sGameMode, "survival") != -1) return 5;
	else if (StrContains(sGameMode, "scavenge") != -1) return 6;
	else if (StrContains(sGameMode, "teamscavenge") != -1) return 7;	
	
	return -1;
}