#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin myinfo = {
   name = "Freak Fortress 2: Alex's Blighcaller pack",
   author = "Lealex14",		
   description = "Version 2.0 of blightcaller",
   version = "2.5.0"
}

float OFF_THE_MAP[3] =
{
	1182792704.0, 1182792704.0, -964690944.0
};
Handle HUDTimerTeleport[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle HUDTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle ImageTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle HUDTimerAttributeOnkill[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle TimerHeal[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
Handle SDKEquipWearable = null;


bool PlayerCanChangeForm[MAXPLAYERS+1];
bool PhaseWalk[MAXPLAYERS+1];
bool TouchWeapon[MAXPLAYERS+1];
bool BlightReverse[MAXPLAYERS + 1];


float SpecialTimer[MAXPLAYERS+1];
float ReloadTimer[MAXPLAYERS+1];
float AltFireTimer[MAXPLAYERS+1];
float ActionTimer[MAXPLAYERS+1];
float CrtlTimer[MAXPLAYERS+1];
float GainMeterTimer[MAXPLAYERS+1];
float BlightSpeed[MAXPLAYERS+1];
float TpPoint[MAXPLAYERS + 1][10][3];
float BossSpawnPoint[MAXPLAYERS + 1][3];

int FormMod[MAXPLAYERS+1];
int StableMeter[MAXPLAYERS+1];
int UnstableMeter[MAXPLAYERS+1];
int PointLockSelect[MAXPLAYERS + 1]=0;
int EntityBlightShield[MAXPLAYERS + 1]=-1;
int WeaponOnDeath[MAXPLAYERS + 1]=0;


public Action FF2_OnAbility2(boss,const char[] plugin_name,const char[] ability_name,action)
{
	if(!strcmp(ability_name, "Blight_Change_Form"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		if (FormMod[client]==0)
		{
			FormMod[client] = 1;
			char RGBA[64], RBGAList[32][32], classname[64], attr[132];
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 6, classname, sizeof(classname));
			int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Change_Form", 7, 0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 8, attr, sizeof(attr));
			
			BlightSpeed[client] = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Blight_Change_Form", 9, 100.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 10, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			TouchWeapon[client]=false;
			
			TF2_RemoveAllWeapons(client);
			FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
		}
		else if (SpecialTimer[client]==0.0)
		{
			FormMod[client] = 0;
			
			char RGBA[64], RBGAList[32][32], classname[64], attr[132];
			
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 1, classname, sizeof(classname));
			int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Change_Form",2, 0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 3, attr, sizeof(attr));
			
			BlightSpeed[client] = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Blight_Change_Form", 4, 100.0);
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Change_Form", 5, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			TouchWeapon[client]=false;
			
			TF2_RemoveAllWeapons(client);
			FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
		}
	}
	
	if(!strcmp(ability_name, "Blight_Weighdown"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		SetEntityGravity(client, 10.0);
		CreateTimer(0.25, Timer_Reset_Gravity, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(!strcmp(ability_name, "Position_Teleport_Change"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		int MaxTeleport = FF2_GetAbilityArgument(boss,this_plugin_name,"Position_Teleport_Change",1, 2)-1;
		
		if (PointLockSelect[client]<MaxTeleport)
			PointLockSelect[client] += 1;
		else
			PointLockSelect[client] = 0;
	}
	
	if(!strcmp(ability_name, "Position_Teleport_Place"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		GetClientAbsOrigin(client, TpPoint[client][PointLockSelect[client]]);
	}
	
	if(!strcmp(ability_name, "Position_Teleport_Teleport"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		
		char Cond[64], CondList[32][32], EffectName[128];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Position_Teleport_Teleport", 1, Cond, sizeof(Cond));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Position_Teleport_Teleport", 2, EffectName, sizeof(EffectName));
		float Duration = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Position_Teleport_Teleport",3, 3.0);
		
		char RGBA[64], RBGAList[32][32], RGBAImage[64], RBGAImageList[32][32];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Position_Teleport_Teleport", 4, RGBAImage, sizeof(RGBAImage));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Position_Teleport_Teleport", 5, RGBA, sizeof(RGBA));
		
		bool VelocityCons = view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, "Position_Teleport_Teleport", 7, 0));
		float VelocityTele[3];
		
		if (VelocityCons)
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", VelocityTele);
		
		ExplodeString(RGBAImage, " ; ", RBGAImageList, sizeof(RBGAImageList), sizeof(RBGAImageList));
		
		int RImage = StringToInt(RBGAImageList[0]);
		int GImage = StringToInt(RBGAImageList[1]);
		int BImage = StringToInt(RBGAImageList[2]);
		int AImage = StringToInt(RBGAImageList[3]);
		
		MakeAnImage(client, Duration, EffectName, RImage, GImage, BImage, AImage);
		TeleportEntity(client, TpPoint[client][PointLockSelect[client]], NULL_VECTOR, VelocityTele);
		
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		float ChangeRGBADuration = StringToFloat(RBGAList[4]);
		
		if (!PhaseWalk[client])
		{
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			CreateTimer(ChangeRGBADuration, Timer_Reset_RGBA, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		int count = ExplodeString(Cond, " ; ", CondList, sizeof(CondList), sizeof(CondList));
		if (count > 0)
		{
			for (new Countid = 0; Countid < count; Countid+=2)
			{
				TF2_AddCondition(client, TFCond:StringToInt(CondList[Countid]), StringToFloat(CondList[Countid+1]));
			}
		}
	}
	
	if(!strcmp(ability_name, "Blight_Touch"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		
		char classname[64], attr[132];
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Touch", 1, classname, sizeof(classname));
		int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 2, 0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Touch", 3, attr, sizeof(attr));
		
		TF2_RemoveAllWeapons(client);
		FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
		
		TouchWeapon[client]=true;
	}
	
	if(!strcmp(ability_name, "Phase_Walk"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		
		char Cond[64], CondList[32][32], RGBA[64], RBGAList[32][32];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Phase_Walk", 3, Cond, sizeof(Cond));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Phase_Walk", 2, RGBA, sizeof(RGBA));
		float Duration = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Phase_Walk",1, 3.0);
		float ImageSpawnRate = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Phase_Walk",4, 0.5);
		
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, R, G, B, A);
		
		PhaseWalk[client] = true;
		
		ImageTimer[client] = CreateTimer(ImageSpawnRate, Timer_Create_Image, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(Duration, Timer_Reset_Phase, client, TIMER_FLAG_NO_MAPCHANGE);
		
		int count = ExplodeString(Cond, " ; ", CondList, sizeof(CondList), sizeof(CondList));
		if (count > 0)
		{
			for (new Countid = 0; Countid < count; Countid+=2)
			{
				TF2_AddCondition(client, TFCond:StringToInt(CondList[Countid]), StringToFloat(CondList[Countid+1]));
			}
		}
		
		for (new player = 1; player <= MaxClients; player++)
		{
			if (IsClientInGame(player))
			{
				if (IsPlayerAlive(player))
				{
					SetEntProp(player, Prop_Data, "m_CollisionGroup", 2);
				}
			}
		}
		for(int ient=1; ient<=2048; ient++) // 2048 = Max entities
	    {
			if (IsValidEdict(ient) && IsValidEntity(ient))
			{
				char sClassname[64];
				GetEdictClassname(ient, sClassname, sizeof(sClassname));
				if (strncmp(sClassname, "obj_",4)==0)
				{
					SetEntProp(ient, Prop_Data, "m_CollisionGroup", 2);
				}
			}
		}
		
		char classname[64], attr[132];
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Phase_Walk", 9, classname, sizeof(classname));
		int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Phase_Walk", 10, 0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Phase_Walk", 11, attr, sizeof(attr));
		
		TF2_RemoveAllWeapons(client);
		FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
	}
	
	if(!strcmp(ability_name, "Create_Projectile_Particle"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		
		float position[3], rot[3], velocity[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
		GetClientEyeAngles(client,rot);
		position[2]+=63;
		
		int BossTeam = GetClientTeam(client);
		
		int proj=CreateEntityByName("tf_projectile_rocket");
		SetVariantInt(BossTeam);
		AcceptEntityInput(proj, "TeamNum", -1, -1, 0);
		SetVariantInt(BossTeam);
		AcceptEntityInput(proj, "SetTeam", -1, -1, 0); 
		SetEntPropEnt(proj, Prop_Send, "m_hOwnerEntity",client);		
		float speed=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Create_Projectile_Particle",4,1000.0);
		velocity[0]=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*speed;
		velocity[1]=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*speed;
		velocity[2]=Sine(DegToRad(rot[0]))*speed;
		velocity[2]*=-1;
		TeleportEntity(proj, position, rot,velocity);
		SetEntProp(proj, Prop_Send, "m_bCritical", 1);
		SetEntDataFloat(proj, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Create_Projectile_Particle",3,40.0), true);
		DispatchSpawn(proj);
		char s[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss,this_plugin_name,"Create_Projectile_Particle",1,s,PLATFORM_MAX_PATH);
		if(strlen(s)>5)
			SetEntityModel(proj,s);
					
		
		FF2_GetAbilityArgumentString(boss,this_plugin_name,"Create_Projectile_Particle",2,s,PLATFORM_MAX_PATH);
		if(strlen(s)>2)
			CreateTimer(15.0, RemoveEntity2, EntIndexToEntRef(AttachParticle(proj, s,_,true)));
		
		float size=FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Create_Projectile_Particle",5,1.0);
		SetEntPropFloat(proj, Prop_Send, "m_flModelScale", size);
	}
	
	if (!strcmp(ability_name, "Blight_Reverse"))
	{
		int client = GetClientOfUserId(FF2_GetBossUserId(boss));
		BlightReverse[client] = true;
		float Duration = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Blight_Reverse",1, 5.0);
		float Size = FF2_GetAbilityArgumentFloat(boss,this_plugin_name,"Blight_Reverse",12, 5.0);
		
		char Cond[64], CondList[32][32], classname[64], attr[132];
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Reverse", 3, Cond, sizeof(Cond));
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Reverse", 4, classname, sizeof(classname));
		int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Reverse",5, 0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Reverse", 6, attr, sizeof(attr));
		
		TF2_RemoveAllWeapons(client);
		FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
		
		int Wearable = TF2_CreateAndEquipWearable(client, "tf_wearable", 166, 666, 13, "");
		
		int count = ExplodeString(Cond, " ; ", CondList, sizeof(CondList), sizeof(CondList));
		if (count > 0)
		{
			for (new Countid = 0; Countid < count; Countid+=2)
			{
				TF2_AddCondition(client, TFCond:StringToInt(CondList[Countid]), StringToFloat(CondList[Countid+1]));
			}
		}
		
		char model[2048], RGBA[64], RBGAList[32][32];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Reverse", 10, model, sizeof(model));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Reverse", 11, RGBA, sizeof(RGBA));
		
		ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
		
		int R = StringToInt(RBGAList[0]);
		int G = StringToInt(RBGAList[1]);
		int B = StringToInt(RBGAList[2]);
		int A = StringToInt(RBGAList[3]);
		
		int modelIndex = PrecacheModel(model);
		SetEntProp(Wearable, Prop_Send, "m_nModelIndex", modelIndex);
		SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
		SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
		SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
		SetEntProp(Wearable, Prop_Send, "m_nModelIndexOverrides", GetEntProp(Wearable, Prop_Send, "m_nModelIndex"), _, 0);
		
		SetEntPropFloat(Wearable, Prop_Send, "m_flModelScale", Size);
		
		SetEntityRenderMode(Wearable, RENDER_TRANSCOLOR);
		SetEntityRenderColor(Wearable, R, G, B, A);
		
		
		EntityBlightShield[client] = Wearable;
		CreateTimer(Duration, Timer_Reset_Reverse, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_Reset_Reverse(Handle timer, client)
{
	if (IsValidEdict(client) && IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);			
		if (FF2_HasAbility(idBoss, this_plugin_name, "Blight_Reverse"))
		{
			char classname[64], attr[132];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Reverse", 7, classname, sizeof(classname));
			int index = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Reverse",8, 0);
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Reverse", 9, attr, sizeof(attr));
			
			TF2_RemoveAllWeapons(client);
			FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
			
			TF2_RemoveWearable(client, EntityBlightShield[client]);
			EntityBlightShield[client] = -1;
			
			BlightReverse[client] = false;
			
		}
	}
}

public Action Timer_Create_Image(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client) && PhaseWalk[client])
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, "Phase_Walk"))
			{
				char EffectName[128], RGBAImage[64], RBGAImageList[32][32];
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Phase_Walk", 5, RGBAImage, sizeof(RGBAImage));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Phase_Walk", 6, EffectName, sizeof(EffectName));
				float ImageDuration = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Phase_Walk",7, 3.0);
				
				ExplodeString(RGBAImage, " ; ", RBGAImageList, sizeof(RBGAImageList), sizeof(RBGAImageList));
				
				int RImage = StringToInt(RBGAImageList[0]);
				int GImage = StringToInt(RBGAImageList[1]);
				int BImage = StringToInt(RBGAImageList[2]);
				int AImage = StringToInt(RBGAImageList[3]);
				
				MakeAnImage(client, ImageDuration, EffectName, RImage, GImage, BImage, AImage);
			}
			else
			{
				if (ImageTimer[client]!=INVALID_HANDLE)
				{
					KillTimer(ImageTimer[client]);
					ImageTimer[client] = INVALID_HANDLE;
				}
			}
		}
		else
		{
			if (ImageTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(ImageTimer[client]);
				ImageTimer[client] = INVALID_HANDLE;
			}
		}
	}
	else
	{
		if (ImageTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(ImageTimer[client]);
			ImageTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action Timer_Reset_Phase(Handle timer, int client)
{
	if (IsValidEdict(client) && IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);			
		if (FF2_HasAbility(idBoss, this_plugin_name, "Phase_Walk"))
		{
			char RGBA[64], RBGAList[32][32];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Phase_Walk", 8, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
			
			PhaseWalk[client] = false;
			
			float ClientPos[3];
			GetClientAbsOrigin(client, ClientPos);
			
			for (new player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player))
				{
					if (IsPlayerAlive(player))
					{
						SetEntProp(player, Prop_Data, "m_CollisionGroup", 5);
					}
				}
			}
			for(int ient=1; ient<=2048; ient++) // 2048 = Max entities
		    {
				if (IsValidEdict(ient) && IsValidEntity(ient))
				{
					char sClassname[64];
					GetEdictClassname(ient, sClassname, sizeof(sClassname));
					if (strncmp(sClassname, "obj_",4)==0)
					{
						SetEntProp(ient, Prop_Data, "m_CollisionGroup", 5);
					}
				}
			}
			
			char classname[64], attr[132];
		
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Phase_Walk", 12, classname, sizeof(classname));
			int index = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Phase_Walk", 13, 0);
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Phase_Walk", 14, attr, sizeof(attr));
			
			TF2_RemoveAllWeapons(client);
			FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
		}
	}
	
}

public Action Timer_Reset_RGBA(Handle timer, int client)
{
	if (IsValidEdict(client) && IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);			
		if (FF2_HasAbility(idBoss, this_plugin_name, "Position_Teleport_Teleport"))
		{
			char RGBA[64], RBGAList[32][32];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Position_Teleport_Teleport", 6, RGBA, sizeof(RGBA));
			
			ExplodeString(RGBA, " ; ", RBGAList, sizeof(RBGAList), sizeof(RBGAList));
			
			int R = StringToInt(RBGAList[0]);
			int G = StringToInt(RBGAList[1]);
			int B = StringToInt(RBGAList[2]);
			int A = StringToInt(RBGAList[3]);
			
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, R, G, B, A);
		}
	}
	
}

