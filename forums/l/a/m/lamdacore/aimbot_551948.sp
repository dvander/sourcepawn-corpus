#pragma semicolon 1
#include <sourcemod>
#include <menus>

#define VERSION "0.0.1.0"
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

//hslog.ini file
#define LOG 1
#if LOG == 1
new Handle:hsfile;
#endif

//Console variable
//aim_minimum_data
new Handle:cMinData;
//aim_minimum_percentage
new Handle:cMinPercentage;
//aim_torso_weight
new Handle:cTorsoWeight;
//aim_limb_weight
new Handle:cLimbWeight;

new admFeatures;
#define FEATURE_BAT 1
#define FEATURE_MANI 2
#define FEATURE_IRC 4

new nextPlayer;


//Snap speed stuff
new off_VecOrigin;
new off_EyeAng[2];
new off_View[MAX_PLAYERS];

new Float:prevAngles[2][MAX_PLAYERS][3];
new curAng, prevAng;
new Float:maxSpeed[MAX_PLAYERS];
new Float:totalSpeed[MAX_PLAYERS];
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
#if LOG == 1
    BuildPath(Path_SM,temp,256,"hslog.ini");
    hsfile = OpenFile(temp,"a");
#endif    
    BuildPath(Path_SM,temp,256,"configs/weapondata.ini");
    new Handle:fl = OpenFile(temp,"r");
    
    decl String:arg[64];
    while (!IsEndOfFile(fl))
    {
        ReadFileLine(fl,temp,256);
        new pos = StrBreak(temp,weapons[nextWeapon],64);
        StrBreak(temp[pos],arg,64);
        wpnWeights[nextWeapon] = StringToFloat(arg);
        //PrintToServer("Loaded %s, weight %f",weapons[nextWeapon],wpnWeights[nextWeapon]);
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
    CreateConVar("aim_version",VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    off_VecOrigin = FindSendPropOffs("CBaseEntity","m_vecOrigin");
    off_EyeAng[0] = FindSendPropOffs("CDODPlayer","m_angEyeAngles[0]");
    off_EyeAng[1] = FindSendPropOffs("CDODPlayer","m_angEyeAngles[1]");
         
    nextPlayer = 1;
    CreateTimer(5.0,CheckNextPlayer,INVALID_HANDLE,TIMER_REPEAT);
    CreateTimer(15.0,UpdateMenus,INVALID_HANDLE,TIMER_REPEAT);
}

public OnServerCfg()
{
    admFeatures = FEATURE_IRC;
    if (FindConVar("bat_version") != INVALID_HANDLE)
        admFeatures |= FEATURE_BAT;
    if (FindConVar("mani_version") != INVALID_HANDLE) 
        admFeatures |= FEATURE_MANI;
    if (FindConVar("irc_version") != INVALID_HANDLE)
        admFeatures |= FEATURE_IRC;       
}

public OnPluginEnd()
{
#if LOG == 1
    CloseHandle(hsfile);
#endif
}

public OnMapStart()
{
    for (new i=0;i<GetMaxClients()+1;++i)
    {
#if LOG == 1
        WriteInfo(i);
#endif
        ClearInfo(i);
    }
#if LOG == 1    
    CloseHandle(hsfile);
    decl String:temp[256];
    BuildPath(Path_SM,temp,256,"hslog.ini");
    hsfile = OpenFile(temp,"a");
#endif
}

public OnClientPutInServer(client)
{
    ClearInfo(client);
    off_View[client] = FindDataMapOffs(client,"m_vecViewOffset");
}

public OnClientDisconnect(client)
{
#if LOG == 1
    WriteInfo(client);
#endif
    ClearInfo(client);
    //DisplayInfo(client);
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
        if (StrCompare(wpnname,weapons[i],true) == 0)
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
    if (!IsPlayerInGame(nextPlayer) || IsFakeClient(nextPlayer) || plSamples[nextPlayer] < GetConVarInt(cMinData) || GetTime()-LastMessage[nextPlayer] < 120)
    {
        //LogToGame("Not checking player %i, samples: %f",nextPlayer,plSamples[nextPlayer]);
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
    
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        if (percent[i] > maxPercent)
        {
             Format(msg,256,"\x02Warning:\x0F Player %s (%s): %.0f (%.02f percent) hits to the %s; max snap speed %.02f, avg %0.2f"
                ,plName,plId,plData[nextPlayer][i],(percent[i]*100.0),hitgroups[i],maxSpeed[nextPlayer],(totalSpeed[nextPlayer]/totalCount[nextPlayer]));
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
                ServerCommand("irc_relay %s",msg);
            }
            for (new j=1;j<GetMaxClients()+1;++j)
            {
                if (IsClientInGame(j) && GetUserFlagBits(j)&Admin_Kick == 1)
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

public OnGameFrame()
{
    for (new i=1;i<GetMaxClients();++i)
    {
        if (IsPlayerInGame(i) && !IsFakeClient(i))
        {
            GetEyeAng(i,prevAngles[curAng][i]);
            decl Float:dist[3];
            GetAngleDistance(prevAngles[curAng][i],prevAngles[prevAng][i],dist);
            new Float:s = dist[0]+dist[1];
            
            if (s > 1 && s < 70)
            {
                //CPrint(i,"Speed: %0.3f avg: %0.3f",dist[1],totalSpeed[i]/totalCount[i]);
                /*if (s > (totalSpeed[i]/totalCount[i])*3.5)
                {
                    CPrint(0,"Aimbot warning %i: Speed: %f, avg: %f",i,s,(totalSpeed[i]/totalCount[i]));
                }*/
                totalSpeed[i] += s;
                ++totalCount[i];
                if (s > maxSpeed[i]) maxSpeed[i] = s;
            }
        }   
    }
    curAng = !curAng;
    prevAng = !prevAng;
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

DisplayInfo(client)
{
    PrintToServer("Client ID: %i Number of samples: %i",client,plSamples[client]);
    PrintToServer("HITGROUP_GENERIC: %f - %f",plData[client][HITGROUP_GENERIC],plData[client][HITGROUP_GENERIC]/plSamples[client]);   
    PrintToServer("HITGROUP_HEAD: %f - %f",plData[client][HITGROUP_HEAD],plData[client][HITGROUP_HEAD]/plSamples[client]);   
    PrintToServer("HITGROUP_CHEST: %f - %f",plData[client][HITGROUP_CHEST],plData[client][HITGROUP_CHEST]/plSamples[client]);   
    PrintToServer("HITGROUP_STOMACH: %f - %f",plData[client][HITGROUP_STOMACH],plData[client][HITGROUP_STOMACH]/plSamples[client]);   
    PrintToServer("HITGROUP_LEFTARM: %f - %f",plData[client][HITGROUP_LEFTARM],plData[client][HITGROUP_LEFTARM]/plSamples[client]);   
    PrintToServer("HITGROUP_RIGHTARM: %f - %f",plData[client][HITGROUP_RIGHTARM],plData[client][HITGROUP_RIGHTARM]/plSamples[client]);   
    PrintToServer("HITGROUP_LEFTLEG: %f - %f",plData[client][HITGROUP_LEFTLEG],plData[client][HITGROUP_LEFTLEG]/plSamples[client]);   
    PrintToServer("HITGROUP_RIGHTLEG: %f - %f",plData[client][HITGROUP_RIGHTLEG],plData[client][HITGROUP_RIGHTLEG]/plSamples[client]);
}
#if LOG == 1
WriteInfo(client)
{
    if (client <= 0 || !IsPlayerInGame(client) || IsFakeClient(client)) return;
    if (plSamples[client] <= 1) return;
    
    new String:out[512];
    GetClientAuthString(client,out,512);
    Format(out,512,"%s,%f",out,plSamples[client]);
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        Format(out,512,"%s,%f",out,plData[client][i]);
    }
    WriteFileLine(hsfile,"%s",out);
}
#endif
ClearInfo(client)
{
    if (client <= 0) return;
    
    plSamples[client] = 0.0;
    for (new i=0;i<MAX_HITGROUP;++i)
    {
        plData[client][i] = 0.0;
    }
    LastMessage[client] = 0;
    maxSpeed[client] = 0.0;
    totalCount[client] = 1;
}
public Float:GetDistance(Float:a[3],Float:b[3])
{
    new Float:x = a[0]-b[0];
    new Float:y = a[1]-b[1];
    new Float:z = a[2]-b[2];
    return SquareRoot((x*x)+(y*y)+(z*z));
}

public GetAngleDistance(Float:a[3],Float:b[3],Float:ret[3])
{
    ret[0] = FloatAbs(a[0]-b[0]);
    if (ret[0] > 180) ret[0] = 360.0-ret[0];
    ret[1] = FloatAbs(a[1]-b[1]);
    if (ret[1] > 180) ret[1] = 360.0-ret[1];
}

public Float:Round3(Float:a)
{
    return RoundToFloor(a*1000.0)/1000.0;
}

public GetEyePos(client,Float:eyepos[3])
{
    new Float:temp[3];
    GetEntDataVector(client,off_View[client],temp);
    GetEntDataVector(client,off_VecOrigin,eyepos);
    eyepos[2]=eyepos[2]+temp[2];
}

public GetEyeAng(client,Float:eyeang[3])
{
    eyeang[0]=GetEntDataFloat(client,off_EyeAng[0]);
    eyeang[1]=GetEntDataFloat(client,off_EyeAng[1]);
    eyeang[2]=0.0;
}