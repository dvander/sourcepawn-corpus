/*
  //=========================================================================================================\\
 //											G L O B A L  S T U F F											  \\	
//=============================================================================================================\\	
*/
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>



#pragma semicolon 1

#define PLUGIN_VERSION "2.0.2.1 [DEV]"
#define PLUGIN_AUTHOR "daneleo, Original Author noodleboy347"
#define PLUGIN_NAME "[TF2] Premium Mod Beta"
#define PLUGIN_URL ""
#define PLUGIN_DESCRIPTION "Extra abilities for donators or special members"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

#define PREMIUMFLAG ADMFLAG_CUSTOM1
#define ROOTFLAG ADMFLAG_ROOT

new Handle:cvar_enable;
new Handle:cvar_ads_enable;
new Handle:cvar_ads_int;
new Handle:cvar_welcomemsg;
new Handle:cvar_speed;
new Handle:cvar_gravity;
new Handle:cvar_hpboost;
new Handle:cvar_clip;
new Handle:cvar_kill_boost;
new Handle:cvar_trial_timelimit;
new Handle:cvar_kill_assist;
new Handle:cvar_color;
new Handle:cvar_fov;
new Handle:cvar_defaultfov;
new Handle:cvar_dark;
//new Handle:cvar_glow;
new Handle:cvar_stunballs;
new Handle:cvar_tag;
new Handle:cvar_jarates;
new Handle:cvar_uber;
new Handle:cvar_respawn;
new Handle:cvar_DisplayPremFeatures;
new Handle:cvar_swapteams;
new Handle:cvar_trial;
new Handle:cvar_cloak;
new Handle:cvar_metal;
new Handle:cvar_mysql;
new Handle:cvar_fakekill;
new Handle:cvar_firearrows;
new Handle:BunnyIncrement = INVALID_HANDLE;
new Handle:cvar_bhop;
new Handle:cvar_pyrofly;
new Handle:cvar_teleport;
new Handle:cvar_playerJoinAnnounce;

new cEnable;
new String:usedTrial[32];
new cTeleport;
new String:TAG[100];
new cAdsEnable;
new cFakeKill;
new cMySql;
new Float:cAdsInterval;
new cWelcomeMessage;
new cSpeed;
new Float:cGravity;
new cHPBoost;
new cClip;
new cKillBoost;
new cCloak;
new cKillAssist;
new cColor;
new cFireArrows;
new cFov;
new Float:cTrialTimeLimit;
new cDefaultFov;
new cDark;
//new cGlow;
new cStunballs;
new cJarates;
new Float:cUber;
new cRespawn;
new cSwap;
new DPFeatures;
new cTrial;
new cBhop;
new cPyrofly;
new cMetal;
new String:TempString[32];
new Float:EyeAngle[3];
new Float:PlayerVel[3];
new Float:TrimpVel[3];
new Float:PlayerSpeed[1];
new Float:PlayerSpeedLastTime[1];
new GroundEntity;
new CanDJump[32];
new InTrimp[32];
new WasInJumpLastTime[32];
new WasOnGroundLastTime[32];
new Float:VelLastTime[32][3];
new cPremJoin;

new colorred[MAXPLAYERS+1] = 255;
new colorgreen[MAXPLAYERS+1] = 255;
new colorblue[MAXPLAYERS+1] = 255;

//new g_Ent[MAXPLAYERS+1];



new ArenaMap;


new Handle:pWelcomeTimer[MAXPLAYERS+1];
new Handle:tTrial[MAXPLAYERS+1];
new Handle:DatabaseConnection;

//new bool:pGlow[MAXPLAYERS+1];
new bool:pDark[MAXPLAYERS+1];
new bool:pFirstSpawn[MAXPLAYERS+1];
new bool:pTrial[MAXPLAYERS+1];

new Float:pSpeed[MAXPLAYERS+1];
new Float:prem_premiumLocation[MAXPLAYERS+1][3];
new Handle:pTrialCookie = INVALID_HANDLE;

new String:Error[200];

new pFov[MAXPLAYERS+1];
new offsFOV;

new Float:TrialTimer[MAXPLAYERS+1];

new Float:days; // Convert seconds to days, hours, minutes, seconds
new Float:hrs;
new Float:mins;
new Float:sec;

new String:daysleft[9999999];
new String:hrsleft[9999999];
new String:minleft[999999];
new String:secleft[9999999];

new daysleftint;
new hrsleftint;
new minleftint;
new secleftint;
/*
  //=========================================================================================================\\
 //										S P E E D  S E T T I N G S											  \\	
//=============================================================================================================\\
*/	
new Handle:cvar_Heavy;
new Float:HeavySpeed = 230.0;

new Handle:cvar_HeavySpin;
new Float:HeavySlow = 120.0;

new Handle:cvar_Scout;
new Float:ScoutSpeed = 400.0;

new Handle:cvar_Medic;
new Float:MedicSpeed = 320.0;

new Handle:cvar_Solider;
new Float:SoldierSpeed = 240.0;

new Handle:cvar_Spy;
new Float:SpySpeed = 300.0;

new Handle:cvar_Demoman;
new Float:DemomanSpeed = 280.0;

new Handle:cvar_Sniper;
new Float:SniperSpeed = 300.0;

new Handle:cvar_Pyro;
new Float:PyroSpeed = 300.0;

