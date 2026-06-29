#include <sourcemod>
#define MLN 32
#define Query 128
#define MaxPlayerOnServer 4
#define Exp_Multiplier 2

public Plugin myinfo = 
{
	name = "[L4D]Exp/rank system",
	author = "marcel, Grzechu",
	description = "Exp, buying, rank, skills - system",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};

// MLN - rozmiar 32 tablicowy dobry np. (jak chcemy jakis nickname gracza wziasc)
// Query rozmiar 128 tablicowy dobry pod query sql
// MaxPlayerOnServer - generuje w tablicach ile max graczy moze grac aktualnie
// Exp_Multiplier - mnoznik expa (z tym pomoca mozemy pomnozyc exp do nastepnego poziomu o wielekrotnosc wartosci tej zmiennej)

int idUser[MaxPlayerOnServer];// tutaj przechowujemy client id uzytkownikow polaczonych na serwerze
int exp[MaxPlayerOnServer]; // przechowujemy exp gracza
int ExpNext[MaxPlayerOnServer]; // do nastepnego poziomu (tymczasowe)
int levels[MaxPlayerOnServer]; // poziomy graczy (tymczasowe)
int health[MaxPlayerOnServer]; // przechowujemy stan zdrowia graczy na serwerze polaczonych
float Speed[MaxPlayerOnServer]; // przechowujemy szybkosc graczy na serwerze polaczonych

// Slots - Ogranicza sloty w funkcjach takich jak (addUserID, deleteUserID) do MaxPlayerOnServer i
//PlayerCount zmiennej
static int Slots; // od 0 do zmiennej MaxPlayerOnServer

static int PlayerCount; // zlicz nam ilosc graczy (nie botow) na serwerze

float SaveStatsAll = 120.0; // przechowuje licznik do zapisywania statystyk graczy na serwerze

EngineVersion l4d; // zmienna odpowiedzialna za sprawdzanie czy to l4d czy l4d2 gra

Handle Mysql = INVALID_HANDLE; // uchwyt do bazy danych

int WeaponCost[26]; // koszt broni, - suma wszystkich itemow wynosi = 26 do l4d2, 11 do l4d1
int LimitsWeapon[MaxPlayerOnServer]; // uchwyt do kupywnia co runde przez graczy
int LIMITS = 3; // limit kupowania broni co runde

int SkillsPoints[MaxPlayerOnServer]; // tutaj przechowujemy ilosc dostepnych punktow umiejetnosci graczom polaczonych na serwerze
const int Skill_Point_Level = 3; // okresla ile punktow umiejetnosci na poziom dostaje gracz

const int SkillHealth=1; // ile trzeba punktow umiejetnosci aby wytrenowac Skill Health oraz daje tyle zycia
const int SkillSpeed=2; // ile trzeba punktow umiejetnosci aby wytrenowac Skill Speed oraz daje tyle szybkosci postaci
const float GiveSpeed=0.1; // tyle daje szybkosci za kazde rozdane w punkt umiejetnosci, skilla (Skill Speed)

new regulate_speed = -1; // tutaj zostaw na -1

// funkcja ta dodaje uzytkownika do tablicy.
bool addUserID(const int client){
	char checkSteam[MLN];
	
	// sprawdzamy czy liczba miejsc zostala przekroczona i zwracamy bool'a.
	if(Slots >= PlayerCount && PlayerCount >= MaxPlayerOnServer){PrintToServer("Array cannot be add more users, limits slots exceeded!"); return false;}
	
	// sprawdzamy, czy to bot, czy nie? Jesli tak zwracamy false.
	if(IsFakeClient(client)){PrintToServer("This client are bot!"); return false;}

	// sprawdzamy czy ma "STEAM_" jesli nie ma zwracamy false
	//GetClientAuthId(client, AuthId_Steam2, checkSteam,sizeof(checkSteam));
	GetClientAuthId(client, AuthId_Steam2, checkSteam, MLN);
	if(StrContains(checkSteam,"STEAM_") <= -1){PrintToServer("non-steam Player"); return false;}
	
	// algorytm ten szuka wolnego miejsca w tablicy po czym...
	//zapisuje id clienta do tablicy.
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] == 0){
			// dodajemy clienta id do tablicy idUser o podanym indeksie
			idUser[i]=client;
			// inkrementujemy zmienna slots
			Slots++;
			// najpierw szukamy takiego gracza w bazie danych,
			// jesli wyszuka takiego gracza to wtedy zwroc true, w przeciwnym razie false
			if(!SearchDatabasePlayer(client, checkSteam))return false;
			return true;
		}else if(idUser[i] == client){
			// ten warunek sprawdza czy jest juz taki uzytkownik w tablicy
			//zapisany, jak tak to zwracamy false
			return false;
		}
	}
	
	// w przeciwnym razie zwraca false
	return false;
}

