#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.0"

#define NICK		0
#define ROCHELLE	1
#define COACH		2
#define ELLIS		3
#define BILL		4
#define ZOEY		5
#define FRANCIS		6
#define LOUIS		7

#define NONE		0
#define SMOKER		1
#define HUNTER		3
#define JOCKEY		5
#define CHARGER		6
#define TANK		8

#define NICK_MDL		"models/survivors/survivor_gambler.mdl"
#define ROCHELLE_MDL	"models/survivors/survivor_producer.mdl"
#define COACH_MDL		"models/survivors/survivor_coach.mdl"
#define ELLIS_MDL		"models/survivors/survivor_mechanic.mdl"
#define BILL_MDL		"models/survivors/survivor_namvet.mdl"
#define ZOEY_MDL		"models/survivors/survivor_teenangst.mdl"
#define FRANCIS_MDL		"models/survivors/survivor_biker.mdl"
#define LOUIS_MDL		"models/survivors/survivor_manager.mdl"

#define MODEL0_SOUND	"/weapons/pistol/gunfire/pistol_fire.wav"
#define MODEL0			"weapon_pistol"

new bool:Debug = false;

new bool:L4D2Version = false;
new String:g_GhostRobotDamage[10];
new Handle:ghost_enable;
new Handle:ghost_versus;
new Handle:ghost_chance;
new Handle:ghost_alpha;
new Handle:ghost_bordcast;
new Handle:ghost_gun;
new Handle:ghost_shot_interval;
new Handle:ghost_shoot_damage;
new g_lGhost[MAXPLAYERS+1];
new g_lAttacker[MAXPLAYERS+1];
new g_Robot[MAXPLAYERS+1];
new g_ScanStart = false;
new g_ShotInterval[MAXPLAYERS+1];
new GameMode = 0;
new g_Rand = 4;
new g_sprite;
new g_Glpha;
new g_Rnd;
new g_Ghost;
new Current, Last = 0;

public Plugin:myinfo =
{
	name = "L4D Ghost",
	author = "GsiX",
	description = "Ghost of the dead survivor",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=1802732#post1802732"
};

public OnPluginStart()
{
	CreateConVar("ghost_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	ghost_enable = CreateConVar("ghost_enable", "1", "0: off,  1: on,  Toggel plugin functionality", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_versus = CreateConVar("ghost_versus", "0", "0: off,  1: on,  Toggle enable plagin on versus", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_chance = CreateConVar("ghost_chance", "10", "1% - 100%, Chance of infected become ghost", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_alpha = CreateConVar("ghost_alpha", "100", "0 - 255, How visible our ghost to the world", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_bordcast = CreateConVar("ghost_bordcast", "1", "0:Off, 1:On, Tell the world our ghost has spawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_gun = CreateConVar("ghost_gun", "1", "0:off, 1:on, Do we give our ghost extra gun? (Note: If off chrac may behave not normal)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_shot_interval = CreateConVar("ghost_shot_interval", "0.3", "0.0:Min, 3.0:Max, Intrval between ghost robot gun shooting", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	ghost_shoot_damage = CreateConVar("ghost_shoot_damage", "1", "0:Min, 100:Max,  Ghost robot gun damage. Note: 100 dmage is instan kill", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_ghost");
	
	HookEvent("player_spawn",				EVENT_GhostSpawn, EventHookMode_Pre);
	HookEvent("player_death",				EVENT_GhostDeath);
	HookEvent("player_hurt",				EVENT_GhostHurt);
	HookEvent("player_team",				EVENT_GhostTeam);
	HookEvent("round_start",				EVENT_GhostStart);
	HookConVarChange(ghost_enable,			CVARChanged);
	HookConVarChange(ghost_versus,			CVARChanged);
	HookConVarChange(ghost_shoot_damage,	CVARChanged);
	
	UpdateGame();
}

public OnMapStart()
{
	UpdateGame();
	if(L4D2Version)	{
		if (!IsModelPrecached(NICK_MDL))		PrecacheModel(NICK_MDL, false);
		if (!IsModelPrecached(ROCHELLE_MDL))	PrecacheModel(ROCHELLE_MDL, false);
		if (!IsModelPrecached(COACH_MDL))		PrecacheModel(COACH_MDL, false);
		if (!IsModelPrecached(ELLIS_MDL))		PrecacheModel(ELLIS_MDL, false);
	}
	if (!IsModelPrecached(BILL_MDL))		PrecacheModel(BILL_MDL, false);
	if (!IsModelPrecached(ZOEY_MDL))		PrecacheModel(ZOEY_MDL, false);
	if (!IsModelPrecached(FRANCIS_MDL))		PrecacheModel(FRANCIS_MDL, false);
	if (!IsModelPrecached(LOUIS_MDL))		PrecacheModel(LOUIS_MDL, false);
	if (!IsModelPrecached(MODEL0))			PrecacheModel(MODEL0, false);
	PrecacheSound(MODEL0_SOUND, true);
	if(L4D2Version)	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	}
	else {
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
 	}
	g_ScanStart = false;
}

