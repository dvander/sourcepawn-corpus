#include <sourcemod>
#include <sdktools>
#define Version "1.0.7"
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = "rpg mode",
	author = "korean guy?",
	description = "rpg mod",
	version = Version,
	url = ""
};


new Lv[MAXPLAYERS+1]

new EXP[MAXPLAYERS+1]


new Handle:JocExp
new Handle:HunExp
new Handle:ChaExp
new Handle:SmoExp
new Handle:SpiExp
new Handle:BooExp
new Handle:TanExp
new Handle:WitExp
new Handle:ComExp

new Handle:CheckExp[MAXPLAYERS+1]

new Handle:LvUpExp1
new Handle:LvUpExp2
new Handle:LvUpExp3
new Handle:LvUpExp4
new Handle:LvUpExp5
new Handle:LvUpExp6
new Handle:LvUpExp7
new Handle:LvUpExp8
new Handle:LvUpExp9
new Handle:LvUpExp10
new Handle:LvUpExp11
new Handle:LvUpExp12
new Handle:LvUpExp13
new Handle:LvUpExp14
new Handle:LvUpExp15
new Handle:LvUpExp16
new Handle:LvUpExp17
new Handle:LvUpExp18
new Handle:LvUpExp19
new Handle:LvUpExp20
new Handle:LvUpExp21
new Handle:LvUpExp22
new Handle:LvUpExp23
new Handle:LvUpExp24
new Handle:LvUpExp25
new Handle:LvUpExp26
new Handle:LvUpExp27
new Handle:LvUpExp28
new Handle:LvUpExp29
new Handle:LvUpExp30

new ZC

new ISCONFIRM[MAXPLAYERS+1]
new Str[MAXPLAYERS+1]
new Agi[MAXPLAYERS+1]
new Health[MAXPLAYERS+1]
new Endurance[MAXPLAYERS+1]
new Intelligence[MAXPLAYERS+1]

new LegValue

new Handle:LvUpSP
new StatusPoint[MAXPLAYERS+1]

new bool:HealingBool[MAXPLAYERS+1]
new HealingLv[MAXPLAYERS+1]

new Float:NowLocation[MAXPLAYERS+1][3]
new bool:EQBool[MAXPLAYERS+1]
new EarthQuakeLv[MAXPLAYERS+1]

new SkillPoint[MAXPLAYERS+1]
new SkillConfirm[MAXPLAYERS+1]

new Handle:ReviveExp

new Handle:DefExp

new bool:JobChooseBool[MAXPLAYERS+1]
new JD[MAXPLAYERS+1] = 0

new bool:AcolyteBool[MAXPLAYERS+1]

new HealingAuraLv[MAXPLAYERS+1]
new bool:EnaHA[MAXPLAYERS+1]

new FWLv[MAXPLAYERS+1]

new bool:SoldierBool[MAXPLAYERS+1]

new TrainedHealthLv[MAXPLAYERS+1]

new SprintLv[MAXPLAYERS+1]
new bool:EnaSprint[MAXPLAYERS+1]
new bool:EnaUG[MAXPLAYERS+1]

new bool:UGBool[MAXPLAYERS+1]
new UpgradeGunLv[MAXPLAYERS+1]

new bool:BioWeaponBool[MAXPLAYERS+1]

new BioShieldLv[MAXPLAYERS+1]
new bool:EnaBioS[MAXPLAYERS+1]
new bool:ActiBioS[MAXPLAYERS+1]

new WRQ[MAXPLAYERS+1]
new WRQL
new OffAW = -1
new OffNPA = -1
new Float:Multi

new C1 = -1
new C2 = -1

