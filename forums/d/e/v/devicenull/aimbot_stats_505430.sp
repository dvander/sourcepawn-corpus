#pragma semicolon 1
#include <sourcemod>
#include <menus>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <irc-relay>
#define REQUIRE_PLUGIN 1

#define VERSION "0.0.2.0"
public Plugin:myinfo = 
{
	name = "Aimbot Detection",
	author = "devicenull",
	description = "Detects aimbots",
	version = VERSION,
	url = "http://www.devicenull.org/"
};
//From the hl2sdk, game_shared/shareddefs.h
#define MAX_HITGROUP 8

#define	HITGROUP_GENERIC	0
#define	HITGROUP_HEAD		1
#define	HITGROUP_CHEST		2
#define	HITGROUP_STOMACH	3
#define HITGROUP_LEFTARM	4	
#define HITGROUP_RIGHTARM	5
#define HITGROUP_LEFTLEG	6
#define HITGROUP_RIGHTLEG	7
//We ignore gear, it doesnt do damage
#define HITGROUP_GEAR		10

new String:hitgroups[MAX_HITGROUP][] =
{
    "GENERIC"
    ,"HEAD"
    ,"CHEST"
    ,"STOMACH"
    ,"LEFTARM"
    ,"RIGHTARM"
    ,"LEFTLEG"
    ,"RIGHTLEG"
};

#define MAX_PLAYERS MAXPLAYERS+1
#define MAX_WEAPONS 32

//Config file stuff
new String:weapons[MAX_WEAPONS][64];
new Float:wpnWeights[MAX_WEAPONS];
new nextWeapon;

//Player data
new Float:plData[MAX_PLAYERS][MAX_HITGROUP];
new Float:plSamples[MAX_PLAYERS];
//Last time we alerted for this player
new LastMessage[MAX_PLAYERS];
//Which menu the player is displaying
new curSel[MAX_PLAYERS];

//Console variable
//aim_minimum_data
new Handle:cMinData;
//aim_minimum_percentage
new Handle:cMinPercentage;
//aim_torso_weight
new Handle:cTorsoWeight;
//aim_limb_weight
new Handle:cLimbWeight;
//aim_irc_channel
new Handle:cIrcChan;


new admFeatures;
#define FEATURE_BAT 1
#define FEATURE_MANI 2
#define FEATURE_IRC 4

new nextPlayer;
new curTrace;


new totalCount[MAX_PLAYERS];


#define DEG2RAD (3.1415927/180)
#define RAD2DEG (180/3.1415927)
#define PRECISION 0.001