bool deleteUserID(const int client){
	char checkSteam[64];
	if(Slots <= 0){PrintToServer("There are no user's in array!"); return false;}
	
	// sprawdzamy, czy to bot, czy nie? Jesli tak zwracamy false.
	if(IsFakeClient(client)){PrintToServer("This client are bot!"); return false;}
	
	// sprawdzamy czy ma "STEAM_" jesli nie ma zwracamy false
	GetClientAuthId(client,AuthId_Steam2,checkSteam,64);
	if(StrContains(checkSteam,"STEAM_") == -1){PrintToServer("non-steam Player"); return false;}
	// 3 = 10 id client'a
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] == client){
			// zerujemy wszystkie zwiazane z graczem (tymczasowe) dane
			idUser[i]=0;
			exp[i]=0;
			ExpNext[i]=0;
			levels[i]=0;
			LimitsWeapon[i]=LIMITS;
			health[i]=0;
			Speed[i]=0.0;
			// dekrementujemy zmienna slots
			Slots--;
			if(i == PlayerCount)return true;
			for(int j=i;j<=PlayerCount;j++){
				for(int c=j;c<=PlayerCount;c++){
					if(idUser[j] == 0 && idUser[c] != 0){
						idUser[j]=idUser[c];
						exp[j]=exp[c];
						ExpNext[j]=ExpNext[c];
						levels[j]=levels[c];
						LimitsWeapon[j]=LimitsWeapon[c];
						health[j]=health[c];
						Speed[j]=Speed[c];
						
						Speed[c]=0.0;
						health[c]=0;
						ExpNext[c]=0;
						exp[c]=0;
						idUser[c]=0;
						levels[c]=0;
						LimitsWeapon[c]=0;
					}
				}
			}
			return true;
		}
	}
	return false;
}

