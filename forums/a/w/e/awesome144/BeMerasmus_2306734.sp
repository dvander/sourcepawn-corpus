/*
-----------------------CREDITS TO:-----------------------
	[TF2] Temp. Be the Merasmus! --- Starman4xz
https://forums.alliedmods.net/showthread.php?t=199578

	[ANY] WiLdTuRkEy's Clusterbomb Plugin --- wildturkey
https://forums.alliedmods.net/showthread.php?t=194963

	[TF2] Horsemann Healthbar - 1.3.2, Updated 2012-08-16 --- Powerlord
https://forums.alliedmods.net/showthread.php?t=188543

	[TF2] Have Some Piss! (Jarate!) --- DarthNinja
http://forums.alliedmods.net/showthread.php?t=135519

	For Some Particle Effects --- FoxMulder
https://forums.alliedmods.net/showpost.php?p=1234966&postcount=2
*/

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
	
#define PLUGIN_VERSION	"2.1"
#define MERASMUS		"models/bots/merasmus/merasmus.mdl"
#define BOMBMODEL		"models/props_lakeside_event/bomb_temp.mdl"
#define DOOM1			"vo/halloween_merasmus/sf12_appears04.mp3"
#define DOOM2			"vo/halloween_merasmus/sf12_appears09.mp3"
#define DOOM3			"vo/halloween_merasmus/sf12_appears01.mp3"
#define DOOM4			"vo/halloween_merasmus/sf12_appears08.mp3"

#define DEATH1			"vo/halloween_merasmus/sf12_defeated01.mp3"
#define DEATH2			"vo/halloween_merasmus/sf12_defeated06.mp3"
#define DEATH3			"vo/halloween_merasmus/sf12_defeated08.mp3"

#define HELLFIRE		"vo/halloween_merasmus/sf12_ranged_attack04.mp3"
#define HELLFIRE2		"vo/halloween_merasmus/sf12_ranged_attack05.mp3"
#define HELLFIRE3		"vo/halloween_merasmus/sf12_ranged_attack06.mp3"
#define HELLFIRE4		"vo/halloween_merasmus/sf12_ranged_attack07.mp3"
#define HELLFIRE5		"vo/halloween_merasmus/sf12_ranged_attack08.mp3"

#define BOMB			"vo/halloween_merasmus/sf12_bombinomicon03.mp3"
#define BOMB2			"vo/halloween_merasmus/sf12_bombinomicon09.mp3"
#define BOMB3			"vo/halloween_merasmus/sf12_bombinomicon11.mp3"
#define BOMB4			"vo/halloween_merasmus/sf12_bombinomicon14.mp3"

#define BOMBTHROW		"vo/halloween_merasmus/sf12_grenades03.mp3"
#define BOMBTHROW2		"vo/halloween_merasmus/sf12_grenades04.mp3"
#define BOMBTHROW3		"vo/halloween_merasmus/sf12_grenades05.mp3"
#define BOMBTHROW4		"vo/halloween_merasmus/sf12_grenades06.mp3"

#define LEAVE			"vo/halloween_merasmus/sf12_leaving11.mp3"
#define LEAVE2			"vo/halloween_merasmus/sf12_leaving03.mp3"
#define LEAVE3			"vo/halloween_merasmus/sf12_leaving04.mp3"
#define LEAVE4			"vo/halloween_merasmus/sf12_leaving05.mp3"

#define LOL			"vo/halloween_merasmus/sf12_combat_idle01.mp3"
#define LOL2			"vo/halloween_merasmus/sf12_combat_idle02.mp3"
#define IN_ATTACK3		(1 << 25)
#define COLLISION_GROUP_DEBRIS_TRIGGER 2
#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
/*
new Float:telepoint[5][3]={{ 0.0, 0.0, 30.0 },
							{ -60.0, 650.0, 30.0 },
							{ 60.0, 650.0, 30.0 },
							{ -120.0, 650.0, 30.0 },
							{ 120.0, 650.0, 30.0 }};
*/
new Handle:kv;
new Float:telepoint[5][3];
new String:telepointName[5][40];
new teleportEnabled = false;
new g_HealthEntity = -1;
new g_healthBar = -1;
new bool:MerasmusHealthBar = false;
new Handle:c_Bar = INVALID_HANDLE;
new bool:MerasmusAlive[MAXPLAYERS+1];
new bool:IsTaunting[MAXPLAYERS+1];
new bool:IsMerasmus[MAXPLAYERS+1];
new MerasmusTelepoint[MAXPLAYERS+1] = 0;
new Handle:c_Health = INVALID_HANDLE;
new g_health = 7500;
new ParticleIndex[MAXPLAYERS+1];
new g_iOldTeam[MAXPLAYERS+1] = {0, ...};

