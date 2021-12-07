// #pragma semicolon 1
// #pragma newdecls required;

#include <sourcemod>
#include <sdktools>
#include <store>
#include <clientprefs>
#include <cstrike>
#include <entity_prop_stocks>

ConVar cv_CreditsAdder;
ConVar cv_CreditsTime;
ConVar cv_CreditsTeam = null;
ConVar cv_GiveCredits;

ConVar cv_GiveHP;
Handle h_GiveDeagle = INVALID_HANDLE;
ConVar cv_GiveArmor;
ConVar cv_GiveGoldTag;
ConVar cv_GiveMoney;

ConVar cv_ServerDNS;
ConVar cv_ShowAds;
ConVar cv_ArenaMode;

Handle TimeAuto = null;
Handle GoldTagCookie;

#define PL_VERSION "1.3"        // Don't edit this

public Plugin myinfo = 
{
	name = "GoldMember (DNS Benefits)",
	author = "xSLOW",
	description = "Benefits for having DNS in STEAM Name",
	version = PL_VERSION,
	url = "https://steamcommunity.com/id/imslow2k17/"
};

public void OnPluginStart()
{
    GoldTagCookie = RegClientCookie("GoldTagCookie", "GoldTagCookie", CookieAccess_Protected);
    RegConsoleCmd("sm_goldtag", menutag);

    // credits cvars
    cv_GiveCredits = CreateConVar("sm_goldmember_givecredits", "1", "Give free credits to goldmembers? 1 = Yes, 0 = No", FCVAR_NOTIFY);
    cv_CreditsAdder = CreateConVar("sm_goldmember_credits", "10", "Credits to give per X time, if player has DNS in name. (If you have sm_goldmember_givecredits 1)", FCVAR_NOTIFY);
    cv_CreditsTime = CreateConVar("sm_goldmember_creditstime", "70", "Time in seconds to give the credits. (If you have sm_goldmember_givecredits 1)", FCVAR_NOTIFY);
    cv_CreditsTeam = CreateConVar("sm_goldmember_creditsteam", "1", "Who gets free credits? 0 = ALL PLAYERS and 1 = ONLY CT/T, without spectators (If you have sm_goldmember_givecredits 1)", FCVAR_NOTIFY);

    // other benefits
    cv_GiveHP = CreateConVar("sm_goldmember_givehp", "0", "How much HP does a goldmember should have? 0 = Disabled option", FCVAR_NOTIFY);
    cv_GiveArmor = CreateConVar("sm_goldmember_givearmor", "100", "How much armor does a goldmember should have? 0 = Disabled option", FCVAR_NOTIFY);
    cv_GiveMoney = CreateConVar("sm_goldmember_givemoney", "300", "How mouch money to give to a goldmember in every round? Every round, except first round | 0 = Disabled option", FCVAR_NOTIFY);
    cv_GiveGoldTag = CreateConVar("sm_goldmember_givegoldtag", "1", "Give goldmember permission to use !goldtag?", FCVAR_NOTIFY);
    h_GiveDeagle = CreateConVar("sm_goldmember_givedeagle", "1", "give free deagle? 0 = Disabled option", FCVAR_NOTIFY);

    // other cvars
    cv_ServerDNS = CreateConVar("sm_goldmember_serverdns", "SERVER.DNS.COM", "Server's DNS to get GoldMember", FCVAR_NOTIFY);
    cv_ShowAds = CreateConVar("sm_goldmember_showads", "90.0", "Show messages about goldmember? If yes, enter a float value of how often should these ads be shown, either enter 0.0 to disable this option", FCVAR_NOTIFY);
    cv_ArenaMode = CreateConVar("sm_goldmember_arenamode", "0", "If you're using Multi 1vs1 (arena server) enable this to get goldtag every round. 1 = Enabled, 0 = Disabled", FCVAR_NOTIFY);

    if(cv_ShowAds.FloatValue > 0.0)
        CreateTimer(cv_ShowAds.FloatValue, Timer_Ads, _, TIMER_REPEAT);

    HookConVarChange(cv_CreditsTime, Change_CreditsTime);

    HookEvent("player_spawn", Event_OnPlayerSpawn);
    HookEvent("round_start", OnRoundStart);

    AutoExecConfig(true, "goldmember");
}