public OnPluginStart()
{
    HookEvent("player_hurt",playerHurt);
    RegConsoleCmd("aim_info",AimInfo);
        
    
    decl String:temp[256];
    PrintToServer("Loading weapon data... ");
 
    BuildPath(Path_SM,temp,256,"configs/weapondata.ini");
    new Handle:fl = OpenFile(temp,"r");
    
    decl String:arg[64];
    while (!IsEndOfFile(fl))
    {
        ReadFileLine(fl,temp,256);
        new pos = BreakString(temp,weapons[nextWeapon],64);
        BreakString(temp[pos],arg,64);
        wpnWeights[nextWeapon] = StringToFloat(arg);
        ++nextWeapon;
    }
    CloseHandle(fl); 
    for (new i=1;i<MAX_PLAYERS;++i)
    {
        plSamples[i] = 0.0;
    }
    cMinData = CreateConVar("aim_minimum_data","20","Minimum number of data to be collected before deciding");	
    cMinPercentage = CreateConVar("aim_minimum_percentage","55","Minimum percentage of hits to a specific area before a user ");	
    cTorsoWeight = CreateConVar("aim_torso_weight","0.50","This will be multiplied by the players percentage of hits to the torso");
    cLimbWeight = CreateConVar("aim_limb_weight","0.50","This will be multiplied by the players percentage of hits to the limbs");
    cIrcChan = CreateConVar("aim_irc_channel","#test","This is the channel to send IRC alerts to");
    CreateConVar("aim_version",VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
            
    nextPlayer = 1;

    CreateTimer(5.0,CheckNextPlayer,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(15.0,UpdateMenus,INVALID_HANDLE,TIMER_REPEAT);
}

public OnConfigsExecuted()
{
    admFeatures = 0;
    if (FindConVar("bat_version") != INVALID_HANDLE)
        admFeatures |= FEATURE_BAT;
    if (FindConVar("mani_version") != INVALID_HANDLE) 
        admFeatures |= FEATURE_MANI;
    if (FindConVar("irc_version") != INVALID_HANDLE)
        admFeatures |= FEATURE_IRC;      
}

public OnMapStart()
{
    for (new i=0;i<GetMaxClients()+1;++i)
    {
        ClearInfo(i);
    }
}

public OnClientPutInServer(client)
{
    ClearInfo(client);
}

public OnClientDisconnect(client)
{
    ClearInfo(client);
}

public playerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new hitgroup = GetEventInt(event,"hitgroup");
    if (hitgroup >= MAX_HITGROUP)
    {
        return;
    }
    new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
    new String:wpnname[64];
    GetEventString(event,"weapon",wpnname,64);
    new wpnIndex = -1;
    for (new i=0;i<nextWeapon;++i)
    {
        if (strcmp(wpnname,weapons[i],true) == 0)
        {
            wpnIndex = i;
            break;
        }
    }
    if (wpnIndex == -1)
    {
        LogToGame("Couldn't find weapon %s",wpnname);
        return;
    }
    
    plData[attacker][hitgroup] += wpnWeights[wpnIndex];
    //If we just add 1 to plSamples, the shotgun fucks everything up
    plSamples[attacker] += wpnWeights[wpnIndex];
}

public Action:CheckNextPlayer(Handle:timer, Handle:hndl)
{
    if (!IsClientInGame(nextPlayer) || IsFakeClient(nextPlayer) || plSamples[nextPlayer] < GetConVarInt(cMinData) || GetTime()-LastMessage[nextPlayer] < 120)
    {
        ++nextPlayer;
        if (nextPlayer > GetMaxClients()) nextPlayer = 1;
        return Plugin_Continue;
    }
    decl Float:percent[MAX_HITGROUP];
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        percent[i] = plData[nextPlayer][i]/plSamples[nextPlayer];
    }
    percent[HITGROUP_CHEST] *= GetConVarFloat(cTorsoWeight);
    percent[HITGROUP_STOMACH] *= GetConVarFloat(cTorsoWeight);
    new Float:limbweight = GetConVarFloat(cLimbWeight);
    percent[HITGROUP_LEFTARM] *= limbweight;
    percent[HITGROUP_RIGHTARM] *= limbweight;
    percent[HITGROUP_LEFTLEG] *= limbweight;
    percent[HITGROUP_RIGHTLEG] *= limbweight;
    
    new Float:maxPercent = GetConVarFloat(cMinPercentage)/100.0;
    decl String:plName[128], String:plId[64], String:msg[256];
    GetClientName(nextPlayer,plName,128);
    GetClientAuthString(nextPlayer,plId,64);
    
    new String:ircchan[64];
    GetConVarString(cIrcChan,ircchan,64);    
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        if (percent[i] > maxPercent)
        {
            Format(msg,256,"\x02Warning:\x0F Player %s (%s): %.0f (%.02f percent) hits to the %s"
                ,plName,plId,plData[nextPlayer][i],(percent[i]*100.0),hitgroups[i]);
            LogToGame("%s",msg);
            if (admFeatures&FEATURE_BAT)
            {
                ServerCommand("admin_chat %s",msg);
            }
            if (admFeatures&FEATURE_MANI)
            {
                ServerCommand("ma_chat %s",msg);
            }
            if (admFeatures&FEATURE_IRC)
            {
                IRC_PrivMsg(ircchan,"%s",msg);
            }
            for (new j=1;j<GetMaxClients()+1;++j)
            {
                if (IsClientInGame(j) && GetUserFlagBits(j)&Admin_Kick)
                {
                    PrintToChat(j,msg);
                }
            }
            LastMessage[nextPlayer] = GetTime();
            break;
        }
    }
    ++nextPlayer;
    if (nextPlayer > GetMaxClients()) nextPlayer = 1;
    return Plugin_Continue;
}

