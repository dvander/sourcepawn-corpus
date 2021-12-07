#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MB 10
#define PEDO_SND "player/taunt_wormshhg.wav"
#define PYROGAS_SND "ambient/halloween/thunder_02.wav"
#define SCT_SND "weapons/ball_buster_break_01_crowd.wav"
#define ZEPH_SND "ambient/siren.wav"
#define POL_SND "misc/taps_02.wav"

new BossTeam=_:TFTeam_Blue;
new Handle:jumpHUD;
new bEnableSuperDuperJump[MB];
new Handle:OnHaleJump = INVALID_HANDLE;
new bool:bSalmon = false; 

public Plugin:myinfo = {
	name = "Freak Fortress 2: Saxtoner Ability Pack (1.2)",
	author = "Otokiru",
};

public OnPluginStart2()
{
	HookEvent("teamplay_round_start", event_round_start);
	HookEvent("player_death", event_player_death);
	jumpHUD = CreateHudSynchronizer();
	LoadTranslations("ff2_otokiru.phrases");
}

public OnMapStart()
{
	PrecacheSound("replay\\exitperformancemode.wav",true);
	PrecacheSound("replay\\enterperformancemode.wav",true);
	PrecacheSound(PEDO_SND,true);
	PrecacheSound(PYROGAS_SND,true);
	PrecacheSound(SCT_SND,true);
	PrecacheSound(ZEPH_SND,true);
	PrecacheSound(POL_SND,true);
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	OnHaleJump = CreateGlobalForward("VSH_OnDoJump", ET_Hook, Param_CellByRef);
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_nurse_bowrage"))
		Rage_Nurse(ability_name,index);						//Polish Nurse' Bow Rage
	else if (!strcmp(ability_name,"rage_scout"))
		Rage_Scout(ability_name,index);						//Scout Rage
	else if (!strcmp(ability_name,"rage_giftwrap"))
		Rage_Giftwrap(ability_name,index);					//giftwrap Rage		
	else if (!strcmp(ability_name,"rage_pedo"))	
		Rage_Pedo(ability_name,index);						//Pedo Rage
	else if (!strcmp(ability_name,"rage_pyrogas"))	
		Rage_Pyrogas(ability_name,index);					//Pyrogas Rage
	else if (!strcmp(ability_name,"charge_salmon"))
		Charge_Salmon(ability_name,index,1,action);			//Zep Mann
	else if (!strcmp(ability_name,"rage_abstractspy"))
		Rage_AbstractSpy(ability_name,index);				//AbstractSpy Rage
	else if (!strcmp(ability_name,"rage_gentlemen"))
		Rage_Gentlemen(ability_name,index);					//Gentlemen Rage
	return Plugin_Continue;
}

public Action:event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<MB;i++)
	{
		bEnableSuperDuperJump[i]=false;
	}
	bSalmon = false;
	return Plugin_Continue;
}

stock SpawnWeapon(client,String:name[],index,level,qual,String:att[])
{
	new Handle:hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	new String:atts[32][32];
	new count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		new i2 = 0;
		for (new i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==INVALID_HANDLE)
		return -1;
	new entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock SetAmmo(client, slot, ammo)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

Rage_Nurse(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//mode
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//sound
	new var3=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//ammo
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Primary);
	if(var1==0)
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_crossbow", 305, 100, 5, "6 ; 0.5 ; 37 ; 0.0 ; 2 ; 3.0 ; 134 ; 19 ; 37 ; 0.0"));
	else
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_crossbow", 305, 100, 5, "6 ; 0.5 ; 37 ; 0.0 ; 2 ; 3.0 ; 150 ; 1 ; 134 ; 19 ; 37 ; 0.0"));
	SetAmmo(Boss, TFWeaponSlot_Primary,var3);
	if(var2!=0)
	{
		EmitSoundToAll(POL_SND);
		EmitSoundToAll(POL_SND);
	}
}

Rage_Scout(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//mode
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//sound
	new var3=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//ammo
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
	if(var1==0)
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_bat_wood", 44, 100, 5, "2 ; 3.0 ; 134 ; 17 ; 38 ; 1 ; 37 ; 0.0"));
	else
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_bat_wood", 44, 100, 5, "2 ; 3.0 ; 350 ; 1 ; 134 ; 17 ; 38 ; 1 ; 37 ; 0.0"));
	SetAmmo(Boss, TFWeaponSlot_Melee,var3);
	if(var2!=0)
	{
		EmitSoundToAll(SCT_SND);
		EmitSoundToAll(SCT_SND);
	}
}

