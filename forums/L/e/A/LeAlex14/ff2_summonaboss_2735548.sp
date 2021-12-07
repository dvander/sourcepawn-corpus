#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <tf2items>
#include <sdkhooks>
#include <sdktools>
#include <ff2_ams>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin myinfo = {
   name = "Freak Fortress 2: Summon A Boss",
   author = "LeAlex14",	
   description = "You need someone ? Alright, Make you a friend !",
   version = "1.0"
}

/* 
------------------------------------------------------------------------------------------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

												HOW WORKS IN CFG

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
------------------------------------------------------------------------------------------------------------------------------------
*/

/* 
------------------------------------------------------------------------------------------------------------------------------------
												SUMMON BOSS ARGS
------------------------------------------------------------------------------------------------------------------------------------
*/
/*
"abilityX"
	{
		"name"		"Summon_Another_Boss"

		"arg1"		"2" // Boss Index in character.cfg
		"arg2"		"1"	// Number of boss
		
		"arg3"		"3" // HP Mode (works with arg4) : 1 = Defined Hp; 2 = % Summoner Max Hp; 3 = % Summoned boss Hp in normal mode
		"arg4"		"50" // HP receive (% if arg3 = 2 or 3)
		
		"arg5"		"2" // Lives Mode (works with arg4) : 1 = If summoned have multiple life, add new life number and maxnumber; 2 = If summoned have multiple life, add % of summoned life number and maxnumber; 3 = % Summoner life; 4 = Add life and max life
		"arg6"		"50" // Lives receive (% if arg3 = 2 or 3)
		
		"arg7"		"3" // Damage rage Mode (works with arg4) : 1 = Defined Rage damage; 2 = % Summoner Rage Damage; 3 = % Summoned rage damage in normal mode
		"arg8"		"50" // Damage rage needed (% if arg3 = 2 or 3)

		"plugin_name"	"ff2_summonaboss"
	}
*/

/* 
------------------------------------------------------------------------------------------------------------------------------------
												RED BOSS BACKUP
------------------------------------------------------------------------------------------------------------------------------------
*/
/*
"abilityX"
	{
		"name"		"Boss_Merc_Backup"

		"arg1"		"2" // How many player need to left
		"arg2"		"1" // Boss Index in character.cfg
		"arg3"		"1"	// Number of boss
		
		"arg4"		"3" // HP Mode (works with arg4) : 1 = Defined Hp; 2 = % Boss with this ability Max Hp; 3 = % Summoned boss Hp in normal mode
		"arg5"		"50" // HP receive (% if arg3 = 2 or 3)
		
		"arg6"		"2" // Lives Mode (works with arg4) : 1 = If summoned have multiple life, add new life number and maxnumber; 2 = If summoned have multiple life, add % of summoned life number and maxnumber; 3 = % Boss with this ability life; 4 = Add life and max life
		"arg7"		"50" // Lives receive (% if arg3 = 2 or 3)
		
		"arg8"		"3" // Damage rage Mode (works with arg4) : 1 = Defined Rage damage; 2 = % Boss with this ability Rage Damage; 3 = % Summoned rage damage in normal mode
		"arg9"		"50" // Damage rage needed (% if arg3 = 2 or 3)

		"plugin_name"	"ff2_summonaboss"
	}
*/

bool AMS_TRIGGER[MAXPLAYERS+1][10];	

bool BackupUsed[MAXPLAYERS + 1];
bool BackupRoundUsed;
bool ClientAlreadyBeABoss[MAXPLAYERS + 1];

int ClientPointBackUp[MAXPLAYERS + 1];
int ClientPointSummon[MAXPLAYERS + 1];
int ClientPointBossRed[MAXPLAYERS + 1];

#define SUMMON "Summon_Another_Boss"

public OnPluginStart2(){
	HookEvent("teamplay_round_start", Event_RoundStart);
	
	HookEvent("teamplay_round_win", Event_RoundEnd);
}

