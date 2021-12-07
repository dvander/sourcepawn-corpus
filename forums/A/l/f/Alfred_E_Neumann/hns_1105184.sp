/*
*                     Seek and Destroy
*
*         A Hide and Seek Like DOD:S Modification
*
*         Hint: All spectators or dead people will be blinded, so that they dont see anything they can use when they back in the game
*               Also this plugin resets some server settings to make Seek and Destroy a better game play expirence (e.g. disable flashlight)
*
*         (c) 2009-2010 by Alfred E. Neumann
*
*         Some parts by Clement Vuchener (http://baronettes.verygames.net/)
*
*         Function WeaponCleanUp by Kigen
*         Function Timer_Beacon by DJ Tsunami
*
* 		  
*         Version 1.0.2.1:
*          - Beacon hopefully fixed (Thanks to BC Pitbull)
* 		   - Plugin should now really inactive if sad_active = 0
*
* 		  Version 1.0.2.0:
* 		   - first Release
* 
* 
*         CVars:
*
*             sad_active
*             Values: 0 | 1
*             Desc: Activates Seek and Destroy
*
*             sad_warmup
*             Values: min 0.0 - max unlimited
*             Desc: Warumup Time before the round begins. (Time for the hidden to find a hideout)
*
*             sad_roundtime
*             Values: min 0.0 - max unlimited
*             Desc: The time the seekers have to find the hidden (if sad_userounds = 1)
*
*             sad_findtime
*             Values: min 1.0 - max unlimited
*             Desc: The time the seekers have to find the last living hidden player (only used if sad_userounds = 0)
*
*             sad_winrounds
*             Values: min 0 - max unlimited
*            Desc: Round wins a time requires to end the map
*
*             sad_userounds
*             Values: 0 | 1
*             Desc: If 1: Play with limited time for each round (set in sad_roundtime)
*                   If 0: Play without time limit
*
*             sad_blind
*             Values: 0 | 1
*             Desc: Blind the Seeker for Warmup Time
*
*             sad_freeze
*             Values: 0 | 1
*             Desc: Freeze the Seeker for Warmup Time
*
*             sad_beacon
*             Values: 0 | 1
*             Desc: Place beacon on the last living player of the hidden team
*
*             sad_beacon_freq
*             Values: min 0.0 - max unlimited
*             Desc: Beacon beep frequency. Time in seconds in which the beacon will beep
*
*             sad_beacon_start
*             Values: min 0.0 - max unlimited
*             Desc:
*
*             sad_earn_pistols
*             Values: 0 | 1
*             Desc: Players can earn pistols for kills with knife/spade
*
*             sad_earn_weapons
*             Values: 0 | 1
*             Desc: Players can earn any kind of weapon (except Snipers and MGs) for kills with knife/spade
*
*             sad_weapon_team
*             Values: 1 | 2 | 3
*             Desc: Specify the team which can gain weapons the kills with knife/spade
*                   1 = both
*                   2 = Hidden team (Allies)
*                   3 = Seeker team (Axis)
*
*
*         Console Commands:
*
*         For Players:
*
*             sad_scoreboard
*             Desc: Shows the Seek and Destroy Scoreboard (usally automatic shown on the left side)
*
*             toggle3rd
*             Desc: Sets view to 3rd person
*
*             toggle1st
*             Desc: Sets view to 1st person
*
*             +3rd/-r3d
*             Desc: Changes view to 3rd person as long as the player presses the binded key
*
*             +1st/-1st
*             Desc: Changes view to 1st person as long as the player presses the binded key
*
*         For Server:
*
*             sad_restart
*             Desc: Restarts the round
*
*
*         Say Commands:
*
*             timeleft/roundtime
*             Desc: Shows the rest time of the running round
*
*             !+3rd/!-3rd
*             Desc: toggles between 3rd and 1st person
*/

// ---------------------------------------------------------------------------------------------------------------------

// ******************************************************************************
// * Default Includes                                                            *
// ******************************************************************************


#include <sourcemod>
#include <sdktools>
#include <string>

// ******************************************************************************
// * Info about the Plugin                                                        *
// ******************************************************************************
public Plugin:myinfo = {
    name = "Seek and Destroy",
    author = "Alfred E. Neumann",
    description = "Hide and Seek like Modification for DOD:S",
    version = "1.0.2.0",
    url = "http://www.die-eierfeile.de"
};


// ******************************************************************************
// * Some simple defines                                                        *
// ******************************************************************************

// how many models we want to use
#define MAX_MODELS            128

// the max size of the models
#define MAX_MODELNAME_SIZE    128

// minimum amount of player to start seek and destroy
#define MINPLAYERS            3


// defines Team numbers
#define HIDDENALLIES        2
#define SEEKINGAXIS            3
#define SPECTATOR            1

// Round Timeleft Sounds
#define ONEMINUTE_GER    "player/german/ger_oneminute1.wav"
#define TWOMINUTE_GER    "player/german/ger_twominute2.wav"

#define ONEMINUTE_US    "player/american/us_oneminute1.wav"
#define TWOMINUTE_US    "player/american/us_twominute1.wav"

// Prepare phases
#define WAITING        0
#define PREPARATION    1
#define SEEKING        2
#define END            3



// Model variables
new String:models[MAX_MODELS][MAX_MODELNAME_SIZE];
new modelCount = 0;

// round specific variables
new roundState;
new Handle:preptimer = INVALID_HANDLE;
new Handle:roundpreptimer = INVALID_HANDLE;

// Max amount of seekers
new bTeam[33] = {SPECTATOR, ...}
// Team switching
new bool:bSwitching[33];
// Var to remember the last model of a player (to be sure he gets the same model in the running round when he switches to spectator and back)
new SavedModels[33] = {-1, ...};

// CVars
new Handle:cvar_active = INVALID_HANDLE;
new Handle:cvar_preptime = INVALID_HANDLE;
new Handle:cvar_blind = INVALID_HANDLE;
new Handle:cvar_freeze = INVALID_HANDLE;
new Handle:cvar_beacon = INVALID_HANDLE;
new Handle:cvar_beep = INVALID_HANDLE;
new Handle:cvar_timedbeacon = INVALID_HANDLE;

// Pistol/weapon fun
new Handle:cvar_earnweapons = INVALID_HANDLE;
new Handle:cvar_randomweapons = INVALID_HANDLE;
new Handle:cvar_teams = INVALID_HANDLE;


// Round settings
new Handle:cvar_findlast = INVALID_HANDLE;
new Handle:cvar_winrounds = INVALID_HANDLE;

// If a timelimit for a round has to be used
new Handle:cvar_roundtime = INVALID_HANDLE;
new Handle:cvar_userounds = INVALID_HANDLE;

// Offsets
new m_hObserverTarget_offs;
new m_iObserverMode_offs;
new m_iFOV_offs;
new m_Local_offs;
new m_bDrawViewmodel_offs;

