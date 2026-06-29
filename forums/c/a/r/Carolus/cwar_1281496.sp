/**
	I recommend keeping only admin_flatfile.smx and cWar.smx for a good War server configuration
	One addition I suggest is to add exec esl5on5.cfg in your server.cfg
**/
#include <sourcemod>
#include <sdktools>

#define INTERP_RATIO 1
#define YELLOW 0x01
#define GREEN 0x04
#define TEAM_TS 2
#define USERNAME_MAXLENGTH 64
#define DEMONAME_MAXLENGTH 8
#define CVARNAME_MAXLENGTH 64
#define STEAMID_MAXLENGTH 64
#define TEAM_CTS 3

#define MATCH_NOT_STARTED 0
#define MATCH_START 1
#define MATCH_RR_ONE 2
#define MATCH_LIVE_ONE 3
#define MATCH_HT 4
#define MATCH_RR_TWO 5
#define MATCH_LIVE_TWO 6
#define MINRATE 35000
#define MAXRATE 80000
new matchLevel = 0;

// Declare offsets
new xVelocityOffset;
new yVelocityOffset;
new PlayerStateOffset;
new PlayerCashOffset;

new svpure = 0;
new pureLoaded = 0;
new isFirstMapLoad =1;
new teamAPoints = 0;
new teamBPoints = 0;
new maxRounds = 15;

new teamAHTPoints = 0;
new teamBHTPoints = 0;


new Handle:cvarTickrate;
new Handle:cvarDefaultPass;
new allCVARsOK = true;


new tickrate = 66;
new String:defaultPass[128]="";
new String:rdemoName[DEMONAME_MAXLENGTH]="";

public Plugin:myinfo = 
{
	name = "cWar",
	author = "Carolus",
	description = "War Fair-Play Plugin",
	version = "1.1.3",
	url = "http://www.caroswar.tk/"
};

public onSVPasswordCVARChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Format(defaultPass,sizeof(defaultPass),"%s",newValue);
}

public startRecording()
{
	ServerCommand("tv_stoprecord");
	
	decl String:name[DEMONAME_MAXLENGTH];
	
	for(new i=1; i <= 999; i++)
	{
		Format(name,sizeof(name),"%d.dem",i);
		if (!FileExists(name))
		{
			break;
		}
	}

	// Remember the demo name
	Format(rdemoName,sizeof(rdemoName),"%s",name);	
	
	ServerCommand("tv_record %s", name);
	PrintToChatAll("%c[cWar]%c SourceTV recording started.",GREEN,YELLOW);
}

public stopRecording()
{
	ServerCommand("tv_stoprecord");
	PrintToChatAll("%c[cWar]%c SourceTV recording ended.",GREEN,YELLOW);
	PrintToChatAll("%c[cWar]%c SourceTV demo name is %s",GREEN,YELLOW,rdemoName);
}


new Handle:forceCV = INVALID_HANDLE;
new numberOfForcedCV = 0;
public setForcedCVAR(const String:convar[],value)
{
	decl String:buff[CVARNAME_MAXLENGTH];
	if (forceCV == INVALID_HANDLE)
		forceCV = CreateDataPack();
		
	ResetPack(forceCV);
	// Skip to end
	for(new i=0; i < numberOfForcedCV; i++)
	{		
		ReadPackString(forceCV, buff, sizeof(buff));
		ReadPackCell(forceCV);
	}
	
	WritePackString(forceCV, convar);
	WritePackCell(forceCV, value);
	numberOfForcedCV++;
	
	ServerCommand("%s %d",convar,value);
}


public Action:runCVARCheck(Handle:timer, any:bla)
{
	if (forceCV == INVALID_HANDLE)
		forceCV = CreateDataPack();
		
	ResetPack(forceCV);
	
	decl String:buff[CVARNAME_MAXLENGTH];
	new val = -1;
	new Handle:conHandle;
	for(new i=0; i < numberOfForcedCV; i++)
	{		
		ReadPackString(forceCV, buff, sizeof(buff));
		val = ReadPackCell(forceCV);
		conHandle = FindConVar(buff);
		if (GetConVarInt(conHandle) == val)
		{
			enableCheatFlagOnCVAR(buff);
			PrintToChatAll("%c[cWar]%c CVAR Check OK %s %d.",GREEN,YELLOW,buff,val);
		} else {
			PrintToChatAll("%c[cWar]%c CVAR Check FAILED %s %d != %d !!!BUG!!!",GREEN,YELLOW,buff,val,GetConVarInt(conHandle));
			allCVARsOK = false;
		}
	}	
	
	// We will not need the datapack anymore
	CloseHandle(forceCV);
}

public enableCheatFlagOnCVAR(const String:convar[])
{
	if (GetCommandFlags(convar) != INVALID_FCVAR_FLAGS)
	{
		if (!(GetCommandFlags(convar)&FCVAR_CHEAT))
		{
			SetCommandFlags(convar,GetCommandFlags(convar)|FCVAR_CHEAT);
		}			
	}
}

/*
public ForceVarListener(Handle:convar, const String:oldValue[], const String:newValue[])
{
	decl String:cvName[64];
	GetConVarName(convar, cvName, sizeof(cvName)); 
	
	new forcedVal = getForcedCVARValue(cvName);	
	if (forcedVal != -1)
	{			
		ServerCommand("%s %d",cvName,forcedVal);
	}		
	
}*/

public getForcedCVARValue(const String:convar[])
{
	if (forceCV == INVALID_HANDLE)
		forceCV = CreateDataPack();
		
	ResetPack(forceCV);	
	decl String:buff[CVARNAME_MAXLENGTH];
	new value = 0;
	for(new i=0; i < numberOfForcedCV; i++)
	{		
		ReadPackString(forceCV, buff, sizeof(buff));
		value = ReadPackCell(forceCV);
		if (strcmp(buff, convar, false) == 0)
			return value;
	}
	return -1;
}


public onTickRateCVARChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	tickrate = StringToInt(newValue);
	UnhookConVarChange(convar,onTickRateCVARChange);
}

public runCVAREnforcements()
{

	if (forceCV == INVALID_HANDLE)
		forceCV = CreateDataPack();
		
	ResetPack(forceCV,true);
	numberOfForcedCV = 0;
	
	setForcedCVAR("sv_cheats",0);	
	setForcedCVAR("sv_minrate",MINRATE);
	setForcedCVAR("sv_maxrate",MAXRATE);
	setForcedCVAR("sv_mincmdrate",tickrate);
	setForcedCVAR("sv_minupdaterate",tickrate);
	
	setForcedCVAR("sv_maxcmdrate",tickrate);
	setForcedCVAR("sv_maxupdaterate",tickrate);
	
	setForcedCVAR("sv_client_max_interp_ratio",INTERP_RATIO);
	setForcedCVAR("sv_client_min_interp_ratio",INTERP_RATIO);
	setForcedCVAR("sv_client_predict",1);
	setForcedCVAR("sv_pure_kick_clients",1);
	setForcedCVAR("sv_consistency",1);
	
	setForcedCVAR("sv_nonemesis",1);
	setForcedCVAR("sv_nomvp",1);
	setForcedCVAR("sv_nostats",1);
	setForcedCVAR("sv_nowinpanel",1);
	setForcedCVAR("sv_disablefreezecam",1);	
	setForcedCVAR("sv_allowupload", 0);
	setForcedCVAR("sv_accelerate", 5);
	setForcedCVAR("sv_stopspeed", 75); // When doing mp_restartgame 1 this changes to 75 but cvarlist says its default is 100? Weird..
	setForcedCVAR("sv_turbophysics", 1);
	setForcedCVAR("sv_allowminmodels", 0);
	setForcedCVAR("sv_voiceenable", 1);
	setForcedCVAR("sv_hudhint_sound", 0);
	setForcedCVAR("sv_competitive_minspec", 1);
	
	

	
	// SourceTV
	
	setForcedCVAR("tv_enable", 1);
	setForcedCVAR("tv_delay", 90);
	setForcedCVAR("tv_snapshotrate", 24);
	setForcedCVAR("tv_autorecord", 0);
	setForcedCVAR("tv_transmitall", 1);
	
	// Force defaults
	setForcedCVAR("sv_footsteps", 1);
	setForcedCVAR("sv_friction", 4);
	setForcedCVAR("sv_allow_color_correction", 0);
	setForcedCVAR("sv_allow_wait_command", 0);	
	setForcedCVAR("sv_airaccelerate", 10);
	setForcedCVAR("sv_ladder_angle", 0);
	setForcedCVAR("sv_ladder_dampen", 0);
	setForcedCVAR("sv_max_usercmd_future_ticks", 8);
	setForcedCVAR("sv_maxreplay", 0);
	setForcedCVAR("sv_maxspeed", 320);
	setForcedCVAR("sv_maxvelocity", 3500);
	setForcedCVAR("sv_pushaway_clientside", 0);
	setForcedCVAR("sv_pushaway_force", 30000);
	setForcedCVAR("sv_pushaway_max_force", 1000);
	setForcedCVAR("sv_pushaway_min_player_speed", 75);
	setForcedCVAR("sv_stepsize", 18);
	setForcedCVAR("sv_wateraccelerate", 10);
	setForcedCVAR("decalfrequency", 60);
	setForcedCVAR("host_framerate", 0);	
	setForcedCVAR("sv_waterdist", 12);
	setForcedCVAR("sv_waterfriction", 1);
	setForcedCVAR("sv_gravity", 800);
	setForcedCVAR("sv_enablebunnyhopping", 0);	
	
	//areRateHooksInPlace = 1;
	CreateTimer(10.0, runCVARCheck,1);
}


//####################################################################"



public OnClientPutInServer(client)
{
	if ( !IsFakeClient(client))
	{
		CreateTimer(1.5, InitializeClient,client); // Must take more than 1 sec
	}
}



/*
public MakeRep(const String:convar[])
{
	if (GetCommandFlags(convar) != INVALID_FCVAR_FLAGS)
	{
		SetCommandFlags(convar,GetCommandFlags(convar)|FCVAR_ARCHIVE);
		SetCommandFlags(convar,GetCommandFlags(convar)|FCVAR_REPLICATED);
	}
}

public Action:DoTest(client, args)
{
	new String:strVar[10];
	GetClientInfo(client, "mat_dxlevel", strVar, sizeof(strVar));
	//new rate = StringToInt(strRate);
	PrintToConsole(client, " mat_dxlevel is %s" ,strVar);
	return Plugin_Handled;	
}*/



public Action:InitializeClient(Handle:timer, any:client){
		
		showConsoleWelcome(client);
		decl String:pname[USERNAME_MAXLENGTH];
		GetClientName( client, pname, sizeof(pname));
		decl String:steamId[STEAMID_MAXLENGTH];
		GetClientAuthString(client, steamId, sizeof(steamId));
		PrintToChatAll("%c[cWar]%c %s (%s) has joined the game.",GREEN,YELLOW,pname,steamId);
		if (!allCVARsOK)
		{
			PrintToChatAll("%c[cWar]%c is running with SEVERE problems!!",GREEN,YELLOW,pname,steamId);
		}
		CreateTimer(5.0, showAdminHelp,client);		
				
}