UpdateGame()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
		GameMode = 0;
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		L4D2Version=true;
	else
		L4D2Version=false;
	
	new String:str[10];
	Format(str, sizeof(str), "%d", GetConVarInt(ghost_shoot_damage));
	g_GhostRobotDamage = str;
	
	if(L4D2Version) g_Rand = 0;
}

public CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateGame();
}

public EVENT_GhostStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(ghost_enable) == 0 || (GameMode == 2 && GetConVarInt(ghost_versus) == 0)) return;
	for (new i =1; i< MaxClients; i++)
	{
		if (IsValidGhost(i))
		{
			if ((g_Robot[i]) > 0)
			{
				AcceptEntityInput(g_Robot[i], "kill")
			}
			g_Robot[i] = 0;
			g_lGhost[i] = 0;
			g_ShotInterval[i] = 0;
		}
		if (IsValidSurvivor(i))
		{
			g_lAttacker[i] = 0;
		}
	}
}

public Action:EVENT_GhostSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(ghost_enable) == 0 || (GameMode == 2 && GetConVarInt(ghost_versus) == 0)) return Plugin_Handled;
	new ghost = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidGhost(ghost))
	{
		g_Rnd = GetRandomInt(0, 100);
		g_Ghost = GetConVarInt(ghost_chance);
		if (g_Ghost > 100) g_Ghost = 100;
		if (g_Ghost < 0) g_Ghost = 0;
		if (g_Rnd <= g_Ghost)
		{
			g_lGhost[ghost] = 1;
			g_ShotInterval[ghost] = 0;
			while (Current == Last)
			{
				Current = GetRandomInt(g_Rand, 7)
			}
			Last = Current;
			switch (Last) {
				case NICK:		{ TweakChracter(ghost, NICK)		;}
				case ROCHELLE:	{ TweakChracter(ghost, ROCHELLE)	;}
				case COACH:		{ TweakChracter(ghost, COACH)		;}
				case ELLIS:		{ TweakChracter(ghost, ELLIS)		;}
				case BILL:		{ TweakChracter(ghost, BILL)		;}
				case ZOEY:		{ TweakChracter(ghost, ZOEY)		;}
				case FRANCIS:	{ TweakChracter(ghost, FRANCIS)		;}
				case LOUIS:		{ TweakChracter(ghost, LOUIS)		;}
			}
		}
		else {
			g_lGhost[ghost] = 0;
			g_Robot[ghost] = 0;
		}
	}
	return Plugin_Handled;
}

