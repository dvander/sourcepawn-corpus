/*
 * FaceBook FanPage 粉絲團
 * 			https://www.facebook.com/TastSDC
 * AlliedMods With English Version 英文版
 * 			https://forums.alliedmods.net/showthread.php?t=273229
 * Tast SD.C with Chinese Version 中文版
 *			http://tast.xclub.tw/viewthread.php?tid=65
 */
#include <sdktools>
#include <sdkhooks>
#include <sourcemod>
#include <clientprefs>
//#include <SDC.Stock>

#include <topmenus>
#undef REQUIRE_PLUGIN
#include <adminmenu>

new sd_SlayLoser = 1				,String:i_sd_SlayLoser[64]
new sd_SlayLoserRD = 1				,String:i_sd_SlayLoserRD[64]
new sd_SlayLoserKill = 1			,String:i_sd_SlayLoserKill[64]
new sd_SlayLoserKillBot = 0			,String:i_sd_SlayLoserKillBot[64]
new sd_SlayLoser_Immunity = 0		,String:i_sd_SlayLoser_Immunity[64]
new sd_SlayLoser_StopWalk = 0		,String:i_sd_SlayLoser_StopWalk[64]
new sd_SlayLoser_SoundOne = 0		,String:i_sd_SlayLoser_SoundOne[64]
new sd_SlayLoser_EffectOne = 0		,String:i_sd_SlayLoser_EffectOne[64]
new sd_SlayLoser_MagicProp = 100	,String:i_sd_SlayLoser_MagicProp[64]
new sd_SlayLoser_Invincible = 1		,String:i_sd_SlayLoser_Invincible[64]
new sd_SlayLoser_DeathLight = 1		,String:i_sd_SlayLoser_DeathLight[64]
new sd_SlayLoser_StripWeapon = 1	,String:i_sd_SlayLoser_StripWeapon[64]


new String:sd_SlayLoser_MagicProp1[64] = "models/props/cs_italy/bananna.mdl"	
new String:sd_SlayLoser_MagicProp2[64] = "models/props/cs_italy/bananna_bunch.mdl"
new String:i_sd_SlayLoser_MagicProp1[64]
new String:i_sd_SlayLoser_MagicProp2[64]

new String:i_cmdSlayLoser[64]
new String:i_cmdSlayLoserAll[64]

//The Round End Time is 6.899995s (Maybe Changed)
new bool:g_bRoundStarted = false;
new String:path[PLATFORM_MAX_PATH];	
//Suicide Custom Cookie
new SlayLoserCustom[65]				,String:i_SlayLoserCustom[64]
new SlayLoserKill[65];
new Handle:g_hCookie;

new SlayLoserItems = 16

#define PLUGIN_VERSION "0.37"
public Plugin:myinfo = {
	name = "Loser Slay Plus",
	author = "Tast - SDC",
	description = "Slay Loser Multi Punishment",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=273229"
};
#define FCVAR FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD
//===================================================================================================================
//Updater		https://forums.alliedmods.net/showthread.php?p=1570806
//#undef REQUIRE_PLUGIN
#include <updater>
#define UPDATE_URL    "http://tast.banner.tw/SourceMod/UpdateService/SDC_SlayLoser/SDC_SlayLoser.update.txt"
public PluginUpdater(){ 					if (LibraryExists("updater")) Updater_AddPlugin(UPDATE_URL); }
public OnLibraryAdded(const String:name[]){ if (StrEqual(name,"updater")) Updater_AddPlugin(UPDATE_URL); }
public OnPluginStart(){
	PluginUpdater()  //Updater Support
	Global_LangSet() //Multi Language
	BuildPath(PathType:Path_SM, path, sizeof(path), "logs/loser.log");
	CreateConVar("SDC_LoserSlay_Version", PLUGIN_VERSION, "Loser Slay Plus Version",FCVAR);
	
	HookConVarChange(CreateConVar("sd_SlayLoser", 			"1"		, i_sd_SlayLoser)			, Cvar_enabled);
	HookConVarChange(CreateConVar("sd_SlayLoserKill", 		"1"		, i_sd_SlayLoserKill)		, Cvar_Kill);
	HookConVarChange(CreateConVar("sd_SlayLoserKillBot", 	"0"		, i_sd_SlayLoserKillBot)	, Cvar_KillBot);
	HookConVarChange(CreateConVar("sd_SlayLoser_RoundDraw", "1"		, i_sd_SlayLoserRD)			, Cvar_RoundDraw);
	HookConVarChange(CreateConVar("sd_SlayLoser_Immunity", 	"0"		, i_sd_SlayLoser_Immunity)	, Cvar_Immunity);
	HookConVarChange(CreateConVar("sd_SlayLoser_StopWalk", 	"0"		, i_sd_SlayLoser_StopWalk)	, Cvar_StopWalk);
	HookConVarChange(CreateConVar("sd_SlayLoser_SoundOne", 	"0"		, i_sd_SlayLoser_SoundOne)	, Cvar_SoundOne);
	HookConVarChange(CreateConVar("sd_SlayLoser_EffectOne", "0"		, i_sd_SlayLoser_EffectOne)	, Cvar_EffectOne);
	HookConVarChange(CreateConVar("sd_SlayLoser_MagicProp", "100"	, i_sd_SlayLoser_MagicProp)	, Cvar_MagicProp);
	HookConVarChange(CreateConVar("sd_SlayLoser_Invincible", "1"	, i_sd_SlayLoser_Invincible), Cvar_Invincible);
	HookConVarChange(CreateConVar("sd_SlayLoser_DeathLight", "1"	, i_sd_SlayLoser_DeathLight), Cvar_DeathLight);
	HookConVarChange(CreateConVar("sd_SlayLoser_StripWeapon","1"	, i_sd_SlayLoser_StripWeapon),Cvar_StripWeapon);
	
	HookConVarChange(CreateConVar("sd_SlayLoser_MagicProp1", sd_SlayLoser_MagicProp1, i_sd_SlayLoser_MagicProp1), Cvar_Magic1);
	HookConVarChange(CreateConVar("sd_SlayLoser_MagicProp2", sd_SlayLoser_MagicProp2, i_sd_SlayLoser_MagicProp2), Cvar_Magic2);
	
	g_hCookie = RegClientCookie("SlayLoserCustom", i_SlayLoserCustom, CookieAccess_Public);
	SetCookieMenuItem(CookieSelected, g_hCookie, i_SlayLoserCustom);
	
	HookEvent("round_end"	, Event_RoundEnd	);
	HookEvent("round_start"	, Event_RoundStart	);
	HookEvent("player_spawn", Hook_PlayerSpawn	);
	
	RegAdminCmd("sdc_sls"			, SDC_SLS , ADMFLAG_SLAY, i_cmdSlayLoser);
	RegAdminCmd("sdc_slsa"			, SDC_SLSA, ADMFLAG_SLAY, i_cmdSlayLoserAll);
	RegAdminCmd("SDC_SlayLoser"		, SDC_SLS , ADMFLAG_SLAY, i_cmdSlayLoser);
	RegAdminCmd("SDC_SlayLoserAll"	, SDC_SLSA, ADMFLAG_SLAY, i_cmdSlayLoserAll);
	
	//RegAdminCmd("sdc_slsmenu"		, SDC_SLSMENU , ADMFLAG_SLAY, i_cmdSlayLoser);
	
	//RegAdminCmd("wdtest"	, test15, ADMFLAG_ROOT);
	RegAdminCmd("wdtest3"	, test14, ADMFLAG_ROOT);
	
	RegConsoleCmd("sls", PrefSet);
	
	AddCommandListener(CommandListener , "kill");
	AddCommandListener(CommandListener2, "say" );
	
	//Slay Loser Menus
	new Handle:topmenu;
	if( LibraryExists( "adminmenu" ) && ( ( topmenu = GetAdminTopMenu() ) != INVALID_HANDLE ) ){ OnAdminMenuReady( topmenu ); }
}
//===================================================================================================================
//Common //RGB http://www.wahart.com.hk/rgb.htm
#define FragColor 	{225,0,0,225}
#define FlashColor 	{255,116,0,225}
#define SmokeColor	{0,225,0,225}
#define whiteColor 	{255,255,255,255}
#define greyColor	{128, 128, 128, 255}
#define orangeColor	{255, 128, 0, 255}
#define PurpleColor	{160, 32, 240, 255}
#define CyanColor	{0, 255, 255, 255}
new g_HaloSprite 	= -1 	, g_BeamSprite 	= -1	, g_ExplosionSprite = -1
new g_BeamSprite2 	= -1	, g_BeamSprite3 = -1	, g_BeamSprite4 	= -1
new GLOW_SPRITE 	= -1	, GLOW_SPRITE2 	= -1
new Snow_Decal[5]
new String:CacheSound[128][128] //[MaxItem][MaxLen]
//===================================================================================================================
//Choose the one.
stock ForcePlayerSuicide2(client,const eun = 0){
	SetRandomSeed(GetRandomInt( -99999 , 99999 ))
	
	if(!IsValidClient(client)) 		return; //if(!StatusCheck(client)) return;
	if(sd_SlayLoser_StripWeapon) 	StripWeapons(client)
	if(sd_SlayLoser_StopWalk) 		SetEntityMoveType(client, MOVETYPE_NONE);

	//m_takedamage		https://forums.alliedmods.net/showthread.php?t=133811
	SetEntProp(client, Prop_Data, "m_takedamage",1, 1); //Invincible
	new rand = SlayLoserCustom[client] ? SlayLoserCustom[client]:GetRandomInt( 1 , SlayLoserItems ) //? 1:0
	if(eun) rand = eun
	switch(rand){
		case 1: 	PimpSlap	(client);	//巴掌到死
		case 2: 	Rocket		(client);	//火箭升空
		case 3: 	Falling		(client);	//摔來摔去
		case 4: 	TimeBomb	(client);	//定時炸彈
		case 5: 	Fire		(client);	//慾火焚身
		case 6: 	Quake		(client);	//雷神之鎚
		case 7: 	Sword		(client);	//萬劍歸宗
		case 8: 	DeadFly		(client);	//我愛阿飛
		case 9: 	Tesla		(client);	//核磁電爆
		case 10: 	Thunder		(client);	//雙極閃電
		case 11: 	Chicken		(client);	//小雞逼逼
		case 12: 	BirdFly		(client);	//失落小鳥
		case 13: 	Snow		(client);	//冰封絕地
		case 14: 	Magic		(client);	//人體練成
		case 15: 	Bomber		(client);	//炸彈超人
		//Developing.......................................
		case 16: 	EVA			(client);	//使徒來襲
		case 17:  	BarrelExp	(client);	//絕對炸桶
		//case 18: 	Crash(client);		//巔峰撞擊
		//case 17: 	FireFly(client);	//
		//case 18: 	FireWorks(client);	//

	}
}

//Enum		https://wiki.alliedmods.net/Tags_(Scripting)
//https://wiki.alliedmods.net/Translations_(SourceMod_Scripting)
//===================================================================================================================
//Evangelion Reference:
public EVA(client){//16
	if(!StatusCheck(client)) return;
	
	new Float:Range = 120.0
	new Float:Pos1[3],Float:Pos2[3]
	GetClientAbsOrigin(client, Pos1);
	GetClientAbsOrigin(client, Pos2);
	Pos2[2] += Range * 2.5
	
	new Color[4]
	Color[0] = GetRandomInt(0,255)
	Color[1] = GetRandomInt(0,255)
	Color[2] = GetRandomInt(0,255)
	Color[3] = GetRandomInt(0,255)
	
	//TE_SetupBeamPoints2(client,start,end,	ModelIndex, 	HaloIndex,		StartFrame, FrameRate, 	Life, 	Width, 	EndWidth, 	FadeLen, 	Amplitude, 	Color, 		Speed)
	TE_SetupBeamPoints2(client,Pos2,Pos1,g_BeamSprite4,	g_HaloSprite,0,			500, 		7.0, 	3.0, 	0.5, 		0, 		0.2, Color, 50)
	TE_SetupBeamPoints2(client,Pos2,Pos1,g_BeamSprite4,	g_HaloSprite,0,			500, 		7.0, 	3.0, 	0.5, 		0, 		0.2, Color, 50)
	
	new Float:Pos3[3],Float:Pos4[3]
	GetClientAbsOrigin(client, Pos3);
	GetClientAbsOrigin(client, Pos4);
	
	Pos3[1] += Range
	Pos3[2] += Range
	
	Pos4[1] -= Range
	Pos4[2] += Range
	TE_SetupBeamPoints2(client,Pos3,Pos4,g_BeamSprite4,	g_HaloSprite,0,			500, 		7.0, 	3.0, 	0.5, 		0, 		0.2, Color, 50)
	TE_SetupBeamPoints2(client,Pos4,Pos3,g_BeamSprite4,	g_HaloSprite,0,			500, 		7.0, 	3.0, 	0.5, 		0, 		0.2, Color, 50)
	
	new Float:clientposOrgin[3]
	GetClientAbsOrigin(client, clientposOrgin);
	clientposOrgin[2] += 35
	TE_SetupGlowSprite2(client,clientposOrgin,GLOW_SPRITE, 8.0, 2.0, 600)
	GetClientEyePosition(client, clientposOrgin);
	TE_SetupGlowSprite2(client,clientposOrgin,GLOW_SPRITE2, 8.0, 2.0, 600)

	ClientKill(client)
}

//===================================================================================================================
//Bomber Reference:
//Hammer Tutorial V2 Series #20 "Func_Rotating, Making fans and things spin!" https://youtu.be/4wugEudz4Q0
public Bomber(client){ //15
	if(!StatusCheck(client)) return;
	ThirdPerson(client)
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	new Float:Range = 30.0
	new Float:Pos1[3],Float:Pos2[3],Float:Pos3[3],Float:Pos4[3]
	GetClientAbsOrigin(client,Pos1);
	GetClientAbsOrigin(client,Pos2);
	GetClientAbsOrigin(client,Pos3);
	GetClientAbsOrigin(client,Pos4);
	
	Pos1[0] += Range
	Pos1[2] += 10
	
	Pos2[0] -= Range
	Pos2[2] += 10
	
	Pos3[1] += Range
	Pos3[2] += 10
	
	Pos4[1] -= Range
	Pos4[2] += 10
	
	BomberProp(Pos1)
	BomberProp(Pos2)
	BomberProp(Pos3)
	BomberProp(Pos4)
	
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 1);
	CreateTimer(2.0, BomberCrissCross, Hpack);
	CreateTimer(2.0, ClientKillDelay, client);
}

public BomberProp(Float:Pos[3]){
	new ent = CreateEntityByName("prop_physics");
	if(ent == -1) return ent
	
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "skin","1");
	
	new String:angles[16]
	Format(angles,sizeof(angles),"%d %d %d",GetRandomInt(0,360),GetRandomInt(0,360),GetRandomInt(0,360))
	DispatchKeyValue(ent, "angles", angles);//"0 180 0"
	DispatchKeyValue(ent, "model", "models/props_junk/watermelon01.mdl");
	DispatchKeyValue(ent, "StartDisabled", "0");
	DispatchKeyValue(ent, "renderamt", "255");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	TeleportEntity(ent, Pos, NULL_VECTOR, NULL_VECTOR);
	CreateTimer(2.0, ChickenBreak, ent);
	return ent;
}

public Action:BomberCrissCross(Handle: timer, any: Hpack){ 
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new count = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(!StatusCheck()) return;
	if(count > 15) return;
	
	new Float:PosX[3],Float:PosY[3],Float:Down = 50.0
	GetClientAbsOrigin(client,PosX);
	GetClientAbsOrigin(client,PosY);
	PosX[2] -= Down
	PosY[2] -= Down
	
	PosX[0] += count * 20
	TE_SetupExplosion2(client,PosX, g_ExplosionSprite, 0.051, 50,TE_EXPLFLAG_NOFIREBALLSMOKE , 1, 1);
	PosX[0] -= count * 20 * 2
	TE_SetupExplosion2(client,PosX, g_ExplosionSprite, 0.051, 50,TE_EXPLFLAG_NOFIREBALLSMOKE , 1, 1);
	
	PosY[1] += count * 20
	TE_SetupExplosion2(client,PosY, g_ExplosionSprite, 0.051, 50,TE_EXPLFLAG_NOFIREBALLSMOKE , 1, 1);
	PosY[1] -= count * 20 * 2
	TE_SetupExplosion2(client,PosY, g_ExplosionSprite, 0.051, 50,TE_EXPLFLAG_NOFIREBALLSMOKE , 1, 1);
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, count+=1);
	CreateTimer(0.05, BomberCrissCross, Hpack2);
}

//===================================================================================================================
//CarCrash Reference:
//Hammer Tutorial #59 "Path_track, and func_tanktrain" https://youtu.be/wvpwQRlKuHE
public Crash(client){
	new Float:Pos[3]
	GetClientEyePosition(client, Pos);
	//GetClientAbsOrigin(client, Pos);
	Pos[0] += 300
	PrecacheModel("models/props_vehicles/car002a.mdl",true)
	new ent = CrashProp(client,Pos,"models/props_vehicles/car002a.mdl",1)
	
	new Float:Pos2[3]
	Pos2[0] = -500.0
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, Pos2);
}