public Action Timer_Reset_Gravity(Handle timer, int client)
{
	SetEntityGravity(client, 1.0);
}

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("arena_win_panel", Event_WinPanel);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_spawn", OnPlayerSpawn);
	AddCommandListener(OnCallForMedic, "voicemenu");
	
	Handle gameData = LoadGameConfigFile("equipwearable");
	if(gameData == INVALID_HANDLE)
	{
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();

	delete gameData;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	PrepareAbilities();
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(FF2_GetRoundState()!=1)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;	
		
	int idBoss = FF2_GetBossIndex(client);
	
	FormMod[client]=0;
	PlayerCanChangeForm[client]=true;
	SpecialTimer[client]=0.0;
	ReloadTimer[client]=0.0;
	AltFireTimer[client]=0.0;
	ActionTimer[client]=0.0;
	CrtlTimer[client]=0.0;
	GainMeterTimer[client]=0.0;
	BlightSpeed[client] = 0.0;
	PhaseWalk[client] = false;
	TouchWeapon[client]=false;
	BlightReverse[client] = false;
	EntityBlightShield[client]=-1;
	WeaponOnDeath[client]=0;
	if (HUDTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HUDTimer[client]);
		HUDTimer[client] = INVALID_HANDLE;
	}
	
	if (HUDTimerTeleport[client] != INVALID_HANDLE)
	{
		KillTimer(HUDTimerTeleport[client]);
		HUDTimerTeleport[client] = INVALID_HANDLE;
	}
	
	if (HUDTimerAttributeOnkill[client]!=INVALID_HANDLE)
	{
		KillTimer(HUDTimerAttributeOnkill[client]);
		HUDTimerAttributeOnkill[client] = INVALID_HANDLE;
	}
	
	if (ImageTimer[client] != INVALID_HANDLE)
	{
		KillTimer(ImageTimer[client]);
		ImageTimer[client] = INVALID_HANDLE;
	}
	
	if (TimerHeal[client] != INVALID_HANDLE)
	{
		KillTimer(TimerHeal[client]);
		TimerHeal[client] = INVALID_HANDLE;
	}
	
	if (IsValidEdict(client) && IsClientInGame(client))
	{	
		if (FF2_HasAbility(idBoss, this_plugin_name, "Blight_Form"))
		{
			FF2_SetFF2flags(client, FF2_GetFF2flags(client) | FF2FLAG_HUDDISABLED);
			StableMeter[client]=FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 9, 11);
			UnstableMeter[client]=FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 19, 11);
			HUDTimer[client] = CreateTimer(0.1, Timer_Hud, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		
		
		if(FF2_HasAbility(idBoss, this_plugin_name, "Position_Teleport_Place"))
		{
			PointLockSelect[client] = 0;
			for (new TpSlot = 0; TpSlot <= 9; TpSlot++)
			{
				GetClientAbsOrigin(client, TpPoint[client][TpSlot]);
				
				bool HideWithForm = view_as<bool>(FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 6, 0));
				
				if (!HideWithForm)
				{
					HUDTimerTeleport[client] = CreateTimer(0.1, Timer_Hud_Teleport, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
		
		if(FF2_HasAbility(idBoss, this_plugin_name, "Passive_Regen"))
		{
			float Rate = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Passive_Regen", 1, 0.7);
				
			TimerHeal[client] = CreateTimer(Rate, Timer_Regen, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(FF2_HasAbility(idBoss, this_plugin_name, "Krazys_BS"))
		{
			float Waiting = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Krazys_BS", 1, 11.0);
			CreateTimer(Waiting, Timer_Emit_Sound, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if(FF2_HasAbility(idBoss, this_plugin_name, "Krazys_BS"))
		{
			float Waiting = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Krazys_BS", 1, 11.0);
			CreateTimer(Waiting, Timer_Emit_Sound, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		if (FF2_HasAbility(idBoss, this_plugin_name, "New_Attribute_On_Death"))
		{
			HUDTimerAttributeOnkill[client] = CreateTimer(0.1, Timer_Hud_Attr_On_Kill, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			
			char classname[64], attr[132];
		
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 1+(10*WeaponOnDeath[client]), classname, sizeof(classname));
			int index = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 2+(10*WeaponOnDeath[client]), 0);
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 3+(10*WeaponOnDeath[client]), attr, sizeof(attr));
			int slot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 4+(10*WeaponOnDeath[client]), 0);
			bool RemoveAll = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 5+(10*WeaponOnDeath[client]), 0));
			bool Max = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", (10*WeaponOnDeath[client]), 0));
			
			if (!Max)
			{
				WeaponOnDeath[client] += 1;
			
				TF2_RemoveWeaponSlot(client, slot);
				
				if (RemoveAll)
					TF2_RemoveAllWeapons(client);
					
				if (StrEqual(classname,"tf_wearable_demoshield"))
					TF2_CreateAndEquipWearable(client, classname, index, 666, 13, attr);
				else
					FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
			}
		}
	}
}

public Action Timer_Regen(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);
			float Range = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Passive_Regen", 2, 100.0);
			float Heal = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Passive_Regen", 3, 100.0);
			bool SelfHeal = view_as<bool>(FF2_GetAbilityArgument(idBoss, this_plugin_name, "Passive_Regen", 5, 1));
			bool CanOverHeal = view_as<bool>(FF2_GetAbilityArgument(idBoss, this_plugin_name, "Passive_Regen", 6, 0));
			
			char Cond[64], CondList[32][32];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Passive_Regen", 4, Cond, sizeof(Cond));
			
			for (int player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player))
				{
					if (IsPlayerAlive(player) && GetClientTeam(client)==GetClientTeam(player) && ((!SelfHeal && client!=player) || SelfHeal))
					{
						float ClientOrigin[3], PlayerOrigin[3];
						GetClientAbsOrigin(client, ClientOrigin);
						GetClientAbsOrigin(player, PlayerOrigin);
						
						if (Range >= GetVectorDistance(PlayerOrigin,ClientOrigin))
						{
							int count = ExplodeString(Cond, " ; ", CondList, sizeof(CondList), sizeof(CondList));
							if (count > 0)
							{
								for (new Countid = 0; Countid < count; Countid+=2)
								{
									TF2_AddCondition(player, TFCond:StringToInt(CondList[Countid]), StringToFloat(CondList[Countid+1]));
								}
							}
							
							int boss = FF2_GetBossIndex(player);
							if (boss != -1)
							{
								int Health = FF2_GetBossHealth(boss);
								int Maxhealth = FF2_GetBossMaxHealth(boss);
								int Lives = FF2_GetBossLives(boss);
										
								Health = RoundToCeil(Health + Heal + (Maxhealth*(Lives-1)));
								if(Health > Maxhealth && !CanOverHeal)
								{
									Health = Maxhealth;
								}
								
								FF2_SetBossHealth(boss, Health);
							}
							else
							{
								
								int Health = GetClientHealth(player);
								int Maxhealth = TF2_GetPlayerMaxHealth(player);
										
								Health = RoundToCeil(Health + Heal);
								if(Health > Maxhealth && !CanOverHeal)
								{
									Health = Maxhealth;
								}
								
								SetEntityHealth(player, Health);
							}
						}
					}
				}
			}
		}
	}
}
	
