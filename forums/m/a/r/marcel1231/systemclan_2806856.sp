#include <sourcemod>
#include <sdkhooks>
public Plugin myinfo =
{
    name = "Clan System",
    author = "marcel",
    description = "Add to game simple system clan.",
    version = "1.0",
    url = ""
};

#define MAX_CLANS 999 // there are some limits for max available clan. Can here you change it for your server.
#define MAX_MEMBERS 4 // max members for clan
#define CLANS_PER_PAGE 4 // max clans displayed of a screen (listplayers and joinclans)
#if !defined MAXMENUITEMS
    #define MAXMENUITEMS 512
#endif

char g_szClanNames[MAX_CLANS][10]; // przechowujemy tymczasowe nazwy klanow
char specialChars[] = "!@#$%^&*()_+{}\"|<>?\0"; // Edit your special characters

Database Data; // don't delete it this handle to mysql connect
char Errors[256]; // przechwytuje bledy z bazy danych

bool checksVersion=false; // sprawdza czy do left4dead, czy left4dead2

//There are variables of pages for Listclans and Joinclan
int g_iCurrentPage[MAXPLAYERS + 1];
int g_iCurrentPage2[MAXPLAYERS + 1];
int g_iMenuItemClanIndex[MAXMENUITEMS];
int g_iMenuItemClanIndex2[MAXMENUITEMS];

// variables of points (rank clan system)
int SpecialZombieKills = 3; // special zombies (boomer,smoker,hunter)
int ZombieKills = 1; // infected (normal zombies)
int TankKill = 5; // tank
int WitchKill = 5; /// witch
ConVar ChecksDifficultMap; // check difficult level of map

// przechowuje nam statystyki gracza
int tableOfScore[MAXPLAYERS + 1];

// its for arrays simply system. You can change value of variables.
const int x = MAX_CLANS; // ilosc kolumn
const int y = 10; // ilosc wierszy

public void OnPluginStart()
{
if(GetEngineVersion() == Engine_Left4Dead2)
{
		checksVersion=true;
}
Data = SQL_DefConnect(Errors,sizeof(Errors));
RegConsoleCmd("createclan", MenuClan);
RegConsoleCmd("joinclan", MenuClan2);
RegConsoleCmd("listclan", MenuClan3);
RegConsoleCmd("leaveclan", MenuClan4);
RegConsoleCmd("top10clan", MenuClan5);
RegConsoleCmd("say", ClanSay);
HookEvent("player_death",Player_Death);
ChecksDifficultMap = FindConVar("z_difficulty");
if(ChecksDifficultMap != null){
		ChecksDifficultMap.AddChangeHook(ChangeLevelDifficultys);
	}
}

public void OnClientAuthorized(int client,const char[] auth)
{
	char name[32]; // nazwa gracza
	bool isNameExists;
	
	if(!IsFakeClient(client) && SearchClientDatabase(client,auth)==true){PrintToServer("You have Databased STEAMID!");return;}
	else if(client && (!IsFakeClient(client)) && auth[0]!='\0')
	{
		isNameExists=GetClientName(client,name,sizeof(name));
		if(isNameExists)
		{
			PrintToServer("ADDED TO DATABASE STEAMID: %s\n",auth);
			AddPlayerDatabase(client,auth,name);
		}
	}
}

public void OnMapStart()
{	
	if(Data == null || Data == INVALID_HANDLE)
	{
		Data = SQL_DefConnect(Errors,sizeof(Errors));
	}
}

public void OnClientConnected(int client)
{
	// resetujemy wartosc po dolaczeniu przez gracza punkty klanowe
	if(!IsFakeClient(client))tableOfScore[client]=0;
}

public Action:Player_Death(Handle:event, const String:name[],bool:dontBroadcast)
{
	char names[32];
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	GetEventString(event,"victimname",names,sizeof(names));
	
	if(attacker == 0)
	{
		return Plugin_Continue;
	}
	
	if(!IsFakeClient(attacker))
	{
		// jesli to zombie
		if(StrEqual(names,"Infected"))
		{
			tableOfScore[attacker] += ZombieKills;
		}
		//jesli to left4dead2 to dodajemy trzy zombie
		if(checksVersion == true)
		{
			if(StrEqual(names,"Charger"))
			{
				tableOfScore[attacker] += SpecialZombieKills;
			}
			else if(StrEqual(names,"Jockey"))
			{
				tableOfScore[attacker] += SpecialZombieKills;
			}
			else if(StrEqual(names,"Spitter"))
			{
				tableOfScore[attacker] += SpecialZombieKills;
			}
		}
		// jesli to specjalny zarazony
		if(StrEqual(names,"Boomer") || StrEqual(names,"Smoker") || StrEqual(names,"Hunter"))
		{
			tableOfScore[attacker] += SpecialZombieKills;
		}
		// jesli to tank
		if(StrEqual(names,"Tank"))
		{
			tableOfScore[attacker] += TankKill;
		}
		// jesli to witch
		if(StrEqual(names,"Witch"))
		{
			tableOfScore[attacker] += WitchKill;
		}
	}
}

