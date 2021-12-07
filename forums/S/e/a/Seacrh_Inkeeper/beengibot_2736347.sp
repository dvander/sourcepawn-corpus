#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>

#define TF_OBJECT_TELEPORTER	1
#define TF_TELEPORTER_ENTR	0

bool engibotactive;
bool teleportercheck;
bool AnnouncerQuiet;

int EngieTeam = 2;
int engieid = -1;
int g_iMaxEntities;
int BossTeleporter;

bool isfromtele[MAXPLAYERS];

#define SCOUT_ROBOT					"models/bots/scout/bot_scout.mdl"
#define SOLDIER_ROBOT				"models/bots/soldier/bot_soldier.mdl"
#define PYRO_ROBOT					"models/bots/pyro/bot_pyro.mdl"
#define DEMOMAN_ROBOT				"models/bots/demo/bot_demo.mdl"
#define HEAVY_ROBOT					"models/bots/heavy/bot_heavy.mdl"
#define MEDIC_ROBOT					"models/bots/medic/bot_medic.mdl"
#define	SPY_ROBOT					"models/bots/spy/bot_spy.mdl"
#define ENGINEER_ROBOT				"models/bots/engineer/bot_engineer.mdl"
#define SNIPER_ROBOT				"models/bots/sniper/bot_sniper.mdl"

#define ENGIE_SPAWN_SOUND		"vo/announcer_mvm_engbot_arrive02.mp3"
#define ENGIE_SPAWN_SOUND2		"vo/announcer_mvm_engbot_arrive03.mp3"

#define TELEPORTER_ACTIVATE1	"vo/announcer_mvm_eng_tele_activated01.mp3"
#define TELEPORTER_ACTIVATE2	"vo/announcer_mvm_eng_tele_activated02.mp3"
#define TELEPORTER_ACTIVATE3	"vo/announcer_mvm_eng_tele_activated03.mp3"
#define TELEPORTER_ACTIVATE4	"vo/announcer_mvm_eng_tele_activated04.mp3"
#define TELEPORTER_ACTIVATE5	"vo/announcer_mvm_eng_tele_activated05.mp3"

#define TELEPORTER_SPAWN		"mvm/mvm_tele_deliver.wav"

#define PLUGIN_VERSION "1.1"

public Plugin beengibot =
{
  name = "Be EngiBot REX",
  author = "Ordinary Made by Benoist3012, Rebuilt & Powered By Увеселитель",
  description = "Become EngiBot from MvM!",
  version = PLUGIN_VERSION,
  url = "https://forums.alliedmods.net/showthread.php?p=2736347"
}