public Action Timer_Emit_Sound(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);
		if(FF2_HasAbility(idBoss, this_plugin_name, "Krazys_BS"))
		{
			char Sound[2048];
			FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Krazys_BS", 2, Sound, sizeof(Sound));
			for (int player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player))
				{
					EmitSoundToAll(Sound, player);
				}
			}
		}
	}
}

public PrepareAbilities()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		FormMod[client]=0;
		PlayerCanChangeForm[client]=true;
		SpecialTimer[client]=0.0;
		ReloadTimer[client]=0.0;
		AltFireTimer[client]=0.0;
		ActionTimer[client]=0.0;
		CrtlTimer[client]=0.0;
		GainMeterTimer[client]=0.0;
		BlightSpeed[client] = 0.0;
		PhaseWalk[client] = false;
		TouchWeapon[client]=false;
		BossSpawnPoint[client][0] =  0.0; 
		BossSpawnPoint[client][1] =  0.0; 
		BossSpawnPoint[client][2] =  0.0; 
		BlightReverse[client] = false;
		EntityBlightShield[client]=-1;
		WeaponOnDeath[client]=0;
		if (HUDTimer[client] != INVALID_HANDLE)
		{
			KillTimer(HUDTimer[client]);
			HUDTimer[client] = INVALID_HANDLE;
		}
		
		if (HUDTimerTeleport[client] != INVALID_HANDLE)
		{
			KillTimer(HUDTimerTeleport[client]);
			HUDTimerTeleport[client] = INVALID_HANDLE;
		}
		
		if (HUDTimerAttributeOnkill[client]!=INVALID_HANDLE)
		{
			KillTimer(HUDTimerAttributeOnkill[client]);
			HUDTimerAttributeOnkill[client] = INVALID_HANDLE;
		}
		
		if (ImageTimer[client] != INVALID_HANDLE)
		{
			KillTimer(ImageTimer[client]);
			ImageTimer[client] = INVALID_HANDLE;
		}
		
		if (TimerHeal[client] != INVALID_HANDLE)
		{
			KillTimer(TimerHeal[client]);
			TimerHeal[client] = INVALID_HANDLE;
		}
		
		if (IsValidEdict(client) && IsClientInGame(client))
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, "Blight_Form"))
			{
				FF2_SetFF2flags(client, FF2_GetFF2flags(client) | FF2FLAG_HUDDISABLED);
				StableMeter[client]=FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 9, 11);
				UnstableMeter[client]=FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 19, 11);
				HUDTimer[client] = CreateTimer(0.1, Timer_Hud, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
			
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			
			SDKHook(client, SDKHook_PreThink, ClientSpeed);
			
			if(FF2_HasAbility(idBoss, this_plugin_name, "Position_Teleport_Place"))
			{
				PointLockSelect[client] = 0;
				for (new TpSlot = 0; TpSlot <= 9; TpSlot++)
				{
					GetClientAbsOrigin(client, TpPoint[client][TpSlot]);
					
					bool HideWithForm = view_as<bool>(FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 6, 0));
					
					if (!HideWithForm)
					{
						HUDTimerTeleport[client] = CreateTimer(0.1, Timer_Hud_Teleport, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
					}
					
				}
			}
			if(FF2_HasAbility(idBoss, this_plugin_name, "Passive_Regen"))
			{
				float Rate = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Passive_Regen", 1, 0.7);
					
				TimerHeal[client] = CreateTimer(Rate, Timer_Regen, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (FF2_HasAbility(idBoss, this_plugin_name, "New_Attribute_On_Death"))
			{
				HUDTimerAttributeOnkill[client] = CreateTimer(0.1, Timer_Hud_Attr_On_Kill, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
				
				char classname[64], attr[132];
		
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 1+(10*WeaponOnDeath[client]), classname, sizeof(classname));
				int index = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 2+(10*WeaponOnDeath[client]), 0);
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 3+(10*WeaponOnDeath[client]), attr, sizeof(attr));
				int slot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 4+(10*WeaponOnDeath[client]), 0);
				bool RemoveAll = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 5+(10*WeaponOnDeath[client]), 0));
				bool Max = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", (10*WeaponOnDeath[client]), 0));
				
				if (!Max)
				{
					WeaponOnDeath[client] += 1;
				
					TF2_RemoveWeaponSlot(client, slot);
					
					if (RemoveAll)
						TF2_RemoveAllWeapons(client);
						
					if (StrEqual(classname,"tf_wearable_demoshield"))
						TF2_CreateAndEquipWearable(client, classname, index, 666, 13, attr);
					else
						FF2_SpawnWeapon(client, classname, index, 666, 13, attr, false);
				}
			}
		}
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;


	int idBoss = FF2_GetBossIndex(client);
	if (FF2_HasAbility(idBoss, this_plugin_name, "Blight_Form"))
	{
		if (ActionTimer[client]==0.0) 
		{
			char PluginName[64], AbilityName[64];
			int PluginSlot, Cost;
			char Sound[2048];
			if (FormMod[client]==0)
			{
				Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 55, 11);
				
				bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 57, 0));
			
				if (Cost<=StableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
				{
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 51, PluginName, sizeof(PluginName));
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 52, AbilityName, sizeof(AbilityName));
					PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 53, 11);
					
					FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
					ActionTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 24, 2.0);
					StableMeter[client] -= Cost;
					
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 56, Sound, sizeof(Sound));
					EmitSoundToAll(Sound, client);
				}
			}
			else if (FormMod[client]==1)
			{
				Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 105, 11);
				
				bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 107, 0));
			
				if (Cost<=UnstableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
				{
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 101, PluginName, sizeof(PluginName));
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 102, AbilityName, sizeof(AbilityName));
					PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 103, 11);
					
					FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
					ActionTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 104, 2.0);
					UnstableMeter[client] -= Cost;
					
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 106, Sound, sizeof(Sound));
					EmitSoundToAll(Sound, client);
				}
			}
		}
		return Plugin_Handled;
	}
	
	if (FF2_HasAbility(idBoss, this_plugin_name, "Summoned_Rage_Fixed"))
	{
		CreateTimer(0.2, Timer_Check_Rage, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_Check_Rage(Handle timer, int client)
{
	if (IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);
		if(FF2_HasAbility(idBoss, this_plugin_name, "Summoned_Rage_Fixed"))
		{
			char PluginName[64], AbilityName[64];
			int PluginSlot; 
			float Cost, RageNeeded, ClientRage;
			char Sound[2048];
			
			Cost = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Summoned_Rage_Fixed", 5, 100.0);
			RageNeeded = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Summoned_Rage_Fixed", 4, 100.0);
			ClientRage = FF2_GetBossCharge(idBoss, 0);
			
			if (RageNeeded<=ClientRage)
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Summoned_Rage_Fixed", 1, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Summoned_Rage_Fixed", 2, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Summoned_Rage_Fixed", 3, 0);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Summoned_Rage_Fixed", 6, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
				
				ClientRage -= Cost;
				FF2_SetBossCharge(idBoss, 0, ClientRage);
			}
		}
	}
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if (!PlayerCanChangeForm[client] || !IsPlayerAlive(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;
		
	int idBoss = FF2_GetBossIndex(client);
	if (!FF2_HasAbility(idBoss, this_plugin_name, "Blight_Form"))
		return Plugin_Continue;
				
	if (buttons & IN_ATTACK3 && SpecialTimer[client]==0.0) 
	{
		char PluginName[64], AbilityName[64];
		int PluginSlot, Cost;
		
		char Sound[2048];
		if (FormMod[client]==0)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 25, 11);
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 27, 0));
			
			if (Cost<=StableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 21, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 22, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 23, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				SpecialTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 24, 2.0);
				StableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 26, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
		else if (FormMod[client]==1)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 75, 11);
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 77, 0));
			
			if (Cost<=UnstableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 71, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 72, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 73, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				SpecialTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 74, 2.0);
				UnstableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 76, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
			
		}
	}
	
	if (buttons & IN_DUCK && CrtlTimer[client]==0.0) 
	{
		char PluginName[64], AbilityName[64];
		int PluginSlot, Cost;
		
		char Sound[2048];
		if (FormMod[client]==0)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 35, 11);
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 37, 0));
			
			if (Cost<=StableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 31, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 32, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 33, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				CrtlTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 34, 2.0);
				StableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 36, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
		else if (FormMod[client]==1)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 85, 11);
			
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 87, 0));
			
			if (Cost<=UnstableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 81, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 82, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 83, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				CrtlTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 84, 2.0);
				UnstableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 86, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
	}
	
	if (buttons & IN_ATTACK2 && AltFireTimer[client]==0.0) 
	{
		char PluginName[64], AbilityName[64];
		int PluginSlot, Cost;
		
		char Sound[2048];
		if (FormMod[client]==0)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 45, 11);
			
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 47, 0));
			
			if (Cost<=StableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 41, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 42, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 43, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				AltFireTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 44, 2.0);
				StableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 46, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
		else if (FormMod[client]==1)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 95, 11);
			
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 97, 0));
			
			if (Cost<=UnstableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 91, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 92, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 93, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				AltFireTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 94, 2.0);
				UnstableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 96, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
	}
	
	if (buttons & IN_RELOAD && ReloadTimer[client]==0.0) 
	{
		char PluginName[64], AbilityName[64];
		int PluginSlot, Cost;
		
		char Sound[2048];
		if (FormMod[client]==0)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 65, 11);
			
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 67, 0));
			
			if (Cost<=StableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 61, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 62, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 63, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				ReloadTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 64, 2.0);
				StableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 66, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
		else if (FormMod[client]==1)
		{
			Cost = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 115, 11);
			
			bool LockIfNotReady = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 117, 0));
			
			if (Cost<=UnstableMeter[client] && ((!LockIfNotReady) || (LockIfNotReady && ReloadTimer[client]==0.0 && AltFireTimer[client]==0.0 && ActionTimer[client]==0.0 && CrtlTimer[client]==0.0)))
			{
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 111, PluginName, sizeof(PluginName));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 112, AbilityName, sizeof(AbilityName));
				PluginSlot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 113, 11);
				
				FF2_DoAbility(idBoss, PluginName, AbilityName, PluginSlot);
				ReloadTimer[client]=FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Form", 114, 2.0);
				UnstableMeter[client] -= Cost;
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 116, Sound, sizeof(Sound));
				EmitSoundToAll(Sound, client);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Hud_Teleport(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, "Position_Teleport_Place"))
			{
				char TextToShow[1024];
				
				float x = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Position_Teleport_Place", 1, 0.0);
				float y = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Position_Teleport_Place", 2, 0.0);
				
				int R = FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 3, 0);
				int G = FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 4, 0);
				int B = FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 5, 0);
				
				bool HideWithForm = view_as<bool>(FF2_GetAbilityArgument(idBoss, this_plugin_name, "Position_Teleport_Place", 6, 0));
				
				Format(TextToShow, sizeof(TextToShow), "Current Teleport Slot: %i", (PointLockSelect[client]+1));
				
				if ((HideWithForm && FormMod[client]==1) || !HideWithForm)
				{
					Handle hHudText = CreateHudSynchronizer();
					SetHudTextParams(x, y, 0.11, R, G, B, 255);
					ShowSyncHudText(client, hHudText, TextToShow);
					CloseHandle(hHudText);
				}
			}
		}
		else
		{
			if (HUDTimerTeleport[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimerTeleport[client]);
				HUDTimerTeleport[client] = INVALID_HANDLE;
			}
		}
	}
	else
	{
		if (HUDTimerTeleport[client]!=INVALID_HANDLE)
		{
			KillTimer(HUDTimerTeleport[client]);
			HUDTimerTeleport[client] = INVALID_HANDLE;
		}
	}
}

