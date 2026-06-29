#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

// ** DO EDYCJI

// określ jaką procentową szansę na wylosowanie mają broń, kasa, hp... (suma musi wynosić 100%)
// przykładowo, obecnie szansa na drop broni to 20%, a kasa - 40%. Do 100% pozostało 40 i tyle właśnie będzie mieć szansa na HP
// Gdyby SZANSA_BROŃ ustawić na 10%, a SZANSA_KASA na 25%, to szansa na HP bedzie: 100% - (10% + 25%) = 65%

#define SZANSA_BRON 20
#define SZANSA_KASA 40
// #define SZANSA_HP 100 - (SZANSA_BRON + SZANSA_KASA)

// **

#define PISTOL_ROUND 1
#define VIP_FLAG ADMFLAG_CUSTOM1
#define TAG "[{green}uKatowa.pl{default}]"

int roundCounter = 0;
int phase = 0;
bool wasSwitch = false;

bool usedRoulette[MAXPLAYERS];

int g_iAccount;

public void OnPluginStart() {
    RegConsoleCmd("sm_rtd", MainMenu);
    HookEvent("round_start", NowaRunda);
    HookEvent("announce_phase_end", Event_Phase);

    g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
}

public void OnMapStart() {
    roundCounter = 0;
    phase = 0;
    wasSwitch = false;
}

public Action Event_Phase(Event event, const char[] name, bool dontBroadcast)  {
    ++phase;
} 

public Action NowaRunda(Handle event, const char[] name, bool dontbroadcast) {
    if (wasSwitch) {
        wasSwitch = false;
        phase = -1;
    }
    else {
        if (phase == 1)
            wasSwitch = true;
    }

    if (roundCounter == PISTOL_ROUND || wasSwitch) {
        CPrintToChatAll("%s Ruletka{darkred} ZABLOKOWANA!{default} Runda pistoletowa", TAG);
    }
    if (roundCounter == PISTOL_ROUND+1 || phase == -1) {
        CPrintToChatAll("%s Ruletka{green} ODBLOKOWANA!", TAG);
        phase = 0;
    }

    ++roundCounter;

    for (int i = 0; i < MAXPLAYERS; i++) {
        usedRoulette[i] = false;
    }
}

public Action MainMenu(int client, int args) {
    if (!IsPlayerVIP(client)) {
        CPrintToChat(client, "%s Potrzebujesz wyższych uprawnień, aby użyć tej komendy (VIP/Admin/H.A)", TAG);
        return Plugin_Continue;
    }

    if (!CanUseRoulette()) {
        CPrintToChat(client, "%s Ruletka{darkred} ZABLOKOWANA!", TAG);
        return Plugin_Continue;
    }

    if (!IsPlayerAlive(client)) {
        CPrintToChat(client, "%s Musisz być żywy, aby użyć ruletki!", TAG);
        return Plugin_Continue;
    }

    if (usedRoulette[client]) {
        CPrintToChat(client, "%s W ruletkę można zagrać {lightred} tylko raz na rundę!", TAG);
        return Plugin_Continue;
    }

    usedRoulette[client] = true;

    int randomNum = GetRandomInt(0, 100);
    if (randomNum < SZANSA_BRON) {
        if (GetRandomInt(1,2) == 1) {
            GivePlayerItem(client, "weapon_ak47");
            CPrintToChatAll("%s{purple} %N{default} zagrał w ruletkę... i wygrał{green} AK47!", TAG, client);
        }
        else {
            GivePlayerItem(client, "weapon_famas");
            CPrintToChatAll("%s{purple} %N{default} zagrał w ruletkę... i wygrał{green} Famasa!", TAG, client);
        }
        return Plugin_Continue;
    }
    else if (randomNum < SZANSA_BRON+SZANSA_KASA) {
        int money = GetRandomInt(-16000, 16000);
        AddMoney(client, money);

        CPrintToChatAll("%s{purple} %N{default} zagrał w ruletkę... i %s %d$!", TAG, client, money > 0 ? "wygrał{green}" : "stracił{lightred}", money);

        return Plugin_Continue;
    }
    else {
        int hp = GetRandomInt(-40, 40);
        int currentHP = GetClientHealth(client);
        if (currentHP + hp < 1)
            SDKHooks_TakeDamage(client, client, client, 500.0);
        else
            SetEntityHealth(client, currentHP + hp);

        CPrintToChatAll("%s{purple} %N{default} zagrał w ruletkę... i %s%dHP", TAG, client, hp > 0 ? "dostał{green} +" : "dostał wp*****l od Ruskiej Mafii{lightred} ", hp);

        return Plugin_Continue;
    }

}

bool CanUseRoulette() {
    if (roundCounter <= PISTOL_ROUND+1)
        return false;
    
    return !wasSwitch;
}

void AddMoney(int client, int n) {
    int currMoney = GetEntData(client, g_iAccount);
    if (currMoney + n > 16000)
        SetEntData(client, g_iAccount, 16000);
    else if (currMoney + n < 0)
        SetEntData(client, g_iAccount, 0);
    else
        SetEntData(client, g_iAccount, GetEntData(client, g_iAccount) + n);
}

bool IsPlayerVIP(int client) {
    if (GetUserFlagBits(client) & (VIP_FLAG|ADMFLAG_BAN))
        return true;

    return false;
}