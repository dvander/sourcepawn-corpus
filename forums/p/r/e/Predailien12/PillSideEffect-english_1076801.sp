#include <sourcemod>
#include <sdktools>
#define Version "1.1.0"

public Plugin:myinfo =
{
	name = "Pill's Side Effect",
	author = "Rayne",
	description = "Pill's SideEffect",
	version = Version,
	url = ""
};

new Handle:PillHealMax
new probabilityR
new RandomSideEffectDamage
new Handle:x
new Handle:y
new Handle:SetProbability
new Handle:DieProbability
new Die

public OnPluginStart ()
{
	//version
	CreateConVar("l4d2_Pill's_Side_Effect_Version", Version, "Pill's Side Effect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD)
	
	//Make Console command.
	PillHealMax = CreateConVar("PillHealMaxValue","50","Set Buffer Health. Default: 50", FCVAR_PLUGIN)
	x = CreateConVar("SideEffectDamageMin","1","the minimun damage of SideEffect you will get", FCVAR_PLUGIN)
	y = CreateConVar("SideEffectDamageMax","30","the maximum damage of sideEffect you will get", FCVAR_PLUGIN)
	SetProbability = CreateConVar("SetProbabilitY","300","probability to cause sideEffect. default value equals 300, it mean probability of 30%. substitute betweent 1~1000", FCVAR_PLUGIN)
	DieProbability = CreateConVar("SetDieProbability","1000","When the health become 0 or down the 0 because of SideEffect,you will die, not incapped by this probability. 1000 equals 10%.", FCVAR_PLUGIN)
	
	//Timer.
	CreateTimer (0.01, SideEffectDamage, _, TIMER_REPEAT)
	CreateTimer (0.01, Death, _, TIMER_REPEAT)
	CreateTimer (0.01, PillHealMaxChange, _, TIMER_REPEAT)
	
	//Event Trigger.
	HookEvent("pills_used", PillUse)
	
	//Change ConVars.
	HookConVarChange(PillHealMax, CVARChanged)
	
	//make CFG file.
	AutoExecConfig(true, "l4d2_Pill's Side Effect")
}

//Change ConVars.

public CVARChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UpdateConVars()
}

UpdateConVars()
{
	SetConVarInt(FindConVar("pain_pills_health_value"), GetConVarInt(PillHealMax))
}

//Event trigger. When you use pill, it will work.

public Action:PillUse(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if(probabilityR <= GetConVarInt(SetProbability))//if the SetProbability equlas 300, sideeffect will occur by probability of 30%
	{
		ClientCommand(target, "hurtme %d", RandomSideEffectDamage) //give side effect damage
		ClientCommand(target, "play player/survivor/voice/producer/fall02.wav") //lol fun sound.
		PrintCenterText(target, "You got SideEffect of Pill!!!.") //make PrintCenterText
		new Health = GetClientHealth(target)
		if(Health - GetConVarInt(y) < 0) 
		{
			if(Die < GetConVarInt(DieProbability)) 
			{
				ClientCommand(target, "kill")
			}
			else
			{
				SetEntProp(target, Prop_Send, "m_Incapacitated", 0)
			}
		}
	}
}
	
//Set the SideEffect Damamge
//And Set the variable to occur the SideEffect.

public Action:SideEffectDamage(Handle:timer, any:client)
{
	static NumPrinted = 0;
	if(NumPrinted++ <= 2)
	{
			RandomSideEffectDamage = GetRandomInt(GetConVarInt(x), GetConVarInt(y))
			probabilityR = GetRandomInt (1, 1000)
			NumPrinted = 0
	}
	return Plugin_Continue
}

//Set variable to make people die.

public Action:Death(Handle:timer)
{
	static NumPrinted = 0;
	if(NumPrinted++ <= 2)
	{
			Die = GetRandomInt(1, 10000)
			NumPrinted = 0
	}
}

//when the SideEffect takes place, the pills do not give you any buffer health

public Action:PillHealMaxChange(Handle:timer)
{
	if(probabilityR <= GetConVarInt(SetProbability))
	{
		SetConVarInt(FindConVar("pain_pills_health_value"), 0)
	}
	else
	{
		SetConVarInt(FindConVar("pain_pills_health_value"), GetConVarInt(PillHealMax))
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg949\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset129 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