public Action Timer_Hud_Attr_On_Kill(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, "New_Attribute_On_Death"))
			{
				char TextToShow[1024];
				
				char Pos[32][32], RGB[32][32], Position[1024], RGBA[1024];
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 7+(10*(WeaponOnDeath[client]-1)), TextToShow, sizeof(TextToShow));
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 8+(10*(WeaponOnDeath[client]-1)), RGBA, sizeof(RGBA));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 9+(10*(WeaponOnDeath[client]-1)), Position, sizeof(Position));
				
				ExplodeString(RGBA, " ; ", RGB, sizeof(RGB), sizeof(RGB));
				ExplodeString(Position, " ; ", Pos, sizeof(Pos), sizeof(Pos)); 
				
				float x = StringToFloat(Pos[0]);
				float y = StringToFloat(Pos[1]);
				
				int R = StringToInt(RGB[0]);
				int G = StringToInt(RGB[1]);
				int B = StringToInt(RGB[2]);
				
				ReplaceString(TextToShow, sizeof(TextToShow), "\\n", "\n");
				
				Handle hHudText5 = CreateHudSynchronizer();
				SetHudTextParams(x, y, 0.2, R, G, B, 255);
				ShowSyncHudText(client, hHudText5, TextToShow);
				CloseHandle(hHudText5);
			}
		}
		else
		{
			if (HUDTimerAttributeOnkill[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimerAttributeOnkill[client]);
				HUDTimerAttributeOnkill[client] = INVALID_HANDLE;
			}
		}
	}
	else
	{
		if (HUDTimerAttributeOnkill[client]!=INVALID_HANDLE)
		{
			KillTimer(HUDTimerAttributeOnkill[client]);
			HUDTimerAttributeOnkill[client] = INVALID_HANDLE;
		}
	}
}

