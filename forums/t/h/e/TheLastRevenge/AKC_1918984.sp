/*
my english is very bad :(
i'm korean
Change Log
1.0.0
	(EN) Added setting the knife's knockback(separate:cut, stab) default : 0.0 0.0
	(KR) 칼의 넉백을 설정하는 기능이 추가되었습니다.(베기와 찍기) 기본값 : 0.0 0.0
	
	(EN) Added setting the knife's damage(separate:cut, stab) default : 20.0, 65.0
	(KR) 칼의 데미지를 설정하는 기능이 추가되었습니다.(베기와 찍기) 기본값 : 20.0 65.0
	
	(EN) Added setting the knife's all of sounds(only set 1 sound) default : default 1sound
	(KR) 칼의 모든 사운드를 설정할 수 있는 기능이 추가되었습니다.(오로지 한개만 설정 가능) 기본값 : 기본 사운드 1개
	
	(EN) Added setting the knife's model(separate:view, world) default : default skin
	(KR) 칼의 모델을 설정할 수 있는 기능이 추가되었습니다.(뷰와 월드) 기본값 : 기본 카솟 칼스킨
1.0.1
	(EN) Fixed sound was not precached
	(KR) 사운드가 프리캐싱 되지 않던 점을 수정했습니다.
	
	(EN) Deleted 'sendproxy' extension(not used)
	(KR) 'Sendproxy' 익스텐션을 제거하였습니다.(사용하지 않음)
1.1.0
	(EN) Added setting the knife's back stab damage default : 195
	(KR) 칼의 뒤에서 찍기(훚따기)의 데미지를 설정하는 기능이 추가되었습니다. 기본값 : 195
	
	(EN) Fixed world model with dropping weapon.
	(KR) 떨어져 있는 무기의 월드 모델을 고쳤습니다.
	
	(EN) Added setting the knife's delay(separate:cut, stab) default : 0.5 1.0
	(KR) 칼의 딜레이를 설정하는 기능이 추가되었습니다.(베기와 찍기) 기본값 : 0.5 1.0
1.1.1
	(EN) Fixed bug going spectate with alive.
	(KR) 살아있는채 관전자로 갈때 생기는 버그를 수정했습니다.
	
	(EN) Fixed bleeding if damage was zero.
	(KR) 데미지가 0일때 피를 흘리던것을 수정했습니다.
	
	(EN) Fixed no viewmodel after spawn
	(KR) 스폰 이후에 뷰모델이 나오지 않던 점을 수정했습니다.
1.1.2
	(EN) Fixed knocback for same team
	(KR) 같은팀에게 적용되는 넉백을 수정했습니다.
	
	(EN) Added setting the knife's back stab knockback default : 0.0
	(KR) 뒤에서 찍기의 넉백을 설정하는 기능이 추가되어었습니다. 기본값 : 0.0
2.0.0
	(EN) Re-fixed knockback for same team(Add ConVar)
	(KR) 같은팀에게 적용되는 넉백을 수정했습니다.(서버 ConVar 추가)
	
	(EN) Removed minimize and maximize in cfg
	(KR) 최소값, 최대값을 삭제했습니다.
	
	(EN) Added function that set viewmodel animation speed percent default : 100.0
	(KR) 뷰모델 애니메이션의 속도 퍼센트를 설정하는 기능이 추가됬습니다. 기본값 : 100.0
	
	(EN) Re-fixed no viewmodel with holding weapon(not knife) after spawn
	(KR) 스폰이후 들고있던 무기(칼 제외)의 뷰모델이 안보이던 점을 다시 수정했습니다.
	
	(EN) Added auto-updating cfg file
	(KR) cfg 파일 자동 업데이트 기능을 추가했습니다.
	
	(EN) Added setting the knife's hitmiss delay(separate:cut, stab) default : 0.4 0.985
	(KR) 칼의 헛스윙 딜레이를 설정하는 기능이 추가되었습니다.(베기와 찍기) 기본값 : 0.4 0.985
	
	(EN) Changed knife's stab delay 1.0 to 1.085
	(KR) 칼의 찍기 딜레이가 1.0초에서 1.085초로 변경되었습니다.
	
	(EN) Added swap each other reach(N)
	(KR) 리치(명사형)를 서로 바꾸는 기능을 추가했습니다.
	
	(EN) Added setting allowed to drop the knife
	(KR) 칼을 버리는걸 설정하는 기능을 추가했습니다.
	
	(EN) Changed ConVar version's name(DKC_Ver -> dynamic_knife_controller_version)
	(KR) ConVar 버전의 이름을 변경했습니다.(DKC_Ver -> dynamic_knife_controller_version)
2.0.1
	(EN) Changed Plugin's name DKC(Dynamic Knife Controller) to AKC(Advanced Knife Customizer)
	(KR) 플러그인의 이름을 변경했습니다. DKC(Dynamic Knife Controller) -> AKC(Advanced Knife Customizer)
	
	(EN) Changed ConVar version's name(dynamic_knife_controller_version -> advanced_knife_customizer_version)
	(KR) ConVar 버전의 이름을 변경했습니다.(dynamic_knife_controller_version -> advanced_knife_customizer_version)
	
	(EN) ConVar Descriptions were translated into Englsih.
	(KR) ConVar의 설명이 영어로 번역되었습니다.
2.0.2
	(EN) Fixed duplication config file
	(KR) 콘픽 파일이 중복 생성되는 버그를 수정했습니다.
	
	(EN) Added ConVar that support different mode(0 = everyone, 1 = only admin(specific flags), 2 = Terrorist, 3 = CT) if you used mode 1, you should use ConVar admin flag
	(KR) 다른 모드를 지원하는 콘바를 추가했습니다.(0 = 모두, 1 = 오로지 어드민(특정 플래그), 2 = 테러리스트, 3 = 대테러리스트) 만약 당신이 모드 1을 사용한다면, 당신은 admin flag 콘바를 사용해야한다.
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

/*Defines*/
#define PLUGIN_VERSION "2.0.2"
#define EF_NODRAW 32