public Plugin:myinfo =
{
	name = "[TF2]Be Merasmus!",
	author = "Mitch",
	description = "Be Merasmus!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_bemerasmus_version", PLUGIN_VERSION, "Be Merasmus Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	c_Health = CreateConVar("sm_merasmus_hp", "7500", "Sets the health the player playing Merasmus will have");
	c_Bar = CreateConVar("sm_merasmus_bar", "0", " Use HealthBar for Merasmus?");
	HookConVarChange(c_Health, OnCVARSChanged);
	HookConVarChange(c_Bar, OnCVARSChanged);
	RegAdminCmd("sm_bemerasmus", Command_Merasmus, ADMFLAG_ROOT);
	RegAdminCmd("sm_meras", Command_Merasmus, ADMFLAG_ROOT);
	//RegAdminCmd("sm_killhealthbar", Command_khb, ADMFLAG_KICK);
	//RegAdminCmd("sm_testskin", Command_testskin, ADMFLAG_KICK);
	RegConsoleCmd("sm_merasmus_menu", Command_MerasmusMenu);
	//RegAdminCmd("sm_state", Command_state, ADMFLAG_CHANGEMAP);
	HookEvent("player_death", Event_Death, EventHookMode_Post);
	HookEvent("player_death", Event_DeathPre, EventHookMode_Pre);
	HookEvent("post_inventory_application", Event_RedoModel, EventHookMode_Post);
}
////
////PLUGIN SETUP
////
public OnMapStart()
{
	PrecacheModel(MERASMUS, true);
	PrecacheModel(BOMBMODEL, true);
	
	PrecacheSound(DOOM1, true);
	PrecacheSound(DOOM2, true);
	PrecacheSound(DOOM3, true);
	PrecacheSound(DOOM4, true);
	
	PrecacheSound(DEATH1, true);
	PrecacheSound(DEATH2, true);
	PrecacheSound(DEATH3, true);

	PrecacheSound(HELLFIRE, true);
	PrecacheSound(HELLFIRE2, true);
	PrecacheSound(HELLFIRE3, true);
	PrecacheSound(HELLFIRE4, true);
	PrecacheSound(HELLFIRE5, true);
	
	PrecacheSound(BOMB, true);
	PrecacheSound(BOMB2, true);
	PrecacheSound(BOMB3, true);
	PrecacheSound(BOMB4, true);
	
	PrecacheSound(BOMBTHROW, true);
	PrecacheSound(BOMBTHROW2, true);
	PrecacheSound(BOMBTHROW3, true);
	PrecacheSound(BOMBTHROW4, true);

	PrecacheSound(LEAVE, true);
	PrecacheSound(LEAVE2, true);
	PrecacheSound(LEAVE3, true);
	PrecacheSound(LEAVE4, true);
	
	PrecacheSound(LOL, true);
	PrecacheSound(LOL2, true);
	
	FindHealthBar();
}
public OnConfigsExecuted() 
{
	kv = CreateKeyValues("merasmus");
	decl String:file[512];
	GetCurrentMap(file, sizeof(file));
	BuildPath(Path_SM, file, sizeof(file), "configs/BeMerasmus/%s.cfg", file);
	if(FileExists(file, false))
	{
		FileToKeyValues(kv, file);
		teleportEnabled = true;
		BuildTelepoints();
		BuildTelepointsNames();
	}
	else
	{
		PrintToServer("[SM] BeMerasmus unable to find config file: \"%s\"", file);
		LogMessage("BeMerasmus unable to find config file: \"%s\"", file);
	}
}
BuildTelepoints()
{
	if (!KvJumpToKey(kv, "Telepoints")) return;
	if (!KvGotoFirstSubKey(kv, false)) return;
	decl String:key[10];
	decl String:value[64];
	new String:floatstrings[3][8];
	new i = 0;
	do
	{
		KvGetSectionName(kv, key, sizeof(key));
		KvGetString(kv, NULL_STRING, value, sizeof(value));
		ExplodeString(value, ",", floatstrings, 3, 8, false);
		telepoint[i][0] = StringToFloat(floatstrings[0]);
		telepoint[i][1] = StringToFloat(floatstrings[1]);
		telepoint[i][2] = StringToFloat(floatstrings[2]);
		i++;
	} while (KvGotoNextKey(kv, false) && i<5);

	KvRewind(kv);
}
BuildTelepointsNames()
{
	if (!KvJumpToKey(kv, "TelepointsNames")) return;
	if (!KvGotoFirstSubKey(kv, false)) return;
	decl String:key[10];
	decl String:value[64];
	new i = 0;
	do
	{
		KvGetSectionName(kv, key, sizeof(key));
		KvGetString(kv, NULL_STRING, value, sizeof(value));
		strcopy(telepointName[StringToInt(key)], 40, value);
		i++;
	} while (KvGotoNextKey(kv, false) && i<5);

	KvRewind(kv);
}
public OnCVARSChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == c_Bar)
	{
		new Val = StringToInt(newVal);
		if(Val == 1)
		{
			MerasmusHealthBar = true;
		}
		else
		{
			MerasmusHealthBar = false;
		}
	}
	if(cvar == c_Health)
	{
		new Val = StringToInt(newVal);
		g_health = Val;
	}
}
////
////ENDPLUGINSETUP
////
////
////CLIENT STUFF
////
public OnClientDisconnect(client)
{
	if(MerasmusAlive[client])
	{
		if (IsValidEntity(g_healthBar) && g_healthBar != -1)
		{
			AcceptEntityInput(g_healthBar, "Kill");	
		}
		SDKUnhook(g_HealthEntity, SDKHook_OnTakeDamage, OnMerasmusDamaged);
		g_HealthEntity = -1;
		MerasmusAlive[client] = false;
		IsMerasmus[client] = false;
		RemoveMerasmus(client);
		RemoveParticle(client);
		if(IsClientInGame(client))
		{
			MerasmusLeave(client);
		}
	}
}
////
////ENDCLIENTSTUFF
////
////
////COMMANDS
////
/*
public Action:Command_khb(client, args)
{
	if(IsValidEntity(g_healthBar) && g_healthBar != -1)
	{
		AcceptEntityInput(g_healthBar, "Kill");
		ReplyToCommand(client, "Health Bar Is Killed");
	}
	return Plugin_Handled;
}*/
/*
public Action:Command_state(client, args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		SetEntProp(g_healthBar, Prop_Send, "m_iBossState", StringToInt(arg1));
	}
	return Plugin_Handled;
}*/
public Action:Command_Merasmus(client, args)
{
	if(args == 1)
	{
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new Target = FindTarget(client, arg1, false, true);
		if(Target != 0 && IsValidClient(Target) && !IsMerasmus[Target])
		{
			g_iOldTeam[Target] = GetClientTeam(Target);
			ReplyToCommand(client, "[SM]Made %N Merasmus!", Target);
			BuildMerasmus(Target);
		}
		else 
		{
			ReplyToCommand(client, "[SM] Invalid Target");
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] sm_bemerasmus <Player>");
	}
	return Plugin_Handled;
}
public Action:Command_MerasmusMenu(client, args) 
{
	if (IsValidClient(client) && MerasmusAlive[client] == true && IsTaunting[client] != true)
	{
		new Handle:merasmenu = CreateMenu(MerasMenuCallback);
		SetMenuTitle(merasmenu, "Merasmus Actions:");
		if(teleportEnabled)
				AddMenuItem(merasmenu, "teleport", "Teleports...");
		else
				AddMenuItem(merasmenu, "teleport", "Teleports...", ITEMDRAW_DISABLED);
		AddMenuItem(merasmenu, "leave", "Leave");
		AddMenuItem(merasmenu, "lol", "Lol");
		AddMenuItem(merasmenu, "...", "tba...", ITEMDRAW_DISABLED);
		DisplayMenu(merasmenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		ReplyToCommand(client, "[SM]You need to be Merasmus to use this command");
	}
	return Plugin_Handled;
}
////
////ENDCOMMANDS
////
////
////MERASMUS STUFF
////
public Action:unfreeze(Handle:timer, any:client)
{
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
}
public Action:BuildMerasmus(client)
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(Float:1.0, CreateMeras, client);
		CreateTimer(Float:2.0, unfreeze, client);
	}
}
public Action:CreateMeras(Handle:timer, any:client)
{
	SetModel(client, MERASMUS);
	SpawnSound();
	BuildParticle(client, "merasmus_ambient_body");
	MerasmusAlive[client] = true;
	IsMerasmus[client] = true;
	BuildClub(client);
	
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	
	SetEntProp(client, Prop_Data, "m_iHealth", g_health);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", g_health);
	SetEntProp(client, Prop_Send, "m_iTeamNum", 0);
	new Handle:spawnevent = CreateEvent("merasmus_summoned", true);
	FireEvent(spawnevent, false);
	TimedParticle(client, "merasmus_spawn", Float:3.0);
	
	///
	///HEALTHBAR
	///
	g_HealthEntity = client;
	SDKHook(g_HealthEntity, SDKHook_OnTakeDamage, OnMerasmusDamaged);
	if(MerasmusHealthBar)
	{
		FindHealthBar();
		UpdateBossHealth(g_HealthEntity);
	}
	///
	////HEALTHBAR
	///
}
public RemoveMerasmus(client)
{
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_iTeamNum", g_iOldTeam[client]);
}
public Action:SetModel(client, const String:model[])
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);		
	}
}
public MerasmusLeave(client)
{
	LeaveSound();
	MerasmusAlive[client] = false;
	IsMerasmus[client] = false;
	RemoveMerasmus(client);
	RemoveParticle(client);
	new Handle:leaveevent = CreateEvent("merasmus_escaped", true);
	FireEvent(leaveevent, false);

	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		new Float:pos[3], Float:ang[3];
		decl String:ClientModel[256];
		
		Format(ClientModel, sizeof(ClientModel), "models/bots/merasmus/merasmus.mdl");
		GetClientAbsOrigin(client, pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, ang);
		
		ang[0] = 0.0;
		ang[2] = 0.0;
	
		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", "leave");	
		DispatchKeyValueVector(Model, "angles", ang);
		
		DispatchSpawn(Model);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");	
	}
	SlapPlayer(client, g_health+g_health, false);
	UpdateBossHealth(client);
	SDKUnhook(g_HealthEntity, SDKHook_OnTakeDamage, OnMerasmusDamaged);
	g_HealthEntity = -1;
}
////
////ENDMERASMUS STUFF
////
////
////EVENTS
////
public Event_DeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[20];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	if(IsMerasmus[client])
	{
		if(StrEqual(weapon, "club", false))
		{
			SetEventString(event, "weapon", "merasmus_decap");
			SetEventString(event, "weapon_logclassname", "merasmus_decap");
		}
		else if(StrEqual(weapon, "flamethrower", false))
		{
			SetEventString(event, "weapon", "merasmus_zap");
			SetEventString(event, "weapon_logclassname", "merasmus_zap");
		}
		else if(StrEqual(weapon, "env_explosion", false))
		{
			SetEventString(event, "weapon", "merasmus_grenade");
			SetEventString(event, "weapon_logclassname", "merasmus_grenade");
		}
	}
}	

