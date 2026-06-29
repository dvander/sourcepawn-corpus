#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define Version "1.1.0"

public Plugin myinfo =
{
	name = "Pills Side Effect",
	author = "Rayne",
	description = "Pill's SideEffect",
	version = Version,
	url = ""
};

ConVar PillHealMax;
int probabilityR;
int RandomSideEffectDamage;
ConVar x;
ConVar y;
ConVar SetProbability;
ConVar DieProbability;
int Die;

public void OnPluginStart ()
{
	//version
	CreateConVar("l4d2_Pill's_Side_Effect_Version", Version, "Pill's Side Effect Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	//Make Console command.
	PillHealMax = CreateConVar("PillHealMaxValue", "50", "Set Buffer Health. Default: 50");
	x = CreateConVar("SideEffectDamageMin", "1", "the minimun damage of SideEffect you will get");
	y = CreateConVar("SideEffectDamageMax", "30", "the maximum damage of sideEffect you will get");
	SetProbability = CreateConVar("SetProbabilitY", "300", "probability to cause sideEffect. default value equals 300, it mean probability of 30%. substitute betweent 1~1000");
	DieProbability = CreateConVar("SetDieProbability", "1000", "When the health become 0 or down the 0 because of SideEffect,you will die, not incapped by this probability. 1000 equals 10%.");

	//Event Trigger.
	HookEvent("pills_used", PillUse);

	//Change ConVars.
	HookConVarChange(PillHealMax, CVARChanged);

	//make CFG file.
	AutoExecConfig(true, "l4d2_Pills_Side_Effect");
}

//Change ConVars.

public void CVARChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateConVars();
}

void UpdateConVars()
{
	SetConVarInt(FindConVar("pain_pills_health_value"), GetConVarInt(PillHealMax));
}

//Event trigger. When you use pill, it will work.
public Action PillUse(Event event, char[] event_name, bool dontBroadcast)
{
	SideEffectDamage();
	Death();
	PillHealMaxChange();
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	if(probabilityR <= GetConVarInt(SetProbability))//if the SetProbability equlas 300, sideeffect will occur by probability of 30%
	{
		FakeClientCommand(target, "hurtme %d", RandomSideEffectDamage); //give side effect damage
		FakeClientCommand(target, "play player/survivor/voice/producer/fall02.wav"); //lol fun sound.
		PrintCenterText(target, "You got SideEffect of Pill!!!."); //make PrintCenterText
		int Health = GetClientHealth(target);
		if(Health - GetConVarInt(y) < 0)
		{
			if(Die < GetConVarInt(DieProbability)) 
			{
				FakeClientCommand(target, "kill");
			}
			else
			{
				SetEntProp(target, Prop_Send, "m_Incapacitated", 0);
			}
		}
	}
}

//Set the SideEffect Damamge
//And Set the variable to occur the SideEffect.
public Action SideEffectDamage()
{
	static int NumPrinted = 0;
	if(NumPrinted++ <= 2)
	{
		RandomSideEffectDamage = GetRandomInt(GetConVarInt(x), GetConVarInt(y));
		probabilityR = GetRandomInt (1, 1000);
		NumPrinted = 0;
	}
	return Plugin_Continue;
}

//Set variable to make people die.
public Action Death()
{
	static int NumPrinted = 0;
	if(NumPrinted++ <= 2)
	{
		Die = GetRandomInt(1, 10000);
		NumPrinted = 0;
	}
}

//when the SideEffect takes place, the pills do not give you any buffer health
public Action PillHealMaxChange()
{
	if(probabilityR <= GetConVarInt(SetProbability))
	{
		SetConVarInt(FindConVar("pain_pills_health_value"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("pain_pills_health_value"), GetConVarInt(PillHealMax));
	}
}