// UserMessageId for Fade.
new UserMsg:g_FadeUserMsgId;

// Beacon
new Handle:g_hBeacon = INVALID_HANDLE;
new g_iBeamSprite;
new g_iGrey[4]       = {128, 128, 128, 255};
new g_iHaloSprite;
new g_iRed[4]        = {255,  75,  75, 255};

// rest time
new ShowTime = -1;

// Because Roundrestart destroys the score, we have to take care about it
new SeekerScore = 0;
new HiddenScore = 0;

// For Weapon Cleanup
new g_WeaponParent;

// ******************************************************************************
// * Plugin init                                                                *
// ******************************************************************************
public OnPluginStart () {
    new i;
    // Init variables
    roundState = PREPARATION;
    for (i = 0; i <= 32; i++)
        bSwitching[i] = false;

    ServerSetup();

    // Load Model-List
    new Handle:file;
    file = OpenFile("hns_models.txt", "r");
    if (file == INVALID_HANDLE)
    {
        SetFailState("Could not find or read hns_models.txt");
    }

    decl String:buffer[MAX_MODELNAME_SIZE];
    i = 0;
    while (ReadFileLine(file, buffer, MAX_MODELNAME_SIZE) && i < MAX_MODELS)
    {
        TrimString(buffer);
        strcopy(models[i], MAX_MODELNAME_SIZE, buffer);
        i++;
    }
    modelCount = i;
    if (modelCount == 0)
    {
        SetFailState("No models specified in hns_models.txt");
    }

    // Init offsets
    m_hObserverTarget_offs = FindSendPropOffs("CDODPlayer", "m_hObserverTarget");
    m_iObserverMode_offs = FindSendPropOffs("CDODPlayer", "m_iObserverMode");
    m_iFOV_offs = FindSendPropOffs("CDODPlayer", "m_iFOV");
    m_Local_offs = FindSendPropOffs("CDODPlayer", "m_Local");
    m_bDrawViewmodel_offs = FindSendPropOffs("CDODPlayer", "m_bDrawViewmodel");

    // Beacon
    //g_fRadius      = GetConVarFloat(FindConVar("sm_beacon_radius"));
    g_iBeamSprite  = PrecacheModel("materials/sprites/laser.vmt");
    g_iHaloSprite  = PrecacheModel("materials/sprites/halo01.vmt");

    // Init ConVars
    cvar_active = CreateConVar ("sad_active", "1", "Enable/Disable Seek And Destroy", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_preptime = CreateConVar ("sad_warmup", "30", "Warmup Time for hiding, before seeker starts", FCVAR_REPLICATED, true, 0.0);
    cvar_blind = CreateConVar ("sad_blind", "0", "Blind seeker while in Warmup Time", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_freeze = CreateConVar ("sad_freeze", "0", "Freeze seeker while in Warmup Time", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_beacon = CreateConVar ("sad_beacon", "0", "Beacon the last hidden player", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_beep = CreateConVar ("sad_beacon_freq", "5", "Beacon beep frequency (in seconds)", FCVAR_REPLICATED, true, 0.0);
    cvar_earnweapons = CreateConVar ("sad_earn_pistols", "0", "Players can earn weapons (pistols) for kills", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_randomweapons = CreateConVar ("sad_earn_weapons", "0", "Players can earn weapons (all except MGs and Snipers) for kills (overrides sad_earn_pistols)", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_winrounds = CreateConVar ("sad_winrounds", "5", "Win rounds until map changes", FCVAR_REPLICATED, true, 1.0);
    cvar_roundtime = CreateConVar ("sad_roundtime", "5", "Time for a round in minutes", FCVAR_REPLICATED, true, 1.0);
    cvar_userounds = CreateConVar ("sad_userounds", "1", "If set to 1, the value from sad_roundtime is used for a round sad_findtime is ignored", FCVAR_REPLICATED, true, 0.0, true, 1.0);
    cvar_findlast = CreateConVar ("sad_findtime","15","Time in seconds to find the last player before round ends", FCVAR_REPLICATED, true, 1.0);
    cvar_teams = CreateConVar ("sad_weapon_team","1","If sad_earn_pistols or sad_earn_weapons is enabled, give weapons to teams: 1 = both; 2 = hidden; 3 = seekers",FCVAR_REPLICATED, true, 1.0, true, 3.0);
    cvar_timedbeacon = CreateConVar ("sad_beacon_start","20","Rest time when last hidden player starts beacon (set to 0 to instant start beacon)", FCVAR_REPLICATED, true, 0.0);

    HookConVarChange(cvar_active, Activate);

    // User message
    g_FadeUserMsgId = GetUserMessageId("Fade");

    // Commands
    RegServerCmd("sad_restart", Restart)

    RegConsoleCmd("+1st", ThirdOff);
    RegConsoleCmd("-1st", ThirdOn);
    RegConsoleCmd("+3rd", ThirdOn);
    RegConsoleCmd("-3rd", ThirdOff);
    RegConsoleCmd("toggle3rd",ThirdOn);
    RegConsoleCmd("toggle1st",ThirdOff);

    // Catch say commands
    RegConsoleCmd("say", Command_Say);
    RegConsoleCmd("say_team", Command_Say);

    // Custom Scoreboard
    RegConsoleCmd("sad_scoreboard", ScoreBoard);

    // Events
    HookEvent ("player_spawn", OnPlayerSpawn);

    HookEvent ("player_death", OnPlayerDeath);
    HookEvent ("player_team", OnPlayerTeam);
    HookEvent ("dod_round_start", OnRoundStart, EventHookMode_Pre);
    HookEvent("player_hurt",OnPlayerHurt);

    // Prevent Class Change
    HookEvent ("player_changeclass", OnChangeClass);

    //weapons
    HookEvent("dod_stats_weapon_attack",PlayerShooting);

    g_WeaponParent = FindSendPropOffs("CDODPlayer", "m_hOwnerEntity");

    RegConsoleCmd("drop", Command_Drop, "Block weapons from being dropped");
    RegConsoleCmd("overview_mode", Command_Drop, "Block Overview from being opened");

    // Save/Load our values ;)
    AutoExecConfig(true,"seek_and_destroy","sourcemod");

}



// ******************************************************************************
// * Resets some server variables/cvars                                            *
// ******************************************************************************
public ServerSetup()
{
    // Classes are uninteresting, as they all spawn without weapon -> Only Riflemans
    ServerCommand("mp_limit_allies_rifleman -1");
    ServerCommand("mp_limit_allies_sniper 0");
    ServerCommand("mp_limit_allies_rocket 0");
    ServerCommand("mp_limit_allies_assault 0");
    ServerCommand("mp_limit_allies_support 0");
    ServerCommand("mp_limit_allies_mg 0");

    ServerCommand("mp_limit_axis_rifleman -1");
    ServerCommand("mp_limit_axis_sniper 0");
    ServerCommand("mp_limit_axis_rocket 0");
    ServerCommand("mp_limit_axis_assault 0");
    ServerCommand("mp_limit_axis_support 0");
    ServerCommand("mp_limit_axis_mg 0");

    // No Friendly Fire
    new Handle:check_ff = INVALID_HANDLE;
    check_ff = FindConVar("mp_friendlyfire");

    if ((check_ff != INVALID_HANDLE) && (GetConVarBool(check_ff) == true))
        ServerCommand("mp_friendlyfire 0");

    // No Team Balance
    new Handle:check_balance = INVALID_HANDLE;
    check_balance = FindConVar("mp_limitteams");

    if ((check_balance != INVALID_HANDLE) && (GetConVarInt(check_balance) > 0))
        ServerCommand("mp_limitteams 33");

    // No Flashlight (creates strange shadows)

    new Handle:check_flash = INVALID_HANDLE;
    check_flash = FindConVar("mp_flashlight");

    if ((check_flash != INVALID_HANDLE) && (GetConVarInt(check_flash) > 0))
    {
        ServerCommand("mp_flashlight 0");
    }

}

// ******************************************************************************
// * Prevent player from dropping weapons                                        *
// ******************************************************************************
public Action:Command_Drop(client, args)
{
    if (GetConVarBool(cvar_active) == true)
    {
        return Plugin_Handled ;
    }
    return Plugin_Continue;
}


// ******************************************************************************
// * Prevent class change, if class gets changed, send player to seeker            *
// ******************************************************************************
public OnChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_active) == true)
    {
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		new team = GetTeam(client);
		if (team == HIDDENALLIES)
		{
			SetTeam(client,SEEKINGAXIS);
		}
    }
}

// ******************************************************************************
// * If the player is fireing his gun                                            *
// ******************************************************************************
public Action:PlayerShooting(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	if (GetConVarBool(cvar_active) == true)
    {
		new userid = GetEventInt(event, "attacker");
		new client = GetClientOfUserId(userid);
		new team = GetTeam(client);
		new String:CurWeapon[32];

		if (IsClientInGame(client))
		{
			if ((GetConVarBool(cvar_earnweapons) == true) || (GetConVarBool(cvar_randomweapons) == true))
            {
                GetClientWeapon(client, CurWeapon, sizeof(CurWeapon))

                if ((strcmp(CurWeapon, "weapon_amerknife", true) != 0) && (strcmp(CurWeapon, "weapon_spade", true) != 0))
                {
                    if (strcmp(CurWeapon, "weapon_garand",true) == 0) // We need a special behavior for garand
                    {
                        new Handle:pack;

                        CreateDataTimer(2.0,RemoveWeapon,pack); // If you remove the garand without delay, the server will crash!
                        WritePackCell(pack,client);
                        WritePackCell(pack,team);
                    }
                    else
                    {
                        new Handle:pack;

                        CreateDataTimer(0.0,RemoveWeapon,pack); //Other weapons dont make any problems, remove them immediately
                        WritePackCell(pack,client);
                        WritePackCell(pack,team);
                    }
                }
            }
        }
    }
}

// ******************************************************************************
// * Player changes team                                                        *
// ******************************************************************************
public Action:OnPlayerTeam (Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(cvar_active)) 
	{
        new team = GetEventInt(event, "team");
        new userid = GetEventInt(event, "userid");
        new client = GetClientOfUserId(userid);

    //    SetEntProp(client, Prop_Send, "m_iHideHUD", 65)

        if (roundState < SEEKING)
        {
            if (bSwitching[client])
                bSwitching[client] = false;
            else
            {
                if ((bTeam[client] == SPECTATOR) && (team != SEEKINGAXIS))
                {
                    SetTeam(client,SEEKINGAXIS);
                }
                else if ((bTeam[client] == SEEKINGAXIS) && (team != SEEKINGAXIS))
                {
                    SetTeam(client, SEEKINGAXIS);
                }
                else if ((bTeam[client] == HIDDENALLIES) && (team != HIDDENALLIES))
                {
                    SetTeam(client, HIDDENALLIES);
                }
            //    else
            //    {
            //        SetTeam(Client,SPECTATOR);
            //    }
            }
        }
        else if (roundState >= SEEKING)
        {
            if ((bTeam[client] == SPECTATOR) && (team != SEEKINGAXIS))
            {
                SetTeam(client,SEEKINGAXIS);
            }

        }

        if (team == SPECTATOR)
        {
            PerformBlind(client,255);
        }
    }
}



// ******************************************************************************
// * Enable/Display Seek and Destroy                                            *
// ******************************************************************************
public Activate (Handle:cvar, const String:oldVal[], const String:newVal[]) {
    if (StringToInt(newVal) != StringToInt(oldVal))
        ServerCommand("mp_clan_restartround 3");
    if (StringToInt(newVal) == 0 && preptimer != INVALID_HANDLE) {
        KillTimer(preptimer);
        preptimer = INVALID_HANDLE;
    }

}

// ******************************************************************************
// * Restart round                                                                *
// ******************************************************************************
public Action:Restart(args)
{
    new i = 0;
    if (GetConVarBool(cvar_active) == true)
    {
        for (i = 0; i <= sizeof(SavedModels)-1; i++)
        {
            SavedModels[i] = -1;
        }

        if (GetConVarBool(cvar_beacon) == true)
        {

            if (g_hBeacon != INVALID_HANDLE)
            {
                KillTimer(g_hBeacon);
            }

        }

        if (GetConVarBool(cvar_userounds) == true)
        {
            if (roundpreptimer != INVALID_HANDLE)
            {
                KillTimer(roundpreptimer);
                roundpreptimer = INVALID_HANDLE;
            }
        }


        if (args <= 0)
            args = 2;

        ShowTime = -1;
        ServerCommand("mp_clan_restartround %d",args);
    }
}


// ******************************************************************************
// * Start Game Timer                                                            *
// ******************************************************************************
public Action:StartT (Handle:timer) {
    Start();
}


// ******************************************************************************
// * Dummy Menu Handler (For Scoreboard)                                        *
// ******************************************************************************
public DummyHandler(Handle:menu, MenuAction:action, param1, param2)
{

 // nothing
}


// ******************************************************************************
// * Scoreboard                                                                    *
// ******************************************************************************
public Action:ScoreBoard (client, args)
{
    new String:strSeekerScore[100];
    new String:strHiddenScore[100];
    new String:strWinScore[100];
    new String:outstrSeeker[100];
    new String:outstrHidden[100];
    new String:outstrWin[100];


    IntToString(SeekerScore,strSeekerScore,100);
    IntToString(HiddenScore,strHiddenScore,100);

    IntToString(GetConVarInt(cvar_winrounds),strWinScore,100);

    outstrSeeker = "Seeker Score: ";
    outstrHidden = "Hidden Score: ";

    outstrWin = "Win-Score: ";

    StrCat(outstrSeeker,100,strSeekerScore);
    StrCat(outstrHidden,100,strHiddenScore);

    StrCat(outstrWin,100,strWinScore);

    new Handle:panel = CreatePanel();
    SetPanelTitle(panel, "Score");
    DrawPanelText(panel, " ");
    DrawPanelText(panel, outstrSeeker);
    DrawPanelText(panel, outstrHidden);
    DrawPanelText(panel, " ");
    DrawPanelText(panel, outstrWin);

    SendPanelToClient(panel, client, DummyHandler, MENU_TIME_FOREVER);

    CloseHandle(panel);

    return Plugin_Handled;

}

// ******************************************************************************
// * Display Scoreboard                                                            *
// ******************************************************************************
public ShowScoreBoard()
{
    new maxclients = GetMaxClients();
    new i = 1;
    for (i = 1; i <= maxclients; i++)
    {
        if (IsClientInGame(i) && (IsPlayerAlive(i)))
        {
            ClientCommand(i,"sad_scoreboard");
        }

    }


}

// ******************************************************************************
// * End The Map                                                                *
// ******************************************************************************
EndGame()
{

    new iGameEnd  = FindEntityByClassname(-1, "game_end");
    if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) {
        LogError("Unable to create entity \"game_end\"!");
    }
    else
    {
        AcceptEntityInput(iGameEnd, "EndGame");
        ShowScoreBoard();
    }
}


// ******************************************************************************
// * If the map has changed, do this                                            *
// ******************************************************************************
public OnMapStart()
{
    if (GetConVarBool(cvar_active) == true)
    {
        AutoExecConfig(true,"seek_and_destroy","sourcemod");
        PrecacheSound(ONEMINUTE_GER, true);
        PrecacheSound(ONEMINUTE_US, true);
        PrecacheSound(TWOMINUTE_GER, true);
        PrecacheSound(TWOMINUTE_US, true);
    }
}

// ******************************************************************************
// * Client used the say or say_team command                                    *
// ******************************************************************************
public Action:Command_Say(client,args)
{
    if (GetConVarBool(cvar_active) == true)
    {
        if(client != 0){

            decl String:speech[64];
            decl String:clientName[64];
            GetClientName(client,clientName,64);
            GetCmdArgString(speech,sizeof(speech));

            new startidx = 0;
            if (speech[0] == '"'){
                startidx = 1;
                /* Strip the ending quote, if there is one */
                new len = strlen(speech);
                if (speech[len-1] == '"'){
                        speech[len-1] = '\0';
                }
            }

            if(strcmp(speech[startidx],"timeleft",false) == 0){
                EchoTime();
                return Plugin_Handled;
            }
            if(strcmp(speech[startidx],"roundtime",false) == 0){
                EchoTime();
                return Plugin_Handled;
            }
            if(strcmp(speech[startidx],"!-3rd",false) == 0){
                SetPOV(client,false);
                return Plugin_Handled;
            }
            if(strcmp(speech[startidx],"!+3rd",false) == 0){
                SetPOV(client,true);
                return Plugin_Handled;
            }

        }

        return Plugin_Continue;
    }
    else
    {
        return Plugin_Continue;
    }

}

// ******************************************************************************
// * Round timeleft display                                                        *
// ******************************************************************************
public EchoTime()
{
    if (ShowTime <= -1)
        PrintToChatAll("Round Timeleft: Round Warmup!");
    else
        PrintToChatAll("Round Timeleft: %02d:%02d",ShowTime/60,ShowTime%60);
}

// ******************************************************************************
// * Timer For Round time                                                        *
// ******************************************************************************
public Action:RoundTimer(Handle:timer, any:timeleft)
{

    ShowTime = timeleft;
    // we check if we have a seeker
    if (GetTeamClientCount(SEEKINGAXIS) <= 0)
    {
        // No Seeker!! Restart the round
        PrintCenterTextAll("Ohh... no one is seeking, restarting round!");
        Restart(2);
    }


    if (Won())
    {
        // nothing
    }
    else if (GetTeamClientCount(HIDDENALLIES) == 0)
    {
        if (roundpreptimer != INVALID_HANDLE)
        {
            KillTimer(roundpreptimer); // Kill roundtimer if round is over
            roundpreptimer = INVALID_HANDLE;
        }
        SeekerScore++;
        ShowScoreBoard();
        if ((SeekerScore >= GetConVarInt(cvar_winrounds)))
        {
            // Reset Score before map change;
            HiddenScore = 0;
            SeekerScore = 0;
            EndGame();
        }
        PrintCenterTextAll("Seekers have won!");
        Restart(4);

    }
    else if (timeleft == 0)
    {
        roundpreptimer = INVALID_HANDLE;
        HiddenScore++;
        ShowScoreBoard();
        if ((HiddenScore >= GetConVarInt(cvar_winrounds)))
        {
            // Reset Score before map change;
            HiddenScore = 0;
            SeekerScore = 0;
            EndGame();
        }
        PrintCenterTextAll("Seekers have lost the round!");
        Restart(4);
    }
    else
    {
        roundpreptimer = INVALID_HANDLE;


        if ((GetConVarBool(cvar_beacon) == true) && (GetConVarInt(cvar_timedbeacon) > 0))
            {
                if ((timeleft <= GetConVarInt(cvar_timedbeacon)) && (timeleft%GetConVarInt(cvar_timedbeacon) == 0) && (GetTeamClientCount(HIDDENALLIES) == 1))
                {
                    CreateTimer(GetConVarFloat(cvar_beep),Timer_Beacon,GetLastLivingPlayer());
                }
            }

        if (timeleft > 60) { // if countdown is bigger then 10 seconds
            if (timeleft%60 == 0)
            {
                if (timeleft/60 == 1)
                {
                    PrintCenterTextAll("%d minute left", 1);
                    PrintToChatAll("\x04[Seek and Destroy] \x01One minute left");
                    PlaySound(1);
                }
                else
                {

                    PrintCenterTextAll("%d minutes left", timeleft/60);
                    if ((timeleft/60 == 2))
                    {
                        PlaySound(2);
                        PrintToChatAll("\x04[Seek and Destroy] \x01Two minutes left");
                        for (new i = 1; i <= MaxClients; i++)
                        {
                        }
                    }
                }
                roundpreptimer = CreateTimer(1.0, RoundTimer, timeleft-1);
            }
            else
            {
                //roundpreptimer = CreateTimer(float(timeleft%60), RoundTimer, timeleft-(timeleft%60));
                roundpreptimer = CreateTimer(1.0, RoundTimer, timeleft-1);
            }
        }
        else
        { // if there are less then 10 seconds left
            if (timeleft > 1)
            {
                if (timeleft == 60)
                {
                    PrintCenterTextAll("%d minute left", 1);
                    PrintToChatAll("\x04[Seek and Destroy] \x01One minute left");
                    PlaySound(1);
                    for(new i = 1; i <= MaxClients; i++)
                    {
                    }
                }
                PrintCenterTextAll("Hurry up! Only %d seconds left to find the last one", timeleft);
            }
            else
            {
                PrintCenterTextAll("Hurry up! Only %d second left to find the last one", timeleft);
            }
            roundpreptimer = CreateTimer(1.0, RoundTimer, timeleft-1);
        }
    }


}

// ******************************************************************************
// * Play a sound on the client                                                    *
// ******************************************************************************
public PlaySound(args)
{
    new maxclients = GetMaxClients();

    for (new client = 1; client <= maxclients; client++)
    {

        if (GetTeam(client) == HIDDENALLIES)
        {
            if (args == 1)
                EmitSoundToClient(client,ONEMINUTE_US);

            if (args == 2)
                EmitSoundToClient(client,TWOMINUTE_US);
        }

        if (GetTeam(client) == SEEKINGAXIS)
        {
            if (args == 1)
                EmitSoundToClient(client,ONEMINUTE_GER);

            if (args == 2)
                EmitSoundToClient(client,TWOMINUTE_GER);
        }
    }
}

// ******************************************************************************
// * If The round has ended, start this timer                                    *
// ******************************************************************************
public Action:EndRound(Handle:timer, any:timeleft)
{
    preptimer = INVALID_HANDLE;
    if (GetTeamClientCount(HIDDENALLIES) == 1)
    {
        if (Won())
        {
            // nothing
        }
        else if (timeleft == 0)
        {
            HiddenScore++;
            ShowScoreBoard();
            if ((HiddenScore >= GetConVarInt(cvar_winrounds)))
            {
                // Reset Score before map change;
                HiddenScore = 0;
                SeekerScore = 0;
                EndGame();
            }
            PrintCenterTextAll("Seekers have lost the round!");
            Restart(4);
        }
        else
        {
            if (timeleft > 10) { // if countdown is bigger then 10 seconds
                if (timeleft%10 == 0)
                {
                    PrintCenterTextAll("%d seconds left to find the last one", timeleft);
                    preptimer = CreateTimer(10.0, EndRound, timeleft-10);
                }
                else
                {
                    preptimer = CreateTimer(float(timeleft%10), EndRound, timeleft-(timeleft%10));
                }
            }
            else
            { // if there are less then 10 seconds left
                if (timeleft > 1)
                    PrintCenterTextAll("Hurry up! Only %d seconds left to find the last one", timeleft);
                else
                    PrintCenterTextAll("Hurry up! Only %d second left to find the last one", timeleft);
                preptimer = CreateTimer(1.0, EndRound, timeleft-1);
            }
        }
    }

}



// ******************************************************************************
// * Time to play the game                                                        *
// ******************************************************************************
Start () {
    new maxclients = GetMaxClients();
    new client;

    new n = GetRandomInt(0, ActivePlayerCount()-1);

    if (GetConVarBool(cvar_active) == true)
    {
        ServerSetup();
        ShowScoreBoard();




        roundState = PREPARATION;

        for (client = SPECTATOR; client <= maxclients; client++) {
            if (Playing(client))
            {
                if (n == 0) {
                    bTeam[client] = SEEKINGAXIS;
                    SetTeam(client, SEEKINGAXIS);
                }
                else
                {
                    bTeam[client] = HIDDENALLIES;
                    SetTeam(client, HIDDENALLIES);
                }

                n--;
            }
            else
            {
                // Player is Spectator
                bTeam[client] = SPECTATOR;
            }
        }

        new String:class[64];
        new maxentities = GetMaxEntities();
        for (new i = maxclients+1; i <= maxentities; i++)
        {
            if (IsValidEntity(i))
            {
                GetEdictClassname(i, class, sizeof(class));
                if (strcmp(class, "dod_capture_area") == 0 ||
                    strcmp(class, "dod_bomb_target") == 0 ||
                    strcmp(class, "func_team_wall") == 0 ||
                    strcmp(class, "func_teamblocker") == 0) {
                    RemoveEdict(i);
                }
            }
        }

        // Timer setup
        if (preptimer != INVALID_HANDLE)
        {
            KillTimer(preptimer);
            preptimer = INVALID_HANDLE;
        }
        preptimer = CreateTimer(0.0, BeginCountDown, GetConVarInt(cvar_preptime));
    }
}

// ******************************************************************************
// * Check if Seekers have won                                                    *
// ******************************************************************************
bool:Won () {
    new maxclients = GetMaxClients();
    new client;
    for (client = 1; client <= maxclients; client++)
        if (Playing(client)) {
        if (bTeam[client] == HIDDENALLIES)
                return false;
        }

    SeekerScore++;

    if (GetConVarBool(cvar_userounds) == true)
    {
        if (roundpreptimer != INVALID_HANDLE)
        {
            KillTimer(roundpreptimer); // Kill roundtimer if round is over
            roundpreptimer = INVALID_HANDLE;
        }
    }

    ShowScoreBoard();
    if ((SeekerScore >= GetConVarInt(cvar_winrounds)))
    {
        // Reset Score before Mapchange
        SeekerScore = 0;
        HiddenScore = 0;
        EndGame();
    }

    return true;
}

// ******************************************************************************
// * Client is playing and not spectating                                        *
// ******************************************************************************
bool:Playing (client) {
    return IsClientInGame(client) && !IsClientObserver(client);
}

// ******************************************************************************
// * How many players are active                                                *
// ******************************************************************************
_:ActivePlayerCount () {
    new maxclients = GetMaxClients();
    new n = 0;
    for (new client = 1; client <= maxclients; client++)
        if (Playing(client))
            n++;
    return n;
}


// ******************************************************************************
// * Get Last living Hidden player                                                *
// ******************************************************************************
_:GetLastLivingPlayer () {
    new maxclients = GetMaxClients();
    new i = 1;
    for (i = 1; i <= maxclients; i++)
    {
        if (IsClientInGame(i) && (IsPlayerAlive(i)) && (GetTeam(i) == HIDDENALLIES))
            return i;
    }
    return i;
}

// ******************************************************************************
// * Start countdown for a new round                                            *
// ******************************************************************************
public Action:BeginCountDown(Handle:timer, any:timeleft) {
    preptimer = INVALID_HANDLE;

    // we check if we have a seeker
    if (GetTeamClientCount(SEEKINGAXIS) <= 0)
    {
        // No Seeker!! Restart the round
        PrintCenterTextAll("Ohh... no one is seeking, restarting round!");
        Restart(2);
    }

    if (timeleft == 0) {
        PrintCenterTextAll("Here we go!");
        roundState = SEEKING;

        new maxclients = GetMaxClients();
        new client;

        for (client = 1; client <= maxclients; client++) {
            if ((Playing(client)) && (bTeam[client] == SEEKINGAXIS))
            { // Setup Seeker
                if (GetConVarBool(cvar_blind))
                    PerformBlind(client, 0);
                if (GetConVarBool(cvar_freeze))
                    UnfreezeClient(client);
            }
            if (!Playing(client))
            {
                // The rest is not going to be seeker
                bTeam[client] = HIDDENALLIES;
            }
        }

        // If time based rounds are used
        if (GetConVarBool(cvar_userounds) == true)
        {
            roundpreptimer = CreateTimer(1.0,RoundTimer,GetConVarInt(cvar_roundtime)*60); // We got minutes, but need seconds
        }
    }
    else {
        if (timeleft > 10)
        { // if countdown is bigger then 10 seconds
            if (timeleft%10 == 0) {
                PrintCenterTextAll("%d seconds left until round start", timeleft);
                preptimer = CreateTimer(10.0, BeginCountDown, timeleft-10);
            }
            else {
                preptimer = CreateTimer(float(timeleft%10), BeginCountDown, timeleft-(timeleft%10));
            }
        }
        else
        { // if there are less then 10 seconds left
                if (timeleft > 1)
                    PrintCenterTextAll("%d seconds left until round start", timeleft);
                else
                    PrintCenterTextAll("%d second left until round start", timeleft);
                preptimer = CreateTimer(1.0, BeginCountDown, timeleft-1);
        }
    }
}

// ******************************************************************************
// * If we have enough players, start the game                                    *
// ******************************************************************************
public Action:OnRoundStart (Handle:event, const String:name[], bool:dontBroadcast) {
    if (GetConVarBool(cvar_active))
	{
		if (ActivePlayerCount() >= MINPLAYERS) {
			roundState = PREPARATION;
			if (GetConVarBool(cvar_active))
			{
				Start();
			}
		}
		else
			roundState = WAITING;
	}
}

// ******************************************************************************
// * New player joins                                                            *
// ******************************************************************************
public OnClientPutInServer(client) {
    if (GetConVarBool(cvar_active)) {

        if ((roundState == SEEKING) && (bTeam[client] != SPECTATOR))
        {
            bTeam[client] = SEEKINGAXIS;
        }
        else
        {
            bTeam[client] = HIDDENALLIES;
        }

        if (bTeam[client] == SPECTATOR)
        {
            PerformBlind(client,255);
        }
    }
}

// ******************************************************************************
// * Player Spawns                                                              *
// ******************************************************************************
public Action:OnPlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast) 
{
    if (GetConVarBool(cvar_active))
	{
		decl ent, i;
		new String:model[MAX_MODELNAME_SIZE+12];
    
		if (roundState == WAITING)
		{
            if (ActivePlayerCount() >= MINPLAYERS)
            {
                Start();
            }
        }
		else
		{
			new userid = GetEventInt(event, "userid");
			new client = GetClientOfUserId(userid);
			new team = GetTeam(client);

			if (team > 1)
			{ // player is not spectator
			// check team
				if ((bTeam[client] == SEEKINGAXIS) && team != SEEKINGAXIS)
				{
					SetTeam(client, 3);
					return;
				}
				if ((bTeam[client] == HIDDENALLIES) && team != HIDDENALLIES)
				{
					SetTeam(client, 2);
					return;
				}

                // Strip Weapons
				for (i = 0; i < 4; i++)
				{
                    if (IsClientConnected(client))
                    {
                        ent = GetPlayerWeaponSlot(client, i);
                        if(ent != -1)
                            RemovePlayerItem(client, ent);
                    }
                }

				if (team == HIDDENALLIES)
				{ // Allied Team has to hide
						// So we better remove the weapon model
					new String:cname[100];
					if (IsClientConnected(client))
					{
						ent = GivePlayerItem(client, "weapon_amerknife");
						SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
						SetEntityRenderColor(ent, 0, 0, 0, 0);

						// and now he gets a new random model
						if (SavedModels[client] != -1)
						{
							i = SavedModels[client];
						//            PrintToChat(client,"ModelID: %d | Modelname: %s",i,models[i]);
							GetClientName(client,cname,sizeof(cname));
							PrintToServer("Player: %s | Model: %s",cname,models[i]);
						}
						else
						{
							i = GetRandomInt(0, modelCount-1);
							SavedModels[client] = i;
						//            PrintToChat(client,"Random ModelID: %d | Modelname: %s",i,models[i]);
							GetClientName(client,cname,sizeof(cname));
							PrintToServer("Player: %s | Model: %s",cname,models[i]);
						}
						Format(model, sizeof(model), "models/%s.mdl", models[i]);
						// remember model for this round

						if (!IsModelPrecached(model))
							PrecacheModel(model);

						SetEntityModel(client, model);

					// Put the player into 3rd person
						SetPOV(client, true);
						}
					}
				else if (team == SEEKINGAXIS)
				{ // Wehrmacht is seeker
					if (IsClientConnected(client))
					{
						GivePlayerItem(client, "weapon_spade");
					// Blocks the seeker while in Warmup
						if (roundState == PREPARATION)
						{
							if (GetConVarBool(cvar_blind))
							{
								PerformBlind(client, 0);
								PerformBlind(client, 255);
							}
							if (GetConVarBool(cvar_freeze))
								FreezeClient(client);
						}
					}
				}
			}
		}
	}
}

