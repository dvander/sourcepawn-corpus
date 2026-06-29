#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ff2_ams>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define MAXPLAYERARRAY MAXPLAYERS+1


#define PLUGIN_NAME 	"Freak Fortress 2: Cast Projectile"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Rage projectile ability with various settings"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"2"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL ""

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 *	Defines "rage_projectile_X"
 *	Cast a projectile with a various settings
 *	Compatible with ability management system
 *	
 *	@param char 		Projectile classname						
 *	@param float		Projectile velocity						
 *	@param char			Projectile Minimum Damage [Formula]
 *	@param char			Projectile Maximum Damage [Formula]						
 *	@param char			Projectile Overriden New Model [Path]	
 * 	@param int			Projectile Crit Value: -1:Random Crits, 1:Crit, 0:No Random Crits							
 *	
 */
bool AMS_PRJ[10][MAXPLAYERARRAY];				//Internal 	- AMS Trigger
char PRJ_EntityName[10][768];					//arg1		- Projectile Name
float PRJ_Velocity[10][MAXPLAYERARRAY];			//arg2		- Projectile Velocity
char PRJ_MinDamage[10][MAXPLAYERARRAY][1024]; 	//arg3		- Minimum Damage [Formula]
char PRJ_MaxDamage[10][MAXPLAYERARRAY][1024];	//arg4		- Maximum Damage [Formula]
char PRJ_NewModel[10][PLATFORM_MAX_PATH];		//arg5		- Override Projectile Model	
int	PRJ_Crit[10][MAXPLAYERARRAY];				//arg6		- Critz: -1=Use Defaults, 1=Crit, 0=No Random Crits

enum Operators
{
	Operator_None = 0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

public Plugin myinfo = 
{
	name 		= PLUGIN_NAME,
	author 		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESC,
	version 	= PLUGIN_VERSION,
	url			= PLUGIN_URL,
};

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]!=1 || version[1]<11)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");

	FF2_GetForkVersion(version);
	if(version[0]!=1 || version[1]<19)
		SetFailState("This subplugin depends on at least Unofficial FF2 v1.19.0");
	
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_active", Event_RoundStart, EventHookMode_PostNoCopy); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", Event_RoundEnd, EventHookMode_PostNoCopy); // for non-arena maps
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	if(FF2_GetRoundState() == 1)	// In case the plugin is loaded in late
		Event_RoundStart(view_as<Event>(INVALID_HANDLE), "plugin_lateload", false);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.3, Timer_PrepareHooks, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PrepareHooks(Handle timer)
{
	ClearEverything();
	MainBoss_PrepareAbilities();
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserIdx = GetEventInt(event, "userid");
	
	if(IsValidClient(GetClientOfUserId(UserIdx)))
	{
		CreateTimer(0.3, SummonedBoss_PrepareAbilities, UserIdx, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		FF2_LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
	}
}

public Action SummonedBoss_PrepareAbilities(Handle timer, int UserIdx)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return;

	int bossClientIdx = GetClientOfUserId(UserIdx);
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
	else
	{
		FF2_LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}

public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		FF2_LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
		return;
	}
	for(int bossClientIdx = 1; bossClientIdx <= MaxClients; bossClientIdx++)
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		if(bossIdx >= 0)
		{
			HookAbilities(bossIdx, bossClientIdx);
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
}

