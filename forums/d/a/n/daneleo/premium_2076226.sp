//////////////////////////
//G L O B A L  S T U F F//
//////////////////////////
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <clientprefs>



#pragma semicolon 1

#define PLUGIN_VERSION "1.15.8"
#define PLUGIN_AUTHOR "daneleo, Original Author noodleboy347"
#define PLUGIN_NAME "[TF2] Premium Mod"
#define PLUGIN_URL "http://www.frozencubes.com"
#define PLUGIN_DESCRIPTION "Extra abilities for donators or special members"

#define NO_ATTACH 0
#define ATTACH_NORMAL 1
#define ATTACH_HEAD 2

#define TAG "{green}[{lightgreen}PREMIUM{green}]{default}"
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
new Handle:cvar_kill_assist;
new Handle:cvar_color;
new Handle:cvar_fov;
new Handle:cvar_defaultfov;
new Handle:cvar_dark;
new Handle:cvar_glow;
new Handle:cvar_stunballs;
new Handle:cvar_jarates;
new Handle:cvar_uber;
new Handle:cvar_respawn;
new Handle:cvar_DisplayPremFeatures;
new Handle:cvar_swapteams;
new Handle:cvar_trial;
new Handle:cvar_cloak;
new Handle:cvar_trial_length;
new Handle:cvar_metal;
new Handle:cvar_mysql;
new Handle:cvar_fakekill;
new Handle:cvar_firearrows;
new Handle:BunnyIncrement = INVALID_HANDLE;
new Handle:cvar_bhop;
new Handle:cvar_pyrofly;


new cEnable;
new String:usedTrial[32];
new cAdsEnable;
new cFakeKill;
new cMySql;
new Float:cAdsInterval;
new cWelcomeMessage;
new cSpeed;
new cCloak;
new Float:cGravity;
new cHPBoost;
new cClip;
new cKillBoost;
new cKillAssist;
new cColor;
new cFireArrows;
new cFov;
new cDefaultFov;
new cDark;
new cGlow;
new cStunballs;
new cJarates;
new Float:cUber;
new cRespawn;
new cSwap;
new DPFeatures;
new cTrial;
new cBhop;
new cPyrofly;
new Float:cTrialLength;
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


new Handle:pWelcomeTimer[MAXPLAYERS+1];
new Handle:tTrial[MAXPLAYERS+1];
new Handle:Database = INVALID_HANDLE;

new bool:pGlow[MAXPLAYERS+1];
new bool:pDark[MAXPLAYERS+1];
new bool:pFirstSpawn[MAXPLAYERS+1];
new bool:pTrial[MAXPLAYERS+1];

new Float:pSpeed[MAXPLAYERS+1];

new Handle:pTrialCookie = INVALID_HANDLE;

new String:Error[200];

new pFov[MAXPLAYERS+1];

new offsFOV;


////////////////////////
//P L U G I N  I N F O//
////////////////////////
public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