public void PluginInit()
{
	//char temp[MLN];
	PlayerCount=0;
	Slots=0;
	//Mysql = SQL_Connect("l4dstats",true,temp, sizeof(temp));
	// Inicjalizacja tablicy idUser zerami
	for (int i = 0; i < MaxPlayerOnServer; i++)
	{
		idUser[i] = 0;
		exp[i]=0;
		ExpNext[i]=0;
		levels[i]=0;
		LimitsWeapon[i]=LIMITS;
		health[i]=0;
		Speed[i]=0.0;
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("shop", shopBuy); // /shop kupuj przedmioty ze sklepu za expa w grze
	RegConsoleCmd("top100exp", TOP100Exp); // w grze /top100exp aby wyswietlic top exp'a
	RegConsoleCmd("top100level", TOP100Level); // w grze /top100level aby wyswietlic top level'e
	RegConsoleCmd("ss",statsCheck); // uzyj /ss w grze aby wyswietlic dane
	RegConsoleCmd("skills",skillsSystem); // uzyj /skills aby wytrenowac umiejetnosci postaci
	HookEvent("player_death",OnDeath);
	HookEvent("player_spawn",spawning); // gracz sie respawnia
	HookEvent("player_transitioned",roundSpawn); // gracz do nastepnego etapu gry wchodzi
	CreateTimer(SaveStatsAll,SaveStats, _, TIMER_REPEAT); // zapisuje nam statystyki graczom
	
	l4d = GetEngineVersion();
	regulate_speed = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	
	// l4d1
	if(l4d == Engine_Left4Dead){
		WeaponCost[0] = 100;// Price of Pistol
		WeaponCost[1] = 150;// Price of Submachine Gun
		WeaponCost[2] = 150;// Price of Pump Shotgun
		WeaponCost[3] = 200;// Price of Auto Shotgun
		WeaponCost[4] = 200;// Price of Assault Rifle
		WeaponCost[5] = 200;// Price of Hunting Rifle
		WeaponCost[6] = 100;// Price of Molotov Cocktail
		WeaponCost[7] = 100;// Price of Pipe Bomb
		WeaponCost[8] = 125;// Price of Ammo
		WeaponCost[9] = 500;// Price of pain pills
		WeaponCost[10] = 1000;// Price of First aid kit
		
	// l4d2
	} else if (l4d == Engine_Left4Dead2){
		WeaponCost[0] = 100;// Price of Pistol
		WeaponCost[1] = 150;// Price of Submachine Gun
		WeaponCost[2] = 150;// Price of Chrome Shotgun
		WeaponCost[3] = 150;// Price of Pump Shotgun
		WeaponCost[4] = 300;// Price of Tactical Shotgun
		WeaponCost[5] = 300;// Price of Assault Rifle
		WeaponCost[6] = 300;// Price of Hunting Rifle
		WeaponCost[7] = 200;// Price of mp5
		WeaponCost[8] = 200;// Price of Magnum Pistol
		WeaponCost[9] = 300;// Price of Combat Shotgun
		WeaponCost[10] = 250;// Price of Sniper Rifle
		WeaponCost[11] = 250;// Price of M16 Assault Rifle
		WeaponCost[12] = 250;// Price of Scout
		WeaponCost[13] = 500;// Price of AWP
		WeaponCost[14] = 300;// Price of AK-47
		WeaponCost[15] = 500;// Price of Grenade Launcher
		WeaponCost[16] = 500;// Price of M60 Machine Gun
		WeaponCost[17] = 750;// Price of Chainsaw
		WeaponCost[18] = 150;// Price of Molotov Cocktail
		WeaponCost[19] = 150;// Price of Pipe Bomb
		WeaponCost[20] = 150;// Price of Vomitjar
		WeaponCost[21] = 500;// Price of Pain Pills
		WeaponCost[22] = 750;// Price of First Aid Kit
		WeaponCost[23] = 500;// Price of Adrenaline
		WeaponCost[24] = 550;// Price of Defibrillator
		WeaponCost[25] = 150;// Price of ammo
	}
}

public void OnMapStart(){
	char temp[128];
	PlayerCount=0;
	Slots=0;
	if(Mysql != INVALID_HANDLE)CloseHandle(Mysql);
	// tutaj w miejscu "l4dstats" skonfiguruj swoja baze danych.
	Mysql = SQL_Connect("l4dstats",true,temp, sizeof(temp));
	for (int i = 0; i < MaxPlayerOnServer; i++)
	{
		idUser[i] = 0;
		exp[i]=0;
		ExpNext[i]=0;
		levels[i]=0;
		LimitsWeapon[i]=LIMITS;
		health[i]=0;
	}
}
public void OnClientPutInServer(int client){
	//char ipclient[18];
	//GetClientIP(client,ipclient,sizeof(ipclient));
	if(!IsFakeClient(client)){ //&& !StrEqual(ipclient,"127.0.0.1")){
		PlayerCount++;
		addUserID(client);
	}
}

public void OnClientDisconnect(int client){
	if(!IsFakeClient(client)){
		char steamID[MLN];
		bool isSteamID = GetClientAuthId(client,AuthId_Steam2,steamID,MLN);
		if(isSteamID)SaveStatsDataBase(client, steamID);
		deleteUserID(client);
		PlayerCount--;
	}
}

public Action OnDeath(Event event, const char[] name, bool dontBroadcast){
	int idKiller = GetClientOfUserId(GetEventInt(event,"attacker"));
	if(idKiller == 0 || IsFakeClient(idKiller))return Plugin_Handled;
	char tempName[MLN];
	GetEventString(event,"victimname",tempName,MLN);
	
	if(!StrEqual(tempName,"Infected")){
		int idDeath = GetClientOfUserId(GetEventInt(event,"userid"));
		int temp = GetEntProp(idDeath, Prop_Send, "m_zombieClass");
		for(int i=0;i<PlayerCount;i++){
				if(idUser[i] == idKiller){
					if(l4d == Engine_Left4Dead && temp >= 1 && temp <= 5){
						exp[i]+=1;
						if(exp[i] >= ExpNext[i]){
							char temps[MLN];
							GetClientAuthId(idKiller, AuthId_Steam2, temps, MLN);
							nextLevel(idKiller, temps);
						}
						return Plugin_Handled;
					}if(l4d == Engine_Left4Dead2 && temp >= 1 && temp <= 8){
						exp[i]+=1;
						if(exp[i] >= ExpNext[i]){
							char temps[MLN];
							GetClientAuthId(idKiller, AuthId_Steam2, temps, MLN);
							nextLevel(idKiller, temps);
						}
						return Plugin_Handled;
					}
				}
			}
		}
	return Plugin_Handled;
}

// szuka gracza o podanym steamid w bazie danych
bool SearchDatabasePlayer(const int client, const char[] steamids){
	// sprawdza czy mysql nie jest nullem i czy client nie jest przypadkiem 0 serwerowym id
	if(Mysql == INVALID_HANDLE || client <= 0 || !IsClientConnected(client))return false;
	char temp[Query];
	Format(temp, Query, "SELECT ID,name,steamid,exp,expNext,level,skillsPoints,healthPlayer,speed FROM playerStats WHERE steamid='%s';",steamids);
	SQL_TQuery(Mysql,SearchPlayer,temp,client);
	return true;
}
public void SearchPlayer(Handle owner, Handle hndl, const char[] error, any clie){
	if(hndl == INVALID_HANDLE){LogError("This some error in database: %s",error);return;}
	else if(clie <= 0 || !IsClientAuthorized(clie))return;
	char nameGive[MLN];
	char steamidss[MLN];
	char Querend[Query];
	GetClientName(clie,nameGive,MLN);
	GetClientAuthId(clie,AuthId_Steam2,steamidss,MLN);
	
	if(SQL_FetchRow(hndl)){
		for(int i=0;i<PlayerCount;i++){
			if(idUser[i] == clie && IsClientConnected(clie) && IsClientInGame(clie)){
				exp[i]=SQL_FetchInt(hndl,3);
				ExpNext[i]=SQL_FetchInt(hndl,4);
				levels[i]=SQL_FetchInt(hndl,5);
				SkillsPoints[i]=SQL_FetchInt(hndl,6);
				health[i]=SQL_FetchInt(hndl,7);
				Speed[i]=SQL_FetchFloat(hndl,8);
				PrintToServer("Speed: %f",Speed[i]);
				Format(Querend,Query,"UPDATE playerStats SET name='%s' WHERE steamid='%s'",nameGive,steamidss);
				SQL_FastQuery(Mysql,Querend);
				return;
			}
		}
	}else{
		char newVarsx[256];
		// dodajemy do bazy danych uzytkownika
		// statystyki:
		// 0 exp, 200 do nastepnego level'a, 1 level, 0 skillpoint, 100 zycia (podstawowe)
		Format(newVarsx, 256, "INSERT INTO playerStats(name,steamid, exp, expNext, level, skillsPoints, healthPlayer, speed) VALUES('%s','%s','0','200','1','0','100','1.0')",nameGive,steamidss);
		SQL_FastQuery(Mysql,newVarsx);
		for(int i=0;i<PlayerCount;i++){
			if(idUser[i] == clie && IsClientConnected(clie) && IsClientInGame(clie)){
				exp[i]=0;
				ExpNext[i]=200;
				levels[i]=1;
				SkillsPoints[i]=0;
				health[i]=100;
				Speed[i]=1.0;
				return;
			}
		}
	}
	return;
}
// funkcja glowna ktora zapisuje statystyki gracza w bazie danych
void SaveStatsDataBase(const int client, const char[] steamids){
	// sprawdza czy mysql nie jest nullem i czy client nie jest przypadkiem 0 serwerowym id
	if(Mysql == INVALID_HANDLE || client <= 0 || !IsClientConnected(client) && !IsClientAuthorized(client))return;
	char temp[Query];
	int num=0;
	for(int i=0;i<PlayerCount;i++){if(idUser[i]==client)num=exp[i];}
	Format(temp, Query, "UPDATE playerStats SET exp=%d WHERE steamid='%s';",num,steamids);
	SQL_FastQuery(Mysql, temp);
}

// leveluje nam konto jak zdobedziemy wystarczajaco duzo exp
void nextLevel(const int client, const char[] steamid){
	if(Mysql == INVALID_HANDLE || client <= 0 || !IsClientConnected(client))return;
	char temp[Query];
	// jesli aktualny exp jest wieksze lub rowne expnext do awansuj gracza na
	//wyzszy poziom
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i]==client){
				if(exp[i] != 0 && ExpNext[i] != 0 && exp[i] >= ExpNext[i]){
				exp[i] -= ExpNext[i];
				levels[i]= levels[i] + 1;
				ExpNext[i] *= Exp_Multiplier;
				SkillsPoints[i]+=Skill_Point_Level;
				Format(temp,Query,"UPDATE playerStats SET exp=%d, expNext=%d, level=%d, skillsPoints=%d WHERE steamid='%s';",exp[i],ExpNext[i],levels[i],SkillsPoints[i],steamid);
				bool Success = SQL_FastQuery(Mysql,temp);
				if(Success){PrintToChatAll("\x04%N\x01 leveled up!",client);return;}
			}
		}
	}
}
// sprawdzamy za pomoca komendy /ss w grze nasz postep (exp, exp do nastepnego, level, punkty umiejetnosci)
public Action statsCheck(int client, int args){
	if(client <= 0)return Plugin_Handled;
	ShowStats(client);
	return Plugin_Continue;
}
void ShowStats(const int client){
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] == client){
			char temp[128];
			Format(temp,sizeof(temp),"\x04EXP\x01: [%d/%d], \x04LEVEL\x01: %d, \x04SKILL POINT\x01: %d",exp[i],ExpNext[i],levels[i],SkillsPoints[i]);
			PrintToChat(client,temp);
			return;
		}
	}
}