public OnPluginStart()
{
	CreateConVar("l4d2_RPG_Mode_Version", Version, "RPG mod",
CVAR_FLAGS)

	RegConsoleCmd("statusconfirm", ConfirmChooseMenu)
	RegConsoleCmd("usestatus", StatusChooseMenu)
	RegConsoleCmd("useskill", SkillChooseMenu)
	RegConsoleCmd("DS", DetermineSkillMenu)
	RegConsoleCmd("myexp", ShowMyExp)
	RegConsoleCmd("usejob", Job)
	RegConsoleCmd("myinfo", MyInfo)
	RegConsoleCmd("jobinfo", JobInfo)
	RegConsoleCmd("jobskillinfo", JobSkillInfo)
	RegConsoleCmd("rpgmenu", RPG_Menu)

	RegAdminCmd("sm_giveexp",Command_GiveExp,ADMFLAG_KICK,"!sm_giveexp [#userid|name] [number of points]")
	RegAdminCmd("sm_givelv",Command_GiveLevel,ADMFLAG_KICK,"!sm_givelv [#userid|name] [number of points]")


	JocExp = CreateConVar("sm_JocExp","80","EXP that Jockey gives", FCVAR_PLUGIN)
	HunExp = CreateConVar("sm_HunExp","100", "EXP that Hunter gives", FCVAR_PLUGIN)
	ChaExp = CreateConVar("sm_ChaExp","110","EXP that Charger gives", FCVAR_PLUGIN)
	SmoExp = CreateConVar("sm_SmoExp","70","EXP that Smoker gives", FCVAR_PLUGIN)
	SpiExp = CreateConVar("sm_SpiExp","50","EXP that Spitter gives", FCVAR_PLUGIN)
	BooExp = CreateConVar("sm_BooExp","50","EXP that Boomer gives", FCVAR_PLUGIN)
	TanExp = CreateConVar("sm_TanExp","2000","EXP that Tank gives", FCVAR_PLUGIN)
	WitExp = CreateConVar("sm_WitExp","500","EXP that Witch gives", FCVAR_PLUGIN)
	ComExp = CreateConVar("sm_ComExp","25","EXP that Common Zombie gives", FCVAR_PLUGIN)

	LvUpExp1 = CreateConVar("sm_LvUpExp1","50","Required EXP to be Level 1", FCVAR_PLUGIN)
	LvUpExp2 = CreateConVar("sm_LvUpExp2","100","Required EXP to be Level 2", FCVAR_PLUGIN)
	LvUpExp3 = CreateConVar("sm_LvUpExp3","150","Required EXP to be Level 3", FCVAR_PLUGIN)
	LvUpExp4 = CreateConVar("sm_LvUpExp4","200","Required EXP to be Level 4", FCVAR_PLUGIN)
	LvUpExp5 = CreateConVar("sm_LvUpExp5","260","Required EXP to be Level 5", FCVAR_PLUGIN)
	LvUpExp6 = CreateConVar("sm_LvUpExp6","320","Required EXP to be Level 6", FCVAR_PLUGIN)
	LvUpExp7 = CreateConVar("sm_LvUpExp7","400","Required EXP to be Level 7", FCVAR_PLUGIN)
	LvUpExp8 = CreateConVar("sm_LvUpExp8","480","Required EXP to be Level 8", FCVAR_PLUGIN)
	LvUpExp9 = CreateConVar("sm_LvUpExp9","600","Required EXP to be Level 9", FCVAR_PLUGIN)
	LvUpExp10 = CreateConVar("sm_LvUpExp10","730","Required EXP to be Level 10", FCVAR_PLUGIN)
	LvUpExp11 = CreateConVar("sm_LvUpExp11","860","Required EXP to be Level 11", FCVAR_PLUGIN)
	LvUpExp12 = CreateConVar("sm_LvUpExp12","1050","Required EXP to be Level 12", FCVAR_PLUGIN)
	LvUpExp13 = CreateConVar("sm_LvUpExp13","1250","Required EXP to be Level 13", FCVAR_PLUGIN)
	LvUpExp14 = CreateConVar("sm_LvUpExp14","1500","Required EXP to be Level 14", FCVAR_PLUGIN)
	LvUpExp15 = CreateConVar("sm_LvUpExp15","1750","Required EXP to be Level 15", FCVAR_PLUGIN)
	LvUpExp16 = CreateConVar("sm_LvUpExp16","2000","Required EXP to be Level 16", FCVAR_PLUGIN)
	LvUpExp17 = CreateConVar("sm_LvUpExp17","2250","Required EXP to be Level 17", FCVAR_PLUGIN)
	LvUpExp18 = CreateConVar("sm_LvUpExp18","2550","Required EXP to be Level 18", FCVAR_PLUGIN)
	LvUpExp19 = CreateConVar("sm_LvUpExp19","2850","Required EXP to be Level 19", FCVAR_PLUGIN)
	LvUpExp20 = CreateConVar("sm_LvUpExp20","3200","Required EXP to be Level 20", FCVAR_PLUGIN)
	LvUpExp21 = CreateConVar("sm_LvUpExp20","3550","Required EXP to be Level 21", FCVAR_PLUGIN)
	LvUpExp22 = CreateConVar("sm_LvUpExp20","3900","Required EXP to be Level 22", FCVAR_PLUGIN)
	LvUpExp23 = CreateConVar("sm_LvUpExp20","4300","Required EXP to be Level 23", FCVAR_PLUGIN)
	LvUpExp24 = CreateConVar("sm_LvUpExp20","4750","Required EXP to be Level 24", FCVAR_PLUGIN)
	LvUpExp25 = CreateConVar("sm_LvUpExp20","5250","Required EXP to be Level 25", FCVAR_PLUGIN)
	LvUpExp26 = CreateConVar("sm_LvUpExp20","5800","Required EXP to be Level 26", FCVAR_PLUGIN)
	LvUpExp27 = CreateConVar("sm_LvUpExp20","7400","Required EXP to be Level 27", FCVAR_PLUGIN)
	LvUpExp28 = CreateConVar("sm_LvUpExp20","8050","Required EXP to be Level 28", FCVAR_PLUGIN)
	LvUpExp29 = CreateConVar("sm_LvUpExp20","8750","Required EXP to be Level 29", FCVAR_PLUGIN)
	LvUpExp30 = CreateConVar("sm_LvUpExp20","9500","Required EXP to be Level 30", FCVAR_PLUGIN)

	LvUpSP = CreateConVar("sm_LvUpSP","50","given Status Points when level's up", FCVAR_PLUGIN)

	ReviveExp = CreateConVar("sm_ReviveExp","120","EXP when you succeed Setting someone up", FCVAR_PLUGIN)

	DefExp = CreateConVar("sm_DefExp","200","EXP when you succeed to revive someone with defibrillator", FCVAR_PLUGIN)


	HookEvent("witch_killed", WK)
	HookEvent("player_death", PK)
	HookEvent("infected_death", IK)
	HookEvent("player_first_spawn", PFS)
	HookEvent("player_spawn", PlayerS)
	HookEvent("player_hurt", PH)
	HookEvent("infected_hurt", IH)
	HookEvent("heal_success", HealSuc)
	HookEvent("jockey_ride_end", JocRideEnd)
	HookEvent("round_start", RoundStart)
	HookEvent("revive_success", RevSuc)
	HookEvent("defibrillator_used", DefUsed)
	HookEvent("weapon_fire", WeaponF, EventHookMode_Post)


	ZC = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")

	LegValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	OffNPA = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack")
	C1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")
	C2 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip2")

	Multi = 0.5


	AutoExecConfig(true, "l4d2_RollPlayingGameMode")
}

public Action:PFS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckExp[target] = CreateTimer(1.0, CEOP, target, TIMER_REPEAT)
	if(!IsFakeClient(target))
	{
		PrintToChat(target, "\x03you are using \x05RPG Mode Version \x04 1.0.7")
		PrintToChat(target, "\x03Your Level is \x04 %d \x03", Lv[target])
		PrintToChat(target, "\x03Strength: \x04%d, \x03Agility: \x04%d, \x03Health: \x04%d, \x03Endurance: \x04%d", Str[target], Agi[target], Health[target], Endurance[target])
		PrintToChat(target, "\x03Intelligence: \x04%d", Intelligence[target])
	}
}

public Action:CEOP(Handle:timer, any:target)
{

	if(EXP[target] > GetConVarInt(LvUpExp1) && Lv[target] == 0)
	{


		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 1 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp2) && Lv[target] == 1)
	{

		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 2 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}

	if(EXP[target] > GetConVarInt(LvUpExp3) && Lv[target] == 2)
	{


		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 3 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}

	if(EXP[target] > GetConVarInt(LvUpExp4) && Lv[target] == 3)
	{

		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 4 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}

	if(EXP[target] > GetConVarInt(LvUpExp5) && Lv[target] == 4)
	{

		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 5 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}

	if(EXP[target] > GetConVarInt(LvUpExp6) && Lv[target] == 5)
	{

		Lv[target] += 1


		StatusPoint[target] += GetConVarInt(LvUpSP)



		SkillPoint[target] += 1


		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 6 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")

		EXP[target] = 0
	}
			if(EXP[target] > GetConVarInt(LvUpExp7) && Lv[target] == 6)
	{

		Lv[target] += 1

		StatusPoint[target] += GetConVarInt(LvUpSP)

		SkillPoint[target] += 1

PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 7 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}

	//???? ?? ? ??? ????...
	if(EXP[target] > GetConVarInt(LvUpExp8) && Lv[target] == 7)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 8 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}

	//???? ?? ? ??? ????...
	if(EXP[target] > GetConVarInt(LvUpExp9) && Lv[target] == 8)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 9 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}

	//???? ?? ? ??? ????...
	if(EXP[target] > GetConVarInt(LvUpExp10) && Lv[target] == 9)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 10 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp11) && Lv[target] == 10)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 11 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp12) && Lv[target] == 11)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 12 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp13) && Lv[target] == 12)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 13 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp14) && Lv[target] == 13)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 14 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp15) && Lv[target] == 14)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 15 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp16) && Lv[target] == 15)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 16 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp17) && Lv[target] == 16)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 17 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp18) && Lv[target] == 17)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 18 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp19) && Lv[target] == 18)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 19 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp20) && Lv[target] == 19)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 20 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp21) && Lv[target] == 20)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 21 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp22) && Lv[target] == 21)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 22 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp23) && Lv[target] == 22)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 23 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp24) && Lv[target] == 23)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 24 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp25) && Lv[target] == 24)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 25 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp26) && Lv[target] == 25)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 26 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp27) && Lv[target] == 26)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 27 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp28) && Lv[target] == 27)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 28 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp29) && Lv[target] == 28)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 29 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
	
	if(EXP[target] > GetConVarInt(LvUpExp30) && Lv[target] == 29)
	{
		//??? ????
		Lv[target] += 1
		
		//????? ???? ??
		StatusPoint[target] += GetConVarInt(LvUpSP)
		
		//?? ???? ??
		SkillPoint[target] += 1
		
		//?? ? ??
		PrintToChat(target, "\x04Level Up!! \x03Your Level is now \x05 30 \x03Just type \x05!rpgmenu \x03and get your status points used")
		PrintToChat(target, "\x03You got Skill Point. Through \x05!rpgmenu \x03You can get Skills")
		
		//???? ??? ????.
		EXP[target] = 0
	}
}