///////////////////////////
//P L U G I N  S T A R T//
/////////////////////////
public OnPluginStart()
{
	mySQL_connect(); // Mysql
	/////////////////
	//Console Cvars//
	////////////////
	RegConsoleCmd("say", Say);
	RegConsoleCmd("premium_fov", Command_Fov);
	RegConsoleCmd("dark", Command_Dark);
	RegConsoleCmd("glow", Command_Glow);
	RegConsoleCmd("swapteam", Command_Swap);
	RegConsoleCmd("colorme", Command_color);
	RegConsoleCmd("pau", Command_AddUserMysql);
	RegConsoleCmd("pru", Command_removeUserMysql);
	/////////////////////////
	//A D M I N  C V A R S//
	///////////////////////
	RegAdminCmd("premium_refresh", Command_Refresh, ADMFLAG_ROOT);
	RegAdminCmd("premium_createtrial", Command_CreateTrial, ADMFLAG_ROOT);
	RegAdminCmd("premium_resettrial", Command_ResetTrial, ADMFLAG_ROOT);
	RegAdminCmd("premium_createDB", create_PremDatabase, ADMFLAG_ROOT);
	//////////////
	//C v a r s//
	////////////
	CreateConVar("premium_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY);
	cvar_enable = CreateConVar("premium_enable", "1", "Enable the plugin");
	cvar_cloak = CreateConVar("premium_infcloak", "1", "Enable Infinite Cloak");
	cvar_mysql = CreateConVar("premium_use_database", "0", "Enables mySQL database");
	cvar_ads_enable = CreateConVar("premium_advertisement_enable", "1", "Enables advertisements");
	cvar_ads_int = CreateConVar("premium_advertisement_interval", "300", "Advertisement interval");
	cvar_welcomemsg = CreateConVar("premium_welcome_message", "1", "Welcome message for Premium Members");
	cvar_speed = CreateConVar("premium_speed", "1", "Faster movement speed (Scout speed)");
	cvar_gravity = CreateConVar("premium_gravity_mult", "0.75", "Gravity multiplier");
	cvar_hpboost = CreateConVar("premium_health_boost", "15", "Extra health for players on spawn");
	cvar_clip = CreateConVar("premium_extra_clip", "1", "Extra bullets in clip on spawn");
	cvar_kill_boost = CreateConVar("premium_healthbonus_kill", "25", "Amount of health to boost on kill");
	cvar_kill_assist = CreateConVar("premium_healthbonus_assist", "25", "Health to boost on assist");
	cvar_color = CreateConVar("premium_color", "1", "Render color of player");
	cvar_fov = CreateConVar("premium_fov_enable", "1", "Allow usage of fov command");
	cvar_defaultfov = CreateConVar("premium_fov_default", "100", "Default fov");
	cvar_dark = CreateConVar("premium_dark", "1", "Allow usage of dark command");
	cvar_glow = CreateConVar("premium_glow", "1", "Allow usage of glow command");
	cvar_stunballs = CreateConVar("premium_stunballs", "1", "Amount of stunballs for Scouts");
	cvar_jarates = CreateConVar("premium_jarates", "1", "Amount of Jarates for Snipers");
	cvar_uber = CreateConVar("premium_ubercharge", "1", "Percentage of ubercharge for Medics");
	cvar_respawn = CreateConVar("premium_instant_respawn", "1", "Instantly respawn after death");
	cvar_swapteams = CreateConVar("premium_swapteams", "1", "Allow usage of the swapteams command");
	cvar_firearrows = CreateConVar("premium_firearrows", "1", "Makes huntman arrows on fire without the need of it being lit");
	cvar_trial = CreateConVar("premium_trial", "1", "Allow players to use trials");
	cvar_trial_length = CreateConVar("premium_trial_length", "900", "Time in seconds for trials");
	cvar_DisplayPremFeatures = CreateConVar("premium_displaypremfeatures", "1", "Displays the premium features on spawn");
	cvar_metal = CreateConVar("premium_metal", "200", "Amount of metal to spawn with");
	BunnyIncrement = CreateConVar("premium_bhop_Increment", "1.15", "Changes bunnyhop speedincrease");
	cvar_pyrofly = CreateConVar("premium_pyrofly_enabled", "1", "Allow pyro to fly with flamethrower.");
	cvar_fakekill = CreateConVar("premium_deadringer", "1", "Whether or not to detect Dead Ringer kills");
	cvar_bhop = CreateConVar("premium_bhop_enabled", "1", "enables bunnyhopping/trimping/bhopdoublejump");
	
	//////////////
	//O t h e r//
	////////////
	HookEvent("player_death", Player_Death);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_changeclass", Player_Change);
	//HookEvent("post_inventory_application", Player_Locker);
	pTrialCookie = RegClientCookie("UsedTrial", "Has client used their trial yet?", CookieAccess_Protected);
	AutoExecConfig();
	LoadTranslations("premium.phrases");
	offsFOV = FindSendPropInfo("CBasePlayer", "m_iDefaultFOV");
	ReloadConvars();
	CreateTimer(cAdsInterval, Timer_Ad);
}

public OnConfigsExecuted()
{
	ReloadConvars();
}

///////////////////////////////////
//C O N N E C T  T O  S E R V E R//
///////////////////////////////////
public OnClientPostAdminCheck(client)
{
	if(cEnable && (GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG))
	{
		new String:Name[25];
		GetClientName(client, Name , sizeof(Name));
		pGlow[client] = false;
		pDark[client] = false;
		pFirstSpawn[client] = true;
		pFov[client] = cDefaultFov;
		pTrial[client] = false;
		CPrintToChatAll("%s %s is a premium member!",TAG, Name);
	}
	else
	{
		pGlow[client] = false;
		pDark[client] = false;
		pFirstSpawn[client] = true;
		pFov[client] = cDefaultFov;
		pTrial[client] = false;
	}
}

public Action:Timer_Ad(Handle:timer, any:client)
{
	if(cEnable && cAdsEnable && IsValidEntity(client))
	{
		CPrintToChatAll("%t", "Advertisement");
		CreateTimer(cAdsInterval, Timer_Ad);
	}
}

//////////////////////////
//P L A Y E R  S P A W N//
//////////////////////////
public Player_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	
	if((GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG))
	{
		Premium(client);
	}
	
	if(GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || GetUserFlagBits(client) & ROOTFLAG)
	{
		if(pGlow[client] == true)
		{
			Glow(client);
		}
	}
	
	if(pFirstSpawn[client] == true)
	{
		
		pWelcomeTimer[client] = CreateTimer(5.0, Timer_Spawntimer, client);
		pFirstSpawn[client] = false;
		if(DPFeatures)
		{
		DisplayPremiumFeatures(client);
		}
	}

}


