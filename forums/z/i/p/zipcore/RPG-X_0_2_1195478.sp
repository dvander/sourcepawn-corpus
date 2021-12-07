//RPG-X by .#Zipcore

#include <sourcemod>
#include <sdktools>

#define Version "0.2"
#define Author ".#Zipcore"
#define Name "RPG-X"
#define Description "Roleplay Game Mode Extreme for L4D2"
#define URL "www.iskult.net"
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3
#define ZOMBIECLASS_TANK 8
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD

public Plugin:myinfo=
{
	name = Name,
	author = Author,
	description = Description,
	version = Version,
	url = URL
};

//Global
new Handle:LvUpSP
new Handle:LvUpExp
new Handle:LvMax
new Handle:Lv2Exp

new Handle:AgiSP
new Handle:StrSP
new Handle:EndSP
new Handle:IntSP
new Handle:HealthSP

new Handle:JocExp
new Handle:HunExp
new Handle:ChaExp
new Handle:SmoExp
new Handle:SpiExp
new Handle:BooExp
new Handle:TanExp
new Handle:WitExp
new Handle:ComExp
new Handle:ReviveExp
new Handle:DefExp

new ZC
new LegValue

//Player
new StatusPoint[MAXPLAYERS+1]
new Lv[MAXPLAYERS+1]
new EXP[MAXPLAYERS+1]
new Str[MAXPLAYERS+1]
new Agi[MAXPLAYERS+1]
new Endurance[MAXPLAYERS+1]
new Intelligence[MAXPLAYERS+1]
new Health[MAXPLAYERS+1]

new Handle:CheckExp[MAXPLAYERS+1]
new ISCONFIRM[MAXPLAYERS+1]
new JD[MAXPLAYERS+1] = 0

public OnPluginStart()
{
	CreateConVar(Name, Version, Description, CVAR_FLAGS)
	
	RegConsoleCmd("statusconfirm", ConfirmChooseMenu)
	RegConsoleCmd("usestatus", StatusChooseMenu)
	RegConsoleCmd("myexp", ShowMyExp)
	RegConsoleCmd("myinfo", MyInfo)
	RegConsoleCmd("rpgmenu", RPG_Menu)
	
	RegAdminCmd("sm_giveexp",Command_GiveExp,ADMFLAG_KICK,"sm_giveexp [#userid|name] [number of points]")
	RegAdminCmd("sm_givelv",Command_GiveLevel,ADMFLAG_KICK,"sm_givelv [#userid|name] [number of points]")
	RegAdminCmd("sm_givehp",Command_GiveHP,ADMFLAG_KICK,"sm_givehp [#userid|name] [number of points]")
	RegAdminCmd("sm_givestr",Command_GiveStr,ADMFLAG_KICK,"sm_givestr [#userid|name] [number of points]")
	RegAdminCmd("sm_giveagi",Command_GiveAgi,ADMFLAG_KICK,"sm_giveagi [#userid|name] [number of points]")
	RegAdminCmd("sm_giveint",Command_GiveInt,ADMFLAG_KICK,"sm_giveint [#userid|name] [number of points]")
	RegAdminCmd("sm_givepoints",Command_GivePoints,ADMFLAG_KICK,"sm_givepoints [#userid|name] [number of points]")

	JocExp = CreateConVar("sm_JocExp","500","EXP that Jockey gives", FCVAR_PLUGIN)
	HunExp = CreateConVar("sm_HunExp","700", "EXP that Hunter gives", FCVAR_PLUGIN)
	ChaExp = CreateConVar("sm_ChaExp","850","EXP that Charger gives", FCVAR_PLUGIN)
	SmoExp = CreateConVar("sm_SmoExp","650","EXP that Smoker gives", FCVAR_PLUGIN)
	SpiExp = CreateConVar("sm_SpiExp","670","EXP that Spitter gives", FCVAR_PLUGIN)
	BooExp = CreateConVar("sm_BooExp","620","EXP that Boomer gives", FCVAR_PLUGIN)
	TanExp = CreateConVar("sm_TanExp","5000","EXP that Tank gives", FCVAR_PLUGIN)
	WitExp = CreateConVar("sm_WitExp","2000","EXP that Witch gives", FCVAR_PLUGIN)
	ComExp = CreateConVar("sm_ComExp","250","EXP that Common Zombie gives", FCVAR_PLUGIN)
	ReviveExp = CreateConVar("sm_ReviveExp","750","EXP when you succeed Setting someone up", FCVAR_PLUGIN) //Points given when u revive someone with first aid kit
	DefExp = CreateConVar("sm_DefExp","1000","EXP when you succeed to revive someone with defibrillator", FCVAR_PLUGIN) //Points given when u revive someoe with defibrillator
	
	LvUpExp = CreateConVar("sm_LvUpExp","1000","EXP req. for level up", FCVAR_PLUGIN)
	LvMax = CreateConVar("sm_LvMax","100","Max level.", FCVAR_PLUGIN)
	LvUpSP = CreateConVar("sm_LvUpSP","10","Status Points given on level's up", FCVAR_PLUGIN)
	Lv2Exp = CreateConVar("sm_Lv2Exp","1","0=off 1=Give Players SP for each level last round/connect", FCVAR_PLUGIN)
	
	AgiSP = CreateConVar("sm_AgiSP","5","SP req. for Agi up", FCVAR_PLUGIN)
	StrSP = CreateConVar("sm_StrSP","3","SP req. for Str up", FCVAR_PLUGIN)
	EndSP = CreateConVar("sm_EndSP","3","SP req. for End up", FCVAR_PLUGIN)
	IntSP = CreateConVar("sm_IntSP","5","SP req. for Int up", FCVAR_PLUGIN)
	HealthSP = CreateConVar("sm_HealthSP","10","SP req. for Health up", FCVAR_PLUGIN)
	
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
	
	ZC = FindSendPropInfo("CTerrorPlayer", "m_zombieClass")
	
	LegValue = FindSendPropInfo("CTerrorPlayer", "m_flLaggedMovementValue")
	AutoExecConfig(true, "RPG-X")
}

