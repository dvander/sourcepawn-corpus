#include <sourcemod>
#include <sdktools>
#include <sdktools_hooks>
#include <timers>
#include <tf2>
#include <tf2_stocks>
#include <adt_array>

public Plugin:myinfo = 
{
	name = "PerksNAbilities",
	author = "Dllsearch",
	description = "Adds abilities & AP, also S T O N K S",
	version = "0.0.6",
	url = "http://ntaddv.space"
} // угадай))

enum perkdecks {
	civilian, // Тип не выбранный перк
	rager, // Ярость
	runner, // Бегун
	spamer, // Спаммер
	tank, // ТААААНК
	snake, //GAME OVER (Snake. Snake? SNAAAAAKE!!!)
	test,
	user //собственный билд игрока
	// 200MAD // for 200% M A D mode (it costs 200000 dollars to use this ability... for 12 seconds...
}; // список билдов

float pnd_AbilityPoints[MAXPLAYERS + 1] = {0, ...}; //массив, хранящий уровень заряда игроков
perkdecks pnd_Abilities[MAXPLAYERS + 1] = {0, ...}; //массив, хранящий номер билда абилки игроков
float pnd_APMax[MAXPLAYERS + 1] = {0, ...}; //массив, хранящий макс. кол-во AP игрокаов
int pnd_usersPerkDecks[MAXPLAYERS + 1][3]; //массив, хранящий деку игроков
int pnd_usersPerkDecksC[MAXPLAYERS + 1]; //
//int pnd_usersPerkDecks1[MAXPLAYERS + 1];
//int pnd_usersPerkDecks2[MAXPLAYERS + 1];
//int pnd_usersPerkDecks3[MAXPLAYERS + 1];
ConVar pnd_abl_chrg_k; // Консольная переменная, коэфф. зарядки перка
ConVar pnd_abl_chrg_t; // Консольная переменная, коэфф. зарядки перка по времени, пока не пашет
// ConVar pnd_abl_num;

int perkTFCperks[22] = {
	TFCond_Bonked,
	TFCond_Buffed,
	TFCond_CritCola,
	TFCond_DefenseBuffed,
	TFCond_RegenBuffed,
	TFCond_SpeedBuffAlly,
	TFCond_CritHype,
	TFCond_DefenseBuffNoCritBlock,
	TFCond_UberBulletResist,
	TFCond_UberBlastResist,
	TFCond_UberFireResist,
	TFCond_SmallBulletResist,
	TFCond_SmallBlastResist,
	TFCond_SmallFireResist,
	TFCond_Stealthed,
	TFCond_PreventDeath,
	TFCond_HalloweenGiant,
	TFCond_HalloweenTiny,
	TFCond_HalloweenGhostMode,
	TFCond_Parachute,
	TFCond_SwimmingCurse,
	TFCond_KingAura
}

float perkPrices[22] = {
	1.0,
	2.0,
	3.0,
	4.0,
	5.0,
	6.0,
	7.0,
	8.0,
	9.0,
	10.0,
	11.0,
	12.0,
	13.0,
	14.0,
	15.0,
	16.0,
	17.0,
	18.0,
	19.0,
	20.0,
	21.0,
	22.0	
}

char perkNames[22][] = {
	"TFCond_Bonked",
	"TFCond_Buffed",
	"TFCond_CritCola",
	"TFCond_DefenseBuffed",
	"TFCond_RegenBuffed",
	"TFCond_SpeedBuffAlly",
	"TFCond_CritHype",
	"TFCond_DefenseBuffNoCritBlock",
	"TFCond_UberBulletResist",
	"TFCond_UberBlastResist",
	"TFCond_UberFireResist",
	"TFCond_SmallBulletResist",
	"TFCond_SmallBlastResist",
	"TFCond_SmallFireResist",
	"TFCond_Stealthed",
	"TFCond_PreventDeath",
	"TFCond_HalloweenGiant",
	"TFCond_HalloweenTiny",
	"TFCond_HalloweenGhostMode",
	"TFCond_Parachute",
	"TFCond_SwimmingCurse",
	"TFCond_KingAura"
}



