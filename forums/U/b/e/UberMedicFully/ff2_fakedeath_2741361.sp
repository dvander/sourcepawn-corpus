#pragma semicolon 1

#include <tf2_stocks>
#include <tf2items>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

#define PLUGIN_NAME 	"Freak Fortress 2: Fake Death"
#define PLUGIN_AUTHOR 	"J0BL3SS"
#define PLUGIN_DESC 	"Pre nerf dead ringer :D"

#define MAJOR_REVISION 	"1"
#define MINOR_REVISION 	"0"
#define STABLE_REVISION "0"
#define PLUGIN_VERSION 	MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PLUGIN_URL "www.skyregiontr.com"

#define MAXPLAYERARRAY MAXPLAYERS+1

/*
 *	Variables "fake_death"
 */
#define FAKE "fake_death"
int FAKE_Repeat[MAXPLAYERARRAY];		// arg1
float FAKE_Chance[MAXPLAYERARRAY];		// arg2
char FAKE_Health[MAXPLAYERARRAY][1024];	// arg3

int FAKE_RepeatTimes[MAXPLAYERARRAY];	// internal
char DamageList[MAXPLAYERARRAY][768];	// internal
Handle FakeHud, FakeHud2;				// internal

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
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("teamplay_round_active", Event_RoundStart); // for non-arena maps
	
	HookEvent("arena_win_panel", Event_RoundEnd);
	HookEvent("teamplay_round_win", Event_RoundEnd); // for non-arena maps
	
	FakeHud = CreateHudSynchronizer();
	FakeHud2 = CreateHudSynchronizer();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearEverything();
	
	MainBoss_PrepareAbilities();
	CreateTimer(1.0, TimerHookSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action TimerHookSpawn(Handle timer)
{
	HookEvent("player_spawn", Event_PlayerSpawn);
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
		LogError("ERROR: Invalid client index. %s:Event_PlayerSpawn()", this_plugin_name);
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
		LogError("ERROR: Unable to find respawned player. %s:SummonedBoss_PrepareAbilities()", this_plugin_name);
	}
}


public void MainBoss_PrepareAbilities()
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState() != 1)
	{
		LogError("ERROR: Abilitypack called when round is over or when gamemode is not FF2. %s:MainBoss_PrepareAbilities()", this_plugin_name);
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
	for(int i =1; i<= MaxClients; i++)
	{
		SDKUnhook(i, SDKHook_OnTakeDamage, FakeDeath_NoDamage);
		SDKUnhook(i, SDKHook_OnTakeDamageAlive, HealthCheck_OnTakeDamageAlive);
		
		FAKE_RepeatTimes[i] = 0;

	}
	
	/*
	if(FakeHud != INVALID_HANDLE)
		CloseHandle(FakeHud);
	if(FakeHud2 != INVALID_HANDLE)
		CloseHandle(FakeHud2);
	*/
}

public void HookAbilities(int bossIdx, int bossClientIdx)
{
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, FAKE))
		{
			FAKE_Repeat[bossClientIdx] = FF2_GetAbilityArgument(bossIdx, this_plugin_name, FAKE, 1, 1);
			FAKE_Chance[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FAKE, 2, 100.0);
			//FAKE_Health[bossClientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, FAKE, 3, 1.0);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, FAKE, 3, FAKE_Health[bossClientIdx], 1024);
				
			if(FF2_GetBossMaxLives(bossIdx) == 1 || FF2_GetBossLives(bossIdx) == 1)	// if boss has 1 live, hook the healthchecks
			{
				SDKHook(bossClientIdx, SDKHook_OnTakeDamageAlive, HealthCheck_OnTakeDamageAlive);
			}	
		}
	}		
}

