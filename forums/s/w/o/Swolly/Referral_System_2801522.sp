#include <sourcemod>
#include <store>

#pragma tabsize 0
//////////////////////////////////////////////////////////////////////////////////////
char Kodu[MAXPLAYERS + 1][16], Kullandigi_Kod[MAXPLAYERS + 1][16];
bool Engel[MAXPLAYERS + 1];
int Sure[MAXPLAYERS + 1];

Handle db = INVALID_HANDLE;
//////////////////////////////////////////////////////////////////////////////////////
ConVar c_Kodu_Kullanana, c_Kodu_Kullanana_Saatlik, c_Kodu_Kullanilana, c_Kodu_Kullanilana_Saatlik, c_Oto_Mesaj;
//////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = {
	name = "Referral System",
	author = "Swolly",
	description = "Referral System",
	url = "www.plugincim.com"
};
///////////////////////////////////////////////////////////////////////////////////////
public OnMapStart()
{
	//*************************************//		
	if(GetConVarFloat(c_Oto_Mesaj))
		CreateTimer(GetConVarFloat(c_Oto_Mesaj), Bilgi_Mesaji, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	//*************************************//			
}
///////////////////////////////////////////////////////////////////////////////////////	
public Action Bilgi_Mesaji(Handle Timer)
{
	//*************************************//			
	PrintToChatAll("[SM] \x0b!refinfo \x01You can get information about the open reference system.");			
	//*************************************//			
}
///////////////////////////////////////////////////////////////////////////////////////	
public OnPluginStart()
{
	//*************************************//			
	RegConsoleCmd("sm_usecode", Kod_Kullan);
	RegConsoleCmd("sm_createcode", Kod_Olustur);
	
	RegConsoleCmd("sm_ref", Referans);		
	
	RegConsoleCmd("sm_topref", Referans_Siralamasi);		
	RegConsoleCmd("sm_refinfo", Referans_Bilgi);	
	//*************************************//	
	c_Kodu_Kullanana = CreateConVar("ref_kod_kullanana", "1", "Give credit to the player who used the code?    0   ==  OFF");
	c_Kodu_Kullanana_Saatlik = CreateConVar("ref_kodu_kullanana_saatlik", "1", "How many credits per hour should be given to the player using the referral code?    0   ==  OFF");		
	
	c_Kodu_Kullanilana = CreateConVar("ref_kodu_kullanilana", "2", "How many credits should be given to the player whose code is used?    0   ==  OFF");	
	c_Kodu_Kullanilana_Saatlik = CreateConVar("ref_kodu_kullanana", "2", "How many credits per hour should be given to the player whose referral code is used?    0   ==  OFF");		
	
	c_Oto_Mesaj = CreateConVar("ref_bilgi_mesaji", "300.0", "In how many seconds should an information message be sent about the reference?");	
	
	AutoExecConfig(true, "Referral_System", "Plugincim_com");
	//*************************************//	
	DB_Baglan();
	//*************************************//		
	for (new i = 1; i <= MaxClients; i++) 
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
	//*************************************//		
}
//////////////////////////////////////////////////////////////////////////////////////





//////////////////////////////////////////////////////////////////////////////////////
public Action Kod_Kullan(client, args)
{
	//*************************************//	
	if(!StrEqual(Kullandigi_Kod[client], ""))
	{
		PrintToChat(client, "[SM] \x0fYou used a code before.");	
		
		if(StrEqual(Kodu[client], ""))
			PrintToChat(client, "[SM] \x0bTo create code:   \x01!createcode <code>");		
		
		return Plugin_Handled;
	}
	//*************************************//	
	
	
	
	
	//*************************************//		
	if(args == 1)
	{
		//************************************// 
		char SQL_Kodu[256], Kod[16], Sahibinin_Steam_ID[32];	
		GetCmdArg(1, Kod, 16);
		//*************************************//
		Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular WHERE kod = '%s'", Kod);
		Handle query = SQL_Query(db, SQL_Kodu);
		//*************************************//
		int Kullanan_Sayisi, Kazanilan_Kredi, Kazandirilan_Kredi, Biriken_Kredi;
		bool Var;		
		//*************************************//		
		if (query != INVALID_HANDLE)
		{
			//*************************************//	
			while(SQL_FetchRow(query) && !SQL_IsFieldNull(query, 0) && !Var)
			{
				SQL_FetchString(query, 0, Sahibinin_Steam_ID, 32);
				Kullanan_Sayisi = SQL_FetchInt(query, 5) + 1;
				Kazanilan_Kredi = SQL_FetchInt(query, 6) + GetConVarInt(c_Kodu_Kullanilana);
				Kazandirilan_Kredi = SQL_FetchInt(query, 7) + GetConVarInt(c_Kodu_Kullanana);
				Biriken_Kredi = SQL_FetchInt(query, 8) + GetConVarInt(c_Kodu_Kullanilana);
				
				Var = true;
			}
			//*************************************//								
			CloseHandle(query);
			//*************************************//				
		}
		//*************************************//
		if(Var)
		{
			//*************************************//			
			char Steam_ID[32];		
			GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));			
			//*************************************//			
			if(!StrEqual(Sahibinin_Steam_ID, Steam_ID))
			{
				//*************************************//	
				if(GetConVarInt(c_Kodu_Kullanana))
				{	
					//*************************************//									
					PrintToChat(client, "[SM] \x0b%s \x01The reference code was used. \x04%d you have earned credits.", Kod, GetConVarInt(c_Kodu_Kullanana));			
					Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(c_Kodu_Kullanana));
					//*************************************//								
				}
				else
					PrintToChat(client, "[SM] \x0b%s \x01The reference code was used.", Kod);			
				//*************************************//		
				if(GetConVarInt(c_Kodu_Kullanana_Saatlik))				
					CreateTimer(60.0, Sure_Ekle, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				//*************************************//							
				if(StrEqual(Kodu[client], ""))
					PrintToChat(client, "[SM] \x0bTo create your own code:  \x0f!createcode <code>");		
				//*************************************//	
				Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `kullandigi_kod` = '%s' WHERE steam_id = '%s';", Kod, Steam_ID);						  								
				SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);		
				//*************************************//	
				Kullandigi_Kod[client] = Kod;
				//*************************************//
					
				
				
				//*************************************//				
				char iSteam_ID[32];
				int Sahibi;
				//*************************************//								
				for (new i = 1; i <= MaxClients; i++) 
					if(IsValidClient(i))
					{
						GetClientAuthId(i, AuthId_SteamID64, iSteam_ID, sizeof(iSteam_ID));

						if(StrEqual(iSteam_ID, Sahibinin_Steam_ID))
							Sahibi = i;
					}	
				//*************************************//
				if(IsValidClient(Sahibi))
				{
					//*************************************//
					if(GetConVarInt(c_Kodu_Kullanilana))
						PrintToChat(Sahibi, "[SM] \x0b%N \x01used the reference code.  \x04%d you earned credit.", client, GetConVarInt(c_Kodu_Kullanilana));										
					//*************************************//				
				}
				//*************************************//				
				Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `kullanan` = %d, `kazanilan_kredi` = %d, `kazandirilan_kredi` = %d, `biriken_kredi` = %d WHERE kod = '%s';", Kullanan_Sayisi, Kazanilan_Kredi, Kazandirilan_Kredi, Biriken_Kredi, Kod);						  								
				SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
				//*************************************//						
			}
			else
				PrintToChat(client, "[SM] \x0fYou cannot use your own referral code.");
			//*************************************//				
		}	
		else
			PrintToChat(client, "[SM] \x0fReference code not found.");		
		//************************************// 	
	}
	else
		PrintToChat(client, "[SM] \x0bCommand Usage:  \x01!usecode <code>");
	//*************************************//





	//*************************************//	
	return Plugin_Handled;
	//*************************************//			
}
//////////////////////////////////////////////////////////////////////////////////////