// Sprawdza czy istnieje taki STEAMID w bazie danych i UPDATE nam nickname
bool SearchClientDatabase(int client,const char[] BufforSteamID)
{
	char buffer[256];
	char name[32];
	if(client && (!IsFakeClient(client)))
	{
		if(Data != INVALID_HANDLE)
		{
			if(!StrEqual(BufforSteamID,"null"))
			{
				Format(buffer,sizeof(buffer),"SELECT STEAMID FROM `players` WHERE STEAMID='%s';",BufforSteamID);
				DBResultSet result = SQL_Query(Data,buffer);
				if(result != INVALID_HANDLE)
				{
					int liczba = result.RowCount; // liczba wierszy nie moze byc rowna 0 !
					if(liczba != 0)
					{
						bool elo=GetClientName(client,name,sizeof(name));
						if(elo)
						{
							// jesli istnieje juz w bazie steamid klienta to update mu nickname
							Format(buffer,sizeof(buffer),"UPDATE players SET NAME='%s' WHERE STEAMID='%s'",name,BufforSteamID);
							bool prawda=SQL_FastQuery(Data,buffer);
							if(!prawda)
							{
								PrintToServer("some was error with save database");
							}
						}
						delete result;
						return true;
					}
				}else delete result;
			}
		}
	}
	return false;
}

// Dodaje nam punkty do klanu
bool AddPointsToDatabase(int client,char[] BufforSteamID)
{
	char buffer[256];
	int IDCLANs = 0; // przechowujemy tymczasowy id klanu gracza
	if(client && Data != INVALID_HANDLE)
	{
		Format(buffer,sizeof(buffer),"SELECT STEAMID,IDCLAN,PointP FROM players WHERE STEAMID='%s';",BufforSteamID);
		DBResultSet result = SQL_Query(Data,buffer);
		if(result == INVALID_HANDLE || result == null){delete result; return false;}
		int liczba = result.RowCount; // liczba wierszy nie moze byc rowna 0 !
		if(SQL_FetchRow(result) && liczba != 0)
		{
			IDCLANs = SQL_FetchInt(result,1);
			if(IDCLANs != 0)
			{
				delete result;
				Format(buffer,sizeof(buffer),"UPDATE players SET PointP=PointP+%d WHERE IDCLAN=%d AND STEAMID='%s'",tableOfScore[client],IDCLANs,BufforSteamID);
				SQL_FastQuery(Data,buffer);
				
				Format(buffer,sizeof(buffer),"UPDATE clans SET PointC=PointC+%d WHERE ID=%d",tableOfScore[client],IDCLANs);
				SQL_FastQuery(Data,buffer);
				return true;
			}
		}
		delete result;
	}
	return false;
}

// funkcja ta dodaje do bazy danych gracza
public void AddPlayerDatabase(int client,const char[] SteamID,const char[] name)
{
	char Inserto[256];
	if(Data != INVALID_HANDLE)
	{
		Format(Inserto,sizeof(Inserto),"INSERT INTO players(NAME, STEAMID) VALUES('%s','%s')",name,SteamID);
		bool prawda=SQL_FastQuery(Data,Inserto);
		if(!prawda)
		{
			char error[256];
			SQL_GetError (Data,error,sizeof(error));
			PrintToServer("ERROR: %s",error);
		}else {PrintToServer("succeed!");}
		
	}else PrintToServer("ERROR: %s",Errors);
}

// po rozlaczeniu przez gracza z gry zapisujemy dane do bazy danych
public void OnClientDisconnect(int client)
{
	bool isClient = IsClientAuthorized(client)
	char buffor[64];
	// sprawdzamy czy gracz nie jest botem i czy przeszedl pomyslnie weryfikacje klienta
	if((!IsFakeClient(client)) && isClient)
	{
		bool kupka = GetClientAuthId(client,AuthId_Steam2,buffor,sizeof(buffor));
		if(kupka)
		{
			bool ch = SearchClientDatabase(client,buffor);
			if(ch == true)
			{
				PrintToServer("Saved Database!");
				AddPointsToDatabase(client, buffor);
				tableOfScore[client]=0;
			}
		}else PrintToServer("You Don't Have STEAMID");
	}
}