/*ConVars*/
new Handle:CV_knockback_cut = INVALID_HANDLE;
new Handle:CV_knockback_stab = INVALID_HANDLE;
new Handle:CV_knockback_backstab = INVALID_HANDLE;
new Handle:CV_knockback_sameteam = INVALID_HANDLE;
new Handle:CV_damage_cut = INVALID_HANDLE;
new Handle:CV_damage_stab = INVALID_HANDLE;
new Handle:CV_damage_backstab = INVALID_HANDLE;
new Handle:CV_sound_deploy = INVALID_HANDLE;
new Handle:CV_sound_hitwall = INVALID_HANDLE;
new Handle:CV_sound_hitmiss = INVALID_HANDLE;
new Handle:CV_sound_cut = INVALID_HANDLE;
new Handle:CV_sound_stab = INVALID_HANDLE;
new Handle:CV_model_view = INVALID_HANDLE;
new Handle:CV_model_world = INVALID_HANDLE;
new Handle:CV_delay_cut = INVALID_HANDLE;
new Handle:CV_delay_cut_miss = INVALID_HANDLE;
new Handle:CV_delay_stab = INVALID_HANDLE;
new Handle:CV_delay_stab_miss = INVALID_HANDLE;
new Handle:CV_speed_viewmodel = INVALID_HANDLE;
new Handle:CV_swap_reach = INVALID_HANDLE
new Handle:CV_allow_drop = INVALID_HANDLE;
new Handle:CV_mode_apply = INVALID_HANDLE;
new Handle:CV_flags_admin = INVALID_HANDLE;

/*Variables*/
new entity_viewmodel[MAXPLAYERS+1][2];
new Process[MAXPLAYERS+1];
new bool:SpawnCheck[MAXPLAYERS+1];
new bool:IsCustom[MAXPLAYERS+1];

new PrecachedModel[2];//0 : view, 1 : world
new bool:ConfigLoaded;
new bool:VersionLoaded;

public Plugin:myinfo = 
{
	name = "Advanced Knife Customizer",
	author = "TheLastRevenge(복수)",//Steam ID : zorroes96(friend list is full)
	description = "Modification Knife",
	version = PLUGIN_VERSION,
	url = "http://cafe.naver.com/cssttt"
}

public OnPluginStart()
{
	AddCommandListener(DropCommand, "drop");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	AddNormalSoundHook(SoundCallBackHook);
	
	GetConfigVersion();
}

public OnMapStart()
{
	ConfigLoaded = false;
}