public Action HealthCheck_OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(IsValidClient(victim) && IsValidClient(attacker) && victim != attacker)
	{
		int bossIdx = FF2_GetBossIndex(victim);
		if(bossIdx >= 0)
		{
			if(FF2_HasAbility(bossIdx, this_plugin_name, FAKE))
			{
				if(FF2_GetBossLives(bossIdx) == 1 && FF2_GetBossHealth(bossIdx) <= damage) 						// if boss has one live
				{
					float Chance = GetRandomFloat(0.0, 100.0);
					SetRandomSeed(1);
					if(Chance <= FAKE_Chance[victim] && (FAKE_Repeat[victim] > FAKE_RepeatTimes[victim]))
					{
						damage = 0.0;
						FF2_SetBossHealth(bossIdx, 1);
						FakeDeath_Invoke(victim);
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public void FakeDeath_Invoke(int bossClientIdx)
{
	SDKHook(bossClientIdx, SDKHook_OnTakeDamage, FakeDeath_NoDamage);
	//Stop that shit
	SDKUnhook(bossClientIdx, SDKHook_OnTakeDamageAlive, HealthCheck_OnTakeDamageAlive); // Unhook here
	
	// if there is only 1 player in boss team, lets make read team think they are won
	if(GetAliveTeamCount(GetClientTeam(bossClientIdx)) <= 1) 
	{
		FF2_StopMusic(0);	// Stop Music
		
		//Sort the damages
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(FF2_GetClientDamage(i) >= 9000)	//if there is any more than 9K damage, play the over nine thousand sound
				{
					EmitSoundToAll("saxton_hale\'9000.wav");
					EmitSoundToAll("saxton_hale\'9000.wav");
				}
				Format(DamageList[i], 768, "%i-%N", FF2_GetClientDamage(i), i);
			}
		}
		SortStrings(DamageList, MAXPLAYERARRAY, Sort_Descending);	
		
		//Show the fake hud status
		char HUDStatus[768];	
		for(int i = 1; i<= MaxClients;i++)
		{
			if(IsValidClient(i))
			{
				SetHudTextParams(-1.0, 0.39, 6.25, 255 , 255 , 255, 255);
				Format(HUDStatus, sizeof(HUDStatus), "Most damage dealt by:\n1) %s \n2) %s \n3) %s",
				DamageList[0], DamageList[1], DamageList[2]);
				
				ShowSyncHudText(i, FakeHud, HUDStatus);
				
				SetHudTextParams(-1.0, 0.63, 6.25, 255 , 255 , 255, 255);
				Format(HUDStatus, sizeof(HUDStatus), "You dealt %i damage in this round\nYou earned %i points in this round", FF2_GetClientDamage(i), GetRandomInt(1, 10));
				ShowSyncHudText(i, FakeHud2, HUDStatus);
				
				if(i != bossClientIdx)
					TF2_AddCondition(i, view_as<TFCond>(38), 6.2);	// give everyone crits		
			}
		}
	}
	
	//Fake detah sound
	FF2_EmitRandomSound(bossClientIdx, "sound_nextlife");

	//fake ragdoll
	int ragdoll = CreateEntityByName("tf_ragdoll");
	if(ragdoll != -1)
	{
		float clientOrigin[3];
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", clientOrigin); 
		SetEntProp(ragdoll, Prop_Send, "m_iPlayerIndex", bossClientIdx);
				
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", GetClientTeam(bossClientIdx));
		SetEntProp(ragdoll, Prop_Send, "m_iClass",GetClientTeam(bossClientIdx));
		DispatchSpawn(ragdoll);
		
		char info[64];
		Format(info, sizeof(info), "OnUser1 !self:kill::20:1");
		SetVariantString(info);
		AcceptEntityInput(ragdoll, "AddOutput");
		AcceptEntityInput(ragdoll, "FireUser1");
	}
	else
	{
		LogError("ERROR: Something went wrong while creating fake ragdoll. %s:FakeDeath_Invoke()", this_plugin_name);
	}
	
	//prefect invisiblity
	TF2_AddCondition(bossClientIdx, view_as<TFCond>(66), 8.2);
	SetEntProp(bossClientIdx, Prop_Data, "m_CollisionGroup", 2);
	SetEntityRenderMode(bossClientIdx, view_as<RenderMode>(2));
	SetEntityRenderColor(bossClientIdx, 255, 255, 255, 0);
	
	//No collisions
	SetCollisions(true, true, true);
	
	CreateTimer(8.2, FakeDeath_Fix, bossClientIdx, TIMER_FLAG_NO_MAPCHANGE);
}

public Action FakeDeath_Fix(Handle timer, int bossClientIdx)
{
	if(IsValidClient(bossClientIdx))
	{
		int bossIdx = FF2_GetBossIndex(bossClientIdx);
		

		int health = ParseFormula(bossIdx, FAKE_Health[bossClientIdx], FF2_GetBossMaxHealth(bossIdx), GetTotalPlayerCount());
		FF2_SetBossMaxHealth(bossIdx, health);
		FF2_SetBossHealth(bossIdx, FF2_GetBossMaxHealth(bossIdx));
		
		SDKUnhook(bossClientIdx, SDKHook_OnTakeDamage, FakeDeath_NoDamage);
		
		SetCollisions(false, true, true);
		
		SetEntityRenderColor(bossClientIdx, 255, 255, 255, 255);
		SetEntityRenderMode(bossClientIdx, view_as<RenderMode>(1));
		
		FF2_StartMusic(0);
		
		FAKE_RepeatTimes[bossClientIdx]++;
		
		if(FAKE_Repeat[bossClientIdx] > FAKE_RepeatTimes[bossClientIdx])
		{
			SDKHook(bossClientIdx, SDKHook_OnTakeDamageAlive, HealthCheck_OnTakeDamageAlive);
		}
	}
}

public Action FakeDeath_NoDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	damageForce[0] = damageForce[0] * 0.0;
	damageForce[1] = damageForce[1] * 0.0;
	damageForce[2] = damageForce[2] * 0.0;
	
	damage = damage * 0.0;
	return Plugin_Changed;
}

public Action FF2_OnLoseLife(int bossIdx, int &lives, int maxLives)
{
	if(FF2_HasAbility(bossIdx, this_plugin_name, FAKE))
	{
		if(lives-1 == 1)
		{
			int bossClientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
			// Hook Healthcheck
			SDKHook(bossClientIdx, SDKHook_OnTakeDamageAlive, HealthCheck_OnTakeDamageAlive);
		}
	}
}

public Action FF2_OnAbility2(int bossIdx, const char[] plugin_name, const char[] ability_name, int status)
{
	return Plugin_Continue;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client <= 0 || client > MaxClients)
		return false;

	if(!IsClientInGame(client) || !IsClientConnected(client))
		return false;

	if(replaycheck && (IsClientSourceTV(client) || IsClientReplay(client)))
		return false;
		
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	return true;
}

public void FF2_EmitRandomSound(int bossClientIdx, const char[] keyvalue)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	char sound[PLATFORM_MAX_PATH];
	if(FF2_RandomSound(keyvalue, sound, sizeof(sound), bossIdx))
	{
		EmitSoundToAll(sound);
		EmitSoundToAll(sound);
	}
}