//////////////////////////////////////////////////////////////////////////////////////
public Action Kod_Olustur(client, args)
{
	//*************************************//				
	if(!StrEqual(Kodu[client], ""))
	{
		PrintToChat(client, "\x0fYou already have your referral code. \x01!ref");
		return Plugin_Handled;
	}
	else
	{
		//************************************// 
		char SQL_Kodu[256], Kod[16];
		GetCmdArg(1, Kod, 16);
		//*************************************//
		Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular WHERE kod = '%s'", Kod);
		Handle query = SQL_Query(db, SQL_Kodu);
		//*************************************//
		bool Var;
			
		if (query != INVALID_HANDLE)
		{
			//*************************************//	
			while(SQL_FetchRow(query) && !SQL_IsFieldNull(query, 0) && !Var)
				Var = true;
			//*************************************//								
			CloseHandle(query);
			//*************************************//				
		}	
		//*************************************//												
		if(Var)
			PrintToChat(client, "[SM] \x0fThis reference code is being used by someone else.");
		else
		{
			//*************************************//
			PrintToChat(client, "[SM] \x04Successfully created reference code.");			
			//*************************************//				
			char Steam_ID[32];		
			GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));			
			//*************************************//								
			Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `kod` = '%s' WHERE steam_id = '%s';", Kod, Steam_ID);						  								
			SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);		
			//*************************************//	
			Kodu[client] = Kod;
			//*************************************//				
		}			
		//*************************************//
	}
	//*************************************//		
	return Plugin_Handled;
	//*************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////