public Action Timer_Hud(Handle timer, client)
{
	if (IsClientInGame(client))
	{
		if (IsPlayerAlive(client))
		{
			int idBoss = FF2_GetBossIndex(client);			
			if (FF2_HasAbility(idBoss, this_plugin_name, "Blight_Form"))
			{
				char Mana1Name[1024], Mana2Name[1024], TextToShow[1024];
				
				char Pos[32][32], RGB[32][32];
				
				char Ability1Reload[1024], Ability1Special[1024], Ability1Crtl[1024], Ability1AltFire[1024], Ability1Action[1024], Color1[32], Position1[32];
				char Ability2Reload[1024], Ability2Special[1024], Ability2Crtl[1024], Ability2AltFire[1024], Ability2Action[1024], Color2[32], Position2[32];
				
				char Meter1List[32][32], Meter2List[32][32], Meter1[32], Meter2[32];
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 1, Mana1Name, sizeof(Mana1Name));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 2, Ability1Reload, sizeof(Ability1Reload));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 3, Ability1Special, sizeof(Ability1Special));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 4, Ability1Crtl, sizeof(Ability1Crtl));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 5, Ability1AltFire, sizeof(Ability1AltFire));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 6, Ability1Action, sizeof(Ability1Action));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 7, Color1, sizeof(Color1));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 8, Position1, sizeof(Position1));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 10, Meter1, sizeof(Meter1));
				
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 11, Mana2Name, sizeof(Mana2Name));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 12, Ability2Reload, sizeof(Ability2Reload));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 13, Ability2Special, sizeof(Ability2Special));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 14, Ability2Crtl, sizeof(Ability2Crtl));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 15, Ability2AltFire, sizeof(Ability2AltFire));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 16, Ability2Action, sizeof(Ability2Action));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 17, Color2, sizeof(Color2));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 18, Position2, sizeof(Position2));
				FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Blight_Form", 20, Meter2, sizeof(Meter2));
				
				int Cost1Special = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 25, 11);
				int Cost2Special = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 75, 11);
				
				int Cost1Crtl = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 35, 11);
				int Cost2Crtl = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 85, 11);
				
				int Cost1AltFire = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 45, 11);
				int Cost2AltFire = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 95, 11);
				
				int Cost1Reload = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 65, 11);
				int Cost2Reload = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 115, 11);
				
				int Cost1Action = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 55, 11);
				int Cost2Action = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Form", 105, 11);
				
				if (GainMeterTimer[client]-0.1>0.0)
				{
					GainMeterTimer[client] -= 0.1;
				}
				else if (GainMeterTimer[client]-0.1<=0.0)
				{
					if (FormMod[client]==0)
					{
						ExplodeString(Meter1, " ; ", Meter1List, sizeof(Meter1List), sizeof(Meter1List));
						
						int Add = StringToInt(Meter1List[0]);
						int MaxMeter = StringToInt(Meter1List[2]);
						
						if (StableMeter[client]+Add>=MaxMeter)
						{
							StableMeter[client] = MaxMeter;
						}
						else
						{
							StableMeter[client] += Add;
							GainMeterTimer[client] = StringToFloat(Meter1List[1]);
						}
					}
					else
					{
						ExplodeString(Meter2, " ; ", Meter2List, sizeof(Meter2List), sizeof(Meter2List));
						int Add = StringToInt(Meter2List[0]);
						
						int MaxMeter = StringToInt(Meter2List[2]);
						
						if (UnstableMeter[client]+Add>=MaxMeter)
						{
							UnstableMeter[client] = MaxMeter;
						}
						else
						{
							UnstableMeter[client] += Add;
							GainMeterTimer[client] = StringToFloat(Meter2List[1]);
						}
						
					}
				}
				
				if (SpecialTimer[client]-0.1>0.0)
				{
					SpecialTimer[client] -= 0.1;
					Format(Ability1Special, sizeof(Ability1Special), "%s (%.2f)", Ability1Special, SpecialTimer[client]);
					Format(Ability2Special, sizeof(Ability2Special), "%s (%.2f)", Ability2Special, SpecialTimer[client]);
				}
				else if (SpecialTimer[client]-0.1<=0.0)
				{
					SpecialTimer[client] = 0.0;
					Format(Ability1Special, sizeof(Ability1Special), "%s [%i]", Ability1Special, Cost1Special);
					Format(Ability2Special, sizeof(Ability2Special), "%s [%i]", Ability2Special, Cost2Special);
				}
				
				if (ReloadTimer[client]-0.1>0.0)
				{
					ReloadTimer[client] -= 0.1;
					Format(Ability1Reload, sizeof(Ability1Reload), "%s (%.2f)", Ability1Reload, ReloadTimer[client]);
					Format(Ability2Reload, sizeof(Ability2Reload), "%s (%.2f)", Ability2Reload, ReloadTimer[client]);
				}
				else if (ReloadTimer[client]-0.1<=0.0)
				{
					ReloadTimer[client] = 0.0;
					Format(Ability1Reload, sizeof(Ability1Reload), "%s [%i]", Ability1Reload, Cost1Reload);
					Format(Ability2Reload, sizeof(Ability2Reload), "%s [%i]", Ability2Reload, Cost2Reload);
				}
				
				if (AltFireTimer[client]-0.1>0.0)
				{
					AltFireTimer[client] -= 0.1;
					Format(Ability1AltFire, sizeof(Ability1AltFire), "%s (%.2f)", Ability1AltFire, AltFireTimer[client]);
					Format(Ability2AltFire, sizeof(Ability2AltFire), "%s (%.2f)", Ability2AltFire, AltFireTimer[client]);
				}
				else if (AltFireTimer[client]-0.1<=0.0)
				{
					AltFireTimer[client] = 0.0;
					Format(Ability1AltFire, sizeof(Ability1AltFire), "%s [%i]", Ability1AltFire, Cost1AltFire);
					Format(Ability2AltFire, sizeof(Ability2AltFire), "%s [%i]", Ability2AltFire, Cost2AltFire);
				}
				
				if (ActionTimer[client]-0.1>0.0)
				{
					ActionTimer[client] -= 0.1;
					Format(Ability1Action, sizeof(Ability1Action), "%s (%.2f)", Ability1Action, ActionTimer[client]);
					Format(Ability2Action, sizeof(Ability2Action), "%s (%.2f)", Ability2Action, ActionTimer[client]);
				}
				else if (ActionTimer[client]-0.1<=0.0)
				{
					ActionTimer[client] = 0.0;
					Format(Ability1Action, sizeof(Ability1Action), "%s [%i]", Ability1Action, Cost1Action);
					Format(Ability2Action, sizeof(Ability2Action), "%s [%i]", Ability2Action, Cost2Action);
				}
				
				if (CrtlTimer[client]-0.1>0.0)
				{
					CrtlTimer[client] -= 0.1;
					Format(Ability1Crtl, sizeof(Ability1Crtl), "%s (%.2f)", Ability1Crtl, CrtlTimer[client]);
					Format(Ability2Crtl, sizeof(Ability2Crtl), "%s (%.2f)", Ability2Crtl, CrtlTimer[client]);
				}
				else if (CrtlTimer[client]-0.1<=0.0)
				{
					CrtlTimer[client] = 0.0;
					Format(Ability1Crtl, sizeof(Ability1Crtl), "%s [%i]", Ability1Crtl, Cost1Crtl);
					Format(Ability2Crtl, sizeof(Ability2Crtl), "%s [%i]", Ability2Crtl, Cost2Crtl);
				}
				
				
				if (FormMod[client]==0)
				{
					Format(TextToShow, sizeof(TextToShow), "%s%s: %i", TextToShow, Mana1Name, StableMeter[client]);
					Format(TextToShow, sizeof(TextToShow), "%s \n%s", TextToShow, Ability1Special);
					Format(TextToShow, sizeof(TextToShow), "%s \n%s ; %s", TextToShow, Ability1Reload, Ability1Action);
					Format(TextToShow, sizeof(TextToShow), "%s \n%s ; %s", TextToShow, Ability1Crtl, Ability1AltFire);
					ExplodeString(Color1, " ; ", RGB, sizeof(RGB), sizeof(RGB));
					ExplodeString(Position1, " ; ", Pos, sizeof(Pos), sizeof(Pos)); 
					
				}
				else if (FormMod[client]==1)
				{
					if(FF2_HasAbility(idBoss, this_plugin_name, "Position_Teleport_Place"))
					{
						Format(TextToShow, sizeof(TextToShow), "Current Teleport Slot: %i", (PointLockSelect[client]+1));
						Format(TextToShow, sizeof(TextToShow), "%s \n%s: %i", TextToShow, Mana2Name,UnstableMeter[client]);
					}
					else
						Format(TextToShow, sizeof(TextToShow), "%s%s: %i", TextToShow, Mana2Name,UnstableMeter[client]);
						
					Format(TextToShow, sizeof(TextToShow), "%s \n%s", TextToShow, Ability2Special);
					Format(TextToShow, sizeof(TextToShow), "%s \n%s ; %s", TextToShow, Ability2Reload, Ability2Action);
					Format(TextToShow, sizeof(TextToShow), "%s \n%s ; %s", TextToShow, Ability2Crtl, Ability2AltFire);
					ExplodeString(Color2, " ; ", RGB, sizeof(RGB), sizeof(RGB));
					ExplodeString(Position2, " ; ", Pos, sizeof(Pos), sizeof(Pos)); 
				}
				
				
				float x = StringToFloat(Pos[0]);
				float y = StringToFloat(Pos[1]);
				
				int R = StringToInt(RGB[0]);
				int G = StringToInt(RGB[1]);
				int B = StringToInt(RGB[2]);
				
				
				Handle hHudText1 = CreateHudSynchronizer();
				SetHudTextParams(x, y, 0.11, R, G, B, 255);
				ShowSyncHudText(client, hHudText1, TextToShow);
				CloseHandle(hHudText1);
			}
		}
		else
		{
			if (HUDTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimer[client]);
				HUDTimer[client] = INVALID_HANDLE;
			}
		}
	}
	else
	{
		if (HUDTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(HUDTimer[client]);
			HUDTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action Event_WinPanel(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if (IsClientInGame(client))
		{
			if (HUDTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimer[client]);
				HUDTimer[client] = INVALID_HANDLE;
			}
			
			if (HUDTimerTeleport[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimerTeleport[client]);
				HUDTimerTeleport[client] = INVALID_HANDLE;
			}
			
			if (HUDTimerAttributeOnkill[client]!=INVALID_HANDLE)
			{
				KillTimer(HUDTimerAttributeOnkill[client]);
				HUDTimerAttributeOnkill[client] = INVALID_HANDLE;
			}
			
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
						
			FF2_SetFF2flags(client, FF2_GetFF2flags(client) & (~FF2FLAG_HUDDISABLED));
			
			
			SDKUnhook(client, SDKHook_PreThink, ClientSpeed);
			
		}
	}
}

