#include <sourcemod>
//#include <basestock>
//#include <database>
#include <sdktools>
#include <sdkhooks>

#define LoopIngamePlayers(%1) for(new %1=1;%1<=MaxClients;++%1) if(IsClientInGame(%1) && !IsFakeClient(%1))

new g_Turrets[MAXPLAYERS+1]={-1,...};
new bool:g_TurretCanShoot[MAXPLAYERS+1]={true,...};
new Float:g_fTurretAim[MAXPLAYERS+1]={0.0,...};
new bool:g_bTurretAim[MAXPLAYERS+1]={true,...};
//new Float:MinNadeHull[3] = {-2.5, -2.5, -2.5};
//new Float:MaxNadeHull[3] = {5.5, 5.5, 5.5};
new bool:g_BringTurret[MAXPLAYERS+1]={false,...};
new bool:g_TurretupedPlayer[MAXPLAYERS+1]={false,...};
new g_Turretuped[MAXPLAYERS+1]={false,...};
new g_TurretLevel[MAXPLAYERS+1]={1,...};
new g_TurretHealth[MAXPLAYERS+1]={1,...};
new g_BeamSprite;
new g_HaloSprite;

new TestMode = 0

new sd_turret_health1 = 300
new sd_turret_health2 = 500
new sd_turret_Upgrade1 = 5000
new sd_turret_Upgrade2 = 5000
new sd_turret_damage1 = 5
new sd_turret_damage2 = 4
new sd_turret_glow = 1
new sd_turret_collision = 0
new sd_turret_enable = 1
new Float:sd_turret_rate1 = 0.5
new Float:sd_turret_rate2 = 0.3
new sd_turret_lessdamage = 20
new sd_turret_knife = 1
new String:sd_turret_map[64] = "35hp_,mg_,ka_,he_,taser_,dr_"
new sd_turret_dead = 0

new bool:TestPlayer[MAXPLAYERS+1]={false,...};

#define PLUGIN_VERSION 		"0.1 Beta"
public Plugin:myinfo ={
	name = "Turret 10%",
	author = "Tast - SDC",
	description = "Auto Turrets",
	version = PLUGIN_VERSION,
	url = "http://tast.xclub.tw/viewthread.php?tid=98"
};