public void ClearEverything()
{	
	for(int Num = 0; Num < 10; Num++)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			AMS_PRJ[Num][i] = false;
		}
	}
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		char AbilityName[96], AbilityShort[96];
		for(int Num = 0; Num < 10; Num++)
		{
			Format(AbilityName, sizeof(AbilityName), "rage_projectile_%i", Num);
			if(FF2_HasAbility(bossIdx, this_plugin_name, AbilityName))
			{
				AMS_PRJ[Num][bossClientIdx] = AMS_IsSubabilityReady(bossIdx, this_plugin_name, AbilityName);
				if(AMS_PRJ[Num][bossClientIdx])
				{
					Format(AbilityShort, sizeof(AbilityShort), "PRJ%i", Num);
					AMS_InitSubability(bossIdx, bossClientIdx, this_plugin_name, AbilityName, AbilityShort);
				}
			}
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
		return Plugin_Continue; // Because some FF2 forks still allow RAGE to be activated when the round is over....
	
	int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));

	char AbilityName[96];
	for(int Num = 0; Num < 10; Num++)
	{
		Format(AbilityName, sizeof(AbilityName), "rage_projectile_%i", Num);
		if(!strcmp(ability_name, AbilityName))
		{
			if(AMS_PRJ[Num][bossClientIdx])
			{
				if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
				{
					AMS_PRJ[Num][bossClientIdx] = false;
				}
				else
				{
					return Plugin_Continue;
				}
			}
			if(!AMS_PRJ[Num][bossClientIdx])
			{
				CastSpell(bossIdx, bossClientIdx, ability_name, Num);
			}
		}
	}
	return Plugin_Continue;
}


public bool PRJ0_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ1_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ2_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ3_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ4_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ5_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ6_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ7_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ8_CanInvoke(int bossClientIdx)
{
	return true;
}

public bool PRJ9_CanInvoke(int bossClientIdx)
{
	return true;
}

public void PRJ0_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_0", 0);
}

public void PRJ1_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_1", 1);
}

public void PRJ2_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_2", 2);
}

public void PRJ3_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_3", 3);
}

public void PRJ4_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_4", 4);
}

public void PRJ5_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_5", 5);
}

public void PRJ6_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_6", 6);
}

public void PRJ7_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_7", 7);
}

public void PRJ8_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_8", 8);
}

public void PRJ9_Invoke(int bossClientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	CastSpell(bossIdx, bossClientIdx, "rage_projectile_9", 9);
}

public void CastSpell(int bossIdx, int bossClientIdx, const char[] ability_name, int Num)
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 1, PRJ_EntityName[Num], 768);
	PRJ_Velocity[Num][bossClientIdx] 	= FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, ability_name, 2, 1100.0);
	
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 3, PRJ_MinDamage[Num][bossClientIdx], 1024);
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 4, PRJ_MaxDamage[Num][bossClientIdx], 1024);
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, 5, PRJ_NewModel[Num], 1024);
	
	PRJ_Crit[Num][bossClientIdx] 		= FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 6, -1);
	
	if(AMS_PRJ[Num][bossClientIdx])
	{
		char AbilitySound[128], sound[PLATFORM_MAX_PATH];
		Format(AbilitySound, sizeof(AbilitySound), "sound_projectile_%i", Num);
		if(FF2_RandomSound(AbilitySound, sound, sizeof(sound), bossIdx))
		{
			EmitSoundToAll(sound, bossClientIdx);
			EmitSoundToAll(sound, bossClientIdx);	
		}
	}
	
	float flAng[3], flPos[3];
	GetClientEyeAngles(bossClientIdx, flAng);
	GetClientEyePosition(bossClientIdx, flPos);
	
	int iTeam = GetClientTeam(bossClientIdx);
	int iProjectile = CreateEntityByName(PRJ_EntityName[Num]);
	
	float flVel1[3], flVel2[3];
	GetAngleVectors(flAng, flVel2, NULL_VECTOR, NULL_VECTOR);
	
	flVel1[0] = flVel2[0] * PRJ_Velocity[Num][bossClientIdx];
	flVel1[1] = flVel2[1] * PRJ_Velocity[Num][bossClientIdx];
	flVel1[2] = flVel2[2] * PRJ_Velocity[Num][bossClientIdx];
	
	SetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity", bossClientIdx);
	if(!IsProjectileTypeSpell(PRJ_EntityName[Num]))
	{
		SetEntDataFloat(iProjectile, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4,
		GetRandomFloat(float(ParseFormula(bossIdx, PRJ_MinDamage[Num][bossClientIdx], 30, GetTotalPlayerCount())), 
		float(ParseFormula(bossIdx, PRJ_MaxDamage[Num][bossClientIdx], 110, GetTotalPlayerCount()))), true);
		
		int CritValue;
		
		if(PRJ_Crit[Num][bossClientIdx] == 1) CritValue = 1;
		else if(PRJ_Crit[Num][bossClientIdx] == 0) CritValue = 0;
		else CritValue = (GetRandomInt(0, 100) <= 3 ? 1 : 0);
			
		SetEntProp(iProjectile, Prop_Send, "m_bCritical", CritValue, 1);
	}
	SetEntProp(iProjectile, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(iProjectile, Prop_Send, "m_nSkin", (iTeam-2));
	

	if(!IsModelPrecached(PRJ_NewModel[Num]))
	{
		if(FileExists(PRJ_NewModel[Num], true))
		{
			PrecacheModel(PRJ_NewModel[Num]);
		}
		else
		{
			FF2_LogError("ERROR: Model file doesn't exist. %s:CastSpell()", this_plugin_name);
			return;
		}
	}
	SetEntityModel(iProjectile, PRJ_NewModel[Num]);
	
	TeleportEntity(iProjectile, flPos, flAng, NULL_VECTOR);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "TeamNum", -1, -1, 0);
	SetVariantInt(iTeam);
	AcceptEntityInput(iProjectile, "SetTeam", -1, -1, 0);
	
	DispatchSpawn(iProjectile);
	TeleportEntity(iProjectile, NULL_VECTOR, NULL_VECTOR, flVel1);
}

