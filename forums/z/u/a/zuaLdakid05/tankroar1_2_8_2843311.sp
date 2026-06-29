#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <left4dhooks>

#define INFECTED_TEAM 3
#define SURVIVOR_TEAM 2
#define INF_TANK 8
#define VERSION "1.2.8"

#define GAMEDATA "l4d2tankroar"
#define TANK_YELL_SOUND "player/tank/voice/yell/tank_yell_12.wav"
#define ROAR_READY_SOUND "items/flashlight1.wav"

ConVar cvar_tankroar;
ConVar cvar_power;
ConVar cvar_distanceaffected;
ConVar cvar_cooldown;
ConVar cvar_damage;
ConVar cvar_direction;
ConVar cvar_hint;
ConVar cvar_knockback_type;
ConVar cvar_required_hp;
ConVar cvar_tank_stun;

bool cooldown[MAXPLAYERS + 1];

Handle sdkCall;

public Plugin myinfo =
{
	name = "Tank Roar",
	author = "Karma",
	description = "Tank is given a special roar ability that knockbacks survivors.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=126919"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	BuildSDKCall();

	/////////
	//Cvars//
	/////////
	CreateConVar("sm_tankroar_version",VERSION, "The Version of this plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_tankroar = CreateConVar("sm_tankroar","2", "Sets the dimensional plane the roar affects.0 - Disable plugin, 1 - Roar only affect survivors on the (relatively) same plane as tank, 2 - Roar affects survivor as long as survivor is set distance away from tank.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_power = CreateConVar("sm_tankroar_power","300", "Sets how powerful the roar is.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_distanceaffected = CreateConVar("sm_tankroar_radius","400", "Sets how near survivor must be in order to be affected by the roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_cooldown = CreateConVar("sm_tankroar_cooldown","7", "Sets how long before tank can roar again. Numbers <= 0 indicates roar can only be used once.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_damage = CreateConVar("sm_tankroar_damage","0", "Sets damage dealt to survivors.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_direction = CreateConVar("sm_tankroar_direction","1", "Sets which direction the survivor will be knockbacked. 0 for towards tank. 1 for away from tank. ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_hint = CreateConVar("sm_tankroar_hint","3", "Set the displaying hint type. 0 - disable. 1 - chat. 2 - instructor hint. 3 - both.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_knockback_type = CreateConVar("sm_tankroar_knock_type","1", "Sets the type of knockback. 0 - Jump-like knockback. 1 - Tank punch knockback. 2 - Stagger", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_required_hp = CreateConVar("sm_tankroar_req_hp","6000", "Sets the health the tank must be below before it can use roar.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvar_tank_stun = CreateConVar("sm_tankroar_stun","2", "Sets how long the tank cannot move/attack after roaring. Input 0 for no stun. Max stun time can only be as long as roar's cooldown.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	///////////////////////////////////
	//Load Translation and cfg files//
	//////////////////////////////////
	LoadTranslations("tankroar.phrases");
	AutoExecConfig(true, "l4d2_tankroar");

	////////////////////////////////////////////////
	//Hooking Events for (un)Registering Survivors//
	////////////////////////////////////////////////
	HookEvent("bot_player_replace", Event_PlayerReplaceBot);
	HookEvent("tank_spawn", Event_TankSpawn);
}

void BuildSDKCall()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false ) SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer_Fling") == false )
		SetFailState("Could not load the \"CTerrorPlayer_Fling\" gamedata signature.");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCall = EndPrepSDKCall();
	if( sdkCall == null )
		SetFailState("Could not prep the \"CTerrorPlayer_Fling\" function.");

	delete hGameData;
}

public void OnMapStart()
{
	PrecacheSound(TANK_YELL_SOUND, true);
	PrecacheSound(ROAR_READY_SOUND, true);
}

public void Event_PlayerReplaceBot(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "bot"));
	int player = GetClientOfUserId(GetEventInt(event, "player"));

	if (GetClientTeam(player) == INFECTED_TEAM && (GetConVarInt(cvar_tankroar) != 0))
	{
		char entClass[96];
		GetEntityNetClass(client, entClass, sizeof(entClass));
		if (StrEqual(entClass, "Tank", false) )
		{
			Handle pack = CreateDataPack();
			WritePackCell(pack, GetEventInt(event, "player"));
			WritePackString(pack, "Roar");
			WritePackString(pack, "+zoom");
			CreateTimer(0.2, DisplayHint, pack);
		}
	}
}

public void Event_TankSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientValid(client) && IsFakeClient(client))
	{
		cooldown[client] = true;
		CreateTimer(10.0, CooldownReset, GetClientUserId(client));
	}
}