public OnPluginStart(){
	CreateConVar("SDC_Turret_Version", PLUGIN_VERSION, "",FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	HookEvent("round_start", OnRoundStart);
	//HookEvent("player_spawn", Hook_PlayerSpawn); //Knife Check
	
	RegConsoleCmd("turret", CreateTurret);
	//RegAdminCmd("turret2"	, CreateTurret2, ADMFLAG_ROOT, "");
	//RegAdminCmd("turret3"	, test19, ADMFLAG_ROOT, "");
	RegAdminCmd("turret4"	, test20, ADMFLAG_ROOT, "");
	
	HookConVarChange(	CreateConVar("sd_turret_enable"		, 	"1"			, "啟動機槍塔")					, Cvar_Enable);
	HookConVarChange(	CreateConVar("sd_turret_health1"	, 	"300"		, "機槍第1級生命值")			, Cvar_Health1);
	HookConVarChange(	CreateConVar("sd_turret_health2"	, 	"500"		, "機槍第2級生命值")			, Cvar_Health2);
	HookConVarChange(	CreateConVar("sd_turret_Upgrade1"	, 	"5000"		, "機槍第1級購買金額")			, Cvar_Upgrade1);
	HookConVarChange(	CreateConVar("sd_turret_Upgrade2"	, 	"5000"		, "機槍第2級升級金額")			, Cvar_Upgrade1);
	HookConVarChange(	CreateConVar("sd_turret_damage1"	, 	"5"			, "機槍第1級打人傷害")			, Cvar_Damage1);
	HookConVarChange(	CreateConVar("sd_turret_damage2"	, 	"4"			, "機槍第2級打人傷害")			, Cvar_Damage2);
	HookConVarChange(	CreateConVar("sd_turret_glow"		, 	"1"			, "機槍發光")					, Cvar_Glow);
	HookConVarChange(	CreateConVar("sd_turret_collision"	, 	"0"			, "機槍為實體")					, Cvar_Collision);
	HookConVarChange(	CreateConVar("sd_turret_rate1"		, 	"0.5"		, "機槍第1級開槍間隔")			, Cvar_Rate1);
	HookConVarChange(	CreateConVar("sd_turret_rate2"		, 	"0.3"		, "機槍第2級開槍間隔")			, Cvar_Rate2);
	HookConVarChange(	CreateConVar("sd_turret_lessdamage"	, 	"20"		, "機槍每次被傷害上限")			, Cvar_LessDamage);
	HookConVarChange(	CreateConVar("sd_turret_knife"		, 	"1"			, "自動檢測拿刀戰")				, Cvar_KnifeCheck);
	HookConVarChange(	CreateConVar("sd_turret_map"		,sd_turret_map	, "特定地圖自動關閉")			, Cvar_MapCheck);
	HookConVarChange(	CreateConVar("sd_turret_dead"		,	"0"			, "死後機槍塔自暴")				, Cvar_DeadGone); //尚未使用
	
	new String:PW[32]
	GetConVarString(FindConVar("sv_password"),PW,sizeof(PW))
	if(StrEqual(PW,"ccc",false)) TestMode = 1
	
	MapChecking()
}

public Cvar_Enable(Handle:convar, const String:oldValue[], const String:newValue[])		{ sd_turret_enable		= StringToInt(newValue); }
public Cvar_Health1(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_health1		= StringToInt(newValue); }
public Cvar_Health2(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_health2		= StringToInt(newValue); }
public Cvar_Upgrade1(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_Upgrade1	= StringToInt(newValue); }
public Cvar_Upgrade2(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_Upgrade2	= StringToInt(newValue); }
public Cvar_Damage1(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_damage1		= StringToInt(newValue); }
public Cvar_Damage2(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_damage2		= StringToInt(newValue); }
public Cvar_Glow(Handle:convar, const String:oldValue[], const String:newValue[])		{ sd_turret_glow		= StringToInt(newValue); }
public Cvar_Collision(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_collision	= StringToInt(newValue); }
public Cvar_Rate1(Handle:convar, const String:oldValue[], const String:newValue[])		{ sd_turret_rate1		= StringToFloat(newValue); }
public Cvar_Rate2(Handle:convar, const String:oldValue[], const String:newValue[])		{ sd_turret_rate2		= StringToFloat(newValue); }
public Cvar_LessDamage(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_lessdamage	= StringToInt(newValue); }
public Cvar_KnifeCheck(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_knife		= StringToInt(newValue); }
public Cvar_MapCheck(Handle:convar, const String:oldValue[], const String:newValue[])	{ strcopy(sd_turret_map, sizeof(sd_turret_map), newValue); MapChecking();}
public Cvar_DeadGone(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_turret_dead		= StringToInt(newValue); }

new TurretKnifeChecking = false
new TurretMapChecking = false
public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	for(new i=1;i<64;++i){
		g_Turrets[i] = -1;
		g_TurretCanShoot[i] = true;
		g_BringTurret[i] = false;
		g_TurretupedPlayer[i] = false;
		g_Turretuped[i] = false;
		g_TurretLevel[i] = 1
		TestPlayer[i] = false
		
		if(IsClientInGame(i) && IsPlayerAlive(i) && sd_turret_knife){
			new String:WeaponName[32]
			GetClientWeapon(i, WeaponName, sizeof(WeaponName));
			if(StrEqual(WeaponName,"weapon_knife",false)){
				if(TestMode) PrintToChat(i,"W:%s",WeaponName)
				TurretKnifeChecking = true
			}
			else TurretKnifeChecking = false
		}
	}
	CreateTimer(0.15, KnifeChecking);
}

public Action:KnifeChecking(Handle:Timer, any:ent){
	for(new i=1;i<64;++i){
		if(IsClientInGame(i) && IsPlayerAlive(i) && sd_turret_knife){
			new String:WeaponName[32]
			GetClientWeapon(i, WeaponName, sizeof(WeaponName));
			if(StrEqual(WeaponName,"weapon_knife",false)){
				if(TestMode) PrintToChat(i,"W:%s",WeaponName)
				TurretKnifeChecking = true
			}
			else TurretKnifeChecking = false
		}
	}
}

public Action:test20(client, args){
	MapChecking(client)
}

public Action:test19(client, args){
	TestPlayer[client] = true
}

public Action:CreateTurret2(client, args){
	new ent = CreateEntityByName("prop_dynamic_glow");
	if(ent != -1){
		PrecacheModel("models/models/npcs/turret/turret.mdl");
		SetEntityModel(ent, "models/models/npcs/turret/turret.mdl");
		
		decl Float:pos[3], Float:angle[3], Float:vecDir[3];
		
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, pos); 
		
		pos[0]+=vecDir[0]*100.0;
		pos[1]+=vecDir[1]*100.0;
		pos[2]-=60.0;
		angle[0]=0.0;
		TeleportEntity(ent, pos, angle, NULL_VECTOR);
	}
}

