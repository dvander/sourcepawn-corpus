#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#define CS_TEAM_T	2//Terrorists
#define CS_TEAM_CT	3//Counter-Terrorist

new String:sModel[128];
new String:sSound[128] = "sattyon/server/spy/UnCloak.wav";
new String:sSound2[128] = "player/death3.wav";
new String:sChara[PLATFORM_MAX_PATH];
new String:atkweapon[128];
//new String:victimName[32];
//new String:atk1Name[32];
new victim1;
new victimL;
new atk1;
//new rNumb1;
//new rNumb2;

//MODELS
//T---------------------------------
new String:mLeet[128] = "models/player/custom_player/legacy/tm_leet_varianta.mdl";
new String:mAnarchist[128] = "models/player/custom_player/legacy/tm_anarchist_varianta.mdl";
new String:mBalkan[128] = "models/player/custom_player/legacy/tm_balkan_varianta.mdl";
new String:mPhoenix[128] = "models/player/custom_player/legacy/tm_phoenix_varianta.mdl";
new String:mPirate[128] = "models/player/custom_player/legacy/tm_pirate_varianta.mdl";
new String:mProfessional[128] = "models/player/custom_player/legacy/tm_professional_var1.mdl";
new String:mSeparatist[128] = "models/player/custom_player/legacy/tm_separatist_varianta.mdl";
//CT----------------------
new String:mFbi[128] = "models/player/custom_player/legacy/ctm_fbi_varianta.mdl";
new String:mGign[128] = "models/player/custom_player/legacy/ctm_gign_varianta.mdl";
new String:mGsg9[128] = "models/player/custom_player/legacy/ctm_gsg9_varianta.mdl";
new String:mIdf[128] = "models/player/custom_player/legacy/ctm_idf_variantb.mdl"; //Dust2
new String:mSas[128] = "models/player/custom_player/legacy/ctm_sas_varianta.mdl";
new String:mSt6[128] = "models/player/custom_player/legacy/ctm_st6_varianta.mdl";
new String:mSwat[128] = "models/player/custom_player/legacy/ctm_swat_varianta.mdl";
//MODELS_end

public Plugin:myinfo ={
	name = "fakeDeathPluginSattyon",
	author = "sattyon",
	description = "sitai ga demasu",
	url = "https://twitter.com/sattyonPC"};
public void OnPluginStart()
{
	HookEvent("player_hurt", PlayerHurt); // hook on hurt
}

public void OnMapStart()
{
	PrecacheModel(mLeet, true);
	PrecacheModel(mAnarchist, true);
	PrecacheModel(mBalkan, true);
	PrecacheModel(mPhoenix, true);
	PrecacheModel(mPirate, true);
	PrecacheModel(mProfessional, true);
	PrecacheModel(mSeparatist, true);
	PrecacheModel(mFbi, true);
	PrecacheModel(mGign, true);
	PrecacheModel(mGsg9, true);
	PrecacheModel(mIdf, true);
	PrecacheModel(mSas, true);
	PrecacheModel(mSt6, true);
	PrecacheModel(mSwat, true);
	PrecacheSound(sSound, true);
	PrecacheSound(sSound2, true);
}

public Action:PlayerHurt(Event event, const String:name[], bool:dontBroadcast)
{
//Vitimの参照ID 
	victim1 = GetClientOfUserId(GetEventInt(event, "userid")); // Get Victim's userid
	GetEntPropString(victim1, Prop_Data, "m_ModelName", sChara, sizeof(sChara));
//VICTIMの名前を文字列として取得
//	 GetClientName(victim1, victimName, sizeof( victimName ) );
	decl String: Weapon[ 64 ];
	GetClientWeapon(victim1, Weapon, sizeof( Weapon ) );
//条件
	if(StrEqual(Weapon, "weapon_decoy", true)){
//		rNumb1 = GetRandomInt(1, 8);
//		rNumb2 = GetRandomInt(1, 8);
//sansyou ID
//		atk1 =  GetClientOfUserId(GetEventInt(event, "attacker"));
//		GetClientName(atk1, atk1Name, sizeof( atk1Name ) ); // NAME
		ChooseModelTeam();
		new pWeapon =  GetPlayerWeaponSlot(victim1, 3);
		FakeDeath();
		CreateTimer(4.5, DeInv);
		RemovePlayerItem(victim1, pWeapon);
//KILL LOG
		atk1 = GetEventInt(event, "attacker");
		victimL = GetEventInt(event, "userid");
		GetEventString(event, "weapon", atkweapon, sizeof(atkweapon));
		Event event1 = CreateEvent("player_death");
			if(event == null)
			{
			return;
			}
		event1.SetInt("userid", victimL);
		event1.SetInt("attacker", atk1);
		event1.SetString("weapon", atkweapon);
		event1.Fire();
		}}
