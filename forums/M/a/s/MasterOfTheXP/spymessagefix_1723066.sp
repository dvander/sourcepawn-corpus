#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "1.1.0"
#define PL_NAME "TF2 Spy Radio Message Fix"

#define TF2_PLAYER_DISGUISED	(1 << 3)
#define TF2_PLAYER_CLOAKED      (1 << 4)

#define CLASS_SCOUT				1
#define CLASS_SNIPER			2
#define CLASS_SOLDIER			3
#define CLASS_DEMOMAN			4
#define CLASS_MEDIC				5
#define CLASS_HEAVY				6
#define CLASS_PYRO				7
#define CLASS_SPY				8
#define CLASS_ENGINEER			9

new String:Spy_CloackedIdentify[9][10][64];

public Plugin:myinfo = 
{
	name = PL_NAME,
	author = "Flyflo",
	description = "Fix the spy detection radio message broken by changing color/alpha/Etc...",
	version = PL_VERSION,
	url = "http://www.geek-gaming.fr/"
}

stock bool:TF2_IsPlayerDisguised(client)
{
	if(client > 0)
	{
		new pcond = TF2_GetPlayerCond(client);
		return pcond >= 0 ? ((pcond & TF2_PLAYER_DISGUISED) != 0) : false;
	}
	return false;
}

stock bool:TF2_IsPlayerCloaked(client)
{
	if(client > 0)
	{
		new pcond = TF2_GetPlayerCond(client);
		return pcond >= 0 ? ((pcond & TF2_PLAYER_CLOAKED) != 0) : false;
	}
	return false;
}

stock TF2_GetPlayerCond(client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

stock TF2_ClassToInt(TFClassType:PlayerClass)
{
	switch(PlayerClass)
	{
		case TFClass_Unknown:
			return 0;
		case TFClass_Scout:
			return CLASS_SCOUT;
		case TFClass_Sniper:
			return CLASS_SNIPER;
		case TFClass_Soldier:
			return CLASS_SOLDIER;
		case TFClass_DemoMan:
			return CLASS_DEMOMAN;
		case TFClass_Medic:
			return CLASS_MEDIC;
		case TFClass_Heavy:
			return CLASS_HEAVY;
		case TFClass_Pyro:
			return CLASS_PYRO;
		case TFClass_Spy:
			return CLASS_SPY;
		case TFClass_Engineer:
			return CLASS_ENGINEER;
	}
	return 0;
}
public OnPluginStart()
{
	AddNormalSoundHook(BlockingSounds);
	CreateConVar("sm_spyradiofix_version", PL_VERSION, PL_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//SCOUT
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_SCOUT-1] = "vo/scout_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_SNIPER-1] = "vo/scout_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_SOLDIER-1] = "vo/scout_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_DEMOMAN-1] = "vo/scout_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_MEDIC-1] = "vo/scout_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_HEAVY-1] = "vo/scout_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_PYRO-1] = "vo/scout_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_SPY-1] = "vo/scout_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][CLASS_ENGINEER-1] = "vo/scout_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_SCOUT-1][9] = "";

	//SNIPER
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_SCOUT-1] = "vo/sniper_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_SNIPER-1] = "vo/sniper_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_SOLDIER-1] = "vo/sniper_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_DEMOMAN-1] = "vo/sniper_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_MEDIC-1] = "vo/sniper_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_HEAVY-1] = "vo/sniper_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_PYRO-1] = "vo/sniper_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_SPY-1] = "vo/sniper_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][CLASS_ENGINEER-1] = "vo/sniper_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_SNIPER-1][9] = "";
	
	//SOLDIER
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_SCOUT-1] = "vo/soldier_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_SNIPER-1] = "vo/soldier_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_SOLDIER-1] = "vo/soldier_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_DEMOMAN-1] = "vo/soldier_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_MEDIC-1] = "vo/soldier_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_HEAVY-1] = "vo/soldier_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_PYRO-1] = "vo/soldier_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_SPY-1] = "vo/soldier_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][CLASS_ENGINEER-1] = "vo/soldier_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_SOLDIER-1][9] = "";

	//DEMOMAN
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_SCOUT-1] = "vo/demoman_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_SNIPER-1] = "vo/demoman_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_SOLDIER-1] = "vo/demoman_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_DEMOMAN-1] = "vo/demoman_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_MEDIC-1] = "vo/demoman_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_HEAVY-1] = "vo/demoman_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_PYRO-1] = "vo/demoman_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_SPY-1] = "vo/demoman_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][CLASS_ENGINEER-1] = "vo/demoman_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_DEMOMAN-1][9] = "";

	//MEDIC
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_SCOUT-1] = "vo/medic_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_SNIPER-1] = "vo/medic_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_SOLDIER-1] = "vo/medic_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_DEMOMAN-1] = "vo/medic_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_MEDIC-1] = "vo/medic_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_HEAVY-1] = "vo/medic_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_PYRO-1] = "vo/medic_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_SPY-1] = "vo/medic_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][CLASS_ENGINEER-1] = "vo/medic_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_MEDIC-1][9] = "";
	
	//HEAVY
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_SCOUT-1] = "vo/heavy_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_SNIPER-1] = "vo/heavy_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_SOLDIER-1] = "vo/heavy_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_DEMOMAN-1] = "vo/heavy_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_MEDIC-1] = "vo/heavy_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_HEAVY-1] = "vo/heavy_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_PYRO-1] = "vo/heavy_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_SPY-1] = "vo/heavy_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][CLASS_ENGINEER-1] = "vo/heavy_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_HEAVY-1][9] = "";

	//PYRO
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_SCOUT-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_SNIPER-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_SOLDIER-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_DEMOMAN-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_MEDIC-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_HEAVY-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_PYRO-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_SPY-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][CLASS_ENGINEER-1] = "vo/pyro_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_PYRO-1][9] = "";

	//SPY
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_SCOUT-1] = "vo/spy_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_SNIPER-1] = "vo/spy_cloakedspyidentify10.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_SOLDIER-1] = "vo/spy_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_DEMOMAN-1] = "vo/spy_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_MEDIC-1] = "vo/spy_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_HEAVY-1] = "vo/spy_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_PYRO-1] = "vo/spy_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_SPY-1] = "vo/spy_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][CLASS_ENGINEER-1] = "vo/spy_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_SPY-1][9] = "vo/spy_cloakedspyidentify07.wav";

	//ENGINEER
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_SCOUT-1] = "vo/engineer_cloakedspyidentify01.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_SNIPER-1] = "vo/engineer_cloakedspyidentify09.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_SOLDIER-1] = "vo/engineer_cloakedspyidentify02.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_DEMOMAN-1] = "vo/engineer_cloakedspyidentify05.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_MEDIC-1] = "vo/engineer_cloakedspyidentify07.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_HEAVY-1] = "vo/engineer_cloakedspyidentify03.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_PYRO-1] = "vo/engineer_cloakedspyidentify04.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_SPY-1] = "vo/engineer_cloakedspyidentify06.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][CLASS_ENGINEER-1] = "vo/engineer_cloakedspyidentify08.wav";
	Spy_CloackedIdentify[CLASS_ENGINEER-1][9] = "vo/engineer_cloakedspyidentify10.wav";
}