public OnPluginStart()
{
	CreateConVar("sm_beengibot_rex_version", PLUGIN_VERSION,
	"The version of the Be EngiBot plugin.", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	RegAdminCmd("sm_beengibot", BeEngibot, ADMFLAG_BAN, "[SM] Usage: sm_beengibot <target>");	
	
	HookEvent("teamplay_round_active", OnRoundPrepare);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_class", OnPlayerChangeClass);
	
	AddCommandListener(CommandListener_Build, "build");
	AddNormalSoundHook(SoundHook);
	g_iMaxEntities = GetMaxEntities();	
}
public OnMapStart()
{
	engibotactive = false;
	engieid = -1;
	
	PrecacheModel(SCOUT_ROBOT, true);
	PrecacheModel(SOLDIER_ROBOT, true);
	PrecacheModel(PYRO_ROBOT, true);
	PrecacheModel(DEMOMAN_ROBOT, true);
	PrecacheModel(HEAVY_ROBOT, true);
	PrecacheModel(MEDIC_ROBOT, true);
	PrecacheModel(SPY_ROBOT, true);
	PrecacheModel(ENGINEER_ROBOT, true);
	PrecacheModel(SNIPER_ROBOT, true);
	PrecacheSound(ENGIE_SPAWN_SOUND, true);
	PrecacheSound(ENGIE_SPAWN_SOUND2, true);
	PrecacheSound(TELEPORTER_ACTIVATE1, true);
	PrecacheSound(TELEPORTER_ACTIVATE2, true);
	PrecacheSound(TELEPORTER_ACTIVATE3, true);
	PrecacheSound(TELEPORTER_ACTIVATE4, true);
	PrecacheSound(TELEPORTER_ACTIVATE5, true);
	PrecacheSound(TELEPORTER_SPAWN, true);
}

public void OnRoundPrepare(Event event, const char[] name, bool dontBroadcast)
{
	engieid = -1;
	engibotactive = false;
	teleportercheck = false;
	AnnouncerQuiet = false;
	BossTeleporter = -1;	
	
	for (int client = 1; client < MaxClients; client++)
	{
		isfromtele[client] = false;
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	engibotactive = false;
	teleportercheck = false;
	AnnouncerQuiet = false;
	BossTeleporter = -1;
	engieid = -1;
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{	
	if (engibotactive)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client == engieid)
		{
			engibotactive = false;
			teleportercheck = false;
			AnnouncerQuiet = false;
			BossTeleporter = -1;	
			engieid = -1;
			DestroyBuildings(client);
		}
		isfromtele[client] = false;
	}
}
public void OnPlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	if (engibotactive)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		/*if (TF2_GetPlayerClass(client) == TFClass_Engineer && GetClientTeam(client) == EngieTeam && client != engieid)
		{
			TF2_SetPlayerClass(client, TFClass_Pyro);
			TF2_RegeneratePlayer(client);
		}*/
		if (client == engieid)
		{
			TF2_SetPlayerClass(client, TFClass_Engineer);
		}
	}
}

public Action BeEngibot(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[REX] Нет аргумента!");
		return Plugin_Handled;
	}
	if (engibotactive)
	{
		ReplyToCommand(client, "[REX] Инженер уже призван!");
		return Plugin_Handled;
	}

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int	 aTrgList[MAXPLAYERS];
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if((ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0)
	{	
		ReplyToCommand(client, "[REX] Target doesn't exist!");
		return Plugin_Handled;
	}	
	int target = aTrgList[0];	
	Engie(target);
	return Plugin_Handled;
}

Engie(int target)
{		
	engibotactive = true;
	engieid = target;
	
	float uberduration = 10.0;
	char attributes[64]= "26 ; 275; 124; 1; 200; 1; 64; 0.5";	
	//int health = 600;	
	
	int ii = target;
	if(ii != -1)
	{		
		EngieTeam = GetClientTeam(ii);
		DestroyBuildings(ii);		
		
		if (TF2_GetPlayerClass(ii) != TFClass_Engineer) TF2_SetPlayerClass(ii, TFClass_Engineer);		
		if (!IsPlayerAlive(ii)) TF2_RespawnPlayer(ii);
		else TF2_RegeneratePlayer(ii);
		
		
		SetVariantString(ENGINEER_ROBOT);
		AcceptEntityInput(ii, "SetCustomModel");
		SetEntProp(ii, Prop_Send, "m_bUseClassAnimations", 1);
		TF2_RemoveAllWeapons(ii);
		TF2_AddCondition(ii, TFCond_UberchargedCanteen, uberduration);
		if(attributes[0]=='\0')
		{
			attributes="68 ; -1";
		}

		SpawnWeapon(ii, "tf_weapon_shotgun_primary", 199, 101, 0, "");
		SpawnWeapon(ii, "tf_weapon_pistol", 209, 101, 0, "");
		int weapon = SpawnWeapon(ii, "tf_weapon_robot_arm", 142, 101, 0, attributes);
		SetEntPropEnt(ii, Prop_Send, "m_hActiveWeapon", weapon);
		
		TF2Items_GiveWeapon(ii, 737);
		TF2Items_GiveWeapon(ii, 26);    
		TF2Items_GiveWeapon(ii, 28);
				
		//SetEntProp(ii, Prop_Send, "m_iMaxHealth", health);
		//SetEntProp(ii, Prop_Data, "m_iHealth", health);
		//SetEntProp(ii, Prop_Send, "m_iHealth", health);
		
		float position[3];
		GetEntPropVector(ii, Prop_Data, "m_vecOrigin", position);		
		
		int attach = CreateEntityByName("trigger_push");
		CreateTimer(10.0, DeleteTrigger, attach);
		TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);
		TE_Particle("teleported_mvm_bot", position, _, _, attach, 1,0);
		
		int soundswitch = GetRandomInt(1, 2);
		switch(soundswitch)
		{
			case 1:
			{
				EmitSoundToAll(ENGIE_SPAWN_SOUND);
			}
			case 2:
			{
				EmitSoundToAll(ENGIE_SPAWN_SOUND2);
			}
		}
		
		//Fake teleporter
		CreateTimer(0.4, Particle_Teleporter);
		CreateTimer(0.8, CheckTeleporter);
		CreateTimer(1.2, SpawnDeadPlayer);
	}
}

