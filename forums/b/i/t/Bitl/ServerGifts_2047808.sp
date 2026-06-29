#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items_giveweapon>

#define PLUGIN_VERSION "1.2.1"
#define MDL "models/items/tf_gift.mdl"
#define MDL2 "models/props_halloween/halloween_gift.mdl"
#define MDL_FIREWORKS "mini_fireworks"
#define MDL_CONFETTI "bday_confetti"
#define SND_BRDY "misc/happy_birthday.wav"

new Handle:sm_servergifts_giftsondeath;
new Handle:sm_servergifts_rareweapons;
new Handle:sm_servergifts_rarechance;
new Handle:sm_servergifts_bots;
new Handle:sm_servergifts_botsonlyinmvm;

new bool:bGiftsOnDeath;
new bool:bRareWeapons;
new bool:bBots;
new bool:bBotsOnlyInMvM;
new Float:g_pos[3];

public Plugin:myinfo = 
{
    name = "[TF2] ServerGifts",
    author = "Bitl",
    description = "Spawns a gift with a random weapon in it on Domination, Revenge or command.",
    version = PLUGIN_VERSION,
    url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("servergifts.phrases");
	CheckGame();

	sm_servergifts_giftsondeath = CreateConVar("sm_servergifts_giftsondeath", "1", "Enable/Disable creating gifts on victim death.", FCVAR_NOTIFY);
	HookConVarChange( sm_servergifts_giftsondeath, OnConVarChanged );

	sm_servergifts_rareweapons = CreateConVar("sm_servergifts_rareweapons", "1", "Enable/Disable rare weapons.", FCVAR_NOTIFY);
	HookConVarChange( sm_servergifts_rareweapons, OnConVarChanged );
	
	sm_servergifts_rarechance = CreateConVar("sm_servergifts_rarechance", "200", "The chance for a rare weapon to drop.", FCVAR_NOTIFY);
	
	sm_servergifts_bots = CreateConVar("sm_servergifts_bots", "1", "Enable/Disable spawning gifts on bots.", FCVAR_NOTIFY);
	HookConVarChange( sm_servergifts_bots, OnConVarChanged );
	
	sm_servergifts_botsonlyinmvm = CreateConVar("sm_servergifts_botsonlyinmvm", "1", "Enable/Disable spawning gifts on bots only in Mann vs Machine. Requires sm_servergifts_bots to be 1.", FCVAR_NOTIFY);
	HookConVarChange( sm_servergifts_botsonlyinmvm, OnConVarChanged );

	RegAdminCmd("sm_servergifts", ServerGift, ADMFLAG_ROOT);
	
	HookEvent("player_death", event_PlayerDeath);
}

CheckGame()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (StrEqual(strModName, "tf")) return;
	SetFailState("[SM] This plugin is only for Team Fortress 2.");
}

public OnConfigsExecuted()
{
	bGiftsOnDeath = GetConVarBool( sm_servergifts_giftsondeath );
	bRareWeapons = GetConVarBool( sm_servergifts_rareweapons );
	bBots = GetConVarBool( sm_servergifts_bots );
	bBotsOnlyInMvM = GetConVarBool( sm_servergifts_botsonlyinmvm );
}

public OnConVarChanged( Handle:hConVar, const String:strOldValue[], const String:strNewValue[] )
{
	OnConfigsExecuted();
}

public OnMapStart()
{
	PrecacheModel(MDL, true);
	PrecacheModel(MDL2, true);
	PrecacheGeneric(MDL_FIREWORKS, true);
	PrecacheGeneric(MDL_CONFETTI, true);
	PrecacheSound(SND_BRDY, true);
}

public Action:ServerGift(client, args)
{
	if(IsValidClient(client)) 
	{
		if(!SetTeleportEndPoint(client)) PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
		g_pos[2] -= 10;
		createGift(client, g_pos);
		PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
	}
	else
	{
		if (bBots)
		{
			if (IsMvM() && bBotsOnlyInMvM)
			{
				if(!SetTeleportEndPoint(client)) PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
				g_pos[2] -= 10;
				createGift(client, g_pos);
				PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
			}
			else
			{
				if(!SetTeleportEndPoint(client)) PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
				g_pos[2] -= 10;
				createGift(client, g_pos);
				PrintToChat(client, "[ServerGifts]: %t", "SpawnedGift");
			}
		}
	}

	return Plugin_Handled;
}