public bool:filter(entity, contentsMask)
{
    if (entity == curTrace)
    {
        return false;
    }
    if (entity >=1 && entity <= GetMaxClients())
    {
        return true;
    }
    return false;
}

public Action:AimInfo(client,args)
{
    curSel[client] = client;
    AimMenu(client);
    return Plugin_Handled;
}

AimMenu(to)
{
    new Handle:pnl = CreatePanel();
    new String:temp[256];
    GetClientName(curSel[to],temp,256);
    SetPanelTitle(pnl,temp);
    DrawPanelItem(pnl," ",ITEMDRAW_SPACER);
    Format(temp,256,"Sample count: %.2f",plSamples[curSel[to]]);
    DrawPanelText(pnl,temp);
    if (plSamples[curSel[to]] == 0)
    {
        DrawPanelText(pnl,"No data");   
    }
    else
    {
        for (new i=0;i<MAX_HITGROUP;++i)
        {
            Format(temp,256,"%s:  %3.2f%%",hitgroups[i],(plData[curSel[to]][i]/plSamples[curSel[to]])*100.0);
            DrawPanelText(pnl,temp);
        }
    }
    DrawPanelItem(pnl," ",ITEMDRAW_SPACER);
    for (new i=0;i<5;++i)
    {
        DrawPanelItem(pnl," ",ITEMDRAW_NOTEXT);
    }
    if (curSel[to]+1 < GetMaxClients())
    {
        DrawPanelItem(pnl,"Next",ITEMDRAW_CONTROL);
    }
    else
    {
        DrawPanelItem(pnl,"Next",ITEMDRAW_NOTEXT);
    }
    if (curSel[to]-1 > 0)
    {
        DrawPanelItem(pnl,"Prev",ITEMDRAW_CONTROL);
    }
    else
    {
        DrawPanelItem(pnl,"Prev",ITEMDRAW_NOTEXT);
    }
    DrawPanelItem(pnl,"Exit",ITEMDRAW_CONTROL);
    SendPanelToClient(pnl,to,AimInfo_Handler,MENU_TIME_FOREVER);
}

public AimInfo_Handler(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        //(param1=client, param2=item)
        if (param2 == 10)
        {
            curSel[param1] = 0;
            return;
        }
        new cnt = 1;
        
        if (param2 == 9) 
        {   //Prev
            cnt = -1;
        }
        new nextDisp = curSel[param1]+cnt;
        while (nextDisp > 0 && nextDisp <= GetMaxClients())
        {
            if (IsClientInGame(nextDisp) && !IsFakeClient(nextDisp))
            {
                break;
            }
            nextDisp += cnt;   
        }
        if (nextDisp > 0 && nextDisp <= GetMaxClients() && IsClientInGame(nextDisp) && !IsFakeClient(nextDisp))
        {
            curSel[param1] = nextDisp;
            AimMenu(param1);
        }
        else
        {
            AimMenu(param1);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 != MenuCancel_Interrupted)
        {
            curSel[param1] = 0;   
        }
    }
}

public Action:UpdateMenus(Handle:timer, Handle:hndl)
{
    for (new i=1;i<GetMaxClients()+1;++i)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && curSel[i] > 0)
        {
            AimMenu(i);
        }
    }
}

ClearInfo(client)
{
    if (client <= 0) return;
    
    plSamples[client] = 0.0;
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        plData[client][i] = 0.0;
    }
    LastMessage[client] = 0;
    totalCount[client] = 1;
}
