/*
#################################################
##                                             ##
##   CSS Bank (including MySQL support) v1.3   ##
##                                             ##
#################################################

Inital plugin:
    SM Bank Mod: MySQL from Nican, mateo10

Fundamental changes:
    * added new cvars
    * added auto deposit/withdraw
    * added some other features
    * reworked complete code

Description:
    A player can deposit money to the bank, transfer it to other players or withdraw when needed.
    Also set automatic deposit and/or withdraw.
    Supports MySQL

Credits:
    Nican for his inital plugin: SM Bank Mod: MySQL
    graczu for the top10 part in his css_rank plugin
    SilentWarrior for gave mightily assistance
    svito for Slovak translation

Changelog:
    1.0 (03-06-2010)
        ** Initial Release!
    1.1 (03-07-2010)
        ** Fixed: DB storage bug
        ++ Added: bank only activated for player in team
    1.1.1 (03-09-2010)
        ** Fixed: percentage sign not shown in bank menu info
        ** Fixed: checks whether a player is on a team, did not work properly
    1.2 (03-21-2010)
        ** Fixed: Playernames now shown in right teamcolor
        ++ Added: Admin menu; Command: bankadmin
        ++ Added: Possibility to edit amount menu in translation file
        >> Changed: Color in chat from lightgreen to green
        >> some code improvements
    1.3 (06-12-2010)
        ++ Added: Possibility to type !deposit <all/amount> and !withdraw <all/amount>
        ++ Added: New CVARs: css_bank_mapprefixes, css_bank_mapmode
                to enable/disable bank according to map prefix
        ++ Added: Commands to reset bank (only money or all)
        ++ Added: Possibility to hide from top10
        ++ Added: Possibility to reset own account
        ++ Added: admin can target itself
        ++ Added: Slovak translation (thanks to svito)
        >> Changed: Bankmenu (new: settings-item)
    1.3.1 (06-13-2010)
        ** Fixed: with css_bank_maximum "0" (disabled), admin-Setmoney not worked
    1.3.2 (06-20-2010)
        ** Fixed: problem with quotes in player names

Cvarlist: (default value):
    If you load the plugin the first time, a config file (cssbank.cfg) will be generated in the cfg/sourmod folder.

    css_bank_enable "1"                    Turns Bank On/Off
    css_bank_maximum "250000"            Maximun amount of money players are allowed to have in the bank, 0 to disable
    css_bank_announce "1.0"                Turns on announcement when a player joins the server, every map or every round: 0.0 = disabled, 1.0 = every map, 2.0 = every round
    css_bank_deposit_fee "200"            Fee, the players must pay for each deposit
    css_bank_interest "2.5"                % of interest players will get per round
    css_bank_min_deposit "1000"            Min. deposit amount, 0 to disable
    css_bank_pistolrounds "1"            Set the number of pistolrounds the bank is disabled, min. 0
    css_bank_identity "CSS Bank"        Set the name of your bank
    css_bank_min_players "2"            The number of min players to activate bank, min 0
    css_bank_dbconfig "clientprefs"        Set the database configuration listed in databases.cfg
    css_bank_mapmode "0"                0 = Disable bank during listed map prefixes, 1 = disable bank during NON-listed map prefixes (only listed maps enable bank)
    css_bank_mapprefixes " "            List the map prefixes where the bank is enabled or disabled. Related to the css_bank_mapmode Cvar

User commands: (chat trigger)
    bank            (!bank or /bank)                Display a menu with the Bank functions
    deposit            (!deposit or /deposit)            Display a menu with amounts to deposit
    withdraw        (!withdraw or /withdraw)        Display a menu with amounts to withdraw
    bankstatus        (!bankstatus or /bankstatus)    Prints the current bankstatus to the chat
    deposit    <all|amount>    (!deposit <all|amount> or /deposit <all|amount>)    to deposit all or typed amount
    withdraw <all|amount>    (!withdraw <all|amount> or /withdraw <all|amount>)    to withdraw all (max 16000) or typed amount

Admin commands: (chat trigger)
    bankadmin    (!bankadmin or /bankadmin)    Display a menu with the Bank functions for an admin

Server commands:
    css_bank_reset_all        resets the hole bank
    css_bank_reset_money    resets only money amounts

Installation:
    copy the cssbank.smx to your plugins folder
    copy the cssbank.phrases.txt to your translations folder
    
Update from v1.2 or older to v1.3:
    1. delete the cssbank.cfg in your cfg folder to create the new one (two new cvars)
    2. copy the cssbank.smx to your plugins folder
    3. copy the cssbank.phrases.txt to your translations folder
    4. reload the plugin or change map or restart server
    5. execute server command "css_bank_update"
    6. and it's better to change map after update to minimize data loss
    
    If you are using mysql, you can instead of point 5 and 6 also run "ALTER TABLE` css_bank `ADD` hide_rank `int (1) NOT NULL DEFAULT 0" in your db.

Todo:
    - add cash info from players on the server
    - add more translations
    - add a web interface

Author:
    Miraculix
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3.2"

// chat colors
#define YELLOW "\x01"
#define TEAMCOLOR "\x03"
#define GREEN "\x04"

// CVAR-Handles
new Handle:cvar_Bankversion = INVALID_HANDLE;
new Handle:cvar_Bankenable = INVALID_HANDLE;
new Handle:cvar_Bankmaxbank = INVALID_HANDLE;
new Handle:cvar_Bankannounce = INVALID_HANDLE;
new Handle:cvar_Bankdepositfee = INVALID_HANDLE;
new Handle:cvar_Bankinterest = INVALID_HANDLE;
new Handle:cvar_Bankmindep = INVALID_HANDLE;
new Handle:cvar_Bankpistolround = INVALID_HANDLE;
new Handle:cvar_Bankidentity = INVALID_HANDLE;
new Handle:cvar_Bankminplayers = INVALID_HANDLE;
new Handle:cvar_Bankdbconfig = INVALID_HANDLE;
new Handle:cvar_Bankmapprefixes = INVALID_HANDLE;
new Handle:cvar_Bankmapmode = INVALID_HANDLE;

new Handle:db = INVALID_HANDLE;

// CVARS
new String:cvplugin_name[128];
new String:cvintereststr[32];
new Float:cvinterestflt;
new cvbankenable;
new cvfeeint;
new cvmaxbankmoney;
new cvbankannounce;
new cvmindepamount;
new cvpistolround;
new cvminrealplayers;

new String:plugin_name[128];
new maxclients;

new bool:IHateFloods[MAXPLAYERS + 1];
new bool:AdminOperation[MAXPLAYERS + 1];
new bool:IsBankMap;

new PlugMes[MAXPLAYERS + 1];
new HideRank[MAXPLAYERS + 1];
new LastMenuAction[MAXPLAYERS + 1];
new AutoDeposit[MAXPLAYERS + 1];
new AutoWithdraw[MAXPLAYERS + 1];
new BankMoney[MAXPLAYERS + 1];
new DBid[MAXPLAYERS + 1];
new TargetClientMenu[MAXPLAYERS + 1];

new g_iAccount = -1;

new bool:DebugMode = false;

// Plugin definitions
public Plugin:myinfo =
{
    name = "CSS Bank",
    author = "Miraculix, SilentWarrior",
    description = "A player can deposit money to the bank, transfer it to other players or withdraw when needed.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?p=1109391"
};

public OnPluginStart()
{
    // ConVars
    cvar_Bankversion = CreateConVar("css_bank_version", PLUGIN_VERSION, "CSS Bank Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    cvar_Bankenable = CreateConVar("css_bank_enable","1","Turns Bank On/Off",FCVAR_PLUGIN);
    cvar_Bankmaxbank = CreateConVar("css_bank_maximum","250000","Maximun amount of money players are allowed to have in the bank, 0 to disable",FCVAR_PLUGIN);
    cvar_Bankannounce = CreateConVar("css_bank_announce","1.0","Turns on announcement when a player joins the server, every map or every round:\n0.0 = disabled, 1.0 = every map, 2.0 = every round",FCVAR_PLUGIN, true, 0.0, true, 2.0);
    cvar_Bankdepositfee = CreateConVar("css_bank_deposit_fee","200","Fee, the players must pay for each deposit",FCVAR_PLUGIN);
    cvar_Bankinterest = CreateConVar("css_bank_interest","2.5","% of interest players will get per round",FCVAR_PLUGIN);
    cvar_Bankmindep = CreateConVar("css_bank_min_deposit","1000","Min. deposit amount, 0 to disable",FCVAR_PLUGIN);
    cvar_Bankpistolround = CreateConVar("css_bank_pistolrounds","1","Set the number of pistolrounds the bank is disabled, min. 0",FCVAR_PLUGIN);
    cvar_Bankidentity = CreateConVar("css_bank_identity","CSS Bank","Set the name of your bank",FCVAR_PLUGIN);
    cvar_Bankminplayers = CreateConVar("css_bank_min_players","2","The number of min players to activate bank, min 0",FCVAR_PLUGIN);
    cvar_Bankdbconfig = CreateConVar("css_bank_dbconfig","clientprefs","Set the database configuration listed in databases.cfg");
    cvar_Bankmapprefixes = CreateConVar("css_bank_mapprefixes"," ","List the map prefixes where the bank is enabled or disabled. Related to the css_bank_mapmode Cvar\nSeparate with commas. e.g.: css_bank_mapprefixes \"gg_,fy_,aim_\"");
    cvar_Bankmapmode = CreateConVar("css_bank_mapmode","0","0 = Disable bank during listed map prefixes, 1 = disable bank during NON-listed map prefixes (only listed maps enable bank)");

    // commands to use
    RegConsoleCmd("bank", BankMenu);
    RegConsoleCmd("deposit", Deposit);
    RegConsoleCmd("withdraw", WithDraw);
    RegConsoleCmd("bankstatus", BankStatus);

    RegAdminCmd("bankadmin", BankAdminMenu, ADMFLAG_BAN);

    RegServerCmd("css_bank_reset_all", CommandResetBankAll);
    RegServerCmd("css_bank_reset_money", CommandResetBankMoney);
    RegServerCmd("css_bank_update", CommandUpdateBankDatabase);

    LoadTranslations("cssbank.phrases");

    g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");

    // create config file
    AutoExecConfig(true, "cssbank");

    HookConVarChange(cvar_Bankdbconfig, BankConVarChanged);
    HookEvent("round_start", EventRoundStart);

    // Update the Plugin Version cvar
    SetConVarString(cvar_Bankversion, PLUGIN_VERSION, true, true);

    ConnectToDatabase();
}

public OnMapStart()
{
    maxclients = MaxClients;
    IsBankMap = true;
}

public OnMapEnd()
{
    IsBankMap = true;
}

public OnConfigsExecuted()
{
    cvbankenable = GetConVarInt(cvar_Bankenable);
    cvmaxbankmoney = GetConVarInt(cvar_Bankmaxbank);
    GetConVarString(cvar_Bankidentity, cvplugin_name, sizeof(cvplugin_name));
    GetConVarString(cvar_Bankinterest, cvintereststr, sizeof(cvintereststr));
    cvfeeint = GetConVarInt(cvar_Bankdepositfee);
    cvinterestflt = GetConVarFloat(cvar_Bankinterest);
    cvbankannounce = GetConVarInt(cvar_Bankannounce);
    cvmindepamount = GetConVarInt(cvar_Bankmindep);
    cvpistolround = GetConVarInt(cvar_Bankpistolround);
    cvminrealplayers = GetConVarInt(cvar_Bankminplayers);

    Format(plugin_name, sizeof(plugin_name), "%c[%s]%c", GREEN, cvplugin_name, YELLOW);

    CheckIsBankMap();
}

public BankConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    ConnectToDatabase();
}

public OnClientPostAdminCheck(client)
{
    NewClientConnected(client);
}

public OnClientAuthorized(client)
{
    if(cvbankannounce > 0)
        IHateFloods[client] = true;
}

// checks player not spectator
IsPlayerInTeam(client)
{
    new Team = GetClientTeam(client);

    if((Team < 2) || (Team > 3))
        return false;

    return true;
}

// checks client
IsValidClient(client)
{
    if(client == 0)
        return false;

    else if(!IsClientConnected(client))
        return false;

    else if(IsFakeClient(client))
        return false;

    else if(!IsClientInGame(client))
        return false;

    return true;
}

public OnClientDisconnect(client)
{
    if(IsClientInGame(client))
        SaveClientInfo(client);
}

// counts real player
GetPlayerCount()
{
    new clients = 0;
    for(new i = 1; i <= maxclients; i++)
    {
        if(IsValidClient(i))
            clients++;
    }
    return clients;
}

ChatMessage(player_to, player_from, const String:text[], const String:name[])
{
    new Handle:hBf = INVALID_HANDLE;

    hBf = StartMessageOne("SayText2", player_to);

    BfWriteByte(hBf, player_from);
    BfWriteByte(hBf, 0);
    BfWriteString(hBf, text);
    BfWriteString(hBf, name);
    EndMessage();
}

bool:IsBankEnable()
{
    if(!cvbankenable)
        return false;

    if(!IsBankMap)
        return false;

    return true;
}

CheckIsBankMap()
{
    new String:cvmapprefixes[128];
    GetConVarString(cvar_Bankmapprefixes, cvmapprefixes, sizeof(cvmapprefixes));

    if(strlen(cvmapprefixes) > 2)
    {
        decl String:curMap[128], String:curMapPre[4];
        GetCurrentMap(curMap, sizeof(curMap));
        new cvbankmode = GetConVarInt(cvar_Bankmapmode);
        Format(curMapPre, sizeof(curMapPre), "%s", curMap);

        if(cvbankmode == 0)
            IsBankMap = StrContains(cvmapprefixes, curMapPre, false) < 0 ? true : false;
        else if(cvbankmode == 1)
            IsBankMap = StrContains(cvmapprefixes, curMapPre, false) < 0 ? false : true;
    }
    else
        IsBankMap = true;
}

bool:IsBankOn(client)
{
    new actrealplayers;
    actrealplayers = GetPlayerCount();

    if(!IsBankEnable())
        return false;

    else if(!IsPlayerInTeam(client))
        return false;

    else if(actrealplayers < cvminrealplayers)
        return false;

    else if(IsPistolRound())
        return false;

    return true;
}

bool:IsBankOnMsg(client)
{
    new actrealplayers;
    actrealplayers = GetPlayerCount();

    if(!IsBankEnable())
        return false;

    else if(!IsPlayerInTeam(client))
        return false;

    else if(actrealplayers < cvminrealplayers)
    {
        decl String:minplayers[8], String:minplayersstr[8], String:actualplayers[8];

        IntToString(cvminrealplayers, minplayers, sizeof(minplayers));
        IntToString(actrealplayers, actualplayers, sizeof(actualplayers));

        Format(minplayersstr, sizeof(minplayersstr), "%c%s%c", GREEN, minplayers, YELLOW);
        PrintToChat(client, "%t", "Not enough Players", plugin_name, actualplayers, minplayersstr, minplayers);
        return false;
    }
    else if(IsPistolRound())
    {
        if(cvpistolround == 1)
            PrintToChat(client, "%t", "PistolRoundBlocked", plugin_name);
        else
            PrintToChat(client, "%t", "PistolRoundsBlocked", plugin_name);

        return false;
    }
    return true;
}

bool:IsPistolRound()
{
    if((cvpistolround == 0) || (cvpistolround <= (GetTeamScore(2) + GetTeamScore(3))))
        return false;

    return true;
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(!IsBankEnable())
        return;

    new bankmoney, ingamemoney, autodeposit, autowithdraw;
    new String:MoneyGain[32], String:Money[32];
    new j, PluginMes;
    for(new i = 1; i <= maxclients ; i++)
    {
        j = i;

        if(!IsValidClient(j)) continue;

        PluginMes = GetPlugMes(j);

        if(IHateFloods[j] && (PluginMes == 1))
        {
            PrintToChat(j, "%t", "Available commands", plugin_name, GREEN, YELLOW, GREEN);
            if(cvbankannounce < 2)
                IHateFloods[j] = false;
        }

        if(!IsBankOn(j)) continue;
        // No Spectators...
        if(!IsPlayerInTeam(j)) continue;

        bankmoney = GetBankMoney(j);
        bankmoney += RoundFloat(FloatMul( float(bankmoney) , cvinterestflt / 100.0 ));

        if((cvmaxbankmoney > 0) && (bankmoney > cvmaxbankmoney))
            bankmoney = cvmaxbankmoney;

        if(bankmoney != GetBankMoney(j))
        {
            IntToMoney(bankmoney - GetBankMoney(j), MoneyGain, sizeof(MoneyGain));
            Format(Money, sizeof(Money), "%c%s%c", GREEN, MoneyGain, YELLOW);
            SetBankMoney(j, bankmoney);

            if(PluginMes == 1)
                PrintToChat(j, "%t", "Interested gained", plugin_name, Money);
        }

        ingamemoney = GetIngameMoney(j);
        autodeposit = GetAutoDeposit(j);
        autowithdraw = GetAutoWithdraw(j);

        new String:buffer[32];
        if((autodeposit != 0) && (ingamemoney > autodeposit))
        {
            new autodep;
            autodep = ingamemoney - autodeposit - cvfeeint;
            if(autodep > cvmindepamount)
            {
                IntToString(autodep, buffer, sizeof(buffer));
                DepositClientMoney(j, buffer);
            }
        }
        else if((autowithdraw != 0) && (ingamemoney < autowithdraw))
        {
            new autowith;
            autowith = autowithdraw - ingamemoney;
            IntToString(autowith, buffer, sizeof(buffer));
            WithdrawClientMoney(j, buffer);
        }
    }
}

/*################################################################
##                                                                ##
##                            Money                                ##
##                                                                ##
################################################################*/