// ******************************************************************************
// * Checks how many Hidden players are left, to display some notices or start  *
// * the beacon on the last player                                                *
// ******************************************************************************
public Action:CheckHidden(Handle:timer)
{
    if (GetTeamClientCount(HIDDENALLIES) == 1)
        {
            PrintCenterTextAll("Only one person left!!!");

            if (GetConVarBool(cvar_beacon) == true )
            {
                if (GetConVarInt(cvar_timedbeacon) == 0)
                {
                    g_hBeacon = CreateTimer(GetConVarFloat(cvar_beep), Timer_Beacon, GetLastLivingPlayer(), TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                }
            }
            if (GetConVarBool(cvar_userounds) == false)
            {
                preptimer = CreateTimer(1.0, EndRound,GetConVarInt(cvar_findlast));
            }
        }
    return Plugin_Stop;
}


// ******************************************************************************
// * Removes all dropped weapons                                                *
// ******************************************************************************
WeaponCleanUp()
{  // By Kigen (c) 2008 - Please give me credit. :)
    new maxent = GetMaxEntities(), String:name[64];
    for (new i=GetMaxClients();i<maxent;i++)
    {
        if ( IsValidEdict(i) && IsValidEntity(i) )
        {
            GetEdictClassname(i, name, sizeof(name));
            if ( ( StrContains(name, "weapon_") != -1 || StrContains(name, "item_") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
                    RemoveEdict(i);
        }
    }
}


// ******************************************************************************
// * The Player died                                                            *
// ******************************************************************************
public Action:OnPlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(cvar_active) && roundState == SEEKING) {
        new userid = GetEventInt(event, "userid");
        new client = GetClientOfUserId(userid);
        new team = GetTeam(client);


        preptimer = INVALID_HANDLE;
        if (team == HIDDENALLIES) 
		{
			bTeam[client] = SEEKINGAXIS;
			CreateTimer(0.5, ChangeTeamDelayed, client);
			if (GetTeamClientCount(HIDDENALLIES) == 1)
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && (IsPlayerAlive(i)) && (GetTeam(i) == HIDDENALLIES))
						g_hBeacon = CreateTimer(GetConVarFloat(cvar_beep), Timer_Beacon,i,TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				}
			}
			
			if (Won()) 
			{
				KillTimer(g_hBeacon);
				g_hBeacon = INVALID_HANDLE;
				PrintCenterTextAll("The last one has been found :P");
				Restart(4);
            }
			CreateTimer(1.0,CheckHidden);
		}

        // pistol fun
        if ((GetConVarBool(cvar_earnweapons) == true) && (GetConVarBool(cvar_randomweapons) == false))
        {
            new String:CurWeapon[32];
            new attackerid = GetEventInt(event, "attacker");
            new attacker = GetClientOfUserId(attackerid);
            new ateam = GetTeam(attacker);


            WeaponCleanUp();


            if (IsClientInGame(attacker))
            {
                GetClientWeapon(attacker, CurWeapon, sizeof(CurWeapon));

                if ((strcmp(CurWeapon, "weapon_amerknife", true) == 0) || (strcmp(CurWeapon, "weapon_spade", true) == 0))
                {
                    if ((GetConVarInt(cvar_teams) == 1) && (ateam != team))
                    {
                        givePistol(attacker);
                    }
                    else if ((GetConVarInt(cvar_teams) == 2) && (ateam == HIDDENALLIES) && (ateam != team))
                    {
                        givePistol(attacker);
                    }
                    else if ((GetConVarInt(cvar_teams) == 3) && (ateam == SEEKINGAXIS) && (ateam != team))
                    {
                        givePistol(attacker);
                    }
                }
            }
        }

        if ((GetConVarBool(cvar_randomweapons) == true))
        {
            new String:CurWeapon[32];
            new attackerid = GetEventInt(event, "attacker");
            new attacker = GetClientOfUserId(attackerid);
            new ateam = GetTeam(attacker);

            WeaponCleanUp();


            if (IsClientInGame(attacker))
            {
                GetClientWeapon(attacker, CurWeapon, sizeof(CurWeapon));

                if ((strcmp(CurWeapon, "weapon_amerknife", true) == 0) || (strcmp(CurWeapon, "weapon_spade", true) == 0))
                {
                    if ((GetConVarInt(cvar_teams) == 1) && (ateam != team))
                    {
                        giveWeapon(attacker);
                    }
                    else if ((GetConVarInt(cvar_teams) == 2) && (ateam == HIDDENALLIES) && (ateam != team))
                    {
                        giveWeapon(attacker);
                    }
                    else if ((GetConVarInt(cvar_teams) == 3) && (ateam == SEEKINGAXIS) && (ateam != team))
                    {
                        giveWeapon(attacker);
                    }

                }

            }
        }





    }
}