// tworzy nam klan do bazy danych
public void CreateClanDatabase(const char[] NameClan,const int client)
{
	char buffer[256];
	char STEAMID[64];
	int IDName=0; // przechowuje id gracza w bazie danych
	int IDCLAN=0; // przechowuje id klanu w bazie danych
	
	if(Data != INVALID_HANDLE)
	{
		// sprawdza czy przypadkiem cos poszlo nie tak z uwierzytelnianiem id
		bool NotPrawda=GetClientAuthId(client,AuthId_Steam2,STEAMID,sizeof(STEAMID));
		if(!NotPrawda){PrintToServer("Some was error with authid\n");return;}
		
		// sprawdz, czy istnieje w bazie danych STEAMID o takim ID, jak nazwa id steam gracza
		Format(buffer,sizeof(buffer),"SELECT ID FROM players WHERE STEAMID='%s'",STEAMID);
		DBResultSet db = SQL_Query(Data,buffer);
		if (db != INVALID_HANDLE)
		{
			int rows = db.RowCount;
			if(rows <= 0){PrintToServer("No Found STEAMID");delete db;return;}
			else if(rows > 0){if(SQL_FetchRow(db))IDName = SQL_FetchInt(db,0);}
		}
		
		// wstaw do bazy danych klan
		Format(buffer,sizeof(buffer),"INSERT INTO clans(IDT,NAME,MinM,MaxM) VALUES('%d','%s','1','4')",IDName,NameClan);
		bool createClan = SQL_FastQuery(Data,buffer);
		
		// if success
		if(createClan)
		{
			IDCLAN = SQL_GetInsertId(Data);
			Format(buffer,sizeof(buffer),"UPDATE players SET IDCLAN='%d' WHERE STEAMID='%s'",IDCLAN,STEAMID);
			SQL_FastQuery(Data,buffer);
		}
		delete db;
		return;
	}
}

// sprawdza czy gracz nalezy do klanu jesli tak zwraca prawde
public bool isPlayerHaveClan(int client)
{
	char STEAMID[64];
	char buffor[256];
	if (Data != INVALID_HANDLE)
	{
		bool NotPrawda=GetClientAuthId(client,AuthId_Steam2,STEAMID,sizeof(STEAMID));
		if(NotPrawda)
		{
			Format(buffor,sizeof(buffor),"SELECT IDCLAN FROM players WHERE STEAMID='%s'", STEAMID);
			DBResultSet db = SQL_Query(Data,buffor);
			if(db != INVALID_HANDLE)
			{
				if(SQL_FetchRow(db) && SQL_GetRowCount(db) > 0 && SQL_FetchInt(db,0) > 0){delete db;return true;}
			}
			delete db;
		}
	}
	return false;
}

// sprawdza czy istnieje juz taka sama nazwa klanu co w bazie danych
public bool isClanNameExists(char[] nameClan)
{
	char names[128];
	int ilosc=0; // przechowuje bajty do skopiowania nazwy klanu w pamieci
	if(Data != INVALID_HANDLE)
	{
		DBResultSet db = SQL_Query(Data,"SELECT NAME FROM clans");
		if(db != INVALID_HANDLE)
		{
			while(SQL_FetchRow(db))
			{
				ilosc = SQL_FetchSize(db,0);
				SQL_FetchString(db,0,names,ilosc+1);
				if(StrEqual(names,nameClan) == true){delete db;return true;}
			}
			delete db;
		}
	}
	return false;
}

// sprawdza w bazie danych czy istnieje jakikolwiek klan
public bool isClansExists()
{
	if(Data != INVALID_HANDLE)
	{
		DBResultSet db = SQL_Query(Data,"SELECT * FROM clans");
		if(db != INVALID_HANDLE)
		{
			if(SQL_FetchRow(db) && SQL_GetFieldCount(db) > 0)
			{
				delete db;
				return true;
			}
			delete db;
		}
	}
	return false;
}

// wyswietla dostepne klany ( uwaga zaimplementowana funkcja powinna byc zadeklerowana tylko we funkcji OnMapStart() )!
public void PrintAvailableClan()
{
	ResetArray(g_szClanNames);
	char nameClan[128];
	int ilosc=0;
	int i = 0;
	if(Data != INVALID_HANDLE)
	{
		DBResultSet db = SQL_Query(Data,"SELECT NAME FROM clans");
		if(db != INVALID_HANDLE)
		{
			if(SQL_GetFieldCount(db) > 0)
			{
				while(SQL_FetchRow(db))
				{
					ilosc = SQL_FetchSize(db,0);
					SQL_FetchString(db,0,nameClan,ilosc+1);
					AddArray(g_szClanNames,nameClan,i);
					i++;
				}
				delete db;
			}
		}
	}
	return;
}