DepositClientMoney(client, String:amount[])
{
    if(!IsBankOnMsg(client))
        return;

    new bankmoney = GetBankMoney(client);

    if((cvmaxbankmoney > 0) && (bankmoney == cvmaxbankmoney))
    {
        PrintToChat(client, "%t", "Bank Still Full", plugin_name);
        return;
    }

    new deposit = StringToInt(amount);
    new ingamemoney = GetIngameMoney(client);
    new deduction = deposit + cvfeeint;
    new mindeduction = cvmindepamount + cvfeeint;

    if(ingamemoney == 0)
    {
        PrintToChat(client, "%t", "No Money", plugin_name);
        return;
    }

    if(deduction < mindeduction)
    {
        deposit = mindeduction - cvfeeint;
        deduction = mindeduction;

        new String:Money[32], String:MoneyGain[32];
        IntToMoney(cvmindepamount, MoneyGain, sizeof(MoneyGain));
        Format(Money, sizeof(Money), "%c%s%c", GREEN, MoneyGain, YELLOW);
        PrintToChat(client, "%t", "Min Depamount", plugin_name, Money);
    }

    if(deduction > ingamemoney)
    {
        deposit = ingamemoney - cvfeeint;
        deduction = ingamemoney;
    }

    if(deposit == 0)
    {
        PrintToChat(client, "%t", "Not Enough Money", plugin_name);
        return;
    }

    if(deduction < mindeduction)
    {
        new String:Money[32], String:MoneyGain[32];
        IntToMoney(mindeduction, MoneyGain, sizeof(MoneyGain));
        Format(Money, sizeof(Money), "%c%s%c", GREEN, MoneyGain, YELLOW);
        PrintToChat(client, "%t", "Need At Least", plugin_name, Money);
        return;
    }

    new newbankmoney = bankmoney + deposit;

    if((cvmaxbankmoney > 0) && (newbankmoney > cvmaxbankmoney))
    {
        new String:Money[32];
        Format(Money, sizeof(Money), "%c%d%c", GREEN, cvmaxbankmoney, YELLOW);
        PrintToChat(client, "%t", "Bank Full", plugin_name, Money);
        deposit = cvmaxbankmoney - bankmoney;
        deduction = deposit + cvfeeint;
        bankmoney = cvmaxbankmoney;
        if(deposit == 0)
            return;
    }
    else
    {
        bankmoney = newbankmoney;
    }

    ingamemoney -= deduction;

    SetBankMoney(client, bankmoney);
    SetIngameMoney(client, ingamemoney);

    new String:feestr[32], String:depositstr[32], String:Money1[32], String:Money2[32];
    IntToMoney(cvfeeint, feestr, sizeof(feestr));
    IntToMoney(deposit, depositstr, sizeof(depositstr));
    Format(Money1, sizeof(Money1), "%c%s%c", GREEN, depositstr, YELLOW);
    Format(Money2, sizeof(Money2), "%c%s%c", GREEN, feestr, YELLOW);
    PrintToChat(client, "%t", "Deposit successfully", plugin_name, Money1, Money2);
}