public createGift(client, Float:pos[3]) {
	new ent = CreateEntityByName("item_ammopack_small");
	if(IsValidEntity(ent)) {
		//generate a random gift box model
		new gen;
		gen = GetRandomInt(0,1);
		
		if(gen == 0) {
			DispatchKeyValue(ent, "powerup_model", MDL);
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetRandomFloat(1.0, 1.5));
		}
		else if(gen == 1) {
			DispatchKeyValue(ent, "powerup_model", MDL2);
			//makes sure it scales with the other model, not exact but its good enough
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", GetRandomFloat(1.0, 1.5)*0.70);
		}
		DispatchKeyValue(ent, "targetname", "giftbox%tak");
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR); 
		DispatchSpawn(ent); 
		ActivateEntity(ent);
		
		CreateParticle(MDL_FIREWORKS, 5.0, ent);
		CreateParticle(MDL_CONFETTI, 5.0, ent);
		EmitAmbientSound(SND_BRDY, pos);
		
		SetEntProp(ent, Prop_Send, "m_iTeamNum", 1, 4);

		SDKHook(ent, SDKHook_StartTouch, StartTouch);
	}
}

public Action:StartTouch(entity, client) 
{
	if (client > MaxClients)
	{
   		 //return Plugin_Continue;
   		 // Or Plugin_Stop... not sure if it will block trains if you use Plugin_Continue;
		 return Plugin_Stop;
	}  

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
		
	new RandomNumbersArrayRaresScout[12] = {160,423,799,808,888,897,906,915,964,973,1071,1121};
	new randomnumRaresScout = GetRandomInt(0, sizeof(RandomNumbersArrayRaresScout)-1);

	new RandomNumbersArrayRaresSoldier[10] = {423,800,809,889,898,907,916,965,974,1071};
	new randomnumRaresSoldier = GetRandomInt(0, sizeof(RandomNumbersArrayRaresSoldier)-1);

	new RandomNumbersArrayRaresPyro[10] = {423,798,807,887,896,905,914,963,972,1071};
	new randomnumRaresPyro = GetRandomInt(0, sizeof(RandomNumbersArrayRaresPyro)-1);

	new RandomNumbersArrayRaresDemoMan[11] = {266,423,797,806,886,895,904,913,962,971,1071};
	new randomnumRaresDemoMan = GetRandomInt(0, sizeof(RandomNumbersArrayRaresDemoMan)-1);
	
	new RandomNumbersArrayRaresHeavy[12] = {423,793,802,882,891,900,909,958,867,863,1071,1100};
	new randomnumRaresHeavy = GetRandomInt(0, sizeof(RandomNumbersArrayRaresHeavy)-1);
		
	new RandomNumbersArrayRaresEngineer[12] = {160,169,423,795,804,884,893,902,911,960,969,1071};
	new randomnumRaresEngineer = GetRandomInt(0, sizeof(RandomNumbersArrayRaresEngineer)-1);

	new RandomNumbersArrayRaresMedic[10] = {423,796,805,885,894,903,912,961,970,1071};
	new randomnumRaresMedic = GetRandomInt(0, sizeof(RandomNumbersArrayRaresMedic)-1);

	new RandomNumbersArrayRaresSniper[11] = {423,792,801,881,890,899,908,957,966,1071,1105};
	new randomnumRaresSniper = GetRandomInt(0, sizeof(RandomNumbersArrayRaresSniper)-1);
		
	new RandomNumbersArrayRaresSpy[12] = {161,423,794,803,883,892,901,910,959,968,1071,1102};
	new randomnumRaresSpy = GetRandomInt(0, sizeof(RandomNumbersArrayRaresSpy)-1);

	new rareChance = GetRandomInt(0,GetConVarInt(sm_servergifts_rarechance));

	AcceptEntityInput(entity, "Kill");
	
	if (TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresScout[randomnumRaresScout]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresScout[randomnumRaresScout]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresScout[randomnumRaresScout]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayScout[randomnumScout]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSniper[randomnumRaresSniper]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSniper[randomnumRaresSniper]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSniper[randomnumRaresSniper]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySniper[randomnumSniper]);
					}
				}
			}
		}		
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{	
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSoldier[randomnumRaresSoldier]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSoldier[randomnumRaresSoldier]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSoldier[randomnumRaresSoldier]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySoldier[randomnumSoldier]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresDemoMan[randomnumRaresDemoMan]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresDemoMan[randomnumRaresDemoMan]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresDemoMan[randomnumRaresDemoMan]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayDemoMan[randomnumDemoMan]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresMedic[randomnumRaresMedic]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresMedic[randomnumRaresMedic]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresMedic[randomnumRaresMedic]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayMedic[randomnumMedic]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresHeavy[randomnumRaresHeavy]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresHeavy[randomnumRaresHeavy]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresHeavy[randomnumRaresHeavy]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayHeavy[randomnumHeavy]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresPyro[randomnumRaresPyro]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresPyro[randomnumRaresPyro]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresPyro[randomnumRaresPyro]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayPyro[randomnumPyro]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSpy[randomnumRaresSpy]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSpy[randomnumRaresSpy]);
						}
						else
						{
						TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresSpy[randomnumRaresSpy]);
						}
						else
						{
						TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArraySpy[randomnumSpy]);
					}
				}
			}
		}
	}
	
	if (TF2_GetPlayerClass(client) == TFClass_Engineer)
	{
		if (IsValidClient(client))
		{
			if (bRareWeapons)
			{
				if (rareChance == GetConVarInt(sm_servergifts_rarechance))
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayRaresEngineer[randomnumRaresEngineer]);
				}
				else
				{
					TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
				}
			}
			else
			{
				TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
			}
		}
		else
		{
			if (bBots)
			{
				if (IsMvM() && bBotsOnlyInMvM)
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresEngineer[randomnumRaresEngineer]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
					}
				}
				else
				{
					if (bRareWeapons)
					{
						if (rareChance == GetConVarInt(sm_servergifts_rarechance))
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayRaresEngineer[randomnumRaresEngineer]);
						}
						else
						{
							TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
						}
					}
					else
					{
						TF2Items_GiveWeapon(client, RandomNumbersArrayEngineer[randomnumEngineer]);
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if (bGiftsOnDeath)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		new deathflags = GetEventInt(event, "death_flags");
		if(IsValidClient(client) && IsValidClient(killer))
		{
			if (deathflags == TF_DEATHFLAG_KILLERDOMINATION || deathflags == TF_DEATHFLAG_ASSISTERDOMINATION || deathflags == TF_DEATHFLAG_KILLERREVENGE || deathflags == TF_DEATHFLAG_ASSISTERREVENGE || deathflags == TF_DEATHFLAG_FIRSTBLOOD)
			{
				new Float:pos[3];
				GetClientAbsOrigin(client, pos);
				createGift(client, pos);
				PrintToChat(killer, "[ServerGifts]: %t", "FoundGift");
			}
		}
	}
}

