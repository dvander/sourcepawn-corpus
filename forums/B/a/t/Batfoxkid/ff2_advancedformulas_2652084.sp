/*
	Advanced Formulas Pack:

	special_chargeformula
	special_healthformula
	special_lifeformula
	special_rageformula
*/
#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

enum Operators
{
	Operator_None = 0,	// None, for checking valid brackets
	Operator_Add,		// +
	Operator_Subtract,	// -
	Operator_Multiply,	// *
	Operator_Divide,	// /
	Operator_Exponent,	// ^
};

static const char FormulaAbilities[][] =
{
	"special_chargeformula",	// Charge
	"special_healthformula",	// Health
	"special_lifeformula",		// Lives
	"special_rageformula"		// Ragedamage
};

public Plugin myinfo=
{
	name		=	"Freak Fortress 2: Advanced Formulas",
	author		=	"Batfoxkid",
	description	=	"FF2: Allows more advanced formulas for bosses",
	version		=	"1.0"
};

public void OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundSetup);
	HookEvent("arena_round_start", OnRoundStart);
}

public void FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
}

public Action OnRoundSetup(Handle event, const char[] name, bool dontBroadcast)
{
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;

	CreateTimer(9.3, SetStuffTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)	// Needed for first boss round
{
	if(!FF2_IsFF2Enabled())
		return Plugin_Continue;

	CreateTimer(0.3, SetStuffTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action SetStuffTimer(Handle timer)
{
	char formula[768], ability[64];
	int boss, players;
	float total;
	for(int client=1; client<=MaxClients; client++)	// Check all clients
	{
		if(!IsClientConnected(client))
			continue;

		boss = FF2_GetBossIndex(client);	// Check if is a boss
		if(boss >= 0)
		{
			for(int formulas; formulas<sizeof(FormulaAbilities); formulas++)	// Loop through all formulas
			{
				strcopy(ability, sizeof(ability), FormulaAbilities[formulas]);
		 		total = 0.0;
				if(FF2_HasAbility(boss, this_plugin_name, ability))	// Check if the boss has the ability
				{
					Debug("AF: Found %s", ability);
					for(int class=1; class<=10; class++)	// Loop through each class + all class
					{
						players = 0;
						FF2_GetAbilityArgumentString(boss, this_plugin_name, ability, class, formula, sizeof(formula));

						if(!strlen(formula))	// If the arg is undefined
							continue;

						for(int clients=1; clients<=MaxClients; clients++)	// Check how many players are in-game
						{
							if(IsClientInGame(clients))
							{
								if(GetClientTeam(clients) > view_as<int>(TFTeam_Spectator))	// (Intentionally checks both teams)
								{
									if(view_as<int>(TF2_GetPlayerClass(clients))==class || class>9)	// Check if there that class (Unless were checking all-class)
										players++;
								}
							}
						}

						total += ParseFormula(boss, formula, players, ability, class);	// Add to the total
						//Debug("%N | %s | %i | %i", client, ability, class, players);
					}

					switch(formulas)	// Set the total to the boss
					{
						case 0:	// Charge
						{
							FF2_SetBossCharge(boss, FF2_GetAbilityArgument(boss, this_plugin_name, ability, 0), total);
							Debug("%N's slot %i is set to %.3f", client, FF2_GetAbilityArgument(boss, this_plugin_name, ability, 0), total);
						}
						case 1:	// Health
						{
							FF2_SetBossMaxHealth(boss, RoundFloat(total));
							FF2_SetBossHealth(boss, RoundFloat(total));
							Debug("%N's health is set to %i", client, RoundFloat(total));
						}
						case 2:	// Lives
						{
							FF2_SetBossMaxLives(boss, RoundFloat(total));
							FF2_SetBossLives(boss, RoundFloat(total));
							FF2_SetBossHealth(boss, FF2_GetBossMaxHealth(boss)*RoundFloat(total));
							Debug("%N's lives is set to %i", client, RoundFloat(total));
						}
						case 3:	// Ragedamage
						{
							FF2_SetBossRageDamage(boss, RoundFloat(total));
							Debug("%N's ragedamage is set to %i", client, RoundFloat(total));
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

/*
	From Freak Fortress 2 itself
*/

stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum = GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[Boss] Detected a divide by 0 for ff2_advancedformulas!");
				bracket = 0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);	//This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))	//Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

public float ParseFormula(int boss, const char[] key, int playing, const char[] formulaName, int formulaArg)
{
	char formula[1024], bossName[64];
	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
	strcopy(formula, sizeof(formula), key);
	int size = 1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)	//Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i] == '(')
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
		else if(formula[i] == ')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray = CreateArray(_, size);
	Handle _operator = CreateArray(_, size);
	int bracket;	//Each bracket denotes a separate sum (within parentheses). At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0] = formula[i];	//Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':	//Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;	//We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);

				if(GetArrayCell(_operator, bracket) != Operator_None)	//Something like (5*)
				{
					LogError("[Boss] %s's %s formula for %s at arg%i has an invalid operator at character %i", bossName, key, formulaName, formulaArg, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return 0.0;
				}

				if(--bracket < 0)	//Something like (5))
				{
					LogError("[Boss] %s's %s formula for %s at arg%i has an unbalanced parentheses at character %i", bossName, key, formulaName, formulaArg, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return 0.0;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':	//End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);	//Constant? Just add it to the current value
			}
			case 'n', 'x':	//n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);

				switch(character[0])
				{
					case '+':
						SetArrayCell(_operator, bracket, Operator_Add);

					case '-':
						SetArrayCell(_operator, bracket, Operator_Subtract);

					case '*':
						SetArrayCell(_operator, bracket, Operator_Multiply);

					case '/':
						SetArrayCell(_operator, bracket, Operator_Divide);

					case '^':
						SetArrayCell(_operator, bracket, Operator_Exponent);
				}
			}
		}
	}

	float result = GetArrayCell(sumArray, 0);
	CloseHandle(sumArray);
	CloseHandle(_operator);
	return result;
}

#file "FF2 Subplugin: Advanced Formulas"