stock bool IsValidClient(int client)
{
	if(client <= 0 || client > MaxClients) return false;
	if(!IsClientInGame(client) || !IsClientConnected(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;		
}

stock bool IsProjectileTypeSpell(const char[] entity_name)
{
	if(StrContains(entity_name, "tf_projectile_spell", false) != -1 || !strcmp(entity_name, "tf_projectile_lightningorb")) return true;
	else return false;
}

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	//Borrowed from Batfoxkid
	char formula[1024], bossName[64];
	FF2_GetBossName(boss, bossName, sizeof(bossName), 0, 0);
	
	strcopy(formula, sizeof(formula), key);
	int size = 1;
	int matchingBrackets;
	for(int i; i <= strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	ArrayList sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	sumArray.Set(0, 0.0);
	_operator.Set(bracket, Operator_None);

	char character[2], value[16];
	for(int i; i <= strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':
			{
				continue; //Ignore whitespace
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket) != Operator_None)
				{
					LogError("[%s] %s's %s formula has an invalid operator at character %i", this_plugin_name, bossName, key, i+1);
					delete sumArray; delete _operator; return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[%s] %s's %s formula has an unbalanced parentheses at character %i", this_plugin_name, bossName, key, i+1);
					delete sumArray; delete _operator; return defaultValue;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
			}
			case '\0':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator); //End of formula
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':
			{
				Operate(sumArray, bracket, float(playing), _operator); //n and x denote player variables
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':_operator.Set(bracket, Operator_Add);
					case '-':_operator.Set(bracket, Operator_Subtract);
					case '*':_operator.Set(bracket, Operator_Multiply);
					case '/':_operator.Set(bracket, Operator_Divide);
					case '^':_operator.Set(bracket, Operator_Exponent);	
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;
	if(result <= 0)
	{
		LogError("[%s] %s has an invalid %s formula, using default health!", this_plugin_name, bossName, key);
		return defaultValue;
	}
	return RoundFloat(result);
}

stock void OperateString(ArrayList sumArray, int &bracket, char[] value, int size, ArrayList _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

stock void Operate(ArrayList sumArray, int &bracket, float value, ArrayList _operator)
{
	//Borrowed from Batfoxkid
	float sum = sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:sumArray.Set(bracket, sum + value);
		case Operator_Subtract:sumArray.Set(bracket, sum - value);
		case Operator_Multiply:sumArray.Set(bracket, sum * value);
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[%s] Detected a divide by 0!", this_plugin_name);
				bracket = 0;
				return;
			}
			sumArray.Set(bracket, sum/value);
		}
		case Operator_Exponent: sumArray.Set(bracket, Pow(sum, value));
		default: sumArray.Set(bracket, value);  //This means we're dealing with a constant
	}
	_operator.Set(bracket, Operator_None);
}

stock int GetTotalPlayerCount()
{
	int total;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			total++;
		}
	}
	return total;
}