new Handle:cvar_Engineer;
new Float:EngineerSpeed = 300.0;
/*
  //=========================================================================================================\\
 //											P L U G I N  I N F O											  \\	
//=============================================================================================================\\	
*/
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}
/*
  //=========================================================================================================\\
 //							R E G I S T E R  C V A R S	&  C O N S O L E  C V A R S							  \\	
//=============================================================================================================\\
*/	
public OnPluginStart()
{
	mySQL_connect(); // Mysql
/*	
  //=========================================================================================================\\
 //								  R E G I S T E R  C H A T  C O M M A N D S					     			  \\	
//=============================================================================================================\\
*/	
	RegConsoleCmd("trial", Say);
	RegConsoleCmd("save_loc", Save_Loc);
	RegConsoleCmd("load_loc", Load_Loc);
	RegConsoleCmd("premium_fov", Command_Fov);
	RegConsoleCmd("dark", Command_Dark);
	//RegConsoleCmd("glow", Command_Glow);
	RegConsoleCmd("swapteam", Command_Swap);
	RegConsoleCmd("colorme", Command_color);
	RegConsoleCmd("premadduser", Command_AddUserMysql);
	RegConsoleCmd("premremuser", Command_removeUserMysql);
/*	
  //=========================================================================================================\\
 //										A D M I N  C O M M A N D S	        		 						  \\	
//=============================================================================================================\\
*/	
	RegAdminCmd("prem_reload", Command_Reload, ADMFLAG_ROOT);
	RegAdminCmd("createtrial", Command_CreateTrial, ADMFLAG_ROOT);
	RegAdminCmd("resettrial", Command_ResetTrial, ADMFLAG_ROOT);
	RegAdminCmd("premium_database_create", create_PremDatabase, ADMFLAG_ROOT);
/*	
  //=========================================================================================================\\
 //										R E G I S T E R  C V A R S											  \\	
//=============================================================================================================\\	
*/
	CreateConVar("premium_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	cvar_tag = CreateConVar("premium_tag", "{green}[{lightgreen}PREMIUM{green}]{default}", "Changes the Prefix");
	cvar_enable = CreateConVar("premium_enable", "1", "Enable the plugin");
	cvar_mysql = CreateConVar("premium_use_mysql", "0", "Enables mySQL database");
	cvar_teleport = CreateConVar("premium_teleport_enable", "1", "Enables the use of save_loc and load_loc");
	cvar_ads_enable = CreateConVar("premium_advertisement_enable", "1", "Enables advertisements");
	cvar_ads_int = CreateConVar("premium_advertisement_interval", "300", "Advertisement interval");
	cvar_welcomemsg = CreateConVar("premium_welcome_message", "1", "Welcome message for Premium Members");
	cvar_gravity = CreateConVar("premium_gravity_mult", "0.75", "Gravity multiplier");
	cvar_hpboost = CreateConVar("premium_health_boost", "15", "Extra health for players on spawn");
	cvar_clip = CreateConVar("premium_extra_clip", "1", "Extra bullets in clip on spawn");
	cvar_kill_boost = CreateConVar("premium_healthbonus_kill", "25", "Amount of health to boost on kill");
	cvar_kill_assist = CreateConVar("premium_healthbonus_assist", "25", "Health to boost on assist");
	cvar_color = CreateConVar("premium_color", "1", "Render color of player");
	cvar_speed = CreateConVar("premium_speed", "1", "Enable player running");
	cvar_fov = CreateConVar("premium_fov_enable", "1", "Allow usage of fov command");
	cvar_defaultfov = CreateConVar("premium_fov_default", "100", "Default fov");
	cvar_dark = CreateConVar("premium_dark", "1", "Allow usage of dark command");
	//cvar_glow = CreateConVar("premium_glow", "0", "Allow usage of glow command(BETA TESTING)");
	cvar_stunballs = CreateConVar("premium_stunballs", "1", "Amount of stunballs for Scouts");
	cvar_jarates = CreateConVar("premium_jarates", "1", "Amount of Jarates for Snipers");
	cvar_uber = CreateConVar("premium_ubercharge", "1", "Percentage of ubercharge for Medics");
	cvar_respawn = CreateConVar("premium_instant_respawn", "1", "Instantly respawn after death");
	cvar_swapteams = CreateConVar("premium_swapteams", "1", "Allow usage of the swapteams command");
	cvar_firearrows = CreateConVar("premium_firearrows", "1", "Makes huntman arrows on fire without the need of it being lit");
	cvar_trial = CreateConVar("premium_trial", "1", "Allow players to use trials");
	cvar_trial_timelimit = CreateConVar("premium_trial_timelimit", "900", "Time in seconds for trial time limit");
	cvar_DisplayPremFeatures = CreateConVar("premium_displaypremfeatures", "1", "Displays the premium features on spawn");
	cvar_metal = CreateConVar("premium_metal", "200", "Amount of metal to spawn with");
	BunnyIncrement = CreateConVar("premium_bhop_Increment", "1.15", "Changes bunnyhop speedincrease");
	cvar_pyrofly = CreateConVar("premium_pyrofly_enabled", "1", "Allow pyro to fly with flamethrower.");
	cvar_fakekill = CreateConVar("premium_deadringer", "1", "Whether or not to detect Dead Ringer kills");
	cvar_bhop = CreateConVar("premium_bhop_enabled", "1", "enables bunnyhopping/trimping/bhopdoublejump");
	cvar_cloak = CreateConVar("premium_cloak","1","Infinite cloak");
	cvar_playerJoinAnnounce = CreateConVar("premium_premiumjoin_announce","1","displays player is premium on game join");
	
	cvar_Heavy = CreateConVar("premium_speedmod_heavy","230","Changes the max speed of the heavy class");
	cvar_HeavySpin = CreateConVar("premium_speedmod_heavyattack","120","Changes the max speed of the heavy class while minigun is active");
	cvar_Medic = CreateConVar("premium_speedmod_medic","320","Changes the max speed of the Medic lass");
	cvar_Pyro = CreateConVar("premium_speedmod_pyro","300","Changes the max speed of the Pyro class");
	cvar_Engineer = CreateConVar("premium_speedmod_engineer","300","Changes the max speed of the Engineer class");
	cvar_Demoman = CreateConVar("premium_speedmod_demoman","280","Changes the max speed of the demoman class");
	cvar_Solider = CreateConVar("premium_speedmod_soldier","240","Changes the max speed of the solider class");
	cvar_Scout = CreateConVar("premium_speedmod_scout","400","Changes the max speed of the scout class");
	cvar_Sniper = CreateConVar("premium_speedmod_sniper","300","Changes the max speed of the sniper class");
	cvar_Spy = CreateConVar("premium_speedmod_spy","300","Changes the max speed of the spy class");
/*	
  //=========================================================================================================\\
 //													O T H E R												  \\	
//=============================================================================================================\\	
*/
	HookEvent("player_death", Player_Death);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_changeclass", Player_Change);
	HookEvent("post_inventory_application", Player_Locker);
	
	pTrialCookie = RegClientCookie("UsedTrial", "PremiumTrial", CookieAccess_Protected);
	AutoExecConfig();
	LoadTranslations("premium.phrases");
	offsFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	ReloadConvars();
	CreateTimer(cAdsInterval, Timer_Ad);
}
/*
  //=========================================================================================================\\
 //										A R E N A  M O D E  C H E C K										  \\	
//=============================================================================================================\\	
*/
public OnMapStart()
{
	if(GameRules_GetProp("m_nGameType") == 4)
	{
	 ArenaMap = 1;
	}
	else
	{
	 ArenaMap = 0;	
	}
}

public OnConfigsExecuted()
{
	ReloadConvars();
}
/*
  //=========================================================================================================\\
 //							O N  P L A Y E R  J O I N  P R E M I U M  C H E C K								  \\	
//=============================================================================================================\\
*/	
public OnClientPostAdminCheck(client)
{
	if(cEnable && (GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG))
	{
		new String:Name[25];
		GetClientName(client, Name , sizeof(Name));
		//pGlow[client] = false;
		pDark[client] = false;
		pFirstSpawn[client] = true;
		pFov[client] = cDefaultFov;
		pTrial[client] = false;
		if(cPremJoin)
		{
			CPrintToChatAll("%s %s is a premium member!",TAG, Name);
		}
	}
	else
	{
		//pGlow[client] = false;
		pDark[client] = false;
		pFirstSpawn[client] = true;
		pFov[client] = cDefaultFov;
		pTrial[client] = false;
	}
}
/*
  //=========================================================================================================\\
 //											A D V E R T  T I M E R											  \\	
//=============================================================================================================\\
*/	
public Action:Timer_Ad(Handle:timer, any:client)
{
	if(cEnable && cAdsEnable && IsValidEntity(client))
	{
		//CPrintToChatAll("%t", "Advertisement"); - Non-Beta
		CPrintToChatAll("%s This server is running a development build of premium! Some features may be broke! Type !trial to get started", TAG);
		CreateTimer(cAdsInterval, Timer_Ad);
	}
}


public Action:Timer_CheckState(Handle:HeavyTimer, any:client)
{
	if(TF2_GetPlayerClass(client) != TFClass_Heavy)
		return Plugin_Stop;
		
		
	if(GetClientButtons(client) & IN_ATTACK || GetClientButtons(client) & IN_ATTACK2)
	{
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", HeavySlow);
		CreateTimer(2.0, Timer_CheckState, client);
	} else {
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", HeavySpeed);	
		CreateTimer(2.0, Timer_CheckState, client);
	}
	return Plugin_Stop;
}

/*
  //=========================================================================================================\\
 //										O N  P L A Y E R  C H A N G E										  \\	
//=============================================================================================================\\	
*/
public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidEntity(client) && IsPlayerAlive(client) && IsClientInGame(client))
	{
		if((IsValidEntity(client) && GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG))
		{
			Premium(client);
		}
		
		/*
		if(IsValidEntity(client) && GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			if(pGlow[client] == true)
			{
				Glow(client);
			}
		}
		*/
		if(IsValidEntity(client) && GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			if(pDark[client] == false)
			{
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
			else
			{
				SetEntityRenderColor(client, 0, 0, 0, 0);
			}
		}
		
		if(pFirstSpawn[client] == true)
		{
			
			pWelcomeTimer[client] = CreateTimer(5.0, Timer_Spawntimer, client);
			pFirstSpawn[client] = false;
			if(!(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG))
			{
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
			if(DPFeatures)
			{
			DisplayPremiumFeatures(client);
			}
		}
	}
}
/*
  //=========================================================================================================\\
 //									S E T  O P T I O N S  O N  L O C K E R									  \\	
//=============================================================================================================\\	
*/
public Player_Locker(Handle:event, String:strName[], bool:bDontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidEntity(client) && GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
	{
		SetEntityRenderColor(client, colorred[client], colorgreen[client], colorblue[client], 255);
	}
	
	if(IsValidEntity(client) && GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
	{
		if(pDark[client] == false)
		{
			SetEntityRenderColor(client, 255, 255, 255, 255);
		}
		else
		{
			SetEntityRenderColor(client, 0, 0, 0, 0);
		}
	}
}

public Action:Timer_Spawntimer(Handle:hTimer, any:client)
{

	if(IsValidEntity(client) && cWelcomeMessage == 1 && (GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG))
	{
		CPrintToChat(client, "%s %t", TAG, "Welcome");	
	}
}
/*
  //=========================================================================================================\\
 //									P L A Y E R  C H A N G E  S E T  C O L O U R							  \\	
//=============================================================================================================\\	
*/
public Player_Change(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(cEnable && (GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) &  ROOTFLAG) && IsValidEntity(client))
	{
		SetEntityRenderColor(client, colorred[client], colorgreen[client], colorblue[client], 255);
	}
}
/*
  //=========================================================================================================\\
 //											P L A Y E R  K I L L E D    									  \\	
//=============================================================================================================\\	
*/
public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new flags = GetEventInt(event, "death_flags");
	new TFClassType:Class = TF2_GetPlayerClass(victim); 

	
	if(cEnable && IsValidEntity(victim) && IsValidEntity(attacker) && attacker != victim && Class == TFClass_Spy)
	{
		new weapon = GetPlayerWeaponSlot(victim, 4);
		new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		if(IsValidEntity(attacker) && (GetUserFlagBits(attacker) & PREMIUMFLAG || pTrial[attacker] || GetUserFlagBits(attacker) & ROOTFLAG)  && cFakeKill)
		{
			if(weaponindex == 59)
			{			
					CPrintToChat(attacker, "%s %t", TAG, "FakeKill");
			}
		}
	}	
	if(attacker != 0 && attacker != victim && (GetUserFlagBits(attacker) & PREMIUMFLAG || pTrial[attacker] || GetUserFlagBits(attacker) & ROOTFLAG) && cKillBoost > 0)
	{
		new hp_attacker = GetClientHealth(attacker);
		SetEntityHealth(attacker, hp_attacker + cKillBoost);
		CPrintToChat(attacker, "%s %t", TAG, "KillBoost", cKillBoost);
	}
		
	if(assister != 0 && attacker != victim && (GetUserFlagBits(assister) & PREMIUMFLAG || pTrial[assister] || GetUserFlagBits(assister) & ROOTFLAG) && cKillAssist > 0)
	{
		new hp_assister = GetClientHealth(assister);
		SetEntityHealth(assister, hp_assister + cKillAssist);
		CPrintToChat(attacker, "%s %t", TAG, "KillBoost_Assist", cKillAssist);
	}
		
	if(GetUserFlagBits(victim) & PREMIUMFLAG || pTrial[victim] || GetUserFlagBits(victim) & ROOTFLAG)
	{
		if(!(flags && 16))
		{
				if(cRespawn)
				CreateTimer(1.0, Timer_Respawn, victim);
		}
	}
}
/*
  //=========================================================================================================\\
 //											R E S P A W N  T I M E R										  \\	
//=============================================================================================================\\	
*/
public Action:Timer_Respawn(Handle:hTimer, any:client)
{

	if(ArenaMap == 1)
		{	
			CPrintToChat(client, "%s Arena Mod detected! Respwan disabled");
		}
	else
		{

			TF2_RespawnPlayer(client); 

		}			
}
/*
  //=========================================================================================================\\
 //											 	S P E E D  T I M E R									 	  \\	
//=============================================================================================================\\	
*/
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient))
	return Plugin_Continue;

	if(GetUserFlagBits(iClient) & PREMIUMFLAG || pTrial[iClient] || GetUserFlagBits(iClient) & ROOTFLAG)
    {
		if(cSpeed)
		{
			new cond = GetEntProp(iClient, Prop_Send, "m_nPlayerCond");
			new TFClassType:playerclass = TF2_GetPlayerClass(iClient);
			switch(playerclass)
			{
			case TFClass_Spy:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", SpySpeed);
				}
			case TFClass_Scout:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", ScoutSpeed);
				}
				case TFClass_Sniper:
				{
					if(!(cond & 1)) 
					{
						SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", SniperSpeed);
					}
				}
			case TFClass_Engineer:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", EngineerSpeed);
				}
				case TFClass_Medic:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", MedicSpeed);
				}
			case TFClass_Pyro:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", PyroSpeed);
				}
			case TFClass_DemoMan:
				{
					if(!(cond & 131072))
					{
						SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", DemomanSpeed);
					}
				}
			case TFClass_Soldier:
				{
					SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", SoldierSpeed);
				}
			case TFClass_Heavy:
				{
					CreateTimer(1.0, Timer_CheckState, iClient);
				}
			}
		}
	
	}
	return Plugin_Continue;
}
/*
  //=========================================================================================================\\
 //									S P Y  C L O A K  &  H E A V Y  S P E E D								  \\	
//=============================================================================================================\\	
*/
public OnGameFrame()
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(cCloak && IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetUserFlagBits(i) & PREMIUMFLAG ||pTrial[i] || GetUserFlagBits(i) & ROOTFLAG)
			{
				new TFClassType:playerclass = TF2_GetPlayerClass(i);

				switch(playerclass)
				{
				case TFClass_Spy:
					{
						new cond = GetEntProp(i, Prop_Send, "m_nPlayerCond");
						if((cond & 16))
						{
							SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 100.0);
						}
					}
				}
			}
		}