// funkcja zapisuje co iles tam minut statystyki graczom w bazie danych.
public Action SaveStats(Handle timer, any data){
	char temp[MLN];
	// zapisuj statystyki wszystkim graczom i daj 5 exp'a
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] != 0){
			exp[i]+=5;
			GetClientAuthId(idUser[i],AuthId_Steam2,temp,MLN);
			if(exp[i] >= ExpNext[i]){
				nextLevel(idUser[i], temp);
			}else SaveStatsDataBase(idUser[i], temp);
		}
	}
	PrintToChatAll("Stats saved for all players");
	PrintToChatAll("Everyone on the server get 5 Exp");
	PrintToChatAll("\x03New? server commands:\x01");
	PrintToChatAll("\x04/top100level, /top100exp - top players\x01");
	PrintToChatAll("\x04/ss - check stats\x01");
	PrintToChatAll("\x04/shop - buy items\x01");
	PrintToChatAll("\x04/skills - train your character\x01");
	return Plugin_Continue;
}

// funkcja te shopBuy, WeaponShops, BuyWeapon umozliwiaja za exp kupienie broni
public Action shopBuy(int client, int args){
	if(client <= 0)return Plugin_Handled;
	Menu weaponShop = new Menu(WeaponShops);
	weaponShop.SetTitle("Item Shop");
	// bronie do l4d
	if (l4d == Engine_Left4Dead){
		weaponShop.AddItem("pistol","Pistol");
		weaponShop.AddItem("smg","Submachine Gun");
		weaponShop.AddItem("pumpshotgun","Pump Shotgun");
		weaponShop.AddItem("autoshotgun","Auto Shotgun");
		weaponShop.AddItem("rifle","Assault Rifle");
		weaponShop.AddItem("hunting_rifle","Hunting Rifle");
		weaponShop.AddItem("molotov","Molotov Cocktail");
		weaponShop.AddItem("pipe_bomb","Pipe Bomb");
		weaponShop.AddItem("ammo","Ammo");
		weaponShop.AddItem("pain_pills","pain pills");
		weaponShop.AddItem("first_aid_kit","First aid kit");
	}else if (l4d == Engine_Left4Dead2){
		// bronie do l4d2
		weaponShop.AddItem("weapon_pistol","Pistol");
		weaponShop.AddItem("weapon_smg","Submachine Gun");
		weaponShop.AddItem("weapon_shotgun_chrome","Chrome Shotgun");
		weaponShop.AddItem("weapon_pumpshotgun","Pump Shotgun");
		weaponShop.AddItem("weapon_autoshotgun","Tactical Shotgun");
		weaponShop.AddItem("weapon_rifle","Assault Rifle");
		weaponShop.AddItem("weapon_hunting_rifle","Hunting Rifle");
		weaponShop.AddItem("weapon_smg_mp5","MP5");
		weaponShop.AddItem("weapon_pistol_magnum","Magnum Pistol");
		weaponShop.AddItem("weapon_shotgun_spas","Combat Shotgun");
		weaponShop.AddItem("weapon_sniper_military","Sniper Rifle");
		weaponShop.AddItem("weapon_rifle_sg552","M16 Assault Rifle");
		weaponShop.AddItem("weapon_rifle_desert","Combat Rifle");
		weaponShop.AddItem("weapon_sniper_scout","Scout");
		weaponShop.AddItem("weapon_sniper_awp","AWP");
		weaponShop.AddItem("weapon_rifle_ak47","AK-47");
		weaponShop.AddItem("weapon_grenade_launcher","Grenade Launcher");
		weaponShop.AddItem("weapon_rifle_m60","M60 Machine Gun");
		weaponShop.AddItem("weapon_chainsaw","Chainsaw");
		weaponShop.AddItem("weapon_molotov","Molotov Cocktail");
		weaponShop.AddItem("weapon_pipe_bomb","Pipe Bomb");
		weaponShop.AddItem("weapon_vomitjar","Vomitjar");
		weaponShop.AddItem("weapon_pain_pills","Pain Pills");
		weaponShop.AddItem("weapon_first_aid_kit","First Aid Kit");
		weaponShop.AddItem("weapon_adrenaline","Adrenaline");
		weaponShop.AddItem("weapon_defibrillator","Defibrillator");
		weaponShop.AddItem("ammo","ammo");
	}
	
	weaponShop.ExitBackButton = true;
	weaponShop.ExitButton = true;
	weaponShop.Display(client, 30);
	
	return Plugin_Handled;
}
public int WeaponShops(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	
	if(action == MenuAction_Select){
		char temp[MLN];
		char temp2[MLN];
		bool buyWeapon = menu.GetItem(param2,temp,MLN,_,temp2,MLN);
		if(buyWeapon)BuyWeapon(param1, temp2, param2, temp);
	}else if(action == MenuAction_End)delete menu;
	return 0;
}