WithdrawClientMoney(client, String:amount[])
{
    if(!IsBankOnMsg(client))
        return;

    new bankmoney = GetBankMoney(client);
    new ingamemoney = GetIngameMoney(client);
    new withdraw = StringToInt(amount);

    if(ingamemoney == 16000)
    {
        PrintToChat(client, "%t", "No More Money", plugin_name);
        return;
    }

    if(withdraw > bankmoney)
    {
        withdraw = bankmoney;
        if(withdraw == 0)
        {
            PrintToChat(client, "%t", "No Bank Money", plugin_name);
            return;
        }
    }

    new iBalance = ingamemoney + withdraw;
    if(iBalance > 16000)
        withdraw = 16000 - ingamemoney;

    ingamemoney += withdraw;
    bankmoney -= withdraw;

    SetBankMoney(client, bankmoney);
    SetIngameMoney(client, ingamemoney);

    new String:WithStr[32], String:Money[32];
    IntToMoney(withdraw, WithStr, sizeof(WithStr));
    Format(Money, sizeof(Money), "%c%s%c", GREEN, WithStr, YELLOW);
    PrintToChat(client, "%t", "Withdraw successfully", plugin_name, Money);
}

TransferClientMoney(client, target, String:amount[])
{
    if(!IsValidClient(client))
        return;

    if(!IsValidClient(target))
    {
        PrintToChat(client, "%t", "False Target", plugin_name);
        return;
    }

    new deposit, clientbankmoney, targetbankmoney;

    clientbankmoney = GetBankMoney(client);
    targetbankmoney = GetBankMoney(target);

    deposit = StringToInt(amount);

    if(deposit > clientbankmoney)
    {
        PrintToChat(client, "%t", "Not Enough Money", plugin_name);
        return;
    }
    if(deposit == 0)
    {
        PrintToChat(client, "%t", "No Bank Money", plugin_name);
        return;
    }

    new String:clientname[MAX_NAME_LENGTH+1], String:targetname[MAX_NAME_LENGTH+1], String:name[MAX_NAME_LENGTH + 12], String:msg[PLATFORM_MAX_PATH+1];
    new String:depositstr[32], String:depositmon[32];

    GetClientName(client , clientname, sizeof(clientname));
    GetClientName(target , targetname, sizeof(targetname));

    if((cvmaxbankmoney > 0) && (targetbankmoney == cvmaxbankmoney))
    {
        Format(name, sizeof(name), "%c%s%c", TEAMCOLOR, "%s1", YELLOW);
        Format(msg, sizeof(msg), "%T", "TargetTotalLimit", client, plugin_name, name);
        ChatMessage(client, target, msg, targetname);
        return;
    }

    targetbankmoney += deposit;
    clientbankmoney -= deposit;

    if((cvmaxbankmoney > 0) && (targetbankmoney > cvmaxbankmoney))
    {
        new difference = targetbankmoney - cvmaxbankmoney;
        targetbankmoney = cvmaxbankmoney;
        clientbankmoney += difference;
    }

    IntToMoney(GetBankMoney(client) - clientbankmoney ,depositstr, sizeof(depositstr));

    SetBankMoney(client, clientbankmoney);
    SetBankMoney(target, targetbankmoney);

    Format(depositmon, sizeof(depositmon), "%c%s%c", GREEN, depositstr, YELLOW);
    Format(name, sizeof(name), "%c%s%c", TEAMCOLOR, "%s1", YELLOW);
    Format(msg, sizeof(msg), "%T", "TargetDeposited", target, plugin_name, name, depositmon);
    ChatMessage(target, client, msg, clientname);
    Format(msg, sizeof(msg), "%T", "ClientTargetDeposited", client, plugin_name, name, depositmon);
    ChatMessage(client, target, msg, targetname);
}