public Action:DropCommand(id, const String:command[], arg)
{
	if(GetConVarInt(CV_allow_drop))
	{
		new weapons = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
		if(IsPlayerAlive(id) && weapons > 0 && IsValidEdict(weapons))
		{
			new String:classname[32];
			GetEdictClassname(weapons, classname, sizeof(classname));
			if(StrEqual(classname, "weapon_knife"))
			{
				CS_DropWeapon(id, weapons, true, true);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//use to delay hiding viewmodel a frame or it won't work
	SpawnCheck[client] = true;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new mode = GetConVarInt(CV_mode_apply);
	if(mode > 1 && mode < 4)
	{
		SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip_CallBack);
		SDKUnhook(client, SDKHook_PostThink, OnPostThink);
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		//hide viewmodel
		new EntEffects = GetEntProp(entity_viewmodel[client][1], Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(entity_viewmodel[client][1], Prop_Send, "m_fEffects", EntEffects);
		if(mode == GetEventInt(event, "team"))
		{
			SDKHook(client, SDKHook_WeaponEquip, WeaponEquip_CallBack);
			SDKHook(client, SDKHook_PostThink, OnPostThink);
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
			IsCustom[client] = true;
		}
	}
}

public Action:SoundCallBackHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(ConfigLoaded)
	{
		new String:String_Sound[256];
		new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(Owner > 0 && Owner <= MaxClients && IsCustom[Owner])
		{
			if(StrEqual(sample, "weapons/knife/knife_hitwall1.wav"))
			{
				GetConVarString(CV_sound_hitwall, String_Sound, sizeof(String_Sound));
				EmitSoundToAll(String_Sound, Owner, channel, level, flags, volume);
				return Plugin_Handled;
			}
			else if(!StrContains(sample, "weapons/knife/knife_hit"))
			{
				GetConVarString(GetConVarInt(CV_swap_reach)?CV_sound_stab:CV_sound_cut, String_Sound, sizeof(String_Sound));
				EmitSoundToAll(String_Sound, Owner, channel, level, flags, volume);
				return Plugin_Handled;
			}
			if(!StrContains(sample, "weapons/knife/knife_slash"))
			{
				GetConVarString(CV_sound_hitmiss, String_Sound, sizeof(String_Sound));
				EmitSoundToAll(String_Sound, Owner, channel, level, flags, volume);
				return Plugin_Handled;
			}
			if(StrEqual(sample, "weapons/knife/knife_stab.wav"))
			{
				GetConVarString(GetConVarInt(CV_swap_reach)?CV_sound_cut:CV_sound_stab, String_Sound, sizeof(String_Sound));
				EmitSoundToAll(String_Sound, Owner, channel, level, flags, volume);
				return Plugin_Handled;
			}
			if(StrEqual(sample, "weapons/knife/knife_deploy1.wav"))
			{
				GetConVarString(CV_sound_deploy, String_Sound, sizeof(String_Sound));
				EmitSoundToAll(String_Sound, Owner, channel, level, flags, volume);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "predicted_viewmodel", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
	if(StrEqual(classname, "weapon_knife", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned2);
	}
}

//find both of the clients viewmodels
public OnEntitySpawned(entity)
{
	new Owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
	if(Owner > 0 && Owner <= MaxClients)
	{
		if(GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 0)
		{
			entity_viewmodel[Owner][0] = entity;
		}
		else if(GetEntProp(entity, Prop_Send, "m_nViewModelIndex") == 1)
		{
			entity_viewmodel[Owner][1] = entity;
		}
	}
}

public OnEntitySpawned2(entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_Think, WeaponThink);
	}
}

public OnEntitySpawned3(entity)
{
	if(IsValidEntity(entity))
	{
		SDKHook(entity, SDKHook_SetTransmit, SetTransmit_CallBack);
	}
}

public WeaponThink(entity)
{
	SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", PrecachedModel[1]);
}

public OnClientPutInServer(id)
{
	IsCustom[id] = false;
	new mode = GetConVarInt(CV_mode_apply);
	if(ConfigLoaded)
	{
		SDKHook(id, SDKHook_TraceAttack, OnTraceAttack);
		if(!mode)
		{
			SDKHook(id, SDKHook_WeaponEquip, WeaponEquip_CallBack);
			SDKHook(id, SDKHook_PostThink, OnPostThink);
			SDKHook(id, SDKHook_PostThinkPost, OnPostThinkPost);
			IsCustom[id] = true;
		}
		if(mode == 1)
		{
			CreateTimer(0.1, CheckAdmin, id);
		}
	}
}

public Action:CheckAdmin(Handle:timer, any:id)
{
	if(IsClientInGame(id))
	{
		new String:flags[32];
		GetConVarString(CV_flags_admin, flags, 32);
		new adminflags = ReadFlagString(flags);
		if(AdminFlagAccess(id, adminflags))
		{
			SDKHook(id, SDKHook_WeaponEquipPost, WeaponEquip_CallBack);
			SDKHook(id, SDKHook_PostThink, OnPostThink);
			SDKHook(id, SDKHook_PostThinkPost, OnPostThinkPost);
			IsCustom[id] = true;
		}
	}
}

public WeaponEquip_CallBack(id, weapons)
{
	if(IsValidEdict(weapons) && IsValidEntity(weapons))
	{
		decl String:classname[32];
		GetEdictClassname(weapons, classname, sizeof(classname));
		if(StrEqual(classname, "weapon_knife"))
		{
			SDKHook(weapons, SDKHook_SetTransmit, SetTransmit_CallBack);
		}
	}
}

public OnPostThink(id)
{
	new buttons = GetClientButtons(id);
	if(buttons & IN_ATTACK)
	{
		new WeaponIndex = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
		if(WeaponIndex <= 0) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(id, Prop_Send, "m_flNextAttack")) return;
		Process[id] = 0;
	}
	if(buttons & IN_ATTACK2)
	{
		new WeaponIndex = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
		if(WeaponIndex <= 0) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextPrimaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(WeaponIndex, Prop_Send, "m_flNextSecondaryAttack")) return;
		if(GetGameTime() < GetEntPropFloat(id, Prop_Send, "m_flNextAttack")) return;
		Process[id] = 0;
	}
}

public OnPostThinkPost(id)
{
	new weapons = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
	if(IsPlayerAlive(id) && weapons > 0 && IsValidEdict(weapons))
	{
		new buttons = GetClientButtons(id);
		if(GetConVarInt(CV_swap_reach)?buttons & IN_ATTACK2:buttons & IN_ATTACK)
		{
			new String:classname[32];
			GetEdictClassname(GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon"), classname, sizeof(classname));
			if(GetEntPropEnt(id, Prop_Data, "m_hActiveWeapon") == GetPlayerWeaponSlot(id, 2))
			{
				if(!Process[id])
				{
					SetEntProp(id, Prop_Send, "m_iShotsFired", 0);
					new Float:RealDelay = FloatSub(GetEntPropFloat(weapons, Prop_Send, "m_flNextPrimaryAttack"), GetGameTime());
					new Float:Delay = GetConVarInt(CV_swap_reach)?RealDelay>1.05?GetConVarFloat(CV_delay_cut):GetConVarFloat(CV_delay_cut_miss):RealDelay>0.45?GetConVarFloat(CV_delay_cut):GetConVarFloat(CV_delay_cut_miss);
					SetEntPropFloat(weapons, Prop_Send, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Delay));
					SetEntPropFloat(weapons, Prop_Send, "m_flNextSecondaryAttack", FloatAdd(GetGameTime(), Delay));
					Process[id] = 1;
				}
			}
		}
		if(GetConVarInt(CV_swap_reach)?buttons & IN_ATTACK:buttons & IN_ATTACK2)
		{
			new String:classname[32];
			GetEdictClassname(GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon"), classname, sizeof(classname));
			if(GetEntPropEnt(id, Prop_Data, "m_hActiveWeapon") == GetPlayerWeaponSlot(id, 2))
			{
				if(!Process[id])
				{
					SetEntProp(id, Prop_Send, "m_iShotsFired", 0);
					new Float:RealDelay = FloatSub(GetEntPropFloat(weapons, Prop_Send, "m_flNextPrimaryAttack"), GetGameTime());
					new Float:Delay = GetConVarInt(CV_swap_reach)?RealDelay>0.45?GetConVarFloat(CV_delay_stab):GetConVarFloat(CV_delay_stab_miss):RealDelay>1.05?GetConVarFloat(CV_delay_stab):GetConVarFloat(CV_delay_stab_miss);
					SetEntPropFloat(weapons, Prop_Send, "m_flNextPrimaryAttack", FloatAdd(GetGameTime(), Delay));
					SetEntPropFloat(weapons, Prop_Send, "m_flNextSecondaryAttack", FloatAdd(GetGameTime(), Delay));
					Process[id] = 1;
				}
			}
		}
	}
	static OldWeapon[MAXPLAYERS + 1];
	static OldSequence[MAXPLAYERS + 1];
	static Float:OldCycle[MAXPLAYERS + 1];
	static Float:OldPlaybackRate[MAXPLAYERS + 1];
	static bool:IsAlive[MAXPLAYERS + 1];
	
	decl String:classname[32];
	
	if(IsAlive[id] && !IsPlayerAlive(id))
	{
		new EntEffects = GetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects", EntEffects);
	}
	if(!IsAlive[id] && IsPlayerAlive(id))
	{
		SpawnCheck[id] = true;
	}
	IsAlive[id] = IsPlayerAlive(id);
	
	//handle spectators
	if(!IsPlayerAlive(id))
	{
		new spec = GetEntPropEnt(id, Prop_Send, "m_hObserverTarget");
		if(spec != -1)
		{
			weapons = GetEntPropEnt(spec, Prop_Send, "m_hActiveWeapon");
			if(weapons > 0)
			{
				GetEdictClassname(weapons, classname, 32);
				if(StrEqual(classname, "weapon_knife"))
				{
					SetEntProp(entity_viewmodel[spec][1], Prop_Send, "m_nModelIndex", PrecachedModel[0]);
					SetEntProp(weapons, Prop_Send, "m_iWorldModelIndex", PrecachedModel[1]);
				}
			}
		}
		return;
	}
	
	weapons = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon");
	new Sequence = GetEntProp(entity_viewmodel[id][0], Prop_Send, "m_nSequence");
	new Float:Cycle = GetEntPropFloat(entity_viewmodel[id][0], Prop_Data, "m_flCycle");
	new Float:percent = GetConVarFloat(CV_speed_viewmodel);
	new Float:PlaybackRate = GetEntPropFloat(entity_viewmodel[id][0], Prop_Send, "m_flPlaybackRate")*percent/100.0;
	
	if(weapons <= 0)
	{
		new EntEffects = GetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects", EntEffects);
			
		OldWeapon[id] = weapons;
		OldSequence[id] = Sequence;
		OldCycle[id] = Cycle;
		
		return;
	}
	
	//just stuck the weapon switching in here aswell instead of a separate hook
	if(weapons != OldWeapon[id])
	{
		GetEdictClassname(weapons, classname, sizeof(classname));
		if(StrEqual(classname, "weapon_knife"))
		{
			//hide viewmodel
			new EntEffects = GetEntProp(entity_viewmodel[id][0], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(entity_viewmodel[id][0], Prop_Send, "m_fEffects", EntEffects);
			//unhide unused viewmodel
			EntEffects = GetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects");
			EntEffects &= ~EF_NODRAW;
			SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects", EntEffects);
			
			//set model and copy over props from viewmodel to used viewmodel
			SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_nModelIndex", PrecachedModel[0]);
			SetEntPropEnt(entity_viewmodel[id][1], Prop_Send, "m_hWeapon", GetEntPropEnt(entity_viewmodel[id][0], Prop_Send, "m_hWeapon"));
			
			SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_nSequence", GetEntProp(entity_viewmodel[id][0], Prop_Send, "m_nSequence"));
			SetEntPropFloat(entity_viewmodel[id][1], Prop_Send, "m_flPlaybackRate", GetEntPropFloat(entity_viewmodel[id][0], Prop_Send, "m_flPlaybackRate"));
			
			SetEntProp(weapons, Prop_Send, "m_iWorldModelIndex", PrecachedModel[1]);
		}
		else
		{
			//hide unused viewmodel if the current weapon isn't using it
			new EntEffects = GetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects");
			EntEffects |= EF_NODRAW;
			SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_fEffects", EntEffects);
		}
	}
	else
	{
		static Data[MAXPLAYERS+1];
		//copy the animation stuff from the viewmodel to the used one every frame
		SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_nSequence", GetEntProp(entity_viewmodel[id][0], Prop_Send, "m_nSequence"));
		SetEntPropFloat(entity_viewmodel[id][1], Prop_Send, "m_flPlaybackRate", PlaybackRate);
		if((Cycle < OldCycle[id]) && (Sequence == OldSequence[id]))
		{
			if(GetEntPropEnt(id, Prop_Data, "m_hActiveWeapon") == GetPlayerWeaponSlot(id, 2)) Data[id] = 5;
			SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_nSequence", 0);
		}
		else if(Sequence == OldSequence[id])
		{
			if(Data[id] > 0)
			{
				Data[id] -= 1;
				SetEntProp(entity_viewmodel[id][1], Prop_Send, "m_nSequence", 0);
			}
			else if(Data[id]) Data[id] = 0;
		}
		else if(Data[id]) Data[id] = 0;
	}
	//hide viewmodel a frame after spawning
	if(SpawnCheck[id] && GetEntPropEnt(id, Prop_Data, "m_hActiveWeapon") == GetPlayerWeaponSlot(id, 2))
	{
		SpawnCheck[id] = false;
		new EntEffects = GetEntProp(entity_viewmodel[id][0], Prop_Send, "m_fEffects");
		EntEffects |= EF_NODRAW;
		SetEntProp(entity_viewmodel[id][0], Prop_Send, "m_fEffects", EntEffects);
	}
	
	OldWeapon[id] = weapons;
	OldSequence[id] = Sequence;
	OldPlaybackRate[id] = PlaybackRate;
	OldCycle[id] = Cycle;
}

public Action:OnTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(attacker > 0 && attacker <= MaxClients)
	{
		decl String:classname[32];
		GetClientWeapon(attacker, classname, 32);
		if(StrEqual(classname, "weapon_knife") && attacker == inflictor && damagetype == 4098 && ammotype == -1 && !hitbox && !hitgroup && IsCustom[attacker])
		{
			new Float:origin1[3], Float:origin2[3], Float:vector[3];
			GetClientEyePosition(attacker, origin1);
			GetClientEyePosition(victim, origin2);
			MakeVectorFromPoints(origin1, origin2, vector);
			NormalizeVector(vector, vector);
			if(damage < 50.0)
			{
				damage = GetConVarFloat(CV_damage_cut);
				ScaleVector(vector, GetConVarFloat(CV_knockback_cut));
			}
			else if(damage > 100.0)
			{
				damage = GetConVarFloat(CV_damage_backstab);
				ScaleVector(vector, GetConVarFloat(CV_knockback_backstab));
			}
			else
			{
				damage = GetConVarFloat(CV_damage_stab);
				ScaleVector(vector, GetConVarFloat(CV_knockback_stab));
			}
			if(GetClientTeam(victim) != GetClientTeam(attacker) || GetConVarInt(CV_knockback_sameteam)) TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vector);
			if(GetClientTeam(victim) != GetClientTeam(attacker) && damage < 1.0) return Plugin_Handled;
			else if(GetClientTeam(victim) == GetClientTeam(attacker) && damage < 3.0) return Plugin_Handled;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

public Action:SetTransmit_CallBack(entity, viewer)
{
	new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(viewer > 0 && viewer <= MaxClients)
	{
		new weapons = GetEntPropEnt(viewer, Prop_Send, "m_hActiveWeapon");
		if(owner == viewer && weapons == GetPlayerWeaponSlot(viewer, 2))
			return Plugin_Handled;
	}
	if(owner > 0 && owner <= MaxClients && (!IsClientInGame(owner) || !IsCustom[owner])) SDKUnhook(entity, SDKHook_SetTransmit, SetTransmit_CallBack);
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(id, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsClientInGame(id))
	{
		if(IsPlayerAlive(id))
		{
			if(GetConVarInt(CV_swap_reach))
			{
				new weapons = GetEntPropEnt(id, Prop_Send, "m_hActiveWeapon"), String:classname[32];
				if(weapons > 0 && IsValidEntity(weapons)) GetEdictClassname(weapons, classname, sizeof(classname));
				if(StrEqual(classname, "weapon_knife"))
				{
					new temporary = buttons;
					if(buttons & IN_ATTACK)
					{
						if(!(buttons & IN_ATTACK2)) buttons -= IN_ATTACK;
						if(!(buttons & IN_ATTACK2)) buttons += IN_ATTACK2;
					}
					if(temporary & IN_ATTACK2)
					{
						if(!(temporary & IN_ATTACK)) buttons -= IN_ATTACK2;
						if(!(temporary & IN_ATTACK)) buttons += IN_ATTACK;
					}
				}
			}
		}
	}
}

public GetConfigVersion()
{
	new Handle:hDirectory = OpenDirectory("cfg/sourcemod");
	decl String:sFilename[128], FileType:Type;
	new String:Version[32];
	while(ReadDirEntry(hDirectory, sFilename, sizeof(sFilename), Type))
	{
		if(Type == FileType_File)
		{
			if(!StrContains(sFilename, "advanced_knife_customizer", false))
			{
				ReplaceString(sFilename, sizeof(sFilename), "advanced_knife_customizer", "");
				ReplaceString(sFilename, sizeof(sFilename), ".cfg", "");
				Format(Version, sizeof(Version), sFilename);
			}
		}
	}
	CreateConVar("advanced_knife_customizer_version", Version, "Advanced Knife Customizer's Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	VersionLoaded = true;
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	if(VersionLoaded)
	{
		new String:Config_Version[16];
		GetConVarString(FindConVar("advanced_knife_customizer_version"), Config_Version, sizeof(Config_Version));
		new String:config_name[32];
		Format(config_name, sizeof(config_name), "advanced_knife_customizer%s", Config_Version);
		if(!StrEqual(Config_Version, PLUGIN_VERSION, false))
		{
			PrintToServer("AKC Config Updating");
			new String:new_config_name[32];
			Format(new_config_name, sizeof(new_config_name), "advanced_knife_customizer%s", PLUGIN_VERSION);
			AutoExecConfig(true, new_config_name);
			
			CreateConVar("akc_knockback_cut", "0.0", "set cut knockback.");
			CreateConVar("akc_knockback_stab", "0.0", "set stab knockback.");
			CreateConVar("akc_knockback_backstab", "0.0", "set backstab knockback.");
			CreateConVar("akc_knockback_sameteam", "0", "set knockback for same team.");
			CreateConVar("akc_damage_cut", "20.0", "set cut damage.");
			CreateConVar("akc_damage_stab", "65.0", "set stab damage.");
			CreateConVar("akc_damage_backstab", "195.0", "set backstab damage.");
			CreateConVar("akc_sound_deploy", "weapons/knife/knife_deploy1.wav", "set swap(deploy) sound.");
			CreateConVar("akc_sound_hitwall", "weapons/knife/knife_hitwall1.wav", "set hitwall sound.");
			CreateConVar("akc_sound_hitmiss", "weapons/knife/knife_slash1.wav", "set hitmiss sound.");
			CreateConVar("akc_sound_cut", "weapons/knife/knife_hit1.wav", "set cut sound.");
			CreateConVar("akc_sound_stab", "weapons/knife/knife_stab.wav", "set stab sound.");
			CreateConVar("akc_model_view", "models/weapons/v_knife_t.mdl", "set view model.");
			CreateConVar("akc_model_world", "models/weapons/w_knife_t.mdl", "set world model.");
			CreateConVar("akc_delay_cut", "0.5", "set cut delay.");
			CreateConVar("akc_delay_cut_miss", "0.4", "set cut(hitmiss) delay.");
			CreateConVar("akc_delay_stab", "1.085", "set stab delay.");
			CreateConVar("akc_delay_stab_miss", "0.985", "set stab(hitmiss) delay.");
			CreateConVar("akc_speed_viewmodel", "100.0", "set speed viewmodel.");
			CreateConVar("akc_swap_reach", "0", "set swap reach each other.");
			CreateConVar("akc_allow_drop", "0", "set allow drop the knife.");
			CreateConVar("akc_mode_apply", "0", "set mode(0 = everyone, 1 = only admin, 2 = terrorist, 3 = CT");
			CreateConVar("akc_mode_flags", "z", "if you used mode 1, try this!");
			CreateConVar("advanced_knife_customizer_version", PLUGIN_VERSION, "Advanced Knife Customizer's Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
			
			SetConVarString(FindConVar("advanced_knife_customizer_version"), PLUGIN_VERSION);
			
			PrintToServer("AKC Config Updated! You need to rewrite config. advanced_knife_customizer%s.cfg", PLUGIN_VERSION);
		}
		AutoExecConfig(false, config_name);
		CV_knockback_cut = CreateConVar("akc_knockback_cut", "0.0", "set cut knockback.");
		CV_knockback_stab = CreateConVar("akc_knockback_stab", "0.0", "set stab knockback.");
		CV_knockback_backstab = CreateConVar("akc_knockback_backstab", "0.0", "set backstab knockback.");
		CV_knockback_sameteam = CreateConVar("akc_knockback_sameteam", "0", "set knockback for same team.");
		CV_damage_cut = CreateConVar("akc_damage_cut", "20.0", "set cut damage.");
		CV_damage_stab = CreateConVar("akc_damage_stab", "65.0", "set stab damage.");
		CV_damage_backstab = CreateConVar("akc_damage_backstab", "195.0", "set backstab damage.");
		CV_sound_deploy = CreateConVar("akc_sound_deploy", "weapons/knife/knife_deploy1.wav", "set swap(deploy) sound.");
		CV_sound_hitwall = CreateConVar("akc_sound_hitwall", "weapons/knife/knife_hitwall1.wav", "set hitwall sound.");
		CV_sound_hitmiss = CreateConVar("akc_sound_hitmiss", "weapons/knife/knife_slash1.wav", "set hitmiss sound.");
		CV_sound_cut = CreateConVar("akc_sound_cut", "weapons/knife/knife_hit1.wav", "set cut sound.");
		CV_sound_stab = CreateConVar("akc_sound_stab", "weapons/knife/knife_stab.wav", "set stab sound.");
		CV_model_view = CreateConVar("akc_model_view", "models/weapons/v_knife_t.mdl", "set view model.");
		CV_model_world = CreateConVar("akc_model_world", "models/weapons/w_knife_t.mdl", "set world model.");
		CV_delay_cut = CreateConVar("akc_delay_cut", "0.5", "set cut delay.");
		CV_delay_cut_miss = CreateConVar("akc_delay_cut_miss", "0.4", "set cut(hitmiss) delay.");
		CV_delay_stab = CreateConVar("akc_delay_stab", "1.085", "set stab delay.");
		CV_delay_stab_miss = CreateConVar("akc_delay_stab_miss", "0.985", "set stab(hitmiss) delay.");
		CV_speed_viewmodel = CreateConVar("akc_speed_viewmodel", "100.0", "set speed viewmodel.");
		CV_swap_reach = CreateConVar("akc_swap_reach", "0", "set swap reach each other.");
		CV_allow_drop = CreateConVar("akc_allow_drop", "0", "set allow drop the knife.");
		CV_mode_apply = CreateConVar("akc_mode_apply", "0", "set mode(0 = everyone, 1 = only admin, 2 = terrorist, 3 = CT");
		CV_flags_admin = CreateConVar("akc_mode_flags", "z", "if you used mode 1, try this!");
		CreateConVar("advanced_knife_customizer_version", PLUGIN_VERSION, "Advanced Knife Customizer's Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
		HookConVarChange(CV_sound_deploy, ChangeConVar_SoundCallBack);
		HookConVarChange(CV_sound_hitwall, ChangeConVar_SoundCallBack);
		HookConVarChange(CV_sound_hitmiss, ChangeConVar_SoundCallBack);
		HookConVarChange(CV_sound_cut, ChangeConVar_SoundCallBack);
		HookConVarChange(CV_sound_stab, ChangeConVar_SoundCallBack);
		HookConVarChange(CV_model_view, ChangeConVar_ModelCallBack_View);
		HookConVarChange(CV_model_world, ChangeConVar_ModelCallBack_World);
		HookConVarChange(CV_mode_apply, ChangeConVar_ModeCallBack);
		for(new x=1; x<=MaxClients; x++)
		{
			if(IsClientInGame(x))
				OnClientPutInServer(x);
		}
		ConfigLoaded = true;
		Precache();
	}
}

public ChangeConVar_ModeCallBack(Handle:convar, const String:oldValue[], const String:newValue[])
{
	for(new x=1; x<=MaxClients; x++)
	{
		if(IsClientInGame(x))
		{
			IsCustom[x] = false;
			SDKUnhook(x, SDKHook_WeaponEquip, WeaponEquip_CallBack);
			SDKUnhook(x, SDKHook_PostThink, OnPostThink);
			SDKUnhook(x, SDKHook_PostThinkPost, OnPostThinkPost);
			
			new weapons = GetPlayerWeaponSlot(x, 2);
			if(IsValidEdict(weapons)) SDKUnhook(weapons, SDKHook_SetTransmit, SetTransmit_CallBack);
			
			weapons = GetEntPropEnt(x, Prop_Data, "m_hActiveWeapon");
			if(IsValidEdict(weapons) && weapons == GetPlayerWeaponSlot(x, 2))
			{
				new EntEffects = GetEntProp(entity_viewmodel[x][0], Prop_Send, "m_fEffects");
				EntEffects &= ~EF_NODRAW;
				SetEntProp(entity_viewmodel[x][0], Prop_Send, "m_fEffects", EntEffects);
				
				EntEffects = GetEntProp(entity_viewmodel[x][1], Prop_Send, "m_fEffects");
				EntEffects |= EF_NODRAW;
				SetEntProp(entity_viewmodel[x][1], Prop_Send, "m_fEffects", EntEffects);
				
				RemovePlayerItem(x, weapons);
				RemoveEdict(weapons);
				weapons = GivePlayerItem(x, "weapon_knife");
			}
			else if(!IsValidEdict(weapons) && GetClientTeam(x) > 1) weapons = GivePlayerItem(x, "weapon_knife");
			new mode = StringToInt(newValue);
			if((!mode && GetClientTeam(x) > 1) || (mode > 1 && mode < 4 && GetClientTeam(x) == mode))
			{
				SDKHook(x, SDKHook_WeaponEquip, WeaponEquip_CallBack);
				SDKHook(x, SDKHook_PostThink, OnPostThink);
				SDKHook(x, SDKHook_PostThinkPost, OnPostThinkPost);
				SDKHook(weapons, SDKHook_Spawn, OnEntitySpawned3);
				IsCustom[x] = true;
			}
			if(mode == 1)
			{
				new String:flags[32];
				GetConVarString(CV_flags_admin, flags, 32);
				new adminflags = ReadFlagString(flags);
				if(AdminFlagAccess(x, adminflags))
				{
					SDKHook(x, SDKHook_WeaponEquip, WeaponEquip_CallBack);
					SDKHook(x, SDKHook_PostThink, OnPostThink);
					SDKHook(x, SDKHook_PostThinkPost, OnPostThinkPost);
					SDKHook(weapons, SDKHook_Spawn, OnEntitySpawned3);
					IsCustom[x] = true;
				}
			}
		}
	}
}

public ChangeConVar_SoundCallBack(Handle:convar, const String:oldValue[], const String:newValue[])
{
	PrecacheSound(newValue, true);
}

public ChangeConVar_ModelCallBack_View(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!IsModelPrecached(newValue)) PrecacheModel(newValue, true);
	PrecachedModel[0] = PrecacheModel(newValue, true);
}

public ChangeConVar_ModelCallBack_World(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(!IsModelPrecached(newValue)) PrecacheModel(newValue, true);
	PrecachedModel[1] = PrecacheModel(newValue, true);
}

public Precache()
{
	if(ConfigLoaded)
	{
		new String:String_Model[2][256], String:String_Sound[256];
		GetConVarString(CV_model_view, String_Model[0], 256);
		GetConVarString(CV_model_world, String_Model[1], 256);
		PrecachedModel[0] = PrecacheModel(String_Model[0], true);
		PrecachedModel[1] = PrecacheModel(String_Model[1], true);
		GetConVarString(CV_sound_hitwall, String_Sound, sizeof(String_Sound));
		PrecacheSound(String_Sound, true);
		GetConVarString(CV_sound_cut, String_Sound, sizeof(String_Sound));
		PrecacheSound(String_Sound, true);
		GetConVarString(CV_sound_hitmiss, String_Sound, sizeof(String_Sound));
		PrecacheSound(String_Sound, true);
		GetConVarString(CV_sound_stab, String_Sound, sizeof(String_Sound));
		PrecacheSound(String_Sound, true);
		GetConVarString(CV_sound_deploy, String_Sound, sizeof(String_Sound));
		PrecacheSound(String_Sound, true);
	}
}

stock bool:AdminFlagAccess(Client, adminflags)
{
	//return (GetUserAdmin(Client) == INVALID_ADMIN_ID) ? 0 : 1;
	if(GetUserAdmin(Client) != INVALID_ADMIN_ID)
	{
		//(1<<14) is ADMFLAG_ROOT
		if(GetAdminFlags(GetUserAdmin(Client), Access_Effective) & adminflags || GetAdminFlags(GetUserAdmin(Client), Access_Effective) == (1<<14)) return true;
		else return false;
	}
	return false;
}