public void OnPluginStart() //при старте
{
	for (int ses = 0; ses < MAXPLAYERS + 1; ses++)
	{
		pnd_usersPerkDecks[ses] = {0,0,0};
	}
	HookEvent("player_hurt", charger); //Ставим чекалку на хит
	pnd_abl_chrg_k = CreateConVar("pnd_abl_chrg_k", "1.42", "Coefficient of taking ability points", _, true, 0.00, true, 100.00); //делаем в консоль переменную
	pnd_abl_chrg_t = CreateConVar("pnd_abl_chrg_t", "0.42", "Coefficient of taking ability points", _, true, 0.00, true, 100.00); //другая переменная
	// pnd_abl_num = CreateConVar("pnd_abl_num", "0", "Description");
	
	HookConVarChange(pnd_abl_chrg_k, conVarKChanged); // Реагируем на изменение переменной
	HookConVarChange(pnd_abl_chrg_k, conVarTChanged); // вторая
	
	
	RegConsoleCmd("pna_ability_use", useAbility); // Чекаем комманду юзанья абилки в консось
	
	//RegConsoleCmd("pna_ability_new", setAbility);
	
	RegConsoleCmd("perks", perkDeckPanel); // Чекаем комманду запроса смены перка в консоль
	
}

public void OnClientPutInServer(int client) //когда игрок входит на сервер
{
	pnd_AbilityPoints[client] = 0; // Прописываем 0 очкв абилки нвому юзеру
	pnd_Abilities[client] = 0; // И 0й перк (знчт, что не выбирал)
	pnd_APMax[client] = 100.0; // Ставим лимит AP в 100.0
	perkDeckPanel(client, 0); // Если только присоединился, предлагаем выбрать перк
	
	pnd_usersPerkDecksC[client] = 0;
	
	CreateTimer (1.0, chargeHUD, client, TIMER_REPEAT );
	///
	CreateTimer (1.0, time_charger, client, TIMER_REPEAT );
}

public OnClientConnected(int client) //Когда есть контакт, но я не юзаю (пока)
{
	
}

 public conVarKChanged(ConVar convar, const char[] oldValue, const char[] newValue) // Вызывается, если ConVar попытались поменять
 {
 	float next = StringToFloat(newValue);
	SetConVarFloat(pnd_abl_chrg_k, next, true, true); // Меняем ConVar
 }
 
 public conVarTChanged(ConVar convar, const char[] oldValue, const char[] newValue) // Вызывается, если ConVar попытались поменять
 {
 	float next = StringToFloat(newValue);
	SetConVarFloat(pnd_abl_chrg_t, next, true, true); // Меняем ConVar
 }
 
 public Action chargeHUD (Handle timer, int client)  // вывод накопленного заряда на экран
 {
	if (IsClientConnected(client) && IsClientInGame(client)) // если игрок играет
	{
		
		SetHudTextParams(0.15, 0.07, 0.9, 255, 255, 255, 255, 2, 0.02, 0.01, 0.01); // Выставляем положение, время, цвет, эффект, время эффектов для текста
		char ses[5];
		FloatToString(pnd_AbilityPoints[client], ses, 5);
		ShowHudText(client, -1, "PNA %s %%", ses); // Рисуем текст
	}
 }
 
 /// --- /// --- /// --- ///
 
public int perkDeckPanelHandler(Menu menu, MenuAction action, int client, int ablt) // Смотрим выбранный пункт меню
{
	if (action == MenuAction_Select)
	{
		if(ablt == 7) 
		{
			Comm_BuildPerkDeck(client, 0);
			pnd_usersPerkDecksC[client] = 0;
		}
		PrintToConsole(client, "You selected perk # %d", ablt);
		pnd_Abilities[client] = ablt;
	}
	else if (action == MenuAction_Cancel)
	{
		PrintToServer("Client %d's menu was cancelled.  Reason: %d", client, ablt);
	}
}
 
