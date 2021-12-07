#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <tf2items_giveweapon>
#include <sdktools_sound>
#include <tf2_hud>

#define KillSound "mvm/mvm_bought_in.wav"
#define KillSound_Gold "mvm/mvm_used_powerup.wav"

new Handle:sm_ar_goldmodeactivate;

new bool:bGold;

public Plugin:myinfo = 
{
	name = "[TF2] Arms Race",
	author = "Bitl",
	description = "Gives a player a random weapon after a kill.",
	version = "1.0.9",
	url = ""
}

public OnPluginStart()
{
	CheckGame();
	
	sm_ar_goldmodeactivate = CreateConVar( "sm_ar_goldmode", "0", "Enables/disables Gold Mode on spawn", FCVAR_NOTIFY | FCVAR_CHEAT, true, 0.0, true, 1.0 );
	HookConVarChange( sm_ar_goldmodeactivate, OnConVarChanged );

	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("post_inventory_application", event_LockerUpdate);

	PrecacheSound(KillSound);
	PrecacheSound(KillSound_Gold);
}

CheckGame()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public OnConfigsExecuted()
{
	bGold = GetConVarBool( sm_ar_goldmodeactivate );
}

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	OnConfigsExecuted();
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new RandomNumbersArrayScout[21] = {45,220,448,772,46,163,222,449,773,812,44,221,317,325,349,355,450,452,572,648,1103};
	new randomnumScout = GetRandomInt(0, sizeof(RandomNumbersArrayScout)-1);
	
	new RandomNumbersArraySniper[13] = {56,230,402,526,57,58,231,642,751,171,232,401,1098};
	new randomnumSniper = GetRandomInt(0, sizeof(RandomNumbersArraySniper)-1);
	
	new RandomNumbersArraySoldier[20] = {127,228,414,441,730,129,133,226,354,415,442,444,128,154,357,416,447,775,1101,1104};
	new randomnumSoldier = GetRandomInt(0, sizeof(RandomNumbersArraySoldier)-1);
	
	new RandomNumbersArrayDemoMan[18] = {308,405,608,130,131,406,132,154,172,307,327,357,404,482,609,996,1099,1101};
	new randomnumDemoMan = GetRandomInt(0, sizeof(RandomNumbersArrayDemoMan)-1);
	
	new RandomNumbersArrayMedic[10] = {36,305,412,35,411,37,173,304,413,998};
	new randomnumMedic = GetRandomInt(0, sizeof(RandomNumbersArrayMedic)-1);
	
	new RandomNumbersArrayHeavy[15] = {41,312,424,811,42,159,311,425,43,239,310,331,426,587,656};
	new randomnumHeavy = GetRandomInt(0, sizeof(RandomNumbersArrayHeavy)-1);
	
	new RandomNumbersArrayPyro[19] = {40,215,594,741,39,351,415,595,740,38,153,214,326,348,457,466,593,739,813};
	new randomnumPyro = GetRandomInt(0, sizeof(RandomNumbersArrayPyro)-1);
	
	new RandomNumbersArraySpy[15] = {61,161,224,460,525,810,225,356,461,574,638,649,727,59,60};
	new randomnumSpy = GetRandomInt(0, sizeof(RandomNumbersArraySpy)-1);
	
	new RandomNumbersArrayEngineer[9] = {141,527,588,140,528,155,329,589,997};
	new randomnumEngineer = GetRandomInt(0, sizeof(RandomNumbersArrayEngineer)-1);
	
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{	
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (IsClientInGame(client))
		{
			SoundNormal(client);
			TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
		}
	}
	
	new kills = GetClientFrags(client);
	
	if (kills == 20)
	{
		PrintToHudAll("%N NOW HAS A GOLD WEAPON!", client);
		
		new RandomChanceAll = GetRandomInt(0,1);
		new RandomChanceEngie = GetRandomInt(0,2);
		
		if (TF2_GetPlayerClass(client) != TFClass_Engineer)
		{
			if (RandomChanceAll == 1)
			{
				TF2Items_GiveWeapon(client, 1071);
			}
			else
			{
				TF2Items_GiveWeapon(client, 423);
			}
		}
		else
		{
			if (RandomChanceEngie == 1)
			{
				TF2Items_GiveWeapon(client, 1071);
			}
			else if (RandomChanceEngie == 2)
			{
				TF2Items_GiveWeapon(client, 169);
			}
			else
			{
				TF2Items_GiveWeapon(client, 423);
			}
		}
		
		SoundGold(client);
		PrintCenterText(client, "YOU NOW HAVE A GOLD WEAPON. KILL 10 MORE PLAYERS TO WIN.");
	}
	else if (kills == 21)
	{
		PrintCenterText(client, "KILL 9 MORE PLAYERS TO WIN.");
	}
	else if (kills == 22)
	{
		PrintCenterText(client, "KILL 8 MORE PLAYERS TO WIN.");
	}
	else if (kills == 23)
	{
		PrintCenterText(client, "KILL 7 MORE PLAYERS TO WIN.");
	}
	else if (kills == 24)
	{
		PrintCenterText(client, "KILL 6 MORE PLAYERS TO WIN.");
	}
	else if (kills == 25)
	{
		PrintCenterText(client, "KILL 5 MORE PLAYERS TO WIN.");
	}
	else if (kills == 26)
	{
		PrintCenterText(client, "KILL 4 MORE PLAYERS TO WIN.");
	}
	else if (kills == 27)
	{
		PrintCenterText(client, "KILL 3 MORE PLAYERS TO WIN.");
	}
	else if (kills == 28)
	{
		PrintCenterText(client, "KILL 2 MORE PLAYERS TO WIN.");
	}
	else if (kills == 29)
	{
		PrintCenterText(client, "KILL 1 MORE PLAYER TO WIN.");
	}
	else if (kills == 30)
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

		if (victim && attacker)
		{
			if (GetClientTeam(victim) != GetClientTeam(attacker))
			{
				new iEnt = -1;
				iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
				if (iEnt < 1)
				{		
					iEnt = CreateEntityByName("game_round_win");
					if (IsValidEntity(iEnt))
					{
						DispatchSpawn(iEnt);
					}
				}
				
				new iWinningTeam = 0;
				if (client) 
					iWinningTeam = GetClientTeam(client);
					
				if (iWinningTeam == 1)
					iWinningTeam --;
		
				SetVariantInt(iWinningTeam);
				AcceptEntityInput(iEnt, "SetTeam");
				AcceptEntityInput(iEnt, "RoundWin");
				
				SetEntProp(attacker, Prop_Data, "m_iFrags", 0);
			}
		}
	}
	
	if(bGold)
	{
		if (kills == 1)
		{
			PrintCenterText(client, "KILL 9 MORE PLAYERS TO WIN.");
		}
		else if (kills == 2)
		{
			PrintCenterText(client, "KILL 8 MORE PLAYERS TO WIN.");
		}
		else if (kills == 3)
		{
			PrintCenterText(client, "KILL 7 MORE PLAYERS TO WIN.");
		}
		else if (kills == 4)
		{
			PrintCenterText(client, "KILL 6 MORE PLAYERS TO WIN.");
		}
		else if (kills == 5)
		{
			PrintCenterText(client, "KILL 5 MORE PLAYERS TO WIN.");
		}
		else if (kills == 6)
		{
			PrintCenterText(client, "KILL 4 MORE PLAYERS TO WIN.");
		}
		else if (kills == 7)
		{
			PrintCenterText(client, "KILL 3 MORE PLAYERS TO WIN.");
		}
		else if (kills == 8)
		{
			PrintCenterText(client, "KILL 2 MORE PLAYERS TO WIN.");
		}
		else if (kills == 9)
		{
			PrintCenterText(client, "KILL 1 MORE PLAYER TO WIN.");
		}
		else if (kills == 10)
		{
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

			if (victim && attacker)
			{
				if (GetClientTeam(victim) != GetClientTeam(attacker))
				{
					new iEnt = -1;
					iEnt = FindEntityByClassname(iEnt, "game_round_win");
	
					if (iEnt < 1)
					{		
						iEnt = CreateEntityByName("game_round_win");
						if (IsValidEntity(iEnt))
						{
							DispatchSpawn(iEnt);
						}
					}
				
					new iWinningTeam = 0;
					if (client) 
						iWinningTeam = GetClientTeam(client);
					
					if (iWinningTeam == 1)
						iWinningTeam --;
		
					SetVariantInt(iWinningTeam);
					AcceptEntityInput(iEnt, "SetTeam");
					AcceptEntityInput(iEnt, "RoundWin");
				
					SetEntProp(attacker, Prop_Data, "m_iFrags", 0);
				}
			}
		}
	}
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 13);
			TF2Items_GiveWeapon(client, 23);
			TF2Items_GiveWeapon(client, 0);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 14);
			TF2Items_GiveWeapon(client, 16);
			TF2Items_GiveWeapon(client, 3);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{	
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 18);
			TF2Items_GiveWeapon(client, 10);
			TF2Items_GiveWeapon(client, 6);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 19);
			TF2Items_GiveWeapon(client, 20);
			TF2Items_GiveWeapon(client, 1);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 17);
			TF2Items_GiveWeapon(client, 29);
			TF2Items_GiveWeapon(client, 8);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 15);
			TF2Items_GiveWeapon(client, 11);
			TF2Items_GiveWeapon(client, 5);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 21);
			TF2Items_GiveWeapon(client, 12);
			TF2Items_GiveWeapon(client, 2);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 24);
			TF2Items_GiveWeapon(client, 735);
			TF2Items_GiveWeapon(client, 4);
			TF2Items_GiveWeapon(client, 27);
			TF2Items_GiveWeapon(client, 30);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 9);
			TF2Items_GiveWeapon(client, 22);
			TF2Items_GiveWeapon(client, 7);
			TF2Items_GiveWeapon(client, 25);
			TF2Items_GiveWeapon(client, 26);
			TF2Items_GiveWeapon(client, 28);
		}
	}
	
	if(bGold)
	{
		new RandomChanceAll = GetRandomInt(0,1);
		new RandomChanceEngie = GetRandomInt(0,2);
		
		if (TF2_GetPlayerClass(client) != TFClass_Engineer)
		{
			if (RandomChanceAll == 1)
			{
				TF2Items_GiveWeapon(client, 1071);
			}
			else
			{
				TF2Items_GiveWeapon(client, 423);
			}
		}
		else
		{
			if (RandomChanceEngie == 1)
			{
				TF2Items_GiveWeapon(client, 1071);
			}
			else if (RandomChanceEngie == 2)
			{
				TF2Items_GiveWeapon(client, 169);
			}
			else
			{
				TF2Items_GiveWeapon(client, 423);
			}
		}
		
		SoundGold(client);
		PrintCenterText(client, "YOU NOW HAVE A GOLD WEAPON. KILL 10 MORE PLAYERS TO WIN.");
		PrintToHud(client, "GOLD MODE IS ACTIVATED ON ALL PLAYERS!");
	}

	Help_How(client);
}

