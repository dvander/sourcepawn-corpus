#include <sourcemod>
#include <sdkhooks>
public Plugin myinfo =
{
    name = "Calculator for L4D",
    author = "marcel",
    description = "fun",
    version = "1.0",
    url = ""
};
char kupka[MAXPLAYERS+1];
char words[256]={
	'a','b','c','d',
	'e','f','g','h',
	'i','j','k','l',
	'm','n','o','p',
	'q','r','s','t',
	'u','v','w','x',
	'y','z','-','+',
	'!','@','#','$',
	'%','^','&','*',
	'(',')','{','}',
	':','"','<','>',
	'?','\0'};
public void OnPluginStart()
{
	RegConsoleCmd("calc",calculator);
	RegConsoleCmd("addnum",AddNumbers);
}
public void OnClientConnected(int client)
{
	if(!IsFakeClient(client))
	{
		kupka[client]='x';
	}
}

public int wypisz(Menu menu, MenuAction action, int param1, int param2)
{
	char infos[32];
	if(action==MenuAction_Select)
	{
		menu.GetItem(param2,infos,sizeof(infos));
		kupka[param1]='\0';
		if(StrEqual(infos,"a")){StrCat(kupka[param1],MAXPLAYERS+1,infos);}
		else if(StrEqual(infos,"s")){StrCat(kupka[param1],MAXPLAYERS+1,infos);}
		else if(StrEqual(infos,"m")){StrCat(kupka[param1],MAXPLAYERS+1,infos);}
		else if(StrEqual(infos,"d")){StrCat(kupka[param1],MAXPLAYERS+1,infos);}
	}
	return 0;
}

public Action calculator(int client,int args)
{
	if(client == 0)return Plugin_Handled;
	Menu menu = CreateMenu(wypisz);
	menu.SetTitle("Calculator");
	menu.AddItem("a","ADD");
	menu.AddItem("s","Subtract");
	menu.AddItem("m","Multiply");
	menu.AddItem("d","Divide");
	menu.Display(client,20);
	
	return Plugin_Handled;
}

public Action AddNumbers(int client, int args)
{
	char buffor[256];
	int a=0;
	int b=0;
	if(StrEqual(kupka[client],"x")){PrintToChat(client,"sorry, but you must first use command !calc, to use !addnum.");return Plugin_Handled;}
	int lengths = GetCmdArgString(buffor, sizeof(buffor));
	if((args <= 0 && args < 2) || (CheckArguments(buffor,lengths) == true)){PrintToChat(client,"sorry, but you must add two arguments. Like !addnum 2 4, and this must only numbers, and max two arguments!");return Plugin_Handled;}
	
	// checks arguments
	a=GetCmdArgInt(1);
	b=GetCmdArgInt(2);
	
	if(StrEqual(kupka[client],"a"))
	{
		PrintToChat(client,"Calculator 1.0");
		PrintToChat(client,"%d + %d = %d",a,b,a+b);
		PrintToChat(client,"--------------");
	}
	else if(StrEqual(kupka[client],"s"))
	{
		PrintToChat(client,"Calculator 1.0");
		PrintToChat(client,"%d - %d = %d",a,b,a-b);
		PrintToChat(client,"--------------");
	}
	else if(StrEqual(kupka[client],"m"))
	{
		PrintToChat(client,"Calculator 1.0");
		PrintToChat(client,"%d * %d = %d",a,b,a*b);
		PrintToChat(client,"--------------");
	}
	else if(StrEqual(kupka[client],"d"))
	{
		if(b == 0){PrintToChat(client,"We don't divide by zero!");return Plugin_Handled;}
		PrintToChat(client,"Calculator 1.0");
		PrintToChat(client,"%d / %d = %d",a,b,a/b);
		PrintToChat(client,"--------------");
	}
	else
	{
		PrintToChat(client,"Unknown error with calculator!");
	}
	return Plugin_Handled;
}

bool CheckArguments(char[] buffor,int lengths)
{
	for(int i=0;i<lengths;i++)
	{
		if(buffor[i] == ' ')continue;
		for(int j=0;j<(sizeof(words)/1);j++)
		{
			if(words[j] != '\0' && buffor[i] == words[j])return true;
		}
	}
	return false;
}