public Action Event_RoundStart(Handle event, const char [] name, bool dontBroadcast)
{
	BackupRoundUsed = false;
	for (int client=1; client<=MaxClients; client++)
	{
		BackupUsed[client] = false;
		ClientAlreadyBeABoss[client] = false;
		
		ClientPointBackUp[client] = -1;
		ClientPointSummon[client] = -1;
		ClientPointBossRed[client] = -1;
		
		int idBoss = FF2_GetBossIndex(client);
		if (idBoss > -1)
		{
			ClientAlreadyBeABoss[client] = true;
			for (int iNumber = 0; iNumber <= 10; iNumber++)	// Try with prefix
			{
				char abilityFormat1[64];	// Abilityname var 
				Format(abilityFormat1, 64, "%s%i", SUMMON, iNumber);	// Make a Prefix
				if(FF2_HasAbility(idBoss, this_plugin_name, abilityFormat1))	// That ablity was used ?
				{
					//AMS Triggers
					AMS_TRIGGER[client][iNumber] = AMS_IsSubabilityReady(idBoss, this_plugin_name, abilityFormat1);
					if (AMS_TRIGGER[client][iNumber])
					{
						char abilityNumber[64];
						Format(abilityNumber, 64, "%s%i", "SB", iNumber);
						AMS_InitSubability(idBoss, client, this_plugin_name, abilityFormat1, abilityNumber);
					}
				}
			}
		}
	}
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	BackupRoundUsed = false;
	for (int client=1; client<=MaxClients; client++)
	{		
		BackupUsed[client] = false;
		ClientAlreadyBeABoss[client] = false;
		if (IsClientInGame(client))
		{
			if (ClientPointBackUp[client] != -1)
				FF2_SetQueuePoints(client, ClientPointBackUp[client]);
				
			if (ClientPointSummon[client] != -1)
				FF2_SetQueuePoints(client, ClientPointSummon[client]);
			
			if (ClientPointBossRed[client] != -1)
				FF2_SetQueuePoints(client, ClientPointBossRed[client]);
				
			ClientAlreadyBeABoss[client] = false;
			for (int iNumber=1; iNumber<=10; iNumber++)
			{	
				AMS_TRIGGER[client][iNumber] = false;
			}
		}
	}
}

/* 
------------------------------------------------------------------------------------------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

												SUMMON A BOSS FUNC

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
------------------------------------------------------------------------------------------------------------------------------------
*/

public bool SB0_CanInvoke(int bClient)
{
	return true;
}

public bool SB1_CanInvoke(int bClient)
{
	return true;
}

public bool SB2_CanInvoke(int bClient)
{
	return true;
}

public bool SB3_CanInvoke(int bClient)
{
	return true;
}

public bool SB4_CanInvoke(int bClient)
{
	return true;
}

public bool SB5_CanInvoke(int bClient)
{
	return true;
}

public bool SB6_CanInvoke(int bClient)
{
	return true;
}

public bool SB7_CanInvoke(int bClient)
{
	return true;
}

public bool SB8_CanInvoke(int bClient)
{
	return true;
}

public bool SB9_CanInvoke(int bClient)
{
	return true;
}

public Action SB0_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss0");
}

public Action SB1_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss1");
}

public Action SB2_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss2");
}

public Action SB3_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss3");
}

public Action SB4_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss4");
}

public Action SB5_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss5");
}

public Action SB6_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss6");
}

public Action SB7_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss7");
}

public Action SB8_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss8");
}

public Action SB9_Invoke(bClient)
{
	int idBoss = FF2_GetBossIndex(bClient);
	SummonBoss(idBoss, "Summon_Another_Boss9");
}