// dodaje do bazy danych nowego czlonka klanu o podanym id i przeszukuje wolne miejsce w klanie o podanej nazwie
public bool JoinClanDataBase(char[] NameClan,const int client)
{
	char nameClient[32];
	char STEAMID[64];
	char n[256];
	
	int MinCLAN=0;
	int MaxCLAN=0;
	int IDCLAN=0;
	
	if(Data != INVALID_HANDLE)
	{	
		bool NotPrawda=GetClientAuthId(client,AuthId_Steam2,STEAMID,sizeof(STEAMID));
		if(!NotPrawda)return false;
		
		bool names=GetClientName(client,nameClient,sizeof(nameClient));
		if(!names)return false;
		
		Format(n,sizeof(n),"SELECT * FROM clans WHERE NAME='%s'",NameClan);
		DBResultSet db = SQL_Query(Data,n);
		
		if(db != INVALID_HANDLE)
		{
			int rows = SQL_GetFieldCount(db);
			if(SQL_FetchRow(db) && rows > 0)
			{
				// dodaj do zmiennych pol odpowiednie ID z bazy danych
				MinCLAN=SQL_FetchInt(db,3);
				MaxCLAN=SQL_FetchInt(db,4);
				IDCLAN=SQL_FetchInt(db,0);
				
				if(MinCLAN < MaxCLAN)
				{
					Format(n,sizeof(n),"UPDATE players SET IDCLAN='%d' WHERE STEAMID='%s'",IDCLAN,STEAMID);
					db = SQL_Query(Data,n);
					if(db == INVALID_HANDLE){delete db;return false;}
					
					Format(n,sizeof(n),"UPDATE clans SET MinM=MinM+1 WHERE NAME='%s'",NameClan);
					bool s = SQL_FastQuery(Data,n);
					if(!s){delete db;return false;}
				}else if(MinCLAN >= MaxCLAN)
				{
					PrintToChat(client,"Sorry, this clan is full.");
					delete db;
					return false;
				}
				
				delete db;
				return true;
			}
		}
	}
	return false;
}

//funkcja ta opuszcza przez gracza klan i zmienia wartosci w bazie danych
public int LeaveTheClanDataBase(const int client,char[] names)
{
	char STEAMID[32];
	char buffer[256];
	
	int IDCLANs=0; // zapisujemy ID clanu ktory uzytkownik ma
	int ID=0; // ID uzytkownika w bazie danych.
	int temp=0;
	
	if(Data != INVALID_HANDLE)
	{
		bool NotPrawda=GetClientAuthId(client,AuthId_Steam2,STEAMID,sizeof(STEAMID));
		if(!NotPrawda)return 0;
		
		// to zmiennych (IDCLANs i ID) wypisz z bazy danych..
		Format(buffer,sizeof(buffer),"SELECT ID,IDCLAN FROM players WHERE STEAMID='%s'",STEAMID);
		DBResultSet db = SQL_Query(Data,buffer);
		if(db == INVALID_HANDLE){delete db;return 0;}
		
		int rows = db.RowCount;
		if(SQL_FetchRow(db) && rows > 0)
		{
			ID=SQL_FetchInt(db,0);
			IDCLANs=SQL_FetchInt(db,1);
			delete db;
			
			//jesli gracz ktory chce wyjsc jest zalozycielem klanu
            //automatycznie usun klan i wyrzuc graczy
			Format(buffer,sizeof(buffer),"SELECT IDT,NAME FROM clans WHERE ID=%d",IDCLANs);
			db = SQL_Query(Data,buffer);
			if(db == INVALID_HANDLE){delete db;return 0;}
			int rows1 = db.RowCount;
			if(SQL_FetchRow(db) && rows1 > 0)
			{
				temp=SQL_FetchInt(db,0);
				SQL_FetchString(db, 1, names, 32);
				// sprawdz czy id gracza rowna sie id zalozyciela
				// jesli tak.. to usun caly klan w raz uzytkownikami, w klanie.
				if((temp != 0 && ID != 0) && temp == ID )
				{
					delete db;
					Format(buffer,sizeof(buffer),"DELETE FROM clans WHERE ID=%d",IDCLANs);
					db = SQL_Query(Data,buffer);
					if(db == INVALID_HANDLE){delete db;return 0;}
					
					Format(buffer,sizeof(buffer),"UPDATE players SET IDCLAN=0,PointP=0 WHERE IDCLAN=%d",IDCLANs);
					bool s = SQL_FastQuery(Data,buffer);
					if(!s){delete db;return 0;}					
					
					delete db;
					return 1;
				}
				// jesli gracz to zwykly gracz ktory dolaczyl to normalnie usun z klanu..
				else
				{
					Format(buffer,sizeof(buffer),"UPDATE players SET IDCLAN=0,PointP=0 WHERE STEAMID='%s'",STEAMID);
					bool s = SQL_FastQuery(Data,buffer);
					if(!s){delete db;return false;}
					
					Format(buffer,sizeof(buffer),"UPDATE clans SET MinM=MinM-1 WHERE ID=%d",IDCLANs);
					bool b = SQL_FastQuery(Data,buffer);
					if(!b){delete db;return false;}
					
					delete db;
					return 2;
				}
			}
			delete db;
		}
		
	}
	return 0;
}

