#pragma semicolon 1

#include <sourcemod>
#include <sdktools>


#define PLUGIN_NAME		 	"Firework particules"
#define PLUGIN_AUTHOR	   	"Erreur 500"
#define PLUGIN_DESCRIPTION	"Went round end, shoot fireworks"
#define PLUGIN_VERSION	  	"2.0"
#define PLUGIN_CONTACT	  	"erreur500@hotmail.fr"


new Float:PosMax[3] = {0.0, 0.0, 0.0};
new Float:PosMin[2] = {0.0, 0.0};

new bool:IsEnd 			= false;
new bool:PositionForced = false;
new bool:ValidArea 		= false;


new LineCount = 0;

new String:EffectsList[PLATFORM_MAX_PATH];
new String:FireworkPositions[PLATFORM_MAX_PATH];
new String:game_dir[30];
new String:ParticleFile[32];

new Handle:c_ForceNight;


public Plugin:myinfo =
{
	name		= PLUGIN_NAME,
	author	  	= PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version	 	= PLUGIN_VERSION,
	url		 	= PLUGIN_CONTACT
};

public OnPluginStart()
{
	GetGameFolderName(game_dir, 29);
	if(!StrEqual(game_dir,"tf"))
	{
		LogMessage("This plugin can be run only on TF2 servers !");
		return;
	}
	
	CreateConVar("fireworks_version", PLUGIN_VERSION, "Fireworks version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_ForceNight= CreateConVar("fw_force_night", 	"0",	"1 = Force night sky", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	RegAdminCmd("fireworks", ConsoleCmd, ADMFLAG_GENERIC);
	RegAdminCmd("reload_fireworks", ConsoleCmdreload_fireworks, ADMFLAG_GENERIC);
	
	HookConVarChange(c_ForceNight, CallBackCVarForceNight);
	
	Format(ParticleFile, sizeof(ParticleFile), "fireworks_%s_list.txt", game_dir);
	BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", ParticleFile);
	BuildPath(Path_SM, FireworkPositions, sizeof(FireworkPositions), "configs/fireworks_tf_pos.cfg");
	
	AutoExecConfig(true, "Fireworks");
}

public CallBackCVarForceNight(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(StrEqual(newVal, "0"))
	{
		LogMessage("[FIREWORKS] Night Sky is disabled. Take effect on next map !");
	}
	else
	{
		LogMessage("[FIREWORKS] Night Sky is enabled. Take effect on next map !");
	}
}

public OnMapStart()
{
	if(!StrEqual(game_dir,"tf"))
	{
		LogMessage("This plugin can be run only on TF2 servers !");
		return;
	}
	
	decl String:Adress[128];
	for(new i=1;i<=5;i++)
	{
		Format(Adress, sizeof(Adress), "sound/fireworks/firework_explode%i.mp3", i);
		AddFileToDownloadsTable(Adress);
		Format(Adress, sizeof(Adress), "fireworks/firework_explode%i.mp3", i);
		PrecacheSound(Adress);
	}
	
	if(GetConVarBool(c_ForceNight))
	{
		new String:NightSkyList[6][32] = {"sky_night_01", "sky_nightfall_01", "sky_alpinestorm_01", "sky_halloween", "sky_halloween_night_01", "sky_halloween_night2014_01"};
		
		decl String:Command[64];
		Format(Command, sizeof(Command), "sv_skyname %s", NightSkyList[GetRandomInt(0, 5)]);
		ServerCommand(Command);
	}
	
	ValidArea = false;
	PositionForced = false;
	if(!FindPosInFile())
		GetSkyCameraArea();
}

public OnMapEnd()
{
	IsEnd = false;
}

public OnConfigsExecuted()
{
	if(StrEqual(game_dir,"tf")) // for TF2
	{		
		HookEvent("teamplay_round_win", EventRoundEnd);
		HookEvent("teamplay_round_start", EventRoundStart);
	}
}

public Action:ConsoleCmdreload_fireworks(client, Args)
{
	ValidArea = false;
	PositionForced = false;
	
	if(IsValidClient(client))
		PrintToChat(client, "Firework positions reloaded !");
	else
		LogMessage("Firework positions reloaded !");
		
	if(!FindPosInFile())
		GetSkyCameraArea();

}

/////////////////////////////////////////////////////////////////////////////////////////////
//							Event zone 
////////////////////////////////////////////////////////////////////////////////////////////


public Action:EventRoundEnd(Handle:hEvent, const String:strName[], bool:bHidden)
{
	if(ValidArea)
	{
		IsEnd = true;
		ActiveFireworks();
	}
	else
		LogMessage("Can't spawn fireworks: no area found !");
}

public Action:EventRoundStart(Handle:hEvent, const String:strName[], bool:bHidden)
{
	IsEnd = false;
}

/////////////////////////////////////////////////////////////////////////////////////////////
//							Fireworks
////////////////////////////////////////////////////////////////////////////////////////////

public Action:ConsoleCmd(client, Args)
{
	decl String:Argument[256];
	GetCmdArgString(Argument, sizeof(Argument));
	new TimeNeeded = StringToInt(Argument);
	
	if(StrEqual(Argument, "stop"))
	{
		IsEnd = false;
		if(IsValidClient(client))
			PrintToChat(client,"Fireworks stopped");
		else
			LogMessage("Fireworks stopped");
		return;
	}
	else if(StrEqual(Argument, "start"))
	{
		if(ValidArea)
		{
			IsEnd = true;
			if(IsValidClient(client))
				PrintToChat(client,"Fireworks enabled");
			else
				LogMessage("Fireworks enabled");
				
			ActiveFireworks();
			return;
		}
		else
		{
			if(IsValidClient(client))
				PrintToChat(client, "Can't spawn fireworks: no area found !");
			else
				LogMessage("Can't spawn fireworks: no area found !");
		}
		
	}
	else if(TimeNeeded <= 0)
	{
		if(IsValidClient(client))
			PrintToChat(client,"!fireworks <START|TIME|STOP>");
		else
			LogMessage("fireworks <START|TIME|STOP>");
		return;
	}
	else if(TimeNeeded > 0)
	{
		if(ValidArea)
		{
			IsEnd = true;
			CreateTimer(TimeNeeded*1.0, TimerStopFireworks);
			if(IsValidClient(client))
				PrintToChat(client,"Fireworks launched for %i sec", TimeNeeded);
			else
				LogMessage("Fireworks launched for %i sec", TimeNeeded);
			ActiveFireworks();
		}
		else
		{
			if(IsValidClient(client))
				PrintToChat(client, "Can't spawn fireworks: no area found !");
			else
				LogMessage("Can't spawn fireworks: no area found !");
		}
	}
}

stock bool:IsValidClient(iClient)
{
	if (iClient <= 0) return false;
	if (iClient > MaxClients) return false;
	return IsClientInGame(iClient);
}

ActiveFireworks()
{
	LineCount = 0;
	new String:Line[255];
	new Handle:file = OpenFile(EffectsList, "rt");
	if (file == INVALID_HANDLE)
	{
		LogError("[FIREWORKS] Could not open file %s", ParticleFile);
		CloseHandle(file);
		return;
	}
	while (!IsEndOfFile(file))
	{
		ReadFileLine(file, Line, sizeof(Line));
		LineCount++;
	}
	CloseHandle(file);
	if(LineCount == 0)
	{
		LogMessage("Can't find any particle in %s", ParticleFile);
		return;
	}
	
	Fireworks();
}


GetSkyCameraArea()
{
	new entity = FindEntityByClassname(-1, "sky_camera");
	if(entity == -1)
	{
		LogMessage("There is no sky_camera");
		return;
	}
	
	decl Float:Pos_sc[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos_sc);
	
	decl Float:Angle[3];
	decl Float:Up[3];
	decl Float:Right[3];
	decl Float:Left[3];
	decl Float:Right_op[3];
	decl Float:Left_op[3];
	new Handle:trace;
	
	// Up AXE
	Angle[0] = -90.0;
	Angle[1] = 0.0;
	
	trace = TR_TraceRayFilterEx(Pos_sc, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);	
		return;
	}
	TR_GetEndPosition(Up, trace);
	
	
	// Right AXE
	Angle[0] = 0.0;
	Angle[1] = 0.0;
	trace = TR_TraceRayFilterEx(Up, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);	
		return;
	}
	TR_GetEndPosition(Right, trace);
	
	
	// Left AXE
	Angle[0] = 0.0;
	Angle[1] = 90.0;
	trace = TR_TraceRayFilterEx(Up, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);	
		return;
	}
	TR_GetEndPosition(Left, trace);
	
	
	// Right_op AXE
	Angle[0] = 0.0;
	Angle[1] = 180.0;
	trace = TR_TraceRayFilterEx(Up, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);	
		return;
	}
	TR_GetEndPosition(Right_op, trace);
	
	
	// Left_op AXE
	Angle[0] = 0.0;
	Angle[1] = 270.0;
	trace = TR_TraceRayFilterEx(Up, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
	if(!TR_DidHit(trace)) 
	{
		CloseHandle(trace);	
		return;
	}
	TR_GetEndPosition(Left_op, trace);
	
	
	if(!PositionForced) // If there isn't position in .cfg file 
	{
		PosMax[2] = Up[2];
		PosMax[0] = GetTheHighestValue(Right[0], Left[0], Right_op[0], Left_op[0]);
		PosMax[1] = GetTheHighestValue(Right[1], Left[1], Right_op[1], Left_op[1]);
		PosMin[0] = GetTheLowestValue(Right[0], Left[0], Right_op[0], Left_op[0]);
		PosMin[1] = GetTheLowestValue(Right[1], Left[1], Right_op[1], Left_op[1]);
		//LogMessage("MAX [0] %f, [1] %f, [2] %f", PosMax[0], PosMax[1], PosMax[2]);
		//LogMessage("MIN [0] %f, [1] %f", PosMin[0], PosMin[1]);
		ValidArea = true;
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data) 
{
 	return entity > MAXPLAYERS;
}

Float:GetTheHighestValue(Float:a, Float:b, Float:c, Float:d)
{
	if(a > b)
	{
		if(a > c)
		{
			return a > d ? a : d; 
		}
		else
		{
			return c > d ? c : d;
		}
	}
	else
	{
		if(b > c)
		{
			return b > d ? b : d; 
		}
		else
		{
			return c > d ? c : d;
		}
	}
}

Float:GetTheLowestValue(Float:a, Float:b, Float:c, Float:d)
{
	if(a < b)
	{
		if(a < c)
		{
			return a < d ? a : d; 
		}
		else
		{
			return c < d ? c : d;
		}
	}
	else
	{
		if(b < c)
		{
			return b < d ? b : d; 
		}
		else
		{
			return c < d ? c : d;
		}
	}
}

bool:FindPosInFile()
{
	new Handle: kv;
	decl String:CurrentMap[64];
	
	kv = CreateKeyValues("Fireworks");
	if(!FileToKeyValues(kv, FireworkPositions))
	{
		LogError("Can't open fireworks_pos.cfg file");
		CloseHandle(kv);
		return false;
	}
	
	LogMessage("Prepare fireworks !");
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	if(!KvJumpToKey(kv, CurrentMap))
		return false;
	
	PosMin[0] = KvGetFloat(kv, "Xmin", 0.00001);
	PosMin[1] = KvGetFloat(kv, "Ymin", 0.00001);
	PosMax[0] = KvGetFloat(kv, "Xmax", 0.00001);
	PosMax[1] = KvGetFloat(kv, "Ymax", 0.00001);
	PosMax[2] = KvGetFloat(kv, "Z", 0.00001);

	KvRewind(kv);
	CloseHandle(kv);
	
	if(PosMin[0] == 0.00001 || PosMin[1] == 0.00001 || PosMax[0] == 0.00001 || PosMax[1] == 0.00001 || PosMax[2] == 0.00001)
	{
		ValidArea = false;
		return false;
	}
	else
	{
		PositionForced = true;
		ValidArea = true;
		return true;
	}
}

Fireworks()
{	
	CreateTimer(GetRandomFloat(0.01,0.5), TimerSpawnFireworks);
}

public Action:TimerSpawnFireworks(Handle:timer, any:data)
{	
	new Float:Pos[3];
	new Float:Angl[3] = {-90.0,0.0,0.0};
	decl Float:Vel[3];
	decl Float:vBufferi[3];
	
	new RandNum = GetRandomInt(1, 7);
	for(new nbr = 0; nbr< RandNum; nbr++)
	{
		Pos[0] = GetRandomInt(RoundToZero(PosMin[0]), RoundToZero(PosMax[0])) * 1.0;
		Pos[1] = GetRandomInt(RoundToZero(PosMin[1]), RoundToZero(PosMax[1])) * 1.0;	
		Pos[2] = PosMax[2];
		
		if(!PositionForced)	// Generate by the plugin (=Z on the sky)
		{
			new Float:Angle[3] = {90.0,0.0,0.0};
			decl Float:EndPos[3];
			new Handle:trace;
			trace = TR_TraceRayFilterEx(Pos, Angle, MASK_ALL, RayType_Infinite, TraceEntityFilterPlayer); //MASK_SOLID pour detecter les joueurs
			if(!TR_DidHit(trace)) 
			{
				CloseHandle(trace);	
				return;
			}
			TR_GetEndPosition(EndPos, trace);
			Pos[2] = EndPos[2];
		}
			
		GetAngleVectors(Angl, vBufferi, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vBufferi, Vel);
		ScaleVector(Vel, 1000.0);
		
		if(StrEqual(game_dir,"tf"))
		{
			new ent_rocket = CreateEntityByName("tf_projectile_flare");
			SetEntData(ent_rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iTeamNum"), GetRandomInt(2,3), true);
			decl String:TargetName[16];
			Format(TargetName, sizeof(TargetName), "fireworks_%i",nbr);
			DispatchKeyValue(ent_rocket, "targetname", TargetName);
			DispatchSpawn(ent_rocket);
			TeleportEntity(ent_rocket, Pos, Angl, Vel);
			CreateTimer(0.4, ExplodeProjectile, ent_rocket);
		}
	}	
	if(IsEnd)
		Fireworks();
}

public OnEntityDestroyed(entity)	//Called went short skybox
{
	SpawnParticle(entity);
}

public Action:ExplodeProjectile(Handle:timer, any:entity)		//Called went hight skybox
{	
	SpawnParticle(entity);
}

SpawnParticle(entity)
{
	if(!IsValidEdict(entity))
		return;
		
	decl String:ClassName[64];
	GetEdictClassname(entity, ClassName, sizeof(ClassName));
	
	if(!StrEqual(ClassName, "tf_projectile_flare"))	
	{
		return;
	}
	
	new String:WeapData[10];
	GetEntPropString(entity, Prop_Data, "m_iName", WeapData, sizeof(WeapData));
	if(StrContains(WeapData, "fireworks", true) == -1)
		return;
		
	decl Float:Pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);
	RemoveEdict(entity);
		
	new iParticle 	= CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{		
		decl Float:ParticleAng[3];
		ParticleAng[0]	= 0.0;
		ParticleAng[1] 	= GetRandomInt(0, 360) * 1.0;
		ParticleAng[2]	= 0.0;
			
		decl String:Adress[128];
		Format(Adress, sizeof(Adress), "playgamesound fireworks/firework_explode%i.mp3", GetRandomInt(1, 5));
		for(new client=1; client<MaxClients; client++)
			if(IsClientInGame(client) && IsClientConnected(client) && !IsClientReplay(client) && !IsClientSourceTV(client))
				ClientCommand(client, Adress);
		
		SpawnExploseParticle(Pos);
		
		new Line = GetRandomInt(1, LineCount);
		new String:strLine[128];
		new Handle:file = OpenFile(EffectsList, "rt");
		if (file == INVALID_HANDLE)
		{
			LogError("[FIREWORKS] Could not open file %s", ParticleFile);
			CloseHandle(file);
			return;
		}
		
		new CurrentLine = 0;
		while(CurrentLine != Line)
		{
			ReadFileLine(file, strLine, sizeof(strLine));
			CurrentLine++;
		}
		
		CloseHandle(file);
		TrimString(strLine);
		DispatchKeyValue(iParticle, "effect_name", strLine);
		TeleportEntity(iParticle, Pos, ParticleAng, NULL_VECTOR);
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
			
		CreateTimer(0.5, TimerRemoveEdict, EntIndexToEntRef(iParticle));
	}
}

SpawnExploseParticle(Float:Pos[3])
{
	new iParticle 	= CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{	
		DispatchKeyValue(iParticle, "effect_name", "lowV_impactglow");
		TeleportEntity(iParticle, Pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
			
		CreateTimer(0.5, TimerRemoveEdict, EntIndexToEntRef(iParticle));
	}
}

public Action:TimerRemoveEdict(Handle:timer, any:Edict)
{	
	if(IsValidEdict(EntRefToEntIndex(Edict)))
		RemoveEdict(EntRefToEntIndex(Edict));
}

public Action:TimerStopFireworks(Handle:timer, any:data)
{	
	IsEnd = false;
}