//??? ??? ???? ??!
public Action:PK(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new deadbody = GetClientOfUserId(GetEventInt(event, "userid"))
	new ZClass = GetEntData(deadbody, ZC)
	
	if(!IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVORS)
	{
		if(ZClass == 1)
		{
			EXP[killer] += GetConVarInt(SmoExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Smoker", GetConVarInt(SmoExp))
		}
	
		if(ZClass == 2)
		{
			EXP[killer] += GetConVarInt(BooExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Boomer", GetConVarInt(BooExp))
		}
	
		if(ZClass == 3)
		{
			EXP[killer] += GetConVarInt(HunExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Hunter", GetConVarInt(HunExp))
		}
	
		if(ZClass == 4)
		{
			EXP[killer] += GetConVarInt(SpiExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Spitter", GetConVarInt(SpiExp))
		}
	
		if(ZClass == 5)
		{
			EXP[killer] += GetConVarInt(JocExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Jockey", GetConVarInt(JocExp))
		}
	
		if(ZClass == 6)
		{
			EXP[killer] += GetConVarInt(ChaExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Charger", GetConVarInt(ChaExp))
		}
		
		if(IsPlayerTank(deadbody))
		{
			EXP[killer] += GetConVarInt(TanExp)
			PrintToChat(killer, "\x03\x03You got EXP as much as \x04%d \x03from \x05Tank", GetConVarInt(TanExp))
		}
	}
}

public Action:WK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(WitExp)
		PrintToChat(killer, "\\x03You got EXP as much as \x04%d \x03from \x05Witch", GetConVarInt(WitExp))
	}
}

public Action:IK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(ComExp)
	}
}

public Action:PH(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	
	//???
	if(GetClientTeam(hurted) == TEAM_SURVIVORS && !IsFakeClient(hurted))
	{
		if(Endurance[hurted] < 51)
		{
			new EndHealth = GetEventInt(event, "health")
			new Float:EndFloat = Endurance[hurted]*0.01
			new EndAddHealth = RoundToNearest(dmg*EndFloat)
			SetEndurance(hurted, EndHealth, EndAddHealth)
		}
		else
		{
			new EndHealth = GetEventInt(event, "health")
			new EndAddHealth = RoundToNearest(dmg*0.5)
			SetEndurance(hurted, EndHealth, EndAddHealth)
			//???
			new Float:RefFloat = (Endurance[hurted]-50)*0.01
			new RefDecHealth = RoundToNearest(dmg*RefFloat)
			new RefHealth = GetClientHealth(attacker)
			SetEndReflect(attacker, RefHealth, RefDecHealth)
		}
		
		if(ActiBioS[hurted] == true)
		{
			new BioHealth = GetEventInt(event, "health")
			SetEndurance(hurted, BioHealth, dmg)
		}
	}
	
	//?
	if(GetClientTeam(hurted) == TEAM_INFECTED)
	{
		new StrHealth = GetEventInt(event, "health")
		new Float:StrFloat = Str[attacker]*0.02
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		SetStrDamage(hurted, StrHealth, StrRedHealth)
	}
}

//??? ??? ??
SetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}

//?? ??? ??
SetEndReflect(client, health, endurance)
{
	if(health > endurance)
	{
		SetEntityHealth(client, health-endurance)
	}
	else
	{
		ForcePlayerSuicide(client)
	}
}

//? ??? ??
SetStrDamage(client, health, str)
{
	if(health > str)
	{
		SetEntityHealth(client, health-str)
	}
}

public Action:IH(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetEventInt(event, "entityid")
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "amount")
	if(GetClientTeam(attacker) == TEAM_SURVIVORS && !IsFakeClient(attacker))
	{
		new Float:StrFloat = Str[attacker]*0.02
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		if(GetEntProp(hurted, Prop_Data, "m_iHealth") > StrRedHealth)
		{
			SetEntProp(hurted, Prop_Data, "m_iHealth", GetEntProp(hurted, Prop_Data, "m_iHealth")-StrRedHealth)
		}
	}
}

//?? ???
public Action:Command_GiveExp(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: sm_giveexp [Name] [Amount Of EXP to give]");
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		PrintToChatAll("\x03Admin gave \x04%d \x05EXP %d", arg, arg2);
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			EXP[targetclient] += StringToInt(arg2);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveLevel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: sm_giveexp [Name] [Amount of Level to give]");
		return Plugin_Handled;
	}

	new String:arg[MAX_NAME_LENGTH], String:arg2[16];
	GetCmdArg(1, arg, sizeof(arg));

	if (args > 1)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	new targetclient;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			if(Lv[targetclient] + StringToInt(arg2) < 31)
			{
				Lv[targetclient] += StringToInt(arg2);
				StatusPoint[targetclient] += GetConVarInt(LvUpSP)*StringToInt(arg2)
				SkillPoint[targetclient] += StringToInt(arg2)
				PrintToChatAll("\x03Admin gave \x04%s \x05Levels %d", arg, arg2);
			}
			else
			{
				PrintToChat(client, "\x04 %s \x03Limited Level is 30. You can't give over it");
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

//?? ??
public Action:StatusChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		StatusChooseMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:StatusChooseMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(StatusMenu)
	SetMenuTitle(menu, "Status Points left: %d", StatusPoint[clientId])
	AddMenuItem(menu, "option1", "Strength")
	AddMenuItem(menu, "option2", "Agillity")
	AddMenuItem(menu, "option3", "Health")
	AddMenuItem(menu, "option4", "Endurance")
	AddMenuItem(menu, "option5", "Intelligence")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public StatusMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //?
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 0
			}
			
			case 1: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 1
			}
			
			case 2: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 2
			}
			
			case 3: //???
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 3
			}
			
			case 4: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 4
			}
		}
	}
}

public Action:ConfirmChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		StatusConfirmFunc(client)
	}
	return Plugin_Handled
}