// zwraca nam nazwe klanu gracza
bool GiveNameClan(const int client,char[] names)
{
	char nameClans[32];
	char STEAMID[64];
	char buffer[256];
	
	int IDCLAN=0;
	int copybajt=0;
	
	if(Data != INVALID_HANDLE)
	{
		bool NotPrawda=GetClientAuthId(client,AuthId_Steam2,STEAMID,sizeof(STEAMID));
		if(!NotPrawda)return false;
		
		Format(buffer,sizeof(buffer),"SELECT IDCLAN FROM players WHERE STEAMID='%s'",STEAMID);
		DBResultSet db = SQL_Query(Data,buffer);
		if(db == INVALID_HANDLE){delete db;return false;}
		
		int rows = SQL_GetFieldCount(db);
		if(SQL_FetchRow(db) && rows > 0)
		{
			IDCLAN=SQL_FetchInt(db,0);
			
			if(IDCLAN != 0)
			{
				CloseHandle(db);
				Format(buffer,sizeof(buffer),"SELECT * FROM clans WHERE ID='%d'",IDCLAN);
				db = SQL_Query(Data,buffer);
				if(db == INVALID_HANDLE){return false;}
				
				int rows2 = SQL_GetFieldCount(db);
				if(SQL_FetchRow(db) && rows2 > 0)
				{
					copybajt = SQL_FetchSize(db,2);
					SQL_FetchString(db,2,nameClans,copybajt+1);
					for(int i=0;i<copybajt;i++)names[i]=nameClans[i];
					
					delete db;
					return true;
				}
			}
		}
		delete db;
	}
	return false;
}

void GetMembersClan(char[] infos,char[][] tabs,int[] points)
{
	char buffor[256];
	int copybajt=0;
	int idscan=0;
	
	if(Data != INVALID_HANDLE)
	{
		//szukamy ID w bazie danych wybranego przez nas klanu jesli znajdziemy przepisujemy jego ID to zmiennej idscan
		Format(buffor,sizeof(buffor),"SELECT ID, NAME FROM clans WHERE NAME='%s'",infos);
		DBResultSet db = SQL_Query(Data,buffor);
		if(db == INVALID_HANDLE){delete db;return;}
		int rowss = db.RowCount;
		if(SQL_FetchRow(db) && rowss > 0)
		{
			idscan=SQL_FetchInt(db,0);
			if(idscan==0){delete db;return;}
		}
		delete db;//zamykamy
		
		Format(buffor,sizeof(buffor),"SELECT NAME, IDCLAN,PointP FROM players WHERE IDCLAN='%d'",idscan);
		db = SQL_Query(Data,buffor);
		if(db == INVALID_HANDLE){delete db;return;}
		int rows = db.RowCount;
		int zero=0;
		char temp[33];
		if(rows > 0)
		{
			while(SQL_FetchRow(db))
			{
				copybajt = SQL_FetchSize(db,0);
				SQL_FetchString(db,0,temp,copybajt+1);
				points[zero] = SQL_FetchInt(db,2);
				for(int i=0;i<33;i++)
				{
					if(temp[i]=='\0')break;
					tabs[zero][i]=temp[i];
				}
				PrintToServer("NAME: %s",tabs[zero]);
				zero++;
			}
		}
		delete db;
	}
}

// Maly system zarzadzania tablicami dwuwymiarowymi (Opcjonalne dodane)
// wypisuje nam wszystkie elementy w tablicydwuwymiarowej
public void PrintArray(char[][] tab)
{
	PrintToServer("      DATA");
	PrintToServer("-----------------");
	// wypisz dane
	for(int i=0;i<x;i++){
		// jesli element w tablicy o indexie i jest rozny od zerowego miejsca
		// to wypisz z wiersza dane za pomoca petli
		if(tab[i][0]!='\0'){
			for(int j=0;j<y;j++){
				if(tab[i][j]!='\0')
				PrintToServer("Data: %c, || index: %d",tab[i][j],i);
			}
		}
	}
	PrintToServer("-----------------\n");
	PrintToServer("\n");
}

// zlicza nam ilosc w danym indeksie jest elementow w tablicy dwuwymiarowej i zwraca wynik
public int ChecksElementsTab(char[][] tab,int index)
{
	if(tab[index][0]=='\0')return 0;
	int i = 0;
	int il=0;
	while(i != 100)
	{
		if(tab[index][il] == '\0')break;
		i=0;
		il++;
	}
	return il;
}

//	dodaje nam element na dany index
public void AddArray(char[][] tab,const char[] ss,const int index)
{
	// warunek ktory sprawdza czy tablica ss jest zainicjalizowana jakims elementami
	if(ss[0]=='\0'){PrintToServer("Second argument need be initialized with data!");return;}
	
	// warunek sprawdza czy index jest poza zakresem od 0 do (10)-1, koncowy element jest zarezerwowany dla \0
	else if(index >= x || index <0)
	{
		PrintToServer("Your index is so high/low than its ur: %d !\n",x);
		PrintToServer("Remember you need index: 0 to (%d - 1).\n",x);
		return;
	}
	
	else if(tab[0][0]=='\0')
	{
		//PrintToServer("You dont have initiated any element so this index are going to: 0\n");
		for(int i=0;i<y;i++){
		tab[0][i]=ss[i];
		}
		return;
	}
	
	else if(tab[index][0]=='\0')
	{
		char maks[256];
		Format(maks,256,"and copied your data: %c, %c",ss[0],ss[1]);
		for(int j=0;j<y;j++)
		{
		tab[index][j]=ss[j];
		}
		return;
	}
}