AdminClientMoney(client, target, String:amount[], add = false, remove = false)
{
    if(!IsValidClient(client))
        return;

    if(!IsValidClient(target))
    {
        PrintToChat(client, "%t", "False Target", plugin_name);
        return;
    }

    new money = StringToInt(amount);
    new bankmoney = GetBankMoney(target);

    new String:clientname[MAX_NAME_LENGTH+1], String:targetname[MAX_NAME_LENGTH+1], String:name[MAX_NAME_LENGTH + 12], String:msg[PLATFORM_MAX_PATH+1], String:NewMoney[32], String:NewMoneyStr[32];

    GetClientName(client , clientname, sizeof(clientname));
    GetClientName(target , targetname, sizeof(targetname));

    Format(name, sizeof(name), "%c%s%c", TEAMCOLOR, "%s1", YELLOW);

    if(add)
    {
        if((cvmaxbankmoney > 0) && ((bankmoney + money) > cvmaxbankmoney))
            money = cvmaxbankmoney - bankmoney;
        bankmoney += money;

        IntToMoney(money, NewMoney, sizeof(NewMoney));
        Format(NewMoneyStr, sizeof(NewMoneyStr), "%c%s%c", GREEN, NewMoney, YELLOW);
        Format(msg, sizeof(msg), "%T", "AdminAdd", target, plugin_name, name, NewMoneyStr);
        ChatMessage(target, client, msg, clientname);
        Format(msg, sizeof(msg), "%T", "AdminTargetAdd", client, plugin_name, name, NewMoneyStr);
        ChatMessage(client, target, msg, targetname);
    }
    else if(remove)
    {
        if(bankmoney < money)
            money = bankmoney;
        bankmoney -= money;

        IntToMoney(money, NewMoney, sizeof(NewMoney));
        Format(NewMoneyStr, sizeof(NewMoneyStr), "%c%s%c", GREEN, NewMoney, YELLOW);
        Format(msg, sizeof(msg), "%T", "AdminRemove", target, plugin_name, name, NewMoneyStr);
        ChatMessage(target, client, msg, clientname);
        Format(msg, sizeof(msg), "%T", "AdminTargetRemove", client, plugin_name, name, NewMoneyStr);
        ChatMessage(client, target, msg, targetname);
    }
    else
    {
        if(cvmaxbankmoney != 0)
        {
            if(money > cvmaxbankmoney)
                money = cvmaxbankmoney;
        }
        bankmoney = money;

        IntToMoney(money, NewMoney, sizeof(NewMoney));
        Format(NewMoneyStr, sizeof(NewMoneyStr), "%c%s%c", GREEN, NewMoney, YELLOW);
        Format(msg, sizeof(msg), "%T", "AdminSet", target, plugin_name, name, NewMoneyStr);
        ChatMessage(target, client, msg, clientname);
        Format(msg, sizeof(msg), "%T", "AdminTargetSet", client, plugin_name, name, NewMoneyStr);
        ChatMessage(client, target, msg, targetname);
    }

    SetBankMoney(TargetClientMenu[client], bankmoney);
}

// returns a money amount from an integer eg: 5300 -> $5,300
IntToMoney(theint, String:result[], maxlen)
{
    new slen, pointer, bool:negative;
    new String:intstr[maxlen];

    negative = theint < 0;
    if(negative) theint *= -1;

    IntToString(theint, intstr, maxlen);
    slen = strlen(intstr);

    theint = slen % 3;
    if(theint == 0) theint = 3;
    Format(result,theint + 1, "%s", intstr);

    slen -= theint;
    pointer = theint + 1;
    for(new i = theint; i <= slen ; i += 3)
    {
        pointer += 4;
        Format(result, pointer, "%s,%s",result, intstr[i]);
    }

    if(negative)
        Format(result, maxlen, "$-%s", result);
    else
        Format(result, maxlen, "$%s", result);
}

/*################################################################
##                                                                ##
##                            Menu                                ##
##                                                                ##
################################################################*/

public BankMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        LastMenuAction[client] = param2;

        switch(param2)
        {
            case 0:
            {
                new igmoney = GetIngameMoney(client);
                new minded = cvmindepamount + cvfeeint;
                if((igmoney < minded) || (igmoney == 0))
                {
                    new String:money[32], String:moneystr[32];
                    IntToMoney(minded, money, sizeof(money));
                    Format(moneystr, sizeof(moneystr), "%c%s%c", GREEN, money, YELLOW);
                    PrintToChat(client, "%t", "Need At Least", plugin_name, moneystr);
                    return;
                }
                else
                {
                    ShowDepositMenu(client);
                }
            }
            case 1:
            {
                if(GetBankMoney(client) == 0)
                {
                    PrintToChat(client, "%t", "No Bank Money", plugin_name);
                    return;
                }
                else
                {
                    ShowWithdrawMenu(client);
                }
            }
            case 2:
            {
                ShowPlayerMenu(client);
            }
            case 3:
            {
                ShowSettingsMenu(client);
            }
            case 4:
            {
                GetTop10(client);
            }
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public PlayerMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        TargetClientMenu[client] = StringToInt(info);

        if(!IsValidClient(TargetClientMenu[client]))
        {
            PrintToChat(client, "%t", "False Target", plugin_name);
            CloseHandle(menu);
            return;
        }

        GetClientName(TargetClientMenu[client], info, sizeof(info));

        new Handle:menu2 = CreateMenu(AmountMenuHandler);
        SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, info);
        BuildAmountMenu(Handle:menu2, client);
        SetMenuExitBackButton(menu2, true);
        DisplayMenu(menu2, client, 20);
    }
    else if(action == MenuAction_Cancel)
    {
        if(param2 == -6)
        {
            if(AdminOperation[client])
                ShowBankAdminMenu(client);
            else
                ShowBankMenu(client);
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public AmountMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        switch(LastMenuAction[client])
        {
            case 0:
            {
                DepositClientMoney(client, info);
            }
            case 1:
            {
                WithdrawClientMoney(client, info);
            }
            case 2:
            {
                TransferClientMoney(client, TargetClientMenu[client], info);
            }
            case 10:
            {
                new amount = StringToInt(info);
                SetAutoDeposit(client, amount);
            }
            case 11:
            {
                new amount = StringToInt(info);
                SetAutoWithdraw(client, amount);
            }
            case 100:
            {
                AdminClientMoney(client, TargetClientMenu[client], info, true);
            }
            case 101:
            {
                AdminClientMoney(client, TargetClientMenu[client], info, _, true);
            }
            case 102:
            {
                AdminClientMoney(client, TargetClientMenu[client], info);
            }
        }
    }
    else if(action == MenuAction_Cancel)
    {
        if(param2 == -6)
            switch(LastMenuAction[client])
            {
                case 0,1,10,11:
                {
                    ShowBankMenu(client);
                }
                case 2,100,101,102:
                {
                    ShowPlayerMenu(client);
                }
            }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public BuildAmountMenu(Handle:menu2, client)
{
    decl String:dummy[32], String:money[PLATFORM_MAX_PATH+1];
    new String:amounts[32][32];
    new menumoney;

    if(LastMenuAction[client] == 102)
    {
        Format(money, sizeof(money), "%T", "Admin Setmoney Amounts", LANG_SERVER);
        new count = ExplodeString(money, ",", amounts, 32, 32);
        for(new i = 0; i < count; i++)
        {
            menumoney = StringToInt(amounts[i]);
            IntToMoney(menumoney, dummy , sizeof(dummy));
            AddMenuItem(menu2, amounts[i], dummy);
        }
    }
    else
    {
        Format(money, sizeof(money), "%T", "Amount Menu Amounts", LANG_SERVER);
        new count = ExplodeString(money, ",", amounts, 32, 32);
        for(new i = 0; i < count; i++)
        {
            menumoney = StringToInt(amounts[i]);
            IntToMoney(menumoney, dummy , sizeof(dummy));
            AddMenuItem(menu2, amounts[i], dummy);
        }
    }
}

public BankSettingsMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        LastMenuAction[client] = param2 + 10;

        switch(param2)
        {
            case 0,1:
            {
                new Handle:menu2 = CreateMenu(AmountMenuHandler);
                decl String:buffer[PLATFORM_MAX_PATH+1];
                switch(param2)
                {
                    case 0:
                    {
                        Format(buffer, sizeof(buffer), "%T", "Bank Menu AutoDeposit", client);
                        SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, buffer);
                    }
                    case 1:
                    {
                        Format(buffer, sizeof(buffer), "%T", "Bank Menu AutoWithdraw", client);
                        SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, buffer);
                    }
                }
                AddMenuItem(menu2, "0", "Off");
                BuildAmountMenu(Handle:menu2, client);
                SetMenuExitBackButton(menu2, true);
                DisplayMenu(menu2, client, 20);
            }
            case 2:
            {
                if(GetHideRank(client) == 0)
                    SetHideRank(client, 1);
                else
                    SetHideRank(client, 0);

                ShowSettingsMenu(client);
            }
            case 3:
            {
                if(GetPlugMes(client) == 0)
                    SetPlugMes(client, 1);
                else
                    SetPlugMes(client, 0);

                ShowSettingsMenu(client);
            }
            case 4:
            {
                new Handle:menu2 = CreateMenu(SecurityMenuHandler);
                decl String:buffer[PLATFORM_MAX_PATH+1];
                Format(buffer, sizeof(buffer), "%T", "Bank Menu Reset", client);
                SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, buffer);
                AddMenuItem(menu2, "0", "Yes");
                AddMenuItem(menu2, "1", "No");
                DisplayMenu(menu2, client, 20);
            }
        }
    }
    else if(action == MenuAction_Cancel)
    {
        if(param2 == -6)
        {
            ShowBankMenu(client);
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public SecurityMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        switch(param2)
        {
            case 0:
            {
                BankMoney[client] = 0;
                SaveClientInfo(client);
                PrintToChat(client, "%t", "BankResetSuccessfully", plugin_name);
            }
            case 1:
            {
                ShowSettingsMenu(client);
            }
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

public Top10PanelHandler(Handle:panel, MenuAction:action, client, param2){}

public BankAdminMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
    if(action == MenuAction_Select)
    {
        new String:info[32];
        new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
        if(!found)
            return;

        LastMenuAction[client] = param2 + 100;

        switch(param2)
        {
            case 0,1,2:
            {
                ShowPlayerMenu(client);
            }
        }
    }
    else if(action == MenuAction_End)
    {
        CloseHandle(menu);
    }
}

/*################################################################
##                                                                ##
##                            Shows                                ##
##                                                                ##
################################################################*/

ShowBankMenu(client)
{
    decl String:balance[64], String:fee[64], String:intstr[64], String:autodepo[64], String:autowithdr[64];
    decl String:Title[1024], String:TitleInfo[1024];

    IntToMoney(GetBankMoney(client), balance, sizeof(balance));
    IntToMoney(GetAutoDeposit(client), autodepo, sizeof(autodepo));
    IntToMoney(GetAutoWithdraw(client), autowithdr, sizeof(autowithdr));
    IntToMoney(cvfeeint, fee, sizeof(fee));
    Format(intstr, sizeof(intstr), "%s%c%c", cvintereststr, 0x25, 0x25);

    Format(TitleInfo, sizeof(TitleInfo), "%T", "Bank Menu Info", client, balance, intstr, fee, autodepo, autowithdr);
    Format(Title, sizeof(Title), "%s\n \n%s\n \n", cvplugin_name, TitleInfo);

    new Handle:menu = CreateMenu(BankMenuHandler);
    SetMenuTitle(menu, Title);

    new style:item;
    if (!IsBankOn(client))
        item = style:ITEMDRAW_DISABLED;
    else
        item = style:ITEMDRAW_DEFAULT;

    decl String:buffer[PLATFORM_MAX_PATH+1];

    Format(buffer, sizeof(buffer), "%T", "Bank Menu Deposit", client);
    AddMenuItem(menu, "deposit", buffer, item);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Withdraw", client);
    AddMenuItem(menu, "withdraw", buffer, item);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Transfer", client);
    AddMenuItem(menu, "transfer", buffer, item);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Settings", client);
    AddMenuItem(menu, "settings", buffer);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Top10", client);
    AddMenuItem(menu, "top10", buffer);

    DisplayMenu(menu, client, 20);
}

ShowDepositMenu(client)
{
    decl String:buffer[PLATFORM_MAX_PATH+1];
    LastMenuAction[client] = 0;
    new Handle:menu2 = CreateMenu(AmountMenuHandler);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Deposit", client);
    SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, buffer);
    BuildAmountMenu(Handle:menu2, client);
    SetMenuExitBackButton(menu2, true);
    DisplayMenu(menu2, client, 20);
}

ShowWithdrawMenu(client)
{
    decl String:buffer[PLATFORM_MAX_PATH+1];
    LastMenuAction[client] = 1;
    new Handle:menu2 = CreateMenu(AmountMenuHandler);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Withdraw", client);
    SetMenuTitle(menu2, "%s\n \n%s:", cvplugin_name, buffer);
    BuildAmountMenu(Handle:menu2, client);
    SetMenuExitBackButton(menu2, true);
    DisplayMenu(menu2, client, 20);
}

ShowPlayerMenu(client)
{
    new Handle:menu = CreateMenu(PlayerMenuHandler);
    new String:name[MAX_NAME_LENGTH+1], String:id[32], String:buffer[PLATFORM_MAX_PATH+1];

    Format(buffer, sizeof(buffer), "%T", "Choose Player", client);
    SetMenuTitle(menu, "%s\n \n%s:", cvplugin_name, buffer);

    if(LastMenuAction[client] >= 100)
    {
        GetClientName(client, name, sizeof(name));
        IntToString(client, id, sizeof(id));
        AddMenuItem(menu, id, name);
    }
    if(GetPlayerCount() > 1)
    {
        new j;
        for(new i = 1; i <= maxclients; i++)
        {
            j = i;
            if(!IsValidClient(j)) continue;
            if(client == j) continue;

            GetClientName(j, name, sizeof(name));
            IntToString(j, id, sizeof(id));
            AddMenuItem(menu, id, name);
        }
    }
    else if(LastMenuAction[client] >= 100)
    {
        PrintToChat(client, "%t", "No Other Player", plugin_name);
    }
    else
    {
        PrintToChat(client, "%t", "No Other Player", plugin_name);
        CloseHandle(menu);
        return;
    }

    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, 20);
}