/*
  //=========================================================================================================\\
 //									B U N N Y H O P  &  P Y R O F L Y										  \\	
//=============================================================================================================\\	
*/	
		if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetUserFlagBits(i) & PREMIUMFLAG || pTrial[i] || GetUserFlagBits(i) & ROOTFLAG)
			{
				new TFClassType:playerclass = TF2_GetPlayerClass(i);
				
				GroundEntity = GetEntPropEnt(i, Prop_Send, "m_hGroundEntity"); // 0 = World (aka on ground) | -1 = In air | Any other positive value = CBaseEntity pointer to the entity below player. 
				GetEntPropVector(i, Prop_Data, "m_vecVelocity", PlayerVel); 
				PlayerSpeed[0] = SquareRoot( (PlayerVel[0]*PlayerVel[0]) + (PlayerVel[1]*PlayerVel[1]) );             
				// bhop, trimp, normal jump 
				if( (GetClientButtons(i) & IN_JUMP) && (PlayerSpeed[0] >= (2.0)) && (GetConVarInt(cvar_bhop)==1) && ( (GroundEntity != -1) || WasOnGroundLastTime[i] ) ) 
				{ 
					PlayerSpeedLastTime[0] = SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) ); 
                 
					// check we haven't been slowed down since last time 
					if(PlayerSpeedLastTime[0] > PlayerSpeed[0]) 
					{ 
						PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0]; 
						PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0]; 
						PlayerSpeed[0] = PlayerSpeedLastTime[0]; 
					} 
					// trimp 
					if( ( (GetClientButtons(i) & IN_FORWARD) || (GetClientButtons(i) & IN_BACK) ) && (PlayerSpeed[0] >= (400.0 * 1.6)) ) 
					{ 
						TrimpVel[0] = PlayerVel[0] * Cosine(70.0*3.14159265/180.0); 
						TrimpVel[1] = PlayerVel[1] * Cosine(70.0*3.14159265/180.0); 
						TrimpVel[2] = PlayerSpeed[0] * Sine(70.0*3.14159265/180.0); 
                     
						InTrimp[i] = true; 
                     
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, TrimpVel); 
					} 
                 
					// bhop (and normal jump) 
					else 
					{ 
						// apply bhop boost 
						if( WasOnGroundLastTime[i] || (GetClientButtons(i) & IN_DUCK) ){} 
						else 
						{ 
							PlayerVel[0] = GetConVarFloat(BunnyIncrement) * PlayerVel[0]; 
							PlayerVel[1] = GetConVarFloat(BunnyIncrement) * PlayerVel[1]; 
							PlayerSpeed[0] = 1.2 * PlayerSpeed[0];  
						} 
                     
						// apply bhop caps 
						if(GetClientButtons(i) & IN_DUCK) 
						{ 
							if(PlayerSpeed[0] > (1.2 * 400.0 * 1.6)) 
							{ 
								PlayerVel[0] = PlayerVel[0] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0]; 
								PlayerVel[1] = PlayerVel[1] * 1.2 * 400.0 * 1.6 / PlayerSpeed[0]; 
							} 
						} 
						else if(PlayerSpeed[0] > (400.0 * 1.6)) 
						{ 
							PlayerVel[0] = PlayerVel[0] * 400.0 * 1.6 / PlayerSpeed[0]; 
							PlayerVel[1] = PlayerVel[1] * 400.0 * 1.6 / PlayerSpeed[0]; 
						} 
                     
						PlayerVel[2] = 800.0/3.0; 
                     
						TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel);  
					} 
				} 
             
             
				// doublejump 
				else if( (InTrimp[i] || (CanDJump[i] && (playerclass == TFClass_Unknown))) && (WasInJumpLastTime[i] == 0) && (GetClientButtons(i) & IN_JUMP) ) 
				{ 
					PlayerSpeedLastTime[0] = 1.2 * SquareRoot( (VelLastTime[i][0]*VelLastTime[i][0]) + (VelLastTime[i][1]*VelLastTime[i][1]) ); 
                 
					if(PlayerSpeedLastTime[0] < 400.0) 
					{ 
						PlayerSpeedLastTime[0] = 400.0; 
					} 
                 
					if(PlayerSpeed[0] == 0.0) 
					{ 
						PlayerSpeedLastTime[0] = 0.0; 
					} 
                 
					PlayerVel[0] = PlayerVel[0] * PlayerSpeedLastTime[0] / PlayerSpeed[0]; 
					PlayerVel[1] = PlayerVel[1] * PlayerSpeedLastTime[0] / PlayerSpeed[0]; 
					PlayerVel[2] = 800.0/3.0; 
                 
					CanDJump[i] = false; 
					InTrimp[i] = false; 
                 
					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel); 
				} 
             
				// enable doublejump 
				if( ( (InTrimp[i] == 1) || (CanDJump[i] == 0) ) && (GroundEntity != -1) ) 
				{ 
					CanDJump[i] = true; 
					InTrimp[i] = false; 
				} 
             
				// rocketman 
				else 
				{ 
					if(GroundEntity != -1){} 
					else 
					{ 
						GetClientWeapon(i,TempString,32); 
						if( (strcmp(TempString,"tf_weapon_flamethrower") == 0) && cPyrofly && (GetClientButtons(i) & IN_ATTACK) && (GetUserFlagBits(i) & PREMIUMFLAG || GetUserFlagBits(i) & ROOTFLAG || pTrial[i])) 
						{ 
							GetClientEyeAngles(i, EyeAngle); 
                         
							PlayerVel[2] = PlayerVel[2] + ( 15.0 * Sine(EyeAngle[0]*3.14159265/180.0) ); 
                         
							if(PlayerVel[2] > 100.0) 
							{ 
								PlayerVel[2] = 100.0; 
							} 
                         
							PlayerVel[0] = PlayerVel[0] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Cosine(EyeAngle[1]*3.14159265/180.0) ); 
							PlayerVel[1] = PlayerVel[1] - ( 3.0 * Cosine(EyeAngle[0]*3.14159265/180.0) * Sine(EyeAngle[1]*3.14159265/180.0) ); 
                         
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, PlayerVel); 
						} 
					} 
				} 
             
				// always save this stuff for next time 
				WasInJumpLastTime[i] = (GetClientButtons(i) & IN_JUMP); 
				WasOnGroundLastTime[i] = GroundEntity != -1 ? 1 : 0; 
				VelLastTime[i][0] = PlayerVel[0]; 
				VelLastTime[i][1] = PlayerVel[1]; 
				VelLastTime[i][2] = PlayerVel[2]; 
			
			} 
		}
	} 	
}
/*
  //=========================================================================================================\\
 //									H U N T S M A N	 F I R E  A R R O W S									  \\	
//=============================================================================================================\\
*/	
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result) 
{ 
	if(cEnable && cFireArrows && (GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG) && IsValidEntity(weapon)) 
	{ 
		new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"); 
		switch(weaponindex) 
		{ 
		case 56: 
			{ 
				SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1); 
			}
		case 1005: 
			{ 
				SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1); 
			} 
		case 1092: 
			{ 
				SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1); 
			} 
		} 
	} 
	return Plugin_Continue; 
}  
/*
  //=========================================================================================================\\
 //											S A V E  L O C A T I O N										  \\	
//=============================================================================================================\\	
*/
public Action:Save_Loc(client, args)
{

		
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cTeleport)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			GetClientAbsOrigin(client, prem_premiumLocation[client]);
			CPrintToChat(client,"%s Location Saved, Use loadloc to teleport here!", TAG);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}