public void ClientSpeed(int client)
{
	if(IsClientInGame(client))
	{
		int idBoss = FF2_GetBossIndex(client);
		if(FF2_HasAbility(idBoss, this_plugin_name, "Blight_Change_Form"))
		{
			if (BlightSpeed[client]>0.0)
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BlightSpeed[client]);
		}
		
		if(BlightReverse[client])
		{
			float Distance = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"Blight_Reverse", 2, 200.0);
			int Projectile = -1; 
			while ((Projectile = FindEntityByClassname(Projectile, "tf_projectile_*")) != -1)
		    {
		    	if (IsValidEntity(Projectile))
		    	{
			    	float ProjectilePosition[3], ClientPosition[3];
			    	GetEntPropVector(Projectile, Prop_Data, "m_vecOrigin", ProjectilePosition);
			    	GetEntPropVector(client, Prop_Data, "m_vecOrigin", ClientPosition);
			    	
			    	if (GetVectorDistance(ProjectilePosition, ClientPosition) <= Distance)
			    	{
			    		if (GetEntProp(client, Prop_Data,"m_iTeamNum")!=GetEntProp(Projectile, Prop_Data,"m_iTeamNum"))
			    		{
			    			SetEntProp(Projectile, Prop_Data, "m_iTeamNum",GetEntProp(client, Prop_Data,"m_iTeamNum"));
			    			SetEntPropEnt(Projectile, Prop_Data, "m_hOwnerEntity",client);
			    			
			    			float ProjectileVelocity[3], ProjectileAngle[3];
			    			
			    			GetEntPropVector(Projectile, Prop_Data, "m_vecVelocity", ProjectileVelocity);
			    			GetEntPropVector(Projectile, Prop_Data, "m_angRotation", ProjectileAngle);
			    			
			    			ProjectileVelocity[0] *= -1.0;
			    			ProjectileVelocity[1] *= -1.0;
			    			ProjectileVelocity[2] *= -1.0;
			    			
			    			ProjectileAngle[0] *= -1.0;
			    			ProjectileAngle[1] *= -1.0;
			    			ProjectileAngle[2] *= -1.0;
			    			
			    			TeleportEntity(Projectile, ProjectilePosition, ProjectileAngle, ProjectileVelocity);
			    		}
			   		}
			    }
			}
		}
		
		if(FF2_HasAbility(idBoss, this_plugin_name, "New_Attribute_On_Death"))
		{
			
			float Speed = FF2_GetAbilityArgumentFloat(idBoss,this_plugin_name,"New_Attribute_On_Death", 6+(10*(WeaponOnDeath[client]-1)), 0.0);
			
			if (TF2_IsPlayerInCondition(client, TFCond_Charging))
				Speed *= 5.0;
			if (Speed>0.0)
				SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", Speed);
		}
		
		if (PhaseWalk[client])
		{
			for (new player = 1; player <= MaxClients; player++)
			{
				if (IsClientInGame(player))
				{
					if (IsPlayerAlive(player))
					{
						SetEntProp(player, Prop_Data, "m_CollisionGroup", 2);
					}
				}
			}
			for(int ient=1; ient<=2048; ient++) // 2048 = Max entities
		    {
				if (IsValidEdict(ient) && IsValidEntity(ient))
				{
					char sClassname[64];
					GetEdictClassname(ient, sClassname, sizeof(sClassname));
					if (strncmp(sClassname, "obj_",4)==0)
					{
						SetEntProp(ient, Prop_Data, "m_CollisionGroup", 2);
					}
				}
			}
		}
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;
	
	
	
	if (BlightReverse[client])
	{
		if (attacker>MaxClients)
		{
			char ClassName[1024];
			GetEntityClassname(attacker, ClassName, sizeof(ClassName));
			
			if (StrEqual(ClassName, "obj_sentrygun"))
			{
				int owner = GetEntPropEnt(attacker, Prop_Send, "m_hOwnerEntity");
				SDKHooks_TakeDamage(owner, client, client, damage, damagetype, weapon, damageForce, damagePosition);
			}
		}
		else
			SDKHooks_TakeDamage(attacker, client, client, damage, damagetype, weapon, damageForce, damagePosition);
	
		damage = 0.0;
		damageForce[0] = 0.0;
		damageForce[1] = 0.0;
		damageForce[2] = 0.0;
		return Plugin_Changed;
	}
	
	if (PhaseWalk[client])
	{
		damage = 0.0;
		damageForce[0] = 0.0;
		damageForce[1] = 0.0;
		damageForce[2] = 0.0;
		return Plugin_Changed;
	}
	
	int boss = FF2_GetBossIndex(attacker);
	if (TouchWeapon[attacker] && GetClientTeam(attacker)!=GetClientTeam(client))
	{
		GetClientAbsOrigin(client, BossSpawnPoint[client]);
		
		TFClassType ClientClass = TF2_GetPlayerClass(client);
		int BossIndex = 0;
		
		switch(ClientClass)
		{
			case TFClass_Scout: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 7, 1)-1;
			case TFClass_Sniper: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 8, 1)-1;
			case TFClass_Soldier: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 9, 1)-1;
			case TFClass_DemoMan: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 10, 1)-1;
			case TFClass_Medic: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 11, 1)-1;
			case TFClass_Heavy: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 12, 1)-1;
			case TFClass_Pyro: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 13, 1)-1;
			case TFClass_Spy: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 14, 1)-1;
			case TFClass_Engineer: BossIndex = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 15, 1)-1;
		}
		
		int IdBoss = 0;
		for(int playerBoss=1; playerBoss<=MaxClients; playerBoss++)
		{
			int BossCheck = FF2_GetBossIndex(playerBoss);
			if (BossCheck>-1)
			{
				if (BossCheck >= IdBoss)
					IdBoss = BossCheck+1;
			}
		}
		
		ChangeClientTeam(client, 3);
		
		ForcePlayerSuicide(client);
		
		ChangeClientTeam(client, 3);
		
		FF2_MakeBoss(client, IdBoss, BossIndex, false);
		
		CreateTimer(0.40, Timer_Respawn_Boss, client, TIMER_FLAG_NO_MAPCHANGE);
		
		char classname[64], attr[132];
		
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Touch", 4, classname, sizeof(classname));
		int index = FF2_GetAbilityArgument(boss,this_plugin_name,"Blight_Touch", 5, 0);
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "Blight_Touch", 6, attr, sizeof(attr));
		
		TF2_RemoveAllWeapons(attacker);
		FF2_SpawnWeapon(attacker, classname, index, 666, 13, attr, false);
		
		TouchWeapon[attacker]=false;
	}
	
	int idBoss = FF2_GetBossIndex(client);
	if(FF2_HasAbility(idBoss, this_plugin_name, "Blight_Dodge"))
	{
		int DodgeMax = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Dodge", 1, 75);
		int UnstableDodgeMax = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Dodge", 2, 100);
		int UnstableDodgeMin = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Blight_Dodge", 3, 10);
		
		if (UnstableMeter[client]>=UnstableDodgeMin && FormMod[client]==1)
		{
			int Chance = RoundToCeil(((DodgeMax * 1.0) / (UnstableDodgeMax * 1.0))* UnstableMeter[client]);
			if (UnstableMeter[client]>=UnstableDodgeMax)
				Chance = DodgeMax;
				
			if (Chance>=GetRandomInt(0,100))
			{
				damage = 0.0;
				damageForce[0] = 0.0;
				damageForce[1] = 0.0;
				damageForce[2] = 0.0;
				float pos[3];
				GetClientEyePosition(client, pos);
				pos[2] += 4.0;
				if((attacker > 0 && attacker <= MaxClients) && IsPlayerAlive(attacker))
				{
					TE_Particle(attacker, "miss_text", pos);
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Respawn_Boss(Handle timer, int client)
{
	TF2_RespawnPlayer(client);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.5);
	TeleportEntity(client, BossSpawnPoint[client], NULL_VECTOR, NULL_VECTOR);
}

stock TE_Particle(client, const char[] Name,float origin[3]=NULL_VECTOR, float start[3]=NULL_VECTOR, float angles[3]=NULL_VECTOR, int entindex=-1, int attachtype=-1, int attachpoint=-1, bool resetParticles=true, float delay=0.0)
{
    int tblidx = FindStringTable("ParticleEffectNames");
    if (tblidx==INVALID_STRING_TABLE) 
    {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    char tmp[256];
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    int i;
    for (i=0; i<count; i++)
    {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        if (StrEqual(tmp, Name, false))
        {
            stridx = i;
            break;
        }
    }
    if (stridx==INVALID_STRING_INDEX)
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
    if (entindex!=-1)
    {
        TE_WriteNum("entindex", entindex);
    }
    if (attachtype!=-1)
    {
        TE_WriteNum("m_iAttachType", attachtype);
    }
    if (attachpoint!=-1)
    {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }
    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);
    TE_SendToClient(client, delay);
}

public Action MakeAnImage(client, float duration, const char[] EffectName, int R, int G, int B, int A = 250)
{
	float clientPos[3] = 0.0;
	float clientAngles[3] = 0.0;
	float clientVel[3] = 0.0;
	GetClientAbsOrigin(client, clientPos);
	GetEntPropVector(client, Prop_Send, "m_angRotation", clientAngles);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVel);
	int animationentity = CreateEntityByName("prop_physics_multiplayer", -1);
	int particle = CreateEntityByName("info_particle_system", -1);
	if (IsValidEntity(animationentity))
	{
		char model[256];
		GetClientModel(client, model, 256);
		DispatchKeyValue(animationentity, "model", model);
		DispatchKeyValue(animationentity, "solid", "0");
		DispatchSpawn(animationentity);
		SetEntityMoveType(animationentity, MOVETYPE_FLYGRAVITY);
		AcceptEntityInput(animationentity, "TurnOn", animationentity, animationentity, 0);
		SetEntPropEnt(animationentity, Prop_Send, "m_hOwnerEntity", client, 0);
		if (GetEntProp(client, Prop_Send, "m_iTeamNum", 4, 0))
		{
			SetEntProp(animationentity, Prop_Send, "m_nSkin", GetClientTeam(client) + -2, 4, 0);
		}
		else
		{
			SetEntProp(animationentity, Prop_Send, "m_nSkin", GetEntProp(client, Prop_Send, "m_nForcedSkin", 4, 0), 4, 0);
		}
		SetEntProp(animationentity, Prop_Send, "m_nSequence", GetEntProp(client, Prop_Send, "m_nSequence", 4, 0), 4, 0);
		SetEntPropFloat(animationentity, Prop_Send, "m_flPlaybackRate", GetEntPropFloat(client, Prop_Send, "m_flPlaybackRate", 0), 0);
		DispatchKeyValue(client, "disableshadows", "1");
		TeleportEntity(animationentity, clientPos, clientAngles, clientVel);
		TeleportEntity(particle, clientPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", "animationentity");
		DispatchKeyValue(particle, "effect_name", EffectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start", -1, -1, 0);
		
		SetEntityRenderMode(animationentity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(animationentity, R, G, B, A);
		
		CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(animationentity), 2);
	}
}

public Action Timer_RemoveEntity(Handle timer, any:entid)
{
	int entity = EntRefToEntIndex(entid);
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		TeleportEntity(entity, OFF_THE_MAP, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(entity, "Kill", -1, -1, 0);
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("death_flags") & TF_DEATHFLAG_DEADRINGER)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;
		
	for (int player = 1; player <= MaxClients; player++)
	{
		if (IsClientInGame(player))
		{
			if (IsPlayerAlive(player))
			{
				int idBoss = FF2_GetBossIndex(player);
				if(FF2_HasAbility(idBoss, this_plugin_name, "Add_Meter_On_Death"))
				{
					int AddStableMeter = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Add_Meter_On_Death", 1, 10);
					int MaxStableMeter = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Add_Meter_On_Death", 2, 100);
					int AddUnstableMeter = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Add_Meter_On_Death", 3, 10);
					int MaxUnstableMeter = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Add_Meter_On_Death", 4, 100);
					
					
					if (FormMod[player]==0)
					{
						if (StableMeter[player]+AddStableMeter>=MaxStableMeter)
							StableMeter[player] = MaxStableMeter;
						else
							StableMeter[player] += AddStableMeter;
					}
					else
					{
						if (UnstableMeter[player]+AddUnstableMeter>=MaxUnstableMeter)
							UnstableMeter[player] = MaxUnstableMeter;
						else
							UnstableMeter[player] += AddUnstableMeter;
					}
				}
				
				if(FF2_HasAbility(idBoss, this_plugin_name, "New_Attribute_On_Death"))
				{
					char classname[64], attr[132];
		
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 1+(10*WeaponOnDeath[player]), classname, sizeof(classname));
					int index = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 2+(10*WeaponOnDeath[player]), 0);
					FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "New_Attribute_On_Death", 3+(10*WeaponOnDeath[player]), attr, sizeof(attr));
					int slot = FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 4+(10*WeaponOnDeath[player]), 0);
					bool RemoveAll = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", 5+(10*WeaponOnDeath[player]), 0));
					bool Max = view_as<bool>(FF2_GetAbilityArgument(idBoss,this_plugin_name,"New_Attribute_On_Death", (10*WeaponOnDeath[player]), 0));
					
					if (!Max)
					{
						WeaponOnDeath[player] += 1;
					
						TF2_RemoveWeaponSlot(player, slot);
						
						if (RemoveAll)
							TF2_RemoveAllWeapons(player);
							
						if (StrEqual(classname,"tf_wearable_demoshield"))
							TF2_CreateAndEquipWearable(player, classname, index, 666, 13, attr);
						else
							FF2_SpawnWeapon(player, classname, index, 666, 13, attr, false);
					}
				}
			}
		}
	}
}

