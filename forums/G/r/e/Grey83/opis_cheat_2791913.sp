#pragma semicolon 1

#include <multicolors>

Menu hMenu;

public Plugin myinfo =
{
	name = "Opis Cheat",
	author = "Danielek",
	description = "command !cheat show you Cheats on Serwers.",
	version = "1.0",
	url = "https://AlkoSkill.pl"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_cheat", Cmd_CheatMenu);

	hMenu = new Menu(Menu_Cheats);
	hMenu.SetTitle("[ Cheaty INFORMACJE ]");
	hMenu.AddItem("", "Niewidzialnosc");
	hMenu.AddItem("", "Aimbot");
	hMenu.AddItem("", "Wallhack");
	hMenu.AddItem("", "Nieskonczonosc Ammo");
	hMenu.AddItem("", "AutoBH");
	hMenu.AddItem("", "Dodatkowy Skok");
	hMenu.AddItem("", "Brak Obrazen w Glowe");
	hMenu.AddItem("", "Speed na Start");
	hMenu.AddItem("", "Grawitacja na Start");
	hMenu.AddItem("", "Powrot na Spawn");
	hMenu.AddItem("", "Redukcja Obrazen");
	hMenu.AddItem("", "HP na Start");
	hMenu.AddItem("", "Kasa na Start");
	hMenu.AddItem("", "Hp za Fraga");
	hMenu.AddItem("", "Ammo za Fraga");
	hMenu.ExitButton = true;
}

public Action Cmd_CheatMenu(int client, int args)
{
	if(client && IsClientInGame(client) && !IsFakeClient(client)) hMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Menu_Cheats(Menu menu, MenuAction action, int client, int item)
{
	if(action == MenuAction_Select) switch(item)
	{
		case  0:
			CPrintToChat(client, "{purple}Dostajesz 100% Niewidzialnosc i mozesz zabijac tylko z Kosy!");
		case  1:
			CPrintToChat(client, "{purple}Dziala na Zasadzie One Shot One Kill, Musisz kogos wtrafic aby Zabic!");
		case  2:
			CPrintToChat(client, "{purple}Widzisz Wszystkich Graczy Przez Sciane!");
		case  3:
			CPrintToChat(client, "{purple}Masz Nieskonczona Amuncje do Wszystkich Broni!");
		case  4:
			CPrintToChat(client, "{purple}Auto BunnyHop, Ciagle Mozesz, Skakac!");
		case  5:
			CPrintToChat(client, "{purple}Dostajesz Dodatkowe Skoki!.[Mozliwe do zdobycia od 1-5 Skokow]");
		case  6:
			CPrintToChat(client, "{purple}Nie Dostajesz Obrazen W Glowe od Przeciwnikow!,(Nie dziala na AIMBOTA)");
		case  7:
			CPrintToChat(client, "{purple}Otrzymujesz Wieksza Predkosc Chodzenia!,[Mozliwe do zdobycia od 1.2-2.7 Szybkosci]");
		case  8:
			CPrintToChat(client, "{purple}Otrzymujesz Wieksza Grawitacje!,[Mozliwe do zdobycia od 0,35-0,8 Grawitacji]");
		case  9:
			CPrintToChat(client, "{purple}Mozesz Powracac na Spawn co 15 Sekund, Kiedy wcisniesz Klawisz [F]!");
		case 10:
			CPrintToChat(client, "{purple}Redukuje Zadawane Tobie Obrazenia!,[Mozliwe do zdobycia od 0.40-0.70 Redukcji]");
		case 11:
			CPrintToChat(client, "{purple}Dostajesz Na Start HP!,[Mozliwe do zdobycia od 110-600 Hp]");
		case 12:
			CPrintToChat(client, "{purple}Dostajesz na Start Kase!,[Mozliwe do zdobycia od 12k-32k Kasy]");
		case 13:
			CPrintToChat(client, "{purple}Za kazdego Fraga Dostajesz Dane Hp!,[Mozliwe do zdobycia od 10-35 Hp]");
		case 14:
			CPrintToChat(client, "{purple}Za kazdego Fraga Dostajesz Ammo do Broni!");
	}

	return 0;
}