public Action DisplayHint(Handle timer, Handle pack)
{
	char msg[256];
	char bind[16];
	char msgphrase[256];

	ResetPack(pack);
	int client = GetClientOfUserId(ReadPackCell(pack));
	ReadPackString(pack, msg, sizeof(msg));
	ReadPackString(pack, bind, sizeof(bind));
	CloseHandle(pack);

	if (!IsClientValid(client))
		return Plugin_Handled;

	int hintType = GetConVarInt(cvar_hint);
	char tempString[128];
	IntToString(GetConVarInt(cvar_required_hp), tempString, sizeof(tempString));
	FormatEx(msgphrase, sizeof(msgphrase), "%t if your health is below %s", msg, tempString);

	if (hintType == 1 || hintType == 3)
	{
		PrintToChat(client, "\x03[Hint]\x01 %s.", msgphrase);
	}

	if (hintType == 2 || hintType == 3)
	{
		int instrHintEnt;
		char name[32];

		instrHintEnt = CreateEntityByName("env_instructor_hint");
		FormatEx(name, sizeof(name), "TRIH%d", client);
		DispatchKeyValue(client, "targetname", name);
		DispatchKeyValue(instrHintEnt, "hint_target", name);

		DispatchKeyValue(instrHintEnt, "hint_range", "0.01");
		DispatchKeyValue(instrHintEnt, "hint_color", "255 255 255");
		DispatchKeyValue(instrHintEnt, "hint_caption", msgphrase);
		DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", "use_binding");
		DispatchKeyValue(instrHintEnt, "hint_binding", bind);
		DispatchKeyValue(instrHintEnt, "hint_timeout", "6.0");

		DispatchSpawn(instrHintEnt);
		AcceptEntityInput(instrHintEnt, "ShowHint");

		CreateTimer(6.0, DisableInstructor, GetClientUserId(client));
	}

	return Plugin_Handled;
}

public Action DisableInstructor(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientValid(client))
		return Plugin_Handled;

	DispatchKeyValue(client, "targetname", "");

	return Plugin_Handled;
}

void ApplyDamage(int victim, int damage, int attacker, int type, char[] weapon)
{
	if((victim>0) && (damage>0) && (IsClientInGame(victim)) && (IsPlayerAlive(victim)))
	{
		char s_dmg[16];
		IntToString(damage, s_dmg, sizeof(s_dmg));
		char s_type[32];
		IntToString(type, s_type, sizeof(s_type));

		int PtHurtEnt=CreateEntityByName("point_hurt");
		if(PtHurtEnt > 0)
		{
			DispatchKeyValue(victim,"targetname","TRDD");
			DispatchKeyValue(PtHurtEnt,"DamageTarget","TRDD");
			DispatchKeyValue(PtHurtEnt,"Damage",s_dmg);
			DispatchKeyValue(PtHurtEnt,"DamageType",s_type);
			if(!StrEqual(weapon,"")) DispatchKeyValue(PtHurtEnt,"classname",weapon);

			DispatchSpawn(PtHurtEnt);
			if (!(attacker>0)) attacker = -1;
			AcceptEntityInput(PtHurtEnt,"Hurt", attacker);

			DispatchKeyValue(victim,"targetname","");
			RemoveEdict(PtHurtEnt);
		}
	}
}