public Action:startMatch(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (matchLevel < MATCH_START)
		{	
			matchLevel = MATCH_START;
			
			
			decl String:buff[64];
			GetCmdArg(1,buff, sizeof(buff));
			maxRounds = StringToInt(buff);
			
			if (maxRounds <= 0)
				maxRounds = 15;
			
			teamAPoints = 0;
			teamBPoints = 0;
						
			
			startRecording();			
			PrintToChatAll("%c[cWar]%c Match is starting. MaxRounds set to %d.",GREEN,YELLOW,maxRounds);
					
			matchLevel = MATCH_RR_ONE;
			CreateTimer(3.0, roundRestart,1);	
			return Plugin_Handled;
		} else {
			PrintToChat(client,"%c[cWar]%c The match cannot be started now.",GREEN,YELLOW);
			return Plugin_Handled;
		}
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
	
}

public Action:changeMap(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		decl String:buff[64];
		GetCmdArg(1,buff, sizeof(buff));
		if (IsMapValid(buff))
		{
			ServerCommand("changelevel %s",buff);
		} else {
			PrintToChat(client,"%c[cWar]%c %s is not a valid map. Type cw_listmaps.",GREEN,YELLOW,buff);
		}
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
	
}

public Action:continueMatch(client, args)
{	
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (matchLevel >= MATCH_HT && matchLevel != MATCH_RR_TWO)
		{
			teamAPoints = teamAHTPoints;
			teamBPoints = teamBHTPoints;			
			
			matchLevel = MATCH_RR_TWO;
			PrintToChatAll("%c[cWar]%c Match second half started.",GREEN,YELLOW);
			CreateTimer(3.0, roundRestart,1);
		} else {
			PrintToChat(client,"%c[cWar]%c Cannot continue half-time now.",GREEN,YELLOW);
			return Plugin_Handled;
		}		
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}

public Action:ban(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{		
		decl String:buff[64];
		GetCmdArg(1,buff, sizeof(buff));

		new maxclients = GetMaxClients();
		decl teams[maxclients];
		for(new j=1; j <= maxclients; j++)
		{
			if (IsClientInGame(j))
			{
				if (GetClientTeam(j) == TEAM_CTS)
				{
					teams[j] = TEAM_CTS;
				} else if (GetClientTeam(j) == TEAM_TS) {
					teams[j] = TEAM_TS;
				} else {
					teams[j] = -1;
				}
			}
		}
		
		
		if (strcmp(buff, "t", false) == 0)
		{
			// ban all T's

			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientInGame(j))
				{
					if (teams[j] == TEAM_TS)
					{
						ServerCommand("banid 5 %d kick",GetClientUserId(j));
					}
				}
			}
		} else if (strcmp(buff, "ct", false) == 0)
		{
			// ban all CT's
			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientInGame(j))
				{
					if (teams[j] == TEAM_CTS)
					{					
						ServerCommand("banid 5 %d kick",GetClientUserId(j));
					}
				}
			}
		} else if (strcmp(buff, "g", false) == 0)
		{
			// ban all non-ADMINs
			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientConnected(j) && !IsFakeClient(j))
				{
					if (GetUserAdmin(j) == INVALID_ADMIN_ID)
					{
						ServerCommand("banid 5 %d kick",GetClientUserId(j));
					}
				}				
			}
		} else {
			// try to ban this userId
			new userId = StringToInt(buff);
			ServerCommand("banid 5 %d kick",userId);
		}
				
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}

public Action:kick(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{		
		decl String:buff[64];
		GetCmdArg(1,buff, sizeof(buff));

		new maxclients = GetMaxClients();
		decl teams[maxclients];
		for(new j=1; j <= maxclients; j++)
		{
			if (IsClientInGame(j))
			{
				if (GetClientTeam(j) == TEAM_CTS)
				{
					teams[j] = TEAM_CTS;
				} else if (GetClientTeam(j) == TEAM_TS) {
					teams[j] = TEAM_TS;
				} else {
					teams[j] = -1;
				}
			}
		}
		
		
		if (strcmp(buff, "t", false) == 0)
		{
			// kick all T's

			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientInGame(j))
				{
					if (teams[j] == TEAM_TS)
					{
						KickClient(j, "Kicked by admin");
					}
				}
			}
		} else if (strcmp(buff, "ct", false) == 0)
		{
			// kick all CT's
			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientInGame(j))
				{
					if (teams[j] == TEAM_CTS)
					{					
						KickClient(j, "Kicked by admin");
					}
				}
			}
		} else if (strcmp(buff, "g", false) == 0)
		{
			// kick all non-ADMINs
			for(new j=1; j <= maxclients; j++)
			{
				if (IsClientConnected(j) && !IsFakeClient(j))
				{
					if (GetUserAdmin(j) == INVALID_ADMIN_ID)
					{
						KickClient(j, "Kicked by admin");
					}
				}				
			}
		} else {
			// try to kick this userId
			new userId = StringToInt(buff);
			ServerCommand("kickid %d Kicked by admin",userId);
		}
				
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}