public Action FF2_OnAbility2(idBoss,const char [] plugin_name,const char[] ability_name,action)
{
	for (int iNumber = 0; iNumber <= 20; iNumber++)	// Try with prefix
	{
		char abilityFormat1[64];	// Abilityname var 
		Format(abilityFormat1, 64, "%s%i", SUMMON, iNumber);	// Make a Prefix
		if(!strcmp(ability_name, abilityFormat1))	// That ablity was used ?
		{
			int client = GetClientOfUserId(FF2_GetBossUserId(idBoss));
			
			if(AMS_TRIGGER[client][iNumber])
			{
				if(!FunctionExists("ff2_sarysapub3.ff2", "AMS_InitSubability"))
				{
					AMS_TRIGGER[client][iNumber] = false;
				}
				else
					return Plugin_Continue;
			}
			else
				SummonBoss(idBoss, abilityFormat1);
		}
	}
	return Plugin_Continue;
}

public Action SummonBoss(int idBoss,const char[] AbilityName)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(idBoss));
	int BossNumber = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 2, 1);
	
	for(int BOSSN=0; BOSSN<BossNumber; BOSSN++)
	{
		Handle Indexes  = CreateArray();
		char IndexList[64];
		char IndexVar[64][64];
		FF2_GetAbilityArgumentString(idBoss, this_plugin_name, AbilityName, 1, IndexList, sizeof(IndexList));

		int counts = ExplodeString(IndexList, " ; ", IndexVar, sizeof(IndexVar), sizeof(IndexVar));
		if (counts > 0)
		{
			for (new i = 0; i < counts; i++)
			{
				PushArrayCell(Indexes, StringToInt(IndexVar[i]));
			}
		}
		
		int BossIndex = GetArrayCell(Indexes,GetRandomInt(0,GetArraySize(Indexes)-1));
		CloseHandle(Indexes);
							
		Handle compatible  = CreateArray();
		for(int player=1; player<=MaxClients; player++)
		{
			if(IsClientInGame(player))
			{
				TFTeam team = TF2_GetClientTeam(player);
				if(team>TFTeam_Spectator)
				{
					if(!IsPlayerAlive(player) && !ClientAlreadyBeABoss[player])
					{
						PushArrayCell(compatible, player);
					}
				}
			}
		}
		
		int PlayerAreBoss=0;
		for(int playerBoss=1; playerBoss<=MaxClients; playerBoss++)
		{
			if (FF2_GetBossIndex(playerBoss)>-1)
			{
				PlayerAreBoss++;
			}
		}
		if (GetArraySize(compatible)>0)
		{
			int choosen = GetArrayCell(compatible,GetRandomInt(0,GetArraySize(compatible)-1));
			int TfTeamChoosen = GetClientTeam(client);
			ChangeClientTeam(choosen, TfTeamChoosen);
			
			TF2_RespawnPlayer(choosen);
			
			if (BossIndex<0)
				BossIndex = GetRandomInt(0, (BossIndex * -1) - 1);
			
			ClientPointSummon[choosen] = (FF2_GetQueuePoints(choosen) + 10);
			
			if (TfTeamChoosen==2)
				FF2_MakeBoss(choosen, (PlayerAreBoss+1), BossIndex, true);
				
			else
				FF2_MakeBoss(choosen, (PlayerAreBoss+1), BossIndex, false);
			
			CloseHandle(compatible);
			ClientAlreadyBeABoss[client] = true;
			
			DataPack pPack;
			CreateDataTimer(1.0, Timer_Hp_Life, pPack, TIMER_FLAG_NO_MAPCHANGE);
			pPack.WriteCell(client);
			pPack.WriteCell(choosen);
			pPack.WriteString(AbilityName);
		}
	}
}