// ******************************************************************************
// * Remove the weapons of a player                                                *
// ******************************************************************************
public Action:RemoveWeapon(Handle:timer, Handle:pack)
{
    new client;
    new team;

    ResetPack(pack);
    client = ReadPackCell(pack);
    team = ReadPackCell(pack);

    new wpn = GetPlayerWeaponSlot(client, 0);

    if (wpn <= -1)
    {
        wpn = GetPlayerWeaponSlot(client,1);
    }

    if (wpn > 0)
    {
        if (GetConVarInt(cvar_teams) == 1)
        {
            new g_Clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
            new WeaponClip = GetEntData(wpn, g_Clip);

            if (WeaponClip <= 0)
            {
                new ent = GetPlayerWeaponSlot(client, 1);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 0);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 2);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                if (GetTeam(client) == HIDDENALLIES)
                {
                    ent = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
            }
        }
        else if ((GetConVarInt(cvar_teams) == 2) && (team == HIDDENALLIES))
        {
            new g_Clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
            new WeaponClip = GetEntData(wpn, g_Clip);

            if (WeaponClip <= 0)
            {
                new ent = GetPlayerWeaponSlot(client, 1);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 0);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 2);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                if (GetTeam(client) == HIDDENALLIES)
                {
                    ent = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
            }
        }
        else if ((GetConVarInt(cvar_teams) == 3) && (team == SEEKINGAXIS))
        {
            new g_Clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
            new WeaponClip = GetEntData(wpn, g_Clip);

            if (WeaponClip <= 0)
            {
                new ent = GetPlayerWeaponSlot(client, 1);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 0);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                ent = GetPlayerWeaponSlot(client, 2);
                if(ent > 0)
                {
                    RemovePlayerItem(client, ent);
                }

                if (GetTeam(client) == 2)
                {
                    ent = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);
                }
            }
        }
    }

    return Plugin_Stop;
}


