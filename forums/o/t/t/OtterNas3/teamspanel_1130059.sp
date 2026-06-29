#include <sourcemod>
#include <sdktools>


//Define CVARS
#define MAX_SURVIVORS GetConVarInt(FindConVar("survivor_limit"))
#define MAX_INFECTED GetConVarInt(FindConVar("z_max_player_zombies"))
#define PLUGIN_VERSION "1.4"


//Handles
new Handle:invalid = INVALID_HANDLE;
new Handle:cc_plpOnConnect = INVALID_HANDLE;
new Handle:cc_plpTimer = INVALID_HANDLE;


//CVARS
new GameMode;
new plpOnConnect=1;
new plpTimer=20;


//Plugin Info Block
public Plugin:myinfo =
{
	name = "Playerlist Panel",
	author = "OtterNas3",
	description = "Shows Panel for Teams on Server",
	version = PLUGIN_VERSION,
	url = "n/A"
};


//Plugin start
public OnPluginStart()
{
    //Reg Commands
    RegConsoleCmd("sm_teams", PrintTeamsToClient);

    //Reg Cvars
    CreateConVar("l4d_plp_version", PLUGIN_VERSION, "Playerlist Panel Display Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cc_plpOnConnect = CreateConVar("l4d_plp_onconnect", "1", "Show Playerlist Panel on Connect?");
    cc_plpTimer = CreateConVar("l4d_plp_timer", "20", "How long should the Playerlist Panel been displayed? (seconds)");

    AutoExecConfig(true, "l4d_teamspanel");

    //Hook Cvars
    HookConVarChange(cc_plpOnConnect, ConVarChanged);
    HookConVarChange(cc_plpTimer, ConVarChanged);

}


//Prepare & Print Playerlist Panel
public Action:PrintTeamsToClient(client, args)
{
    //Check if l4downtown or l4dtoolz is running and get max clients because server wil show total x/32 with MaxClients when one of this plugins runing
    new Handle:downtownrun = FindConVar("l4d_maxplayers");
    new Handle:toolzrun = FindConVar("sv_maxplayers");
    new maxcl;

	//Downtown is running!
    if (downtownrun != (invalid))
    {
        //Is Downtown used for slot patching? if yes use it for Max Players
        new downtown = GetConVarInt(FindConVar("l4d_maxplayers"));
        if (downtown >= 1)
        {
            maxcl = (GetConVarInt(FindConVar("l4d_maxplayers")));
        }
    }

    //L4DToolz is running!
    if (toolzrun != (invalid))
    {
        //Is L4DToolz used for slot patching? if yes use it for Max Players
        new toolz = GetConVarInt(FindConVar("sv_maxplayers"));
        if (toolz >= 1)
        {
            maxcl = GetConVarInt(FindConVar("sv_maxplayers"));
        }
    }

    //No Downtown or L4DToolz running using fallback (possible x/32)
    if (downtownrun == (invalid) && toolzrun == (invalid))
    {
        maxcl = (MaxClients);
    }

    //Now we found out for how many Players to build let's go
    new i, j = (maxcl);
    new botcounts[3];
    new playerteams[maxcl+1];
    new teamcounts[3];
    new tempteam;

    //Counting teams
    for (i = 1; i < maxcl+1; i++)
    {
        if (IsClientInGame(i))
        {
            tempteam = GetClientTeam(i) -1 ;
        
            playerteams[i-1] = tempteam
            teamcounts[tempteam]++;
            
            //botcount
            if (IsFakeClient(i)) botcounts[tempteam]++;
        }
        //just to be sure
        else playerteams[i-1] = -1;
    }
    
    //Build panel
    new Handle:TeamPanel = CreatePanel();
    SetPanelTitle(TeamPanel, "Playerlist Panel");
    DrawPanelText(TeamPanel, " \n");
    new count;
    new sum;
    new String:text[64];

    //How many Clients ingame?
    for (i = 0; i < 3; i++) sum += teamcounts[i];

    //Draw Spectators count line
    Format(text, sizeof(text), "Spectators (%d of %d)\n", teamcounts[0], (sum - botcounts[1]));

    //Get & Draw Spectator Player Names
    DrawPanelText(TeamPanel, text);
    count = 1;
    for (j = 0; j < maxcl; j++)
    {
        if (playerteams[j] != 0) continue;
        
        Format(text, sizeof(text), "%d. %N", count, (j + 1));
        DrawPanelText(TeamPanel, text);
        
        count++;
    }
    DrawPanelText(TeamPanel, " \n");
	
    //Draw Survivors count line
    Format(text, sizeof(text), "Survivors (%d of %d)\n", (teamcounts[1] - botcounts[1]), MAX_SURVIVORS);

    //Get & Draw Survivor Player Names
    DrawPanelText(TeamPanel, text);
    count = 1;
    for (j = 0; j < maxcl; j++)
    {
        if (playerteams[j] != 1) continue;

        Format(text, sizeof(text), "%d. %N", count, (j + 1));
        DrawPanelText(TeamPanel, text);
        
        count++;
    }
    DrawPanelText(TeamPanel, " \n");


    //Draw Infected part depending on gamemode
    GameModeCheck()

    //Gamemode is Versus
    if (GameMode == 2)
    {
        //Draw Infected count line
        Format(text, sizeof(text), "Infected (%d of %d)\n", (teamcounts[2] - botcounts[2]), MAX_INFECTED);

        //Get & Draw Infected Player Names
        DrawPanelText(TeamPanel, text);
        count = 1;
        for (j = 0; j < maxcl; j++)
        {
            if (playerteams[j] != 2) continue;
        
            Format(text, sizeof(text), "%d. %N", count, (j + 1));
            DrawPanelText(TeamPanel, text);
        
            count++;
        }
        DrawPanelText(TeamPanel, " \n");

        //Draw Total connected Players
        Format(text, sizeof(text), "Connected: %d/%d", (sum - botcounts[1]), maxcl);

        DrawPanelText(TeamPanel, text);
    }

    //If Gamemode Coop
    if (GameMode == 1)
    {
        //2.4.2.1 Draw Total connected Players
        Format(text, sizeof(text), "Connected: %d/%d", (teamcounts[1] - botcounts[1]), MAX_SURVIVORS);

        DrawPanelText(TeamPanel, text);
    }

    //3. Print Panel
    SendPanelToClient(TeamPanel, client, TeamPanelHandler, plpTimer);
    CloseHandle(TeamPanel);
}


//Fake TeamPanelHandler
public TeamPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
    //Nothing
}


//Gamemode Check
GameModeCheck()
{
    new String:gamemodecvar[16];
    GetConVarString(FindConVar("mp_gamemode"), gamemodecvar, sizeof(gamemodecvar));
    if (StrContains(gamemodecvar, "versus", false) != -1)
    {
        GameMode = 2;
    }
    if (StrContains(gamemodecvar, "coop", false) != -1)
    {
        GameMode = 1;
    }
}


//Cvar changed check
public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    ReadCvars();
}


//Re-Read Cvars
public ReadCvars()
{
    plpOnConnect=GetConVarInt(cc_plpOnConnect);
    plpTimer=GetConVarInt(cc_plpTimer);
}


//Dow we Show Panel On Connect? (on by default)
public Action:OnConnect(Handle:timer, any:value)
{
    if (plpOnConnect == 1)
    {
        PrintTeamsToClient(value, 0);
    }
}


//Show Panel when Client is Connected
public OnClientPostAdminCheck(client)
{
    CreateTimer(10.0, OnConnect, client);
}