stock int GetAliveTeamCount(int team)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team) 
            number++;
    }
    return number;
}

stock int GetRandomPlayer()
{
	int clients[MAXPLAYERS];
	int clientCount;
	
	for(int i = 1 ; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) != TFTeam_Spectator)
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

stock int FAKE_RemainFakeDeaths(int bossclientIdx)
{
	int bossIdx = FF2_GetBossIndex(bossClientIdx);
	if(bossIdx >= 0)
	{
		if(FF2_HasAbility(bossIdx, this_plugin_name, FAKE))
		{
			return FAKE_Repeats[bossClientIdx] - FAKE_RepeatTimes[bossClientIdx];
		}
		else
		{
			return -1;
		}
	}
	return -1;
}

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	char formula[1024], bossName[64];
	GetBossName(boss, bossName, sizeof(bossName));
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
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
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
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[%s] %s's %s formula has an unbalanced parentheses at character %i", this_plugin_name, bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
						_operator.Set(bracket, Operator_Add);

					case '-':
						_operator.Set(bracket, Operator_Subtract);

					case '*':
						_operator.Set(bracket, Operator_Multiply);

					case '/':
						_operator.Set(bracket, Operator_Divide);

					case '^':
						_operator.Set(bracket, Operator_Exponent);
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;
	if(result <= 0)
	{
		LogError("[%s] %s has an invalid %s formula, using default health!",this_plugin_name, bossName, key);
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
	float sum = sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:
		{
			sumArray.Set(bracket, sum+value);
		}
		case Operator_Subtract:
		{
			sumArray.Set(bracket, sum-value);
		}
		case Operator_Multiply:
		{
			sumArray.Set(bracket, sum*value);
		}
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
		case Operator_Exponent:
		{
			sumArray.Set(bracket, Pow(sum, value));
		}
		default:
		{
			sumArray.Set(bracket, value);  //This means we're dealing with a constant
		}
	}
	_operator.Set(bracket, Operator_None);
}

stock bool GetBossName(int boss=0, char[] buffer, int bufferLength, int bossMeaning=0, int client=0)
{
	return FF2_GetBossName(boss, buffer, bufferLength, bossMeaning, client);
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

stock void SetCollisions(bool remove = true, bool players = true, bool building = true)
{
	int Num;
	if(remove)
		Num = 2;
	else
		Num = 5;
	
	if(players)
	{
		for(int clientIdx = 1; clientIdx <= MaxClients; clientIdx++)
		{
			if(IsValidClient(clientIdx) && IsPlayerAlive(clientIdx))
			{
				SetEntProp(clientIdx, Prop_Data, "m_CollisionGroup", Num);
			}
		}
	}
	if(building)
	{
		int iBuilding = -1;
		while((iBuilding = FindEntityByClassname(iBuilding, "obj_*")) != -1)
		{
			static char strClassname[15];
			GetEntityClassname(iBuilding, strClassname, sizeof(strClassname));
			if(StrEqual(strClassname, "obj_dispenser") || StrEqual(strClassname, "obj_teleporter") || StrEqual(strClassname, "obj_sentrygun"))
			{
				SetEntProp(iBuilding, Prop_Data, "m_CollisionGroup", Num);
			}
		}
	}
}