// ******************************************************************************
// * give a weapon to the player, but only one clip of ammo                        *
// ******************************************************************************
public giveWeapon (client)
{
    decl i,ent,melee;
    i = GetRandomInt(0,11);
    // weapons

    switch (i)
    {
        case 0: // p38
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_p38");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 1: // colt
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_colt");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 2: // k98
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_k98");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 3: // garand
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_garand");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 4: // bar
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_bar");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 5: // STG44 aka MP44
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_mp44");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 6: // Thompson
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_thompson");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 7: // Panzerschreck
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_pschreck");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 8: // Bazooka
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_bazooka");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 9: // M1 Carbine
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_m1carbine");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 10: // C96
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_c96");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
        case 11: // MP40
        {
            ent = GetPlayerWeaponSlot(client, 0);
            if (ent == -1)
                ent = GetPlayerWeaponSlot(client,1);

            if(ent <= -1)
            {

                ent = GivePlayerItem(client, "weapon_mp40");
                if (GetTeam(client) == HIDDENALLIES)
                {
                    SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(ent, 0, 0, 0, 0);

                    melee = GivePlayerItem(client, "weapon_amerknife");
                    SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                    SetEntityRenderColor(melee, 0, 0, 0, 0);
                }
                else
                {
                    ent = GivePlayerItem(client, "weapon_spade");
                }

                new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

                SetEntData(client, clipOffset+ (2*4), 4, true);
            }
        }
    }
}