public Action:CreateTurret(client, args){
	if(!sd_turret_enable || (sd_turret_knife && TurretKnifeChecking) || TurretMapChecking){
		PrintToChat(client, "機槍塔關閉!");
		PrintHintText(client, "機槍塔關閉!");
		if(!TestMode ||( TestMode && !GetUserFlagBits(client) && ADMFLAG_ROOT)) return;
	}
	if(TestMode && GetUserFlagBits(client) && ADMFLAG_ROOT) SetEntProp(client, Prop_Data, "m_takedamage",1, 1);
	
	if(g_Turrets[client] != -1){
		PrintToChat(client, "你已經擁有了1台機槍塔!");
		PrintHintText(client, "你已經擁有了1台機槍塔!");
		if(!TestMode ||( TestMode && !GetUserFlagBits(client) && ADMFLAG_ROOT)) return;
	}
	else if(!IsPlayerAlive(client)){
		PrintHintText(client,"死後禁止使用機槍塔.")
		if(!TestMode ||( TestMode && !GetUserFlagBits(client) && ADMFLAG_ROOT)) return;
	}
	else if(GetMoney(client) >= sd_turret_Upgrade1){
		SetMoney(client,GetMoney(client) - sd_turret_Upgrade1)
		PrintHintText(client,"E鍵可移動機槍塔.")
		PrintToChat(client, "觸碰別人機槍塔可幫人升級.");
	}
	else {
		PrintToChat(client, "不夠錢購買機槍塔!");
		PrintHintText(client,"不夠錢購買機槍塔")
		if(!TestMode ||( TestMode && !GetUserFlagBits(client) && ADMFLAG_ROOT)) return;
	}
	
	new ent = CreateEntityByName("prop_dynamic_glow");
	//new ent = CreateEntityByName("prop_physics_override");
	//new ent = CreateEntityByName("prop_dynamic_override");
	if(ent != -1){
		//PrecacheModel("models/props/turret_01.mdl");
		//if(TestMode) SetEntityModel(ent, "models/props/turret_01.mdl");
		/*else */
		SetEntityModel(ent, "models/Combine_turrets/floor_turret.mdl");
		
		if(GetClientTeam(client) == 2){ //TS
			DispatchKeyValue(ent, "skin","1");
			DispatchKeyValue(ent, "glowcolor", "128 128 64");
		}
		else if(GetClientTeam(client) == 3){ //CT
			DispatchKeyValue(ent, "skin","2");
			DispatchKeyValue(ent, "glowcolor", "102 153 255");
		}
		else DispatchKeyValue(ent, "glowcolor", "204 0 51");
		
		SetEntProp(ent, Prop_Send, "m_nSolidType", 6 );
		if(sd_turret_collision) SetEntProp(ent, Prop_Data, "m_CollisionGroup", 6); //http://forums.alliedmods.net/showpost.php?p=715655&postcount=6
		if(sd_turret_collision) SetEntProp(ent, Prop_Send, "m_CollisionGroup", 6);
		AcceptEntityInput( ent, "DisableCollision" );
		AcceptEntityInput( ent, "EnableCollision" );
		
		//DispatchKeyValue(ent, "spawnflags", "32");		//Break on Pressure
		DispatchKeyValue(ent, "ExplodeDamage", "100");
		DispatchKeyValue(ent, "ExplodeRadius", "100");
		if(sd_turret_glow) DispatchKeyValue(ent, "glowenabled", "1");
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client) );
		DispatchSpawn(ent);
		SetVariantInt(sd_turret_health1);
		AcceptEntityInput(ent, "SetHealth", -1, -1, 0);
		
		HookSingleEntityOutput(ent, "OnBreak", OnBreak, false);
		HookSingleEntityOutput(ent, "OnAnimationDone", OnAnimationDone, false);
		//HookSingleEntityOutput(ent, "OnAnimationBegun", OnAnimationBegun, false);
		
		g_TurretHealth[client] = sd_turret_health1
		
		//SetVariantString("idlealert"); 	//m_nSequence = 2
		//SetVariantString("fire");			//m_nSequence = 3 none use
		//SetVariantString("retract");		//m_nSequence = 4
		SetVariantString("deploy");			//m_nSequence = 1
		//AcceptEntityInput(ent, "SetDefaultAnimation", -1, -1, 0);
		AcceptEntityInput(ent, "SetAnimation", -1, -1, 0);
		
		SDKHook(ent, SDKHook_Touch, TurretTouch);
		SDKHook(ent, SDKHook_OnTakeDamage, TurretTakeDamage);
		
		//--------------------------------------
		decl Float:pos[3], Float:angle[3], Float:vecDir[3];
		
		GetClientEyeAngles(client, angle);
		GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, pos); 
		
		pos[0]+=vecDir[0]*100.0;
		pos[1]+=vecDir[1]*100.0;
		pos[2]-=60.0;
		angle[0]=0.0;
		TeleportEntity(ent, pos, angle, NULL_VECTOR);
		g_Turrets[client]=ent;
		
		if(GetRandomInt(1,0))
				EmitSoundToAll("training/gallery_stop.wav",ent,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,pos,NULL_VECTOR,true,0.0);
		else 	EmitSoundToAll("training/light_on.wav",ent,SNDCHAN_AUTO,SNDLEVEL_NORMAL,SND_NOFLAGS,SNDVOL_NORMAL,SNDPITCH_NORMAL,-1,pos,NULL_VECTOR,true,0.0);
		
		CreateTimer(1.0, TurretStarted, ent);
		//--------------------------------------
		//DispatchKeyValue(ent, "MaxAnimTime", "0.1");
		//DispatchKeyValue(ent, "AnimateEveryFrame", "1");
		//DispatchKeyValue(ent, "HoldAnimation", "1");
		//SetEntProp(ent, Prop_Send, "movetype", 2);
		//SetEntProp(ent, Prop_Send, "movecollide", 0);
		//SetEntPropFloat(ent, Prop_Send, "m_flCycle", 0.1);
		
		//SetVariantFloat(0.2)
		//AcceptEntityInput(ent, "SetPlaybackRate", -1, -1, 0);
	}
	else PrintToChat(client, "Invalid enttiy:(");
}