public Action:StatusConfirmFunc(clientId)
{
	new cost;
	switch(ISCONFIRM[clientId])
	{
		case 0: //?
		{
			cost = 1
		}
		
		case 1: //??
		{
			cost = 1
		}
		
		case 2: //??
		{
			cost = 1
		}
		
		case 3: //???
		{
			cost = 1
		}
		
		case 4: //??
		{
			cost = 1
		}
		
		case 5: //?? ??
		{
			cost = 1
		}
		
		case 6: //?? ??
		{
			cost = 1
		}
		
		case 7: //????
		{
			cost = 1
		}
		
		case 8: //??? ??
		{
			cost = 1
		}
		
		case 9: //??
		{
			cost = 1
		}
		
		case 10: //????
		{
			cost = 1
		}
		
		case 11: //?? ??
		{
			cost = 1
		}
		
		case 12: //?? ??
		{
			cost = 1
		}
	}
	new Handle:menu = CreateMenu(StatusConfirmHandler)
	SetMenuTitle(menu, "Required Points: %d", cost)
	AddMenuItem(menu, "option1", "Oh! Yeah~")
	AddMenuItem(menu, "option2", "No!!!!!!!")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public StatusConfirmHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		if(itemNum == 0)
		{
			switch(ISCONFIRM[client])
			{
				case 0: //?
				{
					if(StatusPoint[client] > 0)
					{
						Str[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Strength \x03has become \x05 %d.\n\x03Give more Damage as much as \x05%d \x03Percent", Str[client], Str[client]*2)
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 1: //??
				{
					if(StatusPoint[client] > 0)
					{
						Agi[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Agility \x03has become \x05%d. \n\x04Move Speed and Jumping height \x03are increased by \x05%d \x03Percent", Agi[client], Agi[client])
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 2: //??
				{
					if(StatusPoint[client] > 0)
					{
						Health[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Health \x03is increased by \x05 %d", 10)
						new HealthForStatus = GetClientHealth(client)
						CreateTimer(0.1, StatusUp, client)
						if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
						{
							SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
						}
						if(JD[client] == 2)
						{
							if(TrainedHealthLv[client] < 2)
							{
								SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
							}
							else
							{
								SetEntData(client, FindDataMapOffs(client, "m_iHealth"),  HealthForStatus+(10*TrainedHealthLv[client]), 4, true)
							}
						}
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 3: //???
				{
					if(StatusPoint[client] > 0)
					{
						Endurance[client] += 1
						StatusPoint[client] -= 1
						if(Endurance[client] < 51)
						{
							PrintToChat(client, "\x04Endurance \x03has become \x05%d. \n\x03You get \x05%d \x03Percent \x04less Damage", Endurance[client], Endurance[client])
						}
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
						if(Endurance[client] > 50)
						{
							PrintToChat(client, "\x03Added Ability: \x04Damage Reflect. \x03Reflection Rate: \x05%d \x03Percent", (Endurance[client]-50))
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 4: //??
				{
					if(StatusPoint[client] > 0)
					{
						Intelligence[client] += 1
						StatusPoint[client] -= 1
						PrintToChat(client, "\x04Intelligence \x03has become \x05%d. \n\x03Skill Efficiency increased", Intelligence[client])
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 5: //??
				{
					if(SkillPoint[client] > 0)
					{
						HealingBool[client] = true
						HealingLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x03Skill \x04Healing \x03's Level has become \x05 %d.", HealingLv[client])
						if(HealingLv[client] < 21)
						{
							PrintToChat(client, "\x03Amount of Heal ::\x05 %d \x03And the Delay ::\x05 %d \xSeconds", Intelligence[client] + 3*HealingLv[client], 60 - 2*HealingLv[client])
						}
						else
						{
							PrintToChat(client, "\x03Amount of Heal ::\x05 %d \x03And the Delay ::\x05 %d \xSeconds", Intelligence[client] + 3*HealingLv[client], 20)
						}
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 6: //??
				{
					if(SkillPoint[client] > 0)
					{
						if(EarthQuakeLv[client] < 25)
						{
							EQBool[client] = true
							EarthQuakeLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x03Skill \x04EarthQuake \x03's Level has become \x05 %d.", EarthQuakeLv[client])
							PrintToChat(client, "\x03Skill \x04EarthQuake \x03's Range has become \x05 %d.", (50+Intelligence[client])*EarthQuakeLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You already mastered \x04EarthQuake")
						}
					}
					else
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
				}
				
				case 7: //????!!
				{
					if(SkillPoint[client] > 0 && JD[client] == 1)
					{
						EnaHA[client] = true
						HealingAuraLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x03Skill \x04Making Ammo \x03's Level has become \x05 %d.", HealingAuraLv[client])
						CreateTimer(0.1, StatusUp, client)
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					
					if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					
					if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not an \x04Engineer")
					}
				}
				
				case 8: //??? ??
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						if(TrainedHealthLv[client] < 2)
						{
							TrainedHealthLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x04Trained Health \x03's Level has become \x05 %d.", TrainedHealthLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You already mastered \x04Trained Health")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 9: //??
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						EnaSprint[client] = true
						SprintLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x04Sprint \x03's Level has become \x05 %d.", SprintLv[client])
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 10: //????
				{
					if(SkillPoint[client] > 0 && JD[client] == 3)
					{
						EnaBioS[client] = true
						ActiBioS[client] = true
						BioShieldLv[client] += 1
						SkillPoint[client] -= 1
						PrintToChat(client, "\x04Bionic Shield \x03's Level has become \x05 %d.", BioShieldLv[client])
						if(SkillPoint[client] > 0)
						{
							SkillChooseMenuFunc(client)
							PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 2)
					{
						PrintToChat(client, "\x03You are not a \x04Bionic Weapon.")
					}
				}
				
				case 11: //?? ??
				{
					if(SkillPoint[client] > 0 && JD[client] == 2)
					{
						if(UpgradeGunLv[client] < 10)
						{
							UpgradeGunLv[client] += 1
							SkillPoint[client] -= 1
							UGBool[client] = true
							EnaUG[client] = true
							PrintToChat(client, "\x04Infinite Ammo \x03's Level has become \x04%d.", UpgradeGunLv[client])
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
							}
						}
						else
						{
							PrintToChat(client, "\x04You already mastered \x05Infinite Ammo")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not a \x04Soldier")
					}
				}
				
				case 12: //?? ??
				{
					if(SkillPoint[client] > 0 && JD[client] == 1)
					{
						if(FWLv[client] < 10)
						{
							FWLv[client] += 1
							SkillPoint[client] -= 1
							PrintToChat(client, "\x03you \x04Fortified \x03Weapons")
							if(SkillPoint[client] > 0)
							{
								SkillChooseMenuFunc(client)
								PrintToChat(client, "\x03You are having \x04Status Points \x03Yet.")
							}
						}
						else
						{
							PrintToChat(client, "\x03You can't \x04Fortify Weapons \x03anymore")
						}
					}
					else if(SkillPoint[client] < 1) 
					{
						PrintToChat(client, "\x03You are having no \x04Status Point")
					}
					else if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
					{
						PrintToChat(client, "\x03You are not an \x04Engineer")
					}
				}
			}
		}
	}
}

public Action:StatusUp(Handle:timer, any:client)
{
	RebuildStatus(client)
}

RebuildStatus(client)
{
	if(SoldierBool[client] == true)
	{
		if(TrainedHealthLv[client] > 0)
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]*TrainedHealthLv[client]), 4, true)
		}
		else
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]), 4, true)
		}
	}
	else
	{
		SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]), 4, true)
	}
	SetEntDataFloat(client, LegValue, 1.0*(1.0 + Agi[client]*0.01), true)
	if(Agi[client] < 50)
	{
		SetEntityGravity(client, 1.0*(1.0-(Agi[client]*0.005)))
	}
	else
	{
		SetEntityGravity(client, 0.50)
	}
}

public Action:HealSuc(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new HealSucTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(HealSucTarget) == TEAM_SURVIVORS && !IsFakeClient(HealSucTarget) && Lv[HealSucTarget] > 0)
	{
		if(JD[HealSucTarget] == 0 || JD[HealSucTarget] == 1 || JD[HealSucTarget] == 3)
		{
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget]), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget]), 4, true)
		}
		
		if(JD[HealSucTarget] == 2)
		{
			if(TrainedHealthLv[HealSucTarget] == 0)
			{
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget]), 4, true)
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget]), 4, true)
			}
			
			if(TrainedHealthLv[HealSucTarget] > 0)
			{
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget])*TrainedHealthLv[HealSucTarget], 4, true)
				SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget])*TrainedHealthLv[HealSucTarget], 4, true)
			}
		}
	}
}