// ******************************************************************************
// * Give a pistol to the player                                                *
// ******************************************************************************
public givePistol (client)
{
    decl ent,i,melee;

    i = GetRandomInt(0,1);
    if (i == 1)
    {
        ent = GetPlayerWeaponSlot(client, 1);
        //if(ent != -1)
        //    RemovePlayerItem(client, ent);
        if (ent <= -1)
        {
            ent = GivePlayerItem(client, "weapon_p38");
            if (GetTeam(client) == HIDDENALLIES)
            {
                SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                SetEntityRenderColor(ent, 0, 0, 0, 0);

                melee = GivePlayerItem(client, "weapon_amerknife");
                SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                SetEntityRenderColor(melee, 0, 0, 0, 0);
            }
            else
            {
                melee = GivePlayerItem(client, "weapon_spade");
            }

            new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");
            SetEntData(client, clipOffset+ (2*4), 4, true);
        }


    }
    else
    {
        ent = GetPlayerWeaponSlot(client, 1);
    //    if(ent != -1)
    //        RemovePlayerItem(client, ent);
        if (ent <= -1)
        {
            ent = GivePlayerItem(client, "weapon_colt");
            if (GetTeam(client) == HIDDENALLIES)
            {
                SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
                SetEntityRenderColor(ent, 0, 0, 0, 0);

                melee = GivePlayerItem(client, "weapon_amerknife");
                SetEntityRenderMode(melee, RENDER_TRANSCOLOR);
                SetEntityRenderColor(melee, 0, 0, 0, 0);
            }
            else
            {
                melee = GivePlayerItem(client, "weapon_spade");
            }

            new clipOffset = FindSendPropInfo("CDODPlayer", "m_iClip1");

            SetEntData(client, clipOffset+ (2*4), 4, true);
        }
    }
}