void BuyWeapon(const int client, const char[] weaponName, const int weaponID, const char[] weapon){
	if (client <= 0) return;
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] == client){
			if(exp[i] >= WeaponCost[weaponID] && LimitsWeapon[i] > 0 && LimitsWeapon[i] <= 3){
				new flags = GetCommandFlags("give");
				exp[i]-=WeaponCost[weaponID];
				SetCommandFlags("give", flags & ~FCVAR_CHEAT);
				FakeClientCommand(client, "give %s", weapon);
				SetCommandFlags("give", flags|FCVAR_CHEAT);
				PrintToChatAll("%N buyed %s from shop!", client, weaponName);
				PrintToChat(client,"\x04you lost %d experience, now you currently: %d experience\x01",WeaponCost[weaponID],exp[i]);
				LimitsWeapon[i]-=1;
				return;
			}else if(exp[i] >= WeaponCost[weaponID] || LimitsWeapon[i] <= 0){
				PrintToChat(client,"\x04the limit per round is %d for buying items!",LIMITS);
			}else {PrintToChat(client, "\x04You have %d experience, this item prince: %d experience\x01",exp[i],WeaponCost[weaponID]);return;}
		}
	}
}

// funkcje takie jak: (TOP10Exp, TOP100E, TOP100Level, TOP100L) - wyswietlaja top graczy wedle level'a lub exp.
public Action TOP100Exp(int client, int args){
	if(client <= 0)return Plugin_Handled;
	char temp[Query];
	char names[MLN];
	char tempform[64];
	int exps=0;
	int i=1;
	
	Menu checkTop = new Menu(TOP100E);
	checkTop.SetTitle("TOP 100 players: experience");
	
	Format(temp,Query,"SELECT name,exp FROM playerStats ORDER BY exp DESC LIMIT 100;");
	DBResultSet result = SQL_Query(Mysql,temp);
	if(result == INVALID_HANDLE){CloseHandle(result);return Plugin_Handled;}
	while(SQL_FetchRow(result))
	{
		SQL_FetchString(result,0,names,MLN); // pobiera nazwe z wiersza
		exps = SQL_FetchInt(result,1); // pobiera exp z wiersza
		Format(tempform,sizeof(tempform),"(%d. %s, Experience: %d)",i,names,exps);
		checkTop.AddItem("0",tempform);
		i++;
	}
	CloseHandle(result);

	checkTop.ExitBackButton = true;
	checkTop.ExitButton = true;
	checkTop.Display(client,60);
	
	return Plugin_Handled;
}
public int TOP100E(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	
	//if(action == MenuAction_Start){
		// tutaj umieszcze informacje o graczu
	if(action == MenuAction_End)delete menu;
	
	return 0;
}