stock void Fling(int target, float vector[3], int attacker, float stunTime = 3.0)
{
	SDKCall(sdkCall, target, vector, 96, attacker, stunTime);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (GetConVarInt(cvar_tankroar) != 0 && IsClientValid(client) && GetZombieClass(client) == INF_TANK)
	{
		bool isBot = IsFakeClient(client);

		bool validCmd = false;
		if (isBot)
		{
			validCmd = true;
		}
		else
		{
			if (buttons & IN_ZOOM)
				validCmd = true;
		}

		if (validCmd && !cooldown[client])
		{
			if (GetEntProp(client, Prop_Data, "m_iHealth") <= GetConVarInt(cvar_required_hp) && (IsPlayerAlive(client)))
			{
				if (isBot && !HasSurvivorInRange(client))
					return;

				TankRoar(client);

				if (GetConVarFloat(cvar_cooldown) > 0)
				{
					cooldown[client] = true;
					CreateTimer(GetConVarFloat(cvar_cooldown), CooldownReset, GetClientUserId(client));
				}
			}
		}
	}
}

bool HasSurvivorInRange(int tank)
{
	float tankPos[3];
	GetClientEyePosition(tank, tankPos);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (tank == client)
			continue;

		if (!IsClientInGame(client))
			continue;

		if (GetClientTeam(client) != SURVIVOR_TEAM)
			continue;

		if (!IsPlayerAlive(client))
			continue;

		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
			continue;

		if (L4D_IsPlayerPinned(client))
			continue;

		float survivorPos[3];
		GetClientEyePosition(client, survivorPos);

		float distance[3];
		distance[0] = (tankPos[0] - survivorPos[0]);
		distance[1] = (tankPos[1] - survivorPos[1]);
		distance[2] = (tankPos[2] - survivorPos[2]);

		if (CheckDistance(distance))
			return true;
	}

	return false;
}