//////////////////////////////////////////////////////////////////////////////////////
public Action Referans(client, args)
{
	//*************************************//
	if(Engel[client])
	{
		//*************************************//	
		PrintToChat(client, "[SM] \x0fYou cannot open this menu at this time.");		
		return Plugin_Handled;
		//*************************************//		
	}
	//*************************************//	
	char SQL_Kodu[256], Menu_Yazisi[256], Isim[16], Kod[16], Miktar[11];
	//*************************************//	
	if(args)
		GetCmdArg(1, Kod, 16);
	else
	if(!StrEqual(Kodu[client], ""))
		Kod = Kodu[client];
	else
	{
		//*************************************//	
		PrintToChat(client, "[SM] \x01Your reference code could not be found. To review other players' reference: !ref <code>");		
		return Plugin_Handled;
		//*************************************//		
	}
	//*************************************//
	Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular WHERE kod = '%s'", Kod);
	
	Handle query = SQL_Query(db, SQL_Kodu);
	Handle menuhandle = CreateMenu(Referans_);		
	//*************************************//
	int Var, Kullanan_Oyuncu, Kazanilan_Kredi, Kazandirilan_Kredi, Biriken_Kredi;
	
	if (query != INVALID_HANDLE)
	{
		//*************************************//		
		while(SQL_FetchRow(query) && !SQL_IsFieldNull(query, 0))
		{
			//*************************************//		
			if(!Var)
				Var = 1;
			//*************************************//		
			SQL_FetchString(query, 1, Isim, sizeof(Isim));
			
			Kullanan_Oyuncu = SQL_FetchInt(query, 5);
			Kazanilan_Kredi = SQL_FetchInt(query, 6);
			Kazandirilan_Kredi = SQL_FetchInt(query, 7);		
			Biriken_Kredi = SQL_FetchInt(query, 8);						
			//*************************************//						
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "Owner:  ( %s )", Isim);
			AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);	
			//*************************************//	
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "Total Usage:  ( %d )", Kullanan_Oyuncu);
			AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);	
			//*************************************//		
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "Credits Earned:  ( %d )", Kazanilan_Kredi);
			AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);	
			//*************************************//		
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "Credit Earned (Players):  ( %d )\n \n----------------------------------------------------", Kazandirilan_Kredi);
			AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);	
			//*************************************//		
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "Accumulated Credit:  ( %d )\n----------------------------------------------------", Biriken_Kredi);			
			Format(Miktar, 11, "%d", Biriken_Kredi);
			
			if(Biriken_Kredi && !args)
				AddMenuItem(menuhandle, Miktar, Menu_Yazisi);
			else
				AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);				
			//*************************************//					
		}
		//*************************************//			
	}
	//*************************************//						
	if(Var)
	{
		//*************************************//	
		SetMenuTitle(menuhandle, "             - [ REFERRAL SYSTEM ] -\nTo view other players: !ref <code>\n----------------------------------------------------\n                  Ref Code:  ( %s )\n ", Kod);
		SetMenuPagination(menuhandle, 7);
		SetMenuExitButton(menuhandle, true);
		DisplayMenu(menuhandle, client, 30);			
		//*************************************//	
	}
	else
		PrintToChat(client, "[SM] \x0fCode not found.");
	//*************************************//
	return Plugin_Handled;
	//*************************************//	
}
////////////////////////////////////////////////////////////////////////////////
public Referans_(Handle menuhandle, MenuAction:action, client, Position)
{	
	//*****************************************//				
	if(action == MenuAction_Select)
	{
		//*****************************************//				
		char Miktar[11], SQL_Kodu[256], Steam_ID[32];
		GetMenuItem(menuhandle, Position, Miktar, 11);
		
		Engel[client] = true;
		//*****************************************//						
		PrintToChat(client, "[SM] \x0b%s credit was withdraw from the reference system.", Miktar);		
		Store_SetClientCredits(client, Store_GetClientCredits(client) + StringToInt(Miktar));
		//*************************************//		
		GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));			
		
		Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `biriken_kredi` = 0 WHERE steam_id = '%s';", Steam_ID);						  								
		SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
		//*************************************//
		CreateTimer(0.5, Gecikme, client, TIMER_FLAG_NO_MAPCHANGE);
		//*************************************//			
	}
	else 
	if(action == MenuAction_End)
		CloseHandle(menuhandle);
	//*****************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Gecikme(Handle Timer, any client)
{
	//*************************************//	
	Engel[client] = false;
	FakeClientCommand(client, "sm_referans");
	//*************************************//		
}
//////////////////////////////////////////////////////////////////////////////////////