public Action Timer_Hp_Life(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	int choosen = pack.ReadCell();
	
	char AbilityName[1024];
	pack.ReadString(AbilityName, 1024);
	
	int idBoss = FF2_GetBossIndex(client);
	int idSummonedBoss = FF2_GetBossIndex(choosen);
	
	int HPMode = FF2_GetAbilityArgument(idBoss,this_plugin_name, AbilityName, 3, 2);
	int HP = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 4, 1);
	
	int LifeMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 5, 2);
	int Life = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 6, 1);
	
	int MaxLiveSummonedBefore = FF2_GetBossMaxLives(idSummonedBoss);
	
	switch (LifeMode)
	{
	    case 1:
	    {
	    	if (FF2_GetBossMaxLives(idSummonedBoss)>1)
	    	{
		        FF2_SetBossMaxLives(idSummonedBoss, Life);
		        FF2_SetBossLives(idSummonedBoss, Life);
		   	}
	    }
	    case 2:
	    {
        	if (FF2_GetBossMaxLives(idSummonedBoss)>1)
	    	{
	    		int NewLife = RoundToCeil(((FF2_GetBossMaxLives(idSummonedBoss)*1.0) / (Life*1.0)));
	    		if (NewLife <= 0)
	       			NewLife = 1;
		        FF2_SetBossMaxLives(idSummonedBoss, NewLife);
		        FF2_SetBossLives(idSummonedBoss, NewLife);
		   	}
	    }
	    case 3:
	    {
	       	int NewLife = RoundToCeil(((FF2_GetBossMaxLives(idBoss)*1.0) / (Life*1.0)));
	       	if (NewLife <= 0)
	       		NewLife = 1;
	        FF2_SetBossMaxLives(idSummonedBoss, NewLife);
	        FF2_SetBossLives(idSummonedBoss, NewLife);
	    }
	  	case 4:
		{
		    FF2_SetBossMaxLives(idSummonedBoss, Life);
		    FF2_SetBossLives(idSummonedBoss, Life);
		}
	}
	
	int MaxLiveSummonedAfter = FF2_GetBossMaxLives(idSummonedBoss);
	int MaxLiveSummoner = FF2_GetBossMaxLives(idBoss);
	switch (HPMode)
	{
	    case 1:
	    {
	    	FF2_SetBossHealth(idSummonedBoss, HP*MaxLiveSummonedAfter);
	        FF2_SetBossMaxHealth(idSummonedBoss, HP);
	    }
	    case 2:
	    {
	        int NewHp = RoundToCeil((((FF2_GetBossMaxHealth(idBoss)*1.0)/(MaxLiveSummoner*1.0)) * ((HP*1.0)/(100*1.0)))*1.0)*MaxLiveSummonedAfter;
	        FF2_SetBossMaxHealth(idSummonedBoss, RoundFloat((NewHp/MaxLiveSummonedAfter)*1.0));
	        FF2_SetBossHealth(idSummonedBoss, NewHp);
	    }
	    case 3:
	    {
	        int NewHp = RoundToCeil((((FF2_GetBossMaxHealth(idSummonedBoss)*1.0)/(MaxLiveSummonedBefore*1.0)) * ((HP*1.0)/(100*1.0)))*1.0)*MaxLiveSummonedAfter;
	        FF2_SetBossMaxHealth(idSummonedBoss, RoundToCeil((NewHp/MaxLiveSummonedAfter)*1.0));
	        FF2_SetBossHealth(idSummonedBoss, NewHp);
	    }
	}
	
	int RageDamageMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 7, 2);
	int RageDamageNeed = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 8, 1);
	
	switch (RageDamageMode)
	{
	    case 1:
	    {
	    	FF2_SetBossRageDamage(idSummonedBoss, RageDamageNeed);
	    }
	    case 2:
	    {
	        int NewRageNeed = RoundFloat(FF2_GetBossRageDamage(idBoss) * ((RageDamageNeed*1.0)/100.0));
	        FF2_SetBossRageDamage(idSummonedBoss, NewRageNeed);
	    }
	    case 3:
	    {
	        int NewRageNeed = RoundFloat(FF2_GetBossRageDamage(idSummonedBoss) * ((RageDamageNeed*1.0)/100.0));
	        FF2_SetBossRageDamage(idSummonedBoss, NewRageNeed);
	    }
	}
	
	int SpawnMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,AbilityName, 9, 2);
	
	switch (SpawnMode)
	{
	    case 1:
	    {
			float velocity[3], position[3];
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);
			velocity[0] = GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
			velocity[1] = GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
			velocity[2] = GetRandomFloat(300.0, 500.0);
			TeleportEntity(choosen, position, NULL_VECTOR, velocity);
	    }
	}
}