public Action Timer_Ads(Handle timer, any client)
{
    char DNSbuffer[32];
    cv_ServerDNS.GetString(DNSbuffer, sizeof(DNSbuffer));

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientValid(i) && !HasDNS(i))
        {
            PrintToChat(i, " ✪︎ \x01Add \x07'%s' \x01to your NAME to get \x10GoldMember♛ \x04(FREE ARMOR & CREDITS & !GOLDTAG)", DNSbuffer);
        }
    }
}

public void OnMapStart()
{
	TimeAuto = CreateTimer(cv_CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}


public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    char DNSbuffer[32];
    cv_ServerDNS.GetString(DNSbuffer, sizeof(DNSbuffer));
	
    if(IsClientValid(client) && cv_GiveArmor.IntValue > 0 && HasDNS(client) == true)
    {
        GivePlayerItem(client, "item_kevlar");
        GivePlayerItem(client, "item_assaultsuit");
        SetEntProp(client, Prop_Send, "m_ArmorValue", cv_GiveArmor.IntValue);
        SetEntProp(client, Prop_Send, "m_bHasHelmet", true);
        if(GetConVarBool(h_GiveDeagle))
        {
        	RemovePlayerItem(client, GetPlayerWeaponSlot(client, 1));
        	GivePlayerItem(client, "weapon_deagle");
       	}
    }

    if(IsClientValid(client) && cv_GiveHP.IntValue > 0 && HasDNS(client) == true)
    {
        SetEntityHealth(client, cv_GiveHP.IntValue);
    }
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    if(cv_GiveGoldTag.IntValue == 1 && cv_ArenaMode.IntValue == 1)
        CreateTimer(3.0, Timer_ArenaSetGoldTag);

    for(int iClient = 1; iClient <= MaxClients ; iClient++)
    {
        int RoundCount = CS_GetTeamScore(2) + CS_GetTeamScore(3);
        //PrintToChat(iClient, "round %d", RoundCount);
        if(GameRules_GetProp("m_bWarmupPeriod") != 1 && RoundCount != 0 && IsClientValid(iClient) && cv_GiveMoney.IntValue > 0 && HasDNS(iClient) == true)
        {
            int iClientMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
            //PrintToChat(iClient, "money: %d", iClientMoney);
            if(iClientMoney + cv_GiveMoney.IntValue > 16000)
            {
                SetEntProp(iClient, Prop_Send, "m_iAccount", 16000);
                //PrintToChat(iClient, "you've got 16k, gg");
            }
            else
            {
                SetEntProp(iClient, Prop_Send, "m_iAccount", iClientMoney + cv_GiveMoney.IntValue);
                //PrintToChat(iClient, "you've got %d", iClientMoney+cv_GiveMoney.IntValue);
            }
        }
    }
}

public void OnClientPostAdminCheck(int client)
{
    if(cv_GiveGoldTag.IntValue == 1 && cv_ArenaMode.IntValue == 0)
        CreateTimer(5.0, Timer_SetGoldTag);
}

public Action Timer_ArenaSetGoldTag(Handle timer)
{
    if(cv_GiveGoldTag.IntValue == 1)
        SetGoldTag();
}

public Action Timer_SetGoldTag(Handle timer)
{
    if(cv_GiveGoldTag.IntValue == 1)
        SetGoldTag();
}


