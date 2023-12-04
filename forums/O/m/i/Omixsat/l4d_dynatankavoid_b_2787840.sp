#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.6.8b"
#define DEBUG 0

enum struct EntInfo
{
	int entref;
}

Handle h_CheckTankSpawnTimer = INVALID_HANDLE;
bool L4DVersion;
float fTankDangerDistance;
ConVar hTankDangerDistance;
ArrayList ListOTanks;
static int ZOMBIECLASS_TANK;
int TankList;

public Plugin myinfo =
{
	name = "[L4D] Dynamic Tank Avoidance - Type B",
	author = "Omixsat",
	description = "Survivor bots will avoid any tank within a specified range",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=339308"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 
	else if (StrEqual(GameName, "left4dead2", false))
		L4DVersion = true;
	
	return APLRes_Success; 
}

public void OnPluginStart()
{
	if (L4DVersion)
		ZOMBIECLASS_TANK = 8;
	else
		ZOMBIECLASS_TANK = 5;
	ListOTanks = new ArrayList(1);
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{		
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	CreateConVar("l4d_dynatankavoid_version", PLUGIN_VERSION, "[L4D] Dynamic Tank Avoidance Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_SPONLY);
	hTankDangerDistance = CreateConVar("l4d_dynatankavoidancerange", "300.0", "The range the survivor bots must keep a distance from any incoming tank", FCVAR_NOTIFY|FCVAR_REPLICATED);
	HookEvent("tank_killed", evt_TD);
	HookEvent("player_spawn", evt_PS);
	HookEvent("player_team", evt_TS);
	HookEvent("round_end", evt_RE, EventHookMode_PostNoCopy);

	AutoExecConfig(true, "l4d_dynamictankavoidance");
	
}

public void OnMapEnd()
{
	delete h_CheckTankSpawnTimer;
	ListOTanks.Clear();
}

public void OnEntityCreated(int entity, const char[] classname)
{	
	if(entity < 1) return;
	
	if(IsTankEntity(entity))
	{
		int entref = EntIndexToEntRef(entity);
		EntInfo TankData;
		TankData.entref = entref;
		#if DEBUG
			PrintToChatAll("Tank ID %i has just spawned", entity);
		#endif
		ListOTanks.PushArray(TankData);
		CreateTimer(0.1,EntRefCheck);
	}
	
	if (h_CheckTankSpawnTimer == INVALID_HANDLE)
	{
		#if DEBUG
			PrintToChatAll("TYPE-B: Tank avoidance algorithm has started");
		#endif
		h_CheckTankSpawnTimer = CreateTimer(0.1, BotControlTimer, _, TIMER_REPEAT);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(entity < 0) return;
	if(entity > 0 && entity < MaxClients)
	{
		TankList = ListOTanks.Length;
		if(GetClientTeam(entity) == 3 && IsPlayerTank(entity))
		{
			for(int t = 0; t < TankList; t++)
			{
				if(EntIndexToEntRef(entity) == ListOTanks.Get(t,0))
				{
					#if DEBUG
						PrintToChatAll("A tank has despawned");
						PrintToChatAll("Deleting UID ref %i. It is the same as Tank Ref %i.", EntIndexToEntRef(entity), ListOTanks.Get(t,0));
					#endif
					ListOTanks.Erase(t);
					break;
				}
			}
		}
	}
}

Action evt_PS(Event event, const char[] name, bool dontBroadcast)
{
	int spawn = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(spawn) && IsPlayerAlive(spawn) && !IsFakeClient(spawn))
	{
		if(GetClientTeam(spawn) == 3 && IsPlayerTank(spawn))
		{
			EntInfo TankData;
			TankData.entref = EntIndexToEntRef(spawn);
			ListOTanks.PushArray(TankData);
			#if DEBUG
				PrintToChatAll("A player has spawned as a tank");
			#endif
			CreateTimer(0.1,EntRefCheck);
		}
		else if(GetClientTeam(spawn) == 3 && !IsPlayerTank(spawn))
		{
			CreateTimer(0.1,EntRefCheck);
		}
	}
	return Plugin_Continue;
}

Action evt_TS(Event event, const char[] name, bool dontBroadcast)
{
	//For team switch or disconnect
	int TSDC = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInGame(TSDC))
	{
		int team = GetEventInt(event,"team");
		#if DEBUG
			PrintToChatAll("%N has switched to team %i", TSDC, team);
		#endif
		if(team != 3)
		{
			TankList = ListOTanks.Length;
			for(int ts = 0; ts < TankList; ts++)
			{
				if(EntIndexToEntRef(TSDC) == ListOTanks.Get(ts,0))
				{
					#if DEBUG
						PrintToChatAll("%N isn't the tank anymore", TSDC);
					#endif
					ListOTanks.Erase(ts);
					break;
				}
			}
		}
	}
	else if(!IsClientInGame(TSDC))
	{
		TankList = ListOTanks.Length;
		for(int dc = 0; dc < TankList; dc++)
		{
			if(EntIndexToEntRef(TSDC) == ListOTanks.Get(dc,0))
			{
				#if DEBUG
					PrintToChatAll("%N has disconnected", TSDC);
				#endif
				ListOTanks.Erase(dc);
				break;
			}
		}
	}
	return Plugin_Continue;
}

Action evt_TD(Event event, const char[] name, bool dontBroadcast)
{
	int UID = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!UID)
	{
		return Plugin_Continue;
	}
	TankList = ListOTanks.Length;
	for(int t = 0; t < TankList; t++)
	{
		if(EntIndexToEntRef(UID) == ListOTanks.Get(t,0))
		{
			#if DEBUG
				PrintToChatAll("A tank must've died");
				PrintToChatAll("Deleting UID ref %i. It is the same as Tank Ref %i.", EntIndexToEntRef(UID), ListOTanks.Get(t,0));
			#endif
			ListOTanks.Erase(t);
			break;
		}
	}
	return Plugin_Continue;
}