//////////////////////////////////////////////////////////////////////////////////////
public Action Referans_Siralamasi(client, args)
{
	//*************************************//
	char SQL_Kodu[256], Menu_Yazisi[256], Isim[16], Kod[16];
	Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular ORDER BY kullanan DESC LIMIT 0, 100;");
	
	Handle query = SQL_Query(db, SQL_Kodu);
	Handle menuhandle = CreateMenu(Referans_Bilgi_Menusu_);		
	//*************************************//
	int Var, Kullanan_Oyuncu, Kazanilan_Kredi, Kazandirilan_Kredi;
	
	if (query != INVALID_HANDLE)
	{
		//*************************************//		
		while(SQL_FetchRow(query) && !SQL_IsFieldNull(query, 0))
		{
			//*************************************//		
			if(!Var)
				Var = 1;
			//*************************************//		
			SQL_FetchString(query, 1, Isim, sizeof(Isim));
			SQL_FetchString(query, 4, Kod, sizeof(Kod));		
			
			Kullanan_Oyuncu = SQL_FetchInt(query, 5);
			Kazanilan_Kredi = SQL_FetchInt(query, 6);
			Kazandirilan_Kredi = SQL_FetchInt(query, 7);			
			//*************************************//						
			Format(Menu_Yazisi, sizeof(Menu_Yazisi), "%s  ||  %s  ||  %i  ||  %i  ||  %i  ||", Isim, Kod, Kullanan_Oyuncu, Kazanilan_Kredi, Kazandirilan_Kredi);
			AddMenuItem(menuhandle, "", Menu_Yazisi, ITEMDRAW_DISABLED);	
			//*************************************//											
		}
		//*************************************//			
	}
	//*************************************//						
	if(!Var)
		AddMenuItem(menuhandle, "", "The reference ranking is empty.", ITEMDRAW_DISABLED);
	//*************************************//	
	SetMenuTitle(menuhandle, "[ REFERRAL RANKING ]\n \nName:\nCode:\nTotal Usage:\nCredits Earned:\nCredit Earned (Players):\n ");
	SetMenuPagination(menuhandle, 7);
	SetMenuExitButton(menuhandle, true);
	DisplayMenu(menuhandle, client, 30);			
	//*************************************//	
	return Plugin_Handled;
	//*************************************//	
}
////////////////////////////////////////////////////////////////////////////////