public event_LockerUpdate(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetEntProp(client, Prop_Data, "m_iFrags", 0);
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 13);
			TF2Items_GiveWeapon(client, 23);
			TF2Items_GiveWeapon(client, 0);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 14);
			TF2Items_GiveWeapon(client, 16);
			TF2Items_GiveWeapon(client, 3);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{	
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 18);
			TF2Items_GiveWeapon(client, 10);
			TF2Items_GiveWeapon(client, 6);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 19);
			TF2Items_GiveWeapon(client, 20);
			TF2Items_GiveWeapon(client, 1);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 17);
			TF2Items_GiveWeapon(client, 29);
			TF2Items_GiveWeapon(client, 8);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 15);
			TF2Items_GiveWeapon(client, 11);
			TF2Items_GiveWeapon(client, 5);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 21);
			TF2Items_GiveWeapon(client, 12);
			TF2Items_GiveWeapon(client, 2);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 24);
			TF2Items_GiveWeapon(client, 735);
			TF2Items_GiveWeapon(client, 4);
			TF2Items_GiveWeapon(client, 27);
			TF2Items_GiveWeapon(client, 30);
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (IsClientInGame(client))
		{
			TF2Items_GiveWeapon(client, 9);
			TF2Items_GiveWeapon(client, 22);
			TF2Items_GiveWeapon(client, 7);
			TF2Items_GiveWeapon(client, 25);
			TF2Items_GiveWeapon(client, 26);
			TF2Items_GiveWeapon(client, 28);
		}
	}
	
	if(bGold)
	{
		TF2Items_GiveWeapon(client, 423);
	}	
}

stock Help_How(client)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "How to play Arms Race");
	DrawPanelText(menu, " ");
	DrawPanelText(menu, "Once you spawn, all your weapons will be stripped, except the stock weapons.");
	DrawPanelText(menu, "If you kill a player, you will be awarded a random weapon for your class.");
	DrawPanelText(menu, "If you get up to 20 kills (or if sm_ar_goldmode is on), you will be given a gold weapon.");
	DrawPanelText(menu, "If you kill 10 more players, your team will win.");
	DrawPanelText(menu, " ");
	DrawPanelItem(menu, "Close");
 
	SendPanelToClient(menu, client, HelpMenu_Page_Handler, 20);
 
	CloseHandle(menu);
}

public HelpMenu_Page_Handler(Handle:menu, MenuAction:action, param1, param2)
{
	//null
}

stock SoundNormal(client)
{
	EmitSoundToClient(client, KillSound);
}

stock SoundGold(client)
{
	EmitSoundToClient(client, KillSound_Gold);
}

stock GetIndexOfWeaponSlot(client, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	return (IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}