public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && MerasmusAlive[client] == true)
	{
		if(MerasmusHealthBar)
		{
			UpdateBossHealth(g_HealthEntity);
			
		}
		SDKUnhook(g_HealthEntity, SDKHook_OnTakeDamage, OnMerasmusDamaged);
		g_HealthEntity = -1;
		DeathSounds();
		MerasmusAlive[client] = false;
		IsMerasmus[client] = false;
		RemoveMerasmus(client);
		RemoveParticle(client);
		new Handle:deathevent = CreateEvent("merasmus_killed", true);
		FireEvent(deathevent, false);

		new Model = CreateEntityByName("prop_dynamic");
		if (IsValidEdict(Model))
		{
			new Float:pos[3], Float:ang[3];
			decl String:ClientModel[256];
			
			Format(ClientModel, sizeof(ClientModel), "models/bots/merasmus/merasmus.mdl");
			GetClientAbsOrigin(client, pos);
			TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
			GetClientEyeAngles(client, ang);
			
			ang[0] = 0.0;
			ang[2] = 0.0;
			DispatchKeyValue(Model, "model", ClientModel);
			DispatchKeyValue(Model, "DefaultAnim", "death");	
			DispatchKeyValueVector(Model, "angles", ang);
			
			DispatchSpawn(Model);
			
			SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
			AcceptEntityInput(Model, "AddOutput");
		}
		TimedParticle(client, "merasmus_spawn", Float:7.0);
	}
}