// funkcja resetuje nam tablice dwuwymiarowa
public void ResetArray(char[][] tab)
{
	for(int i=0;i<x;i++)
	{
		for(int j=0;j<y;j++)
		{
			tab[i][j]='\0';
		}
	}
}

// funkcja usuwa element z tablicy we wskazanym indeksie
public void DeleteArray(char[][] tab,const int index)
{
	if(tab[0][0]=='\0')
	{
		PrintToServer("You dont have initiated any element!\n");
		return;
	}
	
	else if(index >= x || index <0)
	{
		PrintToServer("Your index is so high/low than its ur: %d !\n",x);
		PrintToServer("Remember you need index: 0 to (%d - 1).\n",x);
		return;
	}
	
	else if(tab[index][0] != '\0')
	{
		PrintToServer("Element are deleted from index: %d\n",index);
		for(int i=0;i<y;i++)
		{
			tab[index][i]='\0';
		}
		return;
	}
	PrintToServer("Element does not exist index: %d\n",index);
}

// add tag name if player are in any clan
public Action ClanSay(int client, int args)
{
	char name[30]; // variable for name
	char testwiad[64]; // variable for messages
	char nameClans[64];
	char buffer[512]; // variable for tag name
	
	
	// if client does exists and arguments are not equal to -1 or lower
	if(client && args >= 0)
	{
		if(isPlayerHaveClan(client))
		{
			GiveNameClan(client,nameClans);
			GetClientName(client,name,sizeof(name));
			GetCmdArgString(testwiad, sizeof(testwiad));
			testwiad[strlen(testwiad)-1] = '\0';
			ReplaceString(testwiad, sizeof(testwiad), "\"", "");
			Format(buffer,sizeof(buffer),"\x04[\x04%s]\x05%N\x01:  %s",nameClans,client,testwiad);
			PrintToChatAll(buffer);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// tworzy nowy klan
public Action MenuClan(int client, int args)
{

// sprawdza czy klient istnieje i czy podal jakikolwiek argument do komendy
if (client && (args > 0 && args < 2)){
char NameClan[128];
// sprawdza czy argument przez gracza jest poprawny.
if(args == 1)
{
	GetCmdArg(1,NameClan,sizeof(NameClan));
	
	// validacje podczas tworzenia klanu
	// sprawdza czy w bazie danych istnieje klan o tej samej nazwie
	if(isClanNameExists(NameClan) == true){PrintToChat(client,"A clan with the name %s already exists",NameClan);return Plugin_Handled;}
	
	// sprawdza czy gracz ma juz klan
	if(isPlayerHaveClan(client) == true){PrintToChat(client,"You are already a member of the clan");return Plugin_Handled;}
   
	//sprawdz, czy aby napewno uzytkownik nie podal przypadkowo znaku specjalnego lub liczbe w nazwie klanu.
	if(CSC(NameClan)){PrintToChat(client,"Please enter a valid name of clan, without special characters.");return Plugin_Handled;}
	//nazwa klanu musi zawierac od 4 do 9 liter.
	if(strlen(NameClan) < 4 || strlen(NameClan) > 9){PrintToChat(client,"The clan name must be (4-9) letters!");return Plugin_Handled;}

	CreateClan(client,NameClan);
}


 }else PrintToChat(client,"Please enter one argument(Name of your clan).");
return Plugin_Handled;
}


// maly system zarzadzania komendami
public Action MenuClan2(int client, int args)
{
JoinClan(client);
return Plugin_Handled;
}

// otwiera liste klanow
public Action MenuClan3(int client, int args)
{
ListClans(client);
return Plugin_Handled;
}
// jesli gracz chce wyjsc z klanu
public Action MenuClan4(int client, int args)
{
LeaveClan(client);
return Plugin_Handled;
}
// sprawdza nam 10 najlepszych klany wzgledem punktow
public Action MenuClan5(int client, int args)
{
TopClan(client);
return Plugin_Handled;
}
/////////////////////////////////////////////////

// funkcja sprawdza, czy nie wystepuje w tablicy char jakas liczba lub znak specjalny.
bool CSC(const char[] tab)
{
	int liczba = strlen(tab);
	int liczba2 = strlen(specialChars); // dlugosc znakow char specialChars[]
	
	for(int i=0;i<liczba; i++)
	{
	  if(IsCharNumeric(tab[i]))return true; // jesli podalismy liczbe lub liczby w nazwe klanu zwroc komunikat i wyjdz
	  
	  for(int j=0;j<liczba2;j++)
	  {
			if(tab[i]==specialChars[j]){return true;}
	  }
	}
	return false;
}

public void CreateClan(int client, const char[] szClanName)
{
// glowna mechanika tworzenia klanu
CreateClanDatabase(szClanName,client);
PrintToChatAll("[%N]: has created a new clan: %s", client, szClanName);
}

public void JoinClan(int client)
{
// Sprawdź, czy indeks klienta jest poprawny
if (client < 1 || client > MaxClients)
{
LogError("Invalid client index (%d)", client);
return;
}

// Sprawdź, czy klient jest połączony
if (!IsClientConnected(client))
{
LogError("Client %d is not connected", client);
return;
}
    
// Sprawdź, czy gracz już należy do klanu
if(isPlayerHaveClan(client) == true){PrintToChat(client,"You are already a member of the clan");return;}
	
// sprawdz czy istnieje jakis klan, jesli nie istnieje zwroc komunikat i wyjdz z funkcji.
if(isClansExists() == false){PrintToChat(client,"There are no are clan available!");return;}

// sprawdz czy w bazie danych jest jakis klan.
PrintAvailableClan();

// Dołączanie do klanu
Menu menu = new Menu(MenuHandler_JoinClan);
menu.SetTitle("Choose a clan to join:");
// Obliczanie liczby stron
int clansPerPage = 2;
int totalPages = (MAX_CLANS + clansPerPage - 1) / clansPerPage;
int currentPage = g_iCurrentPage[client];

// Zainicjuj tablicę indeksów klanów
for(int i = 0; i < MAXMENUITEMS; i++)
{
	g_iMenuItemClanIndex[i] = -1;
}

// Dodaj klany do menu i zaktualizuj tablicę indeksów klanów
int menuItemIndex = 0;
for(int i = currentPage * clansPerPage; i < (currentPage + 1) * clansPerPage; i++)
{
	if(g_szClanNames[i][0] != '\0')
	{
		menu.AddItem(g_szClanNames[i], g_szClanNames[i]);
		g_iMenuItemClanIndex[menuItemIndex] = i;
		menuItemIndex++;
	}
}
if(currentPage > 0)
{
    menu.AddItem("prev_page", "Previous page");
}

if(currentPage < totalPages - 1)
{
    menu.AddItem("next_page", "Next page");
}

menu.Display(client, 30);
}

public int MenuHandler_JoinClan(Menu menu, MenuAction action, int param1, int param2)
{
char names1[32];
char info[32];
bool success=false;
int clanIndex;
// Sprawdź, czy akcja menu to MenuAction_Select
if(action == MenuAction_Select)
{
	menu.GetItem(param2, info, sizeof(info));

	if(StrEqual(info, "next_page", false))
	{
		g_iCurrentPage[param1]++;
		JoinClan(param1);
	}
	else if(StrEqual(info, "prev_page", false))
	{
		g_iCurrentPage[param1]--;
		JoinClan(param1);
	}
	else
	{
		// Gracz wybrał klan do dołączenia
		clanIndex = g_iMenuItemClanIndex[param2];

		// Sprawdź, czy indeks klanu jest poprawny
		if(clanIndex < 0)
		{
			LogError("Invalid clan index (%d)", clanIndex);
			return 0;
		}
		
		if(JoinClanDataBase(info,param1))
		{
			// Gracz dołączył do klanu
			if(g_szClanNames[clanIndex][0]!='\0')
			{
				success=GetClientName(param1,names1,sizeof(names1));
				if(success)PrintToChatAll("[%N]: has joined the clan: %s", param1, g_szClanNames[clanIndex]);
			}
		}
	}
}
return 0;
}

public void LeaveClan(int client)
{
   int validates = 0; // zmienna ta przechowuje dwie wartosci, 1 to kreator klanu, 2 to zwykly gracz klanu.
   char clanName[32];
   // zwraca komunikat czy nie mamy przypadkiem klanu
   if(isPlayerHaveClan(client) == false)PrintToChat(client,"You are not a member of any clan.");
   
   //sprawdz czy istnieje jakis klan, jesli nie istnieje zwroc komunikat i wyjdz z funkcji.
   if(isClansExists() == false){PrintToChat(client,"There are no are clan available!");return;}
   
   // Opuszczanie klanu
   validates=LeaveTheClanDataBase(client,clanName);
   
   if(validates == 1){PrintToChatAll("a clan with name [%s], was deleted!",clanName);}
   else if(validates == 2){PrintToChatAll("player %N was leave clan %s.",client,clanName);}
}

// Jesli zmieniamy poziom trudnosci to takze punkty z zombiaków.
public void ChangeLevelDifficultys(ConVar difficults,const char[] oldValue, const char[] newValue)
{
	char namess[16];
	difficults.GetString(namess,sizeof(namess));
	if(StrEqual(namess,"Easy") || StrEqual(namess,"Normal"))
	{
		PrintToChatAll("Changed to easy/normal");
		SpecialZombieKills = 3;
		ZombieKills = 1;
		TankKill = 5;
		WitchKill = 5;
	}
	else if(StrEqual(namess,"Hard"))
	{
		PrintToChatAll("Changed to hard");
		SpecialZombieKills = 4;
		ZombieKills = 1;
		TankKill = 7;
		WitchKill = 7;
	}
	else if(StrEqual(namess,"Impossible"))
	{
		PrintToChatAll("Changed to expert");
		SpecialZombieKills = 5;
		ZombieKills = 1;
		TankKill = 10;
		WitchKill = 10;
	}
}

public void ListClans(int client)
{
// Sprawdź, czy indeks klienta jest poprawny
if (client < 1 || client > MaxClients)
{
LogError("Invalid client index (%d)", client);
return;
}

// Sprawdź, czy klient jest połączony
if (!IsClientConnected(client))
{
LogError("Client %d is not connected", client);
return;
}

// sprawdz czy istnieje jakis klan, jesli nie istnieje zwroc komunikat i wyjdz z funkcji.
if(!isClansExists){PrintToChat(client,"There are no are clan available!");return;}

// sprawdz czy w bazie danych jest jakis klan.
PrintAvailableClan();

// tworzy nam menu do przegladania klanowiczow w klanach
Menu menu2 = new Menu(MenuHandler);
menu2.SetTitle("List of clans:");
// Obliczanie liczby stron
int clansPerPage = 2;
int totalPages = (MAX_CLANS + clansPerPage - 1) / clansPerPage;
int currentPage = g_iCurrentPage2[client];

// Zainicjuj tablicę indeksów klanów
for(int i = 0; i < MAXMENUITEMS; i++)
{
	g_iMenuItemClanIndex2[i] = -1;
}

// Dodaj klany do menu i zaktualizuj tablicę indeksów klanów
int menuItemIndex = 0;
for(int i = currentPage * clansPerPage; i < (currentPage + 1) * clansPerPage; i++)
{
	if(g_szClanNames[i][0] != '\0')
	{
		menu2.AddItem(g_szClanNames[i], g_szClanNames[i]);
		g_iMenuItemClanIndex2[menuItemIndex] = i;
		menuItemIndex++;
	}
}

if(currentPage > 0)
{
    menu2.AddItem("prev_page", "Previous page");
}

if(currentPage < totalPages - 1)
{
    menu2.AddItem("next_page", "Next page");
}

menu2.Display(client, 30);
}

public int MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
char info[32];
char tempNamesClan[4][64];
int clanIndex;
int pointsClan[4];
// Sprawdź, czy akcja menu to MenuAction_Select
if(action == MenuAction_Select)
{
	menu.GetItem(param2, info, sizeof(info));

	if(StrEqual(info, "next_page", false))
	{
		g_iCurrentPage2[param1]++;
		ListClans(param1);
	}
	else if(StrEqual(info, "prev_page", false))
	{
		g_iCurrentPage2[param1]--;
		ListClans(param1);
	}
	else
	{
		// Gracz sprawdza klan
		clanIndex = g_iMenuItemClanIndex2[param2];

		// Sprawdź, czy indeks klanu jest poprawny
		if(clanIndex < 0 || clanIndex >= MAX_CLANS)
		{
			LogError("Invalid clan index (%d)", clanIndex);
			return 0;
		}
		
		GetMembersClan(info,tempNamesClan,pointsClan);
		
		PrintToChat(param1,"List of members:");
		// sprawdz nickname graczy w danym klanie
		if(tempNamesClan[0][0]=='\0'){return 0;}
		for(int i = 0; i < 4; i++)
		{
			if(tempNamesClan[i][0]=='\0')break;
			PrintToChat(param1,"%s: (Points): %d",tempNamesClan[i],pointsClan[i]);
		}
	}
}
return 0;
}

// funkcja wypisuje nam na chat top 10 najlepszych klanow wzgledem punktow
public void Get10TopClan(int client)
{
	char name[32];
	char n[256];
	int ilosc=0;
	
	if(Data != INVALID_HANDLE)
	{
		Format(n,sizeof(n),"SELECT PointC,NAME FROM clans ORDER BY PointC DESC LIMIT 10");
		PrintToChat(client,"TOP 10 Clan: (Points)");
		PrintToChat(client,"-----------------");
		DBResultSet db = SQL_Query(Data,n);
		if(db != INVALID_HANDLE)
		{
			while(SQL_FetchRow(db))
			{
				ilosc = SQL_FetchInt(db,0);
				SQL_FetchString(db,1,name,sizeof(name));
				PrintToChat(client,"Clan Name[%s]: Points:[%d]",name,ilosc);
			}
			PrintToChat(client,"-----------------");
			delete db;
		}
	}
}

public void TopClan(int client)
{
	Get10TopClan(client);
}