void evt_RE(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
		PrintToChatAll("-----==== CLEARING TANK LIST ====-----");
	#endif
	ListOTanks.Clear();
}

Action BotControlTimer(Handle timer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && !IsIncapacitated(i))
		{
			for(int t = 0; t < ListOTanks.Length; t++)
			{
				int TankIndex = EntRefToEntIndex(ListOTanks.Get(t,0));
				if(IsPlayerTank(TankIndex) && IsPlayerAlive(TankIndex))
				{
					fTankDangerDistance = hTankDangerDistance.FloatValue;
					float TankPosition[3];
					GetClientAbsOrigin(TankIndex, TankPosition);
					float BotPosition[3];
					GetClientAbsOrigin(i, BotPosition);
					if (GetVectorDistance(BotPosition, TankPosition) < fTankDangerDistance && L4DVersion)
					{
						L4D2_RunScript("CommandABot({cmd=2,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(i), GetClientUserId(TankIndex));
						#if DEBUG
							PrintToChatAll("GAME: L4D2 - Survivor Bot ID %i is moving away from Tank ID %i",i,TankIndex);
						#endif
					}
					if (GetVectorDistance(BotPosition, TankPosition) < fTankDangerDistance && !L4DVersion)
					{
						float EyePos[3];
						float LookAtTank[3];
						float AimAngles[3];
						if(isVisibleTo(i,TankIndex,1))
						{
							GetClientEyePosition(i, EyePos);
							MakeVectorFromPoints(EyePos, TankPosition, LookAtTank);
							GetVectorAngles(LookAtTank, AimAngles);
							TeleportEntity(i, NULL_VECTOR, AimAngles, NULL_VECTOR);
							#if DEBUG
								PrintToChatAll("GAME - L4D1: %N has found a %N", i, TankIndex );
							#endif
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

Action EntRefCheck(Handle timer)
{
	TankList = ListOTanks.Length;
	for(int tC = 0; tC < TankList; tC++)
	{
		int Dref = tC + 1;
		for( ;Dref < TankList; Dref++)
		{
			TankList = ListOTanks.Length;
			if(Dref < TankList)
			{
				if(ListOTanks.Get(Dref,0) != INVALID_ENT_REFERENCE)
				{
					if(ListOTanks.Get(tC,0) == ListOTanks.Get(Dref,0))
					{
						ListOTanks.Erase(Dref);
						#if DEBUG
							PrintToChatAll("Found Duplicate! Removing from list");
						#endif
						break;
					}
				}
				else if(ListOTanks.Get(Dref,0) == INVALID_ENT_REFERENCE)
				{
					ListOTanks.Erase(Dref);
					#if DEBUG
						PrintToChatAll("Found and removed invalid entity index.");
					#endif
					break;
				}
			}
		}
		//Check for players that are no longer tanks
		TankList = ListOTanks.Length;
		if(tC < TankList)
		{
			if(ListOTanks.Get(tC,0) != INVALID_ENT_REFERENCE)
			{
				int CPlayerTank = EntRefToEntIndex(ListOTanks.Get(tC,0));
				if(!IsFakeClient(CPlayerTank) && !IsPlayerTank(CPlayerTank))
				{
					ListOTanks.Erase(tC);
					#if DEBUG
						PrintToChatAll("Player ID %i is no longer a tank", tC);
					#endif
					break;
				}
			}
			else if(ListOTanks.Get(tC,0) == INVALID_ENT_REFERENCE)
			{
				ListOTanks.Erase(tC);
				#if DEBUG
					PrintToChatAll("Found and removed invalid entity index from the first entry");
				#endif
				break;
			}
		}
	}
	return Plugin_Continue;
}

//Credits to Timocop for the stock :D
/**
* Runs a single line of vscript code.
* NOTE: Dont use the "script" console command, it starts a new instance and leaks memory. Use this instead!
*
* @param sCode		The code to run.
* @noreturn
*/

stock void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

//TO DO: Implement L4D1 Actions

bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

bool IsTankEntity(int spwnEntity)
{
	if(IsValidEdict(spwnEntity) && IsValidEntity(spwnEntity))
	{
		static char classname[8];
		GetEntityClassname(spwnEntity,classname,sizeof(classname));
		if(StrEqual(classname, "tank"))
		{
			return true;
		}
	}
	
	return false;
}

bool IsPlayerTank(int client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}

bool traceFilter(int entity, int mask, any self)
{
	return entity != self;
}

bool isVisibleTo(int client, int target, int AimType)
{
	bool hasVisual = false;
	float aim_angles[3];
	float self_pos[3];
	
	GetClientEyePosition(client, self_pos);
	computeAimAngles(client, target, aim_angles, AimType);
	
	Handle trace = TR_TraceRayFilterEx(self_pos, aim_angles, MASK_VISIBLE, RayType_Infinite, traceFilter, client);
	if (TR_DidHit(trace)) {
		int hit = TR_GetEntityIndex(trace);
		if (hit == target) {
			hasVisual = true;
		}
	}

	delete trace;
	return hasVisual;
}

void computeAimAngles(int client, int target, float angles[3], int type)
{	
	float target_pos[3];
	float self_pos[3];
	float lookat[3];
	
	GetClientEyePosition(client, self_pos);
	switch (type) {
		case 1: { // Eye (Default)
			GetClientEyePosition(target, target_pos);
		}
		case 2: { // Body
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", target_pos);
		}
		case 3: { // Chest
			GetClientAbsOrigin(target, target_pos);
			target_pos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(self_pos, target_pos, lookat);
	GetVectorAngles(lookat, angles);
}