public EVENT_GhostHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(ghost_enable) == 0 || (GameMode == 2 && GetConVarInt(ghost_versus) == 0)) return;
	new ghost = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidGhost(ghost))
	{
		if (g_lGhost[ghost] == 1)
		{
			g_Glpha = GetConVarInt(ghost_alpha);
			if (g_Glpha > 255) g_Glpha = 255;
			if (g_Glpha < 0) g_Glpha = 0;
			SetEntityRenderMode(ghost, RENDER_TRANSCOLOR);
			SetEntityRenderColor(ghost, 255, 255, 255, g_Glpha);
			if (IsValidSurvivor(attacker))
			{
				g_lAttacker[attacker] = ghost;
			}
		}
	}
}

public EVENT_GhostTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(ghost_enable) == 0 || (GameMode == 2 && GetConVarInt(ghost_versus) == 0)) return;
	new ghost = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidGhost(ghost) && g_lGhost[ghost] == 1 && g_Robot[ghost] > 0)
	{
		g_lGhost[ghost] = 0;
		g_ShotInterval[ghost] = 0;
		CheckValidityScan(ghost);
		for (new i=1; i < MaxClients; i++)
		{
			if ((IsValidSurvivor(i)) && (g_lAttacker[i] == ghost))
			{
				g_lAttacker[i] = 0;
			}
		}
	}
}

public EVENT_GhostDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(ghost_enable) == 0 || (GameMode == 2 && GetConVarInt(ghost_versus) == 0)) return;
	new ghost = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (g_lGhost[ghost] == 1)
	{
		g_lGhost[ghost] = 0;
		g_ShotInterval[ghost] = 0;
		if (IsValidSurvivor(attacker))
		{
			new String:attName[32];
			GetClientName(attacker, attName, sizeof(attName));
			PrintToChatAll("[GHOST] Ghost killed by %s", attName);
		}
		for (new i=1; i < MaxClients; i++)
		{
			if ((IsValidSurvivor(i)) && (g_lAttacker[i] == ghost) && IsNo_Incap(i))
			{
				new health = GetClientHealth(i);
				if(health < 100)
				{
					health = health + 10;
					if ((health) >= 100) health = 100;
					SetEntityHealth(i, health);
					if (health >= 50)
					{
						SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
					}
				}
				g_lAttacker[i] = 0;
			}
		}
		CheckValidityScan(ghost);
	}
}