public CrashProp(client,Float:pos[3],String:model[],num){
	new ent = CreateEntityByName("prop_physics_override");
	if(ent == -1) return ent
	pos[2] +=5
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"CrashProp_%d_%d",client,num)
	DispatchKeyValue(ent, "targetname", targetname);
	
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "skin","1");
	DispatchKeyValue(ent, "angles", "0 180 0");
	DispatchKeyValue(ent, "model", model);
	DispatchKeyValue(ent, "StartDisabled", "0");
	DispatchKeyValue(ent, "renderamt", "255");
	DispatchSpawn(ent);
	//SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	//SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_CUSTOM);
	SetEntProp(ent, Prop_Send, "m_nSolidType", 0 );
	/*
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 17);
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
	*/
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	/*
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntData(ent, FindSendPropOffs("CBasePlayer", "m_fFlags"), FL_CLIENT|FL_ATCONTROLS, 4, true);
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
	*/
	CreateTimer(8.0, KillEntity, ent);
	return ent
}

//===================================================================================================================
//Magic Reference:
//[ANY] OM Prop Spawn					https://forums.alliedmods.net/showthread.php?p=1093283
//[CSS/CSGO] Hide and Seek (Prop Hunt)	https://forums.alliedmods.net/showpost.php?p=2155885&postcount=32
public Magic(client){
	if(!StatusCheck(client)) return;
	
	ThirdPerson(client)
	StripWeapons(client)
	new Float:Ang[3],Float:Ang2[3] = { 180.0,0.0,0.0 }
	//GetClientEyeAngles(client, Ang);
	TeleportEntity(client, NULL_VECTOR, Ang , NULL_VECTOR);
	//SetEntityModel(client, "models/props/cs_italy/bananna_bunch.mdl");
	
	new Float:Pos[3]
	new Float:Pos1[3],Float:Pos2[3],Float:Pos3[3]
	new Float:Pos4[3],Float:Pos5[3],Float:Pos6[3]
	new Float:Pos8[3],Float:Pos9[3]
	GetClientAbsOrigin(client, Pos);
	GetClientAbsOrigin(client, Pos1);
	GetClientAbsOrigin(client, Pos2);
	GetClientAbsOrigin(client, Pos3);
	GetClientAbsOrigin(client, Pos4);
	GetClientAbsOrigin(client, Pos5);
	GetClientAbsOrigin(client, Pos6);
	GetClientAbsOrigin(client, Pos8);
	GetClientAbsOrigin(client, Pos9);
	
	new Float:Range = float(sd_SlayLoser_MagicProp)
	//new Float:Range2 = 0.86
	new Float:Range2 = 0.67
	new Float:Range3 = 20.0
	
	//正三角 triangle
	Pos1[0] += Range
	Pos1[2] += Range3 / 2
	
	Pos2[0] -= Range * Range2
	Pos2[1] -= Range * Range2
	Pos2[2] += Range3
	
	Pos3[0] -= Range * Range2
	Pos3[1] += Range * Range2
	Pos3[2] += Range3
	
	//逆三角 triangle reverse
	Pos4[0] -= Range
	Pos4[2] += Range3 / 2
	
	Pos5[0] += Range * Range2
	Pos5[1] += Range * Range2
	Pos5[2] += Range3
	
	Pos6[0] += Range * Range2
	Pos6[1] -= Range * Range2
	Pos6[2] += Range3
	
	//小圓形 Small Cycle
	Pos8[0] += Range * 0.45
	Pos8[2] += Range3
	Pos9[0] -= Range * 0.45
	Pos9[2] += Range3
	
	new ent1 = MagicProp(client,Pos1,sd_SlayLoser_MagicProp1,1)
	MagicProp(client,Pos2,sd_SlayLoser_MagicProp1,2)
	MagicProp(client,Pos3,sd_SlayLoser_MagicProp1,3)
	
	new ent4 = MagicProp(client,Pos4,sd_SlayLoser_MagicProp2,4)
	MagicProp(client,Pos5,sd_SlayLoser_MagicProp2,5)
	MagicProp(client,Pos6,sd_SlayLoser_MagicProp2,6)
	
	cmd_beam(client , 1 , 2,"255 128 0 255")
	cmd_beam(client , 2 , 3,"255 128 0 255")
	cmd_beam(client , 3 , 1,"255 128 0 255")
	
	cmd_beam(client , 4 , 5,"160 32 240 255")
	cmd_beam(client , 5 , 6,"160 32 240 255")
	cmd_beam(client , 6 , 4,"160 32 240 255")
	
	/*
	new Float:Width = 1.0
	TE_SetupBeamRingPoint2(client,Pos1, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, FlashColor, 1, 0);
	TE_SetupBeamRingPoint2(client,Pos2, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, FlashColor, 1, 0);
	TE_SetupBeamRingPoint2(client,Pos3, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, FlashColor, 1, 0);
	
	TE_SetupBeamRingPoint2(client,Pos4, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, CyanColor, 1, 0);
	TE_SetupBeamRingPoint2(client,Pos5, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, CyanColor, 1, 0);
	TE_SetupBeamRingPoint2(client,Pos6, 11.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 10.0, 10.0, 0.0, CyanColor, 1, 0);
	*/
	
	Pos[2] += 45
	new PlayerProp = MagicProp(client,Pos,sd_SlayLoser_MagicProp2,7)
	SetEntityRenderMode(PlayerProp, RENDER_TRANSCOLOR);
	SetEntityRenderColor(PlayerProp, 255, 255, 255, 0);
	
	new ent8 = MagicProp(client,Pos8,sd_SlayLoser_MagicProp2,8)
	new ent9 = MagicProp(client,Pos9,sd_SlayLoser_MagicProp2,9)
	TE_SetupBeamRing2(client,ent1, ent4, g_BeamSprite2, g_HaloSprite, 0, 15, 10.0, 2.0, 0.2, CyanColor, 1, 0)
	TE_SetupBeamRing2(client,ent8, ent9, g_BeamSprite2, g_HaloSprite, 0, 15, 10.0, 2.0, 0.2, CyanColor, 1, 0)
	SetEntityRenderMode(ent8, RENDER_NONE); 
	SetEntityRenderMode(ent9, RENDER_NONE); 
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"MagicProp_%d_0",client)
	DispatchKeyValue(client, "targetname", targetname);
	
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, PlayerProp);
	
	CreateTimer(1.0,  MagicLighting1, client);
	CreateTimer(2.0,  MagicLighting2, client);
	CreateTimer(3.0,  MagicLighting3, client);
	CreateTimer(4.1,  MagicPlayerOff, Hpack);
	CreateTimer(4.2,  MagicPlayerOn , Hpack);
	CreateTimer(4.3,  MagicPlayerOff, Hpack);
	CreateTimer(4.4,  MagicPlayerOn , Hpack);
	CreateTimer(5.0,  MagicPlayerOff, Hpack);
	CreateTimer(5.0,  MagicChangeSound, client);
	CreateTimer(6.8,  ClientKillDelay, client);
	TeleportEntity(client, NULL_VECTOR, Ang2 , NULL_VECTOR);
}

public Action:MagicChangeSound(Handle: timer, any: client){ 
	if(!StatusCheck(client)) return;
	EmitSound2("weapons/party_horn_01.wav", client);
}

public Action:MagicLighting1(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	cmd_beam(client , 1 , 0,"255 128 0 255","10")
	cmd_beam(client , 2 , 0,"255 128 0 255","10")
	EmitSound2("buttons/light_power_on_switch_01.wav", client);
}

public Action:MagicLighting2(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	cmd_beam(client , 3 , 0,"255 128 0 255","10")
	cmd_beam(client , 4 , 0,"160 32 240 255","10")
	EmitSound2("buttons/light_power_on_switch_01.wav", client);
}

public Action:MagicLighting3(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	cmd_beam(client , 5 , 0,"160 32 240 255","10")
	cmd_beam(client , 6 , 0,"160 32 240 255","10")
	EmitSound2("buttons/light_power_on_switch_01.wav", client);
}

//https://forums.alliedmods.net/showthread.php?t=177518
stock cmd_beam(client , num1 , num2,String:color[],String:Amp[] = "0.0"){ 
	if(!StatusCheck(client)) return -1
	new beam = CreateEntityByName("env_beam");
	if(beam == -1) return -1
	
	new String:StartTargatName[32], String:EndTargatName[32]
	Format(StartTargatName,sizeof(StartTargatName),"MagicProp_%d_%d",client,num1)
	Format(EndTargatName,sizeof(EndTargatName),"MagicProp_%d_%d",client,num2)
	
	DispatchKeyValue(beam, "BoltWidth", "1.0"); 
	DispatchKeyValue(beam, "damage", "0"); 
	DispatchKeyValue(beam, "decalname", "Bigshot");
	DispatchKeyValue(beam, "framerate", "0"); 
	DispatchKeyValue(beam, "framestart", "0"); 
	DispatchKeyValue(beam, "TouchType", "2"); 
	DispatchKeyValue(beam, "HDRColorScale", "1.0"); 
	DispatchKeyValue(beam, "TextureScroll", "10"); 
	DispatchKeyValue(beam, "life", "3.0"); // Beam lifetime 
	DispatchKeyValue(beam, "texture", "materials/sprites/physbeam.vmt"); 
	DispatchKeyValue(beam, "NoiseAmplitude", Amp); 
	DispatchKeyValue(beam, "StrikeTime", "0.0"); 
	DispatchKeyValue(beam, "Radius", "100"); 
	//DispatchKeyValue(beam, "spawnflags", "1"); 
	DispatchKeyValue(beam, "spawnflags", "16");
	DispatchKeyValue(beam, "renderamt", "100"); 
	DispatchKeyValue(beam, "LightningEnd",EndTargatName ); 
	DispatchKeyValue(beam, "renderfx", "100"); 
	DispatchKeyValue(beam, "LightningStart", StartTargatName); 
	DispatchKeyValue(beam, "rendercolor", color); 
	DispatchSpawn(beam); 
	ActivateEntity(beam);
	AcceptEntityInput(beam, "TurnOn");
	CreateTimer(10.0, KillEntity, beam);
	
	return beam;
}  

public Action:MagicPlayerOff(Handle: timer, any: Hpack){ 
	SetRandomSeed(GetRandomInt( -99999 , 99999 ))
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new ent = ReadPackCell(Hpack);
	//CloseHandle(Hpack);
	if(!StatusCheck(client)) return;
	switch(GetRandomInt(1,2)){
		case 1:SetEntityModel(ent, sd_SlayLoser_MagicProp1);
		case 2:SetEntityModel(ent, sd_SlayLoser_MagicProp2);
	}
	
	SetEntityRenderMode(client, RENDER_NONE); 
	//SetEntityRenderMode(ent, RENDER_NORMAL);
	SetEntityRenderColor(ent, 255, 255, 255, 255);
}
public Action:MagicPlayerOn(Handle: timer, any: Hpack){
	SetRandomSeed(GetRandomInt( -99999 , 99999 ))
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new ent = ReadPackCell(Hpack);
	//CloseHandle(Hpack);
	if(!StatusCheck(client)) return;
	SetEntityRenderMode(client, RENDER_NORMAL); 
	SetEntityRenderColor(ent, 255, 255, 255, 0);
}

public MagicProp(client,Float:pos[3],String:model[],num){
	if(!StatusCheck(client)) return -1
	new ent = CreateEntityByName("prop_physics_override");
	if(ent == -1) return ent
	pos[2] +=5
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"MagicProp_%d_%d",client,num)
	DispatchKeyValue(ent, "targetname", targetname);
	
	DispatchKeyValue(ent, "physdamagescale", "0.0");
	DispatchKeyValue(ent, "skin","1");
	DispatchKeyValue(ent, "angles", "0 0 0");
	DispatchKeyValue(ent, "model", model);
	DispatchKeyValue(ent, "StartDisabled", "0");
	DispatchKeyValue(ent, "renderamt", "255");
	DispatchSpawn(ent);
	//SetEntityMoveType(ent, MOVETYPE_VPHYSICS);
	//SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	SetEntProp(ent, Prop_Send, "m_nSolidType", 0 );
	/*
	SetEntProp(entity, Prop_Data, "m_CollisionGroup", 17);
	SetEntProp(entity, Prop_Send, "m_usSolidFlags", 12);
	SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
	*/
	TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntData(ent, FindSendPropOffs("CBasePlayer", "m_fFlags"), FL_CLIENT|FL_ATCONTROLS, 4, true);
	SetEntPropEnt(ent, Prop_Data, "m_hLastAttacker", client);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
	
	CreateTimer(8.0, KillEntity, ent);
	return ent
}

//===================================================================================================================
//Snow Reference:
//sm_snow						https://forums.alliedmods.net/showthread.php?p=1656942
//[ANY] Snowfall				https://forums.alliedmods.net/showthread.php?p=1619374
//[L4D2] Weather Control (1.6) 	https://forums.alliedmods.net/showthread.php?p=1706054
//[CS:GO] Sprays v1.4.1			https://forums.alliedmods.net/showthread.php?p=2118030	
//https://developer.valvesoftware.com/wiki/Env_smokestack
public Snow(client){
	if(!StatusCheck(client)) return;
	ThirdPerson(client)
	CreateSnow(client)
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 255);
	CreateTimer(0.1, SnowColor, Hpack);
	EmitSound2(CacheSound[GetRandomInt(102,104)], client);
}

public Action:SnowColor(Handle: timer, any: Hpack){
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new color = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(!StatusCheck(client)) return;
	
	SnowDecal(client)
	SnowDecal(client)
	SetEntityRenderColor(client, color, color, 255, 255);
	EmitSound2(CacheSound[GetRandomInt(98,101)], client);
	
	if(color <= 3){ 
		ClientKill(client)
		return;
	}
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, color-=42);
	CreateTimer(1.0, SnowColor, Hpack2);
}

public SnowDecal(client){
	if(!StatusCheck(client)) return;
	SetRandomSeed(GetRandomInt( -99999 , 99999 ))
	
	new Float:Min = -15.0 , Float:Max = 15.0 , Float:Pos[3];
	GetClientAbsOrigin(client, Pos);
	Pos[0] += GetRandomFloat(Min,Max)
	Pos[1] += GetRandomFloat(Min,Max)
	TE_SetupWorldDecal(client,Snow_Decal[GetRandomInt(0,4)],Pos)
}

CreateSnow(client){
	if(!StatusCheck(client)) return;
	new ent = CreateEntityByName("env_smokestack");
	if(ent == -1) return;
	
	new Float:eyePosition[3];
	GetClientEyePosition(client, eyePosition);
	
	eyePosition[2] +=25.0
	DispatchKeyValueVector(ent,"Origin", eyePosition);
	DispatchKeyValueFloat(ent,"BaseSpread", 50.0);
	DispatchKeyValue(ent,"SpreadSpeed", "100");
	DispatchKeyValue(ent,"Speed", "25");
	DispatchKeyValueFloat(ent,"StartSize", 1.0);
	DispatchKeyValueFloat(ent,"EndSize", 1.0);
	DispatchKeyValue(ent,"Rate", "125");
	DispatchKeyValue(ent,"JetLength", "300");
	DispatchKeyValueFloat(ent,"Twist", 200.0);
	DispatchKeyValue(ent,"RenderColor", "255 255 255");
	DispatchKeyValue(ent,"RenderAmt", "200");
	DispatchKeyValue(ent,"RenderMode", "18");
	DispatchKeyValue(ent,"SmokeMaterial", "particle/snow");
	DispatchKeyValue(ent,"Angles", "180 0 0");
	
	DispatchSpawn(ent);
	ActivateEntity(ent);
		
	eyePosition[2] += 50;
	TeleportEntity(ent, eyePosition, NULL_VECTOR, NULL_VECTOR);
		
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
		
	AcceptEntityInput(ent, "TurnOn");
	CreateTimer(6.5, SnowOff, ent);
	CreateTimer(15.0, KillEntity, ent);
}