public Action:JocRideEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new JocEndTarget = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(JocEndTarget) == TEAM_SURVIVORS && !IsFakeClient(JocEndTarget) && Lv[JocEndTarget] > 0)
	{
		RebuildStatus(JocEndTarget)
	}
}

public Action:PlayerS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(Lv[target] > 0 && GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		RebuildStatus(target)
		PrintToChat(target, "\x03Your Level is \x04 %d.", Lv[target])
		PrintToChat(target, "\x03Strenth: \x04%d, \x03Agility: \x04%d, \x03Health: \x04%d, \x03Endurance: \x04%d", Str[target], Agi[target], Health[target], Endurance[target])
		PrintToChat(target, "\x03Intelligence: \x04%d", Intelligence[target])
	}
}

bool:IsPlayerTank(client)
{
	//????? ?????
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	else
	return false;
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 0; i < MaxClients; i++)
	{
		if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i))
		{
			RebuildStatus(i)
			PrintToChat(i, "\x03Your Level is \x04 %d.", Lv[i])
			PrintToChat(i, "\x03Strenth: \x04%d, \x03Agility: \x04%d, \x03Health: \x04%d, \x03Endurance: \x04%d", Str[i], Agi[i], Health[i], Endurance[i])
			PrintToChat(i, "\x03Intelligence: \x04%d", Intelligence[i])
		}
	}
}

public Action:SkillChooseMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		SkillChooseMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:SkillChooseMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(SkillMenu)
	SetMenuTitle(menu, "Skill Points Left: %d", SkillPoint[clientId])
	AddMenuItem(menu, "option1", "Healing")
	AddMenuItem(menu, "option2", "EarthQuake")
	AddMenuItem(menu, "option3", "Making Ammo")
	AddMenuItem(menu, "option4", "Trained Health")
	AddMenuItem(menu, "option5", "Sprint")
	AddMenuItem(menu, "option6", "Bionic Sheild")
	AddMenuItem(menu, "option7", "Infinite Ammo")
	AddMenuItem(menu, "option8", "Fortify Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public SkillMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 5
			}
			
			case 1: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 6
			}
			
			case 2: //?? ??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 7
			}
			
			case 3: //??? ??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 8
			}
			
			case 4: //??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 9
			}
			
			case 5: //?? ??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 10
			}
			
			case 6: //?? ??
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 11
			}
			
			case 7: //????
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 12
			}
		}
	}
}

public Action:DetermineSkillMenu(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS)
	{
		DetermineSkillMenuFunc(client)
	}
	return Plugin_Handled
}

public Action:DetermineSkillMenuFunc(clientId)
{
	new Handle:menu = CreateMenu(DeSkiMenu)
	SetMenuTitle(menu, "Skill to Use")
	AddMenuItem(menu, "option1", "Skill Lock")
	AddMenuItem(menu, "option2", "Healing")
	AddMenuItem(menu, "option3", "EarthQuake")
	AddMenuItem(menu, "option4", "Making Ammo")
	AddMenuItem(menu, "option5", "Sprint")
	AddMenuItem(menu, "option6", "Bionic Shield")
	AddMenuItem(menu, "option7", "Infinite Ammo")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public DeSkiMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //??? ??
			{
				SkillConfirm[client] = 0
				PrintToChat(client, "\x03 Lock all Skills")
			}
			
			case 1: //??
			{
				if(HealingLv[client] > 0)
				{
					SkillConfirm[client] = 1
					PrintToChat(client, "\x03Skill to Use :: \x04Healing")
					PrintToChat(client, "\x03How to Use :: Zoom")
				}
				else
				{
					PrintToChat(client, "\x03You didn't learned \x04Healing \x03Yet.")
				}
			}
			
			case 2: //??
			{
				if(EarthQuakeLv[client] > 0)
				{
					SkillConfirm[client] = 2
					PrintToChat(client, "\x03Skill to Use:: \x04EarthQuake")
					PrintToChat(client, "\x03How to Use :: Zoom")
					if(EarthQuakeLv[client] < 21)
					{
						PrintToChat(client, "\x03Delay :: \x05%d \x03Seconds",  60-2*EarthQuakeLv[client])
					}
					else
					{
						PrintToChat(client, "\x03Delay :: \x05 20 \x03Seconds")
					}
				}
				else
				{
					PrintToChat(client, "\x03You didn't learned \x04EarthQuake \x03Yet.")
				}
			}
			
			case 3: //????
			{
				if(HealingAuraLv[client] > 0 && JD[client] == 1)
				{
					SkillConfirm[client] = 3
					PrintToChat(client, "\x03Skill to Use :: \x04Making Ammo")
					PrintToChat(client, "\x03How to Use :: Zoom")
					PrintToChat(client, "\x03Delay :: \x05 %d \x03Seconds", 20+HealingAuraLv[client])
					PrintToChat(client, "\x03Amount :: \x05 %d", 5*HealingAuraLv[client])
				}
				
				if(HealingAuraLv[client] < 1)
				{
					PrintToChat(client, "\x03You didn't learned \x04Making Ammo \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 2 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not an \x04Engineer")
				}
			}
			
			case 4: //??
			{
				if(SprintLv[client] > 0 && JD[client] == 2)
				{
					SkillConfirm[client] = 4
					PrintToChat(client, "\x03Skill to Use :: \x04Sprint")
					PrintToChat(client, "\x03How to Use :: Zoom")
				}
				
				if(SprintLv[client] < 1)
				{
					PrintToChat(client, "\x03You didn't learned \x04Sprint \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not a \x04Soldier")
				}
			}
			
			case 5: //?? ??
			{
				if(BioShieldLv[client] > 0 && JD[client] == 3)
				{
					SkillConfirm[client] = 5
					PrintToChat(client, "\x03Skill to Use :: \x04Bionic Shield")
					PrintToChat(client, "\x03How to Use :: Zoom")
				}
				
				if(BioShieldLv[client] < 1)
				{
					PrintToChat(client, "\x03You didn't learned \x04Bionic Shield \x03Yet.")
				}
				
				if(JD[client] == 0 || JD[client] == 1 || JD[client] == 2)
				{
					PrintToChat(client, "\x03You are not a \x04Bionic Weapon")
				}
			}
			
			case 6: //?? ??
			{
				if(UpgradeGunLv[client] > 0 && JD[client] == 2)
				{
					SkillConfirm[client] = 6
					PrintToChat(client, "\x03Skill to Use :: \x04Infinite Ammo")
					PrintToChat(client, "\x03How to Use :: Zoom")
				}
				else if(UpgradeGunLv[client] < 1)
				{
					PrintToChat(client, "\x03You didn't learned \x04Infinite Ammo \x03Yet.")
				}
				else if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
				{
					PrintToChat(client, "\x03You are not a \x04Soldier")
				}
			}
		}
	}
}