TweakChracter(client, any:chrac)
{
	// tweak our ghost HP xD
	new	l_RandHP = GetRandomInt(0, 4)
	new HP;
	switch (l_RandHP) {
		case 0: {	HP = 1000	;}
		case 1: {	HP = 1500	;}
		case 2: {	HP = 2000	;}
		case 3: {	HP = 2500	;}
		case 4: {	HP = 3000	;}
	}
	SetEntityHealth(client, HP);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	
	g_Glpha = GetConVarInt(ghost_alpha);
	if (g_Glpha > 255) g_Glpha = 255;
	if (g_Glpha < 0) g_Glpha = 0;
	SetEntityRenderColor(client, 255, 255, 255, g_Glpha);
	
	// tweak or ghost model and tell people he is on the field.
	new l_Msg = GetConVarInt(ghost_bordcast);
	new String:model[64];
	switch (chrac){
		case 0: { model = NICK_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Nick's ghost on the field!!,   HP = %d", HP)		;}
		case 1: { model = ROCHELLE_MDL	; if (l_Msg == 1) PrintToChatAll("[GHOST] Rochelle's ghost on the field!!,   HP = %d", HP)	;}
		case 2: { model = COACH_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Coach's ghost on the field!!,   HP = %d", HP)		;}
		case 3: { model = ELLIS_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Ellis's ghost on the field!!,   HP = %d", HP)		;}
		case 4: { model = BILL_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Bill's ghost on the field!!,   HP = %d", HP)		;}
		case 5: { model = ZOEY_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Zoey's ghost on the field!!,   HP = %d", HP)		;}
		case 6: { model = FRANCIS_MDL	; if (l_Msg == 1) PrintToChatAll("[GHOST] Francis's ghost on the field!!,   HP = %d", HP)	;}
		case 7: { model = LOUIS_MDL		; if (l_Msg == 1) PrintToChatAll("[GHOST] Louis's ghost on the field!!,   HP = %d", HP)		;}
	}
	SetEntProp(client, Prop_Send, "m_iTeamNum" , 2);
	//SetEntProp(client, Prop_Send, "m_customAbility", -1);
	SetEntityModel(client, model);
	SetEntProp(client, Prop_Send, "m_survivorCharacter", chrac);
	if (GetConVarInt(ghost_gun) > 0)
		EquipGhost(client, "weapon_pistol");
	SetEntProp(client, Prop_Send, "m_iTeamNum" , 3);
	AddRobot(client);
}

CheckValidityScan(client)
{
	if (g_Robot[client] > 0)
	{
		if (Debug) {
			PrintToChatAll("[Pistol Removed]: %d", g_Robot[client]);
			PrintToChatAll("Pistol Owner]: %d", client);
		}
		AcceptEntityInput(g_Robot[client], "kill")
		g_Robot[client] = 0;
	}
	new Logic = 0
	for (new i=1; i < MaxClients; i++)
	{
		if(IsValidGhost(i) && g_Robot[i] > 0)
		{
			Logic ++;
		}
	}
	if (Logic == 0) g_ScanStart = false;
}

AddRobot(client)
{
	new Float:vAngles[3];
	new Float:vOrigin[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);
	vOrigin[0] += 15.0;
	vOrigin[2] += 50.0;
	GetClientEyeAngles(client, vAngles);
	
	new l_Pistol = CreateEntityByName(MODEL0);         
	DispatchSpawn(l_Pistol);          
	TeleportEntity(l_Pistol, vOrigin, vAngles, NULL_VECTOR);
	SetEntityMoveType(l_Pistol, MOVETYPE_FLY);
	g_Robot[client] = l_Pistol;
	g_ScanStart = true;
	if (Debug) {
		PrintToChatAll("[Pistol Created]: %d", l_Pistol);
		PrintToChatAll("Pistol Owner]: %d", client);
	}
}

public OnGameFrame()
{
	if(!g_ScanStart) return;
	for (new i = 1; i <= MaxClients; i++)
	{
		if ((IsValidGhost(i)) && (g_Robot[i] != 0))
		{
			FollowGhost(i);
		}
	}
	return;
}

FollowGhost(client)
{
	// lets follow the ghost
	new Float:aClPos[3];
	new Float:vClPos[3];
	new Float:vROPos[3];
	new Float:Dist;
	GetClientEyeAngles(client, aClPos);
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vClPos);
	GetEntPropVector(g_Robot[client], Prop_Send, "m_vecOrigin", vROPos);
	Dist = GetVectorDistance(vClPos, vROPos)
	if (Dist > 50.0)
	{
		vClPos[0] += 15.0;
		vClPos[2] += 50.0;
		TeleportEntity(g_Robot[client], vClPos, aClPos, NULL_VECTOR);
	}

	// lets continue aim and shot what our ghost looking at
	decl Float:vSUPos[3];
	decl Float:vNew[3];
	decl Float:angle[3];
	for (new i = 1; i < MaxClients; i++)
	{
		new Object = GetClientAimTarget(client, false);
		if (Object == -1) return;
		if (IsValidSurvivor(i) && Object == i)
		{
			// let shout him
			GetClientEyePosition(i, vSUPos);
			Dist = GetVectorDistance(vROPos, vSUPos) ;
			if (Dist < 2000.0)
			{
				SubtractVectors(vSUPos, vROPos, vNew);
				GetVectorAngles(vNew, angle);
				new Handle:trace = TR_TraceRayFilterEx(vSUPos, vROPos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, g_Robot[client]);
				if(TR_DidHit(trace))
				{
				
				}
				else
				{
					if (g_ShotInterval[i] == 0)
					{
						g_ShotInterval[i] = 1;
						FireBullet(client, g_Robot[client], vSUPos, vROPos);
						new Float:inT = GetConVarFloat(ghost_shot_interval);
						if (inT >= 3.0) inT = 3.0;
						CreateTimer(inT, Timer_ShotInterval, i);
					}
				}
				CloseHandle(trace);
			}
		}
	}
	return;
}
// code from robot by pan xiohai
FireBullet(controller, bot, Float:SurvivorPOS[3], Float:RobotPOS[3])
{
	decl Float:vAngles[3];
	decl Float:vAngles2[3];
	decl Float:pos[3];
	
	SubtractVectors(SurvivorPOS, RobotPOS, SurvivorPOS);
	GetVectorAngles(SurvivorPOS, vAngles);

	decl Float:v1[3];
	decl Float:v2[3];
	
	// how many bullet per shoot (we may need future cvar)
	new l_Bullet = 1;
	for(new c = 0; c < l_Bullet; c++)
	{
		vAngles2[0]=vAngles[0]+GetRandomFloat(1.0, 3.0);	
		vAngles2[1]=vAngles[1]+GetRandomFloat(1.0, 3.0);	
		vAngles2[2]=vAngles[2]+GetRandomFloat(1.0, 3.0);
		
		new hittarget=0;
		new Handle:trace = TR_TraceRayFilterEx(RobotPOS, vAngles2, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndInfected, bot);
		if(TR_DidHit(trace))
		{
			
			TR_GetEndPosition(pos, trace);
			hittarget=TR_GetEntityIndex( trace);
			
			decl Float:Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(pos,Direction,1,3);
			TE_SendToAll();
		}
		CloseHandle(trace);
		if(hittarget > 0)		
		{
			new pointHurt = CreateEntityByName("point_hurt");
			if(pointHurt > 0)
			{
				if(IsValidEdict(pointHurt))
				{
					if(hittarget > 0 && IsValidEdict(hittarget))
					{		
						new String:N[10];
						Format(N, 20, "target%d", hittarget);
						DispatchKeyValue(hittarget,"targetname", N);
						DispatchKeyValue(pointHurt,"DamageType","2");
						DispatchKeyValue(pointHurt,"DamageTarget", N);
						DispatchKeyValue(pointHurt,"classname",MODEL0);
						DispatchKeyValue(pointHurt,"Damage", g_GhostRobotDamage);
						AcceptEntityInput(pointHurt,"Hurt",(controller > 0) ? controller: -1);
					}
				}
			}
		}
		new Float:infectedorigin[3];
		SubtractVectors(RobotPOS, pos, v1);
		NormalizeVector(v1, v2);	
		ScaleVector(v2, 36.0);
		SubtractVectors(RobotPOS, v2, infectedorigin);
	 
		decl color[4];
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
		
		new Float:life = 0.06;
		new Float:width1 = 0.01;
		new Float:width2 = 0.3;		
		if(L4D2Version)width2 = 0.08;		
		TE_SetupBeamPoints(infectedorigin, pos, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
		TE_SendToAll();
 		EmitSoundToAll(MODEL0_SOUND, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, RobotPOS, NULL_VECTOR, false, 0.0);
	}
}
// code from robot by pan xiohai
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}
// code from robot by pan xiohai
public bool:TraceRayDontHitSelfAndInfected(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity) == 3)
		{
			return false;
		}
	}
	return true;
}

public Action:Timer_ShotInterval(Handle:timer, any:shotter)
{
	g_ShotInterval[shotter] = 0;
}

stock EquipGhost(client, String:Item[64])
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", Item);
	SetCommandFlags("give", flags);
}

stock bool:IsValidGhost(client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 3) return false;
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == TANK) return false;
	return true;
}

stock bool:IsValidSurvivor(client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}

stock bool:IsNo_Incap(victim)
{
	// if survivor incaped return false, true otherwise.
	if (GetEntProp(victim, Prop_Send, "m_isIncapacitated") == 1) return false;
	return true;
}