public Action:TurretStarted(Handle:Timer, any:ent){ g_Turrets[GetOwner(ent)] = ent; }
public Action:TurretTakeDamageReset(Handle:Timer, any:ent){	SDKHook(ent, SDKHook_OnTakeDamage, TurretTakeDamage); }
public Action:TurretTakeDamage(Ent, &attacker, &inflictor, &Float:damage, &damagetype){
	if(GetClientTeam(attacker) == GetTeam(Ent)) return;
	SDKUnhook(Ent, SDKHook_OnTakeDamage, TurretTakeDamage);
	
	new owner = GetEntPropEnt(Ent, Prop_Data, "m_hOwnerEntity")
	//if(TestMode) PrintToChat(owner,"Damage:%f",damage);
	new dmg = (damage > float(sd_turret_lessdamage)) ? sd_turret_lessdamage:RoundToZero(damage)
	
	if(g_TurretHealth[owner] <= 0){
		AcceptEntityInput(Ent, "Break", -1, -1, 0);
		BreakTurret(Ent,attacker)
	}
	else g_TurretHealth[owner] -= dmg
	if(TestMode) PrintToChat(owner,"[%d]Damage:%d",g_TurretHealth[owner],dmg);
	
	CreateTimer(0.1, TurretTakeDamageReset, Ent);
}

public Action:UpgradeReset(Handle:Timer, any:data){	SDKHook(data, SDKHook_Touch, TurretTouch);}
public TurretTouch(Ent, client){
	new owner = GetEntPropEnt(Ent, Prop_Data, "m_hOwnerEntity")
	if(client > 0 && client < 65){
		if(IsClientInGame(client)){
			SDKUnhook(Ent, SDKHook_Touch, TurretTouch);
			if(TestMode) PrintToChat(owner,"Toched:%d",client);
			if(g_BringTurret[owner]) return;
			if(GetTeam(Ent) != GetClientTeam(client)){ }
			if(GetTeam(Ent) == GetClientTeam(client) && !g_Turretuped[owner] && !g_TurretupedPlayer[client] && GetMoney(client) > sd_turret_Upgrade2){
				SetVariantInt(sd_turret_health2);AcceptEntityInput(Ent, "SetHealth", -1, -1, 0);
				SetMoney(client,GetMoney(client) - sd_turret_Upgrade2)
				
				g_Turretuped[owner] = 1
				g_TurretLevel[owner] = 2
				g_TurretupedPlayer[client] = true
				g_TurretHealth[client] = sd_turret_health2
				
				SetVariantInt(sd_turret_health2);
				AcceptEntityInput(Ent, "SetHealth", -1, -1, 0);
				
				new String:OwnerName[32],String:ClientName[32]
				GetClientName(owner,OwnerName,sizeof(OwnerName))
				GetClientName(client,ClientName,sizeof(ClientName))
				
				PrintToChat(owner,"\x04%s \x01為你升級了機槍塔",ClientName);
				PrintHintText(owner,"%s 為你升級了機槍塔",ClientName);
				PrintToChat(client,"\x01你幫 \x04%s \x01升級了機槍塔",OwnerName);
				PrintHintText(client,"你幫 %s 升級了機槍塔",OwnerName);
			}
			CreateTimer(0.2, UpgradeReset, Ent);
		}
	}
}