public Action perkDeckPanel(int client, int args) // Рисуем менюшку выбора готовых перков
{
	Panel panel = new Panel();
	panel.SetTitle("!perks | Choose your perkdeck. | bind pnd_ability_use to activate");
	panel.DrawItem("rager");
	panel.DrawItem("runner");
	panel.DrawItem("spamer");
	panel.DrawItem("tank");
	panel.DrawItem("snake");
	panel.DrawItem("BDSM");
	panel.DrawItem("Make your OWN perkdeck! (BETA)");
 
	panel.Send(client, perkDeckPanelHandler, MENU_TIME_FOREVER);
 
	delete panel;
 
	return Plugin_Handled;
}

/// --- /// --- /// --- ///

Menu BuildMapMenu()
{
	Menu menu = new Menu(Menu_BuildPerkDeck);
	for (int o = 0; o < sizeof(perkNames); o++)
	{
		menu.AddItem(perkNames[o], perkNames[o]);
	}
	menu.SetTitle("!perks | Choose your perks | bind pnd_ability_use to activate");
	return menu;
}

public int Menu_BuildPerkDeck(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		/*
		char info[32];
		bool found = menu.GetItem(item, info, sizeof(info));
		PrintToConsole(client, "You selected item: %d (found? %d info: %s)", item, found, info);
		ServerCommand("changelevel %s", info); 
		*/
		if (pnd_usersPerkDecksC[client] < 3)
		{
			pnd_usersPerkDecks[client][pnd_usersPerkDecksC[client]] = item;
			pnd_usersPerkDecksC[client]++;
			if (pnd_usersPerkDecksC[client] < 3) Comm_BuildPerkDeck(client, 0);
		}
	}
}

public Action Comm_BuildPerkDeck(int client, int args)
{ 
	Menu menu = BuildMapMenu();
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

/// --- /// --- /// --- ///
public Action useAbility(int client, int args) //Вызывается при pna_use_ability
{
	char arg[128];
	char full[256];
 
	/* GetCmdArgString(full, sizeof(full));
 
	if (client)
	{
		PrintToServer("Command pna_ability_use from client %d", client);
	} else {
		PrintToServer("Command pna_ability_use from... server?");
	}
 
	PrintToServer("Argument string: %s", full);
	PrintToServer("Argument count: %d", args);
	for (int i=1; i<=args; i++)
	{
		GetCmdArg(i, arg, sizeof(arg));
		PrintToServer("Argument %d: %s", i, arg);
	}
	*/
	if ( pnd_AbilityPoints[client] == 100.00 ) // Если абилка заряжена
	{
		// Перебор и вызов абилк. SWITCH тут глючит пздц, так что, пришлось делать через if else
		//pnd_AbilityPoints[client] = 0.00;
		if (pnd_Abilities[client] == 0) 
			{
				perkDeckPanel(client, 0); // если перк 0 (не выбирал), то предлагаем выбрать
				pnd_AbilityPoints[client] = 100.00;
			}
		else if (pnd_Abilities[client] == 1) frager(client); //юзает перк
		else if (pnd_Abilities[client] == 2) frunner(client); //same
		else if (pnd_Abilities[client] == 3) fspamer(client);
		else if (pnd_Abilities[client] == 4) ftank(client);
		else if (pnd_Abilities[client] == 5) fsnake(client);
		else if (pnd_Abilities[client] == 6) testin(client);
		else if (pnd_Abilities[client] == 7) 
		{
			//perkDeckPanel(client, 0);
			//Comm_BuildPerkDeck(client, 0);
			float pushittothelimit = pnd_AbilityPoints[client] / ( perkPrices[pnd_usersPerkDecks[client][0]] + perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]] );
			int [] buttsecs = new int[pnd_usersPerkDecksC[client]];
			for (int x = 0; x < pnd_usersPerkDecksC[client]; x++)
			{
				buttsecs[x] = perkTFCperks[pnd_usersPerkDecks[client][x]];
			}
			pna_addcond(buttsecs, client, pushittothelimit, pnd_usersPerkDecksC[client]);
			pnd_AbilityPoints[client] = 0;
		}
		PrintToChat(client, "ABILITY USED"); // Пишем в чат, что абилка использована
	}
	else //если ещё не заряжена, пишет 
	{
		char ses[5];
		FloatToString(pnd_AbilityPoints[client], ses, 5);
		PrintToChat(client, "ABILITY: %s%% charged", ses); //сколько заряда в чат
	}
	
	return Plugin_Handled; //сообщает, что отработал
} 