public Action TOP100Level(int client, int args){
	if(client <= 0)return Plugin_Handled;
	char temp[Query];
	char names[MLN];
	char tempform[64];
	int exps=0;
	int i=1;
	
	Menu checkTop = new Menu(TOP100L);
	checkTop.SetTitle("TOP 100 players: level");
	
	Format(temp,Query,"SELECT name,level FROM playerStats ORDER BY level DESC LIMIT 100;");
	DBResultSet result = SQL_Query(Mysql,temp);
	if(result == INVALID_HANDLE){CloseHandle(result);return Plugin_Handled;}
	while(SQL_FetchRow(result))
	{
		SQL_FetchString(result,0,names,MLN); // pobiera nazwe z wiersza
		exps = SQL_FetchInt(result,1); // pobiera exp z wiersza
		Format(tempform,sizeof(tempform),"(%d. %s, level: %d)",i,names,exps);
		checkTop.AddItem("0",tempform);
		i++;
	}
	CloseHandle(result);

	checkTop.ExitBackButton = true;
	checkTop.ExitButton = true;
	checkTop.Display(client,60);
	
	return Plugin_Handled;
}
public int TOP100L(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	if(action == MenuAction_End)delete menu;
	return 0;
}
// gdy gracz sie respawni na serwerze dostaje z bazy danych statystyki
public Action spawning(Event event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsFakeClient(client))return Plugin_Handled;
	CreateTimer(2.0, spawnClient, client);
	return Plugin_Handled;
}
public Action spawnClient(Handle timer, any userID){
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i]==userID){
			SetEntProp(userID, Prop_Data, "m_iHealth",health[i]);
			SetEntProp(userID, Prop_Data, "m_iMaxHealth",health[i]);
			SetEntDataFloat(userID,regulate_speed, Speed[i], true);
		}
	}
	return Plugin_Continue;
}
public Action roundSpawn(Event event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsFakeClient(client))return Plugin_Handled;
	CreateTimer(2.0, roundspawned, client);
	return Plugin_Handled;
}
// zapobiega utracie po wejsciu do nastepnej strefy (umiejetnosci specjalnych).
public Action roundspawned(Handle timer, any userID)
{
	for(int i=0;i<PlayerCount;i++){
	if(idUser[i] == userID){
			SetEntProp(userID, Prop_Data, "m_iMaxHealth",health[i]);
			SetEntDataFloat(userID,regulate_speed, Speed[i], true);
		}
	}
	return Plugin_Continue;
}