// ******************************************************************************
// * Change team, delayed                                                        *
// ******************************************************************************
public Action:ChangeTeamDelayed (Handle:timer, any:client) {
    SetTeam (client, 3)
}

// ******************************************************************************
// * Swap player to team                                                        *
// ******************************************************************************
SetTeam (client, team) {
    if ((client > 0) && (IsClientConnected(client)) && IsClientInGame(client))
    {
        new oldTeam = GetTeam(client);
        bSwitching[client] = true;
        ChangeClientTeam(client, SPECTATOR);
        ChangeClientTeam(client, team);
        if (oldTeam > 1)
            ShowVGUIPanel(client, team == 3 ? "class_ger" : "class_us", INVALID_HANDLE, false);
    }
}

// ******************************************************************************
// * Check which team the player is in                                            *
// ******************************************************************************
GetTeam (client) {
    if ((IsClientInGame(client)))
    {
        return GetClientTeam(client);
    }
    else
    {
        return -1;
    }
}

// ******************************************************************************
// * Commands: +3rd -1st                                                        *
// ******************************************************************************
public Action:ThirdOn(client, args)
{
    if (GetConVarBool(cvar_active))
    {
        SetPOV(client, true);
    }
    else
        PrintToConsole(client, "Command not available: Seek and Destroy is disabled");
}