public void userPerkdeckUse (int client) // Активатор абилки юзера
{
	//float price = perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]] + perkPrices[pnd_usersPerkDecks[client][3]]; // Складываем стоимость перков игрока в общую стоимость
	float price = perkPrices[pnd_usersPerkDecks[client][0]] + perkPrices[pnd_usersPerkDecks[client][1]] + perkPrices[pnd_usersPerkDecks[client][2]]; // Складываем стоимость перков игрока в общую стоимость
	float secks = pnd_AbilityPoints[client]/price; // Делим AP игрока на общую стоимость абилок, получаем кол-во секунд работы
	pna_addcond (pnd_usersPerkDecks[client][0], client, secks, 3); // Применяем выбранные юзером абилки на полученное время
}

public void frager(int client) //готовый абилкосет "Rager"
{
	int conds[4] = {19, 26, 29, 60};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 17.50, limits);
	discharge(client, 56.00);
}

public void frunner(int client) //готовый абилкосет "Runner"
{
	int conds[3] = {26, 42, 72};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 6.50, limits);
	discharge(client, 22.00);
}

public void fspamer(int client) //готовый абилкосет "Spammer"
{
	int conds[3] = {16, 72, 91};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 13.33, limits);
	discharge(client, 78.00);
}

public void ftank(int client) //готовый абилкосет "TAAANK!"
{
	int conds[6] = {26, 42, 61, 62, 63, 73};
	int limits = sizeof(conds);
	//TF2_RegeneratePlayer(client);
	pna_addcond (conds, client, 25.00, limits);
	discharge(client, 100.00);
}

public void fsnake(int client) //готовый абилкосет "(solid) Snake"
{
	int conds[4] = {32, 66};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 7.00, limits);
	discharge(client, 30.00);
}

public void testin(int client) //test
{
	int conds[4] = {24,25,27};
	int limits = sizeof(conds);
	pna_addcond (conds, client, 3.00, limits);
	discharge(client, 5.00);
}

public charger(Event hEvent, const char[] name, bool dontBroadcast) //функция, вызываемая, когда кто-то кого-то бьёт
{
	int attacker = GetClientOfUserId(hEvent.GetInt("attacker"));
	damage_charger(attacker, pnd_abl_chrg_k.FloatValue);
	/*	
	int attacked = GetClientOfUserId(hEvent.GetInt("userid"));
	for(int x = 0; x < 3; x++)
	{
		if(isAttackingPerk[pnd_usersPerkDecks[attacker][y]])
		{
			perkHitCond(attacked, perkTFCperks[pnd_usersPerkDecks[attacker][y]]);
		}
	}
	*/
}