public OnAnimationDone(const String:output[], caller, activator, Float:delay){
	if(IsValidEntity(caller)){
		new sequence = GetEntProp(caller, Prop_Data, "m_nSequence");
		new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity")
		if(TestMode){
			PrintToChat(owner,"Done:%i,%d", sequence,GetEntProp(caller, Prop_Data, "m_iTeamNum"));
		}
		
		SetVariantString("idlealert");
		AcceptEntityInput(caller, "SetAnimation", -1, -1, 0);
	}
}

public OnBreak(const String:output[], caller, activator, Float:delay){ BreakTurret(caller,activator); }

public BreakTurret(caller,activator){
	new owner = GetOwner(caller)
	g_Turrets[owner] = -1;
	g_TurretCanShoot[owner] = true;
	g_BringTurret[owner] = false;
	
	if(IsClientInGame(owner)){
		if(IsClientInGame(activator)){
			new String:Breaker[64]
			GetClientName(activator, Breaker, sizeof(Breaker));
			PrintToChat(owner,"\x01你的機槍塔被 \x04%s 摧毀.",Breaker)
			PrintHintText(owner,"你的機槍塔被 %s 摧毀.",Breaker)
		}
		else {
			PrintToChat(owner,"\x01機槍塔已被\x04摧毀\x01.")
			PrintHintText(owner,"機槍塔已被摧毀.")
		}
	}
}

public OnGameFrame(){
	LoopIngamePlayers(i){
		if(g_Turrets[i] !=-1  && IsValidEntity(g_Turrets[i])) TickTurret(i);
	}
}

TickTurret(client){
	//new ClosestEnemy;
	//new Float:EnemyDistance;
	decl Float:TurretPos[3];
	
	GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecOrigin", TurretPos);
	new iTeam = GetTeam(g_Turrets[client])
	for(new i=1;i<MaxClients;++i){
		if(IsClientInGame(i) && IsPlayerAlive(i)) if (GetClientTeam(i) != iTeam || TestPlayer[i]){
			decl Float:EnemyPos[3];
			GetClientEyePosition(i, EnemyPos);
			new Float:m_vecMins[3];
			new Float:m_vecMaxs[3];
			GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecMins", m_vecMins);
			GetEntPropVector(g_Turrets[client], Prop_Send, "m_vecMaxs", m_vecMaxs);
			
			TR_TraceHullFilter(TurretPos, EnemyPos, m_vecMins, m_vecMaxs, MASK_SOLID, DontHitOwnerOrNade, client);
			if(TR_GetEntityIndex() == i){
				TurretTickFollow(client, i);
				return;
			}
		}
	}
	TurretTickIdle(client);
}

TurretTickIdle(client){
	if(g_fTurretAim[client] <= 0.1) g_bTurretAim[client] = true;
	if(g_fTurretAim[client] >= 0.9) g_bTurretAim[client] = false;	
	
	if(g_bTurretAim[client])
			g_fTurretAim[client] = FloatAdd(g_fTurretAim[client], 0.01);
	else 	g_fTurretAim[client] = FloatSub(g_fTurretAim[client], 0.01);
	
	SetEntPropFloat(g_Turrets[client], Prop_Send, "m_flPoseParameter", g_fTurretAim[client], 0);
	SetEntPropFloat(g_Turrets[client], Prop_Send, "m_flPoseParameter", 0.5, 1);
}