SetTeleportEndPoint(client) 
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) {   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else {
		CloseHandle(trace);
		return false;
	}
	CloseHandle(trace);
	return true;
}

stock Handle:CreateParticle(String:type[], Float:time, entity, attach=0, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0) {
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle)) {
		new Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);

		if(attach != 0) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
		
			if(attach == 2) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "part%dp@tak");

		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		return CreateTimer(time, DeleteParticle, particle);
	} 
	else {
		LogError("Presents (CreateParticle): Could not create info_particle_system");
	}
	return INVALID_HANDLE;
}

public Action:DeleteParticle(Handle:timer, any:particle) {
	if(IsValidEntity(particle)) {
		decl String:name[32];
		GetEntPropString(particle, Prop_Data, "m_iName", name, 128, 0);
		//makes sure i don't kill off the wrong particle
		if(StrEqual(name, "part%dp@tak")) {
			AcceptEntityInput(particle, "Kill");
		}
	}
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) {
	return entity > GetMaxClients() || !entity;
}

stock bool:IsValidClient(iClient, bool:bReplay = true) 
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:IsMvM(bool:forceRecalc = false)
{
    static bool:found = false;
    static bool:ismvm = false;
    if (forceRecalc)
    {
        found = false;
        ismvm = false;
    }
    if (!found)
    {
        new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
        if (i > MaxClients && IsValidEntity(i)) ismvm = true;
        found = true;
    }
    return ismvm;
}