public void SetGoldTag()
{
    for(int iClient = 1; iClient <= MaxClients ; iClient++)
    {
        if(IsClientValid(iClient) && HasDNS(iClient) == true)
        {
            char sBuffer[12];
            GetClientCookie(iClient,GoldTagCookie,sBuffer,sizeof(sBuffer));
            int choosed = StringToInt(sBuffer);
            if (IsClientInGame(iClient)&&(IsClientValid(iClient)))
            {
                if(choosed == 1)
                {
                    CS_SetClientClanTag(iClient, "GoldMember♛");    
                }
                else
                if(choosed == 2)
                {
                    CS_SetClientClanTag(iClient, "GoldMember®");
                }
                else
                if(choosed == 3)
                {
                    CS_SetClientClanTag(iClient, "GoldMember♥");
                }
                else
                if(choosed == 4)
                {
                    CS_SetClientClanTag(iClient, "Avicii™");
                }
                else
                if(choosed == 5)
                {
                    CS_SetClientClanTag(iClient, "theGΦD♰︎");
                }
                else
                if(choosed == 6)
                {
                    CS_SetClientClanTag(iClient, "TheReaper☠︎︎");
                }
                else
                if(choosed == 7)
                {
                    CS_SetClientClanTag(iClient, "BΦ$$♚︎");
                }				
                else
                if(choosed == 8)
                {
                    CS_SetClientClanTag(iClient, "Radioactive ☢︎");
                }
                else
                if(choosed == 9)
                {
                    CS_SetClientClanTag(iClient, "➀︎Ⓣ︎Ⓐ︎Ⓟ︎");
                }
                else
                if(choosed == 10)
                {
                    CS_SetClientClanTag(iClient, "◉◡◉");
                }		
                else
                if(choosed == 11)
                {
                    CS_SetClientClanTag(iClient, "❍ᴥ❍");
                }
                if(choosed == 12)
                {
                    CS_SetClientClanTag(iClient, "sNipeR ❖");    
                }
                else
                if(choosed == 13)
                {
                    CS_SetClientClanTag(iClient, "Star ❖");
                }
                else
                if(choosed == 14)
                {
                    CS_SetClientClanTag(iClient, "spArk ❖");
                }
                else
                if(choosed == 15)
                {
                    CS_SetClientClanTag(iClient, "CiΦaRa ❖");
                }
                else
                if(choosed == 16)
                {
                    CS_SetClientClanTag(iClient, "mOeTTT ❖");
                }
                else
                if(choosed == 17)
                {
                    CS_SetClientClanTag(iClient, "DestroyeR ❖");
                }
                else
                if(choosed == 18)
                {
                    CS_SetClientClanTag(iClient, "NΦ ЅCΦP3 ❖");
                }				
                else
                if(choosed == 19)
                {
                    CS_SetClientClanTag(iClient, "NΦΦB ❖");
                }
                else
                if(choosed == 20)
                {
                    CS_SetClientClanTag(iClient, "milmΦi ❖");
                }									
            }
        }
    }
}