public Action:Job(client, args)
{
	if(GetClientTeam(client) == TEAM_SURVIVORS && Lv[client] > 14)
	{
		JobFunc(client)
	}
	else
	{
		PrintToChat(client, "\x03You are under the Level of 15")
	}
	return Plugin_Handled
}

public Action:JobFunc(clientId)
{
	new Handle:menu = CreateMenu(JobMenu)
	SetMenuTitle(menu, "Job to get")
	AddMenuItem(menu, "option1", "Engineer")
	AddMenuItem(menu, "option2", "Soldier")
	AddMenuItem(menu, "option3", "Bionic Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: // ???
			{
				if(JobChooseBool[client] == false && Intelligence[client] < 65)
				{
					PrintToChat(client, "\x03You \x04failed \x03because \x04Status Condition is not satisfied")
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You are already having Job")
				}
				
				if(Intelligence[client] > 64 && JobChooseBool[client] == false)
				{
					AcolyteBool[client] = true
					Intelligence[client] += 50
					Str[client] += 5
					Agi[client] += 5
					Endurance[client] += 5
					JobChooseBool[client] = true
					PrintToChat(client, "\x03You got the Occupation Of \x04Engineer.")
					PrintToChat(client, "\x03Strength \x05 5 \x03, Agility \x05 5 \x03, Endurance \x05 5 \x03, Intelligence \x05 50 \x04Increased.")
					JD[client] = 1
				}
			}
			
			case 1: //??
			{
				if(Intelligence[client] > 4 && Agi[client] > 9 && Endurance[client] > 14 && Str[client] > 44 && JobChooseBool[client] == false)
				{
					SoldierBool[client] = true
					Agi[client] += 10
					Str[client] += 30
					Intelligence[client] += 5
					JobChooseBool[client] = true
					PrintToChat(client, "\x03You got the Occupation Of \x04Solider.")
					PrintToChat(client, "\x03Strength \x05 30 \x03, Agility \x05 10 \x03, Intelligence \x05 5 \x04Increased.")
					JD[client] = 2
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You are already having Job")
				}
				
				if(JobChooseBool[client] == false)
				{
					if(Intelligence[client] < 5 || Agi[client] < 10 || Endurance[client] < 15 || Str[client] < 45)
					{
						PrintToChat(client, "\x03You \x04failed \x03because \x04Status Condition is not satisfied")
					}
				}
			}
			
			case 2: //?? ??
			{
				if(Str[client] > 24 && Agi[client] > 24 && Intelligence[client] > 9 && Endurance[client] > 14 && Health[client] > 19 && JobChooseBool[client] == false)
				{
					BioWeaponBool[client] = true
					Agi[client] += 15
					Health[client] += 40
					Str[client] += 15
					JobChooseBool[client] = true
					PrintToChat(client, "\x03You got the Occupation Of \x04Bionic Weapon.")
					PrintToChat(client, "\x03Strength \x05 15 \x03, Agility \x05 15 \x03, Health \x05 40 \x04Increased")
					SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 100+10*Health[client], 4, true)
					SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+10*Health[client], 4, true)
					JD[client] = 3
				}
				
				if(JobChooseBool[client] == true)
				{
					PrintToChat(client, "\x03You are already having Job")
				}
				
				if(JobChooseBool[client] == false)
				{
					if(Intelligence[client] < 10 || Agi[client] < 25 || Endurance[client] < 15 || Str[client] < 25 || Health[client] < 20)
					{
						PrintToChat(client, "\x03You \x04failed \x03because \x04Status Condition is not satisfied")
					}
				}
			}
		}
	}
}

public Action:MyInfo(client, args)
{
	MyInfoFunc(client)
	return Plugin_Handled
}

public Action:MyInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(MyInfoMenu)
	SetMenuTitle(menu, "Informations")
	AddMenuItem(menu, "option1", "My Level and Status")
	AddMenuItem(menu, "option2", "Job Informantions")
	if(JD[clientId] > 0)
	{
		AddMenuItem(menu, "option3", "Job Skill Information")
	}
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public MyInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //?? ? ?????
			{
				PrintToChat(client, "\x03Your Level is \x06 %d.", Lv[client])
				PrintToChat(client, "\x03Strength: \x07%d, \x03Agility: \x07%d, \x03Health: \x07%d, \x03Endurance: \x07%d, \x03Intelligence: \x07%d", Str[client], Agi[client], Health[client], Endurance[client], Intelligence[client])
			}
			
			case 1: //?? ??
			{
				FakeClientCommand(client, "jobinfo")
			}
			
			case 2: //?? ?? ??
			{
				FakeClientCommand(client, "jobskillinfo")
			}
		}
	}
}

public Action:JobInfo(client, args)
{
	JobInfoFunc(client)
	return Plugin_Handled
}

public Action:JobInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(JobInfoMenu)
	SetMenuTitle(menu, "Job Informations")
	AddMenuItem(menu, "option1", "Engineer")
	AddMenuItem(menu, "option2", "Soldier")
	AddMenuItem(menu, "option3", "Bionic Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobInfoMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //???
			{
				PrintToChat(client, "\x06Status Condition to be Engineer")
				PrintToChat(client, "\x03Intelligence :: \x04 65")
			}
			
			case 1: //??
			{
				PrintToChat(client, "\x06Status Condition to be Soldier")
				PrintToChat(client, "\x03Intelligence :: \x04 5")
				PrintToChat(client, "\x03Agility :: \x04 10")
				PrintToChat(client, "\x03Endurance :: \x04 15")
				PrintToChat(client, "\x03Strength :: \x04 45")
			}
			
			case 2: //???
			{
				PrintToChat(client, "\x06Status Condition to be Bionic Weapon")
				PrintToChat(client, "\x03Intelligence :: \x04 10")
				PrintToChat(client, "\x03Agility :: \x04 25")
				PrintToChat(client, "\x03Health :: \x04 20")
				PrintToChat(client, "\x03Strength :: \x04 25")
				PrintToChat(client, "\x03Endurance :: \x04 15")
			}
		}
	}
}

public Action:JobSkillInfo(client, args)
{
	JobSkillInfoFunc(client)
	return Plugin_Handled
}