public OnMapStart()
{
	for(new i = 0; i < 9; i++)
	{
		for(new j = 0; j < 10; j++)
		{
			if(strcmp(Spy_CloackedIdentify[i][j], "") != 0)
			{
				PrecacheSound(Spy_CloackedIdentify[i][j], true);
			}
		}
	}
}

public Action:BlockingSounds(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrContains(sample,"CloakedSpy") != -1 && clients[0] == 1)
	{
		decl String:edictName[32];
		GetEdictClassname(entity, edictName, sizeof(edictName));
		
		if(StrEqual(edictName, "player") && !InvalidClient(entity))
		{
			new iTarget = GetClientAimTarget(entity);
				
			if(iTarget != -1 && !TF2_IsPlayerCloaked(iTarget))
			{
				new TFClassType:PlayerClass = TF2_GetPlayerClass(entity);
				new TFClassType:TargetClass = TF2_GetPlayerClass(iTarget);
				
				new iClientTeam = GetClientTeam(entity);
				new iTargetTeam = GetClientTeam(iTarget);
				
				new iFromClass = TF2_ClassToInt(PlayerClass);
				new iToClass = TF2_ClassToInt(TargetClass);
				
				if(TF2_IsPlayerDisguised(entity))
				{
					iFromClass = GetEntProp(entity, Prop_Send, "m_nDisguiseClass");
				}
				
				if(TF2_IsPlayerDisguised(iTarget) && iClientTeam != iTargetTeam)
				{
					iToClass = GetEntProp(iTarget, Prop_Send, "m_nDisguiseClass");
				}
				if((iFromClass == CLASS_ENGINEER || iFromClass == CLASS_SPY) && iToClass == CLASS_SPY)
				{
					new ArrayIndex = (GetRandomInt(4, 5)*2) - 1;
					Format(sample, PLATFORM_MAX_PATH, Spy_CloackedIdentify[iFromClass - 1][ArrayIndex]);
					return Plugin_Changed;
				}
				else
				{
					Format(sample, PLATFORM_MAX_PATH, Spy_CloackedIdentify[iFromClass - 1][iToClass - 1], entity);
					return Plugin_Changed;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public bool:InvalidClient(client)
{
	if(client < 1)
	{
		return true;
	}
	
	if(!IsClientConnected(client))
	{
		return true;
	}
	
	if(!IsClientInGame(client))
	{
		return true;
	}
	
	if(IsFakeClient(client))
	{
		return true;
	}
	
	return false;
}