TurretTickFollow(owner, player){
	decl Float:TurretPos[3],Float: EnemyPos[3], Float:EnemyAngle[3], Float:TuretAngle[3], Float:vecDir[3];
	
	GetEntPropVector(g_Turrets[owner], Prop_Send, "m_angRotation", TuretAngle);
	GetEntPropVector(g_Turrets[owner], Prop_Send, "m_vecOrigin", TurretPos);
	GetClientAbsOrigin(player, EnemyPos);

	MakeVectorFromPoints(EnemyPos, TurretPos, vecDir);
	GetVectorAngles(EnemyPos, EnemyAngle);
	GetVectorAngles(vecDir, vecDir);
	vecDir[2]=0.0;

	TuretAngle[1]+=180.0;

	//new Float:m_iDegreesY = 0.0;
	new Float:m_iDegreesY = (((vecDir[2]-TuretAngle[2])+30.0)/60.0);
	new Float:m_iDegreesX = (((vecDir[1]-TuretAngle[1])+30.0)/60.0);
	
	if(m_iDegreesX < 0.0 || m_iDegreesX > 1.0){
		TurretTickIdle(owner);
		return;
	}
	
	g_fTurretAim[owner] = m_iDegreesX;
	SetEntPropFloat(g_Turrets[owner], Prop_Send, "m_flPoseParameter", m_iDegreesX, 0);
	SetEntPropFloat(g_Turrets[owner], Prop_Send, "m_flPoseParameter", m_iDegreesY, 1);
	
	if(g_TurretCanShoot[owner] && !g_BringTurret[owner]){
		SetVariantString("retract");
		AcceptEntityInput(g_Turrets[owner], "SetAnimationNoReset", -1, -1, 0);
		
		TurretPos[2]+=50.0;
		EnemyPos[2]=FloatAdd(EnemyPos[2], GetRandomFloat(10.0, 40.0));
		EnemyPos[0]=FloatAdd(EnemyPos[0], GetRandomFloat(-5.0, 5.0));
		EnemyPos[1]=FloatAdd(EnemyPos[1], GetRandomFloat(-5.0, 5.0));
		
		if(GetTeam(g_Turrets[owner]) == 2)
				TE_SetupBeamPoints(TurretPos, EnemyPos, g_BeamSprite, g_HaloSprite, 0, 30, GetRandomFloat(0.1, 0.3), 1.0, 1.0, 0, 1.0, {128,128,64, 100}, 0);
		else if(GetTeam(g_Turrets[owner]) == 3)
				TE_SetupBeamPoints(TurretPos, EnemyPos, g_BeamSprite, g_HaloSprite, 0, 30, GetRandomFloat(0.1, 0.3), 1.0, 1.0, 0, 1.0, {102,153,255, 100}, 0);
		else 	TE_SetupBeamPoints(TurretPos, EnemyPos, g_BeamSprite, g_HaloSprite, 0, 30, GetRandomFloat(0.1, 0.3), 1.0, 1.0, 0, 1.0, {204,0,51, 100}, 0);
		TE_SendToAll();
		
		new hp
		if(g_TurretLevel[owner] == 1) hp = sd_turret_damage1;
		if(g_TurretLevel[owner] == 2) hp = sd_turret_damage2;
		
		SDKHooks_TakeDamage(player, 0, owner, float(hp * 2), DMG_BULLET, -1 , TurretPos, EnemyPos); //http://docs.sourcemod.net/api/index.php?fastload=show&id=1028&
		SetArmor(player,GetClientArmor(player) - hp)
		
		decl String:szFile[128];
		Format(szFile, sizeof(szFile), "player/damage%d.wav", GetRandomInt(1, 3));
		EmitSoundToClient(player, szFile);
		EmitAmbientSound("weapons/sg556/sg556-1.wav", TurretPos);
		
		g_TurretCanShoot[owner]=false;
		CreateTimer(g_TurretLevel[owner] == 1 ? sd_turret_rate1:sd_turret_rate2, TurretSetState, owner);
	}
}

public Action:TurretSetState(Handle:Timer, any:data){
	g_TurretCanShoot[data] = true;
}

public bool:DontHitOwnerOrNade(entity, contentsMask, any:data){
	if(entity > 0 && entity < 65 && IsClientInGame(entity)) return true;
	return false;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	new ent = GetClientAimTarget(client, false);
	if(ent == -1 || !IsPlayerAlive(client)) return;
	if(g_BringTurret[client]){
		if(buttons & IN_USE) g_BringTurret[client] = false;
		else {
			decl Float:pos[3], Float:angle[3], Float:vecDir[3];
			
			GetClientEyeAngles(client, angle);
			GetAngleVectors(angle, vecDir, NULL_VECTOR, NULL_VECTOR);
			GetClientEyePosition(client, pos); 
			
			pos[0] += vecDir[0]*100.0;
			pos[1] += vecDir[1]*100.0;
			pos[2] -= 60.0;
			angle[0] = 0.0;
			TeleportEntity(g_Turrets[client], pos, angle, NULL_VECTOR);
		}
	} 
	else if(buttons & IN_USE){
		if(g_Turrets[client] == ent) g_BringTurret[client] = true;
		
		if(GetOwner(ent) != GetClientTeam(client)){
			
			
			
		}
	}
}

//===================================================================================================================
//BarTime From DropBombDefuse
public CreateBarTime(iClient, iDuration){
	if(!IsClientInGame(iClient)) return;
	if(iDuration){
		SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 1);
		SetEntPropFloat(iClient, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	}
	else {
		SetEntProp(iClient, Prop_Send, "m_bIsDefusing", 0);
	}
	SetEntProp(iClient, Prop_Send, "m_iProgressBarDuration", iDuration);
}