// ******************************************************************************
// * Commands: -3rd +1st                                                        *
// ******************************************************************************
public Action:ThirdOff(client, args)
{
    if (GetConVarBool(cvar_active))
        SetPOV(client, false);
    else
        PrintToConsole(client, "Command not available: Seek and Destroy is disabled");
}

// ******************************************************************************
// * Change Point Of View (for 3rd person)                                        *
// ******************************************************************************
SetPOV (client, bool:bThird)
{
    if ((IsClientConnected(client)) && (IsClientInGame(client)))
    {
        if (bThird) {
            SetEntData(client, m_hObserverTarget_offs, 0, 4, true);
            SetEntData(client, m_iObserverMode_offs, 1, 4, true);
            SetEntData(client, m_iFOV_offs, 120, 4, true);
            SetEntData(client, m_Local_offs+m_bDrawViewmodel_offs, 0, 4, true);
        }
        else {
            SetEntData(client, m_hObserverTarget_offs, 0, 4, true);
            SetEntData(client, m_iObserverMode_offs, 0, 4, true);
            SetEntData(client, m_iFOV_offs, 90, 4, true);
            SetEntData(client, m_Local_offs+m_bDrawViewmodel_offs, 1, 4, true);
        }
    }
}


// ******************************************************************************
// * Blind Player                                                                *
// ******************************************************************************
PerformBlind(target, amount)
{
    new targets[2];
    targets[0] = target;
    targets[1] = 0;

    new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
    BfWriteShort(message, 1536);
    BfWriteShort(message, 1536);

    if (amount == 0)
    {
        BfWriteShort(message, (0x0001 | 0x0010));
    }
    else
    {
        BfWriteShort(message, (0x0002 | 0x0008));
    }

    BfWriteByte(message, 0);
    BfWriteByte(message, 0);
    BfWriteByte(message, 0);
    BfWriteByte(message, amount);

    EndMessage();
}


// ******************************************************************************
// * Player got hurt                                                            *
// ******************************************************************************
public OnPlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarBool(cvar_active))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new team = GetTeam(client)

		// Spawn Protection for Axis during Warumup
		if ((roundState == PREPARATION) && (team == SEEKINGAXIS))
		{
			SetEntData(client, FindDataMapOffs(client, "m_iMaxHealth"), 100, 4, true);
			SetEntData(client, FindDataMapOffs(client, "m_iHealth"), 100, 4, true);
		}

		if ((team == HIDDENALLIES) && (GetClientHealth(client) <= 0))
		{
			// Reset Model to normal before dead
			if (!IsModelPrecached("models/player/american_rifleman.mdl"))
				PrecacheModel("models/player/american_rifleman.mdl");

			SetEntityModel(client, "models/player/american_rifleman.mdl");
			SetEntityRenderMode(client, RENDER_TRANSCOLOR);
			SetEntityRenderColor(client, 0, 0, 0, 0);

			// Put the player into 3rd person
			SetPOV(client, false);
		}
	}
}

// ******************************************************************************
// * Timer for Beacon Player                                                    *
// ******************************************************************************
public Action:Timer_Beacon(Handle:timer, any:client)
{
    if (!IsClientInGame(client) || IsClientObserver(client) || !IsPlayerAlive(client)) {
        g_hBeacon      = INVALID_HANDLE;
        return Plugin_Stop;
    }
    decl Float:fPosition[3];
    GetClientAbsOrigin(client, fPosition);
    fPosition[2]    += 10;

    TE_SetupBeamRingPoint(fPosition, 10.0, 375.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.5, 5.0,  0.0, g_iGrey, 10, 0);
    TE_SendToAll();

    TE_SetupBeamRingPoint(fPosition, 10.0, 375.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 10.0, 0.5, g_iRed,  10, 0);
    TE_SendToAll();

    GetClientEyePosition(client, fPosition);
    EmitAmbientSound("buttons/blip1.wav", fPosition, client, SNDLEVEL_RAIDSIREN);

    return Plugin_Handled;
}

// ******************************************************************************
// * Freeze player                                                                *
// ******************************************************************************
FreezeClient(client)
{
    SetEntityMoveType(client, MOVETYPE_NONE);
}

// ******************************************************************************
// * Unfreeze player                                                            *
// ******************************************************************************
UnfreezeClient(client)
{
    SetEntityMoveType(client, MOVETYPE_WALK);
}