/* 
  //=========================================================================================================\\
 //									T E L E P O R T  T O  L O C A T I O N									  \\	
//=============================================================================================================\\	
*/
public Action:Load_Loc(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cTeleport)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			TeleportEntity(client, prem_premiumLocation[client], NULL_VECTOR, NULL_VECTOR);
			CPrintToChat(client,"%s Teleported to location!", TAG);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}

/*
  //=========================================================================================================\\
 //											F I E L D  O F  V I E W											  \\	
//=============================================================================================================\\	
*/
public Action:Command_Fov(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cFov)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			new String:arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			new fov = StringToInt(arg1);
			SetEntData(client, offsFOV, fov, 1);
			pFov[client] = fov;
			CPrintToChat(client, "%s %t", TAG, "SetFOV", fov);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //											D A R K  C O M M A N D											  \\	
//=============================================================================================================\\	
*/
public Action:Command_Dark(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cDark)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			if(pDark[client] == false)
			{
				SetEntityRenderColor(client, 0, 0, 0, 0);
				pDark[client] = true;
				CPrintToChatAllEx(client, "%t", "ToggleDark", client);
			}
			else
			{
				pDark[client] = false;
				PrintToChat(client, "Removed dark effect!");
				SetEntityRenderColor(client, 255, 255, 255, 255);
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //										C O L O R  M E  C O M M A N D										  \\	
//=============================================================================================================\\	
*/

public Action:Command_color(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cDark)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
		
			if (args < 3)
			{
				CReplyToCommand(client, "%s !colorme R:<0-255> G:<0-255> B:<0-255>", TAG);
				return Plugin_Handled;	
			}

			new String:arg1[20];
			GetCmdArg(1, arg1, sizeof(arg1));
			if (StringToIntEx(arg1, colorred[client]) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);
				return Plugin_Handled;
			}
			if (colorred[client] < 0)
			{
				colorred[client] = 0;
			}
			if (colorred[client] > 255)
			{
				colorred[client] = 255;
			}

			new String:arg2[20];
			GetCmdArg(2, arg2, sizeof(arg2));
			if (StringToIntEx(arg2, colorgreen[client]) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);
				return Plugin_Handled;
			}
			if (colorgreen[client] < 0)
			{
				colorgreen[client] = 0;
			}
			if (colorgreen[client] > 255)
			{
				colorgreen[client] = 255;
			}

			//Colour Blue
			new String:arg3[20];
			GetCmdArg(3, arg3, sizeof(arg3));
			if (StringToIntEx(arg3, colorblue[client]) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);

				return Plugin_Handled;
			}
			if (colorblue[client] < 0)
			{
				colorblue[client] = 0;
			}
			if (colorblue[client] > 255)
			{
				colorblue[client] = 255;
			}
			
			SetEntityRenderColor(client, colorred[client], colorgreen[client], colorblue[client], 255);
			CPrintToChat(client, "%s Color has been changed!", TAG);
			return Plugin_Handled;
		}
		CPrintToChat(client, "%s %t", TAG, "NoAccess");
	}
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //											G L O W  C O M M A N D											  \\	
//=============================================================================================================\\	
*/
/*
Glow(client)
{

	AttachParticle(client, "player_recent_teleport_blue");
	AttachParticle(client, "player_recent_teleport_red");
	AttachParticle(client, "critical_grenade_blue");
	AttachParticle(client, "critical_grenade_red");
}


public Action:Command_Glow(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cGlow)
	{
		if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
		{
			if(pGlow[client] == false)
			{
				pGlow[client] = true;
				Glow(client);
				CPrintToChatAllEx(client, "%t", "ToggleGlow", client);

			}
			else
			{
				pGlow[client] = false;
				CPrintToChat(client, "%s Your glow will be removed shortly", TAG);
				DeleteParticle(g_Ent[client]);

			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}
*/

/*
  //=========================================================================================================\\
 //												S W A P  T E A M											  \\	
//=============================================================================================================\\	
*/
public Action:Command_Swap(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(cEnable && cSwap && (GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG))
	{
		new team = GetClientTeam(client);
		if(team == 2)
		{
			ChangeClientTeam(client, 3);
			CPrintToChat(client, "%s %t", TAG, "TeamBLU");
		}
		if(team == 3)
		{
			ChangeClientTeam(client, 2);
			CPrintToChat(client, "%s %t", TAG, "TeamRED");
		}
		
	}
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //											T R I A L  C O M M A N D										  \\	
//=============================================================================================================\\	
*/
public Action:Say(client, args)
{
	if(cEnable && cTrial && IsValidEntity(client) && IsClientInGame(client))
	{		
		new String:trial[32];
		GetClientCookie(client, pTrialCookie, usedTrial, sizeof(usedTrial));
		new cookie = StringToInt(usedTrial);
		
		if(pTrial[client] == true)
		{
			CPrintToChat(client, "%s Your trial is active! You have: ", TAG);
			CPrintToChat(client, "%s Days: %i", TAG, daysleftint);				
			CPrintToChat(client, "%s Hours: %i", TAG, hrsleftint);
			CPrintToChat(client, "%s Minutes: %i ", TAG, minleftint);
			CPrintToChat(client, "%s Seconds: %i", TAG, secleftint);
			CPrintToChat(client, "%s until your trial expires", TAG);
			return Plugin_Handled;
		}
		
		if(GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG)
		{
			DisplayPremiumFeatures(client);
		}
		else if(cookie == 0 && cTrial)
		{
			TrialTimer[client] = cTrialTimeLimit;
			Format(trial, sizeof(trial), "1");
			SetClientCookie(client, pTrialCookie, bool:StringToInt(usedTrial)?"0":"1");
			CPrintToChat(client, "%s %t", TAG, "TrialActivated");
			Premium(client);
			SetAdminFlag(client, Admin_Custom6, true); 
			pFov[client] = cDefaultFov;
			pTrial[client] = true;
			CreateTimer(1.0, GetTimeLeft, client);
			tTrial[client] = CreateTimer(cTrialTimeLimit, Timer_Trial, client);
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "TrialUsed");
			//PrintToChat(client, "You Are now able to use full Premium on the server thank you for beta testing!");
			//SetUserFlagBits(client, PREMIUMFLAG);
		}
	}
	return Plugin_Continue;
}

/*
  //=========================================================================================================\\
 //											T R I A L  E N D E D				  							  \\	
//=============================================================================================================\\	
*/
public Action:Timer_Trial(Handle:hTimer, any:client)
{
	if(cEnable && IsClientInGame(client) && IsValidEntity(client))
	{
		pTrial[client] = false;
		SetAdminFlag(client, Admin_Custom1, false);  
		CPrintToChat(client, "%s %t.", TAG, "TrialEnded");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}
/*
  //=========================================================================================================\\
 //											P R E M I U M  M E N U											  \\	
//=============================================================================================================\\	
*/
DisplayPremiumFeatures(client)
{
	if(IsValidEntity(client))
	{
		new Handle:featurepanel = CreatePanel();
		DrawPanelItem(featurepanel, "Premium Member Features");
		if(cHPBoost)
		DrawPanelText(featurepanel, "- More health on spawn");
		if(cSpeed)
		DrawPanelText(featurepanel, "- Faster movement speed");
		if(cGravity)
		DrawPanelText(featurepanel, "- Low gravity");
		if(cBhop)
		DrawPanelText(featurepanel, "- Bhop");
		if(cPyrofly)
		DrawPanelText(featurepanel, "- Fly around with pyro");
		if(cClip)
		DrawPanelText(featurepanel, "- Larger clip size");
		if(cKillBoost)
		DrawPanelText(featurepanel, "- Health bonuses on kills and assists");
		if(cColor > 1)
		DrawPanelText(featurepanel, "- Special player color");
		if(cFov)
		DrawPanelText(featurepanel, "- Changeable field of view");
		//if(cGlow)
		//DrawPanelText(featurepanel, "- Ability to use !glow");
		if(cDark)
		DrawPanelText(featurepanel, "- Ability to use !dark");
		if(cSwap)
		DrawPanelText(featurepanel, "- Ability to use !swapteam");
		if(cUber > 0)
		DrawPanelText(featurepanel, "- Semi-filled ubercharge on spawn");
		if(cStunballs)
		DrawPanelText(featurepanel, "- More sandman balls");
		if(cJarates)
		DrawPanelText(featurepanel, "- More Jarates");
		if(cMetal)
		DrawPanelText(featurepanel, "- More metal");
		if(cRespawn)
		DrawPanelText(featurepanel, "- Instant respawn");
		if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1 || GetUserFlagBits(client) & ROOTFLAG))
		{
			DrawPanelText(featurepanel, " ");
			DrawPanelItem(featurepanel, "Get a Premium Account!");
		}
		DrawPanelText(featurepanel, " ");
		DrawPanelItem(featurepanel, "Exit");
		SendPanelToClient(featurepanel, client, Panel_Features, 60);
		CloseHandle(featurepanel);
	}
}
/*
  //=========================================================================================================\\
 //												M E N U  C L O S E											  \\	
//=============================================================================================================\\	
*/
public Panel_Features(Handle:menu, MenuAction:action, param1, param2)
{
	if(param2 == 2)
	{
		CPrintToChat(param1, "%s %t", TAG, "WebAd");
	}
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Panel_Premium(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
/*
  //=========================================================================================================\\
 //							P A R T I C L E S  C R E A T E D  W I T H  G L O W								  \\	
//=============================================================================================================\\	
*/
/*
AttachParticle(ent, String:particleType[])
{
	new particle = CreateEntityByName("info_particle_system");
	
	new String:tName[128];
	if (IsValidEdict(particle))
	{
		new Float:pos[3];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[0] += 0.0;
		pos[1] += 0.0;
		pos[2] += 0.0;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);
		
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetVariantString("!activator");
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		
		g_Ent[ent] = particle;
	}
}
DeleteParticle(any:particle)
{
    if (IsValidEntity(particle))
    {
        new String:classname[256];
        GetEdictClassname(particle, classname, sizeof(classname));
        if (StrEqual(classname, "info_particle_system", false))
        {
            RemoveEdict(particle);
        }
    }
}

*/

/*
  //=========================================================================================================\\
 //										S A V E  &  R E L O A D  C V A R S									  \\	
//=============================================================================================================\\	
*/
public Action:Command_Reload(client, args)
{
	if(IsValidEntity(client))
	{
		ReplyToCommand(client, "%s Successfully saved and reloaded new settings", "[Premium]");
	}
	ReloadConvars();
	return Plugin_Handled;
}


/*
  //=========================================================================================================\\
 //												R E S E T  T R I A L										  \\	
//=============================================================================================================\\	
*/
public Action:Command_ResetTrial(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToCommand(client, "[Premium] User Not Found!");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: premium_createtrial <name>");
		return Plugin_Handled;
	}
	for (new i = 0; i <target_count; i++)
	{
		GetClientCookie(target_list[i], pTrialCookie, usedTrial, sizeof(usedTrial));
		SetClientCookie(target_list[i], pTrialCookie, bool:StringToInt(usedTrial)?"0":"0");
		ReplyToCommand(client, "[Premium] Players Trial has been reset");
		CPrintToChat(target_list[i], "%s %t", TAG, "TrialReset");
	}
	
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //											C R E A T E  A T R I A L										  \\	
//=============================================================================================================\\	
*/
public Action:Command_CreateTrial(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
	if ((target_count = ProcessTargetString(
					arg1,
					client,
					target_list,
					MAXPLAYERS,
					COMMAND_FILTER_ALIVE,
					target_name,
					sizeof(target_name),
					tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: premium_createtrial <name>");
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		pTrial[target_list[i]] = true;
		Premium(target_list[i]);
		CPrintToChat(client, "%s Created a trial for %N.", TAG, target_list[i]);
	}
	
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //													S T O C K S 											  \\	
//=============================================================================================================\\
*/

Premium(client)
{

if( IsValidEntity(client)  && IsClientInGame(client) && IsPlayerAlive(client) )
	{
	new health = GetClientHealth(client);
	new TFClassType:pClass = TF2_GetPlayerClass(client);

	if(cHPBoost > 1)
	SetEntityHealth(client, health + cHPBoost);
	if(cGravity != 1)
	SetEntityGravity(client, cGravity);
	if(cJarates > 1)
	SetGrenadeAmmo(client, cJarates, 58, 1);
	if(cStunballs > 1)
	SetGrenadeAmmo(client, cStunballs, 44, 2);
	if(pClass == TFClass_Medic)
	SetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel", cUber * 0.01);
	if(pClass != TFClass_Heavy && pClass != TFClass_Medic && pClass != TFClass_Pyro && pClass != TFClass_Sniper)
	SetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1", GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1") + cClip);
	if(pClass == TFClass_Engineer)
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), cMetal, 4, true);
	if(cColor > 0)
	SetClientColor(client, cColor);
	if(pClass == TFClass_Spy)
	SetEntityRenderColor(client, 255, 255, 255, 0);
	pSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	
	if(pFov[client] == 0)
	pFov[client] = cDefaultFov;
	
	SetEntData(client, offsFOV, pFov[client], 1);
	}
}
/*
  //=========================================================================================================\\
 //												R E L O A D  C V A R S										  \\	
//=============================================================================================================\\	
*/

ReloadConvars()
{
	cEnable = GetConVarInt(cvar_enable);
	cMySql = GetConVarInt(cvar_mysql);
	cTeleport = GetConVarInt(cvar_teleport);
	cAdsEnable = GetConVarInt(cvar_ads_enable);
	cAdsInterval = GetConVarFloat(cvar_ads_int);
	cWelcomeMessage = GetConVarInt(cvar_welcomemsg);
	cSpeed = GetConVarInt(cvar_speed);
	cGravity = GetConVarFloat(cvar_gravity);
	DPFeatures = GetConVarInt(cvar_DisplayPremFeatures);
	cHPBoost = GetConVarInt(cvar_hpboost);
	cClip = GetConVarInt(cvar_clip);
	
	cKillBoost = GetConVarInt(cvar_kill_boost);
	cKillAssist = GetConVarInt(cvar_kill_assist);
	cColor = GetConVarInt(cvar_color);
	cFov = GetConVarInt(cvar_fov);
	cTrialTimeLimit = GetConVarFloat(cvar_trial_timelimit);
	cFakeKill = GetConVarInt(cvar_fakekill);
	cDefaultFov = GetConVarInt(cvar_defaultfov);
	cDark = GetConVarInt(cvar_dark);
	//cGlow = GetConVarInt(cvar_glow);
	cStunballs = GetConVarInt(cvar_stunballs);
	cJarates = GetConVarInt(cvar_jarates);
	cUber = GetConVarFloat(cvar_uber);
	cRespawn = GetConVarInt(cvar_respawn);
	cSwap = GetConVarInt(cvar_swapteams);
	cTrial = GetConVarInt(cvar_trial);
	cFireArrows = GetConVarInt(cvar_firearrows);
	cMetal = GetConVarInt(cvar_metal);
	cBhop = GetConVarInt(cvar_bhop);
	cPyrofly = GetConVarInt(cvar_pyrofly);
	cCloak = GetConVarInt(cvar_cloak);
	mySQL_connect();
	cPremJoin = GetConVarInt(cvar_playerJoinAnnounce);
	
	HeavySpeed = GetConVarFloat(cvar_Heavy);
	HeavySlow = GetConVarFloat(cvar_HeavySpin);
	MedicSpeed = GetConVarFloat(cvar_Medic);
	SpySpeed = GetConVarFloat(cvar_Spy);
	SniperSpeed = GetConVarFloat(cvar_Sniper);
	ScoutSpeed = GetConVarFloat(cvar_Scout);
	EngineerSpeed = GetConVarFloat(cvar_Engineer);
	PyroSpeed = GetConVarFloat(cvar_Pyro);
	SoldierSpeed = GetConVarFloat(cvar_Solider);
	DemomanSpeed = GetConVarFloat(cvar_Demoman);
	GetConVarString(cvar_tag, TAG, sizeof(TAG));
}
/*
  //=========================================================================================================\\
 //											G R A N A D E  A M M O											  \\	
//=============================================================================================================\\	
*/
SetGrenadeAmmo(client, ammo, index, slot)
{
	new weapon = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(weapon))
	{
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == index)
		{    
			new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
			new iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
			SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
		}
	}
}
/*
  //=========================================================================================================\\
 //											P R E M I U M  C O L O R S										  \\	
//=============================================================================================================\\	
*/
SetClientColor(client, color)
{
	switch(color)
	{
	case 0:
		SetEntityRenderColor(client, 255, 255, 255, 255); //DEFAULT
	case 1:
		SetEntityRenderColor(client, 100, 255, 100, 255); //GREEN
	case 2:
		SetEntityRenderColor(client, 255, 100, 100, 255); //RED
	case 3:
		SetEntityRenderColor(client, 100, 100, 255, 255); //BLUE
	case 4:
		SetEntityRenderColor(client, 255, 255, 100, 255); //YELLOW
	case 5:
		SetEntityRenderColor(client, 100, 255, 255, 255); //CYAN
	case 6:
		SetEntityRenderColor(client, 255, 100, 255, 255); //PURPLE
	}
}
/*
  //=========================================================================================================\\
 //									C L I E N T  L E F T  T H E  G A M E									  \\	
//=============================================================================================================\\
*/	
public OnClientDisconnect(client)
{
	pTrial[client] = false;
	pFirstSpawn[client] = true;
	GetClientCookie(client, pTrialCookie, usedTrial, sizeof(usedTrial));
	SetClientCookie(client, pTrialCookie, bool:StringToInt(usedTrial)?"0":"0");
}
/*
  //=========================================================================================================\\
 //									D A T A B A S E  C O N N E C T I O N									  \\	
//=============================================================================================================\\	
*/
public mySQL_connect()
{
	if(cMySql == 1) // Chck if mysql is enabled
	{
		DatabaseConnection = SQL_Connect("premium", true, Error, sizeof(Error)); //Use Premium settings in database.cfg
		new String:ident[16];
		SQL_ReadDriver(DatabaseConnection, ident, sizeof(ident));
		
		if (strcmp(ident, "mysql") == 0)
		{
			if (DatabaseConnection == INVALID_HANDLE)
			{
				PrintToServer("Cannot connect to database!: %s", Error);
				CloseHandle(DatabaseConnection);
			} else {
				PrintToServer("[Premium] Connected to database! Using MYSQL");
			}
		} else if (strcmp(ident, "sqlite") == 0) {
			PrintToServer("[Premium] Connected to database! Using SQLite ");
		} else {
			PrintToServer("[Premium] database disabled!, Using premium flags");
		}
	}
}
/*
  //=========================================================================================================\\
 //									D A T A B A S E  A D D  C L I E N T										  \\	
//=============================================================================================================\\	
*/
public Action:Command_AddUserMysql(client, args)
{

	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		if(cMySql == 1)
		{
			new String:arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			if ((target_count = ProcessTargetString(
							arg1,
							client,
							target_list,
							MAXPLAYERS,
							COMMAND_FILTER_ALIVE,
							target_name,
							sizeof(target_name),
							tn_is_ml)) <= 0)
			{
				ReplyToCommand(client, "[Premium] User Not Found!");
				return Plugin_Handled;
			}

			if(args < 1)
			{ 
				ReplyToCommand(client, "[Premium] Please enter client name");
				return Plugin_Handled;
			}
			for (new i = 0; i <target_count; i++)
			{
				// Start insertign the player in to the database
				new String:name[32];
				new String:steamid[40];
				GetClientName(target_list[i], name, sizeof(name));
				GetClientAuthId(target_list[i], AuthId_Steam3, steamid, 32);
				
				new String:queryInsert[300];
				Format(queryInsert, sizeof(queryInsert), "INSERT INTO premium (name, steamid) VALUES ('%s', '%s')", name, steamid);
				new Handle:queryH = SQL_Query(DatabaseConnection, queryInsert);
				
				if(queryH != INVALID_HANDLE)
				{
					ReplyToCommand(client,"[Premium] Client %s successfuly added!", name);
				} else {
					ReplyToCommand(client, "[Premium] Client %s Not been Added", name);
				}
				return Plugin_Handled;
			}
		} else {
			ReplyToCommand(client,"[Premium] Mysql is not enabled!");
			return Plugin_Handled;
		}
	}else{
		ReplyToCommand(client, "%s Cannot add user! MySQL disabled",TAG);
		
	}	
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //									D A T A B A S E  R E M O V E  U S E R									  \\	
//=============================================================================================================\\	
*/
public Action:Command_removeUserMysql(client, args)
{
	if(!client)
	{
		PrintToServer("[Premium] This command can only be used ingame!");
		return Plugin_Handled;
	}
	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		if(cMySql == 1)
		{
			new String:arg1[64];
			GetCmdArg(1, arg1, sizeof(arg1));
			new String:target_name[MAX_TARGET_LENGTH];
			new target_list[MAXPLAYERS], target_count;
			new bool:tn_is_ml;
			
			if ((target_count = ProcessTargetString(
							arg1,
							client,
							target_list,
							MAXPLAYERS,
							COMMAND_FILTER_ALIVE,
							target_name,
							sizeof(target_name),
							tn_is_ml)) <= 0)
			{
				ReplyToCommand(client, "[Premium] User Not Found!");
				return Plugin_Handled;
			}

			if(args < 1)
			{ 
				ReplyToCommand(client, "[Premium] Please enter client name");
				return Plugin_Handled;
			}
			for (new i = 0; i <target_count; i++)
			{
				// Start removing the player in to the database
				new String:queryInsert[300];
				Format(queryInsert, sizeof(queryInsert), "DELETE FROM premium WHERE name='%s'", target_list[i]);
				new Handle:queryH = SQL_Query(DatabaseConnection, queryInsert);
				if(queryH != INVALID_HANDLE)
				{
					if(SQL_FetchRow(queryH))
					{
						ReplyToCommand(client, "[Premium] User has been removed");
						RemoveUserFlags(client,AdminFlag:"g");
					} 
					else 
					{
						SQL_GetError(DatabaseConnection, Error, sizeof(Error));
						ReplyToCommand(client, "[Premium] User was not removed: %s", Error);
					}
				}
				return Plugin_Handled;
			} 
		}else{
			ReplyToCommand(client,"[Premium] Mysql not enabled!");
		}
		return Plugin_Handled;
	}else{
		ReplyToCommand(client, "%s Cannot remove user! MySQL disabled",TAG);
	}
	return Plugin_Handled;
}
/*
  //=========================================================================================================\\
 //										C R E A T E  D A T A B A S E										  \\	
//=============================================================================================================\\	
*/
public Action:create_PremDatabase(client, args)
{
	if(cMySql == 1)
	{
	new String:CreateDatabase[250];

	new String:ident[16];
	SQL_ReadDriver(DatabaseConnection, ident, sizeof(ident));
	if (strcmp(ident, "mysql") == 0)
	{
		
		Format(CreateDatabase, sizeof(CreateDatabase), "CREATE TABLE IF NOT EXISTS `premium` ( `name` varchar(32) NOT NULL, `steamid` varchar(32) NOT NULL ) ENGINE=InnoDB DEFAULT CHARSET=latin1;");
		new Handle:queryH = SQL_Query(DatabaseConnection, CreateDatabase);
		
		if(queryH != INVALID_HANDLE)
		{
			ReplyToCommand(client,"[Premium] MySQL Database has been created! ");
		} else {
			ReplyToCommand(client, "[Premium] MySQL Database cannot be created: ", Error);
		}
	} else if (strcmp(ident, "sqlite") == 0)
	{
		Format(CreateDatabase, sizeof(CreateDatabase), "CREATE DATABASE premium;");
		Format(CreateDatabase, sizeof(CreateDatabase), "CREATE TABLE premium(name varchar(32), steamid varchar(32));");
		new Handle:queryH = SQL_Query(DatabaseConnection, CreateDatabase);
		//was Succsessful
		if(queryH != INVALID_HANDLE)
		{
			ReplyToCommand(client,"[Premium] SQL Database has been created! ");
		} else {
			ReplyToCommand(client, "[Premium] SQL Database cannot be created: ", Error);
		}
	}
  }
}
/*
  //=========================================================================================================\\
 //				    	G I V E  U S E R  P R E M I U M  O N  D A T A B A S E  C H E C K					  \\	
//=============================================================================================================\\	
*/

public OnClientAuthorized(client)
{
 if(cMySql == 1)
	{
	new String:SteamAuth2[32];
	GetClientAuthId(client,AuthId_Steam3, SteamAuth2, sizeof(SteamAuth2));
	new String:getquery[200];
	Format(getquery, sizeof(getquery), "SELECT steamid FROM premium WHERE steamid='%s'", SteamAuth2);
	new Handle:queryH = SQL_Query(DatabaseConnection, getquery);
	
	if(queryH != INVALID_HANDLE)
	{
		if(SQL_FetchRow(queryH))
		{
			SetUserFlagBits(client, PREMIUMFLAG);
		}
	} else {
		SQL_GetError(DatabaseConnection, Error, sizeof(Error));
		ReplyToCommand(client, "User was not given premium %s", Error);
	}
  }
}



public Action:GetTimeLeft(Handle:TimeLeft, any:client)
{
	if(TrialTimer[client] != 0)
	{
		TrialTimer[client] -= 1;
		days = TrialTimer[client]/86400;        // Convert seconds to days, hours, minutes, seconds
		hrs = (TrialTimer[client]/3600);
		mins = (TrialTimer[client]/60);
		sec = TrialTimer[client];
		
		//Convert to Strings
		FloatToString(days, daysleft, sizeof(daysleft));
		FloatToString(hrs, hrsleft, sizeof(hrsleft));
		FloatToString(mins, minleft, sizeof(minleft));
		FloatToString(sec, secleft, sizeof(secleft));
		
		//Then convert to Ints so there can be converted to time
		daysleftint = StringToInt(daysleft);
		hrsleftint = StringToInt(hrsleft)%24;
		minleftint = StringToInt(minleft)%60;
		secleftint = StringToInt(secleft)%60;
		
		//repeat until finished
		CreateTimer(1.0, GetTimeLeft, client);
	}
	return Plugin_Stop;
}