public Action:JobSkillInfoFunc(clientId)
{
	new Handle:menu = CreateMenu(JobSkillMenu)
	SetMenuTitle(menu, "Job Skill Information")
	AddMenuItem(menu, "option1", "Making Ammo")
	AddMenuItem(menu, "option2", "Passive::Trained Health")
	AddMenuItem(menu, "option3", "Sprint")
	AddMenuItem(menu, "option4", "Bionic Shield")
	AddMenuItem(menu, "option5", "Infinite Ammo")
	AddMenuItem(menu, "option6", "Passive::Fortify Weapon")
	SetMenuExitButton(menu, true)
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public JobSkillMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		switch(itemNum)
		{
			case 0: //?? ??
			{
				PrintToChat(client, "\x06Making Ammo")
				PrintToChat(client, "\x03Level :: \x04 %d", HealingAuraLv[client])
				PrintToChat(client, "\x03Making Amount :: \x04 %d", 5*HealingAuraLv[client])
			}
			
			case 1: //???::??? ??
			{
				PrintToChat(client, "\x06Trained Health")
				PrintToChat(client, "\x03Level :: \x04 %d", TrainedHealthLv[client])
				PrintToChat(client, "\x03Explanation :: \x04Increase Efficiency of Health Status")
			}
			
			case 2: //??
			{
				PrintToChat(client, "\x06Sprint")
				PrintToChat(client, "\x03Level :: \x04 %d", SprintLv[client])
				PrintToChat(client, "\x03Lasting Time :: \x04%d \x03Seconds", 6+2*SprintLv[client])
				PrintToChat(client, "\x03Explanation :: \x04During the Lasting Time, Moving Speed is doubled")
				PrintToChat(client, "\x03Delay :: \x04 %d \x03Seconds", 2*(6+2*SprintLv[client]))
			}
			
			case 3: //?? ??
			{
				PrintToChat(client, "\x06Bionic Shield")
				PrintToChat(client, "\x03Level :: \x04 %d", BioShieldLv[client])
				PrintToChat(client, "\x03Lasting Time :: \x04%d \x03Seconds", 2*BioShieldLv[client])
				PrintToChat(client, "\x03Explanation :: \x04During the Lasting Time, You are Unbeatable")
			}
			
			case 4: //?? ??
			{
				PrintToChat(client, "\x06Infinite Ammo")
				PrintToChat(client, "\x03Level :: \x04 %d", UpgradeGunLv[client])
				PrintToChat(client, "\x03Lasting Time :: \x04 %d", 20+2*UpgradeGunLv[client])
				PrintToChat(client, "\x03Explanation :: \x04During the Lasting Time, Ammo is Infinite")
			}
			
			case 5: //?? ??
			{
				PrintToChat(client, "\x06Fortify Weapon")
				PrintToChat(client, "\x03Level :: \x04 %d", FWLv[client])
				PrintToChat(client, "\x03Increasing Rate :: \x04 %d \x03Percent", FWLv[client])
				PrintToChat(client, "\x03Explanation :: \x04Attack Speed Increases")
			}
		}
	}
}

//RPG??~
public Action:RPG_Menu(client,args)
{
	RPG_MenuFunc(client)

	return Plugin_Handled
}
public Action:RPG_MenuFunc(clientId) 
{
	new Handle:menu = CreateMenu(RPG_MenuHandler)
	SetMenuTitle(menu, "EXP : %d",EXP[clientId])
	
	AddMenuItem(menu, "option1", "Use Status Points")
	AddMenuItem(menu, "option2", "Use Skill Points")
	AddMenuItem(menu, "option3", "Designate Skill to Zoom")
	AddMenuItem(menu, "option4", "Get Job[Only upward Lv.15]")
	AddMenuItem(menu, "option5", "Identify my Lv and Status")
	
	SetMenuExitButton(menu, true)
	
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER)

	return Plugin_Handled
}
public RPG_MenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	if ( action == MenuAction_Select ) 
	{
		switch (itemNum)
		{
			case 0: // ?? ??? ??
			{
				FakeClientCommand(client,"usestatus")
			}
			case 1: //?? ??? ??
			{
				FakeClientCommand(client,"useskill")
			}
			case 2: //??? ?? ??
			{
				FakeClientCommand(client,"DS")
			}
			case 3: //?? ??
			{
				FakeClientCommand(client,"usejob")
			}
			case 4: //?? ? ?? ??
			{
				FakeClientCommand(client,"myinfo")
			}
		}
	}
}

//??
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsPlayerAlive(client) && buttons & IN_ZOOM && GetClientTeam(client) == TEAM_SURVIVORS)
	{
		switch(SkillConfirm[client])
		{
			case 0:
			{
			
			}
			
			case 1:
			{
				if(HealingBool[client])
				{
					new ClientHealth = GetClientHealth(client)
					if(100 + Health[client]*10 > ClientHealth+Intelligence[client]+(3*HealingLv[client]))
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), ClientHealth+Intelligence[client]+(3*HealingLv[client]), 4, true)
						if(HealingLv[client] < 21)
						{
							CreateTimer(60.0 - 2*HealingLv[client], HealingDelayTimer, client)
						}
						else
						{
							CreateTimer(20.0, HealingDelayTimer, client)
						}
					}
					else
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 100+Health[client]*10, 4, true)
						if(HealingLv[client] < 21)
						{
							CreateTimer(60.0 - 2*HealingLv[client], HealingDelayTimer, client)
							PrintToChat(client, "\x03Skill \x04Healing Lv %d \x03was spelled. Delay Left:: \x05%d \x03Seconds", HealingLv[client], 60-2*HealingLv[client])
						}
						else
						{
							CreateTimer(20.0, HealingDelayTimer, client)
							PrintToChat(client, "\x03Skill \x04Healing Lv %d \x03was spelled. Delay Left:: \x05%d \x03Seconds", HealingLv[client], 20)
						}
					}	
					HealingBool[client] = false
				}
			}
	
			case 2:
			{
				if(EQBool[client])
				{
					GetClientAbsOrigin(client, NowLocation[client])
					Create_PointHurt(client)
					Shake_Screen(client, 100.0, 1.0, 1.0)
					EmitSoundToAll("player/footsteps/tank/walk/tank_walk05.wav")
					if(EarthQuakeLv[client] < 21)
					{
						CreateTimer(60.0-2*EarthQuakeLv[client], ResetEarthQuakeDelay, client)
					}
					else
					{
						CreateTimer(20.0, ResetEarthQuakeDelay, client)
					}
					EQBool[client] = false
					PrintToChat(client, "\x03Skill \x04EarthQuake \x03was spelled. Delay Left: \x05 %d \x03Seconds", 60-2*EarthQuakeLv[client])
				}
			}
		
			case 3:
			{
				if(EnaHA[client])
				{
					new ent = GetEntDataEnt2(client, OffAW)
					if(ent != -1)
					{
						new CC1 = GetEntData(ent, C1)
						new CC2 = GetEntData(ent, C2)
						SetEntData(ent, C1, CC1+5*HealingAuraLv[client], 4, true)
						SetEntData(ent, C2, CC2+5*HealingAuraLv[client], 4, true)
					}
					EnaHA[client] = false
					CreateTimer(20.0+HealingAuraLv[client], HealingAuraDelay, client)
					PrintToChat(client, "\x03You \x04Made Ammo!!")
				}	
			}
			
			case 4:
			{
				if(EnaSprint[client])
				{
					
					new SprintHealth = GetClientHealth(client)
					if(SprintHealth - ((100+10*Health[client])*0.5) > 0)
					{
						SetEntData(client, FindDataMapOffs(client, "m_iHealth"), SprintHealth - RoundToNearest((100+10*Health[client])*0.5), 4, true)
						EnaSprint[client] = false
						CreateTimer(6.0+2*SprintLv[client], SprinDelay, client)
						PrintToChat(client, "\x04Sprint \x03was spelled.")
						PrintToChat(client, "\x03By the Penalty, You're hurted by \x05%d", RoundToNearest((100+10*Health[client])*0.5))
						SetEntDataFloat(client, LegValue, 2.0*(1.0 + Agi[client]*0.02), true)
					}
					else
					{
						PrintToChat(client, "\x03You can't Sprint because \x04penalty condition is not Satisfied.")
					}
				}
			}
			
			case 5:
			{
				if(EnaBioS[client])
				{
					EnaBioS[client] = false
					ActiBioS[client] = true
					CreateTimer(2.0+2*BioShieldLv[client], BionSDelay, client)
					PrintToChat(client, "\x04Bionic Shield \x03was spelled")
				}
			}
			
			case 6:
			{
				if(EnaUG[client])
				{
					EnaUG[client] = false
					CreateTimer(20.0+2*UpgradeGunLv[client], UGTimer, client)
					PrintToChat(client, "\x04Infinite Ammo \x03is spelled. Delay Left: \x04%d \x03Seconds", 20+2*UpgradeGunLv[client])
				}
			}
		}
	}
}