public Action:Timer_Spawntimer(Handle:hTimer, any:client)
{

	if(cWelcomeMessage == 1 && (GetUserFlagBits(client) & PREMIUMFLAG || GetUserFlagBits(client) & ROOTFLAG))
	{
		CPrintToChat(client, "%s %t", TAG, "Welcome");	
	}
}

//////////////////////////
//C H A N G E  C L A S S//
//////////////////////////
public Player_Change(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(cEnable && (GetUserFlagBits(client) & PREMIUMFLAG || pTrial[client] || ROOTFLAG) && IsValidEntity(client))
	{
	}
}

////////////////////////////
//P L A Y E R  K I L L E D//
////////////////////////////
public Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	new flags = GetEventInt(event, "death_flags");
	
	if(cEnable && IsValidEntity(victim) && IsValidEntity(attacker) && attacker != victim)
	{
		if(flags & 32 && GetUserFlagBits(attacker) & PREMIUMFLAG || pTrial[attacker] && cFakeKill)
			CPrintToChat(attacker, "%s %t", TAG, "FakeKill");
		if(attacker != 0 && (GetUserFlagBits(attacker) & PREMIUMFLAG || pTrial[attacker] || GetUserFlagBits(attacker) & ROOTFLAG) && cKillBoost > 0)
		{
			new hp_attacker = GetClientHealth(attacker);
			SetEntityHealth(attacker, hp_attacker + cKillBoost);
			CPrintToChat(attacker, "%s %t", TAG, "KillBoost", cKillBoost);
		}
		if(assister != 0 && (GetUserFlagBits(assister) & PREMIUMFLAG || pTrial[assister] || GetUserFlagBits(assister) & ROOTFLAG) && cKillAssist > 0)
		{
			new hp_assister = GetClientHealth(assister);
			SetEntityHealth(assister, hp_assister + cKillAssist);
			CPrintToChat(attacker, "%s %t", TAG, "KillBoost_Assist", cKillAssist);
		}
		
		if(!(flags & 32) && GetUserFlagBits(victim) & PREMIUMFLAG || pTrial[victim] || GetUserFlagBits(victim) & ROOTFLAG)
		{
				if(cRespawn)
				CreateTimer(0.1, Timer_Respawn, victim);
		}
	}
}

public Action:Timer_Respawn(Handle:hTimer, any:client)
{
	TF2_RespawnPlayer(client);
}