public Action:PFS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	CheckExp[target] = CreateTimer(1.0, CEOP, target, TIMER_REPEAT)
	if(!IsFakeClient(target))
	{
		PrintToChat(target, "\x03You are using \x04RPG-X \x05by .#Zipcore")
		PrintToChat(target, "\x04Level & Skill reset each round!!!")
	}
}

//Level-UP
public Action:CEOP(Handle:timer, any:target)
{
	if(EXP[target] > GetConVarInt(LvUpExp) && Lv[target] < GetConVarInt(LvMax))
	{
		Lv[target] += 1
		StatusPoint[target] += GetConVarInt(LvUpSP)
		StatusPoint[target] += Intelligence[target]
		EXP[target] -= GetConVarInt(LvUpExp)
		PrintToChat(target, "\x04Your level has increased! \x03Type \x05!rpgmenu \x03in CHAT for use!")
	}
}

public Action:PK(Handle:event, String:event_name[], bool:dontBroadcast)	
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	new deadbody = GetClientOfUserId(GetEventInt(event, "userid"))
	new ZClass = GetEntData(deadbody, ZC)
	
	if(!IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVORS)
	{
		//Smoker
		if(ZClass == 1)
		{
			EXP[killer] += GetConVarInt(SmoExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Smoker", GetConVarInt(SmoExp))
		}
	
		//Boomer
		if(ZClass == 2)
		{
			EXP[killer] += GetConVarInt(BooExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Boomer", GetConVarInt(BooExp))
		}
		
		// Hunter
		if(ZClass == 3)
		{
			EXP[killer] += GetConVarInt(HunExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Hunter", GetConVarInt(HunExp))
		}
	
		// Spitter
		if(ZClass == 4)
		{
			EXP[killer] += GetConVarInt(SpiExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Spitter", GetConVarInt(SpiExp))
		}
		
		// Jockey
		if(ZClass == 5)
		{
			EXP[killer] += GetConVarInt(JocExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Jockey", GetConVarInt(JocExp))
		}
		
		// Charger
		if(ZClass == 6)
		{
			EXP[killer] += GetConVarInt(ChaExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Charger", GetConVarInt(ChaExp))
		}
		
		// Tank
		if(IsPlayerTank(deadbody))
		{
			EXP[killer] += GetConVarInt(TanExp)
			PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Tank", GetConVarInt(TanExp))
		}
	}
}

public Action:RevSuc(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new Reviver = GetClientOfUserId(GetEventInt(event, "userid"))
	new Subject = GetClientOfUserId(GetEventInt(event, "subject"))
	if(GetClientTeam(Reviver) == TEAM_SURVIVORS)
	{
		EXP[Reviver] += GetConVarInt(ReviveExp)
		RebuildStatus(Subject)
		PrintToChat(Reviver, "\x03You got \x04%d\x03 EXP because you revived a player with first aid kit.", GetConVarInt(ReviveExp))
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
		PrintToChat(UserID, "\x03You got \x04%d\x03 EXP because you revived a player with defibrillator", GetConVarInt(DefExp))
	}
}

// Witch kill
public Action:WK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "userid"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(WitExp)
		PrintToChat(killer, "\x03You got EXP as much as \x04%d \x03from \x05Witch", GetConVarInt(WitExp))
	}
}

// Infected Kill
public Action:IK(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"))
	if(GetClientTeam(killer) == TEAM_SURVIVORS && !IsFakeClient(killer))
	{
		EXP[killer] += GetConVarInt(ComExp)
	}
}

// Player Hurt
public Action:PH(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new hurted = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new dmg = GetEventInt(event, "dmg_health")
	
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
			new Float:RefFloat = (Endurance[hurted]-50)*0.01
			new RefDecHealth = RoundToNearest(dmg*RefFloat)
			new RefHealth = GetClientHealth(attacker)
			SetEndReflect(attacker, RefHealth, RefDecHealth)
		}
	}
	
	if(GetClientTeam(hurted) == TEAM_INFECTED)
	{
		new StrHealth = GetEventInt(event, "health")
		new Float:StrFloat = Str[attacker]*0.02
		new StrRedHealth = RoundToNearest(dmg*StrFloat)
		SetStrDamage(hurted, StrHealth, StrRedHealth)
	}
}
SetEndurance(client, health, endurance)
{
	SetEntityHealth(client, health+endurance)
}
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
			case 0:
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 0
			}
			
			case 1:
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 1
			}
			
			case 2:
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 2
			}
			
			case 3:
			{
				FakeClientCommand(client, "statusconfirm")
				ISCONFIRM[client] = 3
			}
			
			case 4:
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
		case 0:
		{
			cost = GetConVarInt(StrSP)
		}
		
		case 1:
		{
			cost = GetConVarInt(AgiSP)
		}
		
		case 2:
		{
			cost = GetConVarInt(HealthSP)
		}
		
		case 3:
		{
			cost = GetConVarInt(EndSP)
		}
		
		case 4:
		{
			cost = GetConVarInt(IntSP)
		}
	}
	new Handle:menu = CreateMenu(StatusConfirmHandler)
	SetMenuTitle(menu, "Required Points: %d", cost)
	AddMenuItem(menu, "option1", "Yes")
	AddMenuItem(menu, "option2", "No")
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
				case 0: //Str
				{
					if(StatusPoint[client] > GetConVarInt(StrSP)-1)
					{
						Str[client] += 1
						StatusPoint[client] -= GetConVarInt(StrSP)
						PrintToChat(client, "\x05Strength\x03 has become \x04%d\x03. You give \x04%d \x03percent more \x05damage.", Str[client], Str[client]*2)
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04%d \x05SP \x03left.", StatusPoint[client])
						}
					}
					else
					{
						PrintToChat(client, "\x03Not enough \x05SP \x03remain. You need \x04%d \x03more.", (GetConVarInt(StrSP)-StatusPoint[client]))
					}
				}
				
				case 1: //Agi
				{
					if(StatusPoint[client] > GetConVarInt(AgiSP)-1)
					{
						Agi[client] += 1
						StatusPoint[client] -= GetConVarInt(AgiSP)
						PrintToChat(client, "\x05Agility \x03has become \x04%d\x03. Move \x05Speed \x03and \x05Jumping height \x03are increased by \x04%d \x03Percent", Agi[client], Agi[client])
						CreateTimer(0.1, StatusUp, client)
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04%d \x05SP \x03left.", StatusPoint[client])
						}
					}
					else
					{
						PrintToChat(client, "\x03Not enough \x05SP \x03remain. You need \x04%d \x03more.", (GetConVarInt(AgiSP)-StatusPoint[client]))
					}
				}
				
				case 2: //Health
				{
					if(StatusPoint[client] > GetConVarInt(HealthSP)-1)
					{
						Health[client] += 1
						StatusPoint[client] -= GetConVarInt(HealthSP)
						PrintToChat(client, "\x05Max Health \x03has increased up to\x04 %d\x03.", (100+10*Health[client]))
						new HealthForStatus = GetClientHealth(client)
						CreateTimer(0.1, StatusUp, client)
						if(JD[client] == 0 || JD[client] == 1 || JD[client] == 3)
						{
							SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
						}
						if(JD[client] == 2)
						{
							SetEntData(client, FindDataMapOffs(client, "m_iHealth"), HealthForStatus+10, 4, true)
						}
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04%d \x05SP \x03left.", StatusPoint[client])
						}
					}
					else
					{
						PrintToChat(client, "\x03Not enough \x05SP \x03remain. You need \x04%d \x03more.", (GetConVarInt(HealthSP)-StatusPoint[client]))
					}
				}
				
				case 3: //End
				{
					if(StatusPoint[client] > GetConVarInt(EndSP)-1)
					{
						Endurance[client] += 1
						StatusPoint[client] -= GetConVarInt(EndSP)
						if(Endurance[client] < 51)
						{
							PrintToChat(client, "\x05Endurance\x03 has increased up to \x04%d. \x03You get \x04%d \x03Percent less \x05Damage", Endurance[client], Endurance[client])
						}
						CreateTimer(0.1, StatusUp, client)
						if(Endurance[client] > 50)
						{
							PrintToChat(client, "\x03Added Ability: \x05Damage Reflect\x03. Reflection Rate: \x04%d \x03Percent.", (Endurance[client]-50))
						}
						if(StatusPoint[client] > 0)
						{
							StatusChooseMenuFunc(client)
							PrintToChat(client, "\x03You have \x04%d \x05SP \x03left.", StatusPoint[client])
						}
					}
					else
					{
						PrintToChat(client, "\x03Not enough \x05SP \x03remain. You need \x04%d \x03more.", (GetConVarInt(EndSP)-StatusPoint[client]))
					}
				}
				
				case 4: //Int
				{
					if(Lv[client] > Intelligence[client])
					{
						if(StatusPoint[client] > GetConVarInt(IntSP)-1)
						{
							Intelligence[client] += 1
							StatusPoint[client] -= GetConVarInt(IntSP)
							PrintToChat(client, "\x05Intelligence \x03has increased up to \x04%d. \x03From now on you'll get \x04%d \x05SP \x03when Levelup.", Intelligence[client], (Intelligence[client]+GetConVarInt(LvUpSP)))
							CreateTimer(0.1, StatusUp, client)
							if(StatusPoint[client] > 0)
							{
								StatusChooseMenuFunc(client)
								PrintToChat(client, "\x03You have \x04%d \x05SP \x03left.", StatusPoint[client])
							}
						}
						else
						{
							PrintToChat(client, "\x03Not enough \x05SP \x03remain. You need \x04%d \x03more.", (GetConVarInt(IntSP)-StatusPoint[client]))
						}
					}
					else
					{
					PrintToChat(client, "\x03Your \x05level(\x04%d\x05) \x03must be higher than your \x05intelligence(\x04%d\x05)\x03.", Lv[client], Intelligence[client])
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
	SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100+(10*Health[client]), 4, true)
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
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iMaxHealth"), 100+(10*Health[HealSucTarget]), 4, true)
			SetEntData(HealSucTarget, FindDataMapOffs(HealSucTarget, "m_iHealth"), 100+(10*Health[HealSucTarget]), 4, true)
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

//Reset on Player Spawn
public Action:PlayerS(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"))
	if(Lv[target] > 0 && GetClientTeam(target) == TEAM_SURVIVORS && !IsFakeClient(target))
	{
		new LvLastRound = Lv[target]
		if(GetConVarInt(Lv2Exp) == 1)
		{
			StatusPoint[target] = Lv[target]
		}
		else
		{
			StatusPoint[target] = 0
		}
		Lv[target] = 0
		EXP[target] = 0
		Str[target] = 0
		Agi[target] = 0
		Intelligence[target] = 0
		Health[target] = 0
		Endurance[target] = 0
		
		RebuildStatus(target)
		
		PrintToChat(target, "\x03Your last level was \x04%d\x03, so many \x05SP\x03 are credited to this round.", LvLastRound)
	}
}

//Reset on Round Start
public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	for(new i = 0; i < MaxClients; i++)
	{
		if(GetClientTeam(i) == TEAM_SURVIVORS && !IsFakeClient(i))
		{
			new LvLastRound = Lv[i]
			if(GetConVarInt(Lv2Exp) == 1)
			{
			StatusPoint[i] = Lv[i]
			}
			else
			{
				StatusPoint[i] = 0
			}
			Lv[i] = 0
			EXP[i] = 0
			Str[i] = 0
			Agi[i] = 0
			Intelligence[i] = 0
			Health[i] = 0
			Endurance[i] = 0
			RebuildStatus(i)	
			PrintToChat(i, "\x03Your last level was \x04%d\x03, so many \x05SP\x03 are credited to this round.", LvLastRound)
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
			case 0:
			{
				PrintToChat(client, "\x03Your Level is \x04%d.\x03", Lv[client])
				PrintToChat(client, "\x03Strength: \x04%d.\x03, Agility: \x04%d.\x03, Health: \x04%d.\x03, End: \x04%d.\x03, Int: \x04%d.\x03", Str[client], Agi[client], Health[client], Endurance[client], Intelligence[client])
			}
		}
	}
}