//////////////////////////////////////////////////////////////////////////////////////
public Action Referans_Bilgi(client, args)
{
	//*************************************//				
	Referans_Bilgi_Menusu(client);	
	return Plugin_Handled;
	//*************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////
Referans_Bilgi_Menusu(client)
{
	//*************************************//					
	Handle menuhandle = CreateMenu(Referans_Bilgi_Menusu_);
	SetMenuTitle(menuhandle, "                              - [ REFERRAL SYSTEM ] -\n ");
	char Menu_Yazisi[256];	
	//*************************************//							
	AddMenuItem(menuhandle, "", "How to use the reference code: !usecode <code>");
	//*************************************//	
	if(GetConVarInt(c_Kodu_Kullanana) && GetConVarInt(c_Kodu_Kullanana_Saatlik))	
		Format(Menu_Yazisi, 256, "You earn %d credits and %d hourly credits when using the code.", GetConVarInt(c_Kodu_Kullanana), GetConVarInt(c_Kodu_Kullanana_Saatlik));
	else
	if(GetConVarInt(c_Kodu_Kullanana))	
		Format(Menu_Yazisi, 256, "You earn %d credits when using the code.", GetConVarInt(c_Kodu_Kullanana));
	else
	if(GetConVarInt(c_Kodu_Kullanana_Saatlik))	
		Format(Menu_Yazisi, 256, "You earn %d hourly credits when using the code.", GetConVarInt(c_Kodu_Kullanana_Saatlik));
	else
		Format(Menu_Yazisi, 256, "You can't earn anything hourly when you use code.");	
		
	AddMenuItem(menuhandle, "", Menu_Yazisi);
	//*************************************//	
	AddMenuItem(menuhandle, "", "How to create a referral code: !createcode <code>");
	//*************************************//	
	if(GetConVarInt(c_Kodu_Kullanilana) && GetConVarInt(c_Kodu_Kullanilana_Saatlik))	
		Format(Menu_Yazisi, 256, "You earn %d credits and %d hourly credits when your code is redeemed.", GetConVarInt(c_Kodu_Kullanilana), GetConVarInt(c_Kodu_Kullanilana_Saatlik));
	else
	if(GetConVarInt(c_Kodu_Kullanilana))	
		Format(Menu_Yazisi, 256, "You earn %d credits when your code is redeemed.", GetConVarInt(c_Kodu_Kullanilana));
	else
	if(GetConVarInt(c_Kodu_Kullanilana_Saatlik))	
		Format(Menu_Yazisi, 256, "You earn %d hourly credits when your code is redeemed.", GetConVarInt(c_Kodu_Kullanilana_Saatlik));
	else
		Format(Menu_Yazisi, 256, "You earn nothing hourly when your code is redeemed.");	
		
	AddMenuItem(menuhandle, "", Menu_Yazisi);
	//*************************************//		
	AddMenuItem(menuhandle, "", "By typing !ref, you can withdraw your accumulated credit and see the statistics.");
	AddMenuItem(menuhandle, "", "You can reach the ranking by typing !topref.");	
	//*************************************//	
	SetMenuPagination(menuhandle, 7);
	SetMenuExitButton(menuhandle, true);
	DisplayMenu(menuhandle, client, 30);	
	//*************************************//					
}
//////////////////////////////////////////////////////////////////////////////////////
public Referans_Bilgi_Menusu_(Handle menuhandle, MenuAction:action, client, Position)
{	
	//*****************************************//				
	if(action == MenuAction_Select)
		Referans_Bilgi_Menusu(client);
	else 
	if(action == MenuAction_End)
		CloseHandle(menuhandle);
	//*****************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////






//////////////////////////////////////////////////////////////////////////////////////
public OnClientPostAdminCheck(client)
{
	//*************************************//
	if(IsValidClient(client))
	{
		//*************************************//
		char SQL_Kodu[256], Steam_ID[32];
		GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));
		//*************************************//
		Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular WHERE steam_id = '%s'", Steam_ID);
		Handle Oyuncu_Bilgisi = SQL_Query(db, SQL_Kodu);
		
		bool Var;
		//*************************************//
		if (Oyuncu_Bilgisi != INVALID_HANDLE)
		{
			//*************************************//	
			while(SQL_FetchRow(Oyuncu_Bilgisi) && !SQL_IsFieldNull(Oyuncu_Bilgisi, 0))
			{
				//*************************************//					
				SQL_FetchString(Oyuncu_Bilgisi, 2, Kullandigi_Kod[client], 16);
				SQL_FetchString(Oyuncu_Bilgisi, 4, Kodu[client], 16);
				//*************************************//									
				Sure[client] = SQL_FetchInt(Oyuncu_Bilgisi, 2);
				Var = true;
				//*************************************//									
			}
			//*************************************//				
			CloseHandle(Oyuncu_Bilgisi);
			//*************************************//				
		}
		//*************************************//	
		if(!Var)
		{
			//*************************************//
			Format(SQL_Kodu, sizeof(SQL_Kodu), "INSERT INTO Oyuncular (steam_id, isim, kullandigi_kod, sure, kod, kullanan, kazanilan_kredi, kazandirilan_kredi, biriken_kredi) VALUES ('%s', '%N', '', '0', '', '0', '0', '0', '0')", Steam_ID, client);		
			SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);		
			//*************************************//			
			Kullandigi_Kod[client] = "";
			Kodu[client] = "";
			Sure[client] = 0;				
			//*************************************//			
		}		
		//*************************************//	
		if(!StrEqual(Kullandigi_Kod[client], ""))
			CreateTimer(60.0, Sure_Ekle, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
		//*************************************//
		Engel[client] = false;
		//*************************************//		
	}
	//*************************************//	
}
//////////////////////////////////////////////////////////////////////////////////////
public Action Sure_Ekle(Handle Timer, any client)
{
	//*************************************//	
	if(IsValidClient(client))
	{
		//*************************************//	
		char SQL_Kodu[256], Steam_ID[32];
		Sure[client]++;
		//*************************************//		

		
		
		
		//*************************************//	
		if(Sure[client] >= 60)
		{
			//*************************************//			
			if(GetConVarInt(c_Kodu_Kullanana_Saatlik))
			{			
				Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(c_Kodu_Kullanana));
				PrintToChat(client, "[SM] \x01You earned %d credits for using a referral code and play 1 hour.", GetConVarInt(c_Kodu_Kullanana));			
			}
			//*************************************//									
			Sure[client] = 0;
			//*************************************//						
			
			
			
			
			
			
			//*************************************//											
			int Kazanilan_Kredi, Kazandirilan_Kredi, Biriken_Kredi;
			//*************************************//	
			Format(SQL_Kodu, sizeof(SQL_Kodu), "SELECT * FROM Oyuncular WHERE kod = '%s'", Kullandigi_Kod[client]);
			Handle Oyuncu_Bilgisi = SQL_Query(db, SQL_Kodu);
			//*************************************//
			if (Oyuncu_Bilgisi != INVALID_HANDLE)
			{
				//*************************************//	
				while(SQL_FetchRow(Oyuncu_Bilgisi) && !SQL_IsFieldNull(Oyuncu_Bilgisi, 0))
				{
					Kazanilan_Kredi = SQL_FetchInt(Oyuncu_Bilgisi, 6) + GetConVarInt(c_Kodu_Kullanilana_Saatlik);
					Kazandirilan_Kredi = SQL_FetchInt(Oyuncu_Bilgisi, 7) + GetConVarInt(c_Kodu_Kullanana_Saatlik);
					Biriken_Kredi = SQL_FetchInt(Oyuncu_Bilgisi, 8) + GetConVarInt(c_Kodu_Kullanilana_Saatlik);
				}
				//*************************************//				
				CloseHandle(Oyuncu_Bilgisi);
				//*************************************//				
			}
			//*************************************//
			Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `kazanilan_kredi` = %d, `kazandirilan_kredi` = %d, `biriken_kredi` = %d WHERE kod = '%s';", Kazanilan_Kredi, Kazandirilan_Kredi, Biriken_Kredi, Kullandigi_Kod[client]);						  								
			SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
			//*************************************//				
		}
		
		
		

		//*************************************//		
		GetClientAuthId(client, AuthId_SteamID64, Steam_ID, sizeof(Steam_ID));			
		//*************************************//
		Format(SQL_Kodu, sizeof(SQL_Kodu), "UPDATE Oyuncular SET `sure` = %d WHERE steam_id = '%s';", Sure[client], Steam_ID);						  								
		SQL_TQuery(db, SQLErrorCheckCallback, SQL_Kodu);	
		//*************************************//	
	}
	//*************************************//		
}
//////////////////////////////////////////////////////////////////////////////////////









//////////////////////////////////////////////////////////////////////////////////////
public DB_Baglan()
{
	//*************************************//
	char Hata[255];
	//*************************************//
	db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "Plugincim_Referans_Sistemi", Hata, sizeof(Hata), true, 0);	
	//*************************************//
	if(db == INVALID_HANDLE)
		SetFailState(Hata);
	//*************************************//
	SQL_LockDatabase(db);
	SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS Oyuncular (steam_id TEXT, isim TEXT, kullandigi_kod TEXT, sure INTEGER, kod TEXT, kullanan INTEGER, kazanilan_kredi INTEGER, kazandirilan_kredi INTEGER, biriken_kredi INTEGER);");
	SQL_UnlockDatabase(db);
	//*************************************//				
}
//////////////////////////////////////////////////////////////////////////////////////
public SQLErrorCheckCallback(Handle owner, Handle hndl, const char [] error, any data)
{
}
///////////////////////////////////////////////////////////////////////////////////////
stock bool IsValidClient(client, bool nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false; 

    return IsClientInGame(client); 
} 
///////////////////////////////////////////////////////////////////////////////////////