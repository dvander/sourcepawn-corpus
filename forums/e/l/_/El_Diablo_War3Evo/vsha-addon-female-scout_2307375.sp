// vsha-addon-female-scout.sp

#pragma semicolon 1
#include <sourcemod>
//#include <sdkhooks>
#include <morecolors>
#include <vsha>
#include <vsha_stocks>
#include <vsha_ff2_interface>

public Plugin myinfo =
{
	name 			= "Female Scout",
	author 			= "Valve",
	description 		= "Female Scout",
	version 		= "1.0",
	url 			= "https://forums.alliedmods.net/showthread.php?t=246980"
}

int iThisPlugin = -1; //DO NOT TOUCH THIS, THIS IS USED TO IDENTIFY THIS BOSS PLUGIN.

//#define ThisConfigurationFile "configs/vsha/miku.cfg"

char ScoutModel[PATHX] = "models/player/female_scout/scout.mdl";
//char MikuModelPrefix[PATHX];

bool InRage[PATHX];

//char MIKUTheme[PATHX];

// still need to work on jump charge vs more players == faster jump charge
// also need to send the jump charge new stuff to saxtonhale

#define HALE_JUMPCHARGE			3
#define HALE_JUMPCHARGETIME		100

public void OnAddToDownloads()
{
	//PrecacheModel(file);

	AddFileToDownloadsTable(ScoutModel);
	VSHA_SetPluginModel(iThisPlugin, ScoutModel);
}


//make defines, handles, variables heer lololol
int HaleCharge[PLYR];

float WeighDownTimer = 0.0;
//float RageDist = 800.0;

//int JumpCoolDown[PLYR];

//Handle JumpTimerHandle[PLYR];

int HaleChargeCoolDown[PLYR];