public void damage_charger(int client, float points) //Зарядка ударами
{
	// Сейчас идёт перебор по классу игрока. Если еслт совпатение - количество зарядов умножается на коэффициент для класса
	if (TF2_GetPlayerClass(client) == TFClass_Pyro) points *= 0.39; // Если игрок пиро, то 42% от К
	else if (TF2_GetPlayerClass(client) == TFClass_Heavy) points *= 0.74;// Если игрок Хуви 80% от К
	else if (TF2_GetPlayerClass(client) == TFClass_DemoMan) points *= 0.80; // итд
	else if (TF2_GetPlayerClass(client) == TFClass_Soldier) points *= 0.85;
	else if (TF2_GetPlayerClass(client) == TFClass_Engineer) points *= 1.01;// Если игрок Инж, 101% от К
	else if (TF2_GetPlayerClass(client) == TFClass_Spy) points *= 1.13;
	else if (TF2_GetPlayerClass(client) == TFClass_Sniper) points *= 1.17;
	else if (TF2_GetPlayerClass(client) == TFClass_Scout) points *= 1.33;
	else if (TF2_GetPlayerClass(client) == TFClass_Medic) points *= 1.57;
	/// --- ///
	pnd_AbilityPoints[client] += points; // Складываем поинты
	if (pnd_AbilityPoints[client] > pnd_APMax[client]) pnd_AbilityPoints[client] = pnd_APMax[client];  // Если получилось больше лимита, делаем равным лимиту
}

public void discharge(int client, float points) //Разрядка
{
	pnd_AbilityPoints[client] -= points; // снимаем поинты
	if (pnd_AbilityPoints[client] < 0.00) pnd_AbilityPoints[client] = 0.00; //если <0, делаем 0
}

public Action time_charger(Handle timer, int client) //зарядка по таймеру
{
	if (IsClientInGame(client) && !IsFakeClient(client) && (pnd_AbilityPoints[client] < pnd_APMax[client])) // Если в клиент игре, не фейковый, и заряд меньше лимита
		pnd_AbilityPoints[client] += pnd_abl_chrg_t.FloatValue; // прибавляем Т
	if (pnd_AbilityPoints[client] > pnd_APMax[client]) pnd_AbilityPoints[client] = pnd_APMax[client];  // Если получилось больше лимита, делаем равным лимиту
}