void TankRoar(int tank)
{
	float power = GetConVarFloat(cvar_power);

	float tankPos[3];
	GetClientEyePosition(tank, tankPos);

	float stun = GetConVarFloat(cvar_tank_stun);
	float cd = GetConVarFloat(cvar_cooldown);
	if (stun>cd) stun = cd;

	EmitSoundToAll(TANK_YELL_SOUND, tank);

	if (stun>0)
	{
		SetEntProp(tank, Prop_Send, "m_fFlags", GetEntityFlags(tank) | FL_FROZEN);
		SetEntProp(tank, Prop_Data, "m_nSequence", 53);
		CreateTimer(stun, UnstunTank, GetClientUserId(tank));
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (GetClientTeam(client) != SURVIVOR_TEAM)
			continue;

		if (!IsPlayerAlive(client))
			continue;

		if (GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1)
			continue;

		if (L4D_IsPlayerPinned(client))
			continue;

		float survivorPos[3];
		GetClientEyePosition(client, survivorPos);

		float distance[3];
		distance[0] = (tankPos[0] - survivorPos[0]);
		distance[1] = (tankPos[1] - survivorPos[1]);
		distance[2] = (tankPos[2] - survivorPos[2]);

		if (CheckDistance(distance))
		{
			float addAmount[3];
			float resultant[3];
			float svVector[3];
			float ratio[2];

			ratio[0] = distance[0] / SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]);//Ratio x/hypo
			ratio[1] = distance[1] / SquareRoot(distance[1]*distance[1] + distance[0]*distance[0]);//Ratio y/hypo

			GetEntPropVector(client, Prop_Data, "m_vecVelocity", svVector);

			addAmount[0] = (ratio[0] * Direction()) * power;//multiply negative = away from tank. multiply positive = towards tank.
			addAmount[1] = (ratio[1] * Direction()) * power;
			addAmount[2] = power;

			resultant[0] = addAmount[0] + svVector[0];//current velocity + added velocity
			resultant[1] = addAmount[1] + svVector[1];
			resultant[2] = power;

			//SetEntProp(client, Prop_Data, "m_nSequence", 803);

			switch (GetConVarInt(cvar_knockback_type))
			{
				case 0: //Jump-like knockback
				{
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, resultant);
					break;
				}

				case 1: //Tank punch knockback
				{
					Fling(client, addAmount, tank);
					break;
				}

				case 2: //Stagger survivors
				{
					L4D_StaggerPlayer(client, tank, tankPos);
				
					//Optional: show hint depending on sm_tankroar_hint setting
					int hintType = GetConVarInt(cvar_hint);
					if (hintType == 1 || hintType == 3)
					{
					PrintToChat(client, "\x03[Hint]\x01 Tank roar staggered you!");
					}
					if (hintType == 2 || hintType == 3)
					{
						int instrHintEnt = CreateEntityByName("env_instructor_hint");
						DispatchKeyValue(instrHintEnt, "hint_target", "!self");
						DispatchKeyValue(instrHintEnt, "hint_range", "0.01");
						DispatchKeyValue(instrHintEnt, "hint_color", "255 255 255");
						DispatchKeyValue(instrHintEnt, "hint_caption", "Tank roar staggered you!");
						DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", "use_binding");
						DispatchKeyValue(instrHintEnt, "hint_timeout", "4.0");
						DispatchSpawn(instrHintEnt);
						AcceptEntityInput(instrHintEnt, "ShowHint", client);
						CreateTimer(4.0, DisableInstructor, GetClientUserId(client));
					}
					break;
				}
			}
			Handle hShake = StartMessageOne("Shake", client);
			if (hShake != INVALID_HANDLE)
			{
				BfWriteByte(hShake, 0);		
				BfWriteFloat(hShake, 10.0);
				BfWriteFloat(hShake, 1.0);
				BfWriteFloat(hShake, 1.0);
				EndMessage();
			}

			int dmg = GetConVarInt(cvar_damage);
			while (dmg>100)
			{
				ApplyDamage(client, 100, tank, 0, "weapon tank_claw");
				dmg -= 100;
			}
			ApplyDamage(client, dmg, tank, 0, "weapon tank_claw");
		}
	}
}

public Action UnstunTank(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientValid(client))
		return Plugin_Handled;

	if (IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Send, "m_fFlags", GetEntityFlags(client) & ~FL_FROZEN);
	}
	return Plugin_Handled;
}

bool CheckDistance(float distance[3])
{
	int roarType = GetConVarInt(cvar_tankroar);

	float distanceaffected = GetConVarFloat(cvar_distanceaffected);

	switch (roarType)
	{
		case 0: return false;
		case 1:
		{
			if ((SquareRoot(distance[0]*distance[0] + distance[1]*distance[1]) <= distanceaffected) && (Absolute(distance[2]) <= 50)) return true;
		}
		default:
		{
			if (SquareRoot(distance[0]*distance[0] + distance[1]*distance[1] + distance[2]*distance[2]) <= distanceaffected) return true;
		}
	}
	return false;
}

float Absolute(float number)
{
	if (number < 0) return -number;
	return number;
}

bool IsClientValid(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

int Direction()
{
	int direction = GetConVarInt(cvar_direction);
	if (direction == 0) return 1;
	return -1;
}

public Action CooldownReset(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsClientValid(client))
		return Plugin_Handled;

	cooldown[client] = false;

	if (!IsFakeClient(client))
		EmitSoundToClient(client, ROAR_READY_SOUND, SOUND_FROM_PLAYER, SNDCHAN_STATIC);

	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	cooldown[client] = false;
}

int GetZombieClass(int client)
{
	if (GetClientTeam(client) == INFECTED_TEAM)
		return GetEntProp(client, Prop_Send, "m_zombieClass");

	return -1;
}