public Action:SnowOff(Handle: timer, any: ent){ AcceptEntityInput(ent, "TurnOff"); }
/*
//https://developer.valvesoftware.com/wiki/Func_precipitation
public CreateSnowFullMap(){
	new ent = CreateEntityByName("func_precipitation");
	new Float:minbounds[3],Float:maxbounds[3],Float:m_vecOrigin[3];
	
	new String:buffer[128];
	GetCurrentMap(buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "maps/%s.bsp", buffer);

	DispatchKeyValue(ent, "model", buffer);
	DispatchKeyValue(ent, "preciptype", "3");//0 = Rain , 2 = Ash , 3 = Snowfall
	DispatchKeyValue(ent, "renderamt", "5"); //Density (0-100%) renderamt <integer> 
	DispatchKeyValue(ent, "rendercolor", "255 255 255");
	//DispatchKeyValue(ent, "minSpeed", ""); //Minimum speed (snowfall only) minSpeed <float> 
	//DispatchKeyValue(ent, "maxSpeed", ""); //Maximum speed (snowfall only) maxSpeed <float> 
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	GetEntPropVector(0, Prop_Data, "m_WorldMins", minbounds);
	GetEntPropVector(0, Prop_Data, "m_WorldMaxs", maxbounds);
	SetEntPropVector(ent, Prop_Send, "m_vecMins", minbounds);
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", maxbounds);
	
	m_vecOrigin[0] = (minbounds[0] + maxbounds[0]) / 2;
	m_vecOrigin[1] = (minbounds[1] + maxbounds[1]) / 2;
	m_vecOrigin[2] = (minbounds[2] + maxbounds[2]) / 2;
	
	TeleportEntity(ent, m_vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	//PrintToChatAll("%f %f %f",minbounds[0],minbounds[1],minbounds[2])
	//PrintToChatAll("%f %f %f",maxbounds[0],maxbounds[1],maxbounds[2])
}
*/
//===================================================================================================================
//BirdFly Reference:
//Fly Command				https://forums.alliedmods.net/showthread.php?p=1687851
//[L4D & L4D2] Flying Tank	https://forums.alliedmods.net/showthread.php?p=900622
//https://sm.alliedmods.net/api/index.php?fastload=file&id=47&
new SlayLoserBird[65]
public BirdFly(client){
	if(!StatusCheck(client)) return;
	ThirdPerson(client)
	SetEntityGravity(client, 0.3)
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	new BirdType = GetRandomInt(1,1)
	switch(BirdType){
		case 1:SetEntityModel(client, "models/crow.mdl");
		case 2:SetEntityModel(client, "models/pigeon.mdl");
		case 3:SetEntityModel(client, "models/seagull.mdl");
	}
	
	SlayLoserBird[client] = 6
	PrintHintText(client,"%T : %d \n%T","PunishName12",LANG_SERVER,SlayLoserBird[client],"PunishName12_Help",LANG_SERVER)
	
	CreateTimer(1.0, BirdBlyCounter	, client);
	CreateTimer(4.0, BirdThunder	, client);
	CreateTimer(5.0, BirdThunder	, client);
	CreateTimer(6.37,BirdStop		, client);
	CreateTimer(6.4, BirdThunder	, client);
	CreateTimer(6.5, ClientKillDelay, client);
	CreateTimer(6.5, BirdExplosion	, client);
	
	new String:BirdTypeSound[64],Float:pos[3]
	GetClientAbsOrigin(client, pos);
	if(BirdType == 1){
		switch(GetRandomInt(1,3)){
			case 1:BirdTypeSound = "ambient/animal/crow.wav"
			case 2:BirdTypeSound = "ambient/animal/crow_1.wav"
			case 3:BirdTypeSound = "ambient/animal/crow_2.wav"
		}
	}
	if(BirdType == 2) Format(BirdTypeSound,sizeof(BirdTypeSound),"ambient/creatures/pigeon_idle%d.wav",GetRandomInt(1,4))
	if(BirdType == 3) Format(BirdTypeSound,sizeof(BirdTypeSound),"ambient/creatures/seagull_idle%d.wav",GetRandomInt(1,3))
	EmitAmbientSound2(BirdTypeSound, pos, client, SNDLEVEL_RAIDSIREN)
}

public Action:BirdStop(Handle: timer, any: client){ SetEntityMoveType(client, MOVETYPE_NONE);}
public Action:BirdThunder(Handle: timer, any: client){
	decl String:namebegin[64] = "LaserBeam0", String:nameend[64] = "LaserBeam_end0", String:number[32];
	IntToString(client, number, 32);
	ReplaceString(namebegin, 64, "0", number, false);
	ReplaceString(nameend, 64, "0", number, false);
	
	new Float:clientposOrgin[3],Float:clientposOrgin2[3]
	GetClientAbsOrigin(client, clientposOrgin);
	GetClientEyePosition(client, clientposOrgin2);
	clientposOrgin2[2] += 2000
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client,"10");
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client,"10");
	
	new String:ThunderSound[64]
	Format(ThunderSound,sizeof(ThunderSound),"ambient/playonce/weather/thunder%d.wav",GetRandomInt(4,6))
	EmitAmbientSound2(ThunderSound, clientposOrgin, client, SNDLEVEL_RAIDSIREN)
}

public Action:BirdExplosion(Handle: timer, any: client){
	new Float:clientposOrgin[3]
	GetClientAbsOrigin(client, clientposOrgin);
	//TE_SetupExplosion(const Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, const Float:normal[3]=
	TE_SetupExplosion2(client,clientposOrgin, g_ExplosionSprite, 0.1, 1, 0, 600, 5000);
	
	new String:ThunderSound[64]
	switch(GetRandomInt(1,3)){
		case 1:ThunderSound = "ambient/playonce/weather/thunder_distant_01.wav"
		case 2:ThunderSound = "ambient/playonce/weather/thunder_distant_02.wav"
		case 3:ThunderSound = "ambient/playonce/weather/thunder_distant_06.wav"
	}
	EmitAmbientSound2(ThunderSound, clientposOrgin, client, SNDLEVEL_RAIDSIREN)
}

public Action:BirdBlyCounter(Handle: timer, any: client){
	SlayLoserBird[client] -= 1
	if(SlayLoserBird[client] >= 0 && StatusCheck(client)){
		CreateTimer(1.0, BirdBlyCounter, client);
		if(SlayLoserBird[client] >= 3) 
				PrintHintText(client,"%T : %d \n%T","PunishName12",LANG_SERVER,SlayLoserBird[client],"PunishName12_Help",LANG_SERVER)
		else 	PrintCenterText(client, "%T : %d\n%T","PunishName12",LANG_SERVER,SlayLoserBird[client],"PunishName12_Help",LANG_SERVER)
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){
	if(SlayLoserBird[client] <= 0 || !StatusCheck(client)) return;
	if(buttons & IN_JUMP && buttons & IN_FORWARD){
		new Float:vec[3]
		GetAngleVectors(angles, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec , vec);
		
		if(buttons & IN_SPEED)
				ScaleVector(vec, 550.0);
		else 	ScaleVector(vec, 300.0);
		vec[2] +=200
		
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	}
}

//===================================================================================================================
//Chicken Reference:
//[CSGO] Exploding Chickens?! 	https://forums.alliedmods.net/showthread.php?p=2277923 
//[CSGO] Chicken Spawner 		https://forums.alliedmods.net/showthread.php?p=2283192
//[TF2]  MakeMeInvisible! 		https://forums.alliedmods.net/showthread.php?p=1595691
//[CSGO] Zombie Chickens		https://forums.alliedmods.net/showthread.php?p=2315762
//[CS:S] Thirdperson [1.5]		https://forums.alliedmods.net/showthread.php?p=1776475

public Chicken(client){
	if(!StatusCheck(client)) return;
	ThirdPerson(client)
	SetEntityRenderMode(client, RENDER_NONE);
	SetEntityMoveType(client, MOVETYPE_NONE);
	
	ChickenParticle(client)
	ChickenSpawn(client,true)
	ChickenSpawn(client,false)
	CreateTimer(3.5, ClientKillDelay, client);
	
	new Float:start_cor[3]
	GetClientAbsOrigin(client, start_cor);
	EmitAmbientSound2(CacheSound[GetRandomInt(69,80)], start_cor, client, SNDLEVEL_RAIDSIREN)
}

public ChickenParticle(client){
	if(!StatusCheck(client)) return;
	if(GetRandomInt(0,1)) 
			CreateParticlePub(client,"chicken_gone_feathers_zombie","-90 0 0",3.0)
	else	CreateParticlePub(client,"chicken_gone_feathers","-90 0 0",3.0)
}

public ChickenSpawn(client,Inv){
	if(!StatusCheck(client)) return;
	new chicken = CreateEntityByName("chicken"); //The Chicken
	if(!IsValidEntity(chicken)) return;
	
	new Float:start_cor[3],Float:ang[3]
	GetClientAbsOrigin(client, start_cor);
	GetClientEyeAngles(client, ang);
	
	new String:glowcolor[32]
	Format(glowcolor,sizeof(glowcolor),"%d %d %d",GetRandomInt(50,255),GetRandomInt(50,255),GetRandomInt(50,255))
	
	if(Inv) DispatchKeyValue(chicken, "glowenabled", "0"); 		//Glowing (0-off, 1-on)
	else 	DispatchKeyValue(chicken, "glowenabled", "1"); 		//Glowing (0-off, 1-on)
	DispatchKeyValue(chicken, "glowcolor", glowcolor); 			//Glowing color (R, G, B)
	DispatchKeyValue(chicken, "rendercolor", "255 255 255"); 	//Chickens model color (R, G, B)
	DispatchKeyValue(chicken, "modelscale", "2.5"); 			//Chickens model scale
	DispatchSpawn(chicken);
	
	switch(GetRandomInt(1,3)){ //Chickens model skin(default white 0, brown is 1)
		case 1:DispatchKeyValue(chicken, "skin", "0");
		case 2:DispatchKeyValue(chicken, "skin", "1");
		case 3:SetEntityModel(chicken, "models/chicken/chicken_zombie.mdl");
	}
	
	if(Inv){
		SetEntityRenderMode(chicken, RENDER_TRANSCOLOR);
		SetEntityRenderColor(chicken, 255, 255, 255, 0);
	}
	
	SetEntPropFloat(chicken, Prop_Data, "m_explodeDamage", 5.0);
	SetEntPropFloat(chicken, Prop_Data, "m_explodeRadius", 50.0);
	
	CreateTimer(3.5, ChickenBreak, chicken);
	SDKHook(chicken, SDKHook_OnTakeDamage, OnTakeDamage);
	HookSingleEntityOutput(chicken, "OnBreak", OnChickenBreak);
	
	TeleportEntity(chicken, start_cor, ang, NULL_VECTOR);
}

public Action:ChickenBreak(Handle: timer, any: chicken){ if(IsValidEntity(chicken)) AcceptEntityInput(chicken, "Break"); }
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon,Float:damageForce[3], Float:damagePosition[3], damagecustom)
{ damage = 0.0; return Plugin_Changed; }
public OnChickenBreak(const String: output[], caller, activator, Float: delay){
	if(GetRandomInt(0,1))
			CreateParticlePub(caller,"chicken_gone_feathers_zombie","-90 0 0",3.0)
	else	CreateParticlePub(caller,"chicken_gone_feathers","-90 0 0",3.0)
	
	if(GetRandomInt(0,1)) 
			EmitSound2("weapons/hegrenade/explode3.wav", caller);
	else 	EmitSound2(CacheSound[GetRandomInt(82,84)], caller);
}

//===================================================================================================================
//Fire Fly
public FireFly(client){}
/*
public FireFly(client){
	PrintToChatAll("FireFly:%N",client)
	
	//new Float:start_cor[3];
	//GetClientAbsOrigin(client, start_cor);
	
	new Float:rorigin[3];
	for(new i = 1 ;i < 50; ++i){
		//rorigin = start_cor;
		rorigin[0] = GetRandomFloat(-3000.0,3000.0);
		rorigin[1] = GetRandomFloat(-3000.0,3000.0);
		rorigin[2] = GetRandomFloat(-20.0,2000.0);
		
		//if(GetRandomInt(0,2) == 0) rorigin[0] = rorigin[0] * -1;
		//if(GetRandomInt(0,2) == 0) rorigin[1] = rorigin[1] * -1;
		//if(GetRandomInt(0,2) == 0) rorigin[2] = rorigin[2] * -1;
		
		explodeall(rorigin);
	}
}
*/

//Nukem!	https://forums.alliedmods.net/showthread.php?p=609299
stock explodeall(Float:vec1[3]){
	SetRandomSeed(GetRandomInt( -99999 , 99999 ))
	
	vec1[2] += 10;
	//new color[4]={188,220,255,255};
	new color[4]
	color[0] = GetRandomInt(50,255)
	color[1] = GetRandomInt(50,255)
	color[2] = GetRandomInt(50,255)
	color[3] = GetRandomInt(50,255)
	
	new ar2_muzzle1 = -1
	//ar2_muzzle1 = PrecacheModel("materials/sprites/blueglow1.vmt",true;
	//ar2_muzzle1 = PrecacheModel("materials/sprites/ledglow.vmt",true);
	//ar2_muzzle1 = PrecacheModel("materials/sprites/muzzleflash4.vmt",true);
	//ar2_muzzle1 = PrecacheModel("materials/sprites/purpleglow1.vmt",true);
	//ar2_muzzle1 = PrecacheModel("materials/sprites/zerogxplode.vmt",true);
	//ar2_muzzle1 = PrecacheModel("materials/sprites/xfireball3.vmt",true);
	ar2_muzzle1 = PrecacheModel("materials/sprites/yelflare1.vmt",true);
	//TE_SetupBeamRingPoint(const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame,FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags)
	TE_SetupBeamRingPoint(vec1, 10.0, 1500.0, ar2_muzzle1, g_HaloSprite, 0, 66, 10.0, 128.0, 0.2, color, 25, 0);
  	TE_SendToAll();
}

//https://developer.valvesoftware.com/wiki/Env_screeneffect
//===================================================================================================================
//thunder Reference:
//Laser Sentry by icequeenzz	https://gist.github.com/icequeenzz/845406
//https://developer.valvesoftware.com/wiki/Env_beam

public Thunder(client){ 
	if(!StatusCheck(client)) return;
	SetEntityMoveType(client, MOVETYPE_NONE);
	CreateTimer(0.1, ThunderGlow, client);
	CreateTimer(1.0, ThunderGlow, client);
	CreateTimer(1.5, ThunderBeamLaser, client);
	CreateTimer(2.0, ThunderBeamLaser, client);
	CreateTimer(3.0, ThunderBeam, client);
	CreateTimer(3.1, ThunderBeam, client);
	CreateTimer(3.0, ThunderParticle, client);
	CreateTimer(3.1, ThunderParticle, client);
	CreateTimer(3.25,ThunderParticle, client);
	CreateTimer(3.3, ClientKillDelay, client);
	CreateTimer(5.0, ThunderStop, client);
}

public Action:ThunderParticle(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	CreateParticlePub(client,"c4_train_ground_glow_02","-90 0 0",5.0)
}

public Action:ThunderStop(Handle: timer, any: client){
	new Float:pos[3]
	GetClientAbsOrigin(client, pos);
	pos[2] += 10
	EmitAmbientSound2("ambient/machines/air_conditioner_cycle.wav"	, pos, client, SNDLEVEL_RAIDSIREN,SND_STOPLOOPING)
}

public Action:ThunderGlow(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	new Float:clientposOrgin[3]
	GetClientAbsOrigin(client, clientposOrgin);
	clientposOrgin[2] += 35
	TE_SetupGlowSprite2(client,clientposOrgin,GLOW_SPRITE, 8.0, 2.0, 600)
	GetClientEyePosition(client, clientposOrgin);
	TE_SetupGlowSprite2(client,clientposOrgin,GLOW_SPRITE2, 8.0, 2.0, 600)
	EmitAmbientSound2("ambient/machines/air_conditioner_cycle.wav"	, clientposOrgin, client, SNDLEVEL_RAIDSIREN)
}

public Action:ThunderBeamLaser(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	new Float:pos[3],Float:pos2[3],randm = GetRandomInt( -2 , 2 )
	GetClientAbsOrigin(client, pos);
	GetClientEyePosition(client, pos2);
	pos2[2] += 10
	
	pos[0] += randm
	pos[1] += randm
	pos2[0] += randm
	pos2[1] += randm
	
	new rendercolor2[4]
	rendercolor2[0] = GetRandomInt( 0 , 255 )
	rendercolor2[1] = GetRandomInt( 0 , 255 )
	rendercolor2[2] = GetRandomInt( 0 , 255 )
	rendercolor2[3] = 255
	//TE_SetupBeamPoints2(client,const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life,Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed)
	TE_SetupBeamPoints2(client,pos,pos2,g_BeamSprite4, g_HaloSprite,0,500,5.0,2.0,5.0,-100,50.0,rendercolor2, 100)
}

public Action:ThunderBeam(Handle: timer, any: client){
	if(!StatusCheck(client)) return;
	
	decl String:namebegin[64] = "LaserBeam0", String:nameend[64] = "LaserBeam_end0", String:number[32];
	IntToString(client, number, 32);
	ReplaceString(namebegin, 64, "0", number, false);
	ReplaceString(nameend, 64, "0", number, false);
	
	new Float:clientposOrgin[3],Float:clientposOrgin2[3]
	GetClientAbsOrigin(client, clientposOrgin);
	GetClientEyePosition(client, clientposOrgin2);
	clientposOrgin2[2] += 10
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client);
	CreateBeam(namebegin, nameend, clientposOrgin, clientposOrgin2, client);
	EmitAmbientSound2(CacheSound[GetRandomInt( 66 , 68 )], clientposOrgin, client, SNDLEVEL_RAIDSIREN)
}