// Список состояний, аналогичный addcond
TFCond tfca[128] = {
	TFCond_Slowed,	// 0
	TFCond_Zoomed,
	TFCond_Disguising,
	TFCond_Disguised,
	TFCond_Cloaked,	
	TFCond_Ubercharged, // 5
	TFCond_TeleportedGlow,
	TFCond_Taunting,
	TFCond_UberchargeFading,
	//TFCond_Unknown1,
	TFCond_CloakFlicker, 
	TFCond_Teleporting, // 10
	TFCond_Kritzkrieged,
	//TFCond_Unknown2,
	TFCond_TmpDamageBonus,
	TFCond_DeadRingered,
	TFCond_Bonked,
	TFCond_Dazed, // 15
	TFCond_Buffed,
	TFCond_Charging,
	TFCond_DemoBuff,
	TFCond_CritCola,
	TFCond_InHealRadius, //20
	TFCond_Healing,
	TFCond_OnFire,
	TFCond_Overhealed,
	TFCond_Jarated,
	TFCond_Bleeding, //25
	TFCond_DefenseBuffed,
	TFCond_Milked,
	TFCond_MegaHeal,
	TFCond_RegenBuffed,
	TFCond_MarkedForDeath, //30
	TFCond_NoHealingDamageBuff,
	TFCond_SpeedBuffAlly,
	TFCond_HalloweenCritCandy,
	TFCond_CritCanteen,
	TFCond_CritDemoCharge,
	TFCond_CritHype,
	TFCond_CritOnFirstBlood,
	TFCond_CritOnWin,
	TFCond_CritOnFlagCapture,
	TFCond_CritOnKill, //40
	TFCond_RestrictToMelee,
	TFCond_DefenseBuffNoCritBlock,
	TFCond_Reprogrammed,
	TFCond_CritMmmph,
	TFCond_DefenseBuffMmmph,
	TFCond_FocusBuff,
	TFCond_DisguiseRemoved,
	TFCond_MarkedForDeathSilent,
	TFCond_DisguisedAsDispenser,
	TFCond_Sapped, //50
	TFCond_UberchargedHidden,
	TFCond_UberchargedCanteen,
	TFCond_HalloweenBombHead,
	TFCond_HalloweenThriller,
	TFCond_RadiusHealOnDamage,
	TFCond_CritOnDamage,
	TFCond_UberchargedOnTakeDamage,
	TFCond_UberBulletResist,
	TFCond_UberBlastResist,
	TFCond_UberFireResist, //60
	TFCond_SmallBulletResist,
	TFCond_SmallBlastResist,
	TFCond_SmallFireResist,
	TFCond_Stealthed,
	TFCond_MedigunDebuff,
	TFCond_StealthedUserBuffFade,
	TFCond_BulletImmune,
	TFCond_BlastImmune,
	TFCond_FireImmune,
	TFCond_PreventDeath, //70
	TFCond_MVMBotRadiowave,
	TFCond_HalloweenSpeedBoost,
	TFCond_HalloweenQuickHeal,
	TFCond_HalloweenGiant,
	TFCond_HalloweenTiny,
	TFCond_HalloweenInHell,
	TFCond_HalloweenGhostMode,
	TFCond_MiniCritOnKill,
	TFCond_ObscuredSmoke, //TFCond_DodgeChance,
	TFCond_Parachute, //80
	TFCond_BlastJumping,
	TFCond_HalloweenKart,
	TFCond_HalloweenKartDash,
	TFCond_BalloonHead,
	TFCond_MeleeOnly,
	TFCond_SwimmingCurse,
	TFCond_FreezeInput, //TFCond_HalloweenKartNoTurn,
	TFCond_HalloweenKartCage,
	TFCond_HasRune,
	TFCond_RuneStrength, //90
	TFCond_RuneHaste,
	TFCond_RuneRegen,
	TFCond_RuneResist,
	TFCond_RuneVampire,
	TFCond_RuneWarlock,
	TFCond_RunePrecision,
	TFCond_RuneAgility,
	TFCond_GrapplingHook,
	TFCond_GrapplingHookSafeFall,
	TFCond_GrapplingHookLatched, //100
	TFCond_GrapplingHookBleeding,
	TFCond_AfterburnImmune,
	TFCond_RuneKnockout,
	TFCond_RuneImbalance,
	TFCond_CritRuneTemp,
	TFCond_PasstimeInterception,
	TFCond_SwimmingNoEffects,
	TFCond_EyeaductUnderworld,
	TFCond_KingRune,
	TFCond_PlagueRune, //110
	TFCond_SupernovaRune,
	TFCond_Plague,
	TFCond_KingAura,
	TFCond_SpawnOutline,
	TFCond_KnockedIntoAir,
	TFCond_CompetitiveWinner,
	TFCond_CompetitiveLoser,
	//TFCond_NoTaunting,
	//TFCond_NoTaunting_DEPRECATED,
	TFCond_HealingDebuff,
	TFCond_PasstimePenaltyDebuff,
	TFCond_GrappledToPlayer, // 120
	TFCond_GrappledByPlayer,
	TFCond_ParachuteDeployed,
	TFCond_Gas,
	TFCond_BurningPyro,
	TFCond_RocketPack, // 125
	TFCond_LostFooting,
	TFCond_AirCurrent // 127
}

public pna_addcond (int[] conds, int client, float time, int length) //функция, добавляющая кондишны, указаные в массиве
{
	for (int c=0; c<length; c++)
	{
		TF2_AddCondition(client, tfca[conds[c]], time, 0); // Добавляем кондишны, перебирая нужные из массива, присваиваем им время действия
	}
}

public pna_removecond (int[] conds, int client, int length) //убирает состояния по аналогии
{
	int c = 0;
	while (c < length)
	{
		TF2_RemoveCondition(client, tfca[conds[c]]);
		c++;
	}
}

/// --- /// --- /// --- ///

//Далее должны идти массивы с инфой по покупаемым перкам, НЕ обьединяющиеся в ArrayList?
/*bool isAttackingPerk[22] = {
	false,
	false,	
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false,
	false
}*/
//ArrayList CondShop = new ArrayList(3, 129); 
// CondShop.Push