stock AttachParticle(entity, char[] particleType, float offset[]={0.0,0.0,0.0}, bool attach=true)
{
	int  particle=CreateEntityByName("info_particle_system");

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
	return particle;
}

public Action RemoveEntity2(Handle timer, any:entid)
{
	int entity=EntRefToEntIndex(entid);
	if(IsValidEdict(entity) && entity>MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock int TF2_CreateAndEquipWearable(int client, const char[] classname, int index, int level, int quality, char[] attributes)
{
	int wearable;
	if(classname[0])
	{
		wearable = CreateEntityByName(classname);
	}
	else
	{
		wearable = CreateEntityByName("tf_wearable");
	}

	if(!IsValidEntity(wearable))
		return -1;

	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
	// Allow quality / level override by updating through the offset.
	static char netClass[64];
	GetEntityNetClass(wearable, netClass, sizeof(netClass));
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityQuality"), quality);
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityLevel"), level);

	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

	#if defined _tf2attributes_included
	if(attributes[0] && tf2attributes)
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(wearable, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
	#endif
		
	DispatchSpawn(wearable);
	SDK_EquipWearable(client, wearable);
	return wearable;
}

stock void SDK_EquipWearable(int client, int wearable)
{
	if(SDKEquipWearable != null)
		SDKCall(SDKEquipWearable, client, wearable);
}

stock int TF2_GetPlayerMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}