stock CreateBeam(const String:startname[],const String:endname[], const Float:start[3], const Float:end[3], client,const String:NoiseAmplitude[] = "50"){
	// create laser beam
	new beam_ent = CreateEntityByName("env_beam");
	new startpoint_ent = CreateEntityByName("env_beam");
	new endpoint_ent = CreateEntityByName("env_beam");
	
	TeleportEntity(startpoint_ent, start, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(endpoint_ent, end, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(startpoint_ent, "targetname", startname);
	DispatchKeyValue(endpoint_ent, "targetname", endname);
	
	DispatchSpawn(startpoint_ent);
	DispatchSpawn(endpoint_ent);
	
	SetEntityModel(beam_ent, "materials/sprites/physbeam.vmt");
	
	decl String:Client[128];
	IntToString(client, Client, 128);
	
	SetRandomSeed(GetRandomInt( 1 , 999 ))
	
	new String:rendercolor[32]
	Format(rendercolor,sizeof(rendercolor),"%d %d %d",GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ))
	DispatchKeyValue(beam_ent, "rendercolor", rendercolor);
	
	SetRandomSeed(GetRandomInt( 1 , 999 ))
	new String:BoltWidth[32]
	FloatToString(GetRandomFloat(2.0, 5.0),BoltWidth, sizeof(BoltWidth));
	DispatchKeyValue(beam_ent, "BoltWidth", BoltWidth);
	
	DispatchKeyValue(beam_ent, "targetname", Client);
	DispatchKeyValue(beam_ent, "texture", "materials/sprites/physbeam.vmt");
	DispatchKeyValue(beam_ent, "TouchType", "4");
	DispatchKeyValue(beam_ent, "life", "2.5");
	DispatchKeyValue(beam_ent, "StrikeTime", "0.1");
	DispatchKeyValue(beam_ent, "renderamt", "255");
	DispatchKeyValue(beam_ent, "HDRColorScale", "10.0");
	DispatchKeyValue(beam_ent, "decalname", "redglowfade"); //"Bigshot" "redglowfade"
	DispatchKeyValue(beam_ent, "TextureScroll", "5");
	DispatchKeyValue(beam_ent, "LightningStart", startname);
	DispatchKeyValue(beam_ent, "LightningEnd", endname);
	
	DispatchKeyValue(beam_ent, "ClipStyle", "1");
	DispatchKeyValue(beam_ent, "NoiseAmplitude", NoiseAmplitude);
	//DispatchKeyValue(beam_ent, "damage", "500");
	//DispatchKeyValue(beam_ent, "Radius", "256");
	//DispatchKeyValue(beam_ent, "framerate", "50");
	//DispatchKeyValue(beam_ent, "framestart", "1");
	DispatchKeyValue(beam_ent, "spawnflags", "4");
	
	DispatchSpawn(beam_ent);
	ActivateEntity(beam_ent);
	AcceptEntityInput(beam_ent, "StrikeOnce");
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"Beam_%d",client);
	DispatchKeyValue(client, "targetname", targetname)
	SetVariantString(targetname);
	AcceptEntityInput(endpoint_ent, "SetParent");
	
	CreateTimer(0.5, KillEntity, beam_ent);
	CreateTimer(0.5, KillEntity, startpoint_ent);
	CreateTimer(0.5, KillEntity, endpoint_ent);
}

//===================================================================================================================
//Tesla Lighting
//https://developer.valvesoftware.com/wiki/Point_tesla
//sound\ambient\energy\zap1.wav
public Tesla(client){
	if(!StatusCheck(client)) return;
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 0);
	CreateTimer(0.1, Tesla2, Hpack);
}

public Action: Tesla2(Handle: timer, any: Hpack){
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new count = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(!StatusCheck(client)) return;
	if(count >= 11){
		ClientKill(client)
		return;
	}
	
	SetEntityHealth(client, GetRandomInt(1,999))
	SetEntProp( client, Prop_Send, "m_ArmorValue", GetRandomInt(1,125), 1 );
	
	new TeslaL = CreateEntityByName("point_tesla");
	if(!IsValidEntity(TeslaL)) return;
	
	new EyeAbsRand = GetRandomInt(1,2)
	new Float:clientposOrgin[3],Float:clientposOrgin2[3]
	switch(EyeAbsRand){
		case 1: GetClientAbsOrigin(client, clientposOrgin);
		case 2: GetClientEyePosition(client, clientposOrgin);
	}
	
	clientposOrgin[2] += 10
	clientposOrgin2[0] += GetRandomInt( -150 , 150 )
	clientposOrgin2[1] += GetRandomInt( -150 , 150 )
	clientposOrgin2[2] += (EyeAbsRand == 1) ? 255:-100
	TeleportEntity(TeslaL, clientposOrgin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, clientposOrgin2);
	
	new String:m_Color[32]
	Format(m_Color,sizeof(m_Color),"%d %d %d",GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ),GetRandomInt( 0 , 255 ))
	DispatchKeyValue(TeslaL, "m_Color", m_Color);
		
	new String:texture[64]
	switch(GetRandomInt(1,8)){
		case 1: Format(texture,sizeof(texture),"sprites/zerogxplode.vmt")
		case 2: Format(texture,sizeof(texture),"sprites/physbeam.vmt")
		case 3: Format(texture,sizeof(texture),"sprites/spectator_eye.vmt")
		case 4: Format(texture,sizeof(texture),"sprites/purplelaser1.vmt")
		case 5: Format(texture,sizeof(texture),"sprites/muzzleflash4.vmt")
		case 6: Format(texture,sizeof(texture),"sprites/light_glow04.vmt")
		case 7: Format(texture,sizeof(texture),"sprites/bomb_planted_ring.vmt")
		case 8: Format(texture,sizeof(texture),"sprites/obj_icons/kills.vmt")
	}
	//DispatchKeyValue(TeslaL, "texture", "sprites/obj_icons/kills.vmt");
	DispatchKeyValue(TeslaL, "texture", texture);
	
	DispatchKeyValue(TeslaL, "m_SoundName", "DoSpark");
	//scripts\game_sounds_ambient_generic.txt
	
	DispatchKeyValue(TeslaL, "thick_min", "4");
	DispatchKeyValue(TeslaL, "thick_max", "4");
	DispatchKeyValue(TeslaL, "m_flRadius", "150");
	DispatchKeyValue(TeslaL, "lifetime_min", "0.8");
	DispatchKeyValue(TeslaL, "lifetime_max", "0.8");
	DispatchKeyValue(TeslaL, "interval_min", "0.1");
	DispatchKeyValue(TeslaL, "interval_max", "0.1");
	DispatchKeyValue(TeslaL, "beamcount_min", "5");
	DispatchKeyValue(TeslaL, "beamcount_max", "10");
	
	DispatchSpawn(TeslaL);
	ActivateEntity(TeslaL);
	
	new String:targetname[32]
	Format(targetname,sizeof(targetname),"Tesla_%d",client);
	DispatchKeyValue(client, "targetname", targetname)
	SetVariantString(targetname);
	AcceptEntityInput(TeslaL, "SetParent");
	AcceptEntityInput(TeslaL, "TurnOn");
	
	new Handle:Hpack3 = CreateDataPack();
	WritePackCell(Hpack3, client);
	WritePackCell(Hpack3, count+=1);
	CreateTimer(0.5, Tesla2, Hpack3);
	CreateTimer(0.2, KillEntity, TeslaL);
	
	CreateParticlePub(client,"extinguish_embers_small_02")
	CreateParticlePub(client,"extinguish_embers_small_02")
	CreateParticlePub(client,"extinguish_embers_small_02")
}

//===================================================================================================================
//FireWorks

//https://developer.valvesoftware.com/wiki/List_of_TF2_Particles
//https://developer.valvesoftware.com/wiki/List_of_L4D_Particles
//https://developer.valvesoftware.com/wiki/List_of_L4D2_Particles
//https://developer.valvesoftware.com/wiki/Half-Life_2:_Episode_Two_Particle_Effect_List:ru
//https://developer.valvesoftware.com/wiki/Half-Life_2:_Episode_Two_Particle_Effect_List

//https://developer.valvesoftware.com/wiki/Particle_Editor
//https://developer.valvesoftware.com/wiki/Info_particle_system
//https://developer.valvesoftware.com/wiki/List_of_CS_GO_Particles
//https://www.reddit.com/r/GlobalOffensive/comments/29mabs/you_can_now_use_tools_on_csgo/
//http://tieba.baidu.com/p/3272481340
//https://www.youtube.com/watch?v=JgkxgzR7ByE

public FireWorks(client){
	new Float:g_fDir[3];
	new Float:clientposOrgin[3]
	GetClientAbsOrigin(client, clientposOrgin);
	//GetClientAbsOrigin(client, g_fDir);
	
	//TE_SetupSparks(clientposOrgin, g_fDir, 10, 10);
	//TE_SendToAll();
	
	clientposOrgin[2] += 100
	
	TE_SetupSparks(clientposOrgin, g_fDir, 1, 2);
	TE_SendToAll();
	
	g_fDir[1] -= 5
	g_fDir[2] -= 100
	
	TE_SetupSparks(clientposOrgin, g_fDir, 100, 1000);
	TE_SendToAll();
	
	//AttachParticle(client, "explosion_screen_c4_red",true)
	//AttachParticle(client, "extinguish_embers_small_02")
	CreateParticleE(client)
	CreateParticleE(client)
	CreateParticleE(client)
	CreateParticleE(client)
}
//extinguish_embers_small_02
//c4_train_ground_glow_02
//c4_train_ground_low_02
CreateParticleE(entity){	
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle)){
		new Float: pos[3];
		//GetClientEyePosition(entity, pos);
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", "c4_train_ground_low_02");
		//DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers");
		//DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers_zombie");
		DispatchKeyValue(particle, "angles", "-90 0 0");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		CreateTimer(5.0, KillEntity, particle);
	}
}

//===================================================================================================================
//Fire Fly
//GetClientEyeAngles http://docs.sourcemod.net/api/index.php?fastload=show&id=44&
//ang[0]: pitch (up / down) 
//ang[1]: yaw   (left / right)
//ang[2]: roll  (tilt) 傾斜
//new g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]")
public FireFlyOld(client){

	
	//SetEntityMoveType(client, MOVETYPE_FLY);
	//SetEntProp(client, Prop_Data, "m_takedamage",2, 1);
	
	//new Float:EyeAngles[3],Float:clientposOrgin[3],Float:clienteyeOrgin[3]
	//GetClientEyeAngles(client,EyeAngles)
	//GetClientEyePosition(client, clienteyeOrgin);
	//GetClientAbsOrigin(client, clientposOrgin);
	
	//new Float:vec[3]//,Float:vec2[3]
	//GetEntDataVector(client, g_iVelocity, vec);
	//GetClientMaxs(client, vec);
	//GetClientMins(client, vec);
	//GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	//PrintToChat(client,"[0]:%f , [1]:%f , [2]:%f",vec[0],vec[1],vec[2])
	//PrintToChat(client,"[0]:%d , [1]:%d",RoundToFloor(EyeAngles[0]),RoundToFloor(EyeAngles[1]))
	//PrintToChat(client,"[0]:%f , [1]:%f , [2]:%f",vec[0],vec[1],vec[2])
	//vec[0] = 100.0
	//vec[1] = 0.0
	//vec[2] = 0.0
	
	//vec2[0] = 0.0
	//vec2[1] = 0.0
	//vec2[2] = 0.0
	
	//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
	
	//if(EyeAngles[1] > 0) clientposOrgin[1] -= 1.0
	//else clientposOrgin[0] += 1.0
	
	/*
	if(EyeAngles[1] > 0) clientposOrgin[1] -= 1.0
	else clientposOrgin[1] += 1.0
	*/
	//clientposOrgin[0] -= EyeAngles[0]
	//clientposOrgin[1] += EyeAngles[1]
	
	//PrintToChat(client,"[0]:%d , [1]:%d",RoundToFloor(EyeAngles[0]),RoundToFloor(EyeAngles[1]))
	//PrintToChat(client,"[0]:%f , [1]:%f , [2]:%f",clientposOrgin[0],clientposOrgin[1],clientposOrgin[2])
	//PrintToChat(client,"[0]:%f , [1]:%f , [2]:%f",clienteyeOrgin[0],clienteyeOrgin[1],clienteyeOrgin[2])
	
	//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, clientposOrgin);
	
	//CreateTimer(0.1, Timer_FireFly, client,TIMER_REPEAT);
}

public Action:Timer_FireFly(Handle:timer, any:client){
	if(!IsPlayerAlive(client)) KillTimer(timer)
}

//===================================================================================================================
//barrel "model" "models/props/de_train/barrel.mdl" G51091
//https://developer.valvesoftware.com/wiki/Prop_physics_override
//https://developer.valvesoftware.com/w/index.php?title=Category:Source_Base_Entities&from=Npc+puppet
public BarrelExp(client){
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntProp(client, Prop_Data, "m_takedamage",2, 1);
	BarrelTimes(client,2)
}

public BarrelTimes(client,Times){
	new Float:clientposOrgin[3]
	//GetClientAbsOrigin(client, clientposOrgin);
	GetClientEyePosition(client, clientposOrgin);
	
	for(new i = 1;i < Times;i++){
		//new PropHurt = CreateEntityByName("prop_physics_override");
		new PropHurt = CreateEntityByName("prop_physics_multiplayer");
		if(PropHurt){
			clientposOrgin[2] += 60
			SetEntityModel(PropHurt,"models/props/de_train/barrel.mdl")
			TeleportEntity(PropHurt, clientposOrgin, NULL_VECTOR, NULL_VECTOR);
			DispatchKeyValue(client, "targetname", "explodemebarrel");
			//DispatchKeyValue(PropHurt, "DamageTarget", "explodemebarrel");
			DispatchKeyValue(PropHurt, "damagefilter", "explodemebarrel");
			DispatchKeyValue(PropHurt, "DamageType", "0");
			DispatchKeyValue(PropHurt,"spawnflags" ,"816")
			DispatchKeyValue(PropHurt,"skin", "0")
			DispatchKeyValue(PropHurt,"shadowdepthnocache" ,"0")
			DispatchKeyValue(PropHurt,"shadowcastdist" ,"0")
			DispatchKeyValue(PropHurt,"pressuredelay", "0")
			DispatchKeyValue(PropHurt,"physdamagescale" ,"0.1")
			DispatchKeyValue(PropHurt,"PerformanceMode" ,"0")
			DispatchKeyValue(PropHurt,"nodamageforces" ,"0")
			//DispatchKeyValue(PropHurt,"model" ,"models/props/de_train/barrel.mdl")
			DispatchKeyValue(PropHurt,"minhealthdmg" ,"0")
			DispatchKeyValue(PropHurt,"mingpulevel", "0")
			DispatchKeyValue(PropHurt,"mincpulevel", "0")
			DispatchKeyValue(PropHurt,"maxgpulevel" ,"0")
			DispatchKeyValue(PropHurt,"maxcpulevel", "0")
			DispatchKeyValue(PropHurt,"massScale", "0")
			DispatchKeyValue(PropHurt,"inertiaScale" ,"1.0")
			DispatchKeyValue(PropHurt,"health" ,"0")
			//DispatchKeyValue(PropHurt,"health" ,"99999")
			DispatchKeyValue(PropHurt,"forcetoenablemotion" ,"0")
			DispatchKeyValue(PropHurt,"fadescale", "1")
			DispatchKeyValue(PropHurt,"fademindist" ,"-1")
			DispatchKeyValue(PropHurt,"fademaxdist", "0")
			DispatchKeyValue(PropHurt,"ExplodeRadius", "100")
			DispatchKeyValue(PropHurt,"ExplodeDamage", "600")
			DispatchKeyValue(PropHurt,"drawinfastreflection", "0")
			DispatchKeyValue(PropHurt,"disableX360", "0")
			DispatchKeyValue(PropHurt,"disableshadows" ,"0")
			DispatchKeyValue(PropHurt,"disableshadowdepth" ,"0")
			DispatchKeyValue(PropHurt,"disableflashlight", "0")
			DispatchKeyValue(PropHurt,"damagetoenablemotion" ,"0")
			DispatchKeyValue(PropHurt,"body" ,"0")
			DispatchKeyValue(PropHurt,"angles" ,"0 0 90")
			//DispatchKeyValue(PropHurt, "classname", "prop_physics_override");
			DispatchSpawn(PropHurt);
			
			//AcceptEntityInput(PropHurt, "Ignite");
			
			//DispatchKeyValue(client, "targetname", "");
			
			new Handle:Hpack2 = CreateDataPack();
			WritePackCell(Hpack2, client);
			WritePackCell(Hpack2, PropHurt);
			CreateTimer(1.0, Timer_BarrelExp, Hpack2);
		}
	}
}

public Action:Timer_BarrelExp(Handle:timer, any:Hpack){
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new ent = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(IsValidEntity(ent)){
		/*
		if(!IsPlayerAlive(client)){
			RemoveEdict(ent);
			return;
		}
		*/
		new Float:clientposOrgin[3]
		GetClientEyePosition(client, clientposOrgin);
	
		AcceptEntityInput(ent, "Ignite",-1);
		//RemoveEdict(ent);
		TeleportEntity(ent, clientposOrgin, NULL_VECTOR, NULL_VECTOR);
	}
	
	//CreateTimer(0.5, Timer_BarrelExp2, client);
}

public Action:Timer_BarrelExp2(Handle:timer, any:client){ if(IsPlayerAlive(client)) ClientKill(client); }

//===================================================================================================================
//I can Fly
public DeadFly(client){
	if(!StatusCheck(client)) return;
	new Float:clientposOrgin[3]
	GetClientAbsOrigin(client, clientposOrgin);
	SetRandomSeed(GetRandomInt( -999 , 999 ))
	TE_SetupBeamFollow2(client,client, g_BeamSprite,	0, 2.0, 4.0,3.0, 1, FragColor);
	EmitAmbientSound2(CacheSound[GetRandomInt( 1 , 25 )], clientposOrgin, client, SNDLEVEL_RAIDSIREN)
	
	CreateTimer(0.2, Timer_DeadFly, client,TIMER_REPEAT);
	CreateTimer(2.6, Timer_DeadFly2, client);
	CreateTimer(3.0, Timer_DeadFly3, client);
}

public Action:Timer_DeadFly(Handle:timer, any:client){
	if(!StatusCheck(client)){
		KillTimer(timer)
		return;
	}
	
	new Float:clientposOrgin[3],Float:UD[3]
	GetClientAbsOrigin(client, clientposOrgin);
	floatAddTo(clientposOrgin,UD,GetRandomInt(0,1) ?-3000:3000,GetRandomInt(0,1) ?-3000:3000,GetRandomInt(0,1) ?-3000:3000);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, UD);
}