/* 
------------------------------------------------------------------------------------------------------------------------------------
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

												BACKUP BOSS RED FUNC

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
------------------------------------------------------------------------------------------------------------------------------------
*/
public void FF2_OnAlivePlayersChanged(int Players, int Bosses)
{
	for(int client=1; client<=MaxClients; client++)
	{
		int idBoss = FF2_GetBossIndex(client);
		if (idBoss > -1)
		{
			if (FF2_HasAbility(idBoss, this_plugin_name, "Boss_Merc_Backup"))
			{
				int BackupMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 10, 1);
				if ((!BackupUsed[client] && BackupMode==0) || (!BackupRoundUsed && BackupMode==1))
				{
					int NumberPlayerLeftNeed = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 1, 2);
					int BossNumber = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 3, 1);
					
					if (NumberPlayerLeftNeed>=Players)
					{
						BackupUsed[client] = true;
						BackupRoundUsed = true;
						for(int BOSSN=0; BOSSN<BossNumber; BOSSN++)
						{
								
							Handle Indexes  = CreateArray();
							char IndexList[64];
							char IndexVar[64][64];
							FF2_GetAbilityArgumentString(idBoss, this_plugin_name, "Boss_Merc_Backup", 2, IndexList, sizeof(IndexList));
			
							int counts = ExplodeString(IndexList, " ; ", IndexVar, sizeof(IndexVar), sizeof(IndexVar));
							if (counts > 0)
							{
								for (new i = 0; i < counts; i++)
								{
									PushArrayCell(Indexes, StringToInt(IndexVar[i]));
								}
							}
							
							int BossIndex = GetArrayCell(Indexes,GetRandomInt(0,GetArraySize(Indexes)-1));
							CloseHandle(Indexes);
			
							Handle compatible  = CreateArray();
							for(int player=1; player<=MaxClients; player++)
							{
								if(IsClientInGame(player))
								{
									TFTeam team = TF2_GetClientTeam(player);
									if(team>TFTeam_Spectator)
									{
										if(!IsPlayerAlive(player) && !ClientAlreadyBeABoss[player])
										{
											PushArrayCell(compatible, player);
										}
									}
								}
							}
							
							int PlayerAreBoss=0;
							for(int playerBoss=1; playerBoss<=MaxClients; playerBoss++)
							{
								if (FF2_GetBossIndex(playerBoss)>-1)
								{
									PlayerAreBoss++;
								}
							}
							if (GetArraySize(compatible)>0)
							{
								int choosen = GetArrayCell(compatible,GetRandomInt(0,GetArraySize(compatible)-1));
								int TfTeamClient = GetClientTeam(client);
								int TfTeamChoosen = 0;
								
								if (TfTeamClient == 2)
									TfTeamChoosen = 3;
								else
									TfTeamChoosen = 2;
									
								ChangeClientTeam(choosen, TfTeamChoosen);
								
								TF2_RespawnPlayer(choosen);
								
								if (BossIndex<0)
									BossIndex = GetRandomInt(0, (BossIndex * -1) - 1);
								
								if (TfTeamChoosen==2)
									FF2_MakeBoss(choosen, (PlayerAreBoss+1), BossIndex, true);
									
								else
									FF2_MakeBoss(choosen, (PlayerAreBoss+1), BossIndex, false);
								CloseHandle(compatible);
								ClientAlreadyBeABoss[client] = true;
								
								DataPack pPack;
								CreateDataTimer(1.0, Timer_Hp_Life_Backup, pPack, TIMER_FLAG_NO_MAPCHANGE);
								pPack.WriteCell(client);
								pPack.WriteCell(choosen);
							}
						}
					}
				}
			}
		}
	}
}