////////////////////////
//S P E E D  T I M E R//
////////////////////////
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if(iClient<=0 || iClient>MaxClients || !IsClientConnected(iClient) || !IsClientInGame(iClient))
	return Plugin_Continue;

	if(!(GetUserFlagBits(iClient) & PREMIUMFLAG || pTrial[iClient] || GetUserFlagBits(iClient) & ROOTFLAG))
	return Plugin_Continue;
	new cond = GetEntProp(iClient, Prop_Send, "m_nPlayerCond");
	new TFClassType:playerclass = TF2_GetPlayerClass(iClient);
	switch(playerclass)
	{
	case TFClass_Spy:
		{
			SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 375.0);
		}
	case TFClass_Sniper:
		{
			if(!(cond & 1)) 
			{
				SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 375.0);
			}
		}
	case TFClass_Engineer:
		{
			SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 375.0);
		}
	case TFClass_Medic:
		{
			SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 400.0);
		}
	case TFClass_Pyro:
		{
			SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 375.0);
		}
	case TFClass_DemoMan:
		{
			if(!(cond & 131072))
			{
				SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 350.0);
			}
		}
	case TFClass_Soldier:
		{
			SetEntPropFloat(iClient, Prop_Send, "m_flMaxspeed", 300.0);
		}
	}
	return Plugin_Continue;
}

//////////////////////////
//R E G E N  C L O A K //
////////////////////////
public OnGameFrame()
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if( IsValidEntity(i) && (GetUserFlagBits(i) & PREMIUMFLAG)  && IsClientInGame(i) && IsPlayerAlive(i) )
		{
			new TFClassType:playerclass = TF2_GetPlayerClass(i);
			if(cCloak)
			{

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
					if( (strcmp(TempString,"tf_weapon_flamethrower") == 0) && (GetConVarInt(cvar_pyrofly)==1) && (GetClientButtons(i) & IN_ATTACK) && (GetUserFlagBits(i) & PREMIUMFLAG)) 
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


////////////////
//Fire Arrows//
//////////////
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
		} 
	} 
	return Plugin_Continue; 
}  


///////////////////////////
//F I E L D  O F  V I E W//
///////////////////////////
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

//////////////////////////
//D A R K  C O M M A N D//
//////////////////////////
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
				SetEntityRenderColor(client, 0, 0, 0, 255);
				pDark[client] = true;
				CPrintToChatAllEx(client, "%t", "ToggleDark", client);
			}
			else
			{
				SetClientColor(client, cColor);
				pDark[client] = false;
				PrintToChat(client, "Removed dark effect!");
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}

/////////////////////////////
//C O L O R  C O M M A N D//
///////////////////////////

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

			new colorred = 0;
			new String:arg1[20];
			GetCmdArg(1, arg1, sizeof(arg1));
			if (StringToIntEx(arg1, colorred) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);
				return Plugin_Handled;
			}
			if (colorred < 0)
			{
				colorred = 0;
			}
			if (colorred > 255)
			{
				colorred = 255;
			}

			new colorgreen = 0;
			new String:arg2[20];
			GetCmdArg(2, arg2, sizeof(arg2));
			if (StringToIntEx(arg2, colorgreen) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);
				return Plugin_Handled;
			}
			if (colorgreen < 0)
			{
				colorgreen = 0;
			}
			if (colorgreen > 255)
			{
				colorgreen = 255;
			}

			//Colour Blue
			new colorblue = 0;
			new String:arg3[20];
			GetCmdArg(3, arg3, sizeof(arg3));
			if (StringToIntEx(arg3, colorblue) == 0)
			{
				CReplyToCommand(client, "%S That is an invalid number", TAG);

				return Plugin_Handled;
			}
			if (colorblue < 0)
			{
				colorblue = 0;
			}
			if (colorblue > 255)
			{
				colorblue = 255;
			}
			
			SetEntityRenderColor(client, colorred, colorgreen, colorblue, 255);
		  }
	   }
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	return Plugin_Handled;
}