public Action:Timer_DeadFly2(Handle:timer, any:client){ if(StatusCheck(client)) SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); }
public Action:Timer_DeadFly3(Handle:timer, any:client){ if(StatusCheck(client)) ClientKill(client); }

//===================================================================================================================
//Sword ( unlimit blade works )
public Sword(client){ //7
	if(!StatusCheck(client)) return;
	SetEntityRenderColor(client, 54, 54, 54, 192);
	SetEntityHealth(client, 102)
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, 0);
	CreateTimer(0.5, Timer_Sword, Hpack2);
}

public Action:Timer_Sword(Handle:timer, any:Hpack){
	ResetPack(Hpack)
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(!StatusCheck(client)) return;
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	if(GetClientHealth(client) <= 17) ClientKill(client)
	else SlapPlayer(client, 17, true)
	SlapPlayer(client, 0, true)
	SlapPlayer(client, 0, true)
	//SetEntityMoveType(client, MOVETYPE_WALK);
	
	new Float:UD[3],Float:UD2[3]
	new Float:clienteyeOrgin[3]//,Float:clientposOrgin[3]
	GetClientEyePosition(client, clienteyeOrgin);
	clienteyeOrgin[2] -= 20
	//GetClientAbsOrigin(client, clienteyeOrgin);
	SetRandomSeed(GetRandomInt( -999 , 999 ))
	EmitAmbientSound2(CacheSound[GetRandomInt( 35 , 40 )], clienteyeOrgin, client, SNDLEVEL_RAIDSIREN)
	EmitAmbientSound2(CacheSound[GetRandomInt( 26 , 34 )], clienteyeOrgin, client, SNDLEVEL_RAIDSIREN)
	
	new color[4]
	switch(GetRandomInt( 1 , 8 )){
		case 1:ArrayInt(FragColor	,color,sizeof(color))
		case 2:ArrayInt(FlashColor	,color,sizeof(color))
		case 3:ArrayInt(SmokeColor	,color,sizeof(color))
		case 4:ArrayInt(whiteColor	,color,sizeof(color))
		case 5:ArrayInt(greyColor	,color,sizeof(color))
		case 6:ArrayInt(orangeColor	,color,sizeof(color))
		case 7:ArrayInt(PurpleColor	,color,sizeof(color))
		case 8:ArrayInt(CyanColor	,color,sizeof(color))
	}
	
	if(counter == 0){//上下
		floatAddTo(clienteyeOrgin,UD,0,0,-50);
		floatAddTo(clienteyeOrgin,UD2,0,0,50);
		//TE_SetupBeamPoints2(client,start,end,	ModelIndex, 	HaloIndex,		StartFrame, FrameRate, 	Life, 	Width, 	EndWidth, 	FadeLen, 	Amplitude, 	Color, 		Speed)
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		10.0, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
	}
	if(counter == 1){//左右
		floatAddTo(clienteyeOrgin,UD,-50);
		floatAddTo(clienteyeOrgin,UD2,50);
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		10.0, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
	}
	if(counter == 2){//前後
		floatAddTo(clienteyeOrgin,UD,0,-50);
		floatAddTo(clienteyeOrgin,UD2,0,50);
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		10.0, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
	}
	if(counter == 3){//左前右後
		floatAddTo(clienteyeOrgin,UD,-50,50,-30);
		floatAddTo(clienteyeOrgin,UD2,50,-50,30);
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		9.0, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
	}
	if(counter == 4){//
		floatAddTo(clienteyeOrgin,UD,50,50,30);
		floatAddTo(clienteyeOrgin,UD2,-50,-50,-30);
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		9.5, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
	}
	if(counter == 5){//
		floatAddTo(clienteyeOrgin,UD,-50,-50,30);
		floatAddTo(clienteyeOrgin,UD2,50,50,-30);
		TE_SetupBeamPoints2(client,UD		,UD2,	g_BeamSprite4, 	g_HaloSprite, 	0,			500, 		10.0, 	0.5, 	0.5, 		-10, 		5.0, 		color, 1)
		ClientKill(client)
	}
	
	TeleportEntity(client, NULL_VECTOR, GetRandomInt( 1 , 0 )?UD:UD2, NULL_VECTOR);
	
	if(counter < 5){
		new Handle:Hpack2 = CreateDataPack();
		WritePackCell(Hpack2, client);
		WritePackCell(Hpack2, counter + 1);
		CreateTimer(0.5, Timer_Sword, Hpack2);
	}
}

//===================================================================================================================
//Quake Reference:
//http://docs.sourcemod.net/api/index.php?fastload=show&id=385&
//https://developer.valvesoftware.com/wiki/Env_beam
//https://forums.alliedmods.net/showthread.php?p=1489813
public Quake(client){
	if(!StatusCheck(client)) return;
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, 0, 128, 255, 192);
	
	new Float:clientpos[3],Float:clientpos2[3],Float:clientpos3[3],Float:clientpos4[3]
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(client, clientpos2);
	GetClientAbsOrigin(client, clientpos3);
	GetClientAbsOrigin(client, clientpos4);
	
	new rand = GetRandomInt( 41 , 49 )
	EmitAmbientSound2(CacheSound[rand], clientpos, client, SNDLEVEL_RAIDSIREN)
	new Float:ang[3] //[0]:-89.000000 , [1]:-4.884835 , [2]:0.000000
	//GetClientEyeAngles(client, ang);
	//PrintToChat(client,"[0]:%f , [1]:%f , [2]:%f",ang[0],ang[1],ang[2])
	ang[0] = -89.0
	ang[1] = -4.88
	TeleportEntity(client, NULL_VECTOR, ang, NULL_VECTOR);
	
	new Handle:Hpack3 = CreateDataPack();
	WritePackCell(Hpack3, client);
	WritePackCell(Hpack3, rand);
	WritePackFloat(Hpack3, clientpos[0]);
	WritePackFloat(Hpack3, clientpos[1]);
	WritePackFloat(Hpack3, clientpos[2]);
	ResetPack(Hpack3)
	CreateTimer(5.3 + 3.0, Timer_QuakeStopSound, Hpack3);
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, rand);
	ResetPack(Hpack2)
	CreateTimer(3.0, Timer_QuakeBeam, Hpack2);
	
	//==============================================================================================
	//向內圓環
	TE_SetupBeamRingPoint2(client,clientpos, 10000.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 4.0, 10.0, 0.0, greyColor, 1, 0);
	TE_SetupBeamRingPoint2(client,clientpos, 10000.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 10, 3.5, 20.0, 0.5, whiteColor, 1, 0);
	TE_SetupBeamRingPoint2(client,clientpos, 10.0, 10000.0, g_BeamSprite, g_HaloSprite, 0, 15, 4.0, 10.0, 0.0, greyColor, 1, 0);
	TE_SetupBeamRingPoint2(client,clientpos, 10.0, 10000.0, g_BeamSprite, g_HaloSprite, 0, 10, 3.5, 20.0, 0.5, whiteColor, 1, 0);
	
	//==============================================================================================
	//下面四角交叉
	clientpos[0] += 50
	clientpos[1] += 50
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		11.5, 	10.0, 	10.0, 		-10, 		0.1, 		orangeColor, 15)
	
	clientpos[0] -= 100
	clientpos[1] -= 100
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		11.0, 	10.0, 	10.0, 		-10, 		0.1, 		orangeColor, 15)
	
	clientpos[1] += 100
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		10.5, 	10.0, 	10.0, 		-10, 		0.1, 		orangeColor, 15)
	
	clientpos[0] += 100
	clientpos[1] -= 100
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		10.0, 	10.0, 	10.0, 		-10, 		0.1, 		orangeColor, 15)
	
	//==============================================================================================
	//上下三角
	clientpos3[2] = clientpos3[2] - 10000
	clientpos4[2] = clientpos4[2] + 10000
	
	clientpos3[0] += 50
	clientpos3[1] += 50
	TE_SetupBeamPoints2(client,clientpos3, 	clientpos4, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		11.5, 	10.0, 	10.0, 		-10, 		0.1, 		whiteColor, 15)
	
	clientpos3[0] -= 100
	clientpos3[1] -= 100
	TE_SetupBeamPoints2(client,clientpos3, 	clientpos4, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		11.0, 	10.0, 	10.0, 		-10, 		0.1, 		whiteColor, 15)
	
	clientpos3[1] += 100
	TE_SetupBeamPoints2(client,clientpos3, 	clientpos4, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		10.5, 	10.0, 	10.0, 		-10, 		0.1, 		whiteColor, 15)
	
	clientpos3[0] += 100
	clientpos3[1] -= 100
	TE_SetupBeamPoints2(client,clientpos3, 	clientpos4, g_BeamSprite2, 	g_HaloSprite, 0, 		500, 		10.0, 	10.0, 	10.0, 		-10, 		0.1, 		whiteColor, 15)
}

public Action:Timer_QuakeBeam(Handle:timer, any:Hpack){
	new client = ReadPackCell(Hpack);
	new rand = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	if(!StatusCheck(client)) return;
	new Float:clientpos[3],Float:clientpos2[3]
	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(client, clientpos2);
	
	//==============================================================================================
	//向內圓環
	TE_SetupBeamRingPoint2(client,clientpos, 1000.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 10.0, 0.0, FragColor, 1, 0);
	TE_SetupBeamRingPoint2(client,clientpos, 1000.0, 10.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 20.0, 0.5, FlashColor, 1, 0);
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, 0);
	WritePackFloat(Hpack2, clientpos[0]);
	WritePackFloat(Hpack2, clientpos[1]);
	WritePackFloat(Hpack2, clientpos[2]);
	ResetPack(Hpack2)
	
	new Handle:Hpack3 = CreateDataPack();
	WritePackCell(Hpack3, client);
	WritePackCell(Hpack3, rand);
	WritePackFloat(Hpack3, clientpos[0]);
	WritePackFloat(Hpack3, clientpos[1]);
	WritePackFloat(Hpack3, clientpos[2]);
	ResetPack(Hpack3)
	
	clientpos[2] = clientpos[2] - 10000
	clientpos2[2] = clientpos2[2] + 10000
	//TE_SetupBeamPoints2(client,start, 	end, 		ModelIndex, 	HaloIndex, StartFrame, 	FrameRate, 	Life, 	Width, 	EndWidth, 	FadeLen, 	Amplitude, 	Color, 		Speed)
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite3, 	g_HaloSprite, 0, 		500, 		6.0, 	10.0, 	10.0, 		-10, 		0.1, 		whiteColor, 15)
	
	TE_SetupBeamPoints2(client,clientpos, 	clientpos2, g_BeamSprite4, 	g_HaloSprite, 0, 		500, 		4.0, 	10.0, 	10.0, 		-10, 		0.1, 		SmokeColor, 50)
	
	EmitAmbientSound2("training/firewerks_burst_02.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
	
	if(IsPlayerAlive(client) && !g_bRoundStarted) ClientKill(client)
	
	CreateTimer(0.1, Timer_QuakeSplash, Hpack2);
	//CreateTimer(5.3, Timer_QuakeStopSound, Hpack3);
}

public Action:Timer_QuakeStopSound(Handle:timer, any:Hpack){
	new Float:clientpos[3]
	new client = ReadPackCell(Hpack);
	new rand = ReadPackCell(Hpack);
	clientpos[0] = ReadPackFloat(Hpack);
	clientpos[1] = ReadPackFloat(Hpack);
	clientpos[2] = ReadPackFloat(Hpack);
	CloseHandle(Hpack);
	EmitAmbientSound2(CacheSound[rand], clientpos, client, SNDLEVEL_RAIDSIREN,SND_STOPLOOPING)
}

public Action:Timer_QuakeSplash(Handle:timer, any:Hpack){
	new Float:Origin[3],Float:Origin2[3]
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	Origin[0] = ReadPackFloat(Hpack);
	Origin[1] = ReadPackFloat(Hpack);
	Origin[2] = ReadPackFloat(Hpack);
	Origin2[0] = Origin[0]
	Origin2[1] = Origin[1]
	Origin2[2] = Origin[2]
	CloseHandle(Hpack);
	
	if(!StatusCheck(client)) return;
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, counter + 1);
	WritePackFloat(Hpack2, Origin[0]);
	WritePackFloat(Hpack2, Origin[1]);
	WritePackFloat(Hpack2, Origin[2]);
	ResetPack(Hpack2)
	
	Origin[2] = Origin[2] + 10
	Origin2[2] = Origin2[2] + 100
	
	TE_SetupEnergySplash2(client,Origin,Origin2,true);
	TE_SetupEnergySplash2(client,Origin,Origin2,false);
	
	if(counter < 50)
			CreateTimer(0.1, Timer_QuakeSplash, Hpack2);
	else 	CloseHandle(Hpack2);
}

//===================================================================================================================
//Fire
public Fire(client){
	if(!StatusCheck(client)) return;
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 2);
	ResetPack(Hpack)
	
	IgniteEntity(client, 4.0);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	EmitAmbientSound2("ambient/nature/fire/fire_small1.wav", vec, client, SNDLEVEL_RAIDSIREN);
	EmitAmbientSound2("hostage/hpain/hpain1.wav", vec, client, SNDLEVEL_RAIDSIREN);
	SetEntityHealth(client, 100)
	CreateTimer(0.5, Timer_Fire, Hpack);
}

public Action:Timer_Fire(Handle:timer, any:Hpack){
	if(g_bRoundStarted) return;
	
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	if(!StatusCheck(client)) return;
	
	if(counter >= 7){
		new Float:vec[3];
		GetClientEyePosition(client, vec);
		EmitAmbientSound2("ambient/nature/fire/fire_small1.wav", vec, client, SNDLEVEL_RAIDSIREN,SND_STOPLOOPING)
		ClientKill(client)
		return;
	}
	
	SetEntityHealth(client, ( 100 - ( counter * 16 )) )
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	new String:HpainS[64]
	Format(HpainS,sizeof(HpainS),"hostage/hpain/hpain%d.wav",counter)
	EmitAmbientSound2(HpainS, vec, client, SNDLEVEL_RAIDSIREN);
	
	if(counter <= 6){
		new Handle:Hpack2 = CreateDataPack();
		WritePackCell(Hpack2, client);
		WritePackCell(Hpack2, counter+=1);
		ResetPack(Hpack2)
		CreateTimer(0.5, Timer_Fire, Hpack2);
	}
}

//===================================================================================================================
//Time Bomb Reference:SourceMod
public TimeBomb(client){
	if(!StatusCheck(client)) return;
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 0);
	ResetPack(Hpack)
	CreateTimer(0.0, Timer_FireBomb, Hpack);
}

public Action:Timer_FireBomb(Handle:timer, any:Hpack){
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	
	if(!StatusCheck(client)) return;
	IgniteEntity(client, 1.0);
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	if (counter <= 4){
		new Handle:Hpack2 = CreateDataPack();
		WritePackCell(Hpack2, client);
		WritePackCell(Hpack2, counter + 1);
		ResetPack(Hpack2)
		
		if (counter < 4){
			new color = RoundToFloor(counter * ( 255.0 / 10.0 ));
			
			EmitAmbientSound2("buttons/button17.wav", vec, client, SNDLEVEL_RAIDSIREN);	
			SetEntityRenderColor(client, 255, color, color, 255);
			GetClientAbsOrigin(client, vec);
			vec[2] += 10;
			
			TE_SetupBeamRingPoint2(client,vec, 10.0, 600.0 / 3.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
			TE_SetupBeamRingPoint2(client,vec, 10.0, 600.0 / 3.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, whiteColor, 10, 0);
			CreateTimer(0.7, Timer_FireBomb, Hpack2);
		}
		else {
			EmitAmbientSound2("bot/aw_hell.wav", vec, client, SNDLEVEL_RAIDSIREN);
			CreateTimer(1.5, Timer_FireBomb, Hpack2);
		}
	}
	else{
		TE_SetupExplosion2(client,vec, g_ExplosionSprite, 0.1, 1, 0, 600, 5000);
		
		GetClientAbsOrigin(client, vec);
		
		vec[2] += 10;
		TE_SetupBeamRingPoint2(client,vec, 50.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.5, 30.0, 1.5, orangeColor, 5, 0);
		vec[2] += 15;
		TE_SetupBeamRingPoint2(client,vec, 40.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 30.0, 1.5, orangeColor, 5, 0);
		vec[2] += 15;
		TE_SetupBeamRingPoint2(client,vec, 30.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.7, 30.0, 1.5, orangeColor, 5, 0);
		vec[2] += 15;
		TE_SetupBeamRingPoint2(client,vec, 20.0, 600.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.8, 30.0, 1.5, orangeColor, 5, 0);
		
		EmitAmbientSound2("weapons/c4/c4_explode1.wav", vec, client, SNDLEVEL_RAIDSIREN);
		AttachParticle(client, "explosion_hegrenade_snow_fallback2");
		ClientKill(client)
	}
}

//===================================================================================================================
//Falling Death
public Falling(client){
	if(!StatusCheck(client)) return;
	new Handle:Hpack = CreateDataPack();
	WritePackCell(Hpack, client);
	WritePackCell(Hpack, 0);
	ResetPack(Hpack)
	CreateTimer(0.1, Falling1, Hpack);
}

public Action:Falling1(Handle:timer, any:Hpack){
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	ResetPack(Hpack)
	if(!StatusCheck(client)) return;
	
	new Float:vel[3];
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 1500.0 * 1.0;
	if(counter == 0) SetEntityHealth(client, 100)
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	SetEntityGravity(client, -1.0)
	CreateTimer(0.2, Falling2, Hpack);
}

public Action:Falling2(Handle:timer, any:Hpack){
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	CloseHandle(Hpack);
	if(!StatusCheck(client)) return;
	
	if(counter == 1) SetEntityHealth(client, 75)
	if(counter == 2) SetEntityHealth(client, 50)
	if(counter == 3) SetEntityHealth(client, 25)
	if(counter >= 4){
		SetEntityHealth(client, 1)
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityGravity(client,100.0)
		CreateTimer(0.25, Falling_Dead, client);
		return;
	}
	
	SetEntityGravity(client,100.0)
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, counter + 1);
	ResetPack(Hpack2)
	
	CreateTimer(0.2, Falling1, Hpack2);
}

