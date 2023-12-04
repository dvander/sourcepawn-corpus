#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define PLUGIN_AUTHOR "pr0mers"
#define PLUGIN_VERSION "1.00"

public void OnPluginStart()
{
	
	RegConsoleCmd("sm_xox", denemee);
	RegConsoleCmd("sm_cancelxox", ibidal);
	RegAdminCmd("sm_xoxdebug", denemees,ADMFLAG_ROOT);//debug thingy
	
}
int oynaniyormu[MAXPLAYERS+1];
char xoxdizi[MAXPLAYERS+1][3][3];
int kazandi[MAXPLAYERS+1];
int hamlesayisi[MAXPLAYERS+1] = 0;
int iptal[MAXPLAYERS + 1];
public Action denemee(int client,int args){
	char text1[512];
    char text0[512];
    GetCmdArg(1, text1, sizeof(text1));
    int playersConnected = GetMaxClients();
    int bulduk = 0;
	for (int i = 1; i < playersConnected; i++)
	    {
	        if(IsClientInGame(i)==true)
	        {
	            GetClientName(i, text0, sizeof(text0));
	            if (StrContains(text0, text1, false)!=-1){
	            	if(bulduk!=0){
	            		PrintToChat(client,"Found more than 1 player");
	            		return Plugin_Handled;
	            	}
	           		bulduk = i;
	           	}
	        }
	}
	if(bulduk == 0){
		PrintToChat(client,"Found no one");
		return Plugin_Handled;
	}
	if(bulduk == client){
		PrintToChat(client,"You cant pair with yourself");
		return Plugin_Handled;
	}
	if(iptal[bulduk]==1){
		PrintToChat(client,"The person you tried to pair cancelled the XOX");
		return Plugin_Handled;
	}
	if(oynaniyormu[client] != 0 || oynaniyormu[bulduk] !=0){
		PrintToChat(client,"The person you tried to pair is already playing with someone");
		return Plugin_Handled;
	}
	PrintToChat(bulduk, "The player %N challanged you to play XOX", client);
	PrintToChat(client, "You challanged the player %N .", bulduk);
	oynaniyormu[client] = bulduk;
	oynaniyormu[bulduk] = client;
	evethayirmenu(client, bulduk);
	return Plugin_Handled;
}	
public menuolustur(int sirakimde){
	Menu menu = new Menu(Menu_Callback,MenuAction_Display);
	menu.SetTitle("%c %c %c\n%c %c %c\n%c %c %c",xoxdizi[sirakimde][0][0],xoxdizi[sirakimde][0][1],xoxdizi[sirakimde][0][2],xoxdizi[sirakimde][1][0],xoxdizi[sirakimde][1][1],xoxdizi[sirakimde][1][2],xoxdizi[sirakimde][2][0],xoxdizi[sirakimde][2][1],xoxdizi[sirakimde][2][2]);
	menu.AddItem("lu", "Upper Left",(xoxdizi[sirakimde][0][0] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("mu", "Upper Middle",(xoxdizi[sirakimde][0][1] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("ru", "Upper Right",(xoxdizi[sirakimde][0][2] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("lm", "Middle Left",(xoxdizi[sirakimde][1][0] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("mm", "Middle Middle",(xoxdizi[sirakimde][1][1] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("rm", "Middle Right",(xoxdizi[sirakimde][1][2] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("ld", "Bottom Left",(xoxdizi[sirakimde][2][0] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("md", "Bottom Middle",(xoxdizi[sirakimde][2][1] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("rd", "Bottom Right",(xoxdizi[sirakimde][2][2] == '/')?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.ExitButton = false;
	menu.Display(sirakimde,30);

}
//hamle sayısı çift ise ilk istek atan kişide sıra
public int Menu_Callback(Menu menu, MenuAction action,int param1,int param2){
	char hamle = '/';
	switch (action){
		case MenuAction_Display:
    	{
    		
    	}
		case MenuAction_Select:
		{
			int baslatankisi;
			int hedef;
			int hamleyapan;
			hamleyapan = param1;
			//PrintToChatAll("%N , %d",param1,param1);
			if(hamlesayisi[param1] %2 == 0){
				baslatankisi = param1;
				hedef = oynaniyormu[param1];
			}
			if(hamlesayisi[param1] %2 == 1){
				hedef = param1;
				baslatankisi = oynaniyormu[param1];
			}
			//----------------------
			if(hamlesayisi[param1] %2 == 0){
				hamle = 'O';
			}
			if(hamlesayisi[param1] %2 == 1){
				hamle = 'X';
			}
			hamlesayisi[param1]++;
			hamlesayisi[oynaniyormu[param1]]++;
			char item[64];
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item,"lu")){
				xoxdizi[baslatankisi][0][0] = hamle;
				xoxdizi[hedef][0][0] = hamle;
				
			}
			if(StrEqual(item,"mu")){
				xoxdizi[baslatankisi][0][1] = hamle;
				xoxdizi[hedef][0][1] = hamle;
				
			}
			if(StrEqual(item,"ru")){
				xoxdizi[baslatankisi][0][2] = hamle;
				xoxdizi[hedef][0][2] = hamle;
			}
			if(StrEqual(item,"lm")){
				xoxdizi[hedef][1][0] = hamle;
				xoxdizi[baslatankisi][1][0] = hamle;
				
			}
			if(StrEqual(item,"mm")){
				xoxdizi[hedef][1][1] = hamle;
				xoxdizi[baslatankisi][1][1] = hamle;
				
			}	
			if(StrEqual(item,"rm")){
				xoxdizi[hedef][1][2] = hamle;
				xoxdizi[baslatankisi][1][2] = hamle;
				
			}
			if(StrEqual(item,"ld")){
				xoxdizi[hedef][2][0] = hamle;
				xoxdizi[baslatankisi][2][0] = hamle;
				
			}
			if(StrEqual(item,"md")){
				xoxdizi[hedef][2][1] = hamle;
				xoxdizi[baslatankisi][2][1] = hamle;
				
			}
			if(StrEqual(item,"rd")){
				xoxdizi[hedef][2][2] = hamle;
				xoxdizi[baslatankisi][2][2] = hamle;
			}
			hamleyapildi(param1);
			if(hamlesayisi[hamleyapan]==9 && kazandi[hamleyapan] ==0){
				PrintToChatAll("%N and %N are tied.",baslatankisi,hedef);
				sifirla(baslatankisi);
			}
			else if(hamle == 'O' && kazandi[hamleyapan]== 0 && hamlesayisi[hamleyapan] != 9){
				menuolustur(hedef);
			}
			else if(hamle == 'X' && kazandi[hamleyapan] ==0 && hamlesayisi[hamleyapan] != 9){
				menuolustur(baslatankisi);
			}
			else if(kazandi[hamleyapan] != 0){
				PrintToChatAll("%N and %N winner of the XOX is %N",kazandi[hamleyapan],oynaniyormu[hamleyapan],kazandi[hamleyapan]);
				sifirla(baslatankisi);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
				PrintToChatAll("%N Cancelled the XOX.",param1);
				sifirla(param1);
		}
		
	}
}
public Action denemees(int client,int args){
	PrintToConsole(client, "-----------------");
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i)==true)
		{
			PrintToConsole(client, "player: %d , playwith: %d , numofmoves : %d , winner : %d", i, oynaniyormu[i], hamlesayisi[i],kazandi[i]);
			for (int k = 0; k< 3; k++){
				PrintToConsole(client,"%s", xoxdizi[i][k]);
			}
		}
	}
	PrintToConsole(client, "-----------------");
}
public hamleyapildi(int hamleyapan){
	if(xoxdizi[hamleyapan][0][0]==xoxdizi[hamleyapan][0][1] && xoxdizi[hamleyapan][0][0] == xoxdizi[hamleyapan][0][2] && xoxdizi[hamleyapan][0][0] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][1][0]==xoxdizi[hamleyapan][1][1] && xoxdizi[hamleyapan][1][0] == xoxdizi[hamleyapan][1][2] && xoxdizi[hamleyapan][1][0] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][2][0]==xoxdizi[hamleyapan][2][1] && xoxdizi[hamleyapan][2][0] == xoxdizi[hamleyapan][2][2]&& xoxdizi[hamleyapan][2][0] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][0][0]==xoxdizi[hamleyapan][1][1] && xoxdizi[hamleyapan][0][0] == xoxdizi[hamleyapan][2][2]&& xoxdizi[hamleyapan][0][0] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][0][2]==xoxdizi[hamleyapan][1][1] && xoxdizi[hamleyapan][0][2] == xoxdizi[hamleyapan][2][0] && xoxdizi[hamleyapan][0][2] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][0][2]==xoxdizi[hamleyapan][1][2] && xoxdizi[hamleyapan][0][2] == xoxdizi[hamleyapan][2][2] && xoxdizi[hamleyapan][0][2] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][0][1]==xoxdizi[hamleyapan][1][1] && xoxdizi[hamleyapan][0][1] == xoxdizi[hamleyapan][2][1] && xoxdizi[hamleyapan][0][1] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
	else if(xoxdizi[hamleyapan][0][0]==xoxdizi[hamleyapan][1][0] && xoxdizi[hamleyapan][0][0] == xoxdizi[hamleyapan][2][0] && xoxdizi[hamleyapan][0][0] !='/'){
		kazandi[hamleyapan] = hamleyapan;
		kazandi[oynaniyormu[hamleyapan]] = hamleyapan;
	}
}
public evethayirmenu(int baslatan,int hede){
	Menu menu = new Menu(Menu_Callback2,MenuAction_Display);
	menu.SetTitle("Player %N challanged you to play xox do you accept?",baslatan);
	menu.AddItem("evet", "Yes");
	menu.AddItem("hayır", "No");
	menu.ExitButton = false;
	menu.Display(hede, 30);
	return;
}
public int Menu_Callback2(Menu menu, MenuAction action,int param1,int param2){
	switch (action){
		case MenuAction_Display:
    	{
    	}
		case MenuAction_Select:
		{
			int baslatankisi=oynaniyormu[param1];
			int hedef = param1;
			char item[64];
			//PrintToChatAll("secdi");
			menu.GetItem(param2, item, sizeof(item));
			if(StrEqual(item,"evet")){
				for (int i = 0; i< 3; i++){
					for (int j = 0; j< 3; j++){
						xoxdizi[baslatankisi][i][j] = '/';						
						xoxdizi[hedef][i][j] = '/';
					}
				}
				menuolustur(baslatankisi);
			}
			if(StrEqual(item,"hayır")){
				PrintToChatAll("%N Didn't accept the XOX game", hedef);
				sifirla(baslatankisi);
			}
		}
		case MenuAction_End:
		{			
			delete menu;
		}
		case MenuAction_Cancel:
		{
			PrintToChatAll("%N Cancelled the XOX game", param1);
			sifirla(param1); 
		}
		
	}
}
public OnMapStart(){
	for (int i = 0; i < MAXPLAYERS; i++){
		sifirla(i);
	}
}
public OnClientDisconnect(int client){
	iptal[client] = 0;
	sifirla(client);
}
public sifirla(int baslatan){
	//PrintToChatAll("sifirlandi , %N , %N",baslatan , oynaniyormu[baslatan]);
	for (int i = 0; i< 3; i++){
		for (int j = 0; j< 3; j++){
			xoxdizi[baslatan][i][j] = '/';						
			xoxdizi[oynaniyormu[baslatan]][i][j] = '/';
		}
	}
	hamlesayisi[oynaniyormu[baslatan]] = 0;
	hamlesayisi[baslatan] = 0;
	kazandi[baslatan] = 0;
	kazandi[oynaniyormu[baslatan]] = 0;
	oynaniyormu[oynaniyormu[baslatan]] = 0;
	oynaniyormu[baslatan] = 0;	
}
public Action ibidal(int client,int args){
	if(iptal[client]==0){
		PrintToChat(client, "You cancelled xox requests. No one can send you a xox request, if you type !cancelxox one more time they can send you xox requests");
		iptal[client] = 1;
	}
	else if(iptal[client]==1){
		PrintToChat(client, "You cancelled the cancellation of xox request. They can send you requests now, if you type !cancelxox one more time they cant send you requests");
		iptal[client] = 0;
	}
}