public Action Timer_Hp_Life_Backup(Handle timer, DataPack pack)
{
	pack.Reset();
	
	int client = pack.ReadCell();
	int choosen = pack.ReadCell();
	
	int idBoss = FF2_GetBossIndex(client);
	int idSummonedBoss = FF2_GetBossIndex(choosen);
	
	int HPMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 4, 2);
	int HP = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 5, 1);
	
	int LifeMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 6, 2);
	int Life = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Boss_Merc_Backup", 7, 1);
	
	int MaxLiveSummonedBefore = FF2_GetBossMaxLives(idSummonedBoss);
	
	switch (LifeMode)
	{
	    case 1:
	    {
	    	if (FF2_GetBossMaxLives(idSummonedBoss)>1)
	    	{
		        FF2_SetBossMaxLives(idSummonedBoss, Life);
		        FF2_SetBossLives(idSummonedBoss, Life);
		   	}
	    }
	    case 2:
	    {
        	if (FF2_GetBossMaxLives(idSummonedBoss)>1)
	    	{
	    		int NewLife = RoundToCeil(((FF2_GetBossMaxLives(idSummonedBoss)*1.0) / (Life*1.0)));
	    		if (NewLife <= 0)
	       			NewLife = 1;
		        FF2_SetBossMaxLives(idSummonedBoss, NewLife);
		        FF2_SetBossLives(idSummonedBoss, NewLife);
		   	}
	    }
	    case 3:
	    {
	       	int NewLife = RoundToCeil(((FF2_GetBossMaxLives(idBoss)*1.0) / (Life*1.0)));
	       	if (NewLife <= 0)
	       		NewLife = 1;
	        FF2_SetBossMaxLives(idSummonedBoss, NewLife);
	        FF2_SetBossLives(idSummonedBoss, NewLife);
	    }
	  	case 4:
		{
		    FF2_SetBossMaxLives(idSummonedBoss, Life);
		    FF2_SetBossLives(idSummonedBoss, Life);
		}
	}
	
	int MaxLiveSummonedAfter = FF2_GetBossMaxLives(idSummonedBoss);
	int MaxLiveSummoner = FF2_GetBossMaxLives(idBoss);
	switch (HPMode)
	{
	    case 1:
	    {
	    	FF2_SetBossHealth(idSummonedBoss, HP*MaxLiveSummonedAfter);
	        FF2_SetBossMaxHealth(idSummonedBoss, HP);
	    }
	    case 2:
	    {
	        int NewHp = RoundToCeil((((FF2_GetBossMaxHealth(idBoss)*1.0)/(MaxLiveSummoner*1.0)) * ((HP*1.0)/(100*1.0)))*1.0)*MaxLiveSummonedAfter;
	        FF2_SetBossMaxHealth(idSummonedBoss, RoundFloat((NewHp/MaxLiveSummonedAfter)*1.0));
	        FF2_SetBossHealth(idSummonedBoss, NewHp);
	    }
	    case 3:
	    {
	        int NewHp = RoundToCeil((((FF2_GetBossMaxHealth(idSummonedBoss)*1.0)/(MaxLiveSummonedBefore*1.0)) * ((HP*1.0)/(100*1.0)))*1.0)*MaxLiveSummonedAfter;
	        FF2_SetBossMaxHealth(idSummonedBoss, RoundToCeil((NewHp/MaxLiveSummonedAfter)*1.0));
	        FF2_SetBossHealth(idSummonedBoss, NewHp);
	    }
	}
	
	int RageDamageMode = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Summon_Another_Boss", 7, 2);
	int RageDamageNeed = FF2_GetAbilityArgument(idBoss,this_plugin_name,"Summon_Another_Boss", 8, 1);
	
	switch (RageDamageMode)
	{
	    case 1:
	    {
	    	FF2_SetBossRageDamage(idSummonedBoss, RageDamageNeed);
	    }
	    case 2:
	    {
	        int NewRageNeed = RoundFloat(FF2_GetBossRageDamage(idBoss) * ((RageDamageNeed*1.0)/100.0));
	        FF2_SetBossRageDamage(idSummonedBoss, NewRageNeed);
	    }
	    case 3:
	    {
	        int NewRageNeed = RoundFloat(FF2_GetBossRageDamage(idSummonedBoss) * ((RageDamageNeed*1.0)/100.0));
	        FF2_SetBossRageDamage(idSummonedBoss, NewRageNeed);
	    }
	}
}