public Action:Event_RedoModel(Handle:event, const String:name[], bool:dontBroadcast)
{
	new merasmus = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsMerasmus[merasmus] == true){
	SetModel(merasmus, MERASMUS);
	BuildClub(merasmus);}
	return Plugin_Continue;
}
////
////ENDEVENTS
////
////
////MENU
////
public MerasMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:act[20];
		GetMenuItem(menu, param2, act, sizeof(act));
		if(StrEqual(act, "teleport"))
		{
			new Handle:telemenu = CreateMenu(TeleMenuCallback);
			SetMenuTitle(telemenu, "Select Dest:");
			AddMenuItem(telemenu, "dest0", telepointName[0]);
			AddMenuItem(telemenu, "dest1", telepointName[1]);
			AddMenuItem(telemenu, "dest2", telepointName[2]);
			AddMenuItem(telemenu, "dest3", telepointName[3]);
			AddMenuItem(telemenu, "dest4", telepointName[4]);
			DisplayMenu(telemenu, client, MENU_TIME_FOREVER);
		}
		if(StrEqual(act, "leave") && IsTaunting[client] != true)
		{
			MerasmusLeave(client);
		}
		if(StrEqual(act, "lol"))
		{
			new soundswitch;
			soundswitch = GetRandomInt(1, 2);	
			switch(soundswitch)
			{
				case 1:
				{
				EmitSoundToAll(LOL);
				}
				case 2:
				{
				EmitSoundToAll(LOL2);
				}
			}
		}
	}
	//IsTaunting[client] = false;
	//CloseHandle(menu);
}

public TeleMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:act[20];
		GetMenuItem(menu, param2, act, sizeof(act));
		if(GetEntityFlags(client) & FL_ONGROUND)
		{	
			if(StrEqual(act, "dest0"))
			{
				MerasmusTelepoint[client] = 0;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest1"))
			{
				MerasmusTelepoint[client] = 1;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest2"))
			{
				MerasmusTelepoint[client] = 2;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest3"))
			{
				MerasmusTelepoint[client] = 3;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest4"))
			{
				MerasmusTelepoint[client] = 4;
				TeleOut(client);
			}
		}
	}
	CloseHandle(menu);
}
////
////ENDMENU
////
////
////ATTACKS
////
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsMerasmus[client] == true)
	{
		if(IsPlayerAlive(client))
		{
			TF2_AddCondition(client, TFCond:TFCond_Healing, Float:0.2);
		}
	}
	if(GetEntityFlags(client) & FL_ONGROUND)
	{	
		if(buttons & IN_ATTACK2 && MerasmusAlive[client] == true && IsTaunting[client] != true && IsMerasmus[client] == true)
		{ 
			//
			//
			//DO ZAP
			//
			//
			TF2_StunPlayer(client, Float:3.0, Float:1.0, TF_STUNFLAGS_LOSERSTATE);
			MakePlayerInvisible(client, 0);
			
			
			new Model = CreateEntityByName("prop_dynamic");
			if (IsValidEdict(Model))
			{
				IsTaunting[client] = true;
				new Float:pos[3], Float:ang[3];
				decl String:ClientModel[256];
				
				GetClientModel(client, ClientModel, sizeof(ClientModel));
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
				GetClientEyeAngles(client, ang);
				ang[0] = 0.0;
				ang[2] = 0.0;

				DispatchKeyValue(Model, "model", ClientModel);
				DispatchKeyValue(Model, "DefaultAnim", "zap_attack");	
				DispatchKeyValueVector(Model, "angles", ang);
				
				DispatchSpawn(Model);
				
				SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
				AcceptEntityInput(Model, "AddOutput");
				
				CreateTimer(Float:1.0, DoHellfire, client);
				SetEntityMoveType(client, MOVETYPE_NONE);
				PlayHellfire();
				
				CreateTimer(Float:2.8, ResetTaunt, client);
			}
		}
		else if(buttons & IN_DUCK && buttons & IN_ATTACK && MerasmusAlive[client] == true && IsTaunting[client] != true && IsMerasmus[client] == true)
		{
			//
			//
			//DO TELEPORT
			//
			//
			/*
			TF2_StunPlayer(client, Float:2.0, Float:1.0, TF_STUNFLAGS_LOSERSTATE);
			MakePlayerInvisible(client, 0);
			
			
			new Model = CreateEntityByName("prop_dynamic");
			if (IsValidEdict(Model))
			{
				IsTaunting[client] = true;
				new Float:pos[3], Float:ang[3];
				decl String:ClientModel[256], String:Skin[2];
				
				GetClientModel(client, ClientModel, sizeof(ClientModel));
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
				TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
				GetClientEyeAngles(client, ang);
				ang[0] = 0.0;
				ang[2] = 0.0;
				IntToString(g_skin, Skin, sizeof(Skin));
				
				DispatchKeyValue(Model, "skin", Skin);
				DispatchKeyValue(Model, "model", ClientModel);
				DispatchKeyValue(Model, "DefaultAnim", "teleport_out");	
				DispatchKeyValueVector(Model, "angles", ang);
				
				DispatchSpawn(Model);
				
				SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
				AcceptEntityInput(Model, "AddOutput");
				
				SetEntityMoveType(client, MOVETYPE_NONE);
				CreateTimer(Float:1.1, TeleIn, client);
				TimedParticle(client, "merasmus_tp", Float:1.5);
			}*/
		}
		else if(buttons & IN_RELOAD && MerasmusAlive[client] == true && IsTaunting[client] != true && IsMerasmus[client] == true)
		{
			//
			//
			//DO BOOK
			//
			//
			MakePlayerInvisible(client, 0);
			
			new Model = CreateEntityByName("prop_dynamic");
			if (IsValidEdict(Model))
			{
				IsTaunting[client] = true;
				new Float:posc[3], Float:ang[3];
				decl String:ClientModel[256];
				
				GetClientModel(client, ClientModel, sizeof(ClientModel));
				GetEntPropVector(client, Prop_Send, "m_vecOrigin", posc);
				TeleportEntity(Model, posc, NULL_VECTOR, NULL_VECTOR);
				GetClientEyeAngles(client, ang);
				ang[0] = 0.0;
				ang[2] = 0.0;

				DispatchKeyValue(Model, "model", ClientModel);
				DispatchKeyValue(Model, "DefaultAnim", "bomb_attack");	
				DispatchKeyValueVector(Model, "angles", ang);
				
				DispatchSpawn(Model);
				
				SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
				AcceptEntityInput(Model, "AddOutput");
				
				SetEntityMoveType(client, MOVETYPE_NONE);
				Playbombsound();
				CreateTimer(Float:3.0, StartBombAttack, client);
			
			}
		}
		else if(buttons & IN_ATTACK3 && MerasmusAlive[client] == true && IsTaunting[client] != true && IsMerasmus[client] == true)
		{
			//
			//
			//DO ADDBOMBS
			//
			//
			//IsTaunting[client] = true;
			if(GetPlayerWeaponSlot(client, 1) == -1)
			{
				BuildJarate(client);
			}
			SetJarAmmo(client, 50);
			//CreateTimer(Float:0.75, BombThrow, client);
			//buttons |= IN_ATTACK;
		}
	}
	else
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public Action:DoHellfire(Handle:timer, any:client)
{
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		new Float:pos[3];
		GetClientEyePosition(i, pos);
		
		new Float:distance = GetVectorDistance(vec, pos);
		
		new Float:dist = 400.0;
		
				
		if(distance < dist)
		{
			if (i == client) continue;
		
			new Float:vecc[3];
			
			vecc[0] = 0.0;
			vecc[1] = 0.0;
			vecc[2] = 1500.0;
			AttachParticle(client, "merasmus_zap", i);
			TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vecc);
			TF2_IgnitePlayer(i, client);
			
		}
	}
}
public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "tf_projectile_jar", true))
	{
		SDKHook(entity, SDKHook_SpawnPost, BombThrow);
	}
}
public BombThrow(entity)
{
	new parent = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if(IsMerasmus[parent])
	{
		Playbombthrowsound();
		decl Float:pos[3];
		decl Float:vec[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		decl Float:ang[3];
		GetClientEyeAngles(parent, ang);
		new Float:tempvec[3]
		GetAngleVectors(ang, tempvec, NULL_VECTOR, NULL_VECTOR)
		ScaleVector(tempvec, 20.0)
		AddVectors(pos, tempvec, pos)
		
		new ent2 = CreateEntityByName("prop_physics_override");
		AcceptEntityInput(entity, "Kill");
		if(ent2 != -1)
		{					
			DispatchKeyValue(ent2, "model", BOMBMODEL);
			DispatchKeyValue(ent2, "solid", "6");
			DispatchKeyValue(ent2, "renderfx", "0");
			DispatchKeyValue(ent2, "rendercolor", "255 255 255");
			DispatchKeyValue(ent2, "renderamt", "255");
			SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", parent);
			DispatchSpawn(ent2);
			GetAngleVectors(ang, vec, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vec, 2000.0);

			TeleportEntity(ent2, pos, ang, vec);
		
			CreateTimer((GetURandomFloat() + 0.1) / 1.75 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE);
		}
		
	}
	
}
public Action:StartBombAttack(Handle:timer, any:client)
{
	new Handle:BTime = CreateTimer(Float:2.0, CreateBomb, client, TIMER_REPEAT);
	CreateTimer(Float:11.75, ResetTaunt, client);
	CreateTimer(Float:11.0, KillBombs, BTime);
	TimedParticle(client, "merasmus_book_attack", Float:11.0)
}
public Action:CreateBomb(Handle:timer, any:client)
{
	if(MerasmusAlive[client])
	{
		SpawnClusters(client);
	}
}
public Action:KillBombs(Handle:timer, any:Btimer)
{
	KillTimer(Btimer);
}
public SpawnClusters(ent)
{
	if (IsValidEntity(ent))
	{
		new Float:bombSpreadVel = 50.0;
		new Float:bombVertVel = 90.0;
		new bombVariation = 2;
		
		new Float:pos[3];
		GetClientEyePosition(ent, pos);
		pos[2] += 105.0;
			
		decl Float:ang[3];
		
		for (new i = 0; i < 11; i++)
		{
			ang[0] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation);
			ang[1] = ((GetURandomFloat() + 0.1) * bombSpreadVel - bombSpreadVel / 2.0) * ((GetURandomFloat() + 0.1) * bombVariation);
			ang[2] = ((GetURandomFloat() + 0.1) * bombVertVel) * ((GetURandomFloat() + 0.1) * bombVariation);

			new ent2 = CreateEntityByName("prop_physics_override");

			if(ent2 != -1)
			{					
				DispatchKeyValue(ent2, "model", BOMBMODEL);
				DispatchKeyValue(ent2, "solid", "6");
				DispatchKeyValue(ent2, "renderfx", "0");
				DispatchKeyValue(ent2, "rendercolor", "255 255 255");
				DispatchKeyValue(ent2, "renderamt", "255");
				SetEntPropEnt(ent2, Prop_Data, "m_hOwnerEntity", ent);
				DispatchSpawn(ent2);
				TeleportEntity(ent2, pos, NULL_VECTOR, ang);

				CreateTimer((GetURandomFloat() + 0.1) / 1.75 + 0.5, ExplodeBomblet, ent2, TIMER_FLAG_NO_MAPCHANGE);
			}			
		}
	}
}
public Action:ExplodeBomblet(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		decl Float:pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 32.0;

		new client = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		new team = GetEntProp(client, Prop_Send, "m_iTeamNum");

		AcceptEntityInput(ent, "Kill");
		new BombMagnitude = 120;
		new explosion = CreateEntityByName("env_explosion");
		if (explosion != -1)
		{
			decl String:tMag[8];
			IntToString(BombMagnitude, tMag, sizeof(tMag));
			DispatchKeyValue(explosion, "iMagnitude", tMag);
			DispatchKeyValue(explosion, "spawnflags", "0");
			DispatchKeyValue(explosion, "rendermode", "5");
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);
			DispatchSpawn(explosion);
			ActivateEntity(explosion);

			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "Kill");
		}		
	}
}
public TeleOut(client)
{
	TF2_StunPlayer(client, Float:2.0, Float:1.0, TF_STUNFLAGS_LOSERSTATE);
	MakePlayerInvisible(client, 0);
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		IsTaunting[client] = true;
		new Float:pos[3], Float:ang[3];
		decl String:ClientModel[256];
		
		GetClientModel(client, ClientModel, sizeof(ClientModel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[2] = 0.0;

		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", "teleport_out");	
		DispatchKeyValueVector(Model, "angles", ang);
		
		DispatchSpawn(Model);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(Float:1.1, TeleIn, client);
		TimedParticle(client, "merasmus_tp", Float:1.5);
	}
}	
public Action:TeleIn(Handle:timer, any:client)
{
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		IsTaunting[client] = true;
		new Float:ang[3];
		decl String:ClientModel[256];
		GetClientModel(client, ClientModel, sizeof(ClientModel));
		TeleportEntity(Model, telepoint[MerasmusTelepoint[client]], NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(client, telepoint[MerasmusTelepoint[client]], NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[2] = 0.0;

		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", "teleport_in");	
		DispatchKeyValueVector(Model, "angles", ang);
		
		DispatchSpawn(Model);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(Float:1.5, ResetTaunt, client);
		TimedParticle(client, "merasmus_tp", Float:1.5);
	}
}
////
////ENDATTACKS
////
////
////PARTICLES/STOCKS
////
public Action:ResetTaunt(Handle:timer, any:client)
{
	IsTaunting[client] = false;
	MakePlayerInvisible(client, 255);
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
}
stock MakePlayerInvisible(client, alpha)
{
	SetWeaponsAlpha(client, alpha);
	SetWearablesAlpha(client, alpha);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (client, alpha){
	decl String:classname[64];
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	for(new i = 0, weapon; i < 189; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		if(weapon > -1 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}
stock SetWearablesAlpha (client, alpha)
{
	if(IsPlayerAlive(client))
	{
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable_item_demoshield")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos); 
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
	}
}
public BuildParticle(client, const String:path[32])
{
	new TParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(TParticle))
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(TParticle, "effect_name", path);
		
		DispatchKeyValue(TParticle, "targetname", "particle");
		
		SetVariantString("!activator");
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0);
		
		SetVariantString("effect_robe");
		AcceptEntityInput(TParticle, "SetParentAttachment", TParticle, TParticle, 0);
		
		DispatchSpawn(TParticle);
		ActivateEntity(TParticle);
		AcceptEntityInput(TParticle, "Start");
		
		ParticleIndex[client] = TParticle;
	}
}
AttachParticle(ent, String:particleType[], controlpoint)
{
	new particle  = CreateEntityByName("info_particle_system");
	new particle2 = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{ 
		new String:tName[128];
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		new String:cpName[128];
		Format(cpName, sizeof(cpName), "target%i", controlpoint);
		DispatchKeyValue(controlpoint, "targetname", cpName);

		//--------------------------------------
		new String:cp2Name[128];
		Format(cp2Name, sizeof(cp2Name), "tf2particle%i", controlpoint);

		DispatchKeyValue(particle2, "targetname", cp2Name);
		DispatchKeyValue(particle2, "parentname", cpName);

		SetVariantString(cpName);
		AcceptEntityInput(particle2, "SetParent");

		SetVariantString("flag");
		AcceptEntityInput(particle2, "SetParentAttachment");
		//-----------------------------------------------


		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchKeyValue(particle, "cpoint1", cp2Name);

		DispatchSpawn(particle);

		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent");

		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment");

		//The particle is finally ready
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(Float:1.5, KPart, particle);
		CreateTimer(Float:1.5, KPart, particle2);
	}
}
public Action:KPart(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Kill");
	}
}
public RemoveParticle(client)
{
	if (IsValidEntity(ParticleIndex[client]))
	{
		AcceptEntityInput(ParticleIndex[client], "Kill");
	}	
}
stock bool:IsValidClient(client) 
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
public TimedParticle(client, const String:path[32], Float:FTime)
{
	new TParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(TParticle))
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(TParticle, "effect_name", path);
		
		DispatchKeyValue(TParticle, "targetname", "particle");
		
		SetVariantString("!activator");
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0);
		
		DispatchSpawn(TParticle);
		ActivateEntity(TParticle);
		AcceptEntityInput(TParticle, "Start");
		CreateTimer(FTime, KillTParticle, TParticle);
		
	}
}
public Action:KillTParticle(Handle:timer, any:index)
{
	if (IsValidEntity(index))
	{
		AcceptEntityInput(index, "Kill");
	}
}
////
////ENDPARTICLES/STOCKS
////
////
////WEAPONS
////
public Action:BuildClub(client)
{
	TF2_RemoveAllWeapons(client);
	
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_club");
		TF2Items_SetItemIndex(hWeapon, 3);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		TF2Items_SetNumAttributes(hWeapon, 10); // Atrib Number Total
		
		TF2Items_SetAttribute(hWeapon, 0, 2, 30.0);
		TF2Items_SetAttribute(hWeapon, 1, 4, 91.0);
		TF2Items_SetAttribute(hWeapon, 3, 5, 0.75);
		TF2Items_SetAttribute(hWeapon, 4, 110, 250.0);
		TF2Items_SetAttribute(hWeapon, 5, 26, 250.0);
		TF2Items_SetAttribute(hWeapon, 6, 31, 10.0);
		TF2Items_SetAttribute(hWeapon, 7, 107, 3.0);
		TF2Items_SetAttribute(hWeapon, 8, 97, 0.4);
		TF2Items_SetAttribute(hWeapon, 9, 134, 4.0);
		
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		EquipPlayerWeapon(client, weapon);

		CloseHandle(hWeapon);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", 0);
		BuildJarate(client);
	}
}
public Action:BuildJarate(client)
{

	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if (hWeapon != INVALID_HANDLE)
	{
		TF2Items_SetClassname(hWeapon, "tf_weapon_jar");
		TF2Items_SetItemIndex(hWeapon, 58);
		TF2Items_SetLevel(hWeapon, 100);
		TF2Items_SetQuality(hWeapon, 5);
		TF2Items_SetNumAttributes(hWeapon, 1); // Atrib Number Total
		
		TF2Items_SetAttribute(hWeapon, 0, 134, 4.0);
		
		new weapon = TF2Items_GiveNamedItem(client, hWeapon);
		SetJarAmmo(client, 50);
		EquipPlayerWeapon(client, weapon);
		CloseHandle(hWeapon);
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", 0);
	}
}
stock SetJarAmmo(client, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 58)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
		}
	}
}
////
////ENDWEAPONS
////
////
////SOUNDS
////
public SpawnSound()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 4);	
	switch(soundswitch)
	{
		case 1:
		{
			EmitSoundToAll(DOOM1);
		}
		case 2:
		{
			EmitSoundToAll(DOOM2);
		}
		case 3:
		{
			EmitSoundToAll(DOOM3);
		}
		case 4:
		{
			EmitSoundToAll(DOOM4);
		}
	}
}
public PlayHellfire()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 5);
	
	switch(soundswitch)
	{
		case 1:
		{
			EmitSoundToAll(HELLFIRE);
		}
		case 2:
		{
			EmitSoundToAll(HELLFIRE2);
		}
		case 3:
		{
			EmitSoundToAll(HELLFIRE3);
		}
		case 4:
		{
			EmitSoundToAll(HELLFIRE4);
		}
		case 5:
		{
			EmitSoundToAll(HELLFIRE5);
		}
	}
}
public Playbombsound()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 4);	
	switch(soundswitch)
	{
		case 1:
		{
			EmitSoundToAll(BOMB);
		}
		case 2:
		{
			EmitSoundToAll(BOMB2);
		}
		case 3:
		{
			EmitSoundToAll(BOMB3);
		}
		case 4:
		{
			EmitSoundToAll(BOMB4);
		}
	}
}
public Playbombthrowsound()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 8);	
	switch(soundswitch)
	{
		case 2:
		{
			EmitSoundToAll(BOMBTHROW);
		}
		case 4:
		{
			EmitSoundToAll(BOMBTHROW2);
		}
		case 6:
		{
			EmitSoundToAll(BOMBTHROW3);
		}
		case 8:
		{
			EmitSoundToAll(BOMBTHROW4);
		}
	}
}
public LeaveSound()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 4);	
	switch(soundswitch)
	{
		case 1:
		{
			EmitSoundToAll(LEAVE);
		}
		case 2:
		{
			EmitSoundToAll(LEAVE2);
		}
		case 3:
		{
			EmitSoundToAll(LEAVE3);
		}
		case 4:
		{
			EmitSoundToAll(LEAVE4);
		}
	}
}
public DeathSounds()
{
	new soundswitch;
	soundswitch = GetRandomInt(1, 3);
	switch(soundswitch)
	{
		case 1:
		{
			EmitSoundToAll(DEATH1);
		}
		case 2:
		{
			EmitSoundToAll(DEATH2);
		}
		case 3:
		{
			EmitSoundToAll(DEATH3);
		}
	}
}
////
////ENDSOUNDS
////
////
////HEALTHBAR
////
public Action:OnMerasmusDamaged(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(IsValidClient(victim) && IsValidClient(attacker))
	{
		if (weapon == GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage > 1000.0)	//lousy way of checking backstabs
		{
			decl String:wepclassname[32];
			if (GetEdictClassname(weapon, wepclassname, sizeof(wepclassname)) && strcmp(wepclassname, "tf_weapon_knife", false) == 0)	//more robust knife check
			{
				damage = 0.0;
				return Plugin_Changed;
			}
		}
		if(MerasmusHealthBar)
		{
			UpdateBossHealth(victim);
		}
	}
	return Plugin_Continue;
}
public UpdateBossHealth(entity)
{
	new percentage;
	if (IsValidEntity(entity) && IsMerasmus[entity])
	{
		new iMaxHealth = GetEntProp(entity, Prop_Data, "m_iMaxHealth");
		new iHealth = GetEntProp(entity, Prop_Data, "m_iHealth");
		
		if (iMaxHealth <= 0)
		{
			percentage = 0;
		}
		else
		{
			percentage = RoundToCeil(float(iHealth) / iMaxHealth * HEALTHBAR_MAX);
		}
	}
	else
	{
		percentage = 0;
	}
	
	SetEntProp(g_healthBar, Prop_Send, HEALTHBAR_PROPERTY, percentage);
}

FindHealthBar()
{
	g_healthBar = FindEntityByClassname(-1, HEALTHBAR_CLASS);
	
	if (g_healthBar == -1)
	{
		g_healthBar = CreateEntityByName(HEALTHBAR_CLASS);
		if (g_healthBar != -1)
		{
			DispatchSpawn(g_healthBar);
		}
	}
}
////
////ENDHEALTHBAR
////