public Action:Falling_Dead(Handle:timer, any:client){ if(StatusCheck(client)) ClientKill(client); }
//===================================================================================================================
//Rocket Reference:
//Evil Admin: Rocket	https://forums.alliedmods.net/showthread.php?p=705667
//[ANY] Rocket 			https://forums.alliedmods.net/showthread.php?p=1678732

new Float:rForce = 0.3 //How fast a sm_rocket target is launched upwards, also translates into how far. 1= 1500 hammer units/second 2.66= 4000h/s (same as Evolve's)

public Rocket(client){
	if(!StatusCheck(client)) return;
	new Float:clientpos[3]
	GetClientAbsOrigin(client, clientpos);
	new rand = GetRandomInt(6,7);
	if (rand == 6){
		EmitAmbientSound2("ui/mm_success_lets_roll.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
		CreateTimer(2.0, Rocket2, client);
	}
	else if (rand == 7){
		EmitAmbientSound2("ui/beep22.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
		CreateTimer(0.3, Rocket2, client);
	}
	//TE_SetupBeamFollow2(client,entity, 	g_BeamSprite,	0, 			Float:1.0, 	Float:3.0, 		Float:3.0, 		1, 			FragColor);
	//TE_SetupBeamFollow2(client,EntIndex, 	ModelIndex, 	HaloIndex, 	Float:Life, Float:Width, 	Float:EndWidth, FadeLength, const Color[4])
	
	new Float:Life = 2.0;
	new Float:Width = 4.0;
	new Float:EndWidth = 3.0;
	
	switch(GetRandomInt(1,6)){
		case 1: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, FragColor);
		case 2: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, FlashColor);
		case 3: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, SmokeColor);
		case 4: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, whiteColor);
		case 5: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, greyColor);
		case 6: TE_SetupBeamFollow2(client,client, g_BeamSprite,	g_HaloSprite, Life, Width,EndWidth, 1, orangeColor);
	}
	
	switch(GetRandomInt(1,2)){
		case 1:CreateParticlePub(client,"dust_devil","-90 0 0",3.0)
		case 2:CreateParticlePub(client,"dust_devil_smoke","-90 0 0",3.0)
	}
}

public Action:Rocket2(Handle:timer, any:client){
	if(!StatusCheck(client)) return;
	
	CreateTimer(2.0, Kaboom, client);
	new Float:vel[3];
	vel[0] = 0.0;
	vel[1] = 0.0;
	vel[2] = 1500.0 * rForce;
	SetEntityGravity(client, -1.0)
	SetEntityMoveType(client, MOVETYPE_WALK);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
	AttachParticle(client, "rockettrail");
}

public Action:Kaboom(Handle:timer, any:client){
	if(!StatusCheck(client)) return;
	
	new Float:clientpos[3], Float:startpos[3];
	GetClientAbsOrigin(client, clientpos);
	
	startpos[0] = clientpos[0] + GetRandomInt(-500, 500);
	startpos[1] = clientpos[1] + GetRandomInt(-500, 500);
	startpos[2] = clientpos[2] + 800;
	
	new rand = GetRandomInt(4,5);
	if (rand == 4) EmitAmbientSound2("weapons/hegrenade/explode4.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
	if (rand == 5) EmitAmbientSound2("weapons/hegrenade/explode5.wav", clientpos, client, SNDLEVEL_RAIDSIREN);
	
	new pointHurt = CreateEntityByName("point_hurt");
	if(pointHurt){
		DispatchKeyValue(client, "targetname", "explodeme");
		DispatchKeyValue(pointHurt, "DamageTarget", "explodeme");
		DispatchKeyValue(pointHurt, "Damage", "1410065408");
		DispatchKeyValue(pointHurt, "DamageType", "0");

		DispatchSpawn(pointHurt);
		AcceptEntityInput(pointHurt, "Hurt", -1);
		DispatchKeyValue(pointHurt, "classname", "point_hurt");
		DispatchKeyValue(client, "targetname", "");
		RemoveEdict(pointHurt);
	}
	
	new explosion = CreateEntityByName("env_explosion");
	if (explosion){
		DispatchSpawn(explosion);
		TeleportEntity(explosion, clientpos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(explosion, "Explode", -1, -1, 0);
		RemoveEdict(explosion);
	}
	
	ClientKill(client)
}

AttachParticle(ent, String:particleType[], bool:cache=false){
	new particle = CreateEntityByName("info_particle_system");

	if (IsValidEdict(particle)){
		new String:tName[128];
		new Float:f_pos[3];

		if (cache) f_pos[2] -= 3000;
		else{
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", f_pos);
			f_pos[2] += 60;
		}

		TeleportEntity(particle, f_pos, NULL_VECTOR, NULL_VECTOR);

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(2.0, DeleteParticle, particle);
	}
}

public Action:DeleteParticle(Handle:timer, any:particle){
	if (IsValidEntity(particle)){
		new String:classname[128];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false)) RemoveEdict(particle);
	}
}


//===================================================================================================================
//PimpSlap Reference:
//Evil Admin: Pimp Slap		https://forums.alliedmods.net/showthread.php?t=79322?t=79322

public PimpSlap(client){//490
	if(!StatusCheck(client)) return;
	SetEntityHealth(client, 100)
	SlapPlayer(client, 2, true)
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, 0);
	ResetPack(Hpack2)
	//CreateTimer(0.1, Timer_PimpSlap, Hpack2, TIMER_REPEAT)
	CreateTimer(0.1, Timer_PimpSlap, Hpack2)
}

public Action:Timer_PimpSlap(Handle:timer, any:Hpack){
	new client = ReadPackCell(Hpack);
	new counter = ReadPackCell(Hpack);
	CloseHandle(Hpack)
	
	if(!StatusCheck(client)) return;
	if(GetClientHealth(client) <= 2 || counter >= 55){
		//PrintToChat(client,"%d",counter)
		ClientKill(client)
		return;
	}
	SlapPlayer(client, 2, true)
	
	new Handle:Hpack2 = CreateDataPack();
	WritePackCell(Hpack2, client);
	WritePackCell(Hpack2, counter+=1);
	ResetPack(Hpack2)
	CreateTimer(0.1, Timer_PimpSlap, Hpack2)
}
//===================================================================================================================
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	/*
	new String:sMessage2[256] = "";
	GetEventString(event, "objective",sMessage2, sizeof(sMessage2));
	LogToFileEx(path,"timelimit-%d:fraglimit-%d:%s",GetEventInt(event, "timelimit"),GetEventInt(event, "fraglimit"),sMessage2)
	*/
	g_bRoundStarted = true;
	CreateTimer(2.0, Timer_CancelSterted)
}

public Action:Timer_CancelSterted(Handle:timer, any:client){
	g_bRoundStarted = false;
	for(new i = 1;i < GetMaxClients();i++){ SlayLoserKill[i] = 0; }
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) SlayLoserCustom[client] = 0
	ClientDefault(client)
	//SlayLoserKill[client] = 0
	
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	//SDKUnhook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public Action:OnWeaponCanUse(client, weapon){ return Plugin_Handled; }
public Action:OnWeaponSwitch(client, weapon){
	SDKHooks_DropWeapon(client, weapon);
	//RemovePlayerItem(client, weapon);
}

//Weapon Remover Lite			https://forums.alliedmods.net/showthread.php?p=2352637
public StripWeapons(client){
	if(!IsClientInGame(client) || !IsPlayerAlive(client)) return;
	for(int j = 0; j < 4; j++){
		int weapon = GetPlayerWeaponSlot(client, j);
		if(weapon != -1){
			RemovePlayerItem(client, weapon);
			RemoveEdict(weapon);						
		}
	}
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

//Reason-1:#SFUI_Notice_Target_Bombed
//Reason-7:#SFUI_Notice_Bomb_Defused
//Reason-8:#SFUI_Notice_CTs_Win
//Reason-9:#SFUI_Notice_Terrorists_Win	
//Reason-10:#SFUI_Notice_Round_Draw
//Reason-11:#SFUI_Notice_All_Hostages_Rescued
//Reason-12:#SFUI_Notice_Target_Saved de沒放炸彈的後果
//Reason-13:#SFUI_Notice_Hostages_Not_Rescued
//Reason-16:#SFUI_Notice_Game_Commencing


//"SFUI_Notice_CTs_PreventEscape"				"反恐部隊要盡可能地阻止恐怖份子逃脫。"
//"SFUI_Notice_Escaping_Terrorists_Neutralized"	"所有逃脫的恐怖分子都已被殲滅。"
//"SFUI_Notice_Terrorists_Not_Escaped"			"恐怖份子並未逃脫。"
//"SFUI_Notice_Terrorists_Surrender"			"恐怖份子投降"
//"SFUI_Notice_CTs_Surrender"					"反恐部隊投降"
//"SFUI_Notice_Terrorists_Escaped"  			"恐怖份子逃脫了！"
//"SFUI_Notice_VIP_Not_Escaped"					"VIP 並未逃脫。"
//"SFUI_Notice_VIP_Escaped"						"VIP 成功的逃脫了！"
//"SFUI_Notice_VIP_Assassinated"				"VIP 被刺殺了！"
//https://github.com/alliedmodders/sourcemod/blob/master/plugins/include/cstrike.inc
public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	g_bRoundStarted = false
	if (!sd_SlayLoser) return;
	
	new String:sMessage[256] = ""
	new String:sMessage2[256] = "";
	new iWinner = GetEventInt(event, "winner");
	new reason = GetEventInt(event, "reason")
	GetEventString(event, "message",sMessage2, sizeof(sMessage2));
	//LogToFileEx(path,"Winner-%d:Reason-%d:%s",iWinner,reason,sMessage2)
	
	for(new i = 1; i < GetMaxClients(); i++){
		if(!IsClientInGame(i)) continue;
		PrintToConsole(i,"---------------RoundEnd(Reason:%d - Winner:%d):%s",reason,iWinner,sMessage2);
		if(sd_SlayLoser_Invincible && IsPlayerAlive(i)) SetEntProp(i, Prop_Data, "m_takedamage",1, 1); //Invincible
	}
	
	Format(sMessage,sizeof(sMessage),"%T",sMessage2,LANG_SERVER)
	
	if (!iWinner) return;
	if (StrEqual(sMessage2,"#SFUI_Notice_Game_Commencing"	,false)) return;
	if (StrEqual(sMessage2,"#SFUI_Notice_Round_Draw"		,false) && !sd_SlayLoserRD) return;
	for(new i = 1; i < GetMaxClients(); i++){
		if(!CanBePunish(i)) continue;
		if(GetClientTeam(i) != iWinner){
			ForcePlayerSuicide2(i);
			PrintToChat(i, "\x03[SDC] \x04%s", sMessage);
		}
	}
	
	//----------------------
	//Old by number not working both for CSS or CSGO
	//Format(sMessage,sizeof(sMessage),"PunishReason_%d",reason)
	//switch (reason){
		/*
		case  1:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER)
		case  7:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER)
		//case  8:#SFUI_Notice_CTs_Win
		//case  9:#SFUI_Notice_Terrorists_Win
		case 10:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER) //Round Draw
		case 11:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER)
		case 12:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER)
		case 13:Format(sMessage,sizeof(sMessage),"%T",sMessage,LANG_SERVER)
		//case 16:#SFUI_Notice_Game_Commencing
		*/
		/*
		case 0: sMessage = "警告!!這不是<炸菜>.";					//你敢叛國??幹嘛不拆炸彈!?
		case 6: sMessage = "菊花還沒展開，你卻已經屎了，太大意惹吧";//沒保護好C4的後果，就是你死掉的隊友爬出墳墓來找你!
		case 10:sMessage = "說好的人質呢??重點是燦爛綻放的菊花呢??";//說好的人質呢??
		case 12:sMessage = "你該向海豹部隊看齊.";					//人質死了，上軍事法庭吧你!
		case 9: sMessage = "平局耶!呵呵呵~~";
		case 11:sMessage = "今日菊花未開，明日槍枝炸堂，訂不了辜枝";//對自己狠就是對敵人狠，這就是不鋪炸彈的結果!
		
		case 1: sMessage = "你的好碰友小皮逃離了你的大魔棒";		//只有VIP能夠換取你的性命，殺了他!!
		case 2: sMessage = "可憐的小皮你不要死阿~你死的好慘阿.";	//你真愧對你的隊友，VIP就是你的生命!
		case 3: sMessage = "對面的變態等待你下輩子的垂憐";			//你該判叛國罪，竟然讓變態們逃了!
		case 14:sMessage = "真是好炮友，可惜你沒機會了.";			//既然你沒保護好VIP就下去償命吧!!
		*/
		//default:iWinner = 1
	//}
}

bool:CanBePunish(client){
	if(!IsClientInGame(client)) return false;
	if(!IsPlayerAlive(client)) 	return false;
	if(!NotImmune(client)) 		return false;
	return true;
}

bool:NotImmune(any:client){
    if (GetUserAdmin(client) == INVALID_ADMIN_ID || !sd_SlayLoser_Immunity)
			return true;
	else 	return false;
}

//===================================================================================================================
public OnClientConnected(client){	SlayLoserCustom[client] = 0; }
public OnClientCookiesCached(client){
	SlayLoserCustom[client] = 0;
	new String:buffer[32];
	GetClientCookie(client, g_hCookie, buffer, sizeof(buffer));
	if(StringToInt(buffer)) SlayLoserCustom[client] = StringToInt(buffer);
	//Format(buffer,sizeof(buffer),"PunishName%s",buffer)
	//PrintToChat(client,"[SDC] %T %T","cmdSlayLoserCustomChoose",buffer)
}

public CookieSelected(client, CookieMenuAction:action, any:info, String:buffer[], maxlen){
	new String:value[100];
	GetClientCookie(client, info, value, sizeof(value));
	Format(value,sizeof(value),"PunishName%s",value)
	if (action == CookieMenuAction_DisplayOption)
		Format(buffer, maxlen, "%T : %T","cmdSlayLoserCustomTitle",LANG_SERVER,value,LANG_SERVER);
	else if(action == CookieMenuAction_SelectOption)
		PrepareMenu(client);
	PrintToChat(client,"%T\x03%T","cmdSlayLoserCustomChoose",LANG_SERVER,value,LANG_SERVER)
}