public Action CheckTeleporter(Handle Timer)
{
	if(engibotactive)
	{
		CreateTimer(0.5, CheckTeleporter);
		int TeleporterExit = -1;	
		if((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1 && GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == EngieTeam && GetEntPropEnt(TeleporterExit, Prop_Send, "m_hBuilder") == engieid)
		{
			char modelname[128];
			GetEntPropString(TeleporterExit, Prop_Data, "m_ModelName", modelname, 128);
			if(StrContains(modelname, "light") != -1)
			{
				teleportercheck = true;
				BossTeleporter = TeleporterExit;
			}
			else
			{
				teleportercheck = false;
				BossTeleporter = -1;
			}
		}
		else
		{
			AnnouncerQuiet = false;
			if(teleportercheck)
			{
				teleportercheck = false;
			}
		}
	}
}
public Action Particle_Teleporter(Handle Timer)
{
	if(engibotactive)
	{
		CreateTimer(3.0, Particle_Teleporter);
		int TeleporterExit = -1;	
		if((TeleporterExit = FindEntityByClassname(TeleporterExit,"obj_teleporter")) != -1)
		{
			if(GetEntProp(TeleporterExit, Prop_Send, "m_iTeamNum") == EngieTeam && GetEntPropEnt(TeleporterExit, Prop_Send, "m_hBuilder") == engieid)
			{
				char modelname[128];
				GetEntPropString(TeleporterExit, Prop_Data, "m_ModelName", modelname, 128);
				if(StrContains(modelname, "light") != -1)
				{
					float position[3];
					GetEntPropVector(TeleporterExit,Prop_Send, "m_vecOrigin",position);
					int attach = CreateEntityByName("trigger_push");
					CreateTimer(3.0, DeleteTrigger, attach);
					TeleportEntity(attach, position, NULL_VECTOR, NULL_VECTOR);
					AttachParticle(attach,"teleporter_mvm_bot_persist");
					if (EngieTeam == 3)
					{
						AttachParticle(attach,"teleporter_blue_floorglow");
						AttachParticle(attach,"teleporter_blue_entrance_disc");
						AttachParticle(attach,"teleporter_blue_exit_level3");
						AttachParticle(attach,"teleporter_blue_charged_wisps");
						AttachParticle(attach,"teleporter_blue_charged");
					}
					else if (EngieTeam == 2)
					{
						AttachParticle(attach,"teleporter_red_floorglow");
						AttachParticle(attach,"teleporter_red_entrance_disc");
						AttachParticle(attach,"teleporter_red_exit_level3");
						AttachParticle(attach,"teleporter_red_charged_wisps");
						AttachParticle(attach,"teleporter_red_charged");
					}
					if(!AnnouncerQuiet)
					{
						int soundswitch = GetRandomInt(1, 5);
						switch(soundswitch)
						{
							case 1:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE1);
							}
							case 2:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE2);
							}
							case 3:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE3);
							}
							case 4:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE4);
							}
							case 5:
							{
								EmitSoundToAll(TELEPORTER_ACTIVATE5);
							}
						}
						AnnouncerQuiet = true;
					}
				}
			}
		}
	}
}
public Action SpawnDeadPlayer(Handle Timer)
{
	if(engibotactive)
	{
		CreateTimer(1.0, SpawnDeadPlayer);
	}
	int random = GetRandomInt(1, 100);
	switch(random)
	{
		case 1,25,31,48,54,68,71,87,57,35,97,24,58,16,19:
		{
			if(teleportercheck && engibotactive)
			{
				SpawnRobot();
			}
		}
	}
}
SpawnRobot()
{
	int ii = GetRandomDeadPlayer();
	int playerinBossTeam = GetTeamPlayerCount(EngieTeam);
	if(ii != -1 && playerinBossTeam < 5)
	{
		if (TF2_GetPlayerClass(ii) == TFClass_Engineer)	TF2_SetPlayerClass(ii, TFClass_Medic);		

		ChangeClientTeam(ii,EngieTeam);	
		TF2_RespawnPlayer(ii);
		
		EmitSoundToAll(TELEPORTER_SPAWN);
		
		TF2_AddCondition(ii, TFCond:TFCond_UberchargedCanteen, 3.0);
		
		float position[3];
		GetEntPropVector(BossTeleporter,Prop_Send, "m_vecOrigin",position);
		position[2] += 20;
		TeleportEntity(ii, position, NULL_VECTOR, NULL_VECTOR);
		
		DefaultWeapons (ii);
		
		CreateTimer(0.1, Timer_SetRobotModel, ii, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		isfromtele[ii] = true;
	}
}

DefaultWeapons (int ii)
{
	TF2_RemoveAllWeapons(ii);

	switch(TF2_GetPlayerClass(ii))
	{
		case TFClass_Scout: 
		{
			SpawnWeapons(ii, "tf_weapon_scattergun", 13);
			SpawnWeapons(ii, "tf_weapon_pistol", 23);
			SpawnWeapons(ii, "tf_weapon_bat", 0);
		}
		case TFClass_Soldier: 
		{
			SpawnWeapons(ii, "tf_weapon_rocketlauncher", 18);
			SpawnWeapons(ii, "tf_weapon_shotgun_soldier", 10);
			SpawnWeapons(ii, "tf_weapon_shovel", 6);
		}
		case TFClass_Pyro: 
		{
			SpawnWeapons(ii, "tf_weapon_flamethrower", 21);
			SpawnWeapons(ii, "tf_weapon_shotgun_pyro", 12);
			SpawnWeapons(ii, "tf_weapon_fireaxe", 2);
		}
		case TFClass_DemoMan: 
		{
			SpawnWeapons(ii, "tf_weapon_grenadelauncher", 19);
			SpawnWeapons(ii, "tf_weapon_pipebomblauncher", 20);
			SpawnWeapons(ii, "tf_weapon_bottle", 1);
		}
		case TFClass_Heavy: 
		{
			SpawnWeapons(ii, "tf_weapon_minigun", 15);
			SpawnWeapons(ii, "tf_weapon_shotgun_hwg", 11);
			SpawnWeapons(ii, "tf_weapon_fists", 5);
		}
		case TFClass_Engineer: 
		{
			SpawnWeapons(ii, "tf_weapon_shotgun_primary", 9);
			SpawnWeapons(ii, "tf_weapon_pistol", 22);
			SpawnWeapons(ii, "tf_weapon_wrench", 7);
			SpawnWeapons(ii, "tf_weapon_pda_engineer_build", 25);
			SpawnWeapons(ii, "tf_weapon_pda_engineer_destroy", 26);
			int weapon = SpawnWeapons(ii, "tf_weapon_builder", 28);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
		}
		case TFClass_Medic: 
		{
			SpawnWeapons(ii, "tf_weapon_syringegun_medic", 17);
			SpawnWeapons(ii, "tf_weapon_medigun", 29);
			SpawnWeapons(ii, "tf_weapon_bonesaw", 8);
		}
		case TFClass_Sniper: 
		{
			SpawnWeapons(ii, "tf_weapon_sniperrifle", 14);
			SpawnWeapons(ii, "tf_weapon_smg", 16);
			SpawnWeapons(ii, "tf_weapon_club", 3);
		}
		case TFClass_Spy: 
		{
			SpawnWeapons(ii, "tf_weapon_revolver", 24);
			int weapon = SpawnWeapons(ii, "tf_weapon_builder", 735);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
			SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
			SpawnWeapons(ii, "tf_weapon_knife", 4);
			SpawnWeapons(ii, "tf_weapon_pda_spy", 27);
			SpawnWeapons(ii, "tf_weapon_invis", 30);
		}
	}	
}

stock int SpawnWeapons(int client, char[] name, int index)
{
	Handle weapon = TF2Items_CreateItem(PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);		
	TF2Items_SetAttribute(weapon, 0, 15, 1.0);		
	TF2Items_SetNumAttributes(weapon, 1);

	if (weapon == INVALID_HANDLE)
	{
		PrintToServer("[REX] Error: Invalid weapon spawned. client=%d name=%s idx=%d", client, name, index);
		return -1;
	}
	else
	{
		int entity = TF2Items_GiveNamedItem(client, weapon);
		delete weapon;	

		EquipPlayerWeapon(client, entity);

		return entity;
	}					

}

public Action CommandListener_Build(client, const char[] command, argc)
{
	char sObjectMode[256], sObjectType[256];
	GetCmdArg(1, sObjectType, sizeof(sObjectType));
	GetCmdArg(2, sObjectMode, sizeof(sObjectMode));
	int iObjectMode = StringToInt(sObjectMode);
	int iObjectType = StringToInt(sObjectType);
	char sClassName[32];
	for(int i = MaxClients + 1; i < g_iMaxEntities; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		GetEntityNetClass(i, sClassName, sizeof(sClassName));
		if(engibotactive && iObjectType == TF_OBJECT_TELEPORTER && iObjectMode == TF_TELEPORTER_ENTR && client == engieid)
		{
			PrintCenterText(client,"You can't build enter teleporter, you can only build a exit teleporter!");
			PrintToChat(client,"You can't build enter teleporter, you can only build a exit teleporter!");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock SpawnWeapon(client, char[] name, index, level, quality, char[] attribute)
{
	Handle weapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}
	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	int entity = TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}
stock AttachParticle(entity, char[] particleType, float offset[]={0.0,0.0,0.0}, bool attach=true)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[0]+=offset[0];
	position[1]+=offset[1];
	position[2]+=offset[2];
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	CreateTimer(3.0, DeleteParticle, particle);
	return particle;
}
public Action DeleteParticle(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "info_particle_system", false)) AcceptEntityInput(Ent, "Kill");
	return;
}
public Action DeleteTrigger(Handle timer, any Ent)
{
	if (!IsValidEntity(Ent)) return;
	char cls[25];
	GetEdictClassname(Ent, cls, sizeof(cls));
	if (StrEqual(cls, "trigger_push", false)) AcceptEntityInput(Ent, "Kill");
	return;
}
public Action Timer_SetRobotModel(Handle Timer, any iClient)
{
	if(!engibotactive)
		return Plugin_Stop;
	if(!IsPlayerAlive(iClient))
		return Plugin_Handled;
	
	if(TF2_IsPlayerInCondition(iClient, TFCond_Taunting) || TF2_IsPlayerInCondition(iClient, TFCond_Dazed))
		return Plugin_Handled;
	
	TFClassType iClass = TF2_GetPlayerClass(iClient);
	char strModel[PLATFORM_MAX_PATH];
	switch(iClass)
	{
		case TFClass_Scout: strcopy( strModel, sizeof(strModel), "scout");
		case TFClass_Sniper: strcopy( strModel, sizeof(strModel), "sniper");
		case TFClass_Soldier: strcopy( strModel, sizeof(strModel), "soldier");
		case TFClass_DemoMan: strcopy( strModel, sizeof(strModel), "demo");
		case TFClass_Medic: strcopy( strModel, sizeof(strModel), "medic");
		case TFClass_Heavy: strcopy( strModel, sizeof(strModel), "heavy");
		case TFClass_Pyro: strcopy( strModel, sizeof(strModel), "pyro");
		case TFClass_Spy:
		{
			strcopy( strModel, sizeof(strModel), "spy");
			SetEntityHealth(iClient, 125);
		}
		case TFClass_Engineer: strcopy( strModel, sizeof(strModel), "engineer");
	}
	if( strlen(strModel) > 0 )
	{
		Format(strModel, sizeof(strModel), "models/bots/%s/bot_%s.mdl", strModel, strModel);
		SetRobotModel(iClient, strModel);
	}	
	return Plugin_Stop;
}
stock SetRobotModel(iClient, const String:strModel[PLATFORM_MAX_PATH] = "" )
{
	if(!engibotactive)
		return;
	
	if(strlen(strModel) > 2)
		PrecacheMdl(strModel);
	
	SetVariantString(strModel);
	AcceptEntityInput(iClient, "SetCustomModel");
	SetEntProp(iClient, Prop_Send, "m_bUseClassAnimations", 1);
}
stock PrecacheMdl( const String:strModel[PLATFORM_MAX_PATH], bool:bPreload = false )
{
	if( FileExists( strModel, true ) || FileExists( strModel, false ) )
		if( !IsModelPrecached( strModel ) )
			return PrecacheModel( strModel, bPreload );
	return -1;
}
stock TE_Particle(char[] Name, float origin[3] = NULL_VECTOR, float start[3] = NULL_VECTOR, float angles[3] = NULL_VECTOR, entindex=-1, attachtype=-1, attachpoint=-1, bool resetParticles=true, customcolors = 0, float color1[3] = NULL_VECTOR, float color2[3] = NULL_VECTOR, controlpoint = -1, controlpointattachment = -1, float controlpointoffset[3] = NULL_VECTOR)
{
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx == INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    float delay = 3.0;
    // find particle index
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    
    for (int i = 0; i < count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx == INVALID_STRING_INDEX)
    {
        LogError("Could not find particle: %s", Name);
        return;
    }

    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
    if (entindex !=- 1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype != -1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint != -1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    
    if(customcolors)
    {
        TE_WriteNum("m_bCustomColors", customcolors);
        TE_WriteVector("m_CustomColors.m_vecColor1", color1);
        if(customcolors == 2)
        {
            TE_WriteVector("m_CustomColors.m_vecColor2", color2);
        }
    }
    if(controlpoint != -1)
    {
        TE_WriteNum("m_bControlPoint1", controlpoint);
        if(controlpointattachment != -1)
        {
            TE_WriteNum("m_ControlPoint1.m_eParticleAttachment", controlpointattachment);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[0]", controlpointoffset[0]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[1]", controlpointoffset[1]);
            TE_WriteFloat("m_ControlPoint1.m_vecOffset[2]", controlpointoffset[2]);
        }
    }    
    TE_SendToAll(delay);
}
stock GetTeamPlayerCount(iTeamNum)
{
	int iCounter = 0;
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && GetClientTeam(i) == iTeamNum && IsPlayerAlive(i))	iCounter++;
	return iCounter;
}
stock DestroyBuildings(int client)
{
	decl String:strObjects[3][] = {"obj_sentrygun","obj_dispenser","obj_teleporter"};
	
	int owner = -1; 
	
	for(int o = 0; o < sizeof(strObjects); o++)
	{
		int iEnt = -1;
		while((iEnt = FindEntityByClassname(iEnt, strObjects[o])) != -1)
			if(IsValidEntity(iEnt) && GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == EngieTeam)
			{
				//owner = GetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity");
				owner = GetEntPropEnt(iEnt, Prop_Send, "m_hBuilder");				
				
				if (client == -1 || owner == client)
				{	
					//PrintToServer("[REX] Destroyed object %i, owner - %N", iEnt, owner);
					SetEntityHealth(iEnt, 100);
					SetVariantInt(1488);
					AcceptEntityInput(iEnt, "RemoveHealth");
				}
			}
	}
}
public Action SoundHook(clients[64], &numClients, char sound[PLATFORM_MAX_PATH], &Ent, &channel, float& volume, &level, &pitch, &flags)
{
	if (!engibotactive) return Plugin_Continue;
	if (volume == 0.0 || volume == 0.9997) return Plugin_Continue;
	if (!IsValidClient(Ent)) return Plugin_Continue;
	int client = Ent;
	
	if (GetClientTeam(client) == EngieTeam && (isfromtele[client] || client == engieid))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		if (StrContains(sound, "player/footsteps/", false) != -1 && class != TFClass_Medic)
		{
			int rand = GetRandomInt(1,18);
			Format(sound, sizeof(sound), "mvm/player/footsteps/robostep_%s%i.wav", (rand < 10) ? "0" : "", rand);
			pitch = GetRandomInt(95, 100);
			PrecacheSound(sound, false);
			EmitSoundToAll(sound, client, SNDCHAN_STATIC, 95, _, _, pitch);
			return Plugin_Changed;
		}
		if (StrContains(sound, "vo/", false) == -1) return Plugin_Continue;
		if (StrContains(sound, "announcer", false) != -1) return Plugin_Continue;
		if (StrContains(sound, "mvm", false) != -1) return Plugin_Continue;
		if (volume == 0.99997) return Plugin_Continue;
		ReplaceString(sound, sizeof(sound), "vo/", "vo/mvm/norm/", false);
		ReplaceString(sound, sizeof(sound), ".wav", ".mp3", false);
		char classname[10], classname_mvm[15];
		TF2_GetNameOfClass(class, classname, sizeof(classname));
		Format(classname_mvm, sizeof(classname_mvm), "%s_mvm", classname);
		ReplaceString(sound, sizeof(sound), classname, classname_mvm, false);
		char soundchk[PLATFORM_MAX_PATH];
		Format(soundchk, sizeof(soundchk), "sound/%s", sound);
		PrecacheSound(sound);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
stock TF2_GetNameOfClass(TFClassType class, char[] name, maxlen)
{
	switch (class)
	{
		case TFClass_Scout: Format(name, maxlen, "scout");
		case TFClass_Soldier: Format(name, maxlen, "soldier");
		case TFClass_Pyro: Format(name, maxlen, "pyro");
		case TFClass_DemoMan: Format(name, maxlen, "demoman");
		case TFClass_Heavy: Format(name, maxlen, "heavy");
		case TFClass_Engineer: Format(name, maxlen, "engineer");
		case TFClass_Medic: Format(name, maxlen, "medic");
		case TFClass_Sniper: Format(name, maxlen, "sniper");
		case TFClass_Spy: Format(name, maxlen, "spy");
	}
}
stock IsValidClient(client)
{
	//Check for client "ID"
	if  (client <= 0 || client > MaxClients) 
		return false;
	
	//Check for client is in game
	if (!IsClientInGame(client)) 
		return false;
	
	return true;
}
stock GetRandomDeadPlayer()
{
	int clients[MAXPLAYERS], clientCount;
	for(int i = 1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == EngieTeam))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}