ShowSettingsMenu(client)
{
    decl String:buffer[PLATFORM_MAX_PATH+1];

    new Handle:menu = CreateMenu(BankSettingsMenuHandler);

    Format(buffer, sizeof(buffer), "%T", "Bank Menu Settings", client);
    SetMenuTitle(menu, "%s\n \n%s:", cvplugin_name, buffer);

    Format(buffer, sizeof(buffer), "%T", "Bank Menu AutoDeposit", client);
    AddMenuItem(menu, "autodep", buffer);
    Format(buffer, sizeof(buffer), "%T", "Bank Menu AutoWithdraw", client);
    AddMenuItem(menu, "autowith", buffer);
    if(GetHideRank(client) == 0)
    {
        Format(buffer, sizeof(buffer), "%T", "Bank Menu HideRank", client);
        AddMenuItem(menu, "hiderank", buffer);
    }
    else
    {
        Format(buffer, sizeof(buffer), "%T", "Bank Menu ShowRank", client);
        AddMenuItem(menu, "showrank", buffer);
    }
    if(GetPlugMes(client) == 0)
    {
        Format(buffer, sizeof(buffer), "%T", "Bank Menu MessagesOn", client);
        AddMenuItem(menu, "messages", buffer);
    }
    else
    {
        Format(buffer, sizeof(buffer), "%T", "Bank Menu MessagesOff", client);
        AddMenuItem(menu, "messages", buffer);
    }
    Format(buffer, sizeof(buffer), "%T", "Bank Menu Reset", client);
    AddMenuItem(menu, "reset", buffer);

    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, 20);
}

ShowBankStatus(client)
{
    decl String:money[32], String:moneystr[32];
    new bankmoney;
    bankmoney = GetBankMoney(client);
    IntToMoney( bankmoney , money, sizeof(money));
    Format(moneystr, sizeof(moneystr), "%c%s%c", GREEN, money, YELLOW);
    PrintToChat(client, "%t", "Bankstatus", plugin_name, moneystr);
}

ShowBankAdminMenu(client)
{
    decl String:buffer[PLATFORM_MAX_PATH+1];

    new Handle:menu = CreateMenu(BankAdminMenuHandler);

    Format(buffer, sizeof(buffer), "%T", "Admin Menu Title", client);
    SetMenuTitle(menu, "%s\n \n%s:", cvplugin_name, buffer);

    Format(buffer, sizeof(buffer), "%T", "Admin Menu Add", client);
    AddMenuItem(menu, "add", buffer);
    Format(buffer, sizeof(buffer), "%T", "Admin Menu Remove", client);
    AddMenuItem(menu, "remove", buffer);
    Format(buffer, sizeof(buffer), "%T", "Admin Menu Setmoney", client);
    AddMenuItem(menu, "setmoney", buffer);

    DisplayMenu(menu, client, 20);
}

/*################################################################
##                                                                ##
##                    Console/Admin/Server CMDs                    ##
##                                                                ##
################################################################*/