//////////////////////////
//G L O W  C O M M A N D//
//////////////////////////
Glow(client)
{
	CreateParticle("player_recent_teleport_blue", 100.0, client, ATTACH_NORMAL);
	CreateParticle("player_recent_teleport_red", 100.0, client, ATTACH_NORMAL);
	CreateParticle("critical_grenade_blue", 100.0, client, ATTACH_NORMAL);
	CreateParticle("critical_grenade_red", 100.0, client, ATTACH_NORMAL);
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
			}
		}
		else
		{
			CPrintToChat(client, "%s %t", TAG, "NoAccess");
		}
	}
	return Plugin_Handled;
}


public Action:Timer_glow(Handle:hTimer, any:client)
{
	pGlow[client] = false;
}
////////////////////
//S W A P  T E A M//
////////////////////
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

////////////////////////////////
//P R E M I U M  C O M M A N D//
////////////////////////////////
public Action:Say(client, args)
{
	
	if(cEnable && IsValidEntity(client))
	{
		new String:message[192];
		GetCmdArgString(message, sizeof(message));
		StripQuotes(message);
		new String:trial[32];
		GetClientCookie(client, pTrialCookie, usedTrial, sizeof(usedTrial));
		new cookie = StringToInt(usedTrial);
		if(StrEqual(message, "!premium"))
		{
			if(GetUserFlagBits(client) & PREMIUMFLAG)
			{
				DisplayPremiumFeatures(client);
			}
			else if(cookie == 0 && cTrial)
			{
				Format(trial, sizeof(trial), "1");
				SetClientCookie(client, pTrialCookie, bool:StringToInt(usedTrial)?"0":"1");
				CPrintToChat(client, "%s %t", TAG, "TrialActivated");
				Premium(client);
				pFov[client] = cDefaultFov;
				pTrial[client] = true;
				tTrial[client] = CreateTimer(cTrialLength, Timer_Trial, client);
			}
			else
			{
				CPrintToChat(client, "%s %t", TAG, "TrialUsed");
			}
		}
		
		if(StrEqual(message, "!features"))
		{
			DisplayPremiumFeatures(client);
		}
	}
}


/////////////////////////////
//T R I A L  C O M M A N D//
///////////////////////////
public Action:Timer_Trial(Handle:hTimer, any:client)
{
	if(cEnable && IsClientInGame(client) && IsValidEntity(client))
	{
		pTrial[client] = false;
		CPrintToChat(client, "%s %t.", TAG, "TrialEnded");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

//////////////////////////
//P R E M I U M  M E N U//
//////////////////////////
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
		if(cGlow)
		DrawPanelText(featurepanel, "- Ability to use !glow");
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

//////////////////////////////
//P A N E L  H A N D L E R S//
//////////////////////////////
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

/////////////////////
//P A R T I C L E S//
/////////////////////
stock Handle:CreateParticle(String:type[], Float:time, entity, attach=NO_ATTACH, Float:xOffs=0.0, Float:yOffs=0.0, Float:zOffs=0.0)
{
	new particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(particle)) {
		decl Float:pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		pos[0] += xOffs;
		pos[1] += yOffs;
		pos[2] += zOffs;
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", type);
		if (attach != NO_ATTACH) {
			SetVariantString("!activator");
			AcceptEntityInput(particle, "SetParent", entity, particle, 0);
			if (attach == ATTACH_HEAD) {
				SetVariantString("head");
				AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", particle, particle, 0);
			}
		}
		DispatchKeyValue(particle, "targetname", "present");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		return CreateTimer(time, DeleteParticle, particle);
	} else {
		LogError("(CreateParticle): Could not create info_particle_system");
	}
	
	return INVALID_HANDLE;
}
public Action:DeleteParticle(Handle:timer, any:particle)
{
	if (IsValidEdict(particle)) {
		new String:classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		
		if (StrEqual(classname, "info_particle_system", false)) {
			RemoveEdict(particle);
		}
	}
}



////////////////////////////
//R E F R E S H  C V A R S//
////////////////////////////
public Action:Command_Refresh(client, args)
{
	if(IsValidEntity(client))
	{
		ReplyToCommand(client, "%s Successfully refreshed all cvars.", "[Premium]");
	}
	ReloadConvars();
	return Plugin_Handled;
}



//////////////////////////
//R E S E T  T R I A L//
//////////////////////////
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
		ReplyToCommand(client, "[Premium] Trial reset!");
		CPrintToChat(target_list[i], "%s %t", TAG, "TrialReset");
	}
	
	return Plugin_Handled;
}