Rage_Giftwrap(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//mode
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//sound
	new var3=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//ammo
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Melee);
	if(var1==0)
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_bat_giftwrap", 648, 100, 5, "2 ; 3.0 ; 134 ; 17 ; 38 ; 1 ; 37 ; 0.0"));
	else
		SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_bat_giftwrap", 648, 100, 5, "2 ; 3.0 ; 350 ; 1 ; 134 ; 17 ; 38 ; 1 ; 37 ; 0.0"));
	SetAmmo(Boss, TFWeaponSlot_Melee,var3);
	if(var2!=0)
	{
		EmitSoundToAll(SCT_SND);
		EmitSoundToAll(SCT_SND);
	}
}

Rage_Pyrogas(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//sound
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//ammo
	TF2_RemoveWeaponSlot(Boss, TFWeaponSlot_Secondary);
	SetEntPropEnt(Boss, Prop_Send, "m_hActiveWeapon", SpawnWeapon(Boss, "tf_weapon_flaregun", 351, 100, 5, "2 ; 3.0 ; 25 ; 0.0 ; 207 ; 2 ; 144 ; 1 ; 99 ; 5 ; 134 ; 1"));
	SetAmmo(Boss, TFWeaponSlot_Secondary,var2);
	if(var1!=0)
	{
		EmitSoundToAll(PYROGAS_SND);
		EmitSoundToAll(PYROGAS_SND);
	}
}

Rage_Pedo(const String:ability_name[],index)
{
	decl Float:pos[3];
	decl Float:pos2[3];
	new var1=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//mode
	new var2=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//sound
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
	if(var2!=0)
	{
		EmitSoundToAll(PEDO_SND);
		EmitSoundToAll(PEDO_SND);
	}
	for(new i=1;i<=MaxClients;i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if(var1==0)
			{
				if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
					FakeClientCommand(i, "taunt");
			}
			else
			{
				if ((GetVectorDistance(pos,pos2)<ragedist))
					FakeClientCommand(i, "taunt");
			}
		}
}

Rage_Gentlemen(const String:ability_name[],index)
{
	decl Float:pos[3];
	decl Float:pos2[3];

	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	new Float:ragedist=FF2_GetRageDist(index,this_plugin_name,ability_name);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
			if (!TF2_IsPlayerInCondition(i,TFCond_Ubercharged) && (GetVectorDistance(pos,pos2)<ragedist))
			{
				EmitSoundToAll("replay\\enterperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
				ChangeClientTeam(i, BossTeam);
				CreateTimer(1.0, JoinKarkan, i);
				CreateTimer(6.0, Back2Karkan, i);
			}
		}
	}

	decl Float:pos_2[3];
	decl target;
	new pingas;
	new bool:RedAlivePlayers;
	for(new ii=1;ii<=MaxClients;ii++)
		if(IsValidEdict(ii) && IsClientInGame(ii) && IsPlayerAlive(ii) && GetClientTeam(ii)!=BossTeam)
		{
			RedAlivePlayers=true;
			break;
		}
	do
	{
		pingas++;
		target=GetRandomInt(1,MaxClients);
		if (pingas==100)
			return;
	}
	while (RedAlivePlayers && (!IsValidEdict(target) || (target==Boss) || !IsPlayerAlive(target)));
	
	if (IsValidEdict(target))
	{
		GetEntPropVector(target, Prop_Data, "m_vecOrigin", pos_2);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos_2);
		if (GetEntProp(target, Prop_Send, "m_bDucked"))
		{
			decl Float:collisionvec[3];
			collisionvec[0] = 24.0;
			collisionvec[1] = 24.0;
			collisionvec[2] = 62.0;
			SetEntPropVector(Boss, Prop_Send, "m_vecMaxs", collisionvec);
			SetEntProp(Boss, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(Boss, FL_DUCKING);
		}
		TeleportEntity(Boss, pos_2, NULL_VECTOR, NULL_VECTOR);
	}
}