public Action:BankMenu(client, args)
{
    if(IsBankEnable())
    {
        IsBankOnMsg(client);
        ShowBankMenu(client);
        AdminOperation[client] = false;
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public Action:Deposit(client, args)
{
    if(IsBankOnMsg(client))
    {
        new igmoney = GetIngameMoney(client);
        new minded = cvmindepamount + cvfeeint;
        if((igmoney < minded) || (igmoney == 0))
        {
            decl String:money[32], String:moneystr[32];
            IntToMoney(minded, money, sizeof(money));
            Format(moneystr, sizeof(moneystr), "%c%s%c", GREEN, money, YELLOW);
            PrintToChat(client, "%t", "Need At Least", plugin_name, moneystr);
            return Plugin_Handled;
        }
        else
        {
            if(args < 1)
            {
                ShowDepositMenu(client);
                AdminOperation[client] = false;
                return Plugin_Handled;
            }
            else
            {
                new String:CmdArg[32], String:Amount[32];
                GetCmdArg(1, CmdArg, sizeof(CmdArg));
                if(StrEqual(CmdArg, "all"))
                {
                    IntToString(igmoney,Amount,sizeof(Amount));
                    DepositClientMoney(client, Amount);
                }
                else
                {
                    DepositClientMoney(client, CmdArg);
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action:WithDraw(client, args)
{
    if(IsBankOnMsg(client))
    {
        if (GetBankMoney(client) == 0)
        {
            PrintToChat(client, "%t", "No Bank Money", plugin_name);
            return Plugin_Handled;
        }
        else
        {
            if(args < 1)
            {
                ShowWithdrawMenu(client);
                AdminOperation[client] = false;
                return Plugin_Handled;
                }
            else
            {
                new String:CmdArg[32], String:Amount[32];
                GetCmdArg(1, CmdArg, sizeof(CmdArg));
                if(StrEqual(CmdArg, "all"))
                {
                    IntToString(16000,Amount,sizeof(Amount));
                    WithdrawClientMoney(client, Amount);
                }
                else
                {
                    WithdrawClientMoney(client, CmdArg);
                }
            }
        }
    }
    return Plugin_Handled;
}

public Action:BankStatus(client, args)
{
    if(IsBankEnable())
    {
        ShowBankStatus(client);
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public Action:BankAdminMenu(client, args)
{
    if(IsBankEnable())
    {
        ShowBankAdminMenu(client);
        AdminOperation[client] = true;
        return Plugin_Handled;
    }
    return Plugin_Handled;
}

public Action:CommandResetBankAll(args)
{
    ResetBankAll();
    return Plugin_Handled;
}

public Action:CommandResetBankMoney(args)
{
    ResetBankMoney();
    return Plugin_Handled;
}

public Action:CommandUpdateBankDatabase(args)
{
    UpdateBankDatabase();
    return Plugin_Handled;
}

/*################################################################
##                                                                ##
##                        Setter/Getter                            ##
##                                                                ##
################################################################*/

SetIngameMoney(client, amount)
{
    if(amount > 16000)
        amount = 16000;
    if(amount < 0)
        amount = 0;
    SetEntData(client, g_iAccount, amount, 4, true);
}

GetIngameMoney(client)
{
    return GetEntData(client, g_iAccount, 4);
}

SetBankMoney(client, amount)
{
    if((cvmaxbankmoney > 0) && (amount > cvmaxbankmoney))
        amount = cvmaxbankmoney;
    if(amount < 0)
        amount = 0;
    BankMoney[client] = amount;
    SaveClientInfo(client);
}

GetBankMoney(client)
{
    return BankMoney[client];
}

SetAutoDeposit(client, amount)
{
    AutoDeposit[client] = amount;
    SaveClientInfo(client);
}

GetAutoDeposit(client)
{
    return AutoDeposit[client];
}

SetAutoWithdraw(client, amount)
{
    AutoWithdraw[client] = amount;
    SaveClientInfo(client);
}

GetAutoWithdraw(client)
{
    return AutoWithdraw[client];
}

SetHideRank(client, value)
{
    HideRank[client] = value;
    SaveClientInfo(client);
}

GetHideRank(client)
{
    return HideRank[client];
}

SetPlugMes(client, value)
{
    PlugMes[client] = value;
    SaveClientInfo(client);
}

GetPlugMes(client)
{
    return PlugMes[client];
}

/*################################################################
##                                                                ##
##                            Database                            ##
##                                                                ##
################################################################*/

ConnectToDatabase()
{
    if(db != INVALID_HANDLE)
    {
        LogMessage("[%s] Disconnecting DB connection", cvplugin_name);
        CloseHandle(db);
        db = INVALID_HANDLE;
    }

    new String:dbname[PLATFORM_MAX_PATH+1];
    GetConVarString(cvar_Bankdbconfig, dbname, sizeof(dbname));

    if(!SQL_CheckConfig( dbname ))
    {
        LogError("[%s] DB configuration '%s' does not exist, using default.", cvplugin_name, dbname );
        dbname = "clientprefs";
    }
    SQL_TConnect(OnSqlConnect, dbname);
}

public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if(hndl == INVALID_HANDLE)
    {
        LogError("[%s] Database failure: %s", cvplugin_name, error);
    }
    else
    {
        db = hndl;
        new String:buffer[1024];

        SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
        new ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;

        if(ismysql == 1)
            Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `css_bank` (`id` int(64) NOT NULL auto_increment, `steam_id` varchar(32) NOT NULL, `amount` int(64) NOT NULL, `auto_deposit` int(5) NOT NULL, `auto_withdraw` int(5) NOT NULL, `plugin_message` int(1) NOT NULL, `player_name` varchar(128) NOT NULL, `hide_rank` int(1) NOT NULL, PRIMARY KEY  (`id`), UNIQUE KEY `steam_id` (`steam_id`))");
        else
            Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS css_bank(id INTEGER PRIMARY KEY AUTOINCREMENT, steam_id TEXT UNIQUE, amount INTEGER, auto_deposit INTEGER, auto_withdraw INTEGER, plugin_message INTEGER, player_name TEXT, hide_rank INTEGER);");

        LogMessage("[%s] Connecting to DB", cvplugin_name);

        if(DebugMode)
            LogMessage("[%s]: %s", cvplugin_name, buffer);

        if (!SQL_FastQuery(db, buffer))
        {
            new String:error2[255];
            SQL_GetError(db, error2, sizeof(error2));
            LogError("[%s] Query failure: %s", cvplugin_name, error2);
            LogError("[%s] Query: %s", cvplugin_name, buffer);
        }
    }
}

public NewClientConnected(client)
{
    DBid[client] = -1;
    PlugMes[client] = 1;
    HideRank[client] = 0;
    AutoDeposit[client] = 0;
    AutoWithdraw[client] = 0;
    BankMoney[client] = 0;

    new String:AuthStr[32], String:Name[MAX_NAME_LENGTH+1];

    if(IsFakeClient(client))
        return;

    if(!GetClientAuthString(client, AuthStr, sizeof(AuthStr)))
    {
        if(!GetClientName( client, Name, sizeof(Name)))
            Format(Name, sizeof(Name), "Client(%d)", client);
        LogMessage("[%s] SteamID not found: %s", cvplugin_name, Name);
        return;
    }

    new String:MysqlQuery[512];

    Format(MysqlQuery, sizeof(MysqlQuery), "SELECT id, amount, auto_deposit, auto_withdraw, plugin_message, hide_rank FROM css_bank WHERE steam_id = '%s';", AuthStr);

    if(DebugMode)
        LogMessage("[%s]: %s", cvplugin_name, MysqlQuery);

    SQL_TQuery(db, T_NewClientConnected, MysqlQuery, GetClientUserId(client));
}

public T_NewClientConnected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client;
    if((client = GetClientOfUserId(data)) == 0)
        return;

    if(hndl == INVALID_HANDLE)
    {
        LogError("[%s] Query failed! %s", cvplugin_name, error);
    }
    else if(!SQL_GetRowCount(hndl))
    {
        new String:AuthStr[32], String:MysqlQuery[512], String:Name[MAX_NAME_LENGTH+1];
        new String:SafeName[(sizeof(Name)*2)+1];
        if(!GetClientAuthString(client, AuthStr, sizeof(AuthStr)))
            return;
        if(!GetClientName( client, Name, sizeof(Name)))
            Format(SafeName, sizeof(SafeName), "<noname>");
        else
        {
            TrimString(Name);
            SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
        }

        Format(MysqlQuery, sizeof(MysqlQuery), "INSERT INTO css_bank(steam_id, plugin_message, player_name, hide_rank) VALUES('%s', %d, '%s', %d);", AuthStr, 1, SafeName, 0);

        if(DebugMode)
            LogMessage("[%s]: %s", cvplugin_name, MysqlQuery);

        if (!SQL_FastQuery(db, MysqlQuery))
        {
            new String:error2[255];
            SQL_GetError(db, error2, sizeof(error2));
            LogError("[%s] Query failure: %s", cvplugin_name, error2);
            LogError("[%s] Query: %s", cvplugin_name, MysqlQuery);
        }

        return;
    }

    if(!SQL_FetchRow(hndl))
        return;

    DBid[client] = SQL_FetchInt( hndl, 0);
    BankMoney[client] = SQL_FetchInt( hndl, 1);
    AutoDeposit[client] = SQL_FetchInt( hndl, 2);
    AutoWithdraw[client] = SQL_FetchInt( hndl, 3);
    PlugMes[client] = SQL_FetchInt( hndl, 4);
    HideRank[client] = SQL_FetchInt( hndl, 5);
    SaveClientInfo(client);
}

SaveClientInfo(client)
{
    new String:MysqlQuery[512], String:Name[MAX_NAME_LENGTH+1];
    new String:SafeName[(sizeof(Name)*2)+1];
    
    if(!GetClientName( client, Name, sizeof(Name)))
        Format(SafeName, sizeof(SafeName), "<noname>");
    else
    {
        TrimString(Name);
        SQL_EscapeString(db, Name, SafeName, sizeof(SafeName));
    }

    if(DBid[client] < 1)
    {
        new String:AuthStr[32];
        if(!GetClientAuthString(client, AuthStr, sizeof(AuthStr)))
            return;

        if(!IsFakeClient(client)){
            Format(MysqlQuery, sizeof(MysqlQuery), "UPDATE css_bank SET amount = %d, auto_deposit = %d, auto_withdraw = %d, plugin_message = %d, player_name = '%s', hide_rank = %d WHERE steam_id = '%s';", BankMoney[client], AutoDeposit[client], AutoWithdraw[client], PlugMes[client], SafeName, HideRank[client], AuthStr);

            if(DebugMode)
                LogMessage("[%s]: %s", cvplugin_name, MysqlQuery);
        }
    }
    else
    {
        if(!IsFakeClient(client)){
            Format(MysqlQuery, sizeof(MysqlQuery), "UPDATE css_bank SET amount = %d, auto_deposit = %d, auto_withdraw = %d, plugin_message = %d, player_name = '%s', hide_rank = %d WHERE id = %d;", BankMoney[client], AutoDeposit[client], AutoWithdraw[client], PlugMes[client], SafeName, HideRank[client], DBid[client]);

            if(DebugMode)
                LogMessage("[%s]: %s", cvplugin_name, MysqlQuery);
        }
    }
    
    if (!SQL_FastQuery(db, MysqlQuery))
    {
        new String:error2[255];
        SQL_GetError(db, error2, sizeof(error2));
        LogError("[%s] Query failure: %s", cvplugin_name, error2);
        LogError("[%s] Query: %s", cvplugin_name, MysqlQuery);
    }
}

public GetTop10(client)
{
    decl String:Query[512];
    Format(Query, sizeof(Query), "SELECT player_name, amount FROM css_bank WHERE amount > 0 AND hide_rank NOT LIKE 1 ORDER BY amount DESC LIMIT 0, 10;");
    SQL_TQuery(db, T_GetTop10, Query, GetClientUserId(client));
}

public T_GetTop10(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    new client;
    if((client = GetClientOfUserId(data)) == 0)
        return;

    if(hndl == INVALID_HANDLE)
    {
        LogError("[%s] Query failed! %s", cvplugin_name, error);
        return;
    }

    new String:title[128], String:title2[128];
    new Handle:panel = CreatePanel();

    Format(title, sizeof(title), "%s\n \n", cvplugin_name);
    SetPanelTitle(panel, title);

    SetPanelKeys(panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9));

    Format(title2, sizeof(title2), "%T", "Top10", client);
    DrawPanelItem( panel, title2);

    new i, String:name[MAX_NAME_LENGTH+1], amount, String:player[128], String:money[32];

    if(SQL_HasResultSet(hndl))
    {
        while(SQL_FetchRow(hndl))
        {
            i++;
            SQL_FetchString(hndl, 0, name, sizeof(name));
            amount = SQL_FetchInt(hndl,1);

            IntToMoney(amount, money, sizeof(money));
            if (i < 10)
                Format(player, sizeof(player), "   %d. %s  -  %s", i, money, name);
            else
                Format(player, sizeof(player), " %d. %s  -  %s", i, money, name);
            DrawPanelText( panel, player);
        }
    }
    else
    {
            DrawPanelText(panel, " ");
    }

    SendPanelToClient(panel, client, Top10PanelHandler, 20);

    CloseHandle(panel);
}

public ResetBankAll()
{
    if(db == INVALID_HANDLE)
    {
        LogError("[%s] Database failure: No connection", cvplugin_name);
        return;
    }

    decl String:buffer[1024];
    Format(buffer, sizeof(buffer), "DROP TABLE css_bank;");

    if (!SQL_FastQuery(db, buffer))
    {
        new String:error[255];
        SQL_GetError(db, error, sizeof(error));
        LogError("[%s] Query failure: %s", cvplugin_name, error);
        LogError("[%s] Query: %s", cvplugin_name, buffer);
    }

    SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
    new ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;

    if(ismysql == 1)
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `css_bank` (`id` int(64) NOT NULL auto_increment, `steam_id` varchar(32) NOT NULL, `amount` int(64) NOT NULL, `auto_deposit` int(5) NOT NULL, `auto_withdraw` int(5) NOT NULL, `plugin_message` int(1) NOT NULL, `player_name` varchar(128) NOT NULL, `hide_rank` int(1) NOT NULL, PRIMARY KEY  (`id`), UNIQUE KEY `steam_id` (`steam_id`))");
    else
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS css_bank(id INTEGER PRIMARY KEY AUTOINCREMENT, steam_id TEXT UNIQUE, amount INTEGER, auto_deposit INTEGER, auto_withdraw INTEGER, plugin_message INTEGER, player_name TEXT, hide_rank INTEGER);");

    if (!SQL_FastQuery(db, buffer))
    {
        new String:error[255];
        SQL_GetError(db, error, sizeof(error));
        LogError("[%s] Query failure: %s", cvplugin_name, error);
        LogError("[%s] Query: %s", cvplugin_name, buffer);
    }
    else
    {
        for(new i = 1; i <= maxclients ; i++)
        {
            if(!IsClientConnected(i)) continue;
            if(IsFakeClient(i)) continue;

            NewClientConnected(i);
        }
    }
}

public ResetBankMoney()
{
    if(db == INVALID_HANDLE)
    {
        LogError("[%s] Database failure: No connection", cvplugin_name);
        return;
    }

    decl String:Query[512];
    Format(Query, sizeof(Query), "UPDATE css_bank SET amount = %d", 0);

    if (!SQL_FastQuery(db, Query))
    {
        new String:error[255];
        SQL_GetError(db, error, sizeof(error));
        LogError("[%s] Query failure: %s", cvplugin_name, error);
        LogError("[%s] Query: %s", cvplugin_name, Query);
    }
    for(new i = 1; i <= maxclients ; i++)
    {
        BankMoney[i] = 0;
    }
}

public UpdateBankDatabase()
{
    if(db == INVALID_HANDLE)
    {
        LogError("[%s] Database failure: No connection", cvplugin_name);
        return;
    }

    decl String:buffer[1024];
    SQL_GetDriverIdent(SQL_ReadDriver(db), buffer, sizeof(buffer));
    new ismysql = StrEqual(buffer,"mysql", false) ? 1 : 0;

    if(ismysql == 1)
        Format(buffer, sizeof(buffer), "ALTER TABLE `css_bank` ADD `hide_rank` int(1) NOT NULL DEFAULT 0");
    else
        Format(buffer, sizeof(buffer), "ALTER TABLE css_bank ADD hide_rank INTEGER DEFAULT 0;");

    if (!SQL_FastQuery(db, buffer))
    {
        new String:error[255];
        SQL_GetError(db, error, sizeof(error));
        LogError("[%s] Query failure: %s", cvplugin_name, error);
        LogError("[%s] Query: %s", cvplugin_name, buffer);
    }
    else
    {
        for(new i = 1; i <= maxclients ; i++)
        {
            if(!IsClientConnected(i)) continue;
            if(IsFakeClient(i)) continue;

            NewClientConnected(i);
        }
        LogMessage("[%s] Update successful to v%s", cvplugin_name, PLUGIN_VERSION);
    }
}