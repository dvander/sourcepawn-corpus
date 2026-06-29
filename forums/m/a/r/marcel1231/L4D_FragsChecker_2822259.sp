#include <sourcemod>
#define MLN 32

public Plugin myinfo =
{
	name = "[L4D]FragsChecker",
	author = "marcel",
	description = "Check Frags of (Smoker,Hunter,Boomer)",
	version = SOURCEMOD_VERSION,
	url = "http://www.sourcemod.net/"
};
// tutaj przechowujemy id uzytkownikow polaczonych na serwerze
// oznaczenia: (0 w idUser oznacza brak graczza zapisanego w tablicy).
int idUser[5]; // mozesz ustawic wartosc wszystkich graczy na serwerze polaczonych
// tutaj przechowujemy ilosc zabitych specjalnych zarazonych gracza
int Frags[5]; // mozesz ustawic wartosc wszystkich graczy na serwerze polaczonych

// Ogranicz sloty w tablicy do PlayerCount zmiennej
static int Slots; // od 0 do MaxClients

static int PlayerCount; // zlicz nam ilosc graczy (nie botow) na serwerze

EngineVersion l4d; // zmienna odpowiedzialna za sprawdzanie czy to l4d czy l4d2 gra

// funkcja ta dodaje uzytkownika do tablicy.
bool addUserID(const int client){
	char checkSteam[64];
	
	// sprawdzamy czy liczba miejsc zostala przekroczona i zwracamy bool'a.
	if(Slots >= PlayerCount){PrintToServer("Array cannot be add more users, limits slots exceeded!"); return false;}
	
	// sprawdzamy, czy to bot, czy nie? Jesli tak zwracamy false.
	if(IsFakeClient(client)){PrintToServer("This client are bot!"); return false;}

	// sprawdzamy czy ma "STEAM_" jesli nie ma zwracamy false
	GetClientAuthId(client,AuthId_Steam2,checkSteam,64);
	if(StrContains(checkSteam,"STEAM_") == -1){PrintToServer("non-steam Player"); return false;}
	
	// algorytm ten szuka wolnego miejsca w tablicy po czym...
	//zapisuje id clienta do tablicy.
	for(int i=1;i<=PlayerCount;i++){
		if(idUser[i] == 0){
			PrintToServer("Find slot for table!");
			idUser[i]=client;
			// inicjlizujemy tablice Frags
			Frags[i]=0;
			// inkrementujemy zmienna slots
			Slots++;
			
			return true;
		}else if(idUser[i] == client){
			// ten warunek sprawdza czy jest juz taki uzytkownik w tablicy
			//zapisany, jak tak to zwracamy false.
			PrintToServer("This user are in array!");
			return false;
		}
	}
	
	// w przeciwnym razie zwraca false i komunikat.
	PrintToServer("Can't Find slot!");
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
	for(int i=1;i<=PlayerCount;i++){
		if(idUser[i] == client){
			PrintToServer("Find user in array!");
			idUser[i]=0;
			Frags[i]=0;
			// dekrementujemy zmienna slots
			Slots--;
			if(PlayerCount <= 0 || i == PlayerCount)return true;
			for(int j=i;j<=PlayerCount;j++){
				for(int c=j;c<=PlayerCount;c++){
					if(idUser[j] == 0 && idUser[c] != 0){
						idUser[j]=idUser[c];
						Frags[j]=idUser[c];
						idUser[c]=0;
						Frags[c]=0;
					}
				}
			}
			PrintToServer("exit ok...");
			return true;
		}
	}
	
	PrintToServer("Can't find User in Array!");
	return false;
}

public void PluginInit()
{
	PlayerCount=0;
	Slots=0;
	// Inicjalizacja tablicy idUser zerami
	for (int i = 0; i < 5; i++)
	{
		idUser[i] = 0;
		Frags[i] = 0;
	}
}

public void OnPluginStart()
{
	RegConsoleCmd("frags",SayFrags);
	HookEvent("player_death",OnDeath);
	l4d = GetEngineVersion();
}
	
public void OnClientConnected(int client){
	char ipclient[18];
	GetClientIP(client,ipclient,sizeof(ipclient));
	if(!IsFakeClient(client) && !StrEqual(ipclient,"127.0.0.1")){
		PlayerCount++;
		addUserID(client);
	}
}

public void OnClientDisconnect(int client){
	if(!IsFakeClient(client)){
		deleteUserID(client);
		PlayerCount--;
	}
}

public Action SayFrags(int client, int args){
	ShowKills();
	return Plugin_Continue;
}

public void OnMapStart(){
	for(int i=1;i<PlayerCount;i++){
		idUser[i]=0;
		Frags[i]=0;
	}
	PlayerCount=0;
	Slots=0;
}

public Action OnDeath(Event event, const char[] name, bool dontBroadcast){
	int idKiller = GetClientOfUserId(GetEventInt(event,"attacker"));
	if(IsFakeClient(idKiller))return Plugin_Handled;
	char tempName[MLN];
	GetEventString(event,"victimname",tempName,MLN);
	
	if(!StrEqual(tempName,"Infected")){
		int idDeath = GetClientOfUserId(GetEventInt(event,"userid"));
		int temp = GetEntProp(idDeath, Prop_Send, "m_zombieClass");
		for(int i=1;i<=PlayerCount;i++){
				if(idUser[i] == idKiller){
					if(l4d == Engine_Left4Dead && temp >= 1 && temp <= 3){
						Frags[i]+=1;
						return Plugin_Handled;
					}if(l4d == Engine_Left4Dead2 && temp >= 1 && temp <= 6){
						Frags[i]+=1;
						return Plugin_Handled;
					}
				}
			}
		}
	return Plugin_Handled;
}

void ShowKills(){
	char names[MLN];
	char buffor[152]; // (8 = 256) dla 8 osob, (4 = 128) dla 4 osob (32 zarezerowowanych dla 1 osoby + 6 = 38)
	char text[38];
	int limitPlayer=1; // wyswietl tylko 4 graczy zapobiega spamem na chat.
	
	for(int i=1;i<=PlayerCount;i++){
		if(idUser[i] == 0)continue;
		else if(idUser[i] != 0 && limitPlayer <= 4){
			GetClientName(idUser[i],names,MLN);
			Format(text, sizeof(text), "\x04%s \x01%d ",names,Frags[i]);
			StrCat(buffor,sizeof(buffor),text);
			limitPlayer++;
		}
	}
	PrintToChatAll(buffor);
}