public Action:UGTimer(Handle:timer, any:client)
{
	EnaUG[client] = true
	UGBool[client] = false
	CreateTimer(20.0+2*UpgradeGunLv[client], UGTimer2, client)
	PrintToChat(client, "\x04Your Weapon \x03is loosing")
}

public Action:UGTimer2(Handle:timer, any:client)
{
	UGBool[client] = true
	PrintToChat(client, "\x04Infinite Ammo \x03Recharged!!")
}

public Action:BionSDelay(Handle:timer, any:client)
{
	ActiBioS[client] = false
	PrintToChat(client, "\x04Bionic Shield \x03is loosing")
	CreateTimer(2.0+2*BioShieldLv[client], ResetBionS, client)
}

public Action:ResetBionS(Handle:timer, any:client)
{
	EnaBioS[client] = true
	PrintToChat(client, "\x04Bionic Shield \x03Recharged!!")
}

public Action:SprinDelay(Handle:timer, any:client)
{
	RebuildStatus(client)
	PrintToChat(client, "\x04Your legs \x03's \x04Strength is gone!!")
	CreateTimer(6.0+2*SprintLv[client], ResetSprin, client)
}

public Action:ResetSprin(Handle:timer, any:client)
{
	EnaSprint[client] = true
	PrintToChat(client, "\x04Sprint \x03Recharged!!")
}

public Action:HealingAuraDelay(Handle:timer, any:client)
{
	EnaHA[client] = true
	PrintToChat(client, "\x04Making Ammo \x03Recharged!!")
}

public Action:ShowMyExp(client, args)
{
	ShowMyExpFunc(client)
	return Plugin_Handled
}

public Action:ShowMyExpFunc(clientId)
{
	PrintToChat(clientId, "\x03Your Exp: \x04%d", EXP[clientId])
	return Plugin_Handled
}

public Action:ResetEarthQuakeDelay(Handle:timer, any:client)
{
		EQBool[client] = true
		PrintToChat(client, "\x04EarthQuake \x03Recharged!!")
}

public Action:HealingDelayTimer(Handle:timer, any:client)
{
	HealingBool[client] = true
	PrintToChat(client, "\x04Healing \x03Recharged!!")
}

//?????
public bool:Create_PointHurt(client)
{
	new Entity;
	new String:sDamage[128];
	new String:sRadius[128];
	new String:sType[128];
	
	FloatToString(0.0, sDamage, sizeof(sDamage))
	if((50+Intelligence[client])*EarthQuakeLv[client] < 3001)
	{
		FloatToString((50.0+Intelligence[client])*EarthQuakeLv[client], sRadius, sizeof(sRadius))
	}
	else
	{
		FloatToString(4375.0, sRadius, sizeof(sRadius))
	}
	IntToString(64, sType, sizeof(sType))
	
	Entity = CreateEntityByName("point_hurt")
	
	if (!IsValidEdict(Entity)) return false
	DispatchKeyValue(Entity, "targetname", "Point_Hurt");
	DispatchKeyValue(Entity, "DamageRadius", sRadius)
	DispatchKeyValue(Entity, "Damage", sDamage)
	DispatchKeyValue(Entity, "DamageType", sType)
	
	TeleportEntity(Entity, NowLocation[client], NULL_VECTOR, NULL_VECTOR)
	DispatchSpawn(Entity)

	ActivateEntity(Entity)
	AcceptEntityInput(Entity, "Hurt")

	CreateTimer(0.1, DeleteEntity, Entity)
	
	return true
}

public Action:DeleteEntity(Handle:Timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		RemoveEdict(entity);
	}
}

//??? ?????..
public Shake_Screen(client, Float:Amplitude, Float:Duration, Float:Frequency)
{
	new Handle:Bfw;
	
	Bfw = StartMessageOne("Shake", client, 1);
	BfWriteByte(Bfw, 0);
	BfWriteFloat(Bfw, Amplitude);
	BfWriteFloat(Bfw, Duration);
	BfWriteFloat(Bfw, Frequency);

	EndMessage();
}

public Action:RevSuc(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(Reviver) == TEAM_SURVIVORS)
	{
		EXP[Reviver] += GetConVarInt(ReviveExp)
		RebuildStatus(Subject)
		PrintToChat(Reviver, "\x03you got EXP \x05%d \x03because you set up Companion", GetConVarInt(ReviveExp))
	}
}

public Action:DefUsed(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new UserID = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(UserID) == TEAM_SURVIVORS && !IsFakeClient(UserID))
	{
		EXP[UserID] += GetConVarInt(DefExp)
		RebuildStatus(Subject)
		PrintToChat(UserID, "\x03you got EXP \x05%d \x03because you revived Companion", GetConVarInt(DefExp))
	}
}

public OnGameFrame()
{
	for(new i = 0; i < MaxClients; i++)
	{
		if(BioWeaponBool[i])
		{
			GetWeapSpeed(Multi)
		}
		else if(AcolyteBool[i])
		{
			new Float:Multi2 = 1.0-(FWLv[i]*0.05)
			GetWeapSpeed(Multi2)
		}
	}
}

GetWeapSpeed(Float:MAS)
{
	if(WRQL)
	{
		decl ent, Float:time
		new Float:ETime = GetGameTime()
		
		for(new i = 0; i < WRQL; i++)
		{
			ent = WRQ[i]
			time = (GetEntDataFloat(ent, OffNPA) - ETime)*MAS
			SetEntDataFloat(ent, OffNPA, time + ETime, true)
		}
		
		WRQL = 0
	}
}

public Action:WeaponF(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"))
	if(BioWeaponBool[id] == true && !IsFakeClient(id))
	{
		new ent = GetEntDataEnt2(id, OffAW)
		
		if(ent != -1)
		{
			WRQ[WRQL++] = ent
		}
	}
	else if(AcolyteBool[id])
	{
		new ent = GetEntDataEnt2(id, OffAW)
		
		if(ent != -1)
		{
			WRQ[WRQL++] = ent
		}
	}
	
	if(EnaUG[id] == false && UGBool[id] == true && GetClientTeam(id) == TEAM_SURVIVORS)
	{
		new ent = GetEntDataEnt2(id, OffAW)
		if(ent != -1)
		{
			SetEntData(ent, C1, 10, 4, true)
			SetEntData(ent, C2, 0, 4, true)
		}
	}
}

public OnMapStart()
{
	for(new i = 0; i < MaxClients; i++)
	{
		if(GetClientTeam(i) == TEAM_SURVIVORS)
		{
			RebuildStatus(i)
		}
	}
}
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/