PrepareMenu(client){
	new String:MenuTitle[64]
	new Handle:menu = CreateMenu(GTMenu, MENU_ACTIONS_DEFAULT|MenuAction_DrawItem|MenuAction_DisplayItem|MenuAction_Display);
	Format(MenuTitle,sizeof(MenuTitle),"PunishName%d",SlayLoserCustom[client])
	Format(MenuTitle,sizeof(MenuTitle),"%T : %T","cmdSlayLoserCustomTitle",LANG_SERVER,MenuTitle,LANG_SERVER)
	SetMenuTitle(menu, MenuTitle);

	for(new i = 0;i < ( SlayLoserItems + 1);i++){
		new String:ItemInt[32]
		IntToString(i, ItemInt, sizeof(ItemInt));
		AddMenuItem(menu, ItemInt,ItemInt);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public GTMenu(Handle:menu, MenuAction:action	, client	, item){
	switch(action){
		case MenuAction_DrawItem: if(SlayLoserCustom[client] == item) return ITEMDRAW_DISABLED;
		case MenuAction_DisplayItem:{
			new String:dispBuf[50],String:LangName[32]
			GetMenuItem(menu, item, "", 0, _, dispBuf, sizeof(dispBuf));
			Format(LangName, sizeof(LangName),"PunishName%d",StringToInt(dispBuf))
			Format(dispBuf, sizeof(dispBuf),"%T",LangName,LANG_SERVER)
			return RedrawMenuItem(dispBuf);
		}
		case MenuAction_Display:{ }
		case MenuAction_Select:{
			new String:dispBuf[50];
			GetMenuItem(menu, item, "", 0, _, dispBuf, sizeof(dispBuf));
			SlayLoserCustom[client] = StringToInt(dispBuf);
			SetClientCookie(client, g_hCookie, dispBuf);
			PrepareMenu(client);
		}
		case MenuAction_Cancel: if( item == MenuCancel_Exit ) ShowCookieMenu(client);
		case MenuAction_End: CloseHandle(menu);
	}
	
	return 0;
}

//===================================================================================================================
//Stock
stock ClientDefault(client){
	SlayLoserBird[client] = 0
	
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	DispatchKeyValue(client, "targetname", "")
	SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	
	SetEntityGravity(client,1.0)
	SetEntityRenderMode(client,RENDER_NORMAL)
	SetEntityRenderColor(client, 255, 255, 255, 255);
}
public Action:ClientKillDelay(Handle: timer, any: client){ ClientKill(client); }
stock ClientKill(client){
	ClientDefault(client)
	if(!IsPlayerAlive(client) || g_bRoundStarted) return;
	
	if(!sd_SlayLoserKill || sd_SlayLoserKill == 2){ ForcePlayerSuicide(client); return; }
	if(sd_SlayLoser_DeathLight) CreateParticlePub(client,"light_gaslamp_glow")
	
	//http://docs.sourcemod.net/api/index.php?fastload=show&id=1028&
	SDKHooks_TakeDamage(client, 0, 0 , 1410065408.0);
	
	/*
	new String:DamageType[32]
	Format(DamageType,sizeof(DamageType),"%d", GetRandomInt( 0 , 1 ) ? TwoExp(1,GetRandomInt( 0 , 10 )):TwoExp(16384,GetRandomInt( 0 , 9 )))
	*/
}
/*
stock TwoExp(OrgV,const Times){
	if(!Times) return OrgV;
	for(new i = 1;i < Times;i++) OrgV = OrgV * 2
	return OrgV;
}
*/
stock TE_SetupBeamRingPoint2(client,const Float:center[3], Float:Start_Radius, Float:End_Radius, ModelIndex, HaloIndex, StartFrame,FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags){
	TE_SetupBeamRingPoint(center, Start_Radius, End_Radius, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width,Amplitude, Color, Speed, Flags);
	TE_Send2(client)
}

stock TE_SetupBeamPoints2(client,const Float:start[3], const Float:end[3], ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life,Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed){
	TE_SetupBeamPoints(start,end, ModelIndex, 	HaloIndex, StartFrame,FrameRate,Life,Width,EndWidth,FadeLength,Amplitude,Color, Speed)
	TE_Send2(client)
}

stock TE_SetupBeamRing2(client,StartEntity, EndEntity, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:Amplitude, const Color[4], Speed, Flags){
	TE_SetupBeamRing(StartEntity, EndEntity, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, Amplitude, Color, Speed, Flags)
	TE_Send2(client)
}

stock TE_SetupEnergySplash2(client,const Float:pos[3], const Float:dir[3], bool:Explosive){
	TE_SetupEnergySplash(pos,dir,Explosive);
	TE_Send2(client)
}

stock TE_SetupBeamFollow2(client,EntIndex, ModelIndex, HaloIndex, Float:Life, Float:Width, Float:EndWidth, FadeLength, const Color[4]){
	new Float:Pos[3] , ent = CreateEntityByName("env_beam");
	GetClientAbsOrigin(client,Pos);
	DispatchSpawn(ent);
	TeleportEntity(ent, Pos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client);
	TE_SetupBeamFollow(ent, ModelIndex, HaloIndex, Life, Width, EndWidth, FadeLength, Color)
	TE_Send2(client)
	CreateTimer(10.0, KillEntity, ent);
}

stock TE_SetupGlowSprite2(client,const Float:pos[3], Model, Float:Life, Float:Size, Brightness){
	TE_SetupGlowSprite(pos, Model, Life, Size, Brightness)
	TE_Send2(client)
}
//https://sm.alliedmods.net/api/index.php?fastload=show&id=381&
stock TE_SetupExplosion2(client,const Float:pos[3], Model, Float:Scale, Framerate, Flags, Radius, Magnitude, const Float:normal[3]={0.0, 0.0, 1.0}, MaterialType='C'){
	TE_SetupExplosion(pos, Model,Scale, Framerate, Flags, Radius, Magnitude,normal, MaterialType)
	TE_Send2(client)
}

stock TE_SetupWorldDecal(client,m_nIndex,const Float:Pos[3]){
	TE_Start("World Decal");
	TE_WriteNum("m_nIndex",m_nIndex);
	TE_WriteVector("m_vecOrigin",Pos);
	TE_Send2(client)
}

stock TE_SetupBeamLaser2(client,StartEntity, EndEntity, ModelIndex, HaloIndex, StartFrame, FrameRate, Float:Life, Float:Width, Float:EndWidth, FadeLength, Float:Amplitude, const Color[4], Speed){
	TE_SetupBeamLaser(StartEntity, EndEntity, ModelIndex, HaloIndex, StartFrame, FrameRate, Life, Width, EndWidth, FadeLength, Amplitude, Color, Speed)
	TE_Send2(client)
}

stock TE_Send2(client){
	if(sd_SlayLoser_EffectOne) 	TE_SendToClient(client);
	else 						TE_SendToAll();
}

stock floatAddTo(const Float:def[3],Float:tar[3],const F0 = 0,const F1 = 0,const F2 = 0){
	if(def[0]) tar[0] = def[0];	if(def[1]) tar[1] = def[1]; if(def[2]) tar[2] = def[2];
	if(F0) tar[0] += float(F0);	if(F1) tar[1] += float(F1);	if(F2) tar[2] += float(F2);
}

stock StatusCheck(const client = 0){
	if (g_bRoundStarted)		return false
	if (!client) 				return true
	if (!IsClientInGame(client))return false
	if (!IsPlayerAlive(client)) return false
	return true
}

stock ArrayInt(Source[],To[],size){ for(new i = 0; i < size;i++){ To[i] = Source[i]; } }
//https://developer.valvesoftware.com/wiki/Info_particle_system
//https://forums.alliedmods.net/showthread.php?t=90658 Particle Systems Control Points?
stock CreateParticlePub(entity,const String:effect_name[] = "extinguish_embers_small_02",const String:angles[] = "-90 0 0",const Float:KillerTimer = 5.0){
	new particle = CreateEntityByName("info_particle_system");
	if(!IsValidEntity(entity) || !IsValidEntity(particle)) return false
	
	new Float: pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(particle, "effect_name", effect_name);
	DispatchKeyValue(particle, "angles", angles);
	DispatchSpawn(particle);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "Start");
	CreateTimer(KillerTimer, KillEntity, particle);
	
	return true
}
public Action: KillEntity(Handle: timer, any: entity){
	if(!IsValidEntity(entity)) return;
	AcceptEntityInput(entity, "Kill"); 
}

stock ThirdPerson(client){
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);
}

stock CanAdminTarget2(client, target){
	new AdminId:clientAdmin = GetUserAdmin(client);
	new AdminId:targetAdmin = GetUserAdmin(target);
	if (CanAdminTarget(clientAdmin, targetAdmin)) 
			return true;
	else 	return false
}

//===================================================================================================================
//Sound Only
stock EmitAmbientSound2(const String:name[], const Float:pos[3], entity = SOUND_FROM_WORLD, level = SNDLEVEL_NORMAL, flags = SND_NOFLAGS,Float:vol = SNDVOL_NORMAL, pitch = SNDPITCH_NORMAL, Float:delay = 0.0){
	PrecacheSound(name, true);
	if(sd_SlayLoser_SoundOne) 
			EmitSoundToClient(entity,name,entity,SNDCHAN_AUTO, level,flags,vol,pitch)
	else 	EmitAmbientSound(name,pos,entity,level, flags,vol,pitch,delay);
}

stock EmitSound2(const String:sample[],entity = 0){
	PrecacheSound(sample, true);
	if(sd_SlayLoser_SoundOne)
			EmitSoundToClient(entity,sample,entity)
	else 	EmitSoundToAll(sample, entity);
}

//===================================================================================================================
//Convar Hook Change
public Cvar_enabled		(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser 				= StringToInt(newValue); }
public Cvar_RoundDraw	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoserRD 			= StringToInt(newValue); }
public Cvar_Kill		(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoserKill 			= StringToInt(newValue); }
public Cvar_KillBot		(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoserKillBot 		= StringToInt(newValue); }
public Cvar_Immunity	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_Immunity 	= StringToInt(newValue); }
public Cvar_StopWalk	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_StopWalk 	= StringToInt(newValue); }
public Cvar_SoundOne	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_SoundOne 	= StringToInt(newValue); }
public Cvar_EffectOne	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_EffectOne 	= StringToInt(newValue); }
public Cvar_MagicProp	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_MagicProp 	= StringToInt(newValue); }
public Cvar_Invincible	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_Invincible 	= StringToInt(newValue); }
public Cvar_DeathLight	(Handle:convar, const String:oldValue[], const String:newValue[]) 	{ sd_SlayLoser_DeathLight 	= StringToInt(newValue); }
public Cvar_StripWeapon	(Handle:convar, const String:oldValue[], const String:newValue[])	{ sd_SlayLoser_StripWeapon 	= StringToInt(newValue); }

public Cvar_Magic1	(Handle:convar, const String:oldValue[], const String:newValue[])
{ strcopy(sd_SlayLoser_MagicProp1, sizeof(sd_SlayLoser_MagicProp1), newValue); }
public Cvar_Magic2	(Handle:convar, const String:oldValue[], const String:newValue[])
{ strcopy(sd_SlayLoser_MagicProp2, sizeof(sd_SlayLoser_MagicProp2), newValue); }
//===================================================================================================================
//Precache Files
new CountOfCacheSound = 0
public OnMapStart(){
	new k = 0;
	//--------------DeadFly------------------------// OK
	CacheSound[k+=1] = "ambient/atmosphere/mountain_wind_lp_01"; //1
	CacheSound[k+=1] = "ambient/atmosphere/thunder_distant_06";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder_distant_01";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder_distant_02";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder_distant_06";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder4";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder5";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder6";
	CacheSound[k+=1] = "ambient/tones/tunnel_wind_loop";
	CacheSound[k+=1] = "ambient/weather/thunder_distant_03";
	CacheSound[k+=1] = "ambient/weather/thunder_distant_04";
	CacheSound[k+=1] = "ambient/weather/thunder_distant_05";
	CacheSound[k+=1] = "ambient/weather/thunder1";
	CacheSound[k+=1] = "ambient/weather/thunder2";
	CacheSound[k+=1] = "ambient/weather/thunder3";
	CacheSound[k+=1] = "ambient/wind/css15_wind_01";
	CacheSound[k+=1] = "ambient/wind/css15_wind_02";
	CacheSound[k+=1] = "ambient/wind/css15_wind_03";
	CacheSound[k+=1] = "ambient/wind/css15_wind_04";
	CacheSound[k+=1] = "ambient/wind/css15_wind_05";
	CacheSound[k+=1] = "ambient/wind/css15_wind_06";
	CacheSound[k+=1] = "ambient/wind/css15_wind_07";
	CacheSound[k+=1] = "ambient/wind/css15_wind_08";
	CacheSound[k+=1] = "ambient/wind/css15_wind_09";
	CacheSound[k+=1] = "ambient/wind/css15_wind_10"; //25
	if(CountOfCacheSound) PrintToServer("DeadFly:%d",k)
	//--------------Sword--------------------------// OK
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor01"; //26
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor06";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor07";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor08";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor09";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor10";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor11";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor13";
	CacheSound[k+=1] = "weapons/fx/nearmiss/bulletltor14"; //34
	CacheSound[k+=1] = "player/death1"; //35
	CacheSound[k+=1] = "player/death2";
	CacheSound[k+=1] = "player/death3";
	CacheSound[k+=1] = "player/death4";
	CacheSound[k+=1] = "player/death5";
	CacheSound[k+=1] = "player/death6"; //40
	if(CountOfCacheSound) PrintToServer("Sword:%d",k)
	//--------------Quake--------------------------// OK
	g_BeamSprite2 = PrecacheModel( "materials/sprites/physbeam.vmt" ,true);		//Blue
	g_BeamSprite3 = PrecacheModel( "materials/sprites/purplelaser1.vmt" ,true);	//Red
	g_BeamSprite4 = PrecacheModel( "materials/sprites/laserbeam.vmt" ,true);		//Green
	CacheSound[k+=1] = "ambient/atmosphere/indoor1"; //41	
	CacheSound[k+=1] = "ambient/atmosphere/indoor2";
	CacheSound[k+=1] = "ambient/energy/electric_loop";
	CacheSound[k+=1] = "ambient/energy/force_field_loop1";
	CacheSound[k+=1] = "ambient/machines/60hzhum";
	CacheSound[k+=1] = "ambient/machines/refinery_loop_1";
	CacheSound[k+=1] = "ambient/playonce/machines/refrigerator";
	CacheSound[k+=1] = "ambient/atmosphere/laundry_amb";
	CacheSound[k+=1] = "ambient/atmosphere/tunnel1"; //49
	CacheSound[k+=1] = "training/firewerks_burst_02"; //50
	if(CountOfCacheSound) PrintToServer("Quake:%d",k)
	//--------------TimeBomb-----------------------// OK
	g_HaloSprite = PrecacheModel("materials/sprites/halo.vmt",true);
	g_BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt",true);
	g_ExplosionSprite = PrecacheModel("materials/models/weapons/v_models/eq_molotov/v_eq_molotov_lighter_flame.vmt",true);
	CacheSound[k+=1] = "weapons/c4/c4_explode1"; // 51
	CacheSound[k+=1] = "buttons/button17";
	CacheSound[k+=1] = "bot/aw_hell"; //53
	if(CountOfCacheSound) PrintToServer("TimeBomb:%d",k)
	//--------------Rocket------------------------// OK
	CacheSound[k+=1] = "weapons/hegrenade/explode4"; //54
	CacheSound[k+=1] = "weapons/hegrenade/explode5";
	CacheSound[k+=1] = "ui/mm_success_lets_roll";
	CacheSound[k+=1] = "ui/beep22"; //57
	if(CountOfCacheSound) PrintToServer("Rocket:%d",k)
	//--------------Fire--------------------------// OK
	CacheSound[k+=1] = "hostage/hpain/hpain1"; //58
	CacheSound[k+=1] = "hostage/hpain/hpain2";
	CacheSound[k+=1] = "hostage/hpain/hpain3";
	CacheSound[k+=1] = "hostage/hpain/hpain4";
	CacheSound[k+=1] = "hostage/hpain/hpain5";
	CacheSound[k+=1] = "hostage/hpain/hpain6"; //63
	CacheSound[k+=1] = "ambient/nature/fire/fire_small1"; //64
	if(CountOfCacheSound) PrintToServer("Fire:%d",k)
	//--------------Thunder-----------------------// OK
	PrecacheModel("sprites/zerogxplode.vmt",true);
	PrecacheModel("sprites/spectator_eye.vmt",true);
	PrecacheModel("sprites/muzzleflash4.vmt",true);
	PrecacheModel("sprites/light_glow04.vmt",true);
	PrecacheModel("sprites/bomb_planted_ring.vmt",true);
	PrecacheModel("sprites/obj_icons/kills.vmt",true);
	GLOW_SPRITE = PrecacheModel("materials/sprites/blueglow1.vmt",true);
	GLOW_SPRITE2 = PrecacheModel("materials/sprites/purpleglow1.vmt",true);
	CacheSound[k+=1] = "ambient/machines/air_conditioner_cycle"; //65
	CacheSound[k+=1] = "ambient/machines/zap1"; //66
	CacheSound[k+=1] = "ambient/machines/zap2";
	CacheSound[k+=1] = "ambient/machines/zap3"; //68
	if(CountOfCacheSound) PrintToServer("Thunder:%d",k)
	//--------------Chicken------------------------// OK
	PrecacheModel("models/chicken/chicken_zombie.mdl",true);
	CacheSound[k+=1] = "ambient/creatures/chicken_fly_long"; //69
	CacheSound[k+=1] = "ambient/creatures/chicken_idle_01";
	CacheSound[k+=1] = "ambient/creatures/chicken_idle_02";
	CacheSound[k+=1] = "ambient/creatures/chicken_idle_03";
	CacheSound[k+=1] = "ambient/creatures/chicken_panic_01";
	CacheSound[k+=1] = "ambient/creatures/chicken_panic_02";
	CacheSound[k+=1] = "ambient/creatures/chicken_panic_03";
	CacheSound[k+=1] = "ambient/creatures/chicken_panic_04";
	CacheSound[k+=1] = "player/vo/separatist/chickenhate01";
	CacheSound[k+=1] = "player/vo/separatist/chickenhate02";
	CacheSound[k+=1] = "player/vo/separatist/chickenhate03";
	CacheSound[k+=1] = "player/vo/separatist/chickenhate04"; //80
	CacheSound[k+=1] = "weapons/hegrenade/explode3";
	CacheSound[k+=1] = "ambient/creatures/chicken_death_01"; //82
	CacheSound[k+=1] = "ambient/creatures/chicken_death_02";
	CacheSound[k+=1] = "ambient/creatures/chicken_death_03"; //84
	if(CountOfCacheSound) PrintToServer("Chicken:%d",k)
	//--------------BirdFly------------------------// OK
	PrecacheModel("models/crow.mdl",true);
	PrecacheModel("models/pigeon.mdl",true);
	PrecacheModel("models/seagull.mdl",true);
	CacheSound[k+=1] = "ambient/playonce/weather/thunder4"; //87
	CacheSound[k+=1] = "ambient/playonce/weather/thunder5";
	CacheSound[k+=1] = "ambient/playonce/weather/thunder6";
	CacheSound[k+=1] = "ambient/creatures/seagull_idle1";
	CacheSound[k+=1] = "ambient/creatures/seagull_idle2";
	CacheSound[k+=1] = "ambient/creatures/seagull_idle3";
	CacheSound[k+=1] = "ambient/creatures/pigeon_idle1";
	CacheSound[k+=1] = "ambient/creatures/pigeon_idle2";
	CacheSound[k+=1] = "ambient/creatures/pigeon_idle3";
	CacheSound[k+=1] = "ambient/creatures/pigeon_idle4";
	CacheSound[k+=1] = "ambient/animal/crow";
	CacheSound[k+=1] = "ambient/animal/crow_1";
	CacheSound[k+=1] = "ambient/animal/crow_2"; //97
	if(CountOfCacheSound) PrintToServer("BirdFly:%d",k)
	//--------------Snow---------------------------//
	PrecacheModel("materials/particle/snow.vmt",true);
	PrecacheModel("particle/snow.vmt",true);
	CacheSound[k+=1] = "physics/glass/glass_impact_bullet1"; //98
	CacheSound[k+=1] = "physics/glass/glass_impact_bullet2";
	CacheSound[k+=1] = "physics/glass/glass_impact_bullet3";
	CacheSound[k+=1] = "physics/glass/glass_impact_bullet4"; //101
	CacheSound[k+=1] = "ambient/wind/wind_med1"; //102
	CacheSound[k+=1] = "ambient/wind/wind_med2";
	CacheSound[k+=1] = "ambient/wind/smallgust2"; //104
	Snow_Decal[0] = PrecacheDecal("decals/glass/shot1", true);
	Snow_Decal[1] = PrecacheDecal("decals/glass/shot2", true);
	Snow_Decal[2] = PrecacheDecal("decals/glass/shot3", true);
	Snow_Decal[3] = PrecacheDecal("decals/glass/shot4", true);
	Snow_Decal[4] = PrecacheDecal("decals/glass/shot5", true);
	if(CountOfCacheSound) PrintToServer("Snow:%d",k)
	//--------------MagicProps---------------------//
	PrecacheModel(sd_SlayLoser_MagicProp1,true);
	PrecacheModel(sd_SlayLoser_MagicProp2,true);
	CacheSound[k+=1] = "weapons/party_horn_01"; //105
	CacheSound[k+=1] = "buttons/light_power_on_switch_01";//106
	AddFileToDownloadsTable(sd_SlayLoser_MagicProp1)
	AddFileToDownloadsTable(sd_SlayLoser_MagicProp2)
	if(CountOfCacheSound) PrintToServer("MagicProps:%d",k)
	//--------------Bomber-------------------------//
	PrecacheModel("models/props_junk/watermelon01.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk01a.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk01b.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk01c.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk02a.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk02b.mdl",true)
	PrecacheModel("models/props_junk/watermelon01_chunk02c.mdl",true)
	//--------------BarrelExp----------------------//
	PrecacheModel("models/props/de_train/barrel.mdl",true);
	//---------------------------------------------//
	
	new cntt = 0
	for(new i = 1;i < sizeof(CacheSound);i++){
		if(strlen(CacheSound[i]) == 0) continue;
		Format(CacheSound[i],128,"%s.wav",CacheSound[i])
		PrecacheSound(CacheSound[i],true);
		cntt++
	}
	if(CountOfCacheSound) PrintToServer("--SoundCache : %d",cntt)
}