public void OnPluginStart()
{
	CreateConVar("vsha_femscout_version", "1.0", "VSHA FemScout Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void Load_VSHAHooks()
{
	if(!VSHAHookEx(VSHAHook_OnBossIntroTalk, OnBossIntroTalk))
	{
		LogError("Error loading VSHAHook_OnBossIntroTalk forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnPlayerKilledByBoss, OnPlayerKilledByBoss))
	{
		LogError("Error loading VSHAHook_OnPlayerKilledByBoss forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnKillingSpreeByBoss, OnKillingSpreeByBoss))
	{
		LogError("Error loading VSHAHook_OnKillingSpreeByBoss forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossKilled, OnBossKilled))
	{
		LogError("Error loading VSHAHook_OnBossKilled forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossWin, OnBossWin))
	{
		LogError("Error loading VSHAHook_OnBossWin forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossAirblasted, OnBossAirblasted))
	{
		LogError("Error loading VSHAHook_OnBossAirblasted forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossChangeClass, OnChangeClass))
	{
		LogError("Error loading VSHAHook_OnBossChangeClass forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossSetHP, OnBossSetHP))
	{
		LogError("Error loading VSHAHook_OnBossSetHP forwards for Female Scout.");
	}
	//if(!VSHAHookEx(VSHAHook_OnLastSurvivor, OnLastSurvivor))
	//{
		//LogError("Error loading VSHAHook_OnLastSurvivor forwards for Female Scout.");
	//}
	if(!VSHAHookEx(VSHAHook_OnBossTimer, OnBossTimer))
	{
		LogError("Error loading VSHAHook_OnBossTimer forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnPrepBoss, OnPrepBoss))
	{
		LogError("Error loading VSHAHook_OnPrepBoss forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnMusic, OnMusic))
	{
		LogError("Error loading VSHAHook_OnMusic forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossRage, OnBossRage))
	{
		LogError("Error loading VSHAHook_OnBossRage forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_ShowBossHelpMenu, OnShowBossHelpMenu))
	{
		LogError("Error loading VSHAHook_ShowBossHelpMenu forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossStabbedPost, OnBossStabbedPost))
	{
		LogError("Error loading VSHAHook_OnBossStabbedPost forwards for Female Scout.");
	}

	//vsha_ff2_interface
	if(!FF2toVSHAHookEx(FF2toVSHAHook_OnFF2_GetAbilityArgument, OnFF2_GetAbilityArgument))
	{
		LogError("Error loading FF2toVSHAHook_OnFF2_GetAbilityArgument forwards for Female Scout.");
	}
}

public void UnLoad_VSHAHooks()
{
	if(!VSHAUnhookEx(VSHAHook_OnBossIntroTalk, OnBossIntroTalk))
	{
		LogError("Error unloading VSHAHook_OnBossIntroTalk forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnPlayerKilledByBoss, OnPlayerKilledByBoss))
	{
		LogError("Error unloading VSHAHook_OnPlayerKilledByBoss forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnKillingSpreeByBoss, OnKillingSpreeByBoss))
	{
		LogError("Error unloading VSHAHook_OnKillingSpreeByBoss forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossKilled, OnBossKilled))
	{
		LogError("Error unloading VSHAHook_OnBossKilled forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossWin, OnBossWin))
	{
		LogError("Error unloading VSHAHook_OnBossWin forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossAirblasted, OnBossAirblasted))
	{
		LogError("Error unloading VSHAHook_OnBossAirblasted forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossChangeClass, OnChangeClass))
	{
		LogError("Error loading VSHAHook_OnBossChangeClass forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossSetHP, OnBossSetHP))
	{
		LogError("Error unloading VSHAHook_OnBossSetHP forwards for Female Scout.");
	}
	//if(!VSHAUnhookEx(VSHAHook_OnLastSurvivor, OnLastSurvivor))
	//{
		//LogError("Error unloading VSHAHook_OnLastSurvivor forwards for Female Scout.");
	//}
	if(!VSHAUnhookEx(VSHAHook_OnBossTimer, OnBossTimer))
	{
		LogError("Error unloading VSHAHook_OnBossTimer forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnPrepBoss, OnPrepBoss))
	{
		LogError("Error unloading VSHAHook_OnPrepBoss forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnMusic, OnMusic))
	{
		LogError("Error unloading VSHAHook_OnMusic forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossRage, OnBossRage))
	{
		LogError("Error unloading VSHAHook_OnBossRage forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_ShowBossHelpMenu, OnShowBossHelpMenu))
	{
		LogError("Error unloading VSHAHook_ShowBossHelpMenu forwards for Female Scout.");
	}
	if(!VSHAUnhookEx(VSHAHook_OnBossStabbedPost, OnBossStabbedPost))
	{
		LogError("Error unloading VSHAHook_OnBossStabbedPost forwards for Female Scout.");
	}
}

public void OnAllPluginsLoaded()
{
	iThisPlugin = VSHA_RegisterBoss("femscout","Female Scout");

	if(!VSHAHookEx(VSHAHook_AddToDownloads, OnAddToDownloads))
	{
		LogError("Error loading VSHAHook_AddToDownloads forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnBossSelected, OnBossSelected))
	{
		LogError("Error loading VSHAHook_OnBossSelected forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnGameOver, OnGameOver))
	{
		LogError("Error loading VSHAHook_OnGameOver forwards for Female Scout.");
	}
	/*
	if(!VSHAHookEx(VSHAHook_OnConfiguration_Load_Sounds, OnConfiguration_Load_Sounds))
	{
		LogError("Error loading VSHAHook_OnConfiguration_Load_Sounds forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnConfiguration_Load_Materials, OnConfiguration_Load_Materials))
	{
		LogError("Error loading VSHAHook_OnConfiguration_Load_Materials forwards for Female Scout.");
	}
	if(!VSHAHookEx(VSHAHook_OnConfiguration_Load_Models, OnConfiguration_Load_Models))
	{
		LogError("Error loading VSHAHook_OnConfiguration_Load_Models forwards for Female Scout.");
	}*/

	// LoadConfiguration ALWAYS after VSHAHook
	//VSHA_LoadConfiguration("configs/vsha/femscout.cfg");
}
public void OnMapEnd()
{
	WeighDownTimer = 0.0;
	//RageDist = 800.0;

	LoopMaxPLYR(player)
	{
		HaleCharge[player] = 0;
	}
}
public void OnChangeClass(int iBossArrayListIndex, Event event, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;

	if (TF2_GetPlayerClass(iiBoss) != TFClass_Scout) TF2_SetPlayerClass(iiBoss, TFClass_Scout, _, false);
	TF2_RemovePlayerDisguise(iiBoss);
}
public void OnPlayerKilledByBoss(int iBossArrayListIndex, int iiBoss, int attacker)
{
	if (iThisPlugin != iBossArrayListIndex) return;
/*
	char playsound[PATHX];

	if (!GetRandomInt(0, 2) && VSHA_GetAliveRedPlayers() != 1)
	{
		strcopy(playsound, PLATFORM_MAX_PATH, MikuKill[GetRandomInt(0, sizeof(MikuKill)-1)]);
	}
	if ( !StrEqual(playsound, "") ) EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	*/
}
public void OnKillingSpreeByBoss(int iBossArrayListIndex, int iiBoss, int attacker)
{
	if (iThisPlugin != iBossArrayListIndex) return;
/*
	char playsound[PATHX];

	strcopy(playsound, PLATFORM_MAX_PATH, MikuSpree[GetRandomInt(0, sizeof(MikuSpree)-1)]);

	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, attacker, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	*/
}
public void OnBossKilled(int iBossArrayListIndex, int iiBoss, int attacker) //victim is boss
{
	if (iThisPlugin != iBossArrayListIndex) return;
/*
	char playsound[PATHX];

	strcopy(playsound, PLATFORM_MAX_PATH, MikuFail[GetRandomInt(0, sizeof(MikuFail)-1)]);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	*/
}
public void OnBossWin(int iBossArrayListIndex, Event event, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;
/*
	char playsound[PATHX];

	strcopy(playsound, PLATFORM_MAX_PATH, MikuWin[GetRandomInt(0, sizeof(MikuWin)-1)]);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if ( !IsClientValid(i) ) continue;
		StopSound(i, SNDCHAN_AUTO, MIKUTheme);
	}
	*/
}
public void OnGameOver() // best play to reset all variables
{
	LoopMaxPLYR(players)
	{
		HaleCharge[players]=0;
		InRage[players]=false;

		//if(ValidPlayer(players))
		//{
			//StopSound(players, SNDCHAN_AUTO, MIKUTheme);
		//}
	}
	// Dynamically unload private forwards
	//UnLoad_VSHAHooks();
}
public void OnBossAirblasted(int iBossArrayListIndex, Event event, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;
	//float rage = 0.04*RageDMG;
	//HaleRage += RoundToCeil(rage);
	//if (HaleRage > RageDMG) HaleRage = RageDMG;
	VSHA_SetBossRage(iiBoss, VSHA_GetBossRage(iiBoss)+4.0); //make this a convar/cvar!
}
public void OnBossSelected(int iBossArrayListIndex, int iiBoss)
{
	if(iBossArrayListIndex!=iThisPlugin)
	{
		// reset variables
		HaleCharge[iiBoss]=0;
		VSHA_SetBossRageLimit(iiBoss, 999999.0);
		InRage[iiBoss]=false;
		return;
	}

	//CPrintToChatAll("%s, Miku Boss Selected!",VSHA_COLOR);

	// Dynamically load private forwards
	VSHA_SetBossRageLimit(iiBoss, 100.0);

	Load_VSHAHooks();
}
public void OnBossIntroTalk()
{
	/*
	char playsound[PATHX];

	strcopy(playsound, PLATFORM_MAX_PATH, MikuStart[GetRandomInt(0, sizeof(MikuStart)-1)]);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	*/
}
public Action OnBossSetHP(int iBossArrayListIndex, int BossEntity, int &BossMaxHealth)
{
	if (iThisPlugin != iBossArrayListIndex) return Plugin_Continue;
	BossMaxHealth = HealthCalc( 760.8, float( VSHA_GetPlayerCount() ), 1.0, 1.0341, 2046.0 );
	//VSHA_SetBossMaxHealth(Hale[BossEntity], BossMax);
	return Plugin_Changed;
}
/*
public void OnLastSurvivor()
{

	char playsound[PATHX];

	strcopy(playsound, PLATFORM_MAX_PATH, MikuLast[GetRandomInt(0, sizeof(MikuLast)-1)]);

	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, NULL_VECTOR, NULL_VECTOR, false, 0.0);
}
*/
public void OnBossTimer(int iBossArrayListIndex, int iiBoss, int &curHealth, int &curMaxHp, int buttons, Handle hHudSync, Handle hHudSync2)
{
	if (iThisPlugin != iBossArrayListIndex) return;

	//char playsound[PATHX];
	float speed;
	//int curHealth = VSHA_GetBossHealth(iiBoss), curMaxHp = VSHA_GetBossMaxHealth(iiBoss);
	// temporary health fix
	if (curHealth < 0)
	{
		ForcePlayerSuicide(iiBoss);
		return;
	}
	if(GetClientHealth(iiBoss) != curHealth)
	{
		SetEntityHealth(iiBoss,curHealth);
	}
	if (curHealth <= curMaxHp) speed = 340.0 + 0.7 * (100.0-float(curHealth)*100.0/float(curMaxHp)); //convar/cvar for speed here!
	SetEntPropFloat(iiBoss, Prop_Send, "m_flMaxspeed", speed);

	//int buttons = GetClientButtons(iiBoss);
	//if ( ((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && HaleCharge[iiBoss] >= 0 )
	if (HaleChargeCoolDown[iiBoss] <= GetTime())
	{
		if ( ((buttons & IN_DUCK) || (buttons & IN_ATTACK2)) && HaleCharge[iiBoss] >= 0 )
		{
			if ((HaleCharge[iiBoss] + HALE_JUMPCHARGE) < HALE_JUMPCHARGETIME) HaleCharge[iiBoss] += HALE_JUMPCHARGE;
			else HaleCharge[iiBoss] = HALE_JUMPCHARGETIME;
			//if (!(buttons & IN_SCORE))
			if (!(buttons & IN_SCORE))
			{
				//if(!InitHaleTimer[iiBoss])
				//{
					SetHudTextParams(-1.0, 0.70, HudTextScreenHoldTime, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(iiBoss, hHudSync, "Jump Charge: %i% ", HaleCharge[iiBoss]);
					//InitHaleTimer[iiBoss]=true;
				//}
			}
		}
		// 5 * 60 = 300
		// 5 * .2 = 1 second, so 5 times number of seconds equals number for HaleCharge after superjump
		// 300 = 1 minute wait
		//float ExtraBoost = float(HaleCharge[iiBoss]) * 2;
		float ExtraBoost = float(HaleCharge[iiBoss]) / 10;
		if ( HaleCharge[iiBoss] > 1 && SuperJump(iiBoss, ExtraBoost, -15.0, HaleCharge[iiBoss], -150) ) //put convar/cvar for jump sensitivity here!
		{
			HaleChargeCoolDown[iiBoss] = GetTime()+3;
			//strcopy(playsound, PLATFORM_MAX_PATH, MikuJump[GetRandomInt(0, sizeof(MikuJump)-1)]);
			//EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, NULL_VECTOR, NULL_VECTOR, false, 0.0);
		}
	}
	else
	{
		HaleCharge[iiBoss] = 0;
		if (!(buttons & IN_SCORE))
		{
			//if(!InitHaleTimer[iiBoss])
			//{
				SetHudTextParams(-1.0, 0.75, HudTextScreenHoldTime, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(iiBoss, hHudSync2, "Mini-Super Jump will be ready again in: %d ", (HaleChargeCoolDown[iiBoss]-GetTime()));
				//InitHaleTimer[iiBoss]=true;
			//}
		}
	}

	int iAlivePlayers;
	LoopAlivePlayers(alivePlayers)
	{
		++iAlivePlayers;
	}
	float AddToRage = 0.0;//VSHA_GetBossRage(iiBoss);

	if (iAlivePlayers > 12)
	{
		//PrintCenterTextAll("Saxton Hale's Current Health is: %i of %i", curHealth, curMaxHp);
		AddToRage += 0.001;
		//VSHA_SetBossRage(iiBoss, VSHA_GetBossRage(iiBoss)+0.2);
	}
	else if(iAlivePlayers > 1)
	{
		//AddToRage += (float((MaxClients + 1) - iAlivePlayers) * 0.001);
		AddToRage += float(iAlivePlayers) * 0.001;
	}
	int iGetOtherTeam = GetClientTeam(iiBoss) == 2 ? 3:2;
	if ( OnlyScoutsLeft(iGetOtherTeam) )
	{
		AddToRage += 0.001;
		//VSHA_SetBossRage(iiBoss, VSHA_GetBossRage(iiBoss)+0.5);
	}

	if(AddToRage > 0)
	{
		VSHA_SetBossRage(iiBoss, (VSHA_GetBossRage(iiBoss)+AddToRage));
	}

	//VSHA_SetBossRage(iiBoss, VSHA_GetBossRage(iiBoss)+1.0);

	if ( !(GetEntityFlags(iiBoss) & FL_ONGROUND) ) WeighDownTimer += 0.2;
	else WeighDownTimer = 0.0;

	if ( (buttons & IN_DUCK) && Weighdown(iiBoss, WeighDownTimer, 60.0, 0.0) )
	{
		//CPrintToChat(client, "{olive}[VSHE]{default} You just used your weighdown!");
		//all this just to do a cprint? It's not like weighdown has a limit...
	}
}
public void OnPrepBoss(int iBossArrayListIndex, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;

	TF2_SetPlayerClass(iiBoss, TFClass_Scout, _, false);
	HaleCharge[iiBoss] = 0;

	TF2_RemoveAllWeapons2(iiBoss);
	TF2_RemovePlayerDisguise(iiBoss);

	//bool pri = IsValidEntity(GetPlayerWeaponSlot(iiBoss, TFWeaponSlot_Primary));
	//bool sec = IsValidEntity(GetPlayerWeaponSlot(iiBoss, TFWeaponSlot_Secondary));
	//bool mel = IsValidEntity(GetPlayerWeaponSlot(iiBoss, TFWeaponSlot_Melee));

	//if (pri || sec || !mel)
	//{
	TF2_RemoveAllWeapons2(iiBoss);
	char attribs[PATH];
	Format(attribs, sizeof(attribs), "68 ; -2 ; 241 ; 0 ; 275 ; 1 ; 280 ; 26 ; 547 ; 0 ; 199 ; 0 ; 712 ; 1");
	SpawnWeapon(iiBoss, "tf_weapon_grapplinghook", 1152, 100, 4, attribs);

	Format(attribs, sizeof(attribs), "3 ; 0.5 ; 5 ; 1.75 ; 68 ; -2 ; 112 ; 9 ; 128 ; 1 ; 137 ; 1.5 ; 138 ; 0 ; 366 ; 5 ; 391 ; 1.75");
	SpawnWeapon(iiBoss, "tf_weapon_handgun_scout_secondary", 773, 100, 4, attribs);

	Format(attribs, sizeof(attribs), "1 ; 0.4 ; 38 ; 1 ; 62 ; 0.5 ; 68 ; -2 ; 278 ; 2.5 ; 279 ; 2 ; 326 ; 1.75 ; 2025 ; 2 ; 2014 ; 1");
	int SaxtonWeapon = SpawnWeapon(iiBoss, "tf_weapon_bat_wood", 44, 100, 4, attribs);
	// if show = 0:
	//SetEntProp(BossWeapon, Prop_Send, "m_iWorldModelIndex", -1);
	//SetEntProp(BossWeapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
	//SetEntPropFloat(BossWeapon, Prop_Send, "m_flModelScale", 0.001);

	SetEntPropEnt(iiBoss, Prop_Send, "m_hActiveWeapon", SaxtonWeapon);
	//}
}
public Action OnMusic(int iBossArrayListIndex, int iiBoss, char BossTheme[PATHX], float &time)
{
	if (iThisPlugin != iBossArrayListIndex) return Plugin_Continue;

	if (iiBoss<0)
	{
		return Plugin_Continue;
	}

	BossTheme = "";
	time = 0.0;

	return Plugin_Continue;
}
public void OnBossRage(int iBossArrayListIndex, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;
	if(InRage[iiBoss]) return;

	// Helps prevent multiple rages
	InRage[iiBoss] = true;
	//char playsound[PATHX];
	//DP("iiBoss = %d",iiBoss);
	//float pos[3];
	//GetEntPropVector(iiBoss, Prop_Send, "m_vecOrigin", pos);
	//pos[2] += 20.0;
	//TF2_AddCondition(iiBoss, view_as<TFCond>(42), 4.0);
	//strcopy(playsound, PLATFORM_MAX_PATH, MikuRage[GetRandomInt(1, sizeof(MikuRage)-1)]);
	//EmitSoundToAll(playsound, iiBoss, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, pos, NULL_VECTOR, true, 0.0);
	//EmitSoundToAll(playsound, iiBoss, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, pos, NULL_VECTOR, true, 0.0);
	CreateTimer(0.6, UseRage, iiBoss);
}
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(VSHA_GetBossArrayListIndex(client)!=iThisPlugin) return;

	switch (condition)
	{
		case TFCond_Jarated:
		{
			VSHA_SetBossRage(client, VSHA_GetBossRage(client)-8.0);
			TF2_RemoveCondition(client, condition);
		}
		case TFCond_MarkedForDeath:
		{
			VSHA_SetBossRage(client, VSHA_GetBossRage(client)-5.0);
			TF2_RemoveCondition(client, condition);
		}
		case TFCond_Disguised: TF2_RemoveCondition(client, condition);
	}
	if (TF2_IsPlayerInCondition(client, view_as<TFCond>(42))
		&& TF2_IsPlayerInCondition(client, TFCond_Dazed)) TF2_RemoveCondition(client, TFCond_Dazed);
}

public void OnBossStabbedPost(int iBossArrayListIndex, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;

	//char playsound[PATHX];
	//strcopy(playsound, PLATFORM_MAX_PATH, MikuPain[GetRandomInt(0, sizeof(MikuPain)-1)]);
	//EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, NULL_VECTOR, NULL_VECTOR, false, 0.0);
	//EmitSoundToAll(playsound, _, SNDCHAN_VOICE, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, iiBoss, NULL_VECTOR, NULL_VECTOR, false, 0.0);
}

public Action UseRage(Handle hTimer, any client)
{
	//float pos[3], pos2[3];
	//int i;
	//float distance;
	if (!IsValidClient(client)) return Plugin_Continue;

	if(InRage[client]) return Plugin_Stop;

	if (!GetEntProp(client, Prop_Send, "m_bIsReadyToHighFive") && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner")))
	{
		TF2_RemoveCondition(client, TFCond_Taunting);
	}

	CPrintToChat(client,"%s {red}RAGE!!",VSHA_COLOR);

	FF2_DoAbility(client, "shadow93_bosses", "boss_config", 0, 0);

	InRage[client] = false;

	return Plugin_Continue;
}

public Action OnFF2_GetAbilityArgument(int iiboss, const char[] pluginName, const char[] abilityName, int argument, int &ReturnValue)
{
	if (iThisPlugin != VSHA_GetBossArrayListIndex(iiboss)) return Plugin_Continue;

	if(StrEqual(abilityName,"boss_config"))
	{
		switch(argument)
		{
			case 1: ReturnValue = 5; // ReturnValue
		}
	}

	return Plugin_Handled;
}

// stocks
stock bool OnlyScoutsLeft( int iTeam )
{
	for (int client; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == iTeam)
		{
			if (TF2_GetPlayerClass(client) != TFClass_Scout) return false;
		}
	}
	return true;
}

/*
// LOAD CONFIGURATION
public void OnConfiguration_Load_Sounds(char[] cFile, char[] skey, char[] value, bool &bPreCacheFile, bool &bAddFileToDownloadsTable)
{
	if(!StrEqual(cFile, ThisConfigurationFile)) return;

	if(StrEqual(skey, "MIKUTheme"))
	{
		strcopy(STRING(MIKUTheme), value);
		bPreCacheFile = true;
		bAddFileToDownloadsTable = true;
	}
	else if(StrEqual(skey, "timeleap"))
	{
		strcopy(STRING(timeleap), value);
		bPreCacheFile = true;
		bAddFileToDownloadsTable = true;
	}

	if(bPreCacheFile || bAddFileToDownloadsTable)
	{
		PrintToServer("Loading Sounds %s = '%s'",skey,value);
	}
}
public void OnConfiguration_Load_Materials(char[] cFile, char[] skey, char[] value, bool &bPrecacheGeneric, bool &bAddFileToDownloadsTable)
{
	if(!StrEqual(cFile, ThisConfigurationFile)) return;

	if(StrEqual(skey, "MaterialPrefix"))
	{
		char s[PATHX];
		char extensionsb[][] = { ".vtf", ".vmt" };

		for (int i = 0; i < sizeof(extensionsb); i++)
		{
			Format(s, PATHX, "%s%s", value, extensionsb[i]);
			if ( FileExists(s, true) )
			{
				AddFileToDownloadsTable(s);

				PrintToServer("Loading Materials %s",s);
			}
		}
	}
}
public void OnConfiguration_Load_Models(char[] cFile, char[] skey, char[] value, bool &bPreCacheModel, bool &bAddFileToDownloadsTable)
{
	if(!StrEqual(cFile, ThisConfigurationFile)) return;

	if(StrEqual(skey, "MikuModel"))
	{
		TrimString(value);
		strcopy(STRING(MikuModel), value);
		bPreCacheModel = true;
		bAddFileToDownloadsTable = true;
		// For Model Manager:
		VSHA_SetPluginModel(iThisPlugin, MikuModel);
	}
	else if(StrEqual(skey, "MikuModelPrefix"))
	{
		char s[PATHX];
		char extensions[][] = { ".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy" };

		for (int i = 0; i < sizeof(extensions); i++)
		{
			Format(s, PATHX, "%s%s", MikuModelPrefix, extensions[i]);
			if ( FileExists(s, true) )
			{
				AddFileToDownloadsTable(s);
				PrintToServer("Loading Model %s = %s",skey,value);
			}
		}
	}
	if(bPreCacheModel || bAddFileToDownloadsTable)
	{
		PrintToServer("Loading Model %s = %s",skey,value);
	}
}
*/


// Just in case you want to have extra configurations for your sub plugin.
// This makes loading configurations easier for you.
// Keeping all your configurations for your sub plugin in one location!
/*
public void VSHA_OnConfiguration_Load_Misc(char[] cFile, char[] skey, char[] value)
{
* if(!StrEqual(cFile, ThisConfigurationFile)) return;
}
*/


// Is triggered by VSHA engine when a boos needs a help menu
public void OnShowBossHelpMenu(int iBossArrayListIndex, int iiBoss)
{
	if (iThisPlugin != iBossArrayListIndex) return;

	if(ValidPlayer(iiBoss))
	{
		Handle panel = CreatePanel();
		char s[512];
		Format(s, 512, "Female Scout:\n''D-Do you have any idea, any idea who I am? I'm a force a' nature!''\nNo Super Jump! Use your multi-jump & grapple hook!\nUse your pistol to take out engy nests & stun airborne targets!\nUse your baseballs to take out long distance targets!\nWeigh-down: in midair, look down and crouch.\nRage(Random Scattergun + Buff): Call for medic when Rage Meter is full.");
		SetPanelTitle(panel, s);
		DrawPanelItem(panel, "Exit");
		SendPanelToClient(panel, iiBoss, HintPanelH, 60);
		CloseHandle(panel);
	}
}

public int HintPanelH(Handle menu, MenuAction action, int param1, int param2)
{
	if (!ValidPlayer(param1)) return;
	//if (action == MenuAction_Select || (action == MenuAction_Cancel && param2 == MenuCancel_Exit)) VSHFlags[param1] |= VSHFLAG_CLASSHELPED;
	return;
}