public Action:JoinKarkan(Handle:timer, any:i)
{
	if(IsClientInGame(i))
	{
		FF2_SetFF2flags(i,FF2_GetFF2flags(i)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		decl Float:pos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", pos);
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
		ChangeClientTeam(i, BossTeam);
		TF2_RespawnPlayer(i);
		if (GetEntProp(i, Prop_Send, "m_bDucked"))
		{
			decl Float:collisionvec[3];
			collisionvec[0] = 24.0;
			collisionvec[1] = 24.0;
			collisionvec[2] = 62.0;
			SetEntPropVector(i, Prop_Send, "m_vecMaxs", collisionvec);
			SetEntProp(i, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(i, FL_DUCKING);
		}
		TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
		TF2_AddCondition(i, TFCond_Ubercharged, 1.0);
	}
}

public Action:Back2Karkan(Handle:timer, any:i)
{
	if(IsClientInGame(i) && IsPlayerAlive(i))
	{
		EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
		EmitSoundToAll("replay\\exitperformancemode.wav", _, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, _, NULL_VECTOR, false, 0.0);
		decl Float:pos[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", pos);
		GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos);
		ChangeClientTeam(i, _:TFTeam_Red);
		TF2_RespawnPlayer(i);
		if (GetEntProp(i, Prop_Send, "m_bDucked"))
		{
			decl Float:collisionvec[3];
			collisionvec[0] = 24.0;
			collisionvec[1] = 24.0;
			collisionvec[2] = 62.0;
			SetEntPropVector(i, Prop_Send, "m_vecMaxs", collisionvec);
			SetEntProp(i, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(i, FL_DUCKING);
		}
		TeleportEntity(i, pos, NULL_VECTOR, NULL_VECTOR);
	}
}

Rage_AbstractSpy(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,1,18.0);
	if(IsClientInGame(Boss) && IsPlayerAlive(Boss))
	{
		TF2_DisguisePlayer(Boss, TFTeam_Red, TFClassType:GetRandomInt(1,9));
		CreateTimer(duration, RemoveDisguise, Boss);
	}
}

public Action:RemoveDisguise(Handle:timer, any:index)
{
	if(IsClientInGame(index) && IsPlayerAlive(index))
		TF2_RemovePlayerDisguise(index);
}

Charge_Salmon(const String:ability_name[],index,slot,action)
{
	new Float:charge=FF2_GetBossCharge(index,slot);
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new var3=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 3);	//sound
	new var4=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4);	//summon_per_rage
	new Float:duration=FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name,5,3.0); //uber_protection

	switch (action)
	{
		case 1:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(Boss, jumpHUD, "%t","salmon_status_2",-RoundFloat(charge));
		}	
		case 2:
		{
			SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
			if (bEnableSuperDuperJump[index])
			{
				SetHudTextParams(-1.0, 0.88, 0.15, 255, 64, 64, 255);
				ShowSyncHudText(Boss, jumpHUD,"%t","super_duper_jump");
			}	
			else
				ShowSyncHudText(Boss, jumpHUD, "%t","salmon_status",RoundFloat(charge));
		}
		case 3:
		{
			new Action:act = Plugin_Continue;
			new super = bEnableSuperDuperJump[index];
			Call_StartForward(OnHaleJump);
			Call_PushCellRef(super);
			Call_Finish(act);
			if (act != Plugin_Continue && act != Plugin_Changed)
				return;
			if (act == Plugin_Changed) bEnableSuperDuperJump[index] = super;
			
			if (bEnableSuperDuperJump[index])
			{
				decl Float:vel[3];
				decl Float:rot[3];
				GetEntPropVector(Boss, Prop_Data, "m_vecVelocity", vel);
				GetClientEyeAngles(Boss, rot);
				vel[2]=750.0+500.0*charge/70+2000;
				vel[0]+=Cosine(DegToRad(rot[0]))*Cosine(DegToRad(rot[1]))*500;
				vel[1]+=Cosine(DegToRad(rot[0]))*Sine(DegToRad(rot[1]))*500;
				bEnableSuperDuperJump[index]=false;
				TeleportEntity(Boss, NULL_VECTOR, NULL_VECTOR, vel);
			}
			else
			{
				if(var3!=0)
				{
					EmitSoundToAll(ZEPH_SND);
					EmitSoundToAll(ZEPH_SND);
				}
				
				new ii;
				for (new i=0; i<var4; i++)
				{
					ii = GetRandomDeadPlayer();
					if(ii != -1)
					{
						bSalmon = true;
						FF2_SetFF2flags(ii,FF2_GetFF2flags(ii)|FF2FLAG_ALLOWSPAWNINBOSSTEAM);
						ChangeClientTeam(ii,BossTeam);
						TF2_RespawnPlayer(ii);
						TF2_AddCondition(ii, TFCond_Ubercharged, duration);
					}
				}
			}			
		}
	}
}

stock GetRandomDeadPlayer()
{
	new clients[MaxClients+1], clientCount;
	for(new i=1;i<=MaxClients;i++)
	{
		if (IsValidEdict(i) && IsClientConnected(i) && IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) > 1))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public Action:Timer_ResetCharge(Handle:timer, any:index)
{
	new slot=index%10000;
	index/=1000;
	FF2_SetBossCharge(index,slot,0.0);
}

public Action:FF2_OnTriggerHurt(index,triggerhurt,&Float:damage)
{
	bEnableSuperDuperJump[index]=true;
	if (FF2_GetBossCharge(index,1)<0)
		FF2_SetBossCharge(index,1,0.0);
	return Plugin_Continue;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (bSalmon)
	{
		new client=GetClientOfUserId(GetEventInt(event, "userid"));
		new isBoss=FF2_GetBossIndex(client);
		if (isBoss!=-1)
		{
			for(new ii=1; ii<=MaxClients; ii++)
			{
				if(IsClientInGame(ii) && IsClientConnected(ii) && IsPlayerAlive(ii) && (GetClientTeam(ii)==BossTeam))
				{
					ChangeClientTeam(ii,2);
				}
			}
			bSalmon = false;
		}
	}
}