public Action:listMaps(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{		
		new Handle:dir = OpenDirectory("maps");
		decl String:buff[128];
		new hasNext = false;
		do
		{
			hasNext = ReadDirEntry(dir, buff, sizeof(buff));
			if (strlen(buff) > 3)
			{
				if (strcmp(buff[strlen(buff)-3], "bsp", false) == 0)
				{
					Format(buff,strlen(buff)-3,"%s",buff);
					if ((strcmp(buff, "test_speakers", false) != 0) && (strcmp(buff, "test_hardware", false) != 0))
					{
						PrintToConsole(client,"Map %s",buff);
					}					
				}
			}			
		}
		while (hasNext);
		CloseHandle(dir);
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}
public Action:changePass(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		decl String:buff[64];
		GetCmdArg(1,buff, sizeof(buff));
		if (strlen(buff) > 0)
		{
			ServerCommand("sv_password %s",buff);
			PrintToChat(client,"%c[cWar]%c You changed sv_password to %s",GREEN,YELLOW,buff);
		} else {
			PrintToChat(client,"%c[cWar]%c You need to type a new pass. Ex: cw_pass pw1",GREEN,YELLOW);
		}
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;	
}



public Action:adminSay(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		decl String:buff[64];
		GetCmdArgString(buff, sizeof(buff));
		if (strlen(buff) > 0)
		{
			ServerCommand("say %s",buff);
		}
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;	
		
}


public OnClientDisconnect (client)
{
	CreateTimer(3.0, checkIfServerIsEmpty,client);
}

public Action:checkIfServerIsEmpty(Handle:timer, any:client)
{
	new maxclients = GetMaxClients();
	new amountOfPlayers = 0;
	for(new i=1; i <= maxclients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{			
			amountOfPlayers++;		
		}
	}	
	
	if (amountOfPlayers == 0)
	{
		if (strlen(defaultPass) > 0)
		{
			ServerCommand("sv_password %s",defaultPass);			
		}
		stopRecording();
		
		matchLevel = MATCH_NOT_STARTED;
	}
}


public Action:endMatch(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if (matchLevel >= MATCH_START)
		{				
			PrintToChatAll("%c[cWar]%c Match ended by admin.",GREEN,YELLOW);
			printFinalScores();
			matchLevel = MATCH_NOT_STARTED;
			stopRecording();
		} else {
			PrintToChat(client,"%c[cWar]%c Not in match.",GREEN,YELLOW);
		}
	} else {
		PrintToChat(client,"%c[cWar]%c You are not an admin. Type cw_help in console.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}



public Action:printHelp(client, args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		PrintToConsole(client, "-------------------------------------------------------------------------------");
		PrintToConsole(client, "cWar Plugin v1.1.3 ( http://www.caroswar.tk )");
		PrintToConsole(client,"   - cWar -");
		PrintToConsole(client,"cWar : You can view cWar's status by typing cw_status in console.");
		PrintToConsole(client,"   - Rates -");
		PrintToConsole(client,"cWar : You can inspect rates by typing cw_rates in console.");
		PrintToConsole(client,"   - Match -");
		PrintToConsole(client,"cWar : You can start a match by typing cw_match <maxrounds> in console. Example: cw_match 15 ");
		PrintToConsole(client,"cWar : You can continue a match by typing cw_match_continue in console (after half time).");
		PrintToConsole(client,"cWar : You can force a match to end by typing cw_match_end in console.");
		PrintToConsole(client,"cWar : You can see the current match score by typing cw_score in console (in match only)");
		PrintToConsole(client,"   - Admin -");
		PrintToConsole(client,"cWar : You can talk as an admin by typing cw_say <message> .Example: cw_say hello world!");
		PrintToConsole(client,"cWar : You can list all available maps by typing cw_listMaps in console.");
		PrintToConsole(client,"cWar : You can change map by typing cw_map <mapname> in console. Example: cw_map de_dust2");		
		PrintToConsole(client,"cWar : You can change the sv_password by typing cw_pass <password> in console. Example: cw_pass pw1");
		PrintToConsole(client,"cWar : You can kick players by typing cw_kick <id> in console. <id> can be t (terrorists), ct (counter-terrorists), g (guests = non-admins) , or even a userid (use status). Example cw_kick t");		
		PrintToConsole(client,"cWar : You can ban players for 5 min by typing cw_ban <id> in console. <id> can be t (terrorists), ct (counter-terrorists), g (guests = non-admins) , or even a userid (use status). Example cw_ban  t");		
		PrintToConsole(client, "-------------------------------------------------------------------------------");
	} else {
		PrintToConsole(client,"-------------------------------------------------------------------------------");
		PrintToConsole(client,"cWar Plugin v1.1.3 ( http://www.caroswar.tk )");
		PrintToConsole(client,"cWar : You can inspect rates by typing cw_rates in console.");
		PrintToConsole(client,"cWar : You can view cWar's status by typing cw_status in console.");
		PrintToConsole(client,"cWar : You can see the current match score by typing cw_score in console (in match only)");
		PrintToConsole(client, "-------------------------------------------------------------------------------");
	}
	return Plugin_Handled;
}


public OnPluginStart()
{

	cvarTickrate = CreateConVar("cw_tickrate", "66", "Sets the tickrate cWar should adjust to.");
	cvarDefaultPass = CreateConVar("cw_defaultpass", "", "Sets the sv_password cWar will fall back to when the server is empty.", FCVAR_NOTIFY);
	
	HookConVarChange(cvarTickrate,onTickRateCVARChange);
	HookConVarChange(cvarDefaultPass,onSVPasswordCVARChange);
	
	fixPure();	
	
	RegConsoleCmd("cw_rates", printRates);
	RegConsoleCmd("cw_match", startMatch);
	RegConsoleCmd("cw_match_continue", continueMatch);
	RegConsoleCmd("cw_match_end", endMatch);
	RegConsoleCmd("cw_map", changeMap);
	RegConsoleCmd("cw_help", printHelp);
	RegConsoleCmd("cw_score", showScore);
	RegConsoleCmd("cw_kick", kick);
	RegConsoleCmd("cw_ban", ban);
	RegConsoleCmd("cw_listMaps", listMaps);
	RegConsoleCmd("cw_pass", changePass);
	RegConsoleCmd("cw_say", adminSay);
	RegConsoleCmd("cw_status", showStatus);
	
	HookEvent("player_jump",playerJumpEvent);
	HookEvent("round_start",RoundStartEvent);
	HookEvent("round_end",RoundEndEvent);
	
	// Find offsets
	xVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecVelocity[0]");
	if (xVelocityOffset == -1)
		SetFailState("[cWar] Error: Failed to find CBasePlayer.m_vecVelocity[0] offset, aborting");	
  
	yVelocityOffset=FindSendPropOffs("CBasePlayer","m_vecVelocity[1]");  
	if (yVelocityOffset == -1)
		SetFailState("[cWar] Error: Failed to find CBasePlayer.m_vecVelocity[1] offset, aborting");
	
  
	PlayerStateOffset = FindSendPropOffs("CCSPlayer","m_iPlayerState");  	
	if (PlayerStateOffset == -1)
		SetFailState("[cWar] Error: Failed to find CCSPlayer.m_iPlayerState offset, aborting");
	
	PlayerCashOffset = FindSendPropOffs("CCSPlayer","m_iAccount");  	
	if (PlayerCashOffset == -1)
		SetFailState("[cWar] Error: Failed to find CCSPlayer.m_iAccount offset, aborting");	

			
	AddCommandListener(pureListener,"sv_pure");
	
	CreateTimer(10.0,timedConvarForcing,1);
		

}

public Action:timedConvarForcing(Handle:timer, any:client)
{
	runCVAREnforcements();
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (matchLevel == MATCH_LIVE_ONE || matchLevel == MATCH_LIVE_TWO)
	{
		new maxclients = GetMaxClients();
		decl String:pname[45];
		decl String:buffer[64];
		new cash = 0;
		new team = 0;
		for(new j=1; j <= maxclients; j++)
		{
			if (IsClientConnected(j) && IsClientInGame(j))
			{
				cash = GetEntData(j, PlayerCashOffset);
				GetClientName(j, pname, sizeof(pname));					
				team = GetClientTeam(j);
				
				decl String:strCash[32];
				
				if (cash < 10)
				{
					Format(strCash,sizeof(strCash),"        %d",cash);
				} else if (cash < 100)
				{
					Format(strCash,sizeof(strCash),"      %d",cash);
				} else if (cash < 1000)
				{
					Format(strCash,sizeof(strCash),"    %d",cash);
				} else if (cash < 10000)
				{
					Format(strCash,sizeof(strCash),"  %d",cash);
				} else
				{
					Format(strCash,sizeof(strCash),"%d",cash);
				}
				
				if (team == TEAM_TS)
				{
					Format(buffer,sizeof(buffer),"%c[cWar]%c $ %s : %s",GREEN,YELLOW,strCash,pname);
					printToTeam(buffer,TEAM_TS);
				} else if (team == TEAM_CTS){
					Format(buffer,sizeof(buffer),"%c[cWar]%c $ %s : %s",GREEN,YELLOW,strCash,pname);
					printToTeam(buffer,TEAM_CTS);
				}
			}
		}		
	}

}

public RoundEndEvent(Handle:event,const String:name[],bool:dontBroadcast)
{	
	if (matchLevel == MATCH_LIVE_ONE || matchLevel == MATCH_LIVE_TWO)
	{
		new winner = GetEventInt(event, "winner");
		if (winner == TEAM_TS)
		{
			decl String:buffer[64];
			if (matchLevel == MATCH_LIVE_ONE)
			{
				// teamA = CT
				// teamB = T
				// winners = T
				// winners = teamB
				teamBPoints = teamBPoints + 1;			
				new roundsLeft = getRoundsLeft();
				Format(buffer,sizeof(buffer),"%c[cWar]%c Your team lost. You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
				printToTeam(buffer,TEAM_CTS);
				Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
				printToTeam(buffer,TEAM_CTS);
				
				Format(buffer,sizeof(buffer),"%c[cWar]%c Your team won! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
				printToTeam(buffer,TEAM_TS);
				Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
				printToTeam(buffer,TEAM_TS);
			} else {
				// teamA = T
				// teamB = CT
				// winners = T
				// winners = teamA
				teamAPoints = teamAPoints + 1;
				new roundsLeft = getRoundsLeft();
				
				if (roundsLeft != 0)
				{
					Format(buffer,sizeof(buffer),"%c[cWar]%c Your team lost. You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
					printToTeam(buffer,TEAM_CTS);
					Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
					printToTeam(buffer,TEAM_CTS);
					
					Format(buffer,sizeof(buffer),"%c[cWar]%c Your team won! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
					printToTeam(buffer,TEAM_TS);
					Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
					printToTeam(buffer,TEAM_TS);
				}
			}
			halfTimeIfNeeded();
			endMatchIfNeeded();
			
		} else if (winner == TEAM_CTS) {
			decl String:buffer[64];
			if (matchLevel == MATCH_LIVE_ONE)
			{
				// teamA = CT
				// teamB = T
				// winner = CT
				// winner = teamA
				teamAPoints = teamAPoints + 1;
				new roundsLeft = getRoundsLeft();
				
				Format(buffer,sizeof(buffer),"%c[cWar]%c Your team lost. You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
				printToTeam(buffer,TEAM_TS);
				Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
				printToTeam(buffer,TEAM_TS);
					
				Format(buffer,sizeof(buffer),"%c[cWar]%c Your team won! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
				printToTeam(buffer,TEAM_CTS);
				Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
				printToTeam(buffer,TEAM_CTS);
			} else {
				// teamA = T
				// teamB = CT
				// winner = CT
				// winner = teamB
				
				teamBPoints = teamBPoints + 1;
				new roundsLeft = getRoundsLeft();
				
				if (roundsLeft != 0)
				{
					Format(buffer,sizeof(buffer),"%c[cWar]%c Your team lost. You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
					printToTeam(buffer,TEAM_TS);
					Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
					printToTeam(buffer,TEAM_TS);
					
					Format(buffer,sizeof(buffer),"%c[cWar]%c Your team won! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
					printToTeam(buffer,TEAM_CTS);
					Format(buffer,sizeof(buffer),"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
					printToTeam(buffer,TEAM_CTS);
				}
			}
			halfTimeIfNeeded();
			endMatchIfNeeded();
		}
	
	} else if (matchLevel == MATCH_HT)
	{
		PrintToChatAll("%c[cWar]%c Waiting for admin to continue the match.",GREEN,YELLOW);
	}
}

public printFinalScores()
{
	decl String:buffer[64];
	if (matchLevel >= MATCH_HT)
	{
		if (teamAPoints > teamBPoints)
		{
			// T Wins
			Format(buffer,sizeof(buffer),"%c[cWar]%c You won the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			
			Format(buffer,sizeof(buffer),"%c[cWar]%c You lost the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
		} else if (teamAPoints < teamBPoints)
		{
			// CT Wins
			Format(buffer,sizeof(buffer),"%c[cWar]%c You won the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			
			Format(buffer,sizeof(buffer),"%c[cWar]%c You lost the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
		} else {
			// Draw
			PrintToChatAll("%c[cWar]%c The match was a draw! %d - %d.",GREEN,YELLOW,teamBPoints,teamAPoints);
		}
	} else {
		if (teamAPoints > teamBPoints)
		{
			// CT Wins
			Format(buffer,sizeof(buffer),"%c[cWar]%c You won the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			
			Format(buffer,sizeof(buffer),"%c[cWar]%c You lost the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
		} else if (teamAPoints < teamBPoints)
		{
			// T Wins
			Format(buffer,sizeof(buffer),"%c[cWar]%c You won the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			printToTeam(buffer,TEAM_TS);
			
			Format(buffer,sizeof(buffer),"%c[cWar]%c You lost the match! You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);
			printToTeam(buffer,TEAM_CTS);			
		} else {
			// Draw
			PrintToChatAll("%c[cWar]%c The match was a draw! %d - %d.",GREEN,YELLOW,teamBPoints,teamAPoints);
		}
	}
}

public endMatchIfNeeded()
{	
	if (matchLevel == MATCH_LIVE_TWO && getRoundsLeft() == 0)
	{		
		printFinalScores();
		matchLevel = MATCH_NOT_STARTED;		
		stopRecording();
	} else if (matchLevel == MATCH_LIVE_TWO)
	{
		if ((teamAPoints > maxRounds) || (teamBPoints > maxRounds))
		{
			printFinalScores();
			matchLevel = MATCH_NOT_STARTED;		
			stopRecording();
		}
	}
}
public getRoundsLeft()
{
	if (matchLevel == MATCH_LIVE_ONE)
	{
		return maxRounds - (teamAPoints + teamBPoints);
	} else {
		return maxRounds - ((teamAPoints + teamBPoints) - maxRounds);
	}
}
public halfTimeIfNeeded()
{
	if (matchLevel == MATCH_LIVE_ONE)
	{
		new roundsLeft = getRoundsLeft();
		if (roundsLeft == 0)
		{
			CreateTimer(1.2, halfTime,1);
		}
	}
}



public Action:halfTime(Handle:timer, any:num)
{
	matchLevel = MATCH_HT;
	
	// Remember the score before half-time
	teamAHTPoints = teamAPoints;
	teamBHTPoints = teamBPoints;
	
	PrintToChatAll("%c[cWar]%c Half time.",GREEN,YELLOW);
	new maxclients = GetMaxClients();
	decl teams[maxclients];
	for(new j=1; j <= maxclients; j++)
	{
		if (IsClientConnected(j) && IsClientInGame(j) && !IsFakeClient(j))
		{
			if (GetClientTeam(j) == TEAM_CTS)
			{
				teams[j] = TEAM_CTS;
			} else {
				teams[j] = TEAM_TS;
			}
		}		
	}		
	for(new j=1; j <= maxclients; j++)
	{
		if (IsClientConnected(j) && IsClientInGame(j) && !IsFakeClient(j))
		{
			if (teams[j] == TEAM_CTS)
			{
				ChangeClientTeam(j, TEAM_TS);
			} else {
				ChangeClientTeam(j, TEAM_CTS);
			}
		}		
	}
	ServerCommand("mp_restartgame 1");
}



public printToTeam(const String:message[],team)
{
	new maxclients = GetMaxClients();
	for(new j=1; j <= maxclients; j++)
	{
		if (IsClientConnected(j) && !IsFakeClient(j) && IsClientInGame(j))
		{
			if (GetClientTeam(j) == team)
			{
				PrintToChat(j,message);
			}
		}		
	}
}


public Action:roundRestart(Handle:timer, any:num)
{
	// This is superfluous
	if (matchLevel == MATCH_START)
		matchLevel = MATCH_RR_ONE;
	else if (matchLevel == MATCH_HT)
		matchLevel = MATCH_RR_TWO;
	// 
	
	
	if (num < 4)
	{
		PrintToChatAll("%c[cWar]%c Restart %d.",GREEN,YELLOW,num);
		ServerCommand("mp_restartgame 1");
		CreateTimer(2.0, roundRestart,(num+1));
	} else {		
		CreateTimer(2.0, printLive,1);
	}
}

public Action:printLive(Handle:timer, any:num)
{
	for(new i=1; i <= 15; i++)
	{
		PrintToChatAll("%c[cWar] LIVE! LIVE! LIVE!",GREEN);
	}

	if (matchLevel == MATCH_RR_ONE)
		matchLevel = MATCH_LIVE_ONE;
	else if (matchLevel == MATCH_RR_TWO)
		matchLevel = MATCH_LIVE_TWO;
	
		
	PrintToChatAll("%c[cWar]%c cWar v1.1.3 http://www.caroswar.tk",GREEN,YELLOW);
}

public Action:changeMapForPureLoad(Handle:timer, any:index)
{
	decl String:mapname[60];
	GetCurrentMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s",mapname);
}


public fixPure()
{
	if (pureLoaded == 0)
	{
		ServerCommand("sv_pure 2");
		svpure = 2;
		PrintToChatAll("%c[cWar]%c Forced sv_pure 2. Map will change in 30 sec.",GREEN,YELLOW);
		CreateTimer(30.0, changeMapForPureLoad,1);
	}
}

public OnMapStart()
{
	matchLevel = MATCH_NOT_STARTED;
	stopRecording();
	
	if (svpure == 2 && pureLoaded == 0)
	{
		if (isFirstMapLoad == 1)
		{
			isFirstMapLoad = 0;
		} else {	
			pureLoaded = 1;
			if (GetCommandFlags("sv_pure") != INVALID_FCVAR_FLAGS)
			{
				if (!(GetCommandFlags("sv_pure")&FCVAR_CHEAT))
				{
					SetCommandFlags("sv_pure",GetCommandFlags("sv_pure")|FCVAR_CHEAT);
				}			
			}
		}
	} else if (pureLoaded == 0)
	{
		fixPure();
	}
}



public Action:pureListener(client, const String:command[], argc)
{
	if (argc == 1)
	{
		decl String:buff[2];
		GetCmdArg(1,buff, sizeof(buff));
		new isOK = 0;
		if (strcmp(buff, "0", false) == 0)
		{
			isOK = 1;
		} else if (strcmp(buff, "1", false) == 0)
		{
			isOK = 1;
		} else if (strcmp(buff, "2", false) == 0)
		{
			isOK = 1;
		}
		if (isOK == 1)
		{
			svpure = StringToInt(buff);
			if (svpure != 2)
			{
				ServerCommand("sv_pure 2");
			}
		}
	}
}
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
public Action:printRates(client, args)
{
	new maxclients = GetMaxClients();
	PrintToConsole(client, " ");
	PrintToConsole(client, " ");
	PrintToConsole(client, " ");
	PrintToConsole(client, "-------------------------------------------------------------------------------");
	PrintToConsole(client, "- Ping | Choke | Loss | UUPD | SUPD | UCMD | SCMD |   SR   |  INP  | INPR | dxLevel | Nickname ");
	new Float:inp = (1.0 * INTERP_RATIO) / tickrate;
	for(new i=1; i <= maxclients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{			
			new Float:din,Float:dout,Float:dping,Float:dloss,Float:dchoke;
			din = GetClientAvgData(i, NetFlow_Outgoing) / 100;
			dout = GetClientAvgData(i, NetFlow_Incoming) / 100;
			dping = 1000.0*GetClientAvgLatency(i, NetFlow_Both);
			dchoke = 100.0*GetClientAvgChoke(i, NetFlow_Both);
			dloss = 100.0*GetClientAvgLoss(i, NetFlow_Both);
			
			decl String:strRate[10];
			GetClientInfo(i, "rate", strRate, sizeof(strRate));
			new rate = StringToInt(strRate);
					
			
			decl String:pname[USERNAME_MAXLENGTH];
			GetClientName( i, pname, sizeof(pname));
						
			if (rate <= MINRATE)
				rate = MINRATE;
			if (rate >= MAXRATE)
				rate = MAXRATE;
			

			PrintToConsole(client,"- %4.0f | %5.0f | %4.0f | %4.0f | %4d | %4.0f | %4d | %6d | %1.3f |   %d  | %s",dping,dchoke,dloss,din,tickrate,dout,tickrate,rate,inp,INTERP_RATIO,pname);
		}
	}	
	PrintToConsole(client, " ");
	PrintToConsole(client, " ");
	PrintToConsole(client, "UUPD : Currently used update rate (depends on how much ingame action there is)");
	PrintToConsole(client, "SUPD : Server-forced cl_updaterate setting");	
	PrintToConsole(client, "UCMD : Currently used cmd rate (depends on how much ingame action there is)");
	PrintToConsole(client, "SCMD : Server-forced cl_cmdrate setting");
	PrintToConsole(client, "SR   : Server-forced rate setting (%d <= rate <= %d)",MINRATE,MAXRATE);
	PrintToConsole(client, "INP  : Server-forced cl_interp setting");
	PrintToConsole(client, "INPR : Server-forced cl_interp_ratio setting");
	PrintToConsole(client, "-------------------------------------------------------------------------------");
	
	return Plugin_Handled;
}




public playerJumpEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new index=GetClientOfUserId(GetEventInt(event,"userid"));
	new Float:xVel;
	new Float:yVel;
	new bhop = 0;
	new Float:maxSpeed = 280.0;
	
	xVel = GetEntDataFloat(index,xVelocityOffset);
	yVel = GetEntDataFloat(index,yVelocityOffset);

	
	if (FloatAbs(xVel) > maxSpeed)
	{
		bhop = 1;	
	}	
	
  	if (FloatAbs(yVel) > maxSpeed)
	{
		bhop = 1;
	}
	
	if (bhop == 1)
	{		
		decl String:pname[60];
		GetClientName( index, pname, sizeof(pname));
			
		SetEntityGravity(index,2.0);
		CreateTimer(0.3, bhopUnblockPlayer,index);
		
		// Old way
		//PrintToChatAll("%c[cWar]%c %s : bunny-hopping is blocked.",GREEN,YELLOW,pname);
		//SetEntData(index, PlayerStateOffset, 14, 4, true);
	}
	
	
}

public Action:bhopUnblockPlayer(Handle:timer, any:index){
	// Old way
	//SetEntData(index, PlayerStateOffset, 0, 4, true);
	
	SetEntityGravity(index,1.0);
}



// ###############################################################
public Action:showStatus(client, args)
{
	showConsoleWelcome(client);
	return Plugin_Handled;	
}

public showConsoleWelcome(client)
{
		for(new i=1; i <= 100; i++)
		{
			PrintToConsole(client, " ");
		}
		PrintToConsole(client, "-------------------------------------------------------------------------------");
		PrintToConsole(client, "cWar Plugin v1.1.3 loaded. ( http://www.caroswar.tk )");
		
		if (!allCVARsOK)
		{
			PrintToConsole(client, " ");
			PrintToConsole(client, " ERROR: cWAR could _NOT_ correctly verify and force important cvars!!(BUG) Please contact www.caroswar.tk!!");
		}
		PrintToConsole(client, " ");
		PrintToConsole(client, "	This plugin provides bunnyhop protection,player rates inspection and match management.");
		PrintToConsole(client, "	This plugin also provides interpolation,rates and sv_pure enforcement.");
		PrintToConsole(client, "	- To inspect player rates type cw_rates in console.");
		PrintToConsole(client, "	- To get help on cWar commands type cw_help in console.");
		PrintToConsole(client, " ");		
		
		if (tickrate != -1)
			PrintToConsole(client, "	cWar is configured to adjust for tickrate %d",tickrate);
		
		PrintToConsole(client, "	Some important server convars:");
		PrintToConsole(client, "	- sv_pure %d",svpure);
		
		new Handle:conHandle = FindConVar("sv_pure_kick_clients");
		PrintToConsole(client, "	- sv_pure_kick_clients %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_consistency");
		PrintToConsole(client, "	- sv_consistency %d",GetConVarInt(conHandle));
			
		PrintToConsole(client, " ");
		
		conHandle = FindConVar("sv_minrate");
		PrintToConsole(client, "	- sv_minrate %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_maxrate");
		PrintToConsole(client, "	- sv_maxrate %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_mincmdrate");
		PrintToConsole(client, "	- sv_mincmdrate %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_maxcmdrate");
		PrintToConsole(client, "	- sv_maxcmdrate %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_minupdaterate");
		PrintToConsole(client, "	- sv_minupdaterate %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_maxupdaterate");
		PrintToConsole(client, "	- sv_maxupdaterate %d",GetConVarInt(conHandle));
		
		PrintToConsole(client, " ");
		
		conHandle = FindConVar("sv_client_max_interp_ratio");
		PrintToConsole(client, "	- sv_client_max_interp_ratio %d",GetConVarInt(conHandle));
				
		conHandle = FindConVar("sv_client_min_interp_ratio");
		PrintToConsole(client, "	- sv_client_min_interp_ratio %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_client_predict");
		PrintToConsole(client, "	- sv_client_predict %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_allowminmodels");
		PrintToConsole(client, "	- sv_allowminmodels %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_competitive_minspec");
		PrintToConsole(client, "	- sv_competitive_minspec %d",GetConVarInt(conHandle));		
		
		PrintToConsole(client, " ");
		
		conHandle = FindConVar("tv_enable");
		PrintToConsole(client, "	- tv_enable %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("tv_delay");
		PrintToConsole(client, "	- tv_delay %d",GetConVarInt(conHandle));
			
		PrintToConsole(client, " ");
		
		conHandle = FindConVar("sv_nonemesis");
		PrintToConsole(client, "	- sv_nonemesis %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_nomvp");
		PrintToConsole(client, "	- sv_nomvp %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_nostats");
		PrintToConsole(client, "	- sv_nostats %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_disablefreezecam");
		PrintToConsole(client, "	- sv_disablefreezecam %d",GetConVarInt(conHandle));
		
		conHandle = FindConVar("sv_nowinpanel");
		PrintToConsole(client, "	- sv_nowinpanel %d",GetConVarInt(conHandle));
		
		
		PrintToConsole(client, "-------------------------------------------------------------------------------");
}

public Action:showAdminHelp(Handle:timer, any:client)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		PrintToChat(client,"%c[cWar]%c You are an administrator. Type cw_help in console.",GREEN,YELLOW);
	}
}


public Action:showScore(client, args)
{
	if (matchLevel >= MATCH_START)
	{
		new roundsLeft = getRoundsLeft();
		new team = GetClientTeam(client);
		if (matchLevel < MATCH_HT)
		{
			if (team == TEAM_CTS)
			{
				PrintToChat(client,"%c[cWar]%c You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
				PrintToChat(client,"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
			} else if (team == TEAM_TS)
			{
				PrintToChat(client,"%c[cWar]%c You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
				PrintToChat(client,"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
			}
		} else {
			if (team == TEAM_CTS)
			{
				PrintToChat(client,"%c[cWar]%c You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamBPoints,teamAPoints);
				PrintToChat(client,"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
			} else if (team == TEAM_TS)
			{
				PrintToChat(client,"%c[cWar]%c You have %d wins, enemy has %d wins.",GREEN,YELLOW,teamAPoints,teamBPoints);
				PrintToChat(client,"%c[cWar]%c %d rounds left.",GREEN,YELLOW,roundsLeft);
			}
		} 
	} else {
		PrintToChat(client,"%c[cWar]%c Not in match.",GREEN,YELLOW);
	}
	return Plugin_Handled;
}