//===================================================================================================================
new String:CacheFile1[36][64] = { //models/Combine_turrets/
"floor_turret.mdl","Floor_turret_gib1.mdl","Floor_turret_gib2.mdl","Floor_turret_gib3.mdl","Floor_turret_gib4.mdl","Floor_turret_gib5.mdl","Floor_turret.phy","Floor_turret_gib1.phy","Floor_turret_gib2.phy","Floor_turret_gib3.phy","Floor_turret_gib4.phy","Floor_turret_gib5.phy","Floor_turret.dx80.vtx","Floor_turret.dx90.vtx","Floor_turret.sw.vtx","Floor_turret_gib1.dx80.vtx","Floor_turret_gib1.dx90.vtx","Floor_turret_gib1.sw.vtx","Floor_turret_gib2.dx80.vtx","Floor_turret_gib2.dx90.vtx","Floor_turret_gib2.sw.vtx","Floor_turret_gib3.dx80.vtx","Floor_turret_gib3.dx90.vtx","Floor_turret_gib3.sw.vtx","Floor_turret_gib4.dx80.vtx","Floor_turret_gib4.dx90.vtx","Floor_turret_gib4.sw.vtx","Floor_turret_gib5.dx80.vtx","Floor_turret_gib5.dx90.vtx","Floor_turret_gib5.sw.vtx","floor_turret.vvd","Floor_turret_gib1.vvd","Floor_turret_gib2.vvd","Floor_turret_gib3.vvd","Floor_turret_gib4.vvd","Floor_turret_gib5.vvd"}

new String:CacheFile2[16][64] = { //materials/models/combine_turrets/floor_turret/
"combine_gun002.vmt","floor_turret_citizen.vmt","floor_turret_citizen2.vmt","floor_turret_citizen4.vmt","combine_gun002.vtf","combine_gun002_mask.vtf","combine_gun002_normal.vtf","floor_turret_citizen.vtf","floor_turret_citizen_glow.vtf","floor_turret_citizen_noalpha.vtf","floor_turret_citizen2.vtf","floor_turret_citizen2_noalpha.vtf","floor_turret_citizen4.vtf","floor_turret_citizen4_noalpha.vtf","floor_turret_citizen4Normal.vtf","floor_turret_citizenNormal.vtf"}
/*
new String:CacheFile_1[30][64] = { //models/Combine_turrets/
"combine_cannon.mdl","combine_cannon_gun.mdl","combine_cannon_powergen.mdl","combine_cannon_stand.mdl","combine_cannon_stand02.mdl","combine_cannon.phy","combine_cannon_gun.phy","combine_cannon_powergen.phy","combine_cannon_stand.phy","combine_cannon_stand02.phy","combine_cannon.dx80.vtx","combine_cannon.dx90.vtx","combine_cannon.sw.vtx","combine_cannon_gun.dx80.vtx","combine_cannon_gun.dx90.vtx","combine_cannon_gun.sw.vtx","combine_cannon_powergen.dx80.vtx","combine_cannon_powergen.dx90.vtx","combine_cannon_powergen.sw.vtx","combine_cannon_stand.dx80.vtx","combine_cannon_stand.dx90.vtx","combine_cannon_stand.sw.vtx","combine_cannon_stand02.dx80.vtx","combine_cannon_stand02.dx90.vtx","combine_cannon_stand02.sw.vtx","combine_cannon.vvd","combine_cannon_gun.vvd","combine_cannon_powergen.vvd","combine_cannon_stand.vvd","combine_cannon_stand02.vvd"}

new String:CacheFile_2[21][64] = { //materials/models/combine_turrets/
"combine_cannon.vmt","combine_cannon_gun.vmt","combine_cannon_powergen.vmt","combine_cannon_powergen02.vmt","combine_cannon_powergen02noillum.vmt","combine_cannon_powergennoillum.vmt","combine_cannon_stand.vmt","combine_cannon_stand02.vmt","combine_cannon_stand02noillum.vmt","combine_cannon_standnoillum.vmt","combine_cannon.vtf","combine_cannon_gun.vtf","combine_cannon_gun_exponent.vtf","combine_cannon_gun_normal.vtf","combine_cannon_powergen.vtf","combine_cannon_powergen_mask.vtf","combine_cannon_powergen02.vtf","combine_cannon_stand.vtf","combine_cannon_stand_mask.vtf","combine_cannon_stand_normal.vtf","combine_cannon_stand02.vtf"}
*/
public OnMapStart(){
	//PrecacheSound("weapons/sg550/sg550-1.wav");
	PrecacheSound("weapons/sg556/sg556-1.wav");
	PrecacheSound("player/damage1.wav");
	PrecacheSound("player/damage2.wav");
	PrecacheSound("player/damage3.wav");
	//g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	//g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt");
	
	PrecacheSound("training/light_on.wav");
	PrecacheSound("training/gallery_stop.wav");
	//PrecacheSound("buttons/blip2.wav");
	//-----------------------------------------------------------------------
	//floor_turret
	for(new i = 0;i < 35;i++){
		new String:CacheFile1Path[128]
		Format(CacheFile1Path,sizeof(CacheFile1Path),"models/Combine_turrets/%s",CacheFile1[i])
		AddFileToDownloadsTable(CacheFile1Path);
		if(StrContains(CacheFile1[i], ".mdl", false) != -1) PrecacheModel(CacheFile1Path)
	}
	
	for(new i = 0;i < 16;i++){
		new String:CacheFile2Path[128]
		Format(CacheFile2Path,sizeof(CacheFile2Path),"materials/models/Combine_turrets/floor_turret/%s",CacheFile2[i])
		AddFileToDownloadsTable(CacheFile2Path);
	}
	
	//-----------------------------------------------------------------------
	//Other
	/*
	for(new i = 0;i < 30;i++){
		new String:CacheFilePath[128]
		Format(CacheFilePath,sizeof(CacheFilePath),"models/Combine_turrets/%s",CacheFile_1[i])
		AddFileToDownloadsTable(CacheFilePath);
		if(StrContains(CacheFile_1[i], ".mdl", false) != -1) PrecacheModel(CacheFilePath)
	}
	
	for(new i = 0;i < 20;i++){
		new String:CacheFilePath[128]
		Format(CacheFilePath,sizeof(CacheFilePath),"materials/models/combine_turrets/%s",CacheFile_2[i])
		AddFileToDownloadsTable(CacheFilePath);
	}
	
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ceiling_turret/combine_gun003.vtf");
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ceiling_turret/combine_gun003_mask.vtf");
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ground_turret/ground_turret01.vmt");
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ground_turret/ground_turret02.vmt");
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ground_turret/ground_turret01.vtf");
	AddFileToDownloadsTable("materials/models/Combine_turrets/Ground_turret/ground_turret02.vtf");
	*/
}