//RPG Menu
public Action:RPG_Menu(client,args)
{
	RPG_MenuFunc(client)

	return Plugin_Handled
}

//RPG Menu Func
public Action:RPG_MenuFunc(clientId) 
{
	new Handle:menu = CreateMenu(RPG_MenuHandler)
	SetMenuTitle(menu, "Level: %d | EXP: %d",Lv[clientId],EXP[clientId])
	
	AddMenuItem(menu, "option1", "Use Status Points")
	AddMenuItem(menu, "option2", "Identify myself")
	
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
			case 0:
			{
				FakeClientCommand(client,"usestatus")
			}
			case 1:
			{
				FakeClientCommand(client,"myinfo")
			}
		}
	}
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

bool:IsPlayerTank(client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	else
	return false;
}

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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			EXP[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			if(Lv[targetclient] + StringToInt(arg2) < (GetConVarInt(LvMax)+1))
			{
				Lv[targetclient] += StringToInt(arg2);
				StatusPoint[targetclient] += GetConVarInt(LvUpSP)*StringToInt(arg2)
			}
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveHP(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x04Command: sm_giveehp [Name] [Amount of HPLv to give*10]");
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			Health[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveStr(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Command: sm_giveehp [Name] [Amount of Str to give]");
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			Str[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveAgi(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Command: sm_giveehp [Name] [Amount of Agi to give]");
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			Agi[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GiveInt(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Command: sm_giveehp [Name] [Amount of Intelligence to give]");
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			Intelligence[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action:Command_GivePoints(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Command: sm_giveehp [Name] [Amount of StatusPoints to give]");
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
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) > 0)
	{
		for (new i = 0; i < target_count; i++)
		{
			targetclient = target_list[i];
			StatusPoint[targetclient] += StringToInt(arg2);
		}
		CreateTimer(0.1, StatusUp, client)
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}
	
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