public Global_LangSet(){
	LoadTranslations("SDC_LoserSlay.phrases");
	//Convar
	Format(i_sd_SlayLoser				,sizeof(i_sd_SlayLoser)				,"%T","sd_SlayLoser"				,LANG_SERVER)
	Format(i_sd_SlayLoserKill			,sizeof(i_sd_SlayLoserKill)			,"%T","sd_SlayLoserKill"			,LANG_SERVER)
	Format(i_sd_SlayLoserKillBot		,sizeof(i_sd_SlayLoserKillBot)		,"%T","sd_SlayLoserKillBot"			,LANG_SERVER)
	Format(i_sd_SlayLoserRD				,sizeof(i_sd_SlayLoserRD)			,"%T","sd_SlayLoser_RoundDraw"		,LANG_SERVER)
	Format(i_sd_SlayLoser_Immunity		,sizeof(i_sd_SlayLoser_Immunity)	,"%T","sd_SlayLoser_Immunity"		,LANG_SERVER)
	Format(i_sd_SlayLoser_StopWalk		,sizeof(i_sd_SlayLoser_StopWalk)	,"%T","sd_SlayLoser_StopWalk"		,LANG_SERVER)
	Format(i_sd_SlayLoser_SoundOne		,sizeof(i_sd_SlayLoser_SoundOne)	,"%T","sd_SlayLoser_SoundOne"		,LANG_SERVER)
	Format(i_sd_SlayLoser_EffectOne		,sizeof(i_sd_SlayLoser_EffectOne)	,"%T","sd_SlayLoser_EffectOne"		,LANG_SERVER)
	Format(i_sd_SlayLoser_DeathLight	,sizeof(i_sd_SlayLoser_DeathLight)	,"%T","sd_SlayLoser_DeathLight"		,LANG_SERVER)
	Format(i_sd_SlayLoser_StripWeapon	,sizeof(i_sd_SlayLoser_StripWeapon)	,"%T","sd_SlayLoser_StripWeapon"	,LANG_SERVER)
	Format(i_sd_SlayLoser_MagicProp		,sizeof(i_sd_SlayLoser_MagicProp)	,"%T","sd_SlayLoser_MagicProp"		,LANG_SERVER)
	Format(i_sd_SlayLoser_Invincible	,sizeof(i_sd_SlayLoser_Invincible)	,"%T","sd_SlayLoser_Invincible"		,LANG_SERVER)
	Format(i_sd_SlayLoser_MagicProp1	,sizeof(i_sd_SlayLoser_MagicProp1)	,"%T","sd_SlayLoser_MagicProp1"		,LANG_SERVER)
	Format(i_sd_SlayLoser_MagicProp2	,sizeof(i_sd_SlayLoser_MagicProp2)	,"%T","sd_SlayLoser_MagicProp2"		,LANG_SERVER)
	//Command
	Format(i_SlayLoserCustom			,sizeof(i_SlayLoserCustom)			,"%T","SlayLoserCustom"	,LANG_SERVER)
	Format(i_cmdSlayLoser				,sizeof(i_cmdSlayLoser)				,"%T","cmdSlayLoser"	,LANG_SERVER)
	Format(i_cmdSlayLoserAll			,sizeof(i_cmdSlayLoserAll)			,"%T","cmdSlayLoserAll"	,LANG_SERVER)
	/*
	new String:LangCode[5],String:LangName[16]
	GetLanguageInfo(GetServerLanguage(), LangCode, sizeof(LangCode), LangName, sizeof(LangName));
	PrintToServer("LangCode:%s",LangCode)
	//PrintToServer("LangName:%s",LangName)
	//LogToFileEx(path,"%T","test")
	*/
}
//======================================================================================================================
//Command
public Action:PrefSet(client, args){ PrepareMenu(client); }
public Action:CommandListener(client, const String:command[], argc){
	if(!IsClientInGame(client)) return Plugin_Continue
	if(!IsPlayerAlive(client)) 	return Plugin_Continue
	
	if(IsFakeClient(client)){
		if(sd_SlayLoserKillBot){
			ClientKill(client)
			return Plugin_Handled
		}
		else return Plugin_Continue
	}
	
	if(sd_SlayLoserKill != 1) return Plugin_Continue
	
	if(g_bRoundStarted || SlayLoserKill[client]) ClientKill(client)
	else if(!SlayLoserKill[client]){
		for(new i = 1; i < GetMaxClients();i++){
			if(!IsClientInGame(i)) continue;
			PrintToChat(i,"\x01[SDC] \x04%N\x01 %T.",i,"cmdSuicide",LANG_SERVER)
		}
		ForcePlayerSuicide2(client);
		SlayLoserKill[client] = 1
	}
	return Plugin_Handled;
}

public Action:CommandListener2(client, const String:command[], argc){
	if(!IsClientInGame(client)) return Plugin_Continue
	if(sd_SlayLoserKill == 0) 	return Plugin_Continue
	if(sd_SlayLoserKill == -1) 	return Plugin_Handled
	
	new String:Cmds[32]
	GetCmdArgString(Cmds,sizeof(Cmds))
	if(!StrEqual(Cmds,"kill",false) && !StrEqual(Cmds,"\"kill\"",false)) return Plugin_Continue
	if(IsPlayerAlive(client)){
		CommandListener(client, "kill", 0)
		return Plugin_Handled;
	}
	//PrintToChat(client,"%d:%s",argc,Cmds)
	//return Plugin_Handled;
	return Plugin_Continue
}

public Action:SDC_SLS(client2, args){
	new String:buffer[32],eun = 0
	GetCmdArgString(buffer, sizeof(buffer));
	if(StrContains(buffer,"se",false) != -1){ ForcePlayerSuicide2(client2); return; }
	
	new String:arg1[32],String:arg2[32]
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	new client = GetClientAimTarget(client2, true);
	if(client <= 0 && (StrContains(buffer,"aim",false) != -1)) return;
	else if(client <= 0) client = client2;
	
	if(!IsClientInGame(client)){
		PrintToChat		(client2,"[SDC] %T","PlayerNotExist",LANG_SERVER)
		PrintToConsole	(client2,"[SDC] %T","PlayerNotExist",LANG_SERVER)
		return;
	}
	if(!IsPlayerAlive(client)){
		PrintToChat		(client2,"[SDC] %T","PlayerDead",LANG_SERVER)
		PrintToConsole	(client2,"[SDC] %T","PlayerDead",LANG_SERVER)
		return;
	}
	if(g_bRoundStarted){
		PrintToChat		(client2,"[SDC] %T","g_bRoundStarted",LANG_SERVER)
		PrintToConsole	(client2,"[SDC] %T","g_bRoundStarted",LANG_SERVER)
		return;
	}
	
	if(IsCharNumeric(arg1[0])) eun = StringToInt(arg1)
	if(IsCharNumeric(arg2[0])) eun = StringToInt(arg2)
	
	ForcePlayerSuicide2(client,eun)
	
	new String:PunishName[32]
	Format(PunishName,sizeof(PunishName),"PunishName%d",eun)
	PrintToChat(client2,"(%T)%T : %N",PunishName,LANG_SERVER,"cmdSlayLoserTo",LANG_SERVER,client)
}

public Action:SDC_SLSA(client, args){
	for(new i = 1; i < GetMaxClients(); i++)
		if(IsClientInGame(i) && IsPlayerAlive(i) && CanAdminTarget2(client,i)) ForcePlayerSuicide2(i);
}
/*
public Action:SDC_SLSMENU(client, args){
	//DisplayMenu(playerMenuS, client,30 );
}
*/
//bool:IsValidClient(client) return (client > 0 && client <= GetMaxClients() && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client)) ? true : false;
bool:IsValidClient(client) return (client > 0 && client <= GetMaxClients() && IsClientInGame(client) && IsPlayerAlive(client)) ? true : false;

//===================================================================================================================
//Anthor test
new Float:cnt = 0.0
public TimerCheckOn(client){ CreateTimer(0.1, TimerCheck,client,TIMER_REPEAT);}
public Action:TimerCheck(Handle: timer,any: client){
	if(IsPlayerAlive(client)) cnt += 0.1
	else {
		PrintToChatAll("Time:%f",cnt)
		cnt = 0.0
		KillTimer(timer)
	}
}

public Action:test14(client, args){
	/*
	new String:LangCode[5],String:LangName[16]
	GetLanguageInfo(GetClientLanguage(client), LangCode, sizeof(LangCode), LangName, sizeof(LangName));
	PrintToChat(client,"(%d)LangCode:%s",GetClientLanguage(client),LangCode)
	*/
}

/*
stock DataPack(sizeSource,const String:name[], any:...){
	new size = sizeSource * 32
	if(size >= 4096) size = 4096
	
	decl String:formated[size]//,String:formated2[size];
	
	VFormat(formated, size, name, 3);
	//VFormat(format, 128, name, 6);
	PrintToServer(formated)
	//PrintToServer("%d-%d-%s",size,sizeSource,format)
}
*/
/*
public Action:test15(client, args){
	new Handle:EV = CreateEvent("round_end");
	if(EV == INVALID_HANDLE) return;
	
	SetEventInt(EV, "winner", 1);
	SetEventInt(EV, "reason", 1);
	SetEventString(EV,"message", "");

	FireEvent(EV, false);
	//DataPack(3,"test%s","ccc");
}
*/

//===================================================================================================================
//Swiming Reference:
//[Tutorial] Creating brush entities	https://forums.alliedmods.net/showthread.php?t=129597&page=2
//https://developer.valvesoftware.com/wiki/Func_fish_pool https://youtu.be/G_WGEZP3YEw
//https://developer.valvesoftware.com/wiki/Func_water
//https://developer.valvesoftware.com/wiki/Water_lod_control
//models\props\de_inferno\goldfish.mdl
//===================================================================================================================
//Admin Menu Set Reference:TeamSwitch
new	Handle:hAdminMenu = INVALID_HANDLE
public OnAdminMenuReady( Handle:topmenu ){
	if( topmenu == hAdminMenu ) return;  // Block us from being called twice
	hAdminMenu = topmenu;
	
	// Now add stuff to the menu: My very own category *yay*
	new TopMenuObject:menu_category = AddToTopMenu(
		hAdminMenu,				// Menu
		"SlayLoser",			// Name
		TopMenuObject_Category,	// Type
		Handle_Category,		// Callback
		INVALID_TOPMENUOBJECT	// Parent
	); if( menu_category == INVALID_TOPMENUOBJECT ) return; // Error... lame... 
	
	for(new i = 0;i < ( SlayLoserItems + 1);i++){
		new String:ItemInt[32],String:ItemCMD[32]
		IntToString(i, ItemInt, sizeof(ItemInt));
		Format(ItemCMD,sizeof(ItemCMD),"SlayLoserCMD-%d",i)
		AddToTopMenu(
			hAdminMenu,				// Menu
			ItemInt,				// Name
			TopMenuObject_Item,		// Type
			Handle_ModeChoose,		// Callback
			menu_category,			// Parent
			ItemCMD,				// cmdName
			ADMFLAG_SLAY			// Admin flag
		);
	}
}

public Handle_ModeChoose( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength ){
	new String:buffer2[64] , pid
	GetTopMenuObjName(topmenu, object_id, buffer2, sizeof(buffer2)); pid = StringToInt(buffer2)
	Format(buffer2,sizeof(buffer2),"PunishName%d",pid)
	
	if(action == TopMenuAction_DisplayOption){
		if(pid < 10) 	Format( buffer, maxlength, "0%d-%T",pid , buffer2 , LANG_SERVER );
		else 			Format( buffer, maxlength, "%d-%T" ,pid , buffer2 , LANG_SERVER );
	}
	if(action == TopMenuAction_SelectOption) 	ShowPlayerSelectionMenu( client, pid );
}
	
public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength ){
	switch( action ){
		case TopMenuAction_DisplayTitle:	Format( buffer, maxlength, "Slay Loser Plus %s", PLUGIN_VERSION);
		case TopMenuAction_DisplayOption:	Format( buffer, maxlength, "Slay Loser Plus %s", PLUGIN_VERSION);
	}
}

public ShowPlayerSelectionMenu( client, item){
	new Handle:playerMenuS = INVALID_HANDLE;
	playerMenuS = CreateMenu( Handle_Exec );
	
	new String:MenuTitle[64]
	Format(MenuTitle,sizeof(MenuTitle),"PunishName%d",item)
	Format(MenuTitle,sizeof(MenuTitle),"%T",MenuTitle,LANG_SERVER)
	SetMenuTitle(playerMenuS, MenuTitle);
	SetMenuExitButton(playerMenuS,true);
	SetMenuExitBackButton(playerMenuS,true);
	
	new String:Name[64],String:cBuffer[16]
	new Target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	new SpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if((SpecMode == 4 || SpecMode == 5) && CanAdminTarget2(client,Target)){
		GetClientName(Target,Name,sizeof(Name))
		Format(Name,sizeof(Name),"%T : %N","m_hObserverTarget",LANG_SERVER,Target)
		Format(cBuffer,sizeof(cBuffer),"%d_%d",Target,item)
		AddMenuItem( playerMenuS, cBuffer, Name );
	}
	
	for( new i = 1; i < GetMaxClients(); i++ ){
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		GetClientName(i,Name,sizeof(Name))
		Format(cBuffer,sizeof(cBuffer),"%d_%d",i,item)
		
		if (CanAdminTarget2(client, i))
				AddMenuItem( playerMenuS, cBuffer, Name );
		else	AddMenuItem( playerMenuS, cBuffer, Name ,ITEMDRAW_DISABLED);
	}
	DisplayMenu(playerMenuS, client,30 );
}

public Handle_Exec( Handle:playerMenu, MenuAction:action, client, param ){
	switch( action ){
		case MenuAction_Select:{
			new String:info[16],String:info2[16]
			GetMenuItem(playerMenu, param,  info,  sizeof(info), _,  info2, sizeof(info2));
			new iPos = (StrContains(info,"_") + 1)
			new targetPunish = StringToInt(info[iPos]); ReplaceString(info, sizeof(info), info[iPos-1], "");
			new target = StringToInt(info)
			
			ForcePlayerSuicide2(target,targetPunish)
			ShowPlayerSelectionMenu( client, targetPunish)
			
			new String:PunishName[32]
			Format(PunishName,sizeof(PunishName),"PunishName%d",targetPunish)
			PrintToChat(client,"(%T)%T : %N",PunishName,LANG_SERVER,"cmdSlayLoserTo",LANG_SERVER,target)
		}
			
		case MenuAction_Cancel: if( param == MenuCancel_ExitBack ) RedisplayAdminMenu( hAdminMenu, client );
		case MenuAction_End: CloseHandle( playerMenu );
	}
	return 0;
}