// tagmenu
public int tagmenu(Handle menu, MenuAction action, int iClient, int param2)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            char sBuffer[12];
            int i = 9;

            switch(param2)
            {
                case 0:
                {
                    i=0;
                    CS_SetClientClanTag(iClient, "");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);                       
                }
                case 1:
                {
                    i=1;
                    CS_SetClientClanTag(iClient, "GoldMember♛");
                    IntToString(i, sBuffer, sizeof(sBuffer));        
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 2:
                {
                    i=2;
                    CS_SetClientClanTag(iClient, "GoldMember®");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 3:
                {
                    i=3;
                    CS_SetClientClanTag(iClient, "GoldMember♥");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 4:
                {
                    i=4;
                    CS_SetClientClanTag(iClient, "Avicii™");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 5:
                {
                    i=5;
                    CS_SetClientClanTag(iClient, "theGΦD♰︎");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 6:
                {
                    i=6;
                    CS_SetClientClanTag(iClient, "TheReaper☠︎︎");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 7:
                {
                    i=7;
                    CS_SetClientClanTag(iClient, "BΦ$$♚︎");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 8:
                {
                    i=8;
                    CS_SetClientClanTag(iClient, "Radioactive ☢︎");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 9:
                {
                    i=9;
                    CS_SetClientClanTag(iClient, "➀︎Ⓣ︎Ⓐ︎Ⓟ︎");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 10:
                {
                    i=10;
                    CS_SetClientClanTag(iClient, "◉◡◉");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }					
                case 11:
                {
                    i=11;
                    CS_SetClientClanTag(iClient, "❍ᴥ❍");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }	
                case 12:
                {
                    i=12;
                    CS_SetClientClanTag(iClient, "sNipeR ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));        
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 13:
                {
                    i=13;
                    CS_SetClientClanTag(iClient, "Star ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 14:
                {
                    i=14;
                    CS_SetClientClanTag(iClient, "spArk ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 15:
                {
                    i=15;
                    CS_SetClientClanTag(iClient, "CiΦaRa ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 16:
                {
                    i=16;
                    CS_SetClientClanTag(iClient, "mOeTTT ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 17:
                {
                    i=17;
                    CS_SetClientClanTag(iClient, "DestroyeR ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 18:
                {
                    i=18;
                    CS_SetClientClanTag(iClient, "NΦ ЅCΦP3 ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 19:
                {
                    i=19;
                    CS_SetClientClanTag(iClient, "NΦΦB ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }
                case 20:
                {
                    i=20;
                    CS_SetClientClanTag(iClient, "milmΦi ❖");
                    IntToString(i, sBuffer, sizeof(sBuffer));
                    SetClientCookie(iClient, GoldTagCookie, sBuffer);
                }	
            }
        }
 
        case MenuAction_End:
            CloseHandle(menu);
 
    }
    return 0;
}

// Menu Tag
public Action menutag(int client, int args)
{
    if(cv_GiveGoldTag.IntValue == 1)
    {
        char DNSbuffer[32];
        cv_ServerDNS.GetString(DNSbuffer, sizeof(DNSbuffer));
        if(HasDNS(client))
        {
            GoldTag(client);
        }

        else
        {
            PrintToChat(client, " ✪︎ \x01Add \x07'%s' \x01to your NAME to get \x10GoldMember♛ \x04(FREE ARMOR & CREDITS & !GOLDTAG)", DNSbuffer);
        }
    }
    else
        PrintToChat(client, " ✪︎ GoldTag is disabled.");
}

// GoldTag menu
public int GoldTag(int client)
{
    Handle menu = CreateMenu(tagmenu);
    SetMenuTitle(menu, "Menu TAG GoldMember");
 
    AddMenuItem(menu, "none", "No TaG");
    AddMenuItem(menu, "goldmember1", "GoldMember♛");
    AddMenuItem(menu, "goldmember2", "GoldMember®");
    AddMenuItem(menu, "goldmember3", "GoldMember♥");
    AddMenuItem(menu, "avicii", "Avicii™");
    AddMenuItem(menu, "dumnezeu","theGΦD♰︎");
    AddMenuItem(menu, "reaper", "TheReaper☠︎︎");
    AddMenuItem(menu, "asul","BΦ$$♚︎");
    AddMenuItem(menu, "radioactiv","Radioactive ☢︎");
    AddMenuItem(menu, "1tap","➀︎Ⓣ︎Ⓐ︎Ⓟ︎");
    AddMenuItem(menu, "cioara", "◉◡◉");
    AddMenuItem(menu, "moet", "❍ᴥ❍");
    AddMenuItem(menu, "sniper", "sNipeR ❖");
    AddMenuItem(menu, "stars", "Star ❖");
    AddMenuItem(menu, "spark", "spArk ❖");
    AddMenuItem(menu, "cioara", "CiΦaRa ❖");
    AddMenuItem(menu, "moet", "mOeTTT ❖");
    AddMenuItem(menu, "destroyer", "DestroyeR ❖");
    AddMenuItem(menu, "noscope", "NΦ ЅCΦP3 ❖");
    AddMenuItem(menu, "noob", "NΦΦB ❖");
    AddMenuItem(menu, "milmoi", "milmΦi ❖");
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
   
}


// Verify if player has DNS in name
bool HasDNS(int client)
{
    char PlayerName[32], buffer[32];
    cv_ServerDNS.GetString(buffer, sizeof(buffer));
    GetClientName(client, PlayerName, sizeof(PlayerName));

    if(StrContains(PlayerName, buffer, false) > -1)
        return true;
    else
        return false;
}



// Verify is the client is valid
stock bool IsClientValid(int client)
{
    if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
        return true;
    return false;
}

// Checking players
public Action CheckPlayers(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			addcredits(i);
		}
	}
	
	return Plugin_Continue;
}

// add credits function
public void addcredits(int client)
{
	if(cv_GiveCredits.IntValue == 1 && HasDNS(client) == true)
	{
		if(!(cv_CreditsTeam.IntValue == 1 && GetClientTeam(client) < 2)) 
		{
			Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(cv_CreditsAdder));
			PrintToChat(client, "✪︎ You're getting \x07%i more credits \x01for being a \x10GoldMember♛︎", GetConVarInt(cv_CreditsAdder));
		}
	}
}



public void Change_CreditsTime(Handle cvar, const char[] oldVal, const char[] newVal)
{
	if (TimeAuto != null)
	{
		KillTimer(TimeAuto);
		TimeAuto = null;
	}

	TimeAuto = CreateTimer(cv_CreditsTime.FloatValue, CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}