/////////////////////////////////////
// フェイク
/////////////////////////////////////
public FakeDeath()
{
		SpawnFakeBody();
		Inv();
}
public Action DeInv(Handle timer)
{
	Inv2();
}
//////////////////////
//死体モデル選択
//////////////////
public	ChooseModelTeam()
{
	switch(GetClientTeam(victim1))
	{
	case CS_TEAM_T:
	{
		ChooseModelT();
	}
	case CS_TEAM_CT:
	{
		ChooseModelCT();
	}}}
//Choose models for T

public ChooseModelT()
{
	if(StrContains(sChara, "leet", false) != -1)
	{
		sModel = mLeet;
	}else	if(StrContains(sChara, "anarchist", false) != -1)
	{
		sModel = mAnarchist;
	}else	if(StrContains(sChara, "balkan", false) != -1)
	{
		sModel = mBalkan;
	}else	if(StrContains(sChara, "phoenix", false) != -1)
	{
		sModel = mPhoenix;
	}else	if(StrContains(sChara, "pirate", false) != -1)
	{
		sModel = mPirate;
	}else	if(StrContains(sChara, "professional", false) != -1)
	{
		sModel = mProfessional;
	}else	if(StrContains(sChara, "separatist", false) != -1)
	{
		sModel = mSeparatist;
	}else
	{
		sModel = mPhoenix;
	}
}

//Choose Models for CT
public ChooseModelCT()
{
	if(StrContains(sChara, "fbi", false) != -1)
	{
		sModel = mFbi;
	}else	if(StrContains(sChara, "gign", false) != -1)
	{
		sModel = mGign;
	}else	if(StrContains(sChara, "gsg9", false) != -1)
	{
		sModel = mGsg9;
	}else	if(StrContains(sChara, "idf", false) != -1)
	{
		sModel = mIdf;
	}else	if(StrContains(sChara, "sas", false) != -1)
	{
		sModel = mSas;
	}else	if(StrContains(sChara, "st6", false) != -1)
	{
		sModel = mSt6;
	}else	if(StrContains(sChara, "swat", false) != -1)
	{
		sModel = mSwat;
	}
//	else 
//	{
//		sModel = mFbi;
//	}
}
///////////////////////////////////////////////
// 死体作成処理
///////////////////////////////////////////////
public SpawnFakeBody()
{
	new FakeBody = CreateEntityByName("prop_ragdoll");
	new Float:PlayerPosition[3];
	GetClientAbsOrigin(victim1, PlayerPosition);
	PlayerPosition[0] -= 20;
	PlayerPosition[1] += 2;
	PlayerPosition[2] += 40;
	//AcceptEntityInput(Ent, "Ignite");
	DispatchKeyValue(FakeBody, "model", sModel);
	DispatchKeyValue(FakeBody, "spawnflags", "4");
	DispatchSpawn(FakeBody);	
	TeleportEntity(FakeBody, PlayerPosition, NULL_VECTOR, NULL_VECTOR);
	EmitAmbientSound(sSound2, PlayerPosition, victim1);
}
public Inv()
{	
	SetEntityRenderMode (victim1, RENDER_TRANSCOLOR);
	SetEntityRenderColor(victim1, 100, 100, 0, 5);
}
public Inv2()
{	
	new Float:PlayerPosition2[3];
	GetClientAbsOrigin(victim1, PlayerPosition2);
	SetEntityRenderMode(victim1, RENDER_NORMAL);
	SetEntityRenderColor(victim1, 255, 255, 255, 255);
	EmitAmbientSound(sSound, PlayerPosition2, victim1);
	PrintToChatAll("**************************");
}


//KILL LOG

//public SendDeathMessage()
//{
//	Event event = CreateEvent("player_death");
//	if (event == null)
//	{
//	return;
///	}
//	event.SetInt("userid", victim1);
//	event.SetInt("attacker", atk1);
///	event.SetString("weapon", atkweapon);
//	event.Fire();
//}