//===================================================================================================================
//Stock
stock SetMoney(client,amt){ SetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount"), amt); }
stock GetMoney(client){ return GetEntData(client, FindSendPropOffs("CCSPlayer", "m_iAccount")); }
stock GetOwner(ent){ return GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity"); }
stock GetTeam(ent){ return GetEntProp(ent, Prop_Data, "m_iTeamNum"); }
stock SetArmor(client,amount){ if(amount <= 0) amount = 0; SetEntProp(client,Prop_Send,"m_ArmorValue",amount); }
stock MapChecking(const client = 0){
	new String:Maps[64],String:CurrentMap[64],times = 0
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	strcopy(Maps, sizeof(Maps), sd_turret_map);
	while(ReplaceStringEx(Maps,sizeof(Maps),",","|",-1,-1,false) != -1){ times++; }
	if(times){
		times++
		new String:buffer[times][64];
		ExplodeString(Maps, "|", buffer, times, sizeof(Maps))
		for(new i = 0;i < times;i++){
			new times2 = 0
			//PrintToServer("%d:%s",i,buffer[i])
			if(client) PrintToConsole(client,"%d:%s",i,buffer[i])
			for(new j = 0;j < strlen(buffer[i]);j++){
				new String:buffer2[2],String:buffer3[2];
				strcopy(buffer2, sizeof(buffer2), buffer[i][j]);
				strcopy(buffer3, sizeof(buffer3), CurrentMap[j]);
				if(StrEqual(buffer2,buffer3,false)) times2++
				if(times2 == strlen(buffer[i])) TurretMapChecking = true
				//PrintToServer(buffer2)
				if(client) PrintToConsole(client,"%s:%d:%s",buffer2,times2,buffer3)
				//if(client) PrintToConsole(client,"%d",times2)
			}
		}
	}
}
stock IsEqual(const string1[],const string2[],pram = 0,bool:caseSensitive=false){
	if(!pram && strlen(string1) > strlen(string2)) pram = strlen(string2)
	if(!pram && strlen(string1) < strlen(string2)) pram = strlen(string1)
}
//===================================================================================================================
//Backup
/*
public OnAnimationBegun(const String:output[], caller, activator, Float:delay){
	if(IsValidEntity(caller)){
		new sequence = GetEntProp(caller, Prop_Data, "m_nSequence");
		new owner = GetEntPropEnt(caller, Prop_Data, "m_hOwnerEntity")
		if(TestMode) PrintToChat(owner,"Begun:%i", sequence);
	}
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if(!sd_turret_knife) return;
	new String:WeaponName[32]
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientWeapon(client, WeaponName, sizeof(WeaponName));
	PrintToChat(client,"W:%s",WeaponName) //weapon_knife
}
*/