//system zarzadzania skillami
public Action skillsSystem(int client, int args){
	if(client <= 0)return Plugin_Handled;
	Menu menu1 = new Menu(skillMenu1);
	for(int i=0;i<PlayerCount;i++){
		if(idUser[i] == client){
			menu1.SetTitle("SKILLS MENU,- Skill points: %d",SkillsPoints[i]);
		}
	}
	menu1.AddItem("SH","Increase Health");
	menu1.AddItem("SS","Increase Speed");
	menu1.ExitBackButton = true;
	menu1.ExitButton = true;
	menu1.Display(client,60);
	
	return Plugin_Handled;
}
public int skillMenu1(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	if(action == MenuAction_Select){
		char GetAction[MLN];
		bool isSuccess = menu.GetItem(param2,GetAction,MLN);
		if(isSuccess && StrEqual(GetAction,"SH")){
			Menu HealthI = new Menu(BuyHealthskillMenu1);
			HealthI.SetTitle("Did you wanna increase this Skill?");
			HealthI.AddItem("yes","Yes");
			HealthI.ExitButton = true;
			HealthI.Display(param1,60);
		}else if(isSuccess && StrEqual(GetAction,"SS")){
			Menu SpeedI = new Menu(BuySpeedskillMenu1);
			SpeedI.SetTitle("Did you wanna increase this Skill?");
			SpeedI.AddItem("yes","Yes");
			SpeedI.ExitButton = true;
			SpeedI.Display(param1,60);
		}
	}
	else if(action == MenuAction_End)delete menu;
	return 0;
}
public int BuyHealthskillMenu1(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	if(action == MenuAction_Select){
		char GetAction[MLN];
		bool isSuccess = menu.GetItem(param2,GetAction,MLN);
		if(isSuccess && StrEqual(GetAction,"yes") && Mysql != INVALID_HANDLE){
			for(int i=0;i<PlayerCount;i++){
				if(idUser[i] == param1){
					if(health[i] >= 200){PrintToChat(param1,"\x04You have reached the maximum level for this skill\x01");break;}
					else if(SkillsPoints[i] >= SkillHealth){
						SkillsPoints[i]-= SkillHealth;
						char temp[Query];
						char steamids[MLN];
						health[i]+=1;
						
						GetClientAuthId(param1, AuthId_Steam2, steamids, MLN);
						Format(temp,Query,"UPDATE playerStats SET healthPlayer='%d', SkillsPoints='%d' WHERE steamid='%s'",health[i],SkillsPoints[i],steamids)
						SQL_FastQuery(Mysql,temp);
						PrintToChat(param1,"\x04Increased your health by: %d\x01",SkillHealth);
						SetEntProp(param1, Prop_Data, "m_iMaxHealth",health[i]);
						menu.Display(param1,60);
					}else if(SkillsPoints[i] < SkillHealth){PrintToChat(param1,"\x04You don't have enough skill points to skilled this!\x01");}
				}
			}
		}
	}
	else if(action == MenuAction_End)delete menu;
	return 0;
}
public int BuySpeedskillMenu1(Menu menu, MenuAction action, int param1, int param2){
	if(param1 <= 0)return 0;
	if(action == MenuAction_Select){
		char GetAction[MLN];
		bool isSuccess = menu.GetItem(param2,GetAction,MLN);
		if(isSuccess && StrEqual(GetAction,"yes") && Mysql != INVALID_HANDLE){
			for(int i=0;i<PlayerCount;i++){
				if(idUser[i] == param1){
					if(Speed[i] >= 1.2){PrintToChat(param1,"\x04You have reached the maximum level for this skill\x01");break;}
					else if(SkillsPoints[i] >= SkillSpeed){
						SkillsPoints[i]-= SkillSpeed;
						char temp[Query];
						char steamids[MLN];
						Speed[i]+=GiveSpeed;
						
						GetClientAuthId(param1, AuthId_Steam2, steamids, MLN);
						Format(temp,Query,"UPDATE playerStats SET speed='%f', SkillsPoints='%d' WHERE steamid='%s'",Speed[i],SkillsPoints[i],steamids)
						SQL_FastQuery(Mysql,temp);
						PrintToChat(param1,"\x04Increased your speed by: %f\x01",GiveSpeed);
						SetEntDataFloat(param1,regulate_speed, Speed[i], true);
						menu.Display(param1,60);
					}else if(SkillsPoints[i] < SkillSpeed){PrintToChat(param1,"\x04You don't have enough skill points to skilled this!\x01");}
				}
			}
		}
	}
	else if(action == MenuAction_End)delete menu;
	return 0;
}