//////////////////////////
//C R E A T E  T R I A L//
//////////////////////////
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

///////////////
//S T O C K S//
///////////////
Premium(client)
{
if( IsValidEntity(client)  && IsClientInGame(client) && IsPlayerAlive(client) )
	{
	new health = GetClientHealth(client);
	new TFClassType:pClass = TF2_GetPlayerClass(client);
	
	if(cHPBoost > 0)
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
	SetEntityRenderColor(client, 255, 255, 255, 255);
	
	pSpeed[client] = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");
	
	if(pFov[client] == 0)
	pFov[client] = cDefaultFov;
	
	SetEntData(client, offsFOV, pFov[client], 1);
	}
}


///////////////////
//Reload Convars//
/////////////////
ReloadConvars()
{
	cEnable = GetConVarInt(cvar_enable);
	cMySql = GetConVarInt(cvar_mysql);
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
	cFakeKill = GetConVarInt(cvar_fakekill);
	cDefaultFov = GetConVarInt(cvar_defaultfov);
	cDark = GetConVarInt(cvar_dark);
	cGlow = GetConVarInt(cvar_glow);
	cStunballs = GetConVarInt(cvar_stunballs);
	cJarates = GetConVarInt(cvar_jarates);
	cUber = GetConVarFloat(cvar_uber);
	cRespawn = GetConVarInt(cvar_respawn);
	cSwap = GetConVarInt(cvar_swapteams);
	cTrial = GetConVarInt(cvar_trial);
	cTrialLength = GetConVarFloat(cvar_trial_length);
	cFireArrows = GetConVarInt(cvar_firearrows);
	cCloak = GetConVarInt(cvar_cloak);
	cMetal = GetConVarInt(cvar_metal);
	cBhop = GetConVarInt(cvar_bhop);
	cPyrofly = GetConVarInt(cvar_pyrofly);
	mySQL_connect();
}

//////////////////////////
//G r e n a d e  A m m o//
////////////////////////
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

///////////////
//C o l o u r//
//////////////
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

///////////////////////
//D I S C O N N E C T//
///////////////////////
public OnClientDisconnect(client)
{
	pTrial[client] = false;
	pFirstSpawn[client] = true;
}

////////////////
// M Y S Q L // 
//////////////

public mySQL_connect()
{
	if(cMySql == 1) // Chck if mysql is enabled
	{
		Database = SQL_Connect("premium", true, Error, sizeof(Error)); //Use Premium settings in database.cfg
		new String:ident[16];
		SQL_ReadDriver(Database, ident, sizeof(ident));
		
		if (strcmp(ident, "mysql") == 0)
		{
			if (Database == INVALID_HANDLE)
			{
				PrintToServer("Cannot connect to database!: %s", Error);
				CloseHandle(Database);
			} else {
				PrintToServer("[Premium] Connected to database! Using mySQL database");
			}
		} else if (strcmp(ident, "sqlite") == 0) {
			PrintToServer("[Premium] Connected to database! Using SQLite database");
		}else {
			PrintToServer("[Premium] database disabled!, Using premium flags");
		}
	}
}
/////////////////////////////////
// M Y S Q L  C O M M A N D S //
///////////////////////////////

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
				ReplyToCommand(client, "%s User Not Found!" ,TAG);
				return Plugin_Handled;
			}

			if(args < 1)
			{ 
				ReplyToCommand(client, "%s Please enter client name", TAG);
				return Plugin_Handled;
			}
			for (new i = 0; i <target_count; i++)
			{
				// Start insertign the player in to the database
				new String:name[32];
				new String:steamid[40];
				GetClientName(target_list[i], name, sizeof(name));
				GetClientAuthString(target_list[i], steamid, 32);
				new String:queryInsert[300];
				Format(queryInsert, sizeof(queryInsert), "INSERT INTO premium (name, steamid) VALUES ('%s', '%s')", name, steamid);
				new Handle:queryH = SQL_Query(Database, queryInsert);
				
				if(queryH != INVALID_HANDLE)
				{
					CReplyToCommand(client,"[Premium] Client %s successfuly added!", name);
				} else {
					CReplyToCommand(client, "[Premium] Client %s Not been Added", name);
				}
				return Plugin_Handled;
			}
		}else{
			CReplyToCommand(client, "%s Command cannot be used when database is disabled!",TAG);
			return Plugin_Handled;
			}
		
		} else {
			CReplyToCommand(client,"%s You do not have Access!", TAG);
			return Plugin_Handled;
		
	}	
	return Plugin_Handled;
}

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
				CReplyToCommand(client, "[Premium] User Not Found!");
				return Plugin_Handled;
			}

			if(args < 1)
			{ 
				CReplyToCommand(client, "[Premium] Please enter client name");
				return Plugin_Handled;
			}
			for (new i = 0; i <target_count; i++)
			{
				// Start removing the player in to the database
				new String:queryInsert[300];
				Format(queryInsert, sizeof(queryInsert), "DELETE FROM premium WHERE name='%s'", target_list[i]);
				new Handle:queryH = SQL_Query(Database, queryInsert);
				if(queryH != INVALID_HANDLE)
				{
					if(SQL_FetchRow(queryH))
					{
						CReplyToCommand(client, "[Premium] User has been removed");
					} 
					else 
					{
						SQL_GetError(Database, Error, sizeof(Error));
						CReplyToCommand(client, "[Premium] User was not removed: %s", Error);
					}
				}
				return Plugin_Handled;
			} 
		}else{
			CReplyToCommand(client, "%s Command cannot be used when database is disabled!",TAG);
			return Plugin_Handled;
		}
	}else{
			ReplyToCommand(client,"[Premium] You do not have Access!");
			return Plugin_Handled;
		}
	return Plugin_Handled;
}

/////////////////////////////////////
// D A T A B A S E  C O M M A N D //
///////////////////////////////////
public Action:create_PremDatabase(client, args)
{
	if(cMySql == 1)
	{
	new String:CreateDatabase[250];

	new String:ident[16];
	SQL_ReadDriver(Database, ident, sizeof(ident));
	if (strcmp(ident, "mysql") == 0)
	{
		
		Format(CreateDatabase, sizeof(CreateDatabase), "CREATE TABLE IF NOT EXISTS `premium` ( `name` varchar(32) NOT NULL, `steamid` varchar(32) NOT NULL ) ENGINE=InnoDB DEFAULT CHARSET=latin1;");
		new Handle:queryH = SQL_Query(Database, CreateDatabase);
		
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
		new Handle:queryH = SQL_Query(Database, CreateDatabase);
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

////////////////////////////////////
// CHECK USER IS ON THE DATABASE //
//////////////////////////////////

public OnClientAuthorized(client)
{
 if(cMySql == 1)
	{
	new String:SteamAuth2[32];
	GetClientAuthString(client, SteamAuth2, sizeof(SteamAuth2));
	new String:getquery[200];
	Format(getquery, sizeof(getquery), "SELECT steamid FROM premium WHERE steamid='%s'", SteamAuth2);
	new Handle:queryH = SQL_Query(Database, getquery);
	
	if(queryH != INVALID_HANDLE)
	{
		if(SQL_FetchRow(queryH))
		{
			SetUserFlagBits(client, PREMIUMFLAG);
		}
	} else {
		SQL_GetError(Database, Error, sizeof(Error));
		ReplyToCommand(